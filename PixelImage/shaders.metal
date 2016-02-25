
#include <metal_stdlib>

using namespace metal;

struct metaballData {
    float x;
    float y;
    float r;
    float g;
    float b;
};

kernel void
    drawMetaballs(texture2d<float, access::write> outTexture[[texture(0)]],
                  constant float *edgesBuffer[[buffer(1)]],
                  constant metaballData *metaballBuffer[[buffer(0)]],
                  uint2 gid[[thread_position_in_grid]]) {

    char numberOfMetaballs = metaballBuffer[0].x - 1;

    float sum = 0;
    float3 colorSum = float3(0, 0, 0);
    float colorAccumulation = 0;
    float3 colorSumLink = float3(0, 0, 0);

    char x, y;

    float metaballDistances[10];
    float2 metaballDirections[10];
    float3 metaballColors[10];

    for (x = 1; x <= numberOfMetaballs; x += 1) {
        metaballData metaball = metaballBuffer[x];
        float2 metaballPosition = float2(metaball.x, metaball.y);
        float2 vector
            = float2(metaballPosition.x - gid.x, metaballPosition.y - gid.y);
        float squaredDistance = dot(vector, vector);
        float realDistance = sqrt(squaredDistance);
        metaballDistances[x - 1] = squaredDistance;
        metaballDirections[x - 1] = vector / realDistance;
        metaballColors[x - 1] = float3(metaball.r, metaball.g, metaball.b);
    }

    float bendClose = 0.0;
    float bendCloseCount = 0.0;
    float ball = 0.0;

    for (x = 0; x < numberOfMetaballs; x += 1) {
        float distance1 = metaballDistances[x];
        float value1 = 2048 / (distance1 + 1);
        float2 direction1 = metaballDirections[x];

        float colorContribution = 1 / distance1;
        colorAccumulation += colorContribution;
        colorSum += metaballColors[x] * colorContribution;

        for (y = x + 1; y < numberOfMetaballs; y += 1) {
            float distance2 = metaballDistances[y];
            float value2 = 2048 / (distance2 + 1);
            float2 direction2 = metaballDirections[y];

            float v = value1 + value2;
            float weightedValue = 0.5 * v;

            char edgeIndex = y * numberOfMetaballs + x;
            float edgeWeight = edgesBuffer[edgeIndex];
            float cosine = dot(direction1, direction2);
            float link = pow(((1 - cosine) * 0.5), 100);
            float weightedLink = 0.6 * link * edgeWeight;

            float result = weightedValue + weightedLink;

            ball += step(0.4, weightedValue);

            float metaballValue = step(0.5, weightedValue + weightedLink);

            if (metaballValue > 0.0) {
                colorSumLink = float3(0.0, 0.0, 0.0);
                colorSumLink += metaballColors[x] / distance1;
                colorSumLink += metaballColors[y] / distance2;
                colorSumLink /= (1 / distance1) + (1 / distance2);
            }

            if (result > 0.4) {
                bendClose += result;
                bendCloseCount += 1.0;
            }

            sum += metaballValue;
        }
    }

    //    bendClose = bendClose / bendCloseCount;

    if (bendClose != 0.0) {
        bendClose = (bendClose - 0.4) * (1 / (0.6 - 0.4));
    } else {
        bendClose = 0.0;
    }


    float result = step(0.4, sum);
    result = clamp(result, 0.0, 1.0);

    colorSum = colorSum / colorAccumulation;

    if (result > 0.0 && ball < 1.0) {
        colorSum = colorSumLink;
    }


    colorSum *= result;

    outTexture.write(float4(colorSum.bgr, 1), gid);
}
