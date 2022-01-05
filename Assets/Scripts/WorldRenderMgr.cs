using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    public class WorldGridData
    {

    }

    public class WorldRenderMgr
    {
        private Camera cam;
        private WorldRenderSetting setting;

        public void Setup(WorldRenderSetting setting, Camera cam)
        {
            this.setting = setting;
            this.cam = cam;
        }

        public void DrawGizmos()
        {
            float y = -setting.worldSize * 0.5f + setting.gridSize * 0.5f;
            //Gizmos.color = Color.black;
            while(y < setting.worldSize * 0.5f)
            {
                float x = -setting.worldSize * 0.5f + setting.gridSize * 0.5f;
                while (x < setting.worldSize * 0.5f)
                {
                    Gizmos.DrawWireCube(new Vector3(x, 0, y), new Vector3(setting.gridSize, 1.0f, setting.gridSize));
                    x += setting.gridSize * 0.5f;
                }
                y += setting.gridSize * 0.5f;
            }
        }
    }
}
