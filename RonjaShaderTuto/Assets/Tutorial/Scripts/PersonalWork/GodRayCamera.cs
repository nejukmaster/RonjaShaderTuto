using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class GodRayCamera : MonoBehaviour
{
    [SerializeField] Material mat;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Camera cam = this.GetComponent<Camera>();
        mat.SetTexture("_SceneRenderTexture",cam.targetTexture,RenderTextureSubElement.Default);
    }
}
