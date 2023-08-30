Shader "Tutorial/031_SinglestepToonShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        [HDR] _Emission("Emission",Color) = (0,0,0,1)

        [Header(Lighting Parameters)]
        _ShadowTint ("Shadow Color", Color) = (0, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        CGPROGRAM
        //우리가 만든 라이팅 함수를 표면 라이팅으로 사용하기위해 Standard -> Stepped로 바꿉니다.
        #pragma surface surf Stepped fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        fixed4 _Color;
        half3 _Emission;
        float3 _ShadowTint;

        //커스텀 표면 라이팅 함수입니다. 함수는 반드시 Lighting[Name]형식으로 선언되어야합니다.
        //Lighting[Name](표면 출력 구조체, 빛의 방향, 카메라 방향, 빛 감쇠)
        float4 LightingStepped(SurfaceOutput s, float3 lightDir, half3 viewDir, float shadowAttenuation){
            float towardsLight = dot(s.Normal, lightDir);
            //step함수는 왼쪽값이 오른쪽값보다 크면 1을 아니면 0을 반환합니다.
            //float lightIntensity = step(0, towardsLight);
            //fwidth는 이웃픽셀과 비교하여 이 변수의 변화율을 반환합니다.
            float towardsLightChange = fwidth(towardsLight);
            float lightIntensity = smoothstep(0, towardsLightChange, towardsLight);
    
#ifdef USING_DIRECTIONAL_LIGHT
            float attenuationChange = fwidth(shadowAttenuation) * 0.5;
            float shadow = smoothstep(0.5 - attenuationChange, 0.5 + attenuationChange, shadowAttenuation);
#else
            float attenuationChange = fwidth(shadowAttenuation);
            float shadow = smoothstep(0, attenuationChange, shadowAttenuation);
#endif
            lightIntensity = lightIntensity * shadow;
    
            float3 shadowColor = s.Albedo * _ShadowTint;
            float4 color;
            color.rgb = lerp(shadowColor, s.Albedo, lightIntensity) * _LightColor0.rgb;
            color.a = s.Alpha;
            return color;
        }

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Emission = _Emission;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
