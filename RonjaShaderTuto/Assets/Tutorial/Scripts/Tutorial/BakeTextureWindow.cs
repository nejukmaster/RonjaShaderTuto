using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System;

public class BakeTextureWindow : EditorWindow
{
    //베이킹 할 머티리얼
    Material imgMaterial;
    //이미지가 저장될 경로
    string FilePath = "Assets/MaterialImage.png";
    //이미지의 크기
    Vector2Int Resolution;

    //입력 필드를 체크할 bool 프로퍼티
    bool hasMaterial;
    bool hasResolution;
    bool hasFilePath;

    [MenuItem("Tools/Bake material To Texture")]
    static void OpenWindow()
    {
        BakeTextureWindow window = EditorWindow.GetWindow<BakeTextureWindow>();
        window.Show();

        window.CheckInput();
    }

    private void OnGUI()
    {
        EditorGUILayout.HelpBox("Set the material you want to bake as well as the size " +
        "and location of the texture you want to bake to, then press the \"Bake\" button.", MessageType.None);

        using (var check = new EditorGUI.ChangeCheckScope())
        {
            //ObjectField(오브젝트 필드의 이름, 현재 값, 객체 유형, 씬에서 객체를 받아올 수 있는지 여부)
            imgMaterial = (Material)EditorGUILayout.ObjectField("Material", imgMaterial, typeof(Material), false);
            //Vector2Field(벡터2 필드의 이름, 현재 값)
            Resolution = EditorGUILayout.Vector2IntField("Image Resolution", Resolution);
            //TextField(텍스트 필드 이름, 현재 값)
            FilePath = FileField(FilePath);

            if(check.changed)
            {
                CheckInput();
            }
        }

        //모든 입력이 유효할 경우에만 GUi를 활성화 하여 버튼을 그립니다.
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
        hasResolution = Resolution.x > 0 && Resolution.y > 0;
        hasFilePath = false;
        try
        {
            //Path.GetExtension(path)는 path의 확장자를 반환합니다.
            string ext = Path.GetExtension(FilePath);
            hasFilePath = ext.Equals(".png");
        }
        catch (ArgumentException) { }
    }

    string FileField(string path)
    {
        EditorGUILayout.LabelField("Output file");
        //수평 레이아웃 사용
        using (new GUILayout.HorizontalScope())
        {
            path = EditorGUILayout.TextField(path);
            if (GUILayout.Button("choose"))
            {
                string directory = "Assets";
                string fileName = "MaterialImage.png";
                try
                {
                    directory = Path.GetDirectoryName(path);
                    fileName = Path.GetFileName(path);
                }
                catch (ArgumentException) { }
                //SaveFilePanelInProject함수는 유니티의 파일 저장 윈도우를 띄웁ㄴ디ㅏ.
                string chosenFile = EditorUtility.SaveFilePanelInProject("Choose image file", fileName,
                        "png", "Please enter a file name to save the image to", directory);
                if (!string.IsNullOrEmpty(chosenFile))
                {
                    path = chosenFile;
                }
                //Repaint함수는 이 EditorWindow를 다시 그립니다.
                Repaint();
            }
        }
        return path;
    }

    void BakeTexture()
    {
        //짧은 시간동안만 사용할 것이므로 커스텀 렌더 텍스쳐가 아닌 임시 랜더 텍스쳐를 가져옵니다.
        RenderTexture renderTexture = RenderTexture.GetTemporary(Resolution.x, Resolution.y);
        //모든 랜더링을 머티리얼 자체적으로 진행하므로 input으로 null을 넣습니다.
        Graphics.Blit(null, renderTexture, imgMaterial);

        //이미지 저장을 위해 Texture2D 생성
        Texture2D texture = new Texture2D(Resolution.x, Resolution.y);
        //활성화된 랜더 텍스쳐를 머티리얼의 출력으로 설정합니다.
        RenderTexture.active = renderTexture;
        //ReadPixels 함수는 현재 랜더링 대상에서 픽셀을 읽어서 Texture2D에 씁니다.
        texture.ReadPixels(new Rect(Vector2.zero, Resolution), 0, 0);

        byte[] png = texture.EncodeToPNG();
        File.WriteAllBytes(FilePath, png);
        AssetDatabase.Refresh();

        //임시 랜더 텍스쳐로의 접근 해제
        RenderTexture.active = null;
        //임시 랜더 텍스쳐 할당 해제
        RenderTexture.ReleaseTemporary(renderTexture);
        //Texture2D객체 할당 해제
        DestroyImmediate(texture);
    }

}
