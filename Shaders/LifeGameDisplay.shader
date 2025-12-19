Shader "LifeGame/Display"
{
    Properties
    {
        _MainTex ("Texture (Simulation Result)", 2D) = "white" {}
        _GridResolution ("Grid Resolution (Match Simulation)", Float) = 64
        [Enum(Square, 0, Round, 1)] _ShapeType ("Shape Type", Float) = 0
        _Padding ("Shape Padding", Range(0, 0.5)) = 0.05
        
        [Header(Colors)]
        [HDR] _AliveColor ("Alive Color", Color) = (0, 1, 0, 1)
        _DeadColor ("Dead Color", Color) = (0, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // No fog needed typically, but good practice
            #pragma multi_compile_fog 

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float _GridResolution;
            float _ShapeType;
            float _Padding;
            fixed4 _AliveColor;
            fixed4 _DeadColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 1. Calculate Grid Coordinates
                float2 gridUV = i.uv * _GridResolution;
                float2 cellUV = frac(gridUV) - 0.5; // Local coordinates (-0.5 to 0.5)
                
                // 2. Sample the Simulation Texture
                // Sample at the center of the logical block to avoid filtering artifacts
                float2 samplePos = (floor(gridUV) + 0.5) / _GridResolution;
                
                // Clamp to prevent wrap-around bleeding at edges if Clamp mode isn't set
                samplePos = clamp(samplePos, 0, 1);

                float state = tex2D(_MainTex, samplePos).r;
                
                // 3. Shape Logic (Procedural Anti-Aliasing)
                float shapeDist = 0;
                if (_ShapeType < 0.5) // Square
                {
                    shapeDist = max(abs(cellUV.x), abs(cellUV.y));
                }
                else // Round
                {
                    shapeDist = length(cellUV);
                }

                // Determine shape edge (0.5 for full cell - padding)
                float edge = 0.5 - _Padding;
                
                // Soft edge for AA (derivative based on screen space)
                // fwidth gives rough pixel size in UV space
                float aa = fwidth(shapeDist); 
                float shapeAlpha = 1.0 - smoothstep(edge - aa, edge, shapeDist);

                // 4. Color Logic
                // If state is 0 (dead), we treat it as background
                // But typically user wants to see background color everywhere, 
                // and foreground color only where alive AND within shape.
                
                // Determine 'Cell Color' based on state
                // If Cell is Dead -> DeadColor
                // If Cell is Alive -> Mix DeadColor and AliveColor based on Shape
                
                // Logic:
                // Base is DeadColor.
                // If Alive, draw Shape in AliveColor on top.
                
                // Check if Alive (using threshold 0.5)
                float isAlive = step(0.5, state);

                fixed4 finalColor = _DeadColor;
                
                // LERP: Base -> AliveColor based on (isAlive * shapeAlpha)
                finalColor = lerp(finalColor, _AliveColor, isAlive * shapeAlpha);

                return finalColor;
            }
            ENDCG
        }
    }
}
