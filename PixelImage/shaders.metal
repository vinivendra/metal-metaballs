
#include <metal_stdlib>

using namespace metal;

kernel void
    drawMetaballs(texture2d<float, access::write> outTexture[[texture(0)]],
                  texture2d<float, access::read>
                      metaballTexture[[texture(1)]],
                  uint2 gid[[thread_position_in_grid]]) {

    char numberOfMetaballs = metaballTexture.read(0)[0];
    char metaballArraySize = numberOfMetaballs * 2 + 1;

    float sum = 0;

    for (char i = 1; i < metaballArraySize; i += 2) {
        for (char j = i + 2; j < metaballArraySize; j += 2) {
            float2 metaball1 = float2(metaballTexture.read(i)[0],
                                      600 - metaballTexture.read(i + 1)[0]);

            float2 metaball2 = float2(metaballTexture.read(j)[0],
                                      600 - metaballTexture.read(j + 1)[0]);

            float2 metaball1Vector
                = float2(metaball1.x - gid.x, metaball1.y - gid.y);
            float2 metaball2Vector
                = float2(metaball2.x - gid.x, metaball2.y - gid.y);

            float2 direction1 = normalize(metaball1Vector);
            float2 direction2 = normalize(metaball2Vector);

            float cosine = dot(direction1, direction2);

            float value1 = 2048 / (dot(metaball1Vector, metaball1Vector) + 1);
            float value2 = 2048 / (dot(metaball2Vector, metaball2Vector) + 1);

            float v = value1 + value2;
            float link = pow(((1 - cosine) * 0.5), 100);

            float weightedLink = 0.6 * link;
            float weightedValue = 0.5 * v;

            sum += mix(0.0, 1.0, step(0.5, weightedValue + weightedLink));
        }
    }

    float result = sum;

    outTexture.write(float4(result, result / 2, 0, 1), gid);
}
