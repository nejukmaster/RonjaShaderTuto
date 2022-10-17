//Shader는 쉐이더의 전체를 뜻합니다.
Shader "Unlit/001-004_Basic_Unlit"{
    //인스펙터 창에서 수정할수 있는 변수
    Properties{
      _Color("Tint", Color) = (0, 0, 0, 1)
      _MainTex("Texture", 2D) = "white" {}
    }

        SubShader{
        //Tag전문 : https://docs.unity3d.com/kr/2020.3/Manual/SL-SubShaderTags.html
        //RenderType : 이 서브쉐이더의 랜더링 타입을 설정
        //Queue : 서브 쉐이더가 어떤 랜더링 대기열을 활용할 건지 여부를 설정  -> 같은 대기열은 동시에 랜더링
        Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }

        //Pass는 화면에 그려지는 단일 단위입니다.
        //여러개 정의할 수 있으며 순서대로 그려집니다.
        Pass{
          CGPROGRAM

          //include useful shader functions
          #include "UnityCG.cginc"

          //셰이더 프로그램 정의
          //셰이더 프로그램에서 사용할 버텍스 셰이더와 프래그먼트 셰이더를 지정해줍니다.
          #pragma vertex vert
          #pragma fragment frag

          //데이터 타입 전문 : https://docs.unity3d.com/Manual/SL-DataTypesAndPrecision.html
          //이에 적용할수 있는 수학 함수 전문 : https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions
          //texture and transforms of the texture
          sampler2D _MainTex;
          float4 _MainTex_ST;

          //tint of the texture
          fixed4 _Color;
          
          //개체 데이터
          //이 구조체에 정점 데이터를 보관하여 버텍스쉐이더로 넘깁니다.
          struct appdata {
            //정점 쉐이더 버텍스 데이터 전문 : https://docs.unity3d.com/Manual/SL-VertexProgramInputs.html
            //POSITION은 정점 위치이며 일반적으로 float3또는 float4입니다
            float4 vertex : POSITION;
            //TEXCOORD0는 첫 번째 UV 좌표이며 일반적으로 float2또는 float3,float4입니다.
            float2 uv : TEXCOORD0;
          };

          //보간기 : 버텍스 셰이더의 입력으로 들어간 정점데이터가 프래그넌트 셰이더의 입력으로 들어갈때 갖출 구조를 선언해줍니다.
          struct v2f {
            //SV_POSITION은 정점데이터가 레스티라이저에 의해 화면에 그려질 클리핑된 좌표를 의미한다.
            float4 position : SV_POSITION;
            //첫번째 uv데이터
            float2 uv : TEXCOORD0;
          };

          //버텍스 쉐이더
          //appdata:오브젝트의 데이터 를 입력으로 받아 v2f:보간기 를 출력한다.
          v2f vert(appdata v) {
            v2f o;
            //UnityObjectToClipPos:오브젝트의 각 정점 데이터를 화면의 픽셀데이터로 클리핑하는 함수
            o.position = UnityObjectToClipPos(v.vertex);
            //TRANSFORM_TEX(uv,uv name)은 전달된 UV좌표를 tiling과 offset에 맞게 변환해줍니다.
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            return o;
          }

          //프래그먼트 쉐이더
          //보간기로 입력을 받아 각 픽셀의 색상을 표시합니다.
          fixed4 frag(v2f i) : SV_TARGET{
            //Tex2D(texture,uv position):텍스쳐를  UV에 매핑하는 함수
            fixed4 col = tex2D(_MainTex, i.uv);
          //컬러값 곲셈
          col *= _Color;
          //이후 반환
          return col;
        }

        ENDCG
      }
    }
        Fallback "VertexLit"
}
