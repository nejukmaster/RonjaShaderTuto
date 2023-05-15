Shader "Tutorial/021_ClippingModelWithAPlane"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        [HDR]_CutOffColor("Cut Off Color", Color) = (1,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        //컬링 설정(컬링에 대한 설명: https://docs.unity3d.com/kr/530/Manual/SL-CullAndDepth.html)
        Cull Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
            //VFACE변수는 외부의 점일경우 +1, 내부의 점일경우 -1을 제공합니다.
            float facing : VFACE;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float4 _CutOffColor;

        float4 _Plane;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input i, inout SurfaceOutputStandard o)
        {
            //표면 위의 점 i와 평면사이의 거리를 구한다.
            //아래 식은 실제 거리가 아닌 대략적인 변위를 구하는 식이다.
            float distance = dot(i.worldPos, _Plane.xyz);

            //위의 식은 평면이 원점에 있을 경우를 가정한 식이며, 평면의 좌표를 반영하기 위해 미리구성해둔 _Plane에서 원점으로 부터 평면까지의 변위를 불러와 더해준다.
            distance = distance + _Plane.w;

            //clip함수는 주어진 변수가 0보다 작을경우 해당 변수를 폐기합니다.
            clip(-distance);
            o.Emission = distance;

            fixed4 col = tex2D(_MainTex, i.uv_MainTex);
            col *= _Color;
            o.Albedo = col.rgb;
            o.Metallic = _Metallic;
            float facing = i.facing * 0.5 + 0.5;
            o.Emission = lerp(_CutOffColor,col,facing);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
