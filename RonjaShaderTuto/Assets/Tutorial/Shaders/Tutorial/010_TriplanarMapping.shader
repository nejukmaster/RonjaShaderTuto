Shader "Tutorial/010_TriplanarMapping"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Color", Color) = (0,0,0,1)
        //3면 각각의 텍스쳐 매핑에 대한 선명도
        _Sharpness("Blend Sharpness", Range(1, 64)) = 1
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Sharpness;

            struct appdata
            {
                float4 vertex : POSITION;
                //각 버텍스의 법선벡터 NORMAL을 받는 normal을 추가
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 position : SV_POSITION;
                //각 버텍스의 노말을 정규화해서 넘겨줄 예정이다.
                float3 normal : NORMAL;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                //각 버텍스의 글로벌좌표
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                //각 버텍스의 글로벌 좌표를 그대로 반환
                o.worldPos = worldPos;
                //각 버텍스의 글로벌 노말 벡터를 구한다.
                float3 worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                //버텍스의 노말을 정규화
                o.normal = normalize(worldNormal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //각 xyz축의 UV 좌표를 구한다.
                float2 uv_front = TRANSFORM_TEX(i.worldPos.xy, _MainTex);   //z축 기준으로의 UV좌표
                float2 uv_side = TRANSFORM_TEX(i.worldPos.zy, _MainTex);    //x축을 기준으로의 UV좌표
                float2 uv_top = TRANSFORM_TEX(i.worldPos.xz, _MainTex);     //y축을 기준으로의 UV좌표

                //각 UV좌표에 텍스쳐 매핑
                fixed4 col_front = tex2D(_MainTex, uv_front);
                fixed4 col_side = tex2D(_MainTex, uv_side);
                fixed4 col_top = tex2D(_MainTex, uv_top);

                float3 weights = i.normal;
                //절댓값을 취하여 각 노말의 각 성분의 크기만 추출
                //abs(float3(x,y,z)) = float3(|x|,|y|,|z|)
                weights = abs(weights);

                //pos(A,B): A의 B거듭제곱을 반환
                weights = pow(weights, _Sharpness);
                //벡터 weights를 크기가 1인 벡터로 정규화
                weights = weights / (weights.x + weights.y + weights.z);

                //x는 r, y는 g, z는 b 에 대응하여 색상을 곱해준다.
                col_front *= weights.z;
                col_side *= weights.x;
                col_top *= weights.y;

                fixed4 col = (col_front + col_side + col_top);
                return col * _Color;
            }
            ENDCG
        }
    }
}
