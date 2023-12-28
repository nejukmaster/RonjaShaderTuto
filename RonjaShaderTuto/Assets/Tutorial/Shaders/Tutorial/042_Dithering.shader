Shader"Tutorial/042_Dithering"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _DitherPattern ("DitheringPattern", 2D) = "white"{}
        _Color1 ("Dither Color 1", Color) = (0, 0, 0, 1)
        _Color2 ("Dither Color 2", Color) = (1, 1, 1, 1)
        _MaxDistance("Max Distance", Range(0,10)) = 10
        _MinDistance("Min Distance", Range(0,10)) = 5
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _DitherPattern;
            float4 _DitherPattern_TexelSize;

            float4 _Color1;
            float4 _Color2;

            float _MaxDistance;
            float _MinDistance;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float texColor = tex2D(_MainTex, i.uv).r;
    
                //디더링 값 계산
                //디더링 계산은 UV가 아닌 스크린 스페이스 좌표를 통해 이뤄집니다.
                float2 screenPos = i.screenPosition.xy/i.screenPosition.w;
                float2 ditherCoordinate = screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
                float ditherValue = tex2D(_DitherPattern, ditherCoordinate).r;
                
                /*
                //디더링 값과 비교하여 메인텍스쳐를 스테핑
                float ditheredValue = step(ditherValue, texColor);
                //음영값 보간
                float4 col = lerp(_Color1, _Color2, ditheredValue);
                return col;
                */
                
                //페이드 디더
                //
                float relDistance = i.screenPosition.w;
                relDistance = relDistance - _MinDistance;
                relDistance = relDistance / (_MaxDistance - _MinDistance);  
                clip(relDistance - ditherValue);
                return texColor;
            }
            ENDCG
        }
    }
}
