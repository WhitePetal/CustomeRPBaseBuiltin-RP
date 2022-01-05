using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    public struct AABBBox
    {
        public Vector3[] points;
        public Vector3 center;
        public float extend;

        public void Setup(Vector3 center, float extend)
        {
            this.center = center;
            this.extend = extend;
            this.points = new Vector3[8];

            // 左-上后
            points[0] = center + new Vector3(-extend, extend, -extend);
            // 右-上后
            points[1] = center + new Vector3(extend, extend, -extend);
            // 左-上前
            points[2] = center + new Vector3(-extend, extend, extend);
            // 右-上前
            points[3] = center + new Vector3(extend, extend, extend);

            // 左-下后
            points[4] = center + new Vector3(-extend, -extend, -extend);
            // 右-下后
            points[5] = center + new Vector3(extend, -extend, -extend);
            // 左-下前
            points[6] = center + new Vector3(-extend, -extend, extend);
            // 右-下前
            points[7] = center + new Vector3(extend, -extend, extend);
        }
    }
}
