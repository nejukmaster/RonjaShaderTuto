Shader"Tutorial/023_BlurPostprocessingEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("Blur Size",Range(0,0.1)) = 0
        //���ø� ���� �����ϴ� Enum ������Ƽ ����
        [KeywordEnum(Low, Medium, High)] _Samples ("Sample amount", Float) = 0
        //����ž� ������ �Ѱ� �� ������Ƽ ����
        [Toggle(GAUSS)] _Gauss ("Gaussian Blur", float) = 0
        _StandardDeviation("Standard Deviation (Gauss only)", Range(0, 0.1)) = 0.02
    }
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        //y�� ���� �ڽ����� �н�
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //multi_compile Ű����� Enum ������Ƽ�� ���¸� �������� ���ǰ� �����ϸ�, �̸��� �빮�ڷ� (������Ƽ�̸�)_(�����̸�)���� �Ѵ�.
            #pragma multi_compile _SAMPLES_LOW _SAMPLES_MEDIUM _SAMPLES_HIGH
            //shader_feature Ű����� multi_compile�� ���������� ������Ƽ�� ���¸� �������� ����������, ���� ����� ������ ���� ���´� �������� �ʽ��ϴ�.
            //���� ������ ���� ���¸��� �Է����ִ� ��쵵 �ֽ��ϴ�.
            #pragma shader_feature GAUSS
            //����þ� ������ ����� �������� �ڿ������ ����
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
            //������ �ڽ�ũ��
            float _BlurSize;
            float _StandardDeviation;
            //multicompile���� Enum�� ������Ƽ ���� ���� �ϳ��� ���ǵǹǷ�, �� Enum������ ������ �������� SAMPLES�� �Ҵ��Ѵ�.
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
                //����þ� �Լ��� ����ϱ����ؼ� ǥ�������� ������ �ϹǷ� ǥ�������� 0�ϰ�� ����þ� ������ �������� �ʽ��ϴ�.
                #if GAUSS
                    if(_StandardDeviation == 0)
                        return tex2D(_MainTex, i.uv);
                #endif
                //init color variable
                float4 col = 0;
                //���������� ����� ���Ҷ� ���� ������ sum�� �������ݴϴ�.
                //�Ϲ����� �ڽ��������� ���ü��� ������ ������ ����þ� �������� ����ġ�� ������ ������� �ϹǷ� sum�� �ʱ�ȭ �Ͽ� ����ġ�� ���ؼ� �������ݴϴ�.
                #if GAUSS
                    float sum = 0;
                #else
                    float sum = SAMPLES;
                #endif
                //���Ϸ��� �ڽ������� �ڽ� ũ�⸸ŭ�� ������ ��ȸ�ϸ� col�� ���� ���մϴ�.
                for (float index = 0; index < SAMPLES; index++)
                {
                    //������ ������ Ÿ�� �ȼ��� ���� ����� ��ġ
                    float offset = (index / (SAMPLES - 1) - 0.5) * _BlurSize;
                    //�ڽ� ������ Ÿ�� �ȼ��� �߽����� �ϴ� �簢�� �ȼ����� �� ����� Ÿ�� �ȼ��� ��ȯ�ϴ� �����̹Ƿ� ������ ������ Ÿ�� �ȼ��� ���� ����� ��ġ�� Ÿ���ȼ� uv�� ���Ͽ� ���� ��ǥ�� ������ ���� ��´�.
                    float2 uv = i.uv + float2(0, offset);
                    #if !GAUSS
                        col += tex2D(_MainTex, uv);
                    #else
                        //ǥ�������� ������ ���մϴ�.
                        float stDevSquared = _StandardDeviation * _StandardDeviation;
                        //����þ� ���Ŀ� ���� ����ġ�� ���մϴ�.
                        float gauss = (1 / sqrt(2 * PI * stDevSquared)) * pow(E, -((offset * offset) / (2 * stDevSquared)));
                        //����ġ�� �����մϴ�.
                        sum += gauss;
                        //�� �ȼ��� ����ġ�� �����ݴϴ�.
                        col += tex2D(_MainTex, uv) * gauss;
                    #endif
                }
                //���� ���� ����� �����ݴϴ�.
                col = col / sum;
                return col;
            }
            ENDCG
        }
        //x�� ���� �ڽ����� �н�
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
                    //invAspect�� ��Ⱦ���� ������ ��ȯ�Ͽ� y��� offset�� ������ �����ݴϴ�.
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