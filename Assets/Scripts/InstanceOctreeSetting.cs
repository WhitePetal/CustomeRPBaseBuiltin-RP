using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    [CreateAssetMenu(menuName = "Rendering/InstanceOctreeSetting")]
    public class InstanceOctreeSetting : ScriptableObject
    {
        public float worldSize = 1024;
        public float minGridSize = 5;
    }
}
