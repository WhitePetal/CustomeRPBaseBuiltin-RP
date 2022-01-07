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
#if UNITY_EDITOR
        [SerializeField] private bool drawGizmos = false;
#endif

        [SerializeField]
        private WorldRenderSetting worldRenderSetting;
        private WorldRenderMgr worldRenderMgr;

        // 八叉树CPU剔除不适合用于Instance大量物体的剔除
        //[SerializeField]
        //private InstanceOctreeSetting instanceOctreeSetting;
        //private InstanceOctreeMgr instanceOctreeMgr;

        [HideInInspector] public Camera cam;

        private CommandBuffer cmd_beforeRender;
        private CommandBuffer cmd_afterOpaque;
        private CommandBuffer cmd_afterRender;

        private int colorBufferId = Shader.PropertyToID("_ColorBuffer");
        private int depthBufferId = Shader.PropertyToID("_CustomeDepthTex");
        [HideInInspector] public RenderTexture colorBuffer;
        [HideInInspector] public RenderTexture depthBuffer;

        private Vector4[] cornerPlanes;
        private Matrix4x4 camerRays;

        private void Start()
        {
            cornerPlanes = new Vector4[6];
            camerRays = new Matrix4x4();
            worldRenderMgr = new WorldRenderMgr();

            cmd_beforeRender = new CommandBuffer();
            cmd_afterOpaque = new CommandBuffer();
            cmd_afterRender = new CommandBuffer();
            cam = GetComponent<Camera>();
            cam.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, cmd_beforeRender);
            cam.AddCommandBuffer(CameraEvent.AfterForwardOpaque, cmd_afterOpaque);
            cam.AddCommandBuffer(CameraEvent.AfterEverything, cmd_afterRender);

            colorBuffer = RenderTexture.GetTemporary(cam.pixelWidth, cam.pixelHeight, 0, RenderTextureFormat.Default);
            colorBuffer.name = "_ColorBuffer";
            depthBuffer = RenderTexture.GetTemporary(cam.pixelWidth, cam.pixelHeight, 24, RenderTextureFormat.Depth);
            depthBuffer.name = "_DepthBuffer";

            cam.SetTargetBuffers(colorBuffer.colorBuffer, depthBuffer.depthBuffer);

            worldRenderMgr.Setup(worldRenderSetting, this);

            cmd_beforeRender.SetGlobalTexture(depthBufferId, depthBuffer);

            // init render
            //grassRenderer.SetRenderDepthCmd();
            //grassRenderer.SetRenderDepthCmd();
            cmd_afterRender.Blit(colorBuffer, BuiltinRenderTextureType.CameraTarget);

            //instanceOctreeMgr = new InstanceOctreeMgr();
            //instanceOctreeMgr.Setup(cam, instanceOctreeSetting);
        }

        private void OnDrawGizmos()
        {
            //if (instanceOctreeMgr != null)
            //{
            //    instanceOctreeMgr.UpdateCamera();
            //    instanceOctreeMgr.DrawGizmos();
            //}
#if UNITY_EDITOR
            if (drawGizmos)
            {
                if(worldRenderMgr != null) worldRenderMgr.DrawGizmos();
            }
#endif
        }

        private void OnPreRender()
        {
            if (cam == null) return;
            //if(colorBuffer != null) RenderTexture.ReleaseTemporary(colorBuffer);
            //if(depthBuffer != null) RenderTexture.ReleaseTemporary(depthBuffer);
            //colorBuffer = RenderTexture.GetTemporary(cam.pixelWidth, cam.pixelHeight, 0, RenderTextureFormat.Default);
            //colorBuffer.name = "_ColorBuffer";
            //depthBuffer = RenderTexture.GetTemporary(cam.pixelWidth, cam.pixelHeight, 24, RenderTextureFormat.Depth);
            //depthBuffer.name = "_DepthBuffer";
            //cam.SetTargetBuffers(colorBuffer.colorBuffer, depthBuffer.depthBuffer);


            camerRays = CullTools.GetCameraConnerPlaneAndRaysWorldSpace(cam, cornerPlanes);
            worldRenderMgr.Render(cornerPlanes, camerRays);
        }

        private void OnDisable()
        {
            worldRenderMgr.Destory();
            cmd_beforeRender.Clear();
            cmd_afterRender.Clear();
            cmd_beforeRender = null;
            cmd_afterRender = null;
            cam.RemoveAllCommandBuffers();
            if (colorBuffer != null) RenderTexture.ReleaseTemporary(colorBuffer);
            if (depthBuffer != null) RenderTexture.ReleaseTemporary(depthBuffer);
        }
    }
}
