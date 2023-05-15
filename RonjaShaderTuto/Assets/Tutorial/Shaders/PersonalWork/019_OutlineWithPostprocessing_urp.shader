Shader "Tutorial/019_OutlineWithPostprocessing_urp"
{
    Properties
    {
        [HideInInspector] _MainTex("Texture", 2D) = "white" {}
        _OutlineColor("Outline Color",Color) = (0,0,0,1)
    }
        SubShader
    {
        //포스트 프로세싱에 사용될 머티리얼은 항상 마지막에 적용되는 것처럼 해야하므로 Cull과 Zwrite를 끄고 ZTest를 항상 사용해준다.
        //Cull : 컬링. 보는 방향과 반대면의 폴리곤을 최적화해준다.
        Cull Off
        Zwrite Off
        ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                half3 normal : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float2 _MainTex_TexelSize;
            float4 _MainTex_ST;

            half4 _OutlineColor;

            void Compare(inout float depthOutline, inout float normalOutline,
                float baseDepth, float3 baseNormal, float2 uv, float2 offset) {
                //인접 픽셀의 DepthNormal을 읽어온다.
                float3 neighborNormal = SampleSceneNormals(uv + _MainTex_TexelSize.xy * offset);
                float neighborDepth = SampleSceneDepth(uv + _MainTex_TexelSize.xy * offset);

                //노말벡터에 따른 외곽선
                float3 normalDifference = baseNormal - neighborNormal;
                normalDifference = normalDifference.r + normalDifference.g + normalDifference.b;
                normalOutline = normalOutline + normalDifference;

                float3 depthDifference = baseDepth - neighborDepth;
                depthOutline = depthOutline + depthDifference;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = v.normal;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // sample the texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                float3 normal = SampleSceneNormals(i.uv);
                float depth = depth = SampleSceneDepth(i.uv);
                float normalDifference = 0;
                float depthDifference = 0;

                Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(1, 0));
                Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(0, 1));
                Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(0, -1));
                Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(-1, 0));

                normalDifference = saturate(normalDifference);
                depthDifference = saturate(depthDifference);

                float outline = (normalDifference + depthDifference)/2;

                float4 color = lerp(col, _OutlineColor, outline);
                
                return  color;
            }
            ENDHLSL
        }
    }
}
