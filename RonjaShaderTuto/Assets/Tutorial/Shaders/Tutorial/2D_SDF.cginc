#ifndef SDF_2D
#define SDF_2D
float circle(float2 samplePosition, float radius)
{
    //������ �߽����� radius�� ���� �׸���. �� ���� �ִ� �ȼ��� -����, �ٱ��� ������� 
    return length(samplePosition) - radius;
}

float rectangle(float2 samplePosition, float2 halfSize)
{
    float2 componentWiseEdgeDistance = abs(samplePosition) - halfSize;  //���������� ���̿��� ���簢���� ���μ��θ� ���ϴ�.
    float outsideDistance = length(max(componentWiseEdgeDistance, 0));  //���� �ִ� 0���� �����ϰ� �� ���̸� ���մϴ�.
    float insideDistance = min(max(componentWiseEdgeDistance.x, componentWiseEdgeDistance.y), 0);
    return outsideDistance + insideDistance;
}

//rotate�Լ��� rotation���ڿ� ȸ���� �޽��ϴ�.
float2 rotate(float2 samplePosition, float rotation)
{
    const float PI = 3.14159;
    float angle = rotation * PI * 2 * -1;   //�������� ��ȯ
    float sine, cosine;
    sincos(angle, sine, cosine);    //ȸ������ ���� �ڻ��ΰ��� ���
    return float2(cosine * samplePosition.x + sine * samplePosition.y, cosine * samplePosition.y - sine * samplePosition.x);    //ȸ��
}

float2 scale(float2 samplePosition, float scale)
{
    return samplePosition / scale;
}

float2 translate(float2 samplePosition, float2 offset)
{
    return samplePosition - offset;
}

//�� ���� �������� ��ȯ�ϸ� �� ������ �������� ��ȯ�մϴ�.
float merge(float shape1, float shape2)
{
    return min(shape1, shape2);
}
//�� ���� ū���� ��ȯ�ϸ� �� ������ �������� ��ȯ�մϴ�.
float intersect(float shape1, float shape2)
{
    return max(shape1, shape2);
}
//ù ���� �������� �ι�° ������ ���� ����� �ι�° ������ �����Ͽ� ���� �������� ���ϴ� ���Դϴ�. 
float subtract(float base, float subtraction)
{
    return intersect(base, -subtraction);
}
//�� ������ �����մϴ�.
float interpolate(float shape1, float shape2, float amount)
{
    return lerp(shape1, shape2, amount);
}

//�� ������ �ձ۰� ��Ĩ�ϴ�.
float round_merge(float shape1, float shape2, float radius)
{
    float2 intersectionSpace = float2(shape1 - radius, shape2 - radius);    //�� ������ �ձ۰� ��ĥ �������� ���ݴϴ�.
    intersectionSpace = min(intersectionSpace, 0);  //0���� ���� ���� �Ÿ�
    float insideDistance = -length(intersectionSpace);  //���� �ȼ� ���� ����
    float simpleUnion = merge(shape1, shape2);  //�� ������ ��Ĩ�ϴ�.
    float outsideDistance = max(simpleUnion, radius);   //radius���� ū �����ո� ��ȯ
    return insideDistance + outsideDistance;    //���ʰ� �ٱ��� ���� ��� ����
}

//SDF�� �� ���� �������� �̷����մϴ�.
void mirror(inout float2 position)
{
    position.x = abs(position.x);
}

//SDF�� ���������� �ݺ��մϴ�.
float2 cells(inout float2 position, float2 period)
{
    //fmod(x,y)�� x�� y�� ���� �Ǽ� �������� ��ȯ�ϸ�, �� �������� ��ȣ�� x�� ����.
    position = fmod(position, period);
    //Cellũ�⸦ ���մϴ�.
    position += period;
    
    position = fmod(position, period);
    
    float2 cellIndex = position / period;
    cellIndex = floor(cellIndex);
    return cellIndex;
}

//����� ������ �迭�մϴ�.
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

//��鸲�߰�. 2���� �����ĸ� ��ǥ�� ���� ��ȯ�մϴ�.
void wobble(inout float2 position, float2 frequency, float2 amount)
{
    float2 wobble = sin(position.yx * frequency) * amount;
    position = position + wobble;
}
#endif