
#include <metal_stdlib>

using namespace metal;

kernel void drawMetaballs(texture2d<float, access::write> outTexture[[texture(0)]], constant float *edgesBuffer[[buffer(1)]], constant float *metaballBuffer[[buffer(0)]], uint2 gid[[thread_position_in_grid]]) {

    uint numberOfMetaballs = metaballBuffer[0];
    uint metaballArraySize = numberOfMetaballs * 2 + 1;

    float sum = 0;

    uint i, j, x, y;

    float metaballDistances[10];
    float2 metaballDirections[10];

    for (i = 1, x = 0; i < metaballArraySize; i += 2, x += 1) {
        float2 metaball = float2(metaballBuffer[i], metaballBuffer[i + 1]);
        float2 vector = float2(metaball.x - gid.x, metaball.y - gid.y);
        float squaredDistance = dot(vector, vector);
        float realDistance = sqrt(squaredDistance);
        metaballDistances[x] = squaredDistance;
        metaballDirections[x] = vector/realDistance;
    }

    for (i = 1, x = 0; i < metaballArraySize; i += 2, x += 1) {
        for (j = i + 2, y = x + 1; j < metaballArraySize; j += 2, y += 1) {
            float value1 = 2048 / (metaballDistances[x] + 1);
            float value2 = 2048 / (metaballDistances[y] + 1);

            float v = value1 + value2;

            float weightedValue = 0.5 * v;

            char edgeIndex = y * numberOfMetaballs + x;
            float edgeWeight = edgesBuffer[edgeIndex];
            float2 direction1 = metaballDirections[x];
            float2 direction2 = metaballDirections[y];

            float cosine = dot(direction1, direction2);

            float link = pow(((1 - cosine) * 0.5), 100);

            float weightedLink = 0.6 * link * edgeWeight;

            sum += step(0.5, weightedValue + weightedLink);
        }
    }

    float result = step(0.4, sum);

    outTexture.write(float4(result, result / 2, 0, 1), gid);
}
