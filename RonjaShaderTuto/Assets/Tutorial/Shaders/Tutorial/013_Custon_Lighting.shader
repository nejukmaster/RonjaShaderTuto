Shader "Tutorial/013_Custon_Lighting"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        _Ramp("Ramp",2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 200

        CGPROGRAM
        #pragma surface surf Custom fullforwardshadows

        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _Ramp;

        //light하나당 한번씩 실행될 라이팅 메소드 입니다.
        //메소드의 이름은 Light(surface 정의에서 정의된 이름)을 사용해야합니다.
        float4 LightingCustom(SurfaceOutput s, float3 lightDir, float atten) {
            //normal방향의 light의 양을 계산
            float towardsLight = dot(s.Normal, lightDir);
            //towardsLight의 값을 -1~1사이에서 0~1사이로 조정
            towardsLight = towardsLight * 0.5 + 0.5;

            //Ramp텍스쳐의 (towardsLight,towardsLight)부분의 픽셀의 RGB를 가져옴
            float3 lightIntensity = tex2D(_Ramp, towardsLight).rgb;

            float4 col;
            //s.Albedo : 각픽셀의 알베도값
            //atten : 각 픽셀에 진 그림자의 값
            //_LightColor0 : light의 색상을 가져온다
            float a = atten * 0.5 + 0.5;
            col.rgb = lightIntensity * s.Albedo * a * _LightColor0.rgb;

            col.a = s.Alpha;
            return col;
        }

        struct Input
        {
            float2 uv_MainTex;
        };

        fixed4 _Color;

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
        }
        ENDCG
    }
    FallBack "Standard"
}
