using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    [CreateAssetMenu(menuName = "Rendering/GrassRenderSetting")]
    public class GrassRendererSetting : ScriptableObject
    {
        public bool frustumCullEnable = true;
        public Mesh grassMesh;
        public Material grassMat;
        
        public int worldSize = 10;
        public float gridSize = 0.2f;

        public bool canRender
        {
            get
            {
                return grassMesh != null && grassMat != null;
            }
        }
    }
}
