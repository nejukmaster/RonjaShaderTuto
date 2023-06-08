Shader"Tutorial/026_PerlinNoise"
{
    Properties
    {
        _CellSize ("Cell Size", Range(0, 2)) = 2
        _ScrollSpeed ("Scroll Speed", Range(0, 1)) = 1
        [KeywordEnum(1D, 2D, 3D, SPECIAL)] _NoiseDemension("noiseDemension", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0
        #pragma multi_compile _NOISEDEMENSION_1D _NOISEDEMENSION_2D _NOISEDEMENSION_3D _NOISEDEMENSION_SPECIAL

        #include "WhiteNoise.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float3 worldPos;
        };

        float _CellSize;
        float _ScrollSpeed;
        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        float gradientNoise(float value){
            //Cell에 위치한 fragment의 Cell상의 위치값
			float fraction = frac(value);
            //이 위칫값을 완화
			float interpolator = easeInOut(fraction);
            
            //현재 Cell의 기울기. 기울기의 방향을 다양화 하기위해 기울기의 범위를 -1~1사이로 매핑
			float previousCellInclination = rand1dTo1d(floor(value)) * 2 - 1;
            //기울기에 따른 현재 위치의 함수값
			float previousCellLinePoint = previousCellInclination * fraction;

			float nextCellInclination = rand1dTo1d(ceil(value)) * 2 - 1;
            //값의 보간은 대칭으로 이루어져야하므로, y축 기준 으로 대칭인 점에서 다음 Cell의 함수값을 구해준다.
			float nextCellLinePoint = nextCellInclination * (fraction - 1);
    
            //보간
			return lerp(previousCellLinePoint, nextCellLinePoint, interpolator);
		}

        float perlinNoise(float2 value){
            //2차원 PerlinNoise는 2차원 ValueNoise와 마찬가지로 타깃 셀을 포함한 네개의 셀을 샘플링한 후 각 사이를 보간하여 구한다.
			//좌측 하단 셀의 2차원 기울기
			float2 lowerLeftDirection = rand2dTo2d(float2(floor(value.x), floor(value.y))) * 2 - 1;
            //우측 하단 셀의 2차원 기울기
			float2 lowerRightDirection = rand2dTo2d(float2(ceil(value.x), floor(value.y))) * 2 - 1;
            //좌측 상단 셀의 2차원 기울기
			float2 upperLeftDirection = rand2dTo2d(float2(floor(value.x), ceil(value.y))) * 2 - 1;
            //우측 상단 셀의 2차원 기울기
			float2 upperRightDirection = rand2dTo2d(float2(ceil(value.x), ceil(value.y))) * 2 - 1;

            //위칫값
			float2 fraction = frac(value);

			//2차원 기울기의 함수값은 내적으로 구한다.
            //좌측 하단 셀에서의 함수값
			float lowerLeftFunctionValue = dot(lowerLeftDirection, fraction - float2(0, 0));
            //우측 하단 셀에서의 함수값
			float lowerRightFunctionValue = dot(lowerRightDirection, fraction - float2(1, 0));
            //좌측 상단 셀에서의 함수값
			float upperLeftFunctionValue = dot(upperLeftDirection, fraction - float2(0, 1));
            //우측 상단 셀에서의 함수값
			float upperRightFunctionValue = dot(upperRightDirection, fraction - float2(1, 1));

            //x보간자 완화
			float interpolatorX = easeInOut(fraction.x);
            //y보간자 완화
			float interpolatorY = easeInOut(fraction.y);

			//위,아래 쌍끼리 값을 보간
			float lowerCells = lerp(lowerLeftFunctionValue, lowerRightFunctionValue, interpolatorX);
			float upperCells = lerp(upperLeftFunctionValue, upperRightFunctionValue, interpolatorX);
            
            //위, 아래 보간
			float noise = lerp(lowerCells, upperCells, interpolatorY);
			return noise;
		}
    
        //3차원 PerlinNoise 역시 3차원 ValueNoise처럼 생성해준다.
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

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            
            #if _NOISEDEMENSION_1D
                float value = IN.worldPos.x / _CellSize;
                float noise = gradientNoise(value);
                float dist = abs(noise - IN.worldPos.y);
                float pixelHeight = fwidth(IN.worldPos.y);
                float lineIntensity = smoothstep(2*pixelHeight, pixelHeight, dist);
                o.Albedo = lerp(1,0,lineIntensity);
            #elif _NOISEDEMENSION_2D
                float2 value = IN.worldPos.xy / _CellSize;
                //noise의 값을 0~1로 매핑하기 위해 0.5를 더해준다.
                float noise = perlinNoise(value) + 0.5;
                o.Albedo = noise;
            #elif _NOISEDEMENSION_3D
                float3 value = IN.worldPos / _CellSize;
                float noise = perlinNoise(value) + 0.5;

                o.Albedo = noise;
            #elif _NOISEDEMENSION_SPECIAL
                float3 value = IN.worldPos / _CellSize;
                //입력값의 y값을 시간에따라 임의로 변환
			    value.y += _Time.y * _ScrollSpeed;
                
			    float noise = perlinNoise(value) + 0.5;
                //noise의 각 셀별로 그라데이션 구분
			    noise = frac(noise * 6);
                //noise의 변화값을 관찰합니다.
			    float pixelNoiseChange = fwidth(noise);
                //경계에서 1픽셀이상 떨어진 값에 0을 반환 나머지는 최댓값이 1인 보간 적용
			    float heightLine = smoothstep(1-pixelNoiseChange, 1, noise);
                //보간되지 않은 부분에 대해 추가적인 보간을 진행하여 값을 1로 고정
			    heightLine += smoothstep(pixelNoiseChange, 0, noise);

			    o.Albedo = heightLine;
            #endif
        }   
        ENDCG
    }
    FallBack "Diffuse"
}
