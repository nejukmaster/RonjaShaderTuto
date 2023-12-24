Shader "Tutorial/041_HSV"
{
    Properties
    {
        _HueShift("Hue Shift", Range(-1, 1)) = 0
        [PowerSlider(10.0)]_SaturationPower("Saturation Adjustment", Range(10.0, 0.1)) = 1
        [PowerSlider(10.0)]_ValuePower("Value Adjustment", Range(10.0, 0.1)) = 1
        _MainTex ("Texture", 2D) = "white" {}

        
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

            //HSV modification variables
            float _HueShift;
            float _SaturationPower;
            float _ValuePower;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            //HSV 색공간의 색조값(Hue)를 RGB 색상으로 변환하는 함수를 작성
            float3 hue2rgb(float hue)
            {
                hue = frac(hue); //frac함수는 주어진 실수값에 소수점부분을 반환합니다.
                float r = abs(hue * 6 - 3) - 1; //R채널 값 계산
                float g = 2 - abs(hue * 6 - 2); //G채널 값 계산
                float b = 2 - abs(hue * 6 - 4); //B채널 값 계산
                float3 rgb = float3(r,g,b); //모든 채널을 쌓아 RGB값 구성
                rgb = saturate(rgb); //0~1사이로 제한
                return rgb;
            }

            float3 hsv2rgb(float3 hsv)
            {
                float3 rgb = hue2rgb(hsv.x); //hue값을 rgb색상으로 변환
                rgb = lerp(1, rgb, hsv.y); //채도 적용
                rgb = rgb * hsv.z; //명도 적용
                return rgb;
            }

            float3 rgb2hsv(float3 rgb)
            {
                //색조값(Hue) 계산
                float maxComponent = max(rgb.r, max(rgb.g, rgb.b));
                float minComponent = min(rgb.r, min(rgb.g, rgb.b));
                float diff = maxComponent - minComponent;
                float hue = 0;
                if (maxComponent == rgb.r)
                {
                    hue = 0 + (rgb.g - rgb.b) / diff;
                }
                else if (maxComponent == rgb.g)
                {
                    hue = 2 + (rgb.b - rgb.r) / diff;
                }
                else if (maxComponent == rgb.b)
                {
                    hue = 4 + (rgb.r - rgb.g) / diff;
                }
                hue = frac(hue / 6);
    
                //채도값(Saturation) 계산
                float saturation = diff / maxComponent;
    
                //명도값(Value) 계산
                float value = maxComponent;
                return float3(hue, saturation, value);
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
                float3 col = tex2D(_MainTex, i.uv);
                float3 hsv = rgb2hsv(col);
                hsv.x = hsv.x + _HueShift;
                hsv.y = pow(hsv.y, _SaturationPower);
                hsv.z = pow(hsv.z, _ValuePower);
                col = hsv2rgb(hsv);
                return float4(col, 1);
            }
            ENDCG
        }
    }
}
