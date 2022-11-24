Shader "Custom/SpecularReflection"
{
    Properties
    {
        _Color ("Color", Color) = (0,0,0,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _LightColor("LightColor", Color) = (1,1,1,1)
        _LightPosition("Light Position", Vector) = (0,1,0)
        _SpecularPower("Specular Range", Range(0.01,1)) = 1
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
            float3 worldNormal;
            float3 worldPos;
            float3 viewDir;
            INTERNAL_DATA
        };

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        fixed4 _LightColor;
        float4 _LightPosition;
        float _SpecularPower;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            o.Alpha = _Color.a;

            fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);

            float3 light = _LightPosition - IN.worldPos;
            light = normalize(light);
            float3 view = normalize(IN.viewDir);
            float3 normal = normalize(IN.worldNormal);
            float d = dot(light, normal);
            float c = saturate(dot(light, normal) + dot(view, normal));
            c = pow(c, _SpecularPower);
            o.Emission = d;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
