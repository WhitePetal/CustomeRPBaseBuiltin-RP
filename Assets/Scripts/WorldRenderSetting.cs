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
    }
}
