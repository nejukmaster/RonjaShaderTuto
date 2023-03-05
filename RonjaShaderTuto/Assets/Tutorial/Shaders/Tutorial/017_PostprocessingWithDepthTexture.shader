Shader "Tutorial/017_PostprocessingWithDepthTexture"
{
    Properties
    {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        [Header(Wave)]
        _WaveDistance ("Distance from player", float) = 10
        _WaveTrail ("Length of the trail", Range(0,5)) = 1
        _WaveColor ("Color", Color) = (1,0,0,1)
    }
    SubShader
    {
        Cull Off
        Zwrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;

            float _WaveDistance;
            float _WaveTrail;
            float4 _WaveColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //카메라 DepthTexuture를 가지고와서 uv를 매핑
                float depth = tex2D(_CameraDepthTexture, i.uv).r;

                fixed4 col = tex2D(_MainTex, i.uv);
                //내장함수 Linear01Depth는 Depth Texture를 0~1사이로 선형매핑해줍니다.
                depth = Linear01Depth(depth);
                //_ProjectionParams.z는 카메라의 Far Plan의 값을 반환한다.
                //따라서 선형 매핑된 depth에 _ProjectionParams.z값을 곱하면 depth가 실제 유니티의 unit 단위로 변한다.
                depth = depth * _ProjectionParams.z;

                if(depth >= _ProjectionParams.z)
                    return col;

                //step(a,x): a가 x보다 작으면 0, 아니면 1을 반환
                //웨이브의 앞쪽 경계선
                float waveFront = step(depth, _WaveDistance);
                //smoothstep(min,max,x)는 min~max사이의 값을 보간하며 그 이외의 값은 step함수 처리 하는 함수입니다.
                //함수 smoothstep(x) = f(x)는 x가 [min,max]에서 f'(x) >= 0, f(min) = 0, f'(min) = 0, f(max) = 1, f'(max) = 0 이고, x가 (,min)에서 f(x) = 0, x가 (max,)에서 f(x) = 1인 연속, 미분가능 함수
                //웨이브 뒤쪽 경계선
                float waveTrail = smoothstep(_WaveDistance - _WaveTrail, _WaveDistance, depth);

                //waveFront * waveTrail을 곱하면 waveTrail 앞쪽 값은 반드시 0이되며 waveTrail에서 보간되는 값은 waveFront의 앞쪽이므로 그대로 나오며, waveFront 뒤쪽값은 반드시 0이되는 결과를 얻을 수 있다.
                float wave = waveFront * waveTrail;

                col = lerp(col,_WaveColor, wave);

                return col;
            }
            ENDCG
        }
    }
}
