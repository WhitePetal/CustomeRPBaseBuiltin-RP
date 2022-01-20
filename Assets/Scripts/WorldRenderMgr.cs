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

        private QuadTreeMgr quadTree;
        private WeatherRenderer weatherRenderer;
        private GrassRenderer grassRenderer;
        private CloudFogRenderer cloudFogRenderer;


        public WorldGridData[] worldGridDatas;
        public int worldGridDataArrCount;
        public int worldCullResultCount;

        public void Setup(WorldRenderSetting setting, RenderPiplineMainCamera rp)
        {
            this.setting = setting;
            this.cam = rp.cam;

            setting.gridExtend = setting.gridSize * 0.5f;
            setting.gridCount = setting.worldSize / setting.gridSize;

            worldGridDatas = new WorldGridData[(setting.worldSize / setting.gridSize) * (setting.worldSize / setting.gridSize)];

            quadTree = new QuadTreeMgr();
            quadTree.Setup(this);

            weatherRenderer = new WeatherRenderer();
            weatherRenderer.Setup(rp, setting.weatherSettings);

            grassRenderer = new GrassRenderer();
            grassRenderer.SetUp(cam, setting.grassRenderSetting, setting.frustumCullCS);

            cloudFogRenderer = new CloudFogRenderer();
            cloudFogRenderer.Setup(rp, setting.cloudFogRenderSetting);
        }

        public void Render(Vector4[] cornerPlanes, Matrix4x4 cameraRays)
        {
            weatherRenderer.Render();
            //grassRenderer.Render(cornerPlanes);
            cloudFogRenderer.Render(cameraRays);
        }

        public void Destory()
        {
            grassRenderer.Destory();
            cloudFogRenderer.Destory();
        }

        public void DrawGizmos()
        {
            if (!setting.drawGizmos) return;
            quadTree.DrawGizmos();
        }
    }
}
