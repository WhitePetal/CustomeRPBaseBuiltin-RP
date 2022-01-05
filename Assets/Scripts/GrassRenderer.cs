using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace CustomeRenderPipline
{
    public class GrassRenderer
    {
        private GrassRendererSetting setting;

        private CommandBuffer cmd_beforeRender;
        private CommandBuffer cmd_afterOpaque;
        private ComputeShader frustumCullCS;

        private int grassLine;

        private Matrix4x4[] localToWorldMatrixs;
        private Vector4[] boundBoxs;
        private int instanceCount;

        private uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
        private ComputeBuffer argsBuffer;
        private ComputeBuffer localToWorldMatrixsBuffer;
        private ComputeBuffer boundBoxsBuffer;
        private ComputeBuffer cullResultBuffer;

        public void SetUp(GrassRendererSetting setting, ComputeShader frustumCullCS, CommandBuffer cmd_beforeRender, CommandBuffer cmd_afterOpaque)
        {
            this.setting = setting;
            this.cmd_beforeRender = cmd_beforeRender;
            this.cmd_afterOpaque = cmd_afterOpaque;
            this.frustumCullCS = frustumCullCS;

            grassLine = (int)(setting.worldSize / setting.gridSize);
            instanceCount = grassLine * grassLine;
            localToWorldMatrixs = new Matrix4x4[instanceCount];
            boundBoxs = new Vector4[instanceCount];
            for(int y = 0; y < grassLine; ++y)
            {
                for(int x = 0; x < grassLine; ++x)
                {
                    Vector3 pos_world = new Vector3((x - grassLine / 2) * setting.gridSize, 0.0f, (y - grassLine / 2) * setting.gridSize);
                    localToWorldMatrixs[y * grassLine + x] = Matrix4x4.TRS(pos_world,
                        Quaternion.Euler(0.0f, Mathf.PerlinNoise(pos_world.x + x, pos_world.y + y) * 360f, 90f),
                        new Vector3(100f, 100f, 100f));

                    boundBoxs[y * grassLine + x] = new Vector4(pos_world.x, pos_world.y, pos_world.z, setting.gridSize * 0.5f);
                }
            }

            localToWorldMatrixsBuffer = new ComputeBuffer(instanceCount, 16 * sizeof(float));
            localToWorldMatrixsBuffer.SetData(localToWorldMatrixs);

            boundBoxsBuffer = new ComputeBuffer(instanceCount, 4 * sizeof(float));
            boundBoxsBuffer.SetData(boundBoxs);

            cullResultBuffer = new ComputeBuffer(instanceCount, sizeof(float) * 16, ComputeBufferType.Append);
            argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
            args[0] = (uint)setting.grassMesh.GetIndexCount(0);
            args[2] = (uint)setting.grassMesh.GetIndexStart(0);
            args[3] = (uint)setting.grassMesh.GetBaseVertex(0);
            argsBuffer.SetData(args);
        }

        public void UpdatePreRender(Vector4[] cornerPlanes)
        {
            cullResultBuffer.Release();
            //cullResultBuffer.SetCounterValue(0);
            cullResultBuffer = new ComputeBuffer(instanceCount, sizeof(float) * 16, ComputeBufferType.Append);


            cmd_beforeRender.Clear();
            cmd_beforeRender.SetComputeIntParam(frustumCullCS, "instanceCount", instanceCount);
            cmd_beforeRender.SetComputeIntParam(frustumCullCS, "grassLine", grassLine);
            cmd_beforeRender.SetComputeBufferParam(frustumCullCS, 0, "localToWorldMatrixs", localToWorldMatrixsBuffer);
            cmd_beforeRender.SetComputeVectorArrayParam(frustumCullCS, "cornerPlanes", cornerPlanes);
            cmd_beforeRender.SetComputeBufferParam(frustumCullCS, 0, "boundBoxs", boundBoxsBuffer);
            cmd_beforeRender.SetComputeBufferParam(frustumCullCS, 0, "cullresult", cullResultBuffer);
            cmd_beforeRender.DispatchCompute(frustumCullCS, 0, 1 + instanceCount / 512, 1, 1);
            cmd_beforeRender.CopyCounterValue(cullResultBuffer, argsBuffer, sizeof(uint));
            cmd_beforeRender.SetGlobalBuffer("grassPosBuffer", cullResultBuffer);
            cmd_beforeRender.DrawMeshInstancedIndirect(setting.grassMesh, 0, setting.grassMat, 0, argsBuffer);

            cmd_afterOpaque.Clear();
            cmd_afterOpaque.DrawMeshInstancedIndirect(setting.grassMesh, 0, setting.grassMat, 1, argsBuffer);
        }

        //public void SetRenderDepthCmd()
        //{
        //    if ((setting == null && setting.canRender) || cmd_beforeRender == null) return;
        //    cmd_beforeRender.Clear();
        //    cmd_beforeRender.DrawMeshInstancedIndirect(setting.grassMesh, 0, setting.grassMat, 0, argsBuffer);
        //}

        //public void SetRenderGrassCmd()
        //{
        //    if ((setting == null && setting.canRender) || cmd_beforeRender == null) return;
        //    cmd_afterOpaque.Clear();
        //    cmd_afterOpaque.DrawMeshInstancedIndirect(setting.grassMesh, 0, setting.grassMat, 1, argsBuffer);
        //}

        public void Destory()
        {
            boundBoxsBuffer.Release();
            argsBuffer.Release();
            cullResultBuffer.Release();
            localToWorldMatrixsBuffer.Release();
            argsBuffer = null;
            cullResultBuffer = null;
            localToWorldMatrixsBuffer = null;
            boundBoxsBuffer = null;
        }
    }
}
