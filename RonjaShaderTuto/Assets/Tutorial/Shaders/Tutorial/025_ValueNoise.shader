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

        //inline으로 정의된 함수는 호출시 예약되지 않고 그자리에서 바로 실행합니다.
        //inline에 대한 설명: http://www.tcpschool.com/cpp/cpp_cppFunction_inlineFunction
        //보간값을 완화할 easing함수 작성
        //easing함수(완화자)에 대한 설명 : https://ko.wikipedia.org/wiki/%EC%99%84%ED%99%94%EC%9E%90
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

        //인자 y는 fwidth로 변화율을 관찰할 프래그넌트의 y값을 갖는다.
        float ValueNoise1d(float value, float y){
            //이 Cell이 시작되는 픽셀부분의 노이즈를 구합니다.
            float previousCellNoise = rand1dTo1d(floor(value));
            //이 Cell이 끝나는 픽셀부분의 노이즈를 구합니다.
            //ceil은 올림값을 반환합니다.
            float nextCellNoise = rand1dTo1d(ceil(value));
            //인자를 우선 완화합니다.
            //frac은 소수점 이하의 수를 반환합니다.
            float interpolator = frac(value);
            interpolator = easeInOut(interpolator);
            //이 픽셀의 위치로 둘 사이를 보간합니다.
            float noise = lerp(previousCellNoise, nextCellNoise, interpolator);
            //생성한 1차원 noise에 y월드 좌표값을 빼서 noise = worldPos.y일때 가장 어둡게하여 각 셀에 선을 그린다.
            float dist = abs(noise - y);
            //fwidth는 이웃픽셀과의 변화율을 반환한다.
            //유니티 셰이더는 fragment 셰이더를 처리할때 2*2 단위로 픽셀을 병렬 처리하는데, fwidth는 이 병렬 처리되는 픽셀과 현재픽셀을 비교하여 변화율을 반환한다.
            //따라서 아래의 fwidth값은 픽셀이 y방향으로 이동시 최솟값을 리턴한다.
            float pixelHeight = fwidth(y);
            //픽셀의 높이보다 큰 값은 1을 출력하고, 그렇지 않으면 0을 출력, 사이 값은 비율을 계산해 보간한다.
            //이러면 확대해도 변하지 않는 1픽셀크기의 선을 얻을 수 있다.
            float lineIntensity = smoothstep(0, pixelHeight, dist);
            return lineIntensity;
        }

        //2차원 ValueNoise를 생성하는 메서드
        float ValueNoise2d(float2 value){
            //rand2dTo1d는 024_WhiteNoise때 생성한 WhiteNoise.cginc에 포함된 메서드로 2차원 벡터로 1차원의 WhiteNoise를 생성한다.
            //2차원의 ValueNoise는 1차원의 ValueNoise를 생성하는 과정을 x,y값에 모두 처리해준다. (2*2로 처리)
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
        //3차원 ValueNoise를 생성하는 메서드
        float ValueNoise3d(float3 value){
            float interpolatorX = easeInOut(frac(value.x));
            float interpolatorY = easeInOut(frac(value.y));
            float interpolatorZ = easeInOut(frac(value.z));

            //3차원 ValueNoise는 앞선 과정을 2*2*2로 진행한다.
            float cellNoiseZ[2];
            //unroll속성은 컴파일 과정에서 반복문을 펼쳐서 컴파일 합니다.
            [unroll]
            for(int z=0;z<=1;z++){
                float cellNoiseY[2];
                [unroll]
                for(int y=0;y<=1;y++){
                    float cellNoiseX[2];
                    [unroll]
                    for(int x=0;x<=1;x++){
                        //x축 방향으로 noise를 생성합니다.
                        //float3는 현재 3d픽셀뿐만아니라 주변 2*2*2의 픽셀도 같이 계산하여 값을 보간하는 용도로 사용합니다.
                        float3 cell = floor(value) + float3(x, y, z);
                        cellNoiseX[x] = rand3dTo1d(cell);
                    }
                    //각 픽셀의 Cell상의 위치값으로 보간
                    cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                }
                cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
            }
            float noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
            return noise;
        }
        */

        //3채널의 ValueNoise
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
            //선을 만들기 위해 각 픽셀이 Cell의 어느 부분인지 척도를 가져야하므로 floor을 사용하지 않습니다.
            float3 value = IN.worldPos.xyz / _CellSize;
            float3 noise = ValueNoise3d(value);
            o.Albedo = noise;
        }   
        ENDCG
    }
    FallBack "Diffuse"
}
