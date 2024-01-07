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
                //오브젝트 공간의 정점 좌표를 저장
                o.localPosition = v.vertex;
                //카메라 포지션을 오브젝트 공간으로 변환
                float4 objectSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                //오브젝트 공간에서의 viewDirection
                o.viewDirection = v.vertex - objectSpaceCameraPos;
                return o;
            }

            //3차원 구 SDF
            float scene(float3 pos){
                return length(pos) - 0.5;
            }

            //추적 스텝
            #define MAX_STEPS 10
            //광선이 SDF의 표면을 인식할 최소거리
            #define THICKNESS 0.01

            fixed4 frag (v2f i) : SV_Target
            {
                //광선의 정보
                float3 pos = i.localPosition;
                float3 dir = normalize(i.viewDirection.xyz);
    
                //광선 진행도
                float progress = 0;
    
                //tracing loop
                for (uint iter = 0; iter < MAX_STEPS; iter++) {
                    //진행도에 따른 현재 정점
                    float3 samplePoint = pos + dir * progress;
                    //SDF계산
                    //3차원 구 SDF가 나타내는 값은 원점으로부터의 거리이며,
                    //scene함수는 반지름이 0.5로 설정되어 있기 때문에,
                    //현재 정점 samplePoint가 오브젝트 공간에서의 원점(origin)으로 부터
                    //0.5이상 떨어져있을경우 양수값
                    //그렇지 않을 경우 음수값을 갖게 된다.
                    float distance = scene(samplePoint);
                    //return color if inside shape
                    if(distance < THICKNESS){
                        return _Color;
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
