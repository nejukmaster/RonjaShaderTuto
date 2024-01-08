Shader"Tutorial/044_SpheretracingWithShade"
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
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

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

            v2f vert(appdata v)
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
            float scene(float3 pos)
            {
            return length(pos) - 0.5;
            }

            //SDF�� ǥ���� �̺��Ҷ� ����� ���Ƿ��� ����
            #define NORMAL_EPSILON 0.01
            float3 normal(float3 pos)
            {
                //x��, y��, z�� ������ ǥ�� �̺а��� ����
                //�̺а��� ���� ��ǥ ������ ���п� ���Ƿа��� �յڷ� ���Ͽ� SDF���� ���̸� ���Ѵ�.
                float changeX = scene(pos + float3(NORMAL_EPSILON, 0, 0)) - scene(pos - float3(NORMAL_EPSILON, 0, 0));
                float changeY = scene(pos + float3(0, NORMAL_EPSILON, 0)) - scene(pos - float3(0, NORMAL_EPSILON, 0));
                float changeZ = scene(pos + float3(0, 0, NORMAL_EPSILON)) - scene(pos - float3(0, 0, NORMAL_EPSILON));
                //ǥ���� ��ֺ��͸� ����մϴ�. ��� ���ʹ� �� ������ �̺а��� �պ��ͷ� �����˴ϴ�.
                float3 surfaceNormal = float3(changeX, changeY, changeZ);
                //���� ��ֺ��͸� ���彺���̽� ��ַ� �ٲپ��ݴϴ�.
                surfaceNormal = mul(unity_ObjectToWorld, float4(surfaceNormal, 0));
                return normalize(surfaceNormal);
            }

            float4 lightColor(float3 pos)
            {
                float3 surfaceNormal = normal(pos);
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
    
                float lightAngle = saturate(dot(surfaceNormal, lightDirection));
                return lightAngle * _LightColor0;
            }

            float4 material(float3 pos)
            {
                //return final surface color
            }

            #define MAX_STEPS 10
            #define THICKNESS 0.01

            fixed4 frag(v2f i) : SV_Target
            {
                        //������ ����
                float3 pos = i.localPosition;
                float3 dir = normalize(i.viewDirection.xyz);
    
                            //���� ���൵
                float progress = 0;
    
                            //tracing loop
                for (uint iter = 0; iter < MAX_STEPS; iter++)
                {
                    float3 samplePoint = pos + dir * progress;
                    float distance = scene(samplePoint);
                    if (distance < THICKNESS)
                    {
                        return _Color * lightColor(samplePoint);
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