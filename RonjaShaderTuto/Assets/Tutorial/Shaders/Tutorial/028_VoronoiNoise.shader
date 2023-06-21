Shader "Tutorial/028_VoronoiNoise"
{
    Properties
    {
        _CellSize("Cell Size",Range(0,2)) = 2
        _BorderColor("Border Color", Color) = (0,0,0,1)

        [KeywordEnum(2D, 3D)] _NoiseDemension("noiseDemension", Float) = 0
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
        
        #pragma multi_compile _NOISEDEMENSION_2D _NOISEDEMENSION_3D

        #include "WhiteNoise.cginc"

        struct Input
        {
            float3 worldPos;
        };

        float3 voronoiNoise(float2 value){
            float2 baseCell = floor(value);
            
            float minDistToCell = 10;
            float2 closestCell;
            float2 toClosestCell;
            //������ ��踦 �׸��� ���� �̿����� ���� ���ø��Ͽ� �ȼ��� �ֺ� ������ �߽ɱ����� �Ÿ��� ����Ѵ�.
            [unroll]
            for(int x=-1; x<=1; x++){
                [unroll]
                for(int y=-1; y<=1; y++){
                    //�̿� �� ���ø�
                    float2 cell = baseCell + float2(x, y);
                    //���󿡼��� ������ �߽��� �������� ���Ѵ�.
                    float2 cellPosition = cell + rand2dTo2d(cell);
                    //���� �߽����κ��� ���� �ȼ��� �Ÿ����͸� ���Ѵ�.
                    float2 toCell = cellPosition - value;
                    //�� �Ÿ������� ���̸� ��ȯ�Ѵ�. �̷��� ���� �߽����� �־������� �������.
                    float distToCell = length(toCell);
                    //���� ���� ���� �߽ɰ��� �Ÿ����� ������� Ȯ���Ѵ�.
                    //�� ������ ���� ������ ���� ����� ������ �߽��� �Ÿ��� �׸��� �����̴�.
                    if(distToCell < minDistToCell){
                        minDistToCell = distToCell;
                        //���� ����� Cell�� ��ġ���� ����
                        closestCell = cell;
                        //���� ����� Cell������ ���� ���Ͱ� ����
                        toClosestCell = toCell;
                    }
                }
            }
            //���� ����� �������� �Ÿ��� ã������ 2���� Pass
            float minEdgeDistance = 10;
            [unroll]
            for(int x2=-1; x2<=1; x2++){
                [unroll]
                for(int y2=-1; y2<=1; y2++){
                    float2 cell = baseCell + float2(x2, y2);
                    float2 cellPosition = cell + rand2dTo2d(cell);
                    float2 toCell = cellPosition - value;
                    
                    //1Pass���� ���� ���� ����� ���� ���� ���� ���Ѵ�.
                    float2 diffToClosestCell = abs(closestCell - cell);
                    bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y < 0.1;
                    //���� ���� ���� ���� ����� ���� �ƴҰ��
                    if(!isClosestCell){
                        //���� �ȼ����� ���� ����� ���� �߽ɰ� ���� ���� �߽��� ���� ������ ���� ������ �������� ����
                        float2 toCenter = (toClosestCell + toCell) * 0.5;
                        //���� ������ ���� ����� �������� ���͸� ��ֶ�����
                        float2 cellDifference = normalize(toCell - toClosestCell);
                        //��輱 ������ �Ÿ��� ���Ѵ�.
                        float edgeDistance = dot(toCenter, cellDifference);
                        //�ּڰ� ������Ʈ
                        minEdgeDistance = min(minEdgeDistance, edgeDistance);
                    }
                }
            }
            //������� �ȼ��� ���� ����� ������ �Ÿ��� �� ���� ��ġ���� �õ�� �� ������, ���� ����� �������� �Ÿ��� 3���� ���ͷ� ����Ѵ�.
            //�̷��� ��°��� y������ ���� ������ ���� ����� ������ �� �ȼ��� ���� �������� �Ҵ�ȴ�.
            return float3(minDistToCell, rand2dTo1d(closestCell), minEdgeDistance);
        }

        //3���� ���γ��� ������
        float3 voronoiNoise(float3 value){
            float3 baseCell = floor(value);

            //first pass to find the closest cell
            float minDistToCell = 10;
            float3 toClosestCell;
            float3 closestCell;
            [unroll]
            for(int x1=-1; x1<=1; x1++){
                [unroll]
                for(int y1=-1; y1<=1; y1++){
                    [unroll]
                    for(int z1=-1; z1<=1; z1++){
                        float3 cell = baseCell + float3(x1, y1, z1);
                        float3 cellPosition = cell + rand3dTo3d(cell);
                        float3 toCell = cellPosition - value;
                        float distToCell = length(toCell);
                        if(distToCell < minDistToCell){
                            minDistToCell = distToCell;
                            closestCell = cell;
                            toClosestCell = toCell;
                        }
                    }
                }
            }

            //second pass to find the distance to the closest edge
            float minEdgeDistance = 10;
            [unroll]
            for(int x2=-1; x2<=1; x2++){
                [unroll]
                for(int y2=-1; y2<=1; y2++){
                    [unroll]
                    for(int z2=-1; z2<=1; z2++){
                        float3 cell = baseCell + float3(x2, y2, z2);
                        float3 cellPosition = cell + rand3dTo3d(cell);
                        float3 toCell = cellPosition - value;

                        float3 diffToClosestCell = abs(closestCell - cell);
                        bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y + diffToClosestCell.z < 0.1;
                        if(!isClosestCell){
                            float3 toCenter = (toClosestCell + toCell) * 0.5;
                            float3 cellDifference = normalize(toCell - toClosestCell);
                            float edgeDistance = dot(toCenter, cellDifference);
                            minEdgeDistance = min(minEdgeDistance, edgeDistance);
                        }
                    }
                }
            }

            float random = rand3dTo1d(closestCell);
            return float3(minDistToCell, random, minEdgeDistance);
        }

        float _CellSize;
        fixed4 _BorderColor;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            #if _NOISEDEMENSION_2D
                float2 value = IN.worldPos.xz / _CellSize;
	            float3 noise = voronoiNoise(value);

	            float3 cellColor = rand1dTo3d(noise.y); 
	            float valueChange = length(fwidth(value)) * 0.5;
	            float isBorder = 1 - smoothstep(0.05 - valueChange, 0.05 + valueChange, noise.z);
	            float3 color = lerp(cellColor, _BorderColor, isBorder);
	            o.Albedo = color;
            #elif _NOISEDEMENSION_3D
                float3 value = IN.worldPos.xyz / _CellSize;
                float3 noise = voronoiNoise(value);

                float3 cellColor = rand1dTo3d(noise.y); 
                float valueChange = fwidth(value.z) * 0.5;
                float isBorder = 1 - smoothstep(0.05 - valueChange, 0.05 + valueChange, noise.z);
                float3 color = lerp(cellColor, _BorderColor, isBorder);
                o.Albedo = color;
            #endif
        }
        ENDCG
    }
    FallBack "Diffuse"
}