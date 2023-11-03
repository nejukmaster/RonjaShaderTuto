Shader"Tutorial/040_HalftoneShading"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [HDR] _Emission ("Emission", color) = (0,0,0)
    
        _HalftonePattern("Halftone Pattern",2D) = "white"{}
        _RemapInputMin ("Remap input min value", Range(0, 1)) = 0
        _RemapInputMax ("Remap input max value", Range(0, 1)) = 1
        _RemapOutputMin ("Remap output min value", Range(0, 1)) = 0
        _RemapOutputMax ("Remap output max value", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Halftone fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        fixed4 _Color;
        fixed4 _Emission;

        sampler2D _MainTex;
        sampler2D _HalftonePattern;
        float4 _HalftonePattern_ST;
        float _RemapInputMin;
        float _RemapInputMax;
        float _RemapOutputMin;
        float _RemapOutputMax;
        struct Input
        {
            float2 uv_MainTex;
            float4 screenPos;
        };

        struct HalftoneSurfaceOutput {
            fixed3 Albedo;
            float2 ScreenPos;
            half3 Emission;
            fixed Alpha;
            fixed3 Normal;
        };
        float map(float input, float inMin, float inMax, float outMin,  float outMax){
            float relativeValue = (input - inMin) / (inMax - inMin);
            return lerp(outMin, outMax, relativeValue);
        }
        //our lighting function. Will be called once per light
        float4 LightingHalftone(HalftoneSurfaceOutput s, float3 lightDir, float atten){
            //NdL계산
            float towardsLight = dot(s.Normal, lightDir);
            //0-1범위로 리매핑
            towardsLight = towardsLight * 0.5 + 0.5;

            //감쇠값 곱한후 포화
            float lightIntensity = saturate(atten * towardsLight);

            //하프톤 텍스쳐 샘플링
            float halftoneValue = tex2D(_HalftonePattern, s.ScreenPos).r;

            //계단함수 적용
            lightIntensity = step(halftoneValue, lightIntensity);
    
            halftoneValue = map(halftoneValue, _RemapInputMin, _RemapInputMax, _RemapOutputMin, _RemapOutputMax);
    
            //안티에일리어싱
            float halftoneChange = fwidth(halftoneValue) * 0.5;
            lightIntensity = smoothstep(halftoneValue - halftoneChange, halftoneValue + halftoneChange, lightIntensity);
    
            float4 col;
            //알베도에 빛을 적용
            col.rgb = lightIntensity * s.Albedo * _LightColor0.rgb;
            col.a = s.Alpha;

            return col;
        }


        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout HalftoneSurfaceOutput o)
        {
            fixed4 col = tex2D(_MainTex, IN.uv_MainTex);
			col *= _Color;
			o.Albedo = col.rgb;

			o.Emission = _Emission;
    
            float aspect = _ScreenParams.x / _ScreenParams.y;
            o.ScreenPos = IN.screenPos.xy / IN.screenPos.w;
            o.ScreenPos = TRANSFORM_TEX(o.ScreenPos, _HalftonePattern);
            o.ScreenPos.x = o.ScreenPos.x * aspect;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
