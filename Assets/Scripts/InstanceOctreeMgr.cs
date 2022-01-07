using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    public class InstanceOctreeMgr
    {
        public Camera cam;

        public InstanceOctreeSetting setting;
        private InstanceOctreeNode octree;

        private Vector4[] cornePlanes;

        public void Setup(Camera cam, InstanceOctreeSetting setting)
        {
            this.cam = cam;
            this.setting = setting;
            octree = new InstanceOctreeNode();
            octree.box = new AABBBox();
            octree.box.Setup(Vector3.zero, setting.worldSize * 0.5f);
            octree.Setup(setting.minGridSize);

            cornePlanes = new Vector4[6];
            //CullTools.GetCameraConnerPlaneWorldSpace(cam, cornePlanes);
        }

        public void UpdateCamera()
        {
            //CullTools.GetCameraConnerPlaneWorldSpace(cam, cornePlanes);
        }

        public void Culling(List<InstanceOctreeNode> result)
        {
            //octree.Culling(cornePlanes, result);
        }

        public void AttachData(string name, Vector3 pos, float radius, int index)
        {
            octree.AttachData(name, pos, radius, index);
        }

        //public void DrawGizmos()
        //{
        //    octree.DrawGizmos(cornePlanes);
        //}
    }
}
