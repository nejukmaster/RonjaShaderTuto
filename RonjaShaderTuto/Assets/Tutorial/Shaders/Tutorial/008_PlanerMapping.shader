Shader "Tutorial/008_PlanerMapping"
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

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct appdata
            {
                //텍스쳐를 직접 매핑하기위해 UV좌표를 지워줍니다.
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = v.vertex.xz;
                //직접 매핑한 uv에 MainTex의 offset과 tiling을 적용하기위해 TRANSFORM_TEX매크로를 적용
                //o.uv = TRANSFORM_TEX(v.vertex.xz, _MainTex);
                //각 버텍스의 글로벌좌표를 구하기위해 worldPosition과 mul연산을 한다. 이에대해선 나중에 다시 다루기로 한다.
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(worldPos.xz, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
