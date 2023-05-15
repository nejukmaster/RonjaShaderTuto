using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[DisallowMultipleRendererFeature]
public class TestFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class CustomPassSettings
    {
        //이 랜더링 패스가 언제 실행될지를 담는 RenderPassEvent Enum
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public Material material;
    }

    [SerializeField] private CustomPassSettings settings;
    private TestPass customPass;

    public override void Create()
    {
        customPass = new TestPass(settings);
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {

#if UNITY_EDITOR
        if (renderingData.cameraData.isSceneViewCamera) return;
#endif
        renderer.EnqueuePass(customPass);
    }
}
