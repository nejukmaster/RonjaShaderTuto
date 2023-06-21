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
            //Cell�� ��ġ�� fragment�� Cell���� ��ġ��
			float fraction = frac(value);
            //�� ��ĩ���� ��ȭ
			float interpolator = easeInOut(fraction);
            
            //���� Cell�� ����. ������ ������ �پ�ȭ �ϱ����� ������ ������ -1~1���̷� ����
			float previousCellInclination = rand1dTo1d(floor(value)) * 2 - 1;
            //���⿡ ���� ���� ��ġ�� �Լ���
			float previousCellLinePoint = previousCellInclination * fraction;

			float nextCellInclination = rand1dTo1d(ceil(value)) * 2 - 1;
            //���� ������ ��Ī���� �̷�������ϹǷ�, y�� ���� ���� ��Ī�� ������ ���� Cell�� �Լ����� �����ش�.
			float nextCellLinePoint = nextCellInclination * (fraction - 1);
    
            //����
			return lerp(previousCellLinePoint, nextCellLinePoint, interpolator);
		}

        float perlinNoise(float2 value){
            //2���� PerlinNoise�� 2���� ValueNoise�� ���������� Ÿ�� ���� ������ �װ��� ���� ���ø��� �� �� ���̸� �����Ͽ� ���Ѵ�.
			//���� �ϴ� ���� 2���� ����
			float2 lowerLeftDirection = rand2dTo2d(float2(floor(value.x), floor(value.y))) * 2 - 1;
            //���� �ϴ� ���� 2���� ����
			float2 lowerRightDirection = rand2dTo2d(float2(ceil(value.x), floor(value.y))) * 2 - 1;
            //���� ��� ���� 2���� ����
			float2 upperLeftDirection = rand2dTo2d(float2(floor(value.x), ceil(value.y))) * 2 - 1;
            //���� ��� ���� 2���� ����
			float2 upperRightDirection = rand2dTo2d(float2(ceil(value.x), ceil(value.y))) * 2 - 1;

            //��ĩ��
			float2 fraction = frac(value);

			//2���� ������ �Լ����� �������� ���Ѵ�.
            //���� �ϴ� �������� �Լ���
			float lowerLeftFunctionValue = dot(lowerLeftDirection, fraction - float2(0, 0));
            //���� �ϴ� �������� �Լ���
			float lowerRightFunctionValue = dot(lowerRightDirection, fraction - float2(1, 0));
            //���� ��� �������� �Լ���
			float upperLeftFunctionValue = dot(upperLeftDirection, fraction - float2(0, 1));
            //���� ��� �������� �Լ���
			float upperRightFunctionValue = dot(upperRightDirection, fraction - float2(1, 1));

            //x������ ��ȭ
			float interpolatorX = easeInOut(fraction.x);
            //y������ ��ȭ
			float interpolatorY = easeInOut(fraction.y);

			//��,�Ʒ� �ֳ��� ���� ����
			float lowerCells = lerp(lowerLeftFunctionValue, lowerRightFunctionValue, interpolatorX);
			float upperCells = lerp(upperLeftFunctionValue, upperRightFunctionValue, interpolatorX);
            
            //��, �Ʒ� ����
			float noise = lerp(lowerCells, upperCells, interpolatorY);
			return noise;
		}
    
        //3���� PerlinNoise ���� 3���� ValueNoiseó�� �������ش�.
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
                //noise�� ���� 0~1�� �����ϱ� ���� 0.5�� �����ش�.
                float noise = perlinNoise(value) + 0.5;
                o.Albedo = noise;
            #elif _NOISEDEMENSION_3D
                float3 value = IN.worldPos / _CellSize;
                float noise = perlinNoise(value) + 0.5;

                o.Albedo = noise;
            #elif _NOISEDEMENSION_SPECIAL
                float3 value = IN.worldPos / _CellSize;
                //�Է°��� y���� �ð������� ���Ƿ� ��ȯ
			    value.y += _Time.y * _ScrollSpeed;
                
			    float noise = perlinNoise(value) + 0.5;
                //noise�� �� ������ �׶��̼� ����
			    noise = frac(noise * 6);
                //noise�� ��ȭ���� �����մϴ�.
			    float pixelNoiseChange = fwidth(noise);
                //��迡�� 1�ȼ��̻� ������ ���� 0�� ��ȯ �������� �ִ��� 1�� ���� ����
			    float heightLine = smoothstep(1-pixelNoiseChange, 1, noise);
                //�������� ���� �κп� ���� �߰����� ������ �����Ͽ� ���� 1�� ����
			    heightLine += smoothstep(pixelNoiseChange, 0, noise);

			    o.Albedo = heightLine;
            #endif
        }   
        ENDCG
    }
    FallBack "Diffuse"
}