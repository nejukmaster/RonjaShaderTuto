Shader "Tutorial/034_2D_SDF_Basics"{
    Properties{
        _Color("Color", Color) = (1,1,1,1)
        [KeywordEnum(Solid, HeightLine)] _Mode("Mode", Float) = 0

        _InsideColor("Inside Color", Color) = (.5, 0, 0, 1)
        _OutsideColor("Outside Color", Color) = (0, .5, 0, 1)

        _LineDistance("Mayor Line Distance", Range(0, 2)) = 1
        _LineThickness("Mayor Line Thickness", Range(0, 0.1)) = 0.05
        [IntRange]_SubLines("Lines between major lines", Range(1, 10)) = 4
        _SubLineThickness("Thickness of inbetween lines", Range(0, 0.05)) = 0.01
    }
    SubShader{
        //the material is completely non-transparent and is rendered at the same time as the other opaque geometry
        Tags{ "RenderType"="Transparent" "Queue"="Transparent"}

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass{
            CGPROGRAM

            #include "UnityCG.cginc"
            #include "2D_SDF.cginc"

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _MODE_SOLID _MODE_HEIGHTLINE

            struct appdata{
                float4 vertex : POSITION;
            };

            struct v2f{
                float4 position : SV_POSITION;
                float4 worldPos : TEXCOORD0;
            };

            fixed4 _Color;
            float4 _InsideColor;
            float4 _OutsideColor;
            float _LineDistance;
            float _LineThickness;
            float _SubLines;
            float _SubLineThickness;

            v2f vert(appdata v){
                v2f o;
                //calculate the position in clip space to render the object
                o.position = UnityObjectToClipPos(v.vertex);
                //calculate world position of vertex
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float scene(float2 position) {
                float2 circlePosition = translate(position, float2(1, 0));
                //circlePosition = rotate(circlePosition, _Time.y);
                float pulseScale = 1 + 0.5*sin(_Time.y * 3.14);
                circlePosition = scale(circlePosition, pulseScale); 
                float sceneDistance = rectangle(circlePosition, float2(1, 2)) * pulseScale;
                return sceneDistance;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                float dist = scene(i.worldPos.xz);
                #if _MODE_SOLID
                    float distanceChange = fwidth(dist) * 0.5;
                    float antialiasedCutoff = smoothstep(distanceChange, -distanceChange, dist);    //안티에일리어싱
                    fixed4 col = fixed4(_Color.rgb, antialiasedCutoff);
                    return col;
                #elif _MODE_HEIGHTLINE
                    fixed4 col = lerp(_InsideColor, _OutsideColor, step(0, dist));
                    float distanceChange = fwidth(dist) * 0.5;
                    float majorLineDistance = abs(frac(dist / _LineDistance + 0.5) - 0.5) * _LineDistance;  //frac함수는 주어진 실수의 소수부분을 반환
                    float majorLines = smoothstep(_LineThickness - distanceChange, _LineThickness + distanceChange, majorLineDistance);
                    
                    float distanceBetweenSubLines = _LineDistance / _SubLines;
                    float subLineDistance = abs(frac(dist / distanceBetweenSubLines + 0.5) - 0.5) * distanceBetweenSubLines;
                    float subLines = smoothstep(_SubLineThickness - distanceChange, _SubLineThickness + distanceChange, subLineDistance);
    
                    return col * majorLines * subLines;
                #endif
            }

            ENDCG
        }
    }
    FallBack "Standard" //fallback adds a shadow pass so we get shadows on other objects
}
