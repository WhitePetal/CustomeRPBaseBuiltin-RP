using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    public enum CastResult
    {
        OUT,
        IN,
        INTERSECT
    }

    public class CullTools
    {
        public static void GetCameraConnerPlaneWorldSpace(Camera cam, Vector4[] results)
        {

            Vector3 cam_pos = cam.transform.position;
            Vector3 cam_forward = cam.transform.forward;
            float farPlane = cam.farClipPlane;
            float nearPlane = cam.nearClipPlane;
            float aspect = cam.aspect;

            Vector3 viewport_center = cam_pos+ cam_forward * farPlane;
            Vector3 viewport_up_half = Mathf.Tan(Mathf.Deg2Rad * cam.fieldOfView * 0.5f) * farPlane * cam.transform.up;
            Vector3 viewport_right_half = viewport_up_half.magnitude * aspect * cam.transform.right;
            Vector3 viewport_tl = viewport_center + viewport_up_half - viewport_right_half;
            Vector3 viewport_tr = viewport_tl + 2.0f * viewport_right_half;
            Vector3 viewport_bl = viewport_tl - 2.0f * viewport_up_half;
            Vector3 viewport_br = viewport_tr - 2.0f * viewport_up_half;

            CornePlane[] cornePlanes = new CornePlane[6];
            // f、back、t、bottom、l、r
            cornePlanes[0] = new CornePlane
            {
                normal = cam_forward,
                d = -Vector3.Dot(cam_forward, cam_pos + cam_forward * nearPlane),
            };

            cornePlanes[1] = new CornePlane
            {
                normal = -cam_forward,
                d = -Vector3.Dot(-cam_forward, viewport_center),
            };

            cornePlanes[2] = GetCornerPlaneFromPoints(cam_pos, viewport_tl, viewport_tr);

            cornePlanes[3] = GetCornerPlaneFromPoints(cam_pos, viewport_br, viewport_bl);

            cornePlanes[4] = GetCornerPlaneFromPoints(cam_pos, viewport_bl, viewport_tl);

            cornePlanes[5] = GetCornerPlaneFromPoints(cam_pos, viewport_tr, viewport_br);

            for(int i = 0; i < 6; ++i)
            {
                Vector3 n = cornePlanes[i].normal;
                results[i] = new Vector4(n.x, n.y, n.z, cornePlanes[i].d);
            }
        }

        public static float PointCastCornePlane(Vector3 point, CornePlane cornePlane)
        {
            return Vector3.Dot(point, cornePlane.normal) + cornePlane.d;
        }

        public static CastResult AABBBoxCastCornePlane(AABBBox box, CornePlane plane)
        {
            int inCount = 0;
            for(int i = 0; i < 8; ++i)
            {
                if (PointCastCornePlane(box.points[i], plane) >= 0) inCount++;
            }

            if (inCount == 0) return CastResult.OUT;
            if (inCount == 8) return CastResult.IN;
            return CastResult.INTERSECT;
        }

        private static CornePlane GetCornerPlaneFromPoints(Vector3 a, Vector3 b, Vector3 c)
        {
            CornePlane cornePlane;
            cornePlane.normal = Vector3.Cross(a - b, c - a).normalized;
            cornePlane.d = -Vector3.Dot(cornePlane.normal, a);
            return cornePlane;
        }
    }
}
