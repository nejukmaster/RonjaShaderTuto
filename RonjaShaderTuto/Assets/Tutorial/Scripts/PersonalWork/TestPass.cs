using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TestPass : ScriptableRenderPass
{
    private TestFeature.CustomPassSettings settings;
    private RenderTargetIdentifier colorBuffer, testBuffer;
    private int testBufferID = Shader.PropertyToID("_TestBuffer");

    private Material material;

    public TestPass(TestFeature.CustomPassSettings settings)
    {
        this.settings = settings;
        this.renderPassEvent = settings.renderPassEvent;
        if (material == null) material = settings.material;
        ConfigureInput(ScriptableRenderPassInput.Normal);
    }

    internal bool Setup(ScriptableRenderer renderer)
    {
        return true;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        colorBuffer = renderingData.cameraData.renderer.cameraColorTarget;
        RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;

        cmd.GetTemporaryRT(testBufferID, descriptor, FilterMode.Point);
        testBuffer = new RenderTargetIdentifier(testBufferID);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd, new ProfilingSampler("Test Pass")))
        {
            Blit(cmd, colorBuffer, testBuffer, material);
            Blit(cmd, testBuffer, colorBuffer);
        }
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
    
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        if (cmd == null) throw new System.ArgumentNullException("cmd");
        cmd.ReleaseTemporaryRT(testBufferID);
    }
}
