using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    [CreateAssetMenu(menuName = "Rendering/WorldRenderSetting")]
    public class WorldRenderSetting : ScriptableObject
    {
        public bool drawGizmos = false;

        public int worldSize = 1024;
        public int gridSize = 128;
        public int worldHeight = 512;

        public ComputeShader frustumCullCS;

        public WeatherSettings weatherSettings;
        public GrassRendererSetting grassRenderSetting;
        public CloudFogRenderSetting cloudFogRenderSetting;

        [HideInInspector] public float gridExtend = 64;
        [HideInInspector] public int gridCount = 1024 / 128;
    }
}
