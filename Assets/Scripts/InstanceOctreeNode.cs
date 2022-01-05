using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    public class InstanceOctreeNode
    {
        private InstanceOctreeNode[] nodes;
        private bool final = false;

        public AABBBox box;

        public Dictionary<string, List<int>> data;

        public void Setup(float minGirdSize)
        {
            if (box.extend < minGirdSize)
            {
                final = true;
                return;
            }
            final = false;
            nodes = new InstanceOctreeNode[8];
            float extend = box.extend * 0.5f;
            // 左-后上角
            nodes[0] = new InstanceOctreeNode();
            nodes[0].box = new AABBBox();
            nodes[0].box.Setup(box.center + new Vector3(-box.extend, box.extend, -box.extend) * 0.5f, extend);

            // 右-后上角
            nodes[1] = new InstanceOctreeNode();
            nodes[1].box = new AABBBox();
            nodes[1].box.Setup(box.center + new Vector3(box.extend, box.extend, -box.extend) * 0.5f, extend);

            // 左-前上角
            nodes[2] = new InstanceOctreeNode();
            nodes[2].box = new AABBBox();
            nodes[2].box.Setup(box.center + new Vector3(-box.extend, box.extend, box.extend) * 0.5f, extend);

            // 右-前上角
            nodes[3] = new InstanceOctreeNode();
            nodes[3].box = new AABBBox();
            nodes[3].box.Setup(box.center + new Vector3(box.extend, box.extend, box.extend) * 0.5f, extend);

            // 左-后下角
            nodes[4] = new InstanceOctreeNode();
            nodes[4].box = new AABBBox();
            nodes[4].box.Setup(box.center + new Vector3(-box.extend, -box.extend, -box.extend) * 0.5f, extend);

            // 右-后下角
            nodes[5] = new InstanceOctreeNode();
            nodes[5].box = new AABBBox();
            nodes[5].box.Setup(box.center + new Vector3(box.extend, -box.extend, -box.extend) * 0.5f, extend);

            // 左-前下角
            nodes[6] = new InstanceOctreeNode();
            nodes[6].box = new AABBBox();
            nodes[6].box.Setup(box.center + new Vector3(-box.extend, -box.extend, box.extend) * 0.5f, extend);

            // 右-前下角
            nodes[7] = new InstanceOctreeNode();
            nodes[7].box = new AABBBox();
            nodes[7].box.Setup(box.center + new Vector3(box.extend, -box.extend, box.extend) * 0.5f, extend);

            for(int i = 0; i < 8; ++i)
            {
                nodes[i].Setup(minGirdSize);
            }
        }

        public void Culling(CornePlane[] cornePlanes, List<InstanceOctreeNode> result)
        {
            int inCount = 0;
            for (int i = 0; i < 6; ++i)
            {
                if (CullTools.AABBBoxCastCornePlane(box, cornePlanes[i]) != CastResult.OUT) ++inCount;
            }
            if (!final)
            {
                if (inCount == 6)
                {
                    for (int i = 0; i < 8; ++i) nodes[i].Culling_AllIN(result);
                }
                else if (inCount > 1) for (int i = 0; i < 8; ++i) nodes[i].Culling(cornePlanes, result);
            }
            else
            {
                if (inCount > 1) result.Add(this);
            }
        }

        protected void Culling_AllIN(List<InstanceOctreeNode> result)
        {
            if (final) result.Add(this);
            else for (int i = 0; i < 8; ++i) nodes[i].Culling_AllIN(result);
        }

        public void AttachData(string name, Vector3 pos, float radius, int index)
        {
            int inCount = 0;
            Vector3 frontFacePoint = box.center + Vector3.forward * box.extend;
            float dot_front_face = Vector3.Dot(pos - frontFacePoint, -Vector3.forward);
            if (Mathf.Abs(dot_front_face) <= radius)
            {
                AttachData_Cast_Success(name, pos, radius, index);
                return;
            }
            else if (dot_front_face >= 0) ++inCount;

            Vector3 backFacePoint = box.center - Vector3.forward * box.extend;
            float dot_back_face = Vector3.Dot(pos - backFacePoint, Vector3.forward);
            if (Mathf.Abs(dot_back_face) <= radius)
            {
                AttachData_Cast_Success(name, pos, radius, index);
                return;
            }
            else if (dot_back_face >= 0) ++inCount;

            Vector3 topFacePoint = box.center + Vector3.up * box.extend;
            float dot_top_face = Vector3.Dot(pos - topFacePoint, -Vector3.up);
            if (Mathf.Abs(dot_top_face) <= radius)
            {
                AttachData_Cast_Success(name, pos, radius, index);
                return;
            }
            else if (dot_top_face >= 0) ++inCount;

            Vector3 bottomFacePoint = box.center - Vector3.up * box.extend;
            float dot_bottom_face = Vector3.Dot(pos - bottomFacePoint, Vector3.up);
            if (Mathf.Abs(dot_bottom_face) <= radius)
            {
                AttachData_Cast_Success(name, pos, radius, index);
                return;
            }
            else if (dot_bottom_face >= 0) ++inCount;

            Vector3 rightFacePoint = box.center + Vector3.right * box.extend;
            float dot_right_face = Vector3.Dot(pos - rightFacePoint, -Vector3.right);
            if (Mathf.Abs(dot_right_face) <= radius)
            {
                AttachData_Cast_Success(name, pos, radius, index);
                return;
            }
            else if (dot_right_face >= 0) ++inCount;

            Vector3 leftFacePoint = box.center - Vector3.right * box.extend;
            float dot_left_face = Vector3.Dot(pos - leftFacePoint, Vector3.right);
            if (Mathf.Abs(dot_left_face) <= radius)
            {
                AttachData_Cast_Success(name, pos, radius, index);
                return;
            }
            else if (dot_left_face >= 0) ++inCount;


            if (inCount == 6) AttachData_Cast_Success(name, pos, radius, index);
        }

        private void AttachData_Cast_Success(string name, Vector3 pos, float radius, int index)
        {
            if (final)
            {
                if (data == null) data = new Dictionary<string, List<int>>();
                if (!data.ContainsKey(name)) data.Add(name, new List<int>());
                data[name].Add(index);
            }
            else
            {
                for(int i = 0; i < 8; ++i)
                {
                    nodes[i].AttachData(name, pos, radius, index);
                }
            }
        }

        //public void DrawGizmos(CornePlane[] cornePlanes)
        //{
        //    int inCount = 0;
        //    for(int i = 0; i < 6; ++i)
        //    {
        //        if (CullTools.AABBBoxCastCornePlane(box, cornePlanes[i]) != CastResult.OUT) ++inCount;
        //    }
        //    //Debug.Log(inCount);
        //    if(inCount > 1) Gizmos.DrawCube(box.center, Vector3.one * box.extend * 2.0f - Vector3.one * 0.2f);
        //    if(nodes != null)
        //    {
        //        for(int i = 0; i < nodes.Length; ++i)
        //        {
        //            if (nodes[i] != null) nodes[i].DrawGizmos(cornePlanes);
        //        }
        //    }
        //}
    }
}
