Shader "Tutorial/007_Sprite"
{
    Properties
    {
        _Color("Tint", Color) = (0,0,0,1)
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags{
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha

        ZWrite Off

        //Cull : 컬링. 보는 방향과 반대면의 폴리곤을 최적화해준다.
        //스프라이트는 뒷면을 가지지 않으므로 컬링을 사용할 필요가 없다.
        //컬링 전문: https://docs.unity3d.com/kr/530/Manual/SL-CullAndDepth.html
        Cull Off

        LOD 100

        Pass
        {
			CGPROGRAM

			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			sampler2D _MainTex;
			float4 _MainTex_ST;

			fixed4 _Color;

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				//버텍스 컬러를 사용하기 위해 color속성 추가
				float4 color : COLOR;
			};

			struct v2f {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
			};

			v2f vert(appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed4 col = tex2D(_MainTex, i.uv);
				//버텍스 컬러에 커스텀색상을 적용하여 픽셀에 적용
				col *= (_Color * i.color);
				return col;
			}
            ENDCG
        }
    }
}
