Shader "LifeGame/Simulation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Initialize ("Initialize (0: Run, 1: Reset)", Float) = 0
        _Seed ("Random Seed", Float) = 0
        _Threshold ("Init Threshold", Range(0, 1)) = 0.5
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
            float _Initialize;
            float _Seed;
            float _Threshold;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // Pseudo-random function
            float random (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123 + _Seed);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Initialization logic
                if (_Initialize > 0.5)
                {
                    float r = random(i.uv);
                    return step(_Threshold, r);
                }

                // Game of Life Logic
                float2 pixelSize = _MainTex_TexelSize.xy;
                
                // Count neighbors
                float neighbors = 0;
                
                // Neighbors loop (3x3 grid except center)
                for (int x = -1; x <= 1; x++)
                {
                    for (int y = -1; y <= 1; y++)
                    {
                        if (x == 0 && y == 0) continue;
                        
                        float2 offset = float2(x, y) * pixelSize;
                        neighbors += tex2D(_MainTex, i.uv + offset).r;
                    }
                }

                float current = tex2D(_MainTex, i.uv).r;
                float nextState = 0;

                // Rules
                // 1. Underpopulation: < 2 -> Dead
                // 2. Survival: 2 or 3 -> Alive
                // 3. Overpopulation: > 3 -> Dead
                // 4. Reproduction: 3 -> Alive
                
                if (current > 0.5)
                {
                    // Currently Alive
                    if (neighbors >= 1.9 && neighbors <= 3.1)
                    {
                        nextState = 1.0;
                    }
                }
                else
                {
                    // Currently Dead
                    if (neighbors >= 2.9 && neighbors <= 3.1)
                    {
                        nextState = 1.0;
                    }
                }

                return fixed4(nextState, nextState, nextState, 1.0);
            }
            ENDCG
        }
    }
}
