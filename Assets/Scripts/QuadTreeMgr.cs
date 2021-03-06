using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    public class QuadTreeMgr
    {
        public QuadTreeNode tree;

        public void Setup(WorldRenderMgr worldRenderMgr)
        {
            tree = new QuadTreeNode();
            tree.Setup(Vector2.zero, worldRenderMgr.setting.worldSize * 0.5f, worldRenderMgr);
        }

        public void DrawGizmos()
        {
            tree.DrawGizmos();
        }
    }
}
