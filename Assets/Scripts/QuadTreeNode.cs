using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    public class QuadTreeNode
    {
        public QuadTreeNode[] nodes;

        private int index = -1;
        private bool isFinal = false;
        private Vector2[] verts;

        public void Setup(Vector2 center, float extend, WorldRenderMgr worldRenderMgr)
        {
            verts = new Vector2[4]
            {
                center + new Vector2(extend, extend),
                center + new Vector2(extend, -extend),
                center + new Vector2(-extend, extend),
                center + new Vector2(-extend, -extend)
            };

            if(extend <= worldRenderMgr.setting.gridExtend)
            {
                isFinal = true;
                WorldGridData data = new WorldGridData();
                worldRenderMgr.worldGridDatas[worldRenderMgr.worldGridDataArrEndIndex++] = data;
            }
        }
    }
}
