Shader "Tutorial/011_CheckboardPattern"
{
    Properties
    {
        _Scale("Pattern Size", Range(0,10)) = 1
        //짝수 영역 컬러
        _EvenColor("Color 1",Color) = (0,0,0,1)
        //홀수 영역 컬러
        _OddColor("Color 2",Color) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 position : SV_POSITION;
            };

            float _Scale;
            float4 _EvenColor;
            float4 _OddColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);

                //float4x4 unity_ObjectToWorld는 현재 모델의 매트릭스를 반환합니다.
                //mul함수는 두 행렬의 행렬곱을 반홥합니다.
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 adjustWorldPos = (i.worldPos / _Scale);
                //체크보드 무늬생성
                float chessboard = floor(adjustWorldPos.x) + floor(adjustWorldPos.y) + floor(adjustWorldPos.z);
                //frac(x): x의 소숫점 반환
                chessboard = frac(chessboard * 0.5);
                //값이 홀수면 1, 짝수면 0이게 반환
                chessboard *= 2;

                //chessboard는 짝수영역 0과 홀수영역 1의 딱 두가지 값만 가지므로 이 값을 _EvenColor와 _OddColor의 선형보간값으로 넘기면 0일때 _EvenColor, 1일때 _OddColor를 반환한다.
                float4 color = lerp(_EvenColor, _OddColor, chessboard);
                return color;
            }
            ENDCG
        }
    }
}
