Shader "Tutorial/027_LayeredNoise"
{
    Properties
    {
        _CellSize ("Cell Size", Range(0, 2)) = 2
        _Roughness ("Roughness", Range(1, 8)) = 3
        _Persistance ("Persistance", Range(0, 1)) = 0.4
        _Amplitude("Amplitude", Range(0, 10)) = 1

        [KeywordEnum(1D, 2D, 3D, SPECIAL)] _NoiseDemension("noiseDemension", Float) = 0
    }
    SubShader
    {

        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM

        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow.
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #pragma multi_compile _NOISEDEMENSION_1D _NOISEDEMENSION_2D _NOISEDEMENSION_3D _NOISEDEMENSION_SPECIAL
        

        #include "WhiteNoise.cginc"

        #define OCTAVES 4

        float _CellSize;
        float _Roughness;
        float _Persistance;
        float _Amplitude;

        struct Input
        {
            float3 worldPos;
        };

        float gradientNoise(float value){
			float fraction = frac(value);
			float interpolator = easeInOut(fraction);
            
			float previousCellInclination = rand1dTo1d(floor(value)) * 2 - 1;
			float previousCellLinePoint = previousCellInclination * fraction;

			float nextCellInclination = rand1dTo1d(ceil(value)) * 2 - 1;
			float nextCellLinePoint = nextCellInclination * (fraction - 1);
    
            //보간
			return lerp(previousCellLinePoint, nextCellLinePoint, interpolator);
		}

        float perlinNoise(float2 value){
			float2 lowerLeftDirection = rand2dTo2d(float2(floor(value.x), floor(value.y))) * 2 - 1;
			float2 lowerRightDirection = rand2dTo2d(float2(ceil(value.x), floor(value.y))) * 2 - 1;
			float2 upperLeftDirection = rand2dTo2d(float2(floor(value.x), ceil(value.y))) * 2 - 1;
			float2 upperRightDirection = rand2dTo2d(float2(ceil(value.x), ceil(value.y))) * 2 - 1;
    
			float2 fraction = frac(value);
    
			float lowerLeftFunctionValue = dot(lowerLeftDirection, fraction - float2(0, 0));
			float lowerRightFunctionValue = dot(lowerRightDirection, fraction - float2(1, 0));
			float upperLeftFunctionValue = dot(upperLeftDirection, fraction - float2(0, 1));
			float upperRightFunctionValue = dot(upperRightDirection, fraction - float2(1, 1));
    
			float interpolatorX = easeInOut(fraction.x);
			float interpolatorY = easeInOut(fraction.y);
    
			float lowerCells = lerp(lowerLeftFunctionValue, lowerRightFunctionValue, interpolatorX);
			float upperCells = lerp(upperLeftFunctionValue, upperRightFunctionValue, interpolatorX);
            
			float noise = lerp(lowerCells, upperCells, interpolatorY);
			return noise;
		}
    
        float perlinNoise(float3 value){
            float3 fraction = frac(value);

            float interpolatorX = easeInOut(fraction.x);
            float interpolatorY = easeInOut(fraction.y);
            float interpolatorZ = easeInOut(fraction.z);

            float cellNoiseZ[2];
            [unroll]
            for(int z=0;z<=1;z++){
                float cellNoiseY[2];
                [unroll]
                for(int y=0;y<=1;y++){
                    float cellNoiseX[2];
                    [unroll]
                    for(int x=0;x<=1;x++){
                        float3 cell = floor(value) + float3(x, y, z);
                        float3 cellDirection = rand3dTo3d(cell) * 2 - 1;
                        float3 compareVector = fraction - float3(x, y, z);
                        cellNoiseX[x] = dot(cellDirection, compareVector);
                    }
                    cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                }
                cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
            }
            float noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
            return noise;
        }

        //계층 노이즈는 노이즈를 수정하지 않고 서로다른 주파수의 잡음을 겹쳐서 노이즈를 조절하는 방식이다.
        float sampleLayeredNoise(float value){
            float noise = 0;
            float frequency = 1;
            float factor = 1;

            [unroll]
            for(int i=0; i<OCTAVES; i++){
                //frequency는 다음에 생성할 노이즈의 주파수에 영향을 준다. 따라서 _Roughness가 높을수록 다음에 생성할 노이즈와 현재 노이즈의 차이가 커지며 둘을 겹쳤을때 더 거친(Rough) 잡음을 얻을 수 있다.
                //factor는 다음에 생성할 노이즈의 값에 영향을 준다. 따라서 _Persistance가 높을수록 계층을 쌓음으로써 얻는 증가값이 커져 레이어를 많이 쌓은 것(Persist)처럼 보일 수 있다.
                noise = noise + gradientNoise(value * frequency + i * 0.72354) * factor;
                factor *= _Persistance;
                frequency *= _Roughness;
            }

            return noise;
        }
        
        float sampleLayeredNoise(float2 value){
            float noise = 0;
            float frequency = 1;
            float factor = 1;

            [unroll]
            for(int i=0; i<OCTAVES; i++){
                noise = noise + perlinNoise(value * frequency + i * 0.72354) * factor;
                factor *= _Persistance;
                frequency *= _Roughness;
            }

            return noise;
        }

        float sampleLayeredNoise(float3 value){
            float noise = 0;
            float frequency = 1;
            float factor = 1;

            [unroll]
            for(int i=0; i<OCTAVES; i++){
                noise = noise + perlinNoise(value * frequency + i * 0.72354) * factor;
                factor *= _Persistance;
                frequency *= _Roughness;
            }

            return noise;
        }
        //계층 노이즈의 특수한 사용으로 계층 노이즈를 버텍스 데이터에 
        void vert(inout appdata_full data){
    //get real base position
    float3 localPos = data.vertex / data.vertex.w;

    //calculate new posiiton
    float3 modifiedPos = localPos;
    float2 basePosValue = mul(unity_ObjectToWorld, modifiedPos).xz / _CellSize;
    float basePosNoise = sampleLayeredNoise(basePosValue) + 0.5;
    modifiedPos.y += basePosNoise * _Amplitude;
    
    //calculate new position based on pos + tangent
    float3 posPlusTangent = localPos + data.tangent * 0.02;
    float2 tangentPosValue = mul(unity_ObjectToWorld, posPlusTangent).xz / _CellSize;
    float tangentPosNoise = sampleLayeredNoise(tangentPosValue) + 0.5;
    posPlusTangent.y += tangentPosNoise * _Amplitude;

    //calculate new position based on pos + bitangent
    float3 bitangent = cross(data.normal, data.tangent);
    float3 posPlusBitangent = localPos + bitangent * 0.02;
    float2 bitangentPosValue = mul(unity_ObjectToWorld, posPlusBitangent).xz / _CellSize;
    float bitangentPosNoise = sampleLayeredNoise(bitangentPosValue) + 0.5;
    posPlusBitangent.y += bitangentPosNoise * _Amplitude;

    //get recalculated tangent and bitangent
    float3 modifiedTangent = posPlusTangent - modifiedPos;
    float3 modifiedBitangent = posPlusBitangent - modifiedPos;

    //calculate new normal and set position + normal
    float3 modifiedNormal = cross(modifiedTangent, modifiedBitangent);
    data.normal = normalize(modifiedNormal);
    data.vertex = float4(modifiedPos.xyz, 1);
        }


        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            #if _NOISEDEMENSION_1D
                float value = IN.worldPos.x / _CellSize;
                float noise = sampleLayeredNoise(value);
    
                float dist = abs(noise - IN.worldPos.y);
                float pixelHeight = fwidth(IN.worldPos.y);
                float lineIntensity = smoothstep(2*pixelHeight, pixelHeight, dist);
                o.Albedo = lerp(1, 0, lineIntensity);
            #elif _NOISEDEMENSION_2D
                float2 value = IN.worldPos.xy / _CellSize;
                float noise = sampleLayeredNoise(value) + 0.5;
                o.Albedo = noise;
            #elif _NOISEDEMENSION_3D
                float3 value = IN.worldPos.xyz / _CellSize;
                float noise = sampleLayeredNoise(value) + 0.5;
                o.Albedo = noise;
            #else
                o.Albedo = 1;
            #endif
        }
        ENDCG
    }
    FallBack "Diffuse"
}
