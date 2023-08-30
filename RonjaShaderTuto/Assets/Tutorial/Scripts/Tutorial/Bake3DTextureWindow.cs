using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System;

public class Bake3DTextureWindow : EditorWindow
{
    //베이킹 할 머티리얼
    Material imgMaterial;
    //이미지가 저장될 경로
    string FilePath = "Assets/MaterialImage.asset";
    //이미지의 크기
    Vector3Int Resolution;

    //입력 필드를 체크할 bool 프로퍼티
    bool hasMaterial;
    bool hasResolution;
    bool hasFilePath;

    [MenuItem("Tools/Bake material To 3D Texture")]
    static void OpenWindow()
    {
        Bake3DTextureWindow window = EditorWindow.GetWindow<Bake3DTextureWindow>();

        window.Show();

        window.CheckInput();
    }

    private void OnGUI()
    {

        EditorGUILayout.HelpBox("Set the material you want to bake as well as the size " +
        "and location of the texture you want to bake to, then press the \"Bake\" button.", MessageType.None);

        using (var check = new EditorGUI.ChangeCheckScope())
        {
            imgMaterial = (Material)EditorGUILayout.ObjectField("Material", imgMaterial, typeof(Material), false);
            Resolution = EditorGUILayout.Vector3IntField("Image Resolution", Resolution);
            FilePath = FileField(FilePath);

            if(check.changed)
            {
                CheckInput();
            }
        }

        GUI.enabled = hasMaterial && hasResolution && hasFilePath;

        if (GUILayout.Button("Bake"))
        {
            BakeTexture();
        }
        //이후 GUI 활성
        GUI.enabled = true;

        //알림창
        if (!hasMaterial)
        {
            EditorGUILayout.HelpBox("You're still missing a material to bake.", MessageType.Warning);
        }
        if (!hasResolution)
        {
            EditorGUILayout.HelpBox("Please set a size bigger than zero.", MessageType.Warning);
        }
        if (!hasFilePath)
        {
            EditorGUILayout.HelpBox("No file to save the image to given.", MessageType.Warning);
        }
    }

    void CheckInput()
    {
        hasMaterial = imgMaterial != null;
        hasResolution = Resolution.x > 0 && Resolution.y > 0 && Resolution.z > 0;
        hasFilePath = false;
        try
        {
            string ext = Path.GetExtension(FilePath);
            hasFilePath = ext.Equals(".asset");
        }
        catch (ArgumentException) { }
    }

    string FileField(string path)
    {
        //allow the user to enter output file both as text or via file browser
        EditorGUILayout.LabelField("Image Path");
        using (new GUILayout.HorizontalScope())
        {
            path = EditorGUILayout.TextField(path);
            if (GUILayout.Button("choose"))
            {
                //set default values for directory, then try to override them with values of existing path
                string directory = "Assets";
                string fileName = "MaterialImage.asset";
                try
                {
                    directory = Path.GetDirectoryName(path);
                    fileName = Path.GetFileName(path);
                }
                catch (ArgumentException) { }
                string chosenFile = EditorUtility.SaveFilePanelInProject("Choose image file", fileName,
                        "asset", "Please enter a file name to save the image to", directory);
                if (!string.IsNullOrEmpty(chosenFile))
                {
                    path = chosenFile;
                }
                //repaint editor because the file changed and we can't set it in the textfield retroactively
                Repaint();
            }
        }
        return path;
    }

    void BakeTexture()
    {
        //3D텍스쳐 베이킹은 2D텍스쳐를 _Height값에 따라 여러번 랜더링하여 쌓는 형식으로 베이킹한다.

        RenderTexture renderTexture = RenderTexture.GetTemporary(Resolution.x, Resolution.y);
        Texture3D volumeTexture = new Texture3D(Resolution.x, Resolution.y,Resolution.z, TextureFormat.ARGB32, false);
        Texture2D tempTexture = new Texture2D(Resolution.x, Resolution.y);

        RenderTexture.active = renderTexture;
        //3D텍스쳐의 복셀수
        int voxelAmount = Resolution.x * Resolution.y * Resolution.z;
        //단일 슬라이스 2D텍스쳐의 픽셀수
        int slicePixelAmount = Resolution.x * Resolution.y;
        //3D텍스쳐 베이킹 과정에서 채울 색상 배열
        Color32[] colors = new Color32[voxelAmount];

        //슬라이싱
        for(int slice = 0; slice < Resolution.z; slice++)
        {
            //현재 슬라이스의 0~1 사이의 높이값을 설정. 0.5f는 현재 슬라이스의 높이를 복셀값 중간지점으로 설정하기 위해 더해준다.
            float height = (slice + 0.5f) / Resolution.z;
            //머터리얼 _Height속성에 높이값 적용
            imgMaterial.SetFloat("_Height", height);

            //랜더링
            Graphics.Blit(null, renderTexture, imgMaterial);
            tempTexture.ReadPixels(new Rect(0, 0, Resolution.x, Resolution.y), 0, 0);
            Color32[] sliceColors = tempTexture.GetPixels32();

            //3D텍스쳐에 랜더링된 현재 슬라이스를 씁니다.
            int sliceBaseIndex = slice * slicePixelAmount;
            for (int pixel = 0; pixel < slicePixelAmount; pixel++)
            {
                colors[sliceBaseIndex + pixel] = sliceColors[pixel];
            }
        }

        //3D텍스쳐에 데이터를 저장하고 CreateAsset으로 3D텍스쳐를 파일로 저장합니다.
        volumeTexture.SetPixels32(colors);
        AssetDatabase.CreateAsset(volumeTexture, FilePath);

        //메모리 정리
        RenderTexture.active = null;
        RenderTexture.ReleaseTemporary(renderTexture);
        DestroyImmediate(volumeTexture, true);
        DestroyImmediate(tempTexture, true);
    }

}
