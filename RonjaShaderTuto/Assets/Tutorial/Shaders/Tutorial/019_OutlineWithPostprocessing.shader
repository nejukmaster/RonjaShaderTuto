Shader "Tutorial/019_OutlineWithPostprocessing"
{
    Properties
    {
        [HideInInspector] _MainTex("Texture", 2D) = "white" {}
        //법선 윤곽선의 승수:법선 윤곽선의 또렷한 정도
        _NormalMult ("Normal Outline Multiplier", Range(0,4)) = 1
        //법선 윤곽선의 편향:법선 윤곽선 주변 회색부분의 정도
        _NormalBias ("Normal Outline Bias", Range(1,4)) = 1
        //깊이 윤곽선의 승수:깊이 윤곽선의 또렷한 정도
        _DepthMult ("Depth Outline Multiplier", Range(0,4)) = 1
        //깊이 윤곽선의 편향:깊이 윤곽선 주변 회색부분의 정도
        _DepthBias ("Depth Outline Bias", Range(1,4)) = 1

        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        
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
            sampler2D _CameraDepthNormalsTexture;
            float4 _MainTex_ST;
            //이 변수는 현재 텍스쳐의 텍셀크기를 받아옵니다.
            //후처리를 통한 외곽선을 그릴경우 현재 픽셀과 주변픽셀의 법선과 깊이의 차이를 계산하여 클수록 더 짙은 외곽선을 그리는 방법입니다.
            //이때 사용 되는 각 텍스쳐의 픽셀 크기를 "텍셀(Texel)"이라 합니다.
            float4 _CameraDepthNormalsTexture_TexelSize;

            //variables for customising the effect
            float _NormalMult;
            float _NormalBias;
            float _DepthMult;
            float _DepthBias;

            fixed4 _OutlineColor;

            void Compare(inout float depthOutline, inout float normalOutline, 
                        float baseDepth, float3 baseNormal, float2 uv, float2 offset){
                //인접 픽셀의 DepthNormal을 읽어온다.
                float4 neighborDepthnormal = tex2D(_CameraDepthNormalsTexture, 
                uv + _CameraDepthNormalsTexture_TexelSize.xy * offset);
                float3 neighborNormal;
                float neighborDepth;
                DecodeDepthNormal(neighborDepthnormal, neighborDepth, neighborNormal);
                neighborDepth = neighborDepth * _ProjectionParams.z;

                //깊이에 따른 외곽선
                float depthDifference = baseDepth - neighborDepth;
                depthOutline = depthOutline + depthDifference;

                //노말벡터에 따른 외곽선
                float3 normalDifference = baseNormal - neighborNormal;
                normalDifference = normalDifference.r + normalDifference.g + normalDifference.b;
                normalOutline = normalOutline + normalDifference;
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
                //DepthNormal텍스쳐를 얻어옵니다.
                float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);

                //DepthNormal을 Depth와 Normal로 디코딩합니다.
                float3 normal;
                float depth;
                DecodeDepthNormal(depthnormal, depth, normal);
                
                //각 fragment의 카메라로부터의 깊이를 계산합니다.
                depth = depth * _ProjectionParams.z;

                float depthDifference = 0;
                float normalDifference = 0;

                Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(1, 0));
                Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(0, 1));
                Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(0, -1));
                Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(-1, 0));

                depthDifference = depthDifference * _DepthMult;
                //saturate함수는 값을 0-1사이로 클리핑해준다.
                depthDifference = saturate(depthDifference);
                depthDifference = pow(depthDifference, _DepthBias);

                normalDifference = normalDifference * _NormalMult;
                normalDifference = saturate(normalDifference);
                normalDifference = pow(normalDifference, _NormalBias);

                float outline =  depthDifference + normalDifference;
                float4 sourceColor = tex2D(_MainTex, i.uv);
                float4 color = lerp(sourceColor, _OutlineColor, outline);
                return color;
            }
            ENDCG
        }
    }
}
