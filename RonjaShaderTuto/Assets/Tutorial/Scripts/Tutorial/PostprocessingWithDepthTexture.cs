using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostprocessingWithDepthTexture : MonoBehaviour
{
    [SerializeField] private Material postprocessMaterial;
    [SerializeField] private float waveSpeed;
    [SerializeField] private bool waveActive;

    private float waveDistance;
    // Start is called before the first frame update
    void Start()
    {
        Camera cam = GetComponent<Camera>();
        //유니티 카메라가 depth texture를 받아옵니다.
        //DepthTextureMode의 자세한 설명: https://docs.unity3d.com/ScriptReference/DepthTextureMode.html
        cam.depthTextureMode = DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {
        if(waveActive){
            waveDistance += waveSpeed * Time.deltaTime;
        }
        else{
            waveDistance = 0;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        postprocessMaterial.SetFloat("_WaveDistance",waveDistance);
        Graphics.Blit(source, destination, postprocessMaterial);
    }
}
