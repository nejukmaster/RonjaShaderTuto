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
            //세포의 경계를 그리기 위해 이웃셀을 같이 샘플링하여 픽셀과 주변 세포의 중심까지의 거리를 계산한다.
            [unroll]
            for(int x=-1; x<=1; x++){
                [unroll]
                for(int y=-1; y<=1; y++){
                    //이웃 셀 샘플링
                    float2 cell = baseCell + float2(x, y);
                    //셀상에서의 세포의 중심을 랜덤으로 정한다.
                    float2 cellPosition = cell + rand2dTo2d(cell);
                    //셀의 중심으로부터 현재 픽셀의 거리벡터를 구한다.
                    float2 toCell = cellPosition - value;
                    //그 거리벡터의 길이를 반환한다. 이러면 셀의 중심으로 멀어질수록 밝아진다.
                    float distToCell = length(toCell);
                    //이후 이전 셀의 중심과의 거리보다 가까운지 확인한다.
                    //이 과정은 셀의 색상을 가장 가까운 세포의 중심의 거리로 그리기 위함이다.
                    if(distToCell < minDistToCell){
                        minDistToCell = distToCell;
                        //가장 가까운 Cell의 위치값을 저장
                        closestCell = cell;
                        //가장 가까운 Cell까지의 방향 벡터값 저장
                        toClosestCell = toCell;
                    }
                }
            }
            //가장 가까운 경계까지의 거리를 찾기위한 2번쨰 Pass
            float minEdgeDistance = 10;
            [unroll]
            for(int x2=-1; x2<=1; x2++){
                [unroll]
                for(int y2=-1; y2<=1; y2++){
                    float2 cell = baseCell + float2(x2, y2);
                    float2 cellPosition = cell + rand2dTo2d(cell);
                    float2 toCell = cellPosition - value;
                    
                    //1Pass에서 구한 가장 가까운 셀과 현재 셀을 비교한다.
                    float2 diffToClosestCell = abs(closestCell - cell);
                    bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y < 0.1;
                    //만약 현재 셀이 가장 가까운 셀이 아닐경우
                    if(!isClosestCell){
                        //현재 픽셀에서 가장 가까운 셀의 중심과 현재 셀의 중심을 이은 선분이 경계와 만나는 점까지의 벡터
                        float2 toCenter = (toClosestCell + toCell) * 0.5;
                        //현재 셀에서 가장 가까운 셀까지의 벡터를 노멀라이즈
                        float2 cellDifference = normalize(toCell - toClosestCell);
                        //경계선 까지의 거리를 구한다.
                        float edgeDistance = dot(toCenter, cellDifference);
                        //최솟값 업데이트
                        minEdgeDistance = min(minEdgeDistance, edgeDistance);
                    }
                }
            }
            //결과값은 픽셀의 가장 가까운 셀과의 거리와 그 셀의 위치값을 시드로 한 랜덤값, 가장 가까운 경계까지의 거리의 3차원 벡터로 출력한다.
            //이러면 출력값의 y값에는 같은 세포를 가장 가까운 세포로 둔 픽셀엔 같은 랜덤값이 할당된다.
            return float3(minDistToCell, rand2dTo1d(closestCell), minEdgeDistance);
        }

        //3차원 보로노이 노이즈
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
