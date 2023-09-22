#ifndef SDF_2D
#define SDF_2D
float circle(float2 samplePosition, float radius)
{
    //원점을 중심으로 radius의 원을 그린다. 원 내에 있는 픽셀은 -값을, 바깥에 있을경우 
    return length(samplePosition) - radius;
}

float rectangle(float2 samplePosition, float2 halfSize)
{
    float2 componentWiseEdgeDistance = abs(samplePosition) - halfSize;  //원점에서의 길이에서 직사각형의 가로세로를 뺍니다.
    float outsideDistance = length(max(componentWiseEdgeDistance, 0));  //값을 최대 0으로 제한하고 그 길이를 구합니다.
    float insideDistance = min(max(componentWiseEdgeDistance.x, componentWiseEdgeDistance.y), 0);
    return outsideDistance + insideDistance;
}

//rotate함수는 rotation인자에 회전을 받습니다.
float2 rotate(float2 samplePosition, float rotation)
{
    const float PI = 3.14159;
    float angle = rotation * PI * 2 * -1;   //라디안으로 변환
    float sine, cosine;
    sincos(angle, sine, cosine);    //회전각의 사인 코사인값을 계산
    return float2(cosine * samplePosition.x + sine * samplePosition.y, cosine * samplePosition.y - sine * samplePosition.x);    //회전
}

float2 scale(float2 samplePosition, float scale)
{
    return samplePosition / scale;
}

float2 translate(float2 samplePosition, float2 offset)
{
    return samplePosition - offset;
}

//두 값중 작은값을 반환하면 두 도형의 합집합을 반환합니다.
float merge(float shape1, float shape2)
{
    return min(shape1, shape2);
}
//두 값중 큰값을 반환하면 두 도형의 교집합을 반환합니다.
float intersect(float shape1, float shape2)
{
    return max(shape1, shape2);
}
//첫 번쨰 도형에서 두번째 도형을 빼는 방법은 두번째 도형을 반전하여 이의 교집합을 구하는 것입니다. 
float subtract(float base, float subtraction)
{
    return intersect(base, -subtraction);
}
//두 도형을 보간합니다.
float interpolate(float shape1, float shape2, float amount)
{
    return lerp(shape1, shape2, amount);
}

//두 도형을 둥글게 합칩니다.
float round_merge(float shape1, float shape2, float radius)
{
    float2 intersectionSpace = float2(shape1 - radius, shape2 - radius);    //두 도형을 둥글게 합칠 반지름을 빼줍니다.
    intersectionSpace = min(intersectionSpace, 0);  //0보다 작은 값만 거름
    float insideDistance = -length(intersectionSpace);  //내부 픽셀 값을 반전
    float simpleUnion = merge(shape1, shape2);  //두 도형을 합칩니다.
    float outsideDistance = max(simpleUnion, radius);   //radius보다 큰 합집합만 반환
    return insideDistance + outsideDistance;    //안쪽과 바깥쪽 값을 모두 적용
}

//SDF를 한 축을 기준으로 미러링합니다.
void mirror(inout float2 position)
{
    position.x = abs(position.x);
}

//SDF를 세포단위로 반복합니다.
float2 cells(inout float2 position, float2 period)
{
    //fmod(x,y)는 x를 y로 나눈 실수 나머지를 반환하며, 이 나머지의 부호는 x와 같다.
    position = fmod(position, period);
    //Cell크기를 더합니다.
    position += period;
    
    position = fmod(position, period);
    
    float2 cellIndex = position / period;
    cellIndex = floor(cellIndex);
    return cellIndex;
}

//방사형 세포를 배열합니다.
float radial_cells(inout float2 position, float cells, bool mirrorEverySecondCell = false)
{
    const float PI = 3.14159;

    float cellSize = PI * 2 / cells;
    float2 radialPosition = float2(atan2(position.x, position.y), length(position));

    float cellIndex = fmod(floor(radialPosition.x / cellSize) + cells, cells);

    radialPosition.x = fmod(fmod(radialPosition.x, cellSize) + cellSize, cellSize);

    if (mirrorEverySecondCell)
    {
        float flip = fmod(cellIndex, 2);
        flip = abs(flip - 1);
        radialPosition.x = lerp(cellSize - radialPosition.x, radialPosition.x, flip);
    }

    sincos(radialPosition.x, position.x, position.y);
    position = position * radialPosition.y;

    return cellIndex;
}

//흔들림추가. 2차원 사인파를 좌표에 더해 반환합니다.
void wobble(inout float2 position, float2 frequency, float2 amount)
{
    float2 wobble = sin(position.yx * frequency) * amount;
    position = position + wobble;
}
#endif