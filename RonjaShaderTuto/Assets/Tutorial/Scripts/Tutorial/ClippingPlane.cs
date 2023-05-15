using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class ClippingPlane : MonoBehaviour
{

    public Material mat;

    // Update is called once per frame
    void Update()
    {
        //Plane(normal,point)는 normal을 법선으로 가지고 point를 지나는 무한한 평면을 반환합니다.
        //transform.up은 자신 transform의 월드 상향 벡터를 참조함
        Plane plane = new Plane(transform.up, transform.position);

        //생성한 Plane을 바탕으로 Vector4데이터를 생성합니다.
        //plane.distance는 해당 Plane의 노멀벡터를 따라 측정한 원점까지의 거리입니다.
        Vector4 planeRepresentation = new Vector4(plane.normal.x, plane.normal.y, plane.normal.z, plane.distance);
        //머티리얼의 uniform설정
        mat.SetVector("_Plane", planeRepresentation);
    }
}
