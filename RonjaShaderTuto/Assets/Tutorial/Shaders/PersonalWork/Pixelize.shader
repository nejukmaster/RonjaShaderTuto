Shader "Hidden/Pixelize"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _OutlineColor("Outline Color",Color) = (0.0,0.0,0.0,1.0)

        _NormalMult("Normal Outline Multiplier", Range(0,4)) = 1
        _NormalBias("Normal Outline Bias", Range(1,10)) = 1
        _DepthMult("Depth Outline Multiplier", Range(0,4)) = 1
        _DepthBias("Depth Outline Bias", Range(1,10)) = 1
    }

        SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        HLSLINCLUDE
        #pragma vertex vert
        #pragma fragment frag

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionHCS : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        //텍스쳐 오브젝트를 로드합니다.
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        float4 _MainTex_TexelSize;
        float4 _MainTex_ST;
        float _NormalMult;
        float _NormalBias;
        float _DepthMult;
        float _DepthBias;

        half4 _OutlineColor;

        //샘플러 선언
        SamplerState sampler_point_clamp;

        uniform float2 _BlockCount;
        uniform float2 _BlockSize;
        uniform float2 _HalfBlockSize;


        Varyings vert(Attributes IN)
        {
            Varyings OUT;
            OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
            return OUT;
        }

        ENDHLSL

        Pass
        {
            Name "Pixelation"

            HLSLPROGRAM

            void Compare(inout float depthOutline, inout float normalOutline,
                    float baseDepth, float3 baseNormal, float2 uv, float2 offset) {
                float3 neighborNormal = SampleSceneNormals(uv + _BlockSize.xy * offset);
                float neighborDepth = SampleSceneDepth(uv + _BlockSize.xy * offset);

                float3 normalDifference = baseNormal - neighborNormal;
                normalDifference = normalDifference.r + normalDifference.g + normalDifference.b;
                normalOutline = normalOutline + normalDifference;

                float3 depthDifference = baseDepth - neighborDepth;
                depthOutline = depthOutline + depthDifference;
            }

            half4 frag(Varyings IN) : SV_TARGET
            {
                float2 blockPos = floor(IN.uv * _BlockCount);
                float2 blockCenter = blockPos * _BlockSize + _HalfBlockSize;

                half4 tex = half4(0, 0, 0, 1);

                int a = 0;
                for (int i = 0; i < _BlockSize.x / _MainTex_TexelSize.x; i++) {
                    for (int j = 0; j < _BlockSize.y / _MainTex_TexelSize.y; j++) {
                        tex = tex + SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, blockPos * _BlockSize + _MainTex_TexelSize * float2(i, j));
                        a++;
                    }
                }

                tex = tex / a;


                //로딩한 텍스쳐를 샘플링합니다.
                //SAMPLE_TEXTURE2D(텍스쳐 오브젝트, 샘플러, uv)
                //float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, blockCenter);
                //return float4(IN.uv,1,1);

                float3 normal = SampleSceneNormals(blockCenter);
                float depth = depth = SampleSceneDepth(blockCenter);
                float normalDifference = 0;
                float depthDifference = 0;

                Compare(depthDifference, normalDifference, depth, normal, blockCenter, float2(1, 0));
                Compare(depthDifference, normalDifference, depth, normal, blockCenter, float2(0, 1));
                Compare(depthDifference, normalDifference, depth, normal, blockCenter, float2(0, -1));
                Compare(depthDifference, normalDifference, depth, normal, blockCenter, float2(-1, 0));

                normalDifference = normalDifference * _NormalMult;
                normalDifference = saturate(normalDifference);
                normalDifference = pow(normalDifference, _NormalBias);

                depthDifference = depthDifference * _DepthMult;
                depthDifference = saturate(depthDifference);
                depthDifference = pow(depthDifference, _DepthBias);

                float outline = (normalDifference + depthDifference);

                float4 color = lerp(tex, _OutlineColor, outline);
                return color;
            }
            ENDHLSL
        }
    }
}