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
                        //오브젝트 공간의 정점 좌표를 저장
            o.localPosition = v.vertex;
                        //카메라 포지션을 오브젝트 공간으로 변환
            float4 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                        //오브젝트 공간에서의 viewDirection
            o.viewDirection = v.vertex - objectSpaceCameraPos;
            return o;
            }

                    //3차원 구 SDF
            float scene(float3 pos)
            {
            return length(pos) - 0.5;
            }

            //SDF의 표면을 미분할때 사용할 엡실론을 정의
            #define NORMAL_EPSILON 0.01
            float3 normal(float3 pos)
            {
                //x축, y축, z축 각각의 표면 미분값을 구함
                //미분값은 현재 좌표 각각의 성분에 엡실론값을 앞뒤로 더하여 SDF값의 차이를 구한다.
                float changeX = scene(pos + float3(NORMAL_EPSILON, 0, 0)) - scene(pos - float3(NORMAL_EPSILON, 0, 0));
                float changeY = scene(pos + float3(0, NORMAL_EPSILON, 0)) - scene(pos - float3(0, NORMAL_EPSILON, 0));
                float changeZ = scene(pos + float3(0, 0, NORMAL_EPSILON)) - scene(pos - float3(0, 0, NORMAL_EPSILON));
                //표면의 노멀벡터를 계산합니다. 노멀 벡터는 각 성분의 미분값의 합벡터로 구성됩니다.
                float3 surfaceNormal = float3(changeX, changeY, changeZ);
                //구한 노멀벡터를 월드스페이스 노멀로 바꾸어줍니다.
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
                        //광선의 정보
                float3 pos = i.localPosition;
                float3 dir = normalize(i.viewDirection.xyz);
    
                            //광선 진행도
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
                                //광선을 진행
                    progress = progress + distance;
                }
                            //추적되지 않은 나머지 부분의 픽셀은 버립니다.
                clip(-1);
                return 0;
            }
            ENDCG
        }
    }
}
