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
            tree.Setup(Vector2.zero, worldRenderMgr.setting.gridExtend, worldRenderMgr);
        }
    }
}
