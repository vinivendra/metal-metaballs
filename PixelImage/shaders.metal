
#include <metal_stdlib>

using namespace metal;

kernel void drawMetaballs(texture2d<float, access::write> outTexture[[texture(0)]], constant float *edgesBuffer[[buffer(1)]], constant float *metaballBuffer[[buffer(0)]], uint2 gid[[thread_position_in_grid]]) {

    char numberOfMetaballs = metaballBuffer[0];
    char metaballArraySize = numberOfMetaballs * 5 + 1;

    float sum = 0;

    char x, y;

    float metaballDistances[10];
    float2 metaballDirections[10];

    for (y = 1, x = 0; y < metaballArraySize; y += 5, x += 1) {
        float2 metaball = float2(metaballBuffer[y], metaballBuffer[y + 1]);
        float2 vector = float2(metaball.x - gid.x, metaball.y - gid.y);
        float squaredDistance = dot(vector, vector);
        float realDistance = sqrt(squaredDistance);
        metaballDistances[x] = squaredDistance;
        metaballDirections[x] = vector/realDistance;
    }

    float bendClose = 0.0;
    float bendCloseCount = 0.0;

    for (x = 0; x < numberOfMetaballs; x += 1) {
        float value1 = 2048 / (metaballDistances[x] + 1);
        float2 direction1 = metaballDirections[x];

        for (y = x + 1; y < numberOfMetaballs; y += 1) {
            float value2 = 2048 / (metaballDistances[y] + 1);
            float2 direction2 = metaballDirections[y];

            float v = value1 + value2;
            float weightedValue = 0.5 * v;

            char edgeIndex = y * numberOfMetaballs + x;
            float edgeWeight = edgesBuffer[edgeIndex];
            float cosine = dot(direction1, direction2);
            float link = pow(((1 - cosine) * 0.5), 100);
            float weightedLink = 0.6 * link * edgeWeight;

            float result = weightedValue + weightedLink;

            if (result > 0.4 && result < 0.6) {
                bendClose += result;
                bendCloseCount += 1.0;
            }

            sum += step(0.5, weightedValue + weightedLink);
        }
    }

    bendClose = bendClose / bendCloseCount;

    if (bendClose != 0.0) {
        bendClose = (bendClose - 0.4) * (1/(0.6-0.4));
    } else {
        bendClose = 0.0;
    }

    float result = step(0.4, sum);
    result += bendClose * 10;
    result = clamp(result, 0.0, 1.0);

    outTexture.write(float4(result, result / 2, 0.0, 1), gid);
}
