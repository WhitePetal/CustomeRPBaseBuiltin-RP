using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    [CreateAssetMenu(menuName = "Rendering/CloudFogRenderSetting")]
    public class CloudFogRenderSetting : ScriptableObject
    {
        public Vector3 cloudBoxCenter = new Vector3(0f, 20f, 0f);
        public Vector3 cloudBoxSize = new Vector3(1024f, 10f, 1024f);

        public Material cloudFogMaterial;
    }
}
