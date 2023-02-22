using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostprocessingBasics : MonoBehaviour
{

    [SerializeField] private Material postprocessMaterial;

    //OnRenderImage는 카메라 랜더링이 끝난후 호출된다.
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        //Graphics.Blit메서드는 랜더링되는 픽셀을 교체해준다.
        //세번째 인자로 머티리얼을 넘겨주면 랜더링될 픽셀에 머티리얼을 적용한다.
        Graphics.Blit(source, destination, postprocessMaterial);
    }
}
