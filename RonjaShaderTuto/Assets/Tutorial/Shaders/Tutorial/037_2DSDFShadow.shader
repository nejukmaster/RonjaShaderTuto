Shader "Tutorial/037_2DSDFShadow"{
    Properties{
        _Color("Color", Color) = (1,1,1,1)

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
                float bounds = -rectangle(position, 2);

                float2 quarterPos = abs(position);

                float corner = rectangle(translate(quarterPos, 1), 0.5);
                corner = subtract(corner, rectangle(position, 1.2));

                float diamond = rectangle(rotate(position, 0.125), .5);

                float world = merge(bounds, corner);
                world = merge(world, diamond);

                return world;
            }

            //���ø��� ������ �� �Դϴ�. �������� �������� �� ��Ȯ�� �׸��ڸ� ���� �� �ֽ��ϴ�.
            #define SAMPLES 32
            //�׸��� ���� �Լ�. �ȼ��� ��ġ�� ������ ���� ��ġ, �׸����� �浵�� �޴´�.
            float traceShadows(float2 position, float2 lightPosition, float hardness){
                //�׸��ڸ� ������ ����. �������� �ȼ��� ������ ���� ���� ������ SDF�� ������� �� �ȼ��� �׸��ڸ� �帮��ϴ�.
                float2 direction = normalize(lightPosition - position);
                //�������� �ȼ������� �Ÿ�
                float lightDistance = length(lightPosition - position);

                //������ ���൵�� ������ �����Դϴ�.
                //�Ŀ� Smooth Shadowing�� ���Ͽ� �ּ� �ȼ������� �������̱� ������ ���δ��� ���̱� ���� 0���� �������� �ʽ��ϴ�.
                float rayProgress = 0.0001;
                //������ ���� ����� �ȼ��� ���ø� �����͸� ������ �����Դϴ�.
                float nearest = 9999;
                for(int i=0 ;i<SAMPLES; i++){
                    //�������� ����� ������ �ִ� �ȼ��� ���ø� �մϴ�.
                    float sceneDist = scene(position + direction * rayProgress);

                    if(sceneDist <= 0){
                        return 0;
                    }
                    if(rayProgress > lightDistance){
                        return saturate(nearest);
                    }
                    //sceneDist�� �浵�� ���Ͽ� �ּڰ��� ã���� SDF�� 1�� 0���� �������� ������ ������ ���� �� �ִ�.
                    //�ּڰ����� ������ ���൵�� ������ �������� �־��� �ȼ��� ���� �׸����� ������ �о����ϴ�.
                     nearest = min(nearest, sceneDist * hardness / rayProgress);
                    rayProgress = rayProgress + sceneDist;
                }
                return 0;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                float2 position = i.worldPos.xz;

                //��������
                float2 lightPos1 = float2(sin(_Time.y), -1);
                float shadows1 = traceShadows(position, lightPos1, 20);
                float3 light1 = shadows1 * float3(.6, .6, 1);

                float2 lightPos2 = float2(-sin(_Time.y) * 1.75, 1.75);
                float shadows2 = traceShadows(position, lightPos2, 10);
                float3 light2 = shadows2 * float3(1, .6, .6);

                float sceneDistance = scene(position);
                float distanceChange = fwidth(sceneDistance) * 0.5;
                float binaryScene = smoothstep(distanceChange, -distanceChange, sceneDistance);
                float3 geometry = binaryScene * float3(0, 0.3, 0.1);

                float3 col = geometry + light1 + light2;

                return float4(col, 1);
            }

            ENDCG
        }
    }
    FallBack "Standard"
}