Shader "Unlit/ScreenWave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SinProgress("Sin Progress",Range(0,100)) = 0
        _WaveSize("Wave Size",Range(0,100)) = 5
        _WavePeriod("Wave Period", Range(1,100)) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;

            float _SinProgress;
            float _WaveSize;
            float _WavePeriod;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + _WaveSize * _MainTex_TexelSize * float2(0,sin( _WavePeriod *i.uv.x + _SinProgress)));
                return col;
            }
            ENDHLSL
        }
    }
}
