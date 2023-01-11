Shader "Tutorial/014_PolygonClipping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (0,0,0,1)
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

            //외부에서 폴리곤의 수와 그 좌표를 수정할 수 있도록 uniform 변수 추가
            uniform float2 _corners[1000];
            uniform uint _cornerCount;


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float isLeftOfLine(float2 pos, float2 linePoint1, float2 linePoint2) {
                //그리려고 하는 선의 방향벡터
                float2 lineDirection = linePoint2 - linePoint1;
                //선과 직각인 벡터
                float2 lineNormal = float2(-lineDirection.y, lineDirection.x);
                //직선의 시점으로부터 구하고자하는 점에게로의 벡터
                float2 toPos = pos - linePoint1;

                //점으로의 벡터와 법선벡터를 내적
                float side = dot(toPos, lineNormal);
                //step함수: 0보다 작은 값을 0으로 반환
                side = step(0, side);
                return side;
            }

            v2f vert (appdata v)
            {
                v2f o;
                //각 버텍스를 오브젝트 공간에서 클립공간으로 변환
                o.position = UnityObjectToClipPos(v.vertex);
                //각 버텍스의 월드좌표를 계산
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos.xyz;
                return o;
            }

            fixed4 _Color;
            
            fixed4 frag (v2f i) : SV_Target
            {
                float outsideTriangle = 0;

                //HLSL에게 for루프를 사용하라고 명시해주어야 한다.
                [loop]
                for (uint index; index < _cornerCount; index++) {
                    //모든 점에 대해 연산을 반복
                    //인덱스를 초과했을 경우 나머지 연산으로 인덱스를 처음으로 되돌림
                    outsideTriangle += isLeftOfLine(i.worldPos.xy, _corners[index], _corners[(index + 1) % _cornerCount]);
                }

                //clip(value)는 value가 0보다 작은 모든 폴리곤을 버립니다.(랜더링 하지 않습니다.)
                //우리는 outsideTriangle값이 0인, 즉 다각형 내부의 폴리곤만 남기길 원하기 때문에 clip의 인자로 outsideTriangle을 반전시켜 넣어줍니다.
                clip(-outsideTriangle);

                //버려지지 않은 폴리곤은 _Color값을 반환하여 색상을 입혀 줍니다.
                return _Color;
            }
            ENDCG
        }
    }
}
