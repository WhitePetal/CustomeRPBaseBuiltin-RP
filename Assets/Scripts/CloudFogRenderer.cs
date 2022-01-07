using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace CustomeRenderPipline
{
    public class CloudFogRenderer
    {
        private CloudFogRenderSetting setting;
        private RenderPiplineMainCamera rp;
        private Camera cam;
        private CommandBuffer cmd_render;
        private int postSourceId = Shader.PropertyToID("_PostSource");
        private int cloudFogRenderTempRT = Shader.PropertyToID("_CloudFogRenderTempRT");

        public void Setup(RenderPiplineMainCamera rp, CloudFogRenderSetting setting)
        {
            this.rp = rp;
            this.cam = rp.cam;
            this.setting = setting;

            cmd_render = new CommandBuffer();
            cmd_render.name = "CloudFogRender_Cmd";
            cam.AddCommandBuffer(CameraEvent.AfterForwardAlpha, cmd_render);
        }

        public void Render(Matrix4x4 cameraRays)
        {
            setting.cloudFogMaterial.SetMatrix("_CameraRays", cameraRays);
            setting.cloudFogMaterial.SetVector("_CloudBoundMax", setting.cloudBoxCenter + setting.cloudBoxSize * 0.5f);
            setting.cloudFogMaterial.SetVector("_CloudBoundMin", setting.cloudBoxCenter - setting.cloudBoxSize * 0.5f);
            cmd_render.Clear();
            cmd_render.GetTemporaryRT(cloudFogRenderTempRT, cam.pixelWidth >> 1, cam.pixelHeight >> 1, 0);
            //// DrawProcedural 不适合传入 RayMatrix 的方式
            //cmd_render.SetRenderTarget(cloudFogRenderTempRT, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            //cmd_render.SetGlobalTexture(postSourceId, rp.colorBuffer);
            //cmd_render.DrawProcedural(Matrix4x4.identity, setting. cloudFogMaterial, 0, MeshTopology.Quads, 4);
            cmd_render.Blit(rp.colorBuffer, cloudFogRenderTempRT, setting.cloudFogMaterial, 0);

            //cmd_render.SetRenderTarget(rp.colorBuffer, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, rp.depthBuffer, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
            //cmd_render.SetGlobalTexture(postSourceId, cloudFogRenderTempRT);
            //cmd_render.DrawProcedural(Matrix4x4.identity, setting.cloudFogMaterial, 1, MeshTopology.Quads, 4);
            cmd_render.Blit(cloudFogRenderTempRT, rp.colorBuffer, setting.cloudFogMaterial, 1);
            cmd_render.ReleaseTemporaryRT(cloudFogRenderTempRT);
        }

        public void Destory()
        {
            cam.RemoveCommandBuffer(CameraEvent.AfterForwardAlpha, cmd_render);
            cmd_render.Dispose();
        }
    }
}
