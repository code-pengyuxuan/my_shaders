Shader "Unlit/ToonShading"
{
    Properties
    {
        _Color ("Color Tint",Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Ramp ("Ramp Texture",2D) = "White" {}
        _RampScale ("Ramp Scale",Range(0.1,2)) = 1
        _Outline ("Outline",Range(0,0.002)) = 0.001
        _OutlineColor ("Outline Color",Color) = (0,0,0,1)
        _Specular ("Specular",Color) = (1,1,1,1)
        _SpecularScale (" Specular Scale",Range(0,0.1)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {   
            NAME "OUTLINE"
            cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tan : TANGENT;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            float4 _Ramp_ST;
            fixed _Outline;
            fixed4 _OutlineColor;
            fixed4 _Specular;
            float _SpecularScale;

            v2f vert (appdata v)
            {
                v2f o;
                float3 vertex = UnityObjectToViewPos(v.vertex.xyz);
                float3 normal = normalize(UnityObjectToViewPos(v.tan.xyz));
                normal.z = -0.5;
                float3 pos = vertex + UnityObjectToViewPos(v.normal) * _Outline;

                o.vertex = UnityViewToClipPos(pos);
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                return float4(_OutlineColor.rgb,1);
                //return float4(i.color,1);
            }
            ENDCG
        }
         Pass
        {   
            Tags {"LightMode" = "ForwardBase"}
            cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)

            };

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            float _RampScale;
            float4 _Ramp_ST;
            fixed _Outline;
            fixed4 _OutlineColor;
            fixed4 _Specular;
            float _SpecularScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv , _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = UnityObjectToWorldDir(v.vertex.xyz).xyz;
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_SHADOW(o);
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                fixed4 c = tex2D (_MainTex,i.uv);
                fixed3 albedo = c.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xzy * albedo;
                UNITY_LIGHT_ATTENUATION (atten ,i ,i.worldPos);

                fixed diff = dot(worldNormal,worldLightDir);
                diff = (diff*0.5 + 0.5) *atten;

                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D (_Ramp,float2(_RampScale *diff,0)).rgb ;

                fixed spec = dot(worldNormal,worldHalfDir );
                fixed w = fwidth( spec) * 2.0;
                fixed3 specular = _Specular.rgb * lerp(0,1 , smoothstep(-w,w,spec + _SpecularScale -1)) * step(0.0001,_SpecularScale);


                return float4(ambient + diffuse + specular ,1.0);
                //return float4(1, 1,1 ,1.0);
            }
            ENDCG
        }
       
    }
    
    Fallback "Diffuse"

}
