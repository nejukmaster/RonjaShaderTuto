Shader "Unlit/GodRay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _LightShaftValue("Light Shaft Value",Vector) = (1,1,1,1)
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _SceneRenderTexture;

            float4 _LightShaftValue;

            float4 psLightShaft(float2 texCoord : TEXCOORD0) : COLOR0{
                #define NUM_SAMPLES 64

                float4 lightPos = unity_LightPosition[0];

                float2 DeltaTexCoord = (texCoord.xy - lightPos.xy);

                DeltaTexCoord *= 1.0/NUM_SAMPLES * _LightShaftValue.x;

                float3 Color = tex2D(_SceneRenderTexture,texCoord);

                float IlluminationDecay = 1.0;

                for(int i = 0; i < NUM_SAMPLES; i ++){
                    texCoord -= DeltaTexCoord;

                    float3 Sample = tex2D(_MainTex,texCoord);

                    Sample *= IlluminationDecay * _LightShaftValue.z;

                    Color +=  Sample;

                    IlluminationDecay *= _LightShaftValue.y;
                }
                return saturate(float4(Color * _LightShaftValue.w,1.0));

            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_SceneRenderTexture, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return psLightShaft(i.uv);
            }
            ENDCG
        }
    }
}
