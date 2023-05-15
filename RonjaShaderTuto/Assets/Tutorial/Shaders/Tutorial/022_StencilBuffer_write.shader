Shader "Tutorial/022_StencilBuffer_write"
{
    //StencilBuffer는 사용자가 지정하여 버퍼에 임의 값을 넣고 그 값을 쉐이더에서 참조할 수 있습니다.
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        //Stencil에 쓸 값을 정하는 프로퍼티
        [IntRange] _StencilRef("Stencil Reference Value", Range(0,255)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry-1" }
        LOD 100

        Stencil{
            Ref [_StencilRef]
            //Stencil버퍼값과 상관없이 이 쉐이더는 항상 그립니다.
            Comp Always
            //Stencil버퍼에 Ref값을 집어넣습니다.
            Pass Replace
        }

        Pass
        {
            Blend Zero One
            //깊이 버퍼에 이 쉐이더는 표기하지 않습니다.
            ZWrite Off
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

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
                return 0;
            }
            ENDCG
        }
    }
}
