using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostprocessWithNormalTexture : MonoBehaviour
{
    [SerializeField] private Material postprocessMaterial;

    private Camera cam;

    // Start is called before the first frame update
    void Start()
    {
        cam = GetComponent<Camera>();
        //유니티 카메라가 Depth Normal Texture를 가져옵니다.
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        //유니티 카메라의 cameraToWorldMatrix속성은 클립좌표계를 월드좌표계로 변환할때 사용할 수 있는 변환 행렬을 반환합니다.
        Matrix4x4 viewToWorld = cam.cameraToWorldMatrix;
        postprocessMaterial.SetMatrix("_viewToWorld", viewToWorld);
        Graphics.Blit(source, destination, postprocessMaterial);
    }
}
