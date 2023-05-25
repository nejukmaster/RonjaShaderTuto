using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlurPostprocessing : MonoBehaviour
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
        //RenderTexture.GetTemporary(width,height)는 width*height의 임시 렌더텍스쳐를 제공해준다.
        RenderTexture temporaryTexture = RenderTexture.GetTemporary(source.width, source.height);
        //2개의 패스를 사용하는 머티리얼을 포스트프로세싱에 사용하므로 두단계에 걸쳐서 Blit해준다.
        //먼저 0번 패스(y축 방향 박스 블러)를 소스이미지에 적용하여 임시 렌더텍스쳐에 반영한다.
        Graphics.Blit(source, temporaryTexture, postprocessMaterial, 0);
        //이후 1번 패스(x축 방향 박스 블러)를 임시텍스쳐에 적용하여 결과 텍스쳐에 반영한다.
        Graphics.Blit(temporaryTexture, destination, postprocessMaterial, 1);
        //이후 랜더텍스쳐의 할당을 해제해준다.
        RenderTexture.ReleaseTemporary(temporaryTexture);
    }
}
