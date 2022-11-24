Shader "Tutorial/009_ColorInterpolation"
{
    Properties
    {
        _Color("Color", Color) = (0,0,0,1)
        _Secondary("Seconde Color", Color) = (0,0,0,1)
        _Blend("Blend Value", Range(0,1)) = 0
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //두 색상의 반영정도를 설정할 변수 Blend
            float _Blend;

            fixed4 _Color;
            fixed4 _Secondary;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //선형 보간 직접구현
                //fixed4 col = _Color * (1-_Blend) + _Secondary * _Blend;
                //lerp(색상1,색상2,보간값)사용: 위의 코드와 같은 결과
                fixed4 col = lerp(_Color, _Secondary, _Blend);
                return col;
            }
            ENDCG
        }
    }
}
