Shader "Custom/006_Basic_Transparent"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        //RenderType을 Transparent로 변경하여 물체가 투명함을 쉐이더에 알려준다.
        //Queue를 재설정하여 일반적인 불투명 물체보단 늦게 랜더링되도록 한다.
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 200

        //블렌드모드 정의
        //블렌드 모드는 이 오브젝트가 다른 오브젝트 앞에 그려질 경우 그 두 픽셀의 색상을 섞는 방법을 정의합니다.
        //Blend (첫번째 인자) (두번째 인자) 명령은 첫번째 인자를 현재 적용된 오브젝트의 색상에 곱하고 두번째인자를 뒤에 있는 오브젝트의 색상에 곱하여 더하여 픽셀을 표시합니다.
        //ScrAlpha:소스의 알파값
        //OneMinusScrAlpha: 1-(소스의 알파값)
        Blend SrcAlpha OneMinusSrcAlpha
        //ZWrite는 불투명객체에서 뒤에 있는 객체에게 이 픽셀위엔 그리지 마라고 전달해주는 역할을 합니다.
        //투명객체는 뒤의 객체를 완전히 가리지는 않으므로 작동하지 않습니다. 리소스를 위해 꺼줍니다.
        ZWrite Off

		//투명객체는 빛과 상관없기때문에 Unlit으로 만들어준다.
		Pass{
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
			};

			struct v2f {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed4 col = tex2D(_MainTex, i.uv);
				col *= _Color;
				return col;
			}

			ENDCG
		}
    }
}
