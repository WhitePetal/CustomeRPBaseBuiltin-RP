using System.Collections;
using System.Collections.Generic;
using UnityEngine;

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

    public Color sunDayColor = Color.red;
    public Color sunNightColor = Color.yellow;

    public float maxLightIntensity = 1.0f;
    public float minLightIntensity = 0.2f;

    public float starIntensity = 4.0f;
    public float starRandomScale = 2.0f;
    public float starSpeed = 1.0f;

    [HideInInspector] public float newMoonOffset = 0.2f;



}
