Shader "Tutorial/018_PostprocessingWithNormalTexture"
{
    Properties
    {
        [HideInInspector]_MainTex("Texture", 2D) = "white" {}
        _upCutoff ("up cutoff", Range(0,1)) = 0.7
        _topColor ("top color", Color) = (1,1,1,1)
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            //Camera에서 Depth Normal Texture를 가져옵니다.
            sampler2D _CameraDepthNormalsTexture;

            float4x4 _viewToWorld;
            float _upCutoff;
            float4 _topColor;

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
                //depth normal texture를 샘플링
                float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);

                //우리가 유니티 카메라에서 가져온 DepthNormalTexture는 깊이 데이터(float)와 법선데이터(float3)를 전부 가지고있는 이미지이므로 디코딩하여 두개를 분리해주어야합니다.
                float3 normal;
                float depth;
                //DecodeDepthNormal(depthnormal, depth, normal)내장함수는 depthnormal 프래그먼트에서 깊이 데이터와 법선데이터를 분리해 depth와 normal에 넣어준다.
                DecodeDepthNormal(depthnormal, depth, normal);

                depth = depth * _ProjectionParams.z;

                //mul(matrix1,matrix2)는 두 행렬의 행렬곱을 반환합니다.
                //_viewToWorld행렬을 3x3으로 바꾸어 회전에 위치변경이 적용되지 않도록 합니다.
                normal = mul((float3x3)_viewToWorld,normal);
                
                //z축 단위벡터와 normal을 내적하여 위로 향하는 면은 밝게, 그렇지 않은 면은 어둡게 바꿉니다.
                float up = dot(float3(0,1,0),normal);

                up = step(_upCutoff, up);
                float4 source = tex2D(_MainTex, i.uv);
                float4 col = lerp(source, _topColor, up * _topColor.a);

                return col;
            }
            ENDCG
        }
    }
}
