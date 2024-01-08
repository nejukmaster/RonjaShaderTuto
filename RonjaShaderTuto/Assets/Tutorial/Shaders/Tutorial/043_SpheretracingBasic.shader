Shader"Tutorial/043_SpheretracingBasic"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float4 localPosition : TEXCOORD0;
                float4 viewDirection : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                //������Ʈ ������ ���� ��ǥ�� ����
                o.localPosition = v.vertex;
                //ī�޶� �������� ������Ʈ �������� ��ȯ
                float4 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                //������Ʈ ���������� viewDirection
                o.viewDirection = v.vertex - objectSpaceCameraPos;
                return o;
            }

            //3���� �� SDF
            float scene(float3 pos){
                return length(pos) - 0.5;
            }

            //���� ����
            #define MAX_STEPS 10
            //������ SDF�� ǥ���� �ν��� �ּҰŸ�
            #define THICKNESS 0.01

            fixed4 frag (v2f i) : SV_Target
            {
                //������ ����
                float3 pos = i.localPosition;
                float3 dir = normalize(i.viewDirection.xyz);
    
                //���� ���൵
                float progress = 0;
    
                //tracing loop
                for (uint iter = 0; iter < MAX_STEPS; iter++) {
                    //���൵�� ���� ���� ����
                    float3 samplePoint = pos + dir * progress;
                    //SDF���
                    //3���� �� SDF�� ��Ÿ���� ���� �������κ����� �Ÿ��̸�,
                    //scene�Լ��� �������� 0.5�� �����Ǿ� �ֱ� ������,
                    //���� ���� samplePoint�� ������Ʈ ���������� ����(origin)���� ����
                    //0.5�̻� ������������� �����
                    //�׷��� ���� ��� �������� ���� �ȴ�.
                    float distance = scene(samplePoint);
                    //return color if inside shape
                    if(distance < THICKNESS){
                        return _Color;
                    }
                    //������ ����
                    progress = progress + distance;
                }
                //�������� ���� ������ �κ��� �ȼ��� �����ϴ�.
                clip(-1);
                return 0;
            }
            ENDCG
        }
    }
}