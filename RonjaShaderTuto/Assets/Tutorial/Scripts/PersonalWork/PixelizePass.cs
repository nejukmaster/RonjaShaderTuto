using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

//
public class PixelizePass : ScriptableRenderPass
{
    private PixelizeFeature.CustomPassSettings settings;
    //Blit과 같은 그래픽 명령에서 랜더 텍스쳐에 접근 할 수 있도록 랜더 텍스쳐의 식별자를 저장
    //랜더 텍스쳐는 카메라가 랜더링한 텍스쳐를 말한다.
    //랜더 텍스쳐에 대한 설명 : https://docs.unity3d.com/kr/current/Manual/class-RenderTexture.html
    private RenderTargetIdentifier colorBuffer, pixelBuffer;
    private int pixelBufferID = Shader.PropertyToID("_PixelBuffer");

    //private RenderTargetIdentifier pointBuffer;
    //private int pointBufferID = Shader.PropertyToID("_PointBuffer");

    private Material material;
    private int pixelScreenHeight, pixelScreenWidth;

    //Constructor
    public PixelizePass(PixelizeFeature.CustomPassSettings settings)
    {
        this.settings = settings;
        this.renderPassEvent = settings.renderPassEvent;
        //material이 null일경우 "Hidden/Pixelize"쉐이더를 사용하여 머티리얼을 생성합니다.
        if (material == null) material = CoreUtils.CreateEngineMaterial("Hidden/Pixelize");
    }

    //이 메서드는 카메라를 렌더링하기 전에 렌더러에 의해 호출됩니다.
    //CommandBuffer는 카메라가 씬을 랜더링하는 랜더링 지점마다 지정된 커맨드를 추가할수 있게 해줍니다.
    //CommandBuffer에 대한 설명 : https://docs.unity3d.com/kr/530/Manual/GraphicsCommandBuffers.html
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        //현재 화면 버퍼를 colorBuffer에 저장
        colorBuffer = renderingData.cameraData.renderer.cameraColorTarget;
        //RenderTextureDescriptor는 렌더 텍스쳐를 생성하는데 필요한 정보를 저장합니다.
        //RenderTextureDescriptor에 대한 설명 : https://docs.unity3d.com/ScriptReference/RenderTextureDescriptor.html
        RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;

        //cmd.GetTemporaryRT(pointBufferID, descriptor.width, descriptor.height, 0, FilterMode.Point);
        //pointBuffer = new RenderTargetIdentifier(pointBufferID);

        pixelScreenHeight = settings.screenHeight;
        //종횡비를 사용하여 스크린 와이드 계산
        pixelScreenWidth = (int)(pixelScreenHeight * renderingData.cameraData.camera.aspect + 0.5f);

        material.SetVector("_BlockCount", new Vector2(pixelScreenWidth, pixelScreenHeight));
        material.SetVector("_BlockSize", new Vector2(1.0f / pixelScreenWidth, 1.0f / pixelScreenHeight));
        material.SetVector("_HalfBlockSize", new Vector2(0.5f / pixelScreenWidth, 0.5f / pixelScreenHeight));

        descriptor.height = pixelScreenHeight;
        descriptor.width = pixelScreenWidth;

        //GetTemporaryRT(RenderId, Descriptor, FilterMode)는 현재 카메라의 임시랜더링텍스쳐를 Descriptor의 형식으로 RenderId에 바인딩 합니다..
        //FilterMode는 랜더 텍스쳐를 어떻게 필터링 할건지 정합니다.
        //FilterMode에 대한 설명 : https://docs.unity3d.com/kr/530/ScriptReference/FilterMode.html
        cmd.GetTemporaryRT(pixelBufferID, descriptor, FilterMode.Point);
        //방금 렌더텍스쳐를 바인딩한 정수 아이디를 바탕으로  RenderTargetIdentifier를 생성합니다.
        pixelBuffer = new RenderTargetIdentifier(pixelBufferID);
    }

    //이 Pass가 실행될때 호출됩니다.
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        //CommandBufferPool.Get()함수는 새 커멘드버퍼를 가져옵니다.
        CommandBuffer cmd = CommandBufferPool.Get();
        //using문은 아래와 같이 임시로 사용될 지역변수의 할당을 해제할 필요가 있을때 이를 자동으로 수행하기위해 쓰이기도 한다.
        //ProfilingScope는 따로 Dispose(할당 해제)를 구현해야하는 클래스이기 때문에 편의를 위해 using문 안에 집어넣었다.
        //유니티에선 성능에 관한 프로파일링을 위해 ProfilingScope-ProfilingSampler 두가지 클래스를 사용하여 특정 구간의 성능을 프로파일링하며 이는 이때 프로파일링 한 ProfilingSampler(string name)에 접근하여 얻어올 수 있다.
        using (new ProfilingScope(cmd, new ProfilingSampler("Pixelize Pass")))
        {
            // No-shader variant
            //Blit(cmd, colorBuffer, pointBuffer);
            //Blit(cmd, pointBuffer, pixelBuffer);
            //Blit(cmd, pixelBuffer, colorBuffer);

            //Blit함수의 첫번째 인자로 CommandBuffer를 넣어주면 해당 CommandBuffer에 Blit명령을 추가합니다.
            //현재 화면 버퍼에 material을 적용하여 임시 랜더 텍스쳐 버퍼에 저장
            Blit(cmd, colorBuffer, pixelBuffer, material);
            ////임시 랜더 텍스쳐를 화면 버퍼에 적용
            Blit(cmd, pixelBuffer, colorBuffer);
        }
        //커멘드 버퍼 실행
        context.ExecuteCommandBuffer(cmd);
        //CommandBuffer를 생성한 이후 사용하였으면 다시 CommandBufferPool로 환원하여 메모리 누수를 막아줍니다.
        CommandBufferPool.Release(cmd);
    }
    //카메라의 랜더링이 끝났을때 실행됩니다.
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        if (cmd == null) throw new System.ArgumentNullException("cmd");
        //우리가 사용한 랜더 텍스쳐의 할당을 해제해주어 메모리 누수를 막습니다.
        cmd.ReleaseTemporaryRT(pixelBufferID);
        //cmd.ReleaseTemporaryRT(pointBufferID);
    }

}