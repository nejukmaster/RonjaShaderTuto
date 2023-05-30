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
        
        //WhiteNoise ���̴� ��Ŭ��� ������ �����մϴ�.
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
            //������ ���Ϳ� �����մϴ�.
            float random = dot(smallValue, dotDir);
            //frac�Լ��� �Ҽ��� ������ ���ڸ� ��ȯ�մϴ�. (ex)frac(1.12) => 0.12)
            //������ ���� �ؽ��İ� ��带 �����ϹǷ� �������� ���� ���� ��尡 �Ⱥ��̵��� �մϴ�.
            random = frac(sin(random) * 143758.5453);
            return random;
        }
        //�ռ� ���� �Լ��� ������ ȣ���� 3������ ������ ���͸� �̾Ƴ��� �Լ� ����
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
            //_CellSize�� ���� ���� �����Ͽ� _CellSize���� �ȿ��ִ� �ȼ��� ���� ������ ����
            //�̷��� �������� �� ������ ���� ǥ�õ˴ϴ�.
            o.Albedo = rand3dTo3d(floor(IN.worldPos/_CellSize));
        }   
        ENDCG
    }
    FallBack "Diffuse"
}