using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OutlineWithPostprocessing : MonoBehaviour
{
    [SerializeField] private Material postprocessMaterial;

    private Camera cam;

    // Start is called before the first frame update
    void Start()
    {
        cam = GetComponent<Camera>();
        //??? ???? Depth Normal Texture? ?????.
        cam.depthTextureMode = DepthTextureMode.DepthNormals;
    }

    // Update is called once per frame
    void Update()
    {

    }

    //method which is automatically called by unity after the camera is done rendering
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        //draws the pixels from the source texture to the destination texture
        Graphics.Blit(source, destination, postprocessMaterial);
    }
}
