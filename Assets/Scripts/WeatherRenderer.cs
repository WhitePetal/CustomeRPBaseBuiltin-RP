using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace CustomeRenderPipline
{
    public class WeatherRenderer
    {
        private WeatherSettings setting;
        private RenderPiplineMainCamera rp;
        private Camera cam;
        private CommandBuffer cmd_render;

        private Light sun;

        private int sunColorId = Shader.PropertyToID("_SunColor");
        private int moonColorId = Shader.PropertyToID("_MoonColor");
        private int moonOffsetId = Shader.PropertyToID("_MoonOffset");
        private int starIntensitySpeedId = Shader.PropertyToID("_StarIntensity_StarSpeed");

        public void Setup(RenderPiplineMainCamera rp, WeatherSettings setting)
        {
            this.rp = rp;
            this.cam = rp.cam;
            this.setting = setting;

            sun = RenderSettings.sun;
            RenderSettings.skybox = setting.skyBoxMat;
        }

        private float ExecuteLightIntensity(float hourTime)
        {
            float factor = 0.0f;
            if (hourTime >= 12.0f && hourTime < 20.0f)
            {
                factor = (hourTime - 12.0f) / 8.0f;
            }
            else if (hourTime >= 20.0f)
            {
                factor = (hourTime - 36.0f) / -16.0f;
            }
            else factor = (hourTime - 12.0f) / -8.0f;
            return Mathf.Lerp(setting.maxLightIntensity, setting.minLightIntensity, factor);
        }

        private Quaternion ExecuteLightRotation(float hourTime)
        {
            if(hourTime < 6.0f)
            {
                float factor = hourTime / 6.0f;
                float angle = Mathf.Lerp(270.0f, 360.0f, factor);
                return Quaternion.Euler(angle, 0.0f, 0.0f);
            }
            else
            {
                float factor = (hourTime - 6.0f) / 24.0f;
                float angle = Mathf.Lerp(0.0f, 360.0f, factor);
                return Quaternion.Euler(angle, 0.0f, 0.0f);
            }
        }

        private float ExecuteMooneOffset(float dayTime)
        {
            if(dayTime < 15.0f)
            {
                float factor = dayTime / 15.0f;
                return Mathf.Lerp(0.0f, -setting.newMoonOffset, factor);
            }
            else
            {
                float factor = (dayTime - 15.0f) / 15.0f;
                return Mathf.Lerp(setting.newMoonOffset, 0.0f, factor);
            }
        }

        private float ExecuteStarIntensity(float dayTime)
        {
            return Mathf.Max(0f, setting.starIntensity + (Mathf.PerlinNoise(dayTime, 0.0f) * 2.0f - 1.0f) * setting.starRandomScale);
        }

        public void Render()
        {
            // Hour Time Execute
            float hourTime = setting.hourTime;
            //setting.hourTime += setting.hourSpeed * Time.deltaTime;
            //if (setting.hourTime > 24.0f) setting.hourTime = 0.0f;
            sun.intensity = ExecuteLightIntensity(hourTime);
            sun.transform.localRotation = ExecuteLightRotation(hourTime);
            float time_c = Mathf.Abs(hourTime / 24.0f - 0.5f) * 2.0f;
            time_c = Mathf.Abs (time_c - 0.5f) * 2.0f;
            Color sunColor = Color.Lerp(setting.sunDayColor, setting.sunNightColor, time_c);
            setting.skyBoxMat.SetColor(sunColorId, sunColor);

            // Day Time Execute
            float dayTime = setting.dayTime;
            //setting.dayTime += setting.hourSpeed * Time.deltaTime / 720.0f;
            //if (setting.dayTime > 30.0f) setting.dayTime = 0.0f;
            setting.skyBoxMat.SetFloat(moonOffsetId, ExecuteMooneOffset(dayTime));
            setting.skyBoxMat.SetVector(starIntensitySpeedId, new Vector4(ExecuteStarIntensity(dayTime), setting.starSpeed, 0f, 0f));
        }
    }
}
