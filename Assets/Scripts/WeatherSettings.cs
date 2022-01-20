using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CustomeRenderPipline
{
    [CreateAssetMenu(menuName = "Rendering/WeatherSetting")]
    public class WeatherSettings : ScriptableObject
    {
        public Material skyBoxMat;

        public float hourSpeed = 1.0f;
        [Range(0.0f, 24.0f)]
        public float hourTime = 0.5f;
        [Range(0.0f, 30.0f)]
        public float dayTime = 20.0f;
        [Range(0.0f, 12.0f)]
        public float monthTime = 1.0f;

        [Range(0.0f, 1.0f)]
        public float rain = 0.0f;

        [Header("光源设置")]
        public Color sunDayColor = Color.red;
        public Color sunNightColor = Color.yellow;

        public float maxLightIntensity = 1.0f;
        public float minLightIntensity = 0.2f;

        [Header("星星设置")]
        public float starIntensity = 4.0f;
        public float starRandomScale = 2.0f;
        public float starSpeed = 1.0f;

        [Header("云设置")]
        public Color cloudColor_rain = new Color(.8f, .8f, .8f);
        public float cloudCutout_rain = 0.544f;
        public float cloudThiness_rain = 0.445f;
        public float cloudSpeed_rain = 1f;
        public float cloudDensity_rain = 3f;
        public Color cloudColor_sun = new Color(1f, 1f, 1f);
        public float cloudCutout_sun = 0.845f;
        public float cloudThiness_sun = 0.36f;
        public float cloudSpeed_sun = 4f;
        public float cloudDensity_sun = 1.0f;
        public float cloudSize = 0.04f;

        [Header("雨设置")]
        public GameObject rainPrefab;

        [HideInInspector] public float newMoonOffset = 0.2f;



    }
}
