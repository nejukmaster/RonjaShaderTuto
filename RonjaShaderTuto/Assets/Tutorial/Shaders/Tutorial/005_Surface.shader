Shader "Custom/005_Surface" {
	Properties{
		_Color("Tint", Color) = (0, 0, 0, 1)
		_MainTex("Texture", 2D) = "white" {}
	}
	SubShader{
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry"}

		CGPROGRAM

		//빛을 올바르게 처리하게 하기위해 pragma명령문으로 셰이더의 종류와 이름, 조명모델을 지정해줍니다.
		#pragma surface surf Standard fullforwardshadows

		sampler2D _MainTex;
		fixed4 _Color;

		//표면 쉐이더에 사용될 새로운 구조체 Input을 정의합니다. 이는 표면 쉐이더의 입력으로 사용됩니다.
		struct Input {
			//uv_MainTex는 _MainTex의 UV데이터와 타일링및 오프셋데이터를 가져옵니다. 이름이 다를경우, uvTextureName함수를 사용해 직접 추가해줍니다.
			float2 uv_MainTex;
		};

		//표면 쉐이더
		//표면 쉐이더의 결과를 반환하기위해 SurfaceOutputStandard를 inout형태로 받습니다. 이를 수정하는 형식으로 값 반환을 진행할 예정입니다.
		void surf(Input i, inout SurfaceOutputStandard o) {
			fixed4 col = tex2D(_MainTex, i.uv_MainTex);
			col *= _Color;
			o.Albedo = col.rgb;
		}
		ENDCG
	}
	FallBack "Standard"
}
