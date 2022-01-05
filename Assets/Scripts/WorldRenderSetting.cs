using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    [CreateAssetMenu(menuName = "Rendering/WorldRenderSetting")]
    public class WorldRenderSetting : ScriptableObject
    {
        public GrassRendererSetting grassRenderSetting;
        public int worldSize = 1024;
        public int gridSize = 128;

        [HideInInspector] public float gridExtend = 64;
        [HideInInspector] public int gridCount = 1024 / 128;
    }
}
