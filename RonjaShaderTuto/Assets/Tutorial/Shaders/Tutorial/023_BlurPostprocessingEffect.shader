Shader"Tutorial/023_BlurPostprocessingEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("Blur Size",Range(0,0.1)) = 0
        //샘플링 수를 조절하는 Enum 프로퍼티 생성
        [KeywordEnum(Low, Medium, High)] _Samples ("Sample amount", Float) = 0
        //가우신안 블러를 켜고 끌 프로퍼티 생성
        [Toggle(GAUSS)] _Gauss ("Gaussian Blur", float) = 0
        _StandardDeviation("Standard Deviation (Gauss only)", Range(0, 0.1)) = 0.02
    }
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        //y축 방향 박스블러 패스
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //multi_compile 키워드는 Enum 프로퍼티의 상태를 다중으로 정의가 가능하며, 이름은 대문자로 (프로퍼티이름)_(상태이름)으로 한다.
            #pragma multi_compile _SAMPLES_LOW _SAMPLES_MEDIUM _SAMPLES_HIGH
            //shader_feature 키워드는 multi_compile과 마찬가지로 프로퍼티의 상태를 다중으로 정의하지만, 실제 빌드시 사용되지 않은 상태는 포함하지 않습니다.
            //또한 다음과 같이 상태명만 입력해주는 경우도 있습니다.
            #pragma shader_feature GAUSS
            //가우시안 블러를 계산할 원주율과 자연상수를 정의
            #define PI 3.14159265359
            #define E 2.71828182846

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            //블러의 박스크기
            float _BlurSize;
            float _StandardDeviation;
            //multicompile에서 Enum은 프로퍼티 값에 따라 하나만 정의되므로, 각 Enum마다의 정해진 고정값을 SAMPLES에 할당한다.
            #if _SAMPLES_LOW
                #define SAMPLES 10
            #elif _SAMPLES_MEDIUM
                #define SAMPLES 30
            #else
                #define SAMPLES 100
            #endif

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //가우시안 함수를 계산하기위해선 표준편차로 나눠야 하므로 표준편차가 0일경우 가우시안 블러를 실행하지 않습니다.
                #if GAUSS
                    if(_StandardDeviation == 0)
                        return tex2D(_MainTex, i.uv);
                #endif
                //init color variable
                float4 col = 0;
                //마지막으로 평균을 구할때 나눌 변수인 sum을 선언해줍니다.
                //일반적인 박스블러에선 샘플수로 나누면 되지만 가우시안 블러에선 가중치의 합으로 나누어야 하므로 sum을 초기화 하여 가중치를 더해서 저장해줍니다.
                #if GAUSS
                    float sum = 0;
                #else
                    float sum = SAMPLES;
                #endif
                //구하려는 박스블러의 박스 크기만큼의 샘플을 순회하며 col에 값을 더합니다.
                for (float index = 0; index < SAMPLES; index++)
                {
                    //참고할 샘플의 타깃 픽셀에 대한 상대적 위치
                    float offset = (index / (SAMPLES - 1) - 0.5) * _BlurSize;
                    //박스 블러는 타깃 픽셀을 중심으로 하는 사각형 픽셀들의 색 평균을 타깃 픽셀에 반환하는 블러이므로 참고할 샘플의 타깃 픽셀에 대한 상대적 위치를 타깃픽셀 uv에 더하여 얻은 좌표로 샘플의 색을 얻는다.
                    float2 uv = i.uv + float2(0, offset);
                    #if !GAUSS
                        col += tex2D(_MainTex, uv);
                    #else
                        //표준편차의 제곱을 구합니다.
                        float stDevSquared = _StandardDeviation * _StandardDeviation;
                        //가우시안 공식에 따라 가중치를 구합니다.
                        float gauss = (1 / sqrt(2 * PI * stDevSquared)) * pow(E, -((offset * offset) / (2 * stDevSquared)));
                        //가중치를 저장합니다.
                        sum += gauss;
                        //각 픽셀에 가중치를 곱해줍니다.
                        col += tex2D(_MainTex, uv) * gauss;
                    #endif
                }
                //이후 값의 평균을 구해줍니다.
                col = col / sum;
                return col;
            }
            ENDCG
        }
        //x축 방향 박스블러 패스
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _SAMPLES_LOW _SAMPLES_MEDIUM _SAMPLES_HIGH
            #pragma shader_feature GAUSS
            #define PI 3.14159265359
            #define E 2.71828182846

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _BlurSize;
            float _StandardDeviation;
            #if _SAMPLES_LOW
                #define SAMPLES 10
            #elif _SAMPLES_MEDIUM
                #define SAMPLES 30
            #else
                #define SAMPLES 100
            #endif

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                #if GAUSS
                    if(_StandardDeviation == 0)
                        return tex2D(_MainTex, i.uv);
                #endif
                float4 col = 0;
                float invAspect = _ScreenParams.y / _ScreenParams.x;
                #if GAUSS
                    float sum = 0;
                #else
                    float sum = SAMPLES;
                #endif
                for (float index = 0; index < SAMPLES; index++)
                {
                    //invAspect는 종횡비의 역수를 반환하여 y축과 offset의 비율을 맞춰줍니다.
                    float offset = (index / (SAMPLES - 1) - 0.5) * _BlurSize * invAspect;
                    float2 uv = i.uv + float2(offset, 0);
                    #if !GAUSS
                        col += tex2D(_MainTex, uv);
                    #else
                        float stDevSquared = _StandardDeviation * _StandardDeviation;
                        float gauss = (1 / sqrt(2 * PI * stDevSquared)) * pow(E, -((offset * offset) / (2 * stDevSquared)));
                        sum += gauss;
                        col += tex2D(_MainTex, uv) * gauss;
                    #endif
                }
                col = col / sum;
                return col;
            }
            ENDCG
        }
    }
}
