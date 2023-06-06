Shader"Tutorial/025_ValueNoise"
{
    Properties
    {
        _CellSize("Cell Size", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        #include "WhiteNoise.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float3 worldPos;
        };

        float _CellSize;
        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        //inline���� ���ǵ� �Լ��� ȣ��� ������� �ʰ� ���ڸ����� �ٷ� �����մϴ�.
        //inline�� ���� ����: http://www.tcpschool.com/cpp/cpp_cppFunction_inlineFunction
        //�������� ��ȭ�� easing�Լ� �ۼ�
        //easing�Լ�(��ȭ��)�� ���� ���� : https://ko.wikipedia.org/wiki/%EC%99%84%ED%99%94%EC%9E%90
        inline float easeIn(float interpolator){
            return interpolator * interpolator;
        }
        float easeOut(float interpolator){
            return 1 - easeIn(1 - interpolator);
        }
        float easeInOut(float interpolator){
            float easeInValue = easeIn(interpolator);
            float easeOutValue = easeOut(interpolator);
            return lerp(easeInValue, easeOutValue, interpolator);
        }

        //���� y�� fwidth�� ��ȭ���� ������ �����׳�Ʈ�� y���� ���´�.
        float ValueNoise1d(float value, float y){
            //�� Cell�� ���۵Ǵ� �ȼ��κ��� ����� ���մϴ�.
            float previousCellNoise = rand1dTo1d(floor(value));
            //�� Cell�� ������ �ȼ��κ��� ����� ���մϴ�.
            //ceil�� �ø����� ��ȯ�մϴ�.
            float nextCellNoise = rand1dTo1d(ceil(value));
            //���ڸ� �켱 ��ȭ�մϴ�.
            //frac�� �Ҽ��� ������ ���� ��ȯ�մϴ�.
            float interpolator = frac(value);
            interpolator = easeInOut(interpolator);
            //�� �ȼ��� ��ġ�� �� ���̸� �����մϴ�.
            float noise = lerp(previousCellNoise, nextCellNoise, interpolator);
            //������ 1���� noise�� y���� ��ǥ���� ���� noise = worldPos.y�϶� ���� ��Ӱ��Ͽ� �� ���� ���� �׸���.
            float dist = abs(noise - y);
            //fwidth�� �̿��ȼ����� ��ȭ���� ��ȯ�Ѵ�.
            //����Ƽ ���̴��� fragment ���̴��� ó���Ҷ� 2*2 ������ �ȼ��� ���� ó���ϴµ�, fwidth�� �� ���� ó���Ǵ� �ȼ��� �����ȼ��� ���Ͽ� ��ȭ���� ��ȯ�Ѵ�.
            //���� �Ʒ��� fwidth���� �ȼ��� y�������� �̵��� �ּڰ��� �����Ѵ�.
            float pixelHeight = fwidth(y);
            //�ȼ��� ���̺��� ū ���� 1�� ����ϰ�, �׷��� ������ 0�� ���, ���� ���� ������ ����� �����Ѵ�.
            //�̷��� Ȯ���ص� ������ �ʴ� 1�ȼ�ũ���� ���� ���� �� �ִ�.
            float lineIntensity = smoothstep(0, pixelHeight, dist);
            return lineIntensity;
        }

        //2���� ValueNoise�� �����ϴ� �޼���
        float ValueNoise2d(float2 value){
            //rand2dTo1d�� 024_WhiteNoise�� ������ WhiteNoise.cginc�� ���Ե� �޼���� 2���� ���ͷ� 1������ WhiteNoise�� �����Ѵ�.
            //2������ ValueNoise�� 1������ ValueNoise�� �����ϴ� ������ x,y���� ��� ó�����ش�. (2*2�� ó��)
            float upperLeftCell = rand2dTo1d(float2(floor(value.x), ceil(value.y)));
            float upperRightCell = rand2dTo1d(float2(ceil(value.x), ceil(value.y)));
            float lowerLeftCell = rand2dTo1d(float2(floor(value.x), floor(value.y)));
            float lowerRightCell = rand2dTo1d(float2(ceil(value.x), floor(value.y)));

            float interpolatorX = easeInOut(frac(value.x));
            float interpolatorY = easeInOut(frac(value.y));

            float upperCells = lerp(upperLeftCell, upperRightCell, interpolatorX);
            float lowerCells = lerp(lowerLeftCell, lowerRightCell, interpolatorX);

            float noise = lerp(lowerCells, upperCells, interpolatorY);
            return noise;
        }
        
/*
        //3���� ValueNoise�� �����ϴ� �޼���
        float ValueNoise3d(float3 value){
            float interpolatorX = easeInOut(frac(value.x));
            float interpolatorY = easeInOut(frac(value.y));
            float interpolatorZ = easeInOut(frac(value.z));

            //3���� ValueNoise�� �ռ� ������ 2*2*2�� �����Ѵ�.
            float cellNoiseZ[2];
            //unroll�Ӽ��� ������ �������� �ݺ����� ���ļ� ������ �մϴ�.
            [unroll]
            for(int z=0;z<=1;z++){
                float cellNoiseY[2];
                [unroll]
                for(int y=0;y<=1;y++){
                    float cellNoiseX[2];
                    [unroll]
                    for(int x=0;x<=1;x++){
                        //x�� �������� noise�� �����մϴ�.
                        //float3�� ���� 3d�ȼ��Ӹ��ƴ϶� �ֺ� 2*2*2�� �ȼ��� ���� ����Ͽ� ���� �����ϴ� �뵵�� ����մϴ�.
                        float3 cell = floor(value) + float3(x, y, z);
                        cellNoiseX[x] = rand3dTo1d(cell);
                    }
                    //�� �ȼ��� Cell���� ��ġ������ ����
                    cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                }
                cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
            }
            float noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
            return noise;
        }
        */

        //3ä���� ValueNoise
        float3 ValueNoise3d(float3 value){
            float interpolatorX = easeInOut(frac(value.x));
            float interpolatorY = easeInOut(frac(value.y));
            float interpolatorZ = easeInOut(frac(value.z));

            float3 cellNoiseZ[2];
            [unroll]
            for(int z=0;z<=1;z++){
                float3 cellNoiseY[2];
                [unroll]
                for(int y=0;y<=1;y++){
                    float3 cellNoiseX[2];
                    [unroll]
                    for(int x=0;x<=1;x++){
                        float3 cell = floor(value) + float3(x, y, z);
                        cellNoiseX[x] = rand3dTo3d(cell);
                    }
                    cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                }
                cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
            }
            float3 noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
            return noise;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            //���� ����� ���� �� �ȼ��� Cell�� ��� �κ����� ô���� �������ϹǷ� floor�� ������� �ʽ��ϴ�.
            float3 value = IN.worldPos.xyz / _CellSize;
            float3 noise = ValueNoise3d(value);
            o.Albedo = noise;
        }   
        ENDCG
    }
    FallBack "Diffuse"
}