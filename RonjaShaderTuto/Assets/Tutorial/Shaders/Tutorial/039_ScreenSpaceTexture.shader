Shader "Tutorial/039_ScreenSpaceTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //스크린포지션에서 w값으로 나눠 uv를 구하는 이유는 GPU에서 실행하는 원근보정에 대응하기 위함이다.
                float2 uv = i.screenPos.xy/i.screenPos.w;
                //_ScreenParams는 현재 랜더 텍스쳐의 종횡비를 담고있다.
                float aspect = _ScreenParams.x / _ScreenParams.y;
                //왜곡을 방지하기 위해 횡방향에 종횡비를 곱해준다.
                uv.x = uv.x * aspect;
                //_MainTex의 타일링과 오프셋을 적용
                uv = TRANSFORM_TEX(uv, _MainTex);
                // sample the texture
                fixed4 col = tex2D(_MainTex, uv);
                return col;
            }
            ENDCG
        }
    }
}
