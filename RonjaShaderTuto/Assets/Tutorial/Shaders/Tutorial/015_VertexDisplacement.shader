Shader "Tutorial/015_VertexDisplacement"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Amplitude("Wave Size", Range(0,1)) = 0.4
        _Frequency("Wave Freqency", Range(1, 8)) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // ? ?? vertex:vert? vert?? ??? ??? ???? ?????.
        // ??? ??? Surface????? ??? ???? ?????? ? ? ????.
        // addshadow? ???? ??????? ??? ?? ???? ?? ?????.
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        fixed4 _Color;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        float _Amplitude;
        float _Frequency;


        // appdata_full? unity? ???? ?? ??????.
        void vert(inout appdata_full data)
        {
            float4 modifiedPos = data.vertex;
            modifiedPos.y += sin(data.vertex.x * _Frequency) * _Amplitude;
            data.vertex = modifiedPos;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
