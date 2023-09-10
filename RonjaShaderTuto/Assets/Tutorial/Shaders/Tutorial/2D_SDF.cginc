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
#endif