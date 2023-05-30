Shader "Tutorial/024_WhiteNoise"
{
    Properties
    {
        _CellSize("Cell Size", Vector) = (1,1,1,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        
        //WhiteNoise 셰이더 인클루드 파일을 포함합니다.
        #include "WhiteNoise.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float3 worldPos;
        };

        float3 _CellSize;
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)
        /*
        float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)){
            //make value smaller to avoid artefacts
            float3 smallValue = sin(value);
            //임의의 벡터와 내적합니다.
            float random = dot(smallValue, dotDir);
            //frac함수로 소숫점 이하의 숫자를 반환합니다. (ex)frac(1.12) => 0.12)
            //생성된 랜덤 텍스쳐가 밴드를 형성하므로 오프셋을 아주 높여 밴드가 안보이도록 합니다.
            random = frac(sin(random) * 143758.5453);
            return random;
        }
        //앞서 만든 함수를 여러번 호출해 3차원의 랜덤한 벡터를 뽑아내는 함수 생성
        float3 rand3dTo3d(float3 value){
            return float3(
                rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
                rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
                rand3dTo1d(value, float3(73.156, 52.235, 09.151))
            );
        }
        */

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            //_CellSize로 나눈 값을 내림하여 _CellSize범위 안에있는 픽셀은 같은 값으로 매핑
            //이러면 랜덤값이 셀 단위로 같게 표시됩니다.
            o.Albedo = rand3dTo3d(floor(IN.worldPos/_CellSize));
        }   
        ENDCG
    }
    FallBack "Diffuse"
}
