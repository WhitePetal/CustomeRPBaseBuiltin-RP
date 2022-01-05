using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    public class WorldGridData
    {
        public int index;
        public Vector2Int girdPos;
        public Vector2 position;

        public Matrix4x4[] grassMatrixs;
        public Vector4[] grassTerNormals;

        public GameObject terr_gamobject;
        public Texture2D terr_diffuse_tex;

    }

    public class WorldRenderMgr
    {
        private Camera cam;
        public WorldRenderSetting setting;

        public WorldGridData[] worldGridDatas;
        public int worldGridDataArrEndIndex;

        public void Setup(WorldRenderSetting setting, Camera cam)
        {
            this.setting = setting;
            this.cam = cam;
            setting.gridExtend = setting.gridSize * 0.5f;
            setting.gridCount = setting.worldSize / setting.gridSize;
        }

        public void DrawGizmos()
        {
            float y = -setting.worldSize * 0.5f + setting.gridExtend;
            //Gizmos.color = Color.black;
            while(y < setting.worldSize * 0.5f)
            {
                float x = -setting.worldSize * 0.5f + setting.gridExtend;
                while (x < setting.worldSize * 0.5f)
                {
                    Gizmos.DrawWireCube(new Vector3(x, 0, y), new Vector3(setting.gridSize, 1.0f, setting.gridSize));
                    x += setting.gridExtend;
                }
                y += setting.gridExtend;
            }
        }
    }
}
