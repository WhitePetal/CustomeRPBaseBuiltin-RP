using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    public class QuadTreeNode
    {
        public QuadTreeNode[] nodes;

        private WorldRenderMgr worldRender;

        private int index = -1;
        private bool isFinal = false;
        private Vector2[] verts;

        public void Setup(Vector2 center, float extend, WorldRenderMgr worldRenderMgr)
        {
            this.worldRender = worldRenderMgr;
            verts = new Vector2[4]
            {
                center + new Vector2(extend, extend),
                center + new Vector2(extend, -extend),
                center + new Vector2(-extend, -extend),
                center + new Vector2(-extend, extend)
            };

            float extedn_child = extend * 0.5f;

            if(extedn_child < worldRenderMgr.setting.gridExtend)
            {
                isFinal = true;
                WorldGridData data = new WorldGridData();
                index = worldRenderMgr.worldGridDataArrCount;
                worldRenderMgr.worldGridDatas[worldRenderMgr.worldGridDataArrCount++] = data;
                return;
            }

            nodes = new QuadTreeNode[4];
            for(int i = 0; i < 4; ++i) nodes[i] = new QuadTreeNode();
            nodes[0].Setup(center + new Vector2(extedn_child, extedn_child), extedn_child, worldRenderMgr);
            nodes[1].Setup(center + new Vector2(extedn_child, -extedn_child), extedn_child, worldRenderMgr);
            nodes[2].Setup(center + new Vector2(-extedn_child, -extedn_child), extedn_child, worldRenderMgr);
            nodes[3].Setup(center + new Vector2(-extedn_child, extedn_child), extedn_child, worldRenderMgr);
        }

        public bool FrustumCulling(Vector4[] cornerPlanes)
        {
            for(int i = 0; i < 6; ++i)
            {
                // TODO: sphere dst cast
                int outSizeCount = 0;
                Vector4 plane = cornerPlanes[i];
                for (int j = 0; j < 4; ++j)
                {
                    if (Vector3.Dot(new Vector3(verts[j].x, 0f, verts[j].y), new Vector3(plane.x, plane.y, plane.z)) + plane.w < 0.0f) ++outSizeCount;
                }
                for (int j = 0; j < 4; ++j)
                {
                    if (Vector3.Dot(new Vector3(verts[j].x, worldRender.setting.worldHeight, verts[j].y), new Vector3(plane.x, plane.y, plane.z)) + plane.w < 0.0f) ++outSizeCount;
                }
                if (outSizeCount == 8) return false;
            }

            return true;
        }

        public void DrawGizmos()
        {
            if (isFinal)
            {
                Gizmos.color = new Color(index * 1.0f / worldRender.worldGridDataArrCount, 0.0f, 0.0f);
                for(int i = 1; i < 4; ++i)
                {
                    Gizmos.DrawLine(new Vector3(verts[i].x, 0f, verts[i].y), new Vector3(verts[i - 1].x, 0f, verts[i - 1].y));
                }
                Gizmos.DrawLine(new Vector3(verts[3].x, 0f, verts[3].y), new Vector3(verts[0].x, 0f, verts[0].y));
                return;
            }

            for (int i = 0; i < 4; ++i) nodes[i].DrawGizmos();
        }
    }
}
