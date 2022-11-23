Shader "Tutorial/012_Fresnel"
{
    Properties
    {
        _Color ("Color", Color) = (0,0,0,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
        [HDR] _Emission("Emission", color) = (0,0,0)

        _FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        [PowerSlider(4)] _FresnelExponent("Fresnel Exponent", Range(0.25,4)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            //각 정점의 월드 노멀 벡터
            float3 worldNormal;
            //각정점의 카메라 뷰 벡터
            float3 viewDir;
            INTERNAL_DATA
        };

        half _Smoothness;
        half _Metallic;
        fixed4 _Color;
        half3 _Emission;

        float3 _FresnelColor;
        //프레넬 강도
        float _FresnelExponent;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;

            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            c = c * _Color;
            o.Albedo = c.rgb;

            //광원이 카메라에 있다고 가정하여 계산
            float3 fresnel = dot(IN.worldNormal, IN.viewDir);

            //saturate(value): value가 0이하면 0, 1이상이면 1, 그 사이면 value값 반환
            //fresnel을 1에서 빼주면 광원이 오브젝트 기준으로 카메라 정 반대편에 있는 효과를 낼수 있다.
            fresnel = saturate(1-fresnel);

            //프레넬 강도 적용
            fresnel = pow(fresnel, _FresnelExponent);

            //계산한 프레넬을 색상에 적용
            float3 fresnelColor = _FresnelColor * fresnel;

            o.Emission = _Emission + fresnelColor;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
