Shader "Tutorial/039_ScreenSpaceTexture"
{
    Properties
    {
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //��ũ�������ǿ��� w������ ���� uv�� ���ϴ� ������ GPU���� �����ϴ� ���ٺ����� �����ϱ� �����̴�.
                float2 uv = i.screenPos.xy/i.screenPos.w;
                //_ScreenParams�� ���� ���� �ؽ����� ��Ⱦ�� ����ִ�.
                float aspect = _ScreenParams.x / _ScreenParams.y;
                //�ְ��� �����ϱ� ���� Ⱦ���⿡ ��Ⱦ�� �����ش�.
                uv.x = uv.x * aspect;
                //_MainTex�� Ÿ�ϸ��� �������� ����
                uv = TRANSFORM_TEX(uv, _MainTex);
                // sample the texture
                fixed4 col = tex2D(_MainTex, uv);
                return col;
            }
            ENDCG
        }
    }
}