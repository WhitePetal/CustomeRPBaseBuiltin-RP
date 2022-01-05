using System.Collections;
using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;
using UnityEngine.Rendering;

namespace CustomeRenderPipline
{
    //[ImageEffectAllowedInSceneView]
    public class RenderPiplineMainCamera : MonoBehaviour
    {
        [SerializeField]
        private GrassRendererSetting grassRendererSetting;
        private GrassRenderer grassRenderer;

        [SerializeField]
        private ComputeShader frustumCullCS;

        // 八叉树CPU剔除不适合用于Instance大量物体的剔除
        //[SerializeField]
        //private InstanceOctreeSetting instanceOctreeSetting;
        //private InstanceOctreeMgr instanceOctreeMgr;

        private Camera cam;

        private CommandBuffer cmd_beforeRender;
        private CommandBuffer cmd_afterOpaque;
        private CommandBuffer cmd_afterRender;

        private int colorBufferId = Shader.PropertyToID("_ColorBuffer");
        private int depthBufferId = Shader.PropertyToID("_CustomeDepthTex");
        private RenderTexture colorBuffer;
        private RenderTexture depthBuffer;

        private Vector4[] cornerPlanes;

        private void Start()
        {
            cornerPlanes = new Vector4[6];
            grassRenderer = new GrassRenderer();

            cmd_beforeRender = new CommandBuffer();
            cmd_afterOpaque = new CommandBuffer();
            cmd_afterRender = new CommandBuffer();
            cam = GetComponent<Camera>();
            cam.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, cmd_beforeRender);
            cam.AddCommandBuffer(CameraEvent.AfterForwardOpaque, cmd_afterOpaque);
            cam.AddCommandBuffer(CameraEvent.AfterEverything, cmd_afterRender);
            

            grassRenderer.SetUp(grassRendererSetting, frustumCullCS, cmd_beforeRender, cmd_afterOpaque);


            colorBuffer = RenderTexture.GetTemporary(cam.pixelWidth, cam.pixelHeight, 0, RenderTextureFormat.Default);
            colorBuffer.name = "_ColorBuffer";
            depthBuffer = RenderTexture.GetTemporary(cam.pixelWidth, cam.pixelHeight, 24, RenderTextureFormat.Depth);
            depthBuffer.name = "_DepthBuffer";
            cam.SetTargetBuffers(colorBuffer.colorBuffer, depthBuffer.depthBuffer);

            // init render
            //grassRenderer.SetRenderDepthCmd();
            //grassRenderer.SetRenderDepthCmd();

            cmd_afterRender.Blit(colorBuffer, BuiltinRenderTextureType.CameraTarget);

            //instanceOctreeMgr = new InstanceOctreeMgr();
            //instanceOctreeMgr.Setup(cam, instanceOctreeSetting);
        }

        //private void OnDrawGizmos()
        //{
        //    if(instanceOctreeMgr != null)
        //    {
        //        instanceOctreeMgr.UpdateCamera();
        //        instanceOctreeMgr.DrawGizmos();
        //    }
        //}

        private void OnPreCull()
        {
        
        }

        private void OnPreRender()
        {
            if (cam == null) return;
            CullTools.GetCameraConnerPlaneWorldSpace(cam, cornerPlanes);
            grassRenderer.UpdatePreRender(cornerPlanes);
        }

        private void OnPostRender()
        {
        
        }

        private void OnDisable()
        {
            grassRenderer.Destory();

            cmd_beforeRender.Clear();
            cmd_afterRender.Clear();
            cmd_beforeRender = null;
            cmd_afterRender = null;
            cam.RemoveAllCommandBuffers();

            RenderTexture.ReleaseTemporary(colorBuffer);
            RenderTexture.ReleaseTemporary(depthBuffer);
        }
    }
}
