/*
    This file is part of darktable,
    copyright (c) 2009--2012 johannes hanika.
    copyright (c) 2011--2013 Ulrich Pegelow

    darktable is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    darktable is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with darktable.  If not, see <http://www.gnu.org/licenses/>.
*/

inline float4 Lab_2_LCH(float4 Lab)
{
  float H = atan2(Lab.z, Lab.y);

  H = (H > 0.0f) ? H / (2.0f*M_PI_F) : 1.0f - fabs(H) / (2.0f*M_PI_F);

  float L = Lab.x;
  float C = sqrt(Lab.y*Lab.y + Lab.z*Lab.z);

  return (float4)(L, C, H, Lab.w);
}


inline float4 LCH_2_Lab(float4 LCH)
{
  float L = LCH.x;
  float a = cos(2.0f*M_PI_F*LCH.z) * LCH.y;
  float b = sin(2.0f*M_PI_F*LCH.z) * LCH.y;

  return (float4)(L, a, b, LCH.w);
}


inline float4 lab_f(float4 x)
{
  const float4 epsilon = 216.0f / 24389.0f;
  const float4 kappa = 24389.0f / 27.0f;
  return (x > epsilon) ? native_powr(x, (float4)(1.0f/3.0f)) : (kappa * x + (float4)16.0f) / ((float4)116.0f);
}


inline float4 XYZ_to_Lab(float4 xyz)
{
  float4 lab;
  const float4 d50 = (float4)(0.9642f, 1.0f, 0.8249f, 1.0f);
  xyz = lab_f(xyz / d50);
  lab.x = 116.0f * xyz.y - 16.0f;
  lab.y = 500.0f * (xyz.x - xyz.y);
  lab.z = 200.0f * (xyz.y - xyz.z);

  return lab;
}


inline float4 lab_f_inv(float4 x)
{
  const float4 epsilon = 0.206896551f;
  const float4 kappa   = 24389.0f / 27.0f;
  return (x > epsilon) ? x*x*x : ((float4)116.0f * x - (float4)16.0f)/kappa;
}


inline float4 Lab_to_XYZ(float4 Lab)
{
  const float4 d50 = (float4)(0.9642f, 1.0f, 0.8249f, 0.0f);
  float4 f;
  f.y = (Lab.x + 16.0f)/116.0f;
  f.x = Lab.y/500.0f + f.y;
  f.z = f.y - Lab.z/200.0f;
  return d50 * lab_f_inv(f);
}

inline float4 prophotorgb_to_XYZ(float4 rgb)
{
  const float rgb_to_xyz[3][3] = { // prophoto rgb
    {0.7976749f, 0.1351917f, 0.0313534f},
    {0.2880402f, 0.7118741f, 0.0000857f},
    {0.0000000f, 0.0000000f, 0.8252100f},
  };
  float4 XYZ = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
  XYZ.x += rgb_to_xyz[0][0] * rgb.x;
  XYZ.x += rgb_to_xyz[0][1] * rgb.y;
  XYZ.x += rgb_to_xyz[0][2] * rgb.z;
  XYZ.y += rgb_to_xyz[1][0] * rgb.x;
  XYZ.y += rgb_to_xyz[1][1] * rgb.y;
  XYZ.y += rgb_to_xyz[1][2] * rgb.z;
  XYZ.z += rgb_to_xyz[2][0] * rgb.x;
  XYZ.z += rgb_to_xyz[2][1] * rgb.y;
  XYZ.z += rgb_to_xyz[2][2] * rgb.z;
  return XYZ;
}

inline float4 XYZ_to_prophotorgb(float4 XYZ)
{
  const float xyz_to_rgb[3][3] = { // prophoto rgb d50
    { 1.3459433f, -0.2556075f, -0.0511118f},
    {-0.5445989f,  1.5081673f,  0.0205351f},
    { 0.0000000f,  0.0000000f,  1.2118128f},
  };
  float4 rgb = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
  rgb.x += xyz_to_rgb[0][0] * XYZ.x;
  rgb.x += xyz_to_rgb[0][1] * XYZ.y;
  rgb.x += xyz_to_rgb[0][2] * XYZ.z;
  rgb.y += xyz_to_rgb[1][0] * XYZ.x;
  rgb.y += xyz_to_rgb[1][1] * XYZ.y;
  rgb.y += xyz_to_rgb[1][2] * XYZ.z;
  rgb.z += xyz_to_rgb[2][0] * XYZ.x;
  rgb.z += xyz_to_rgb[2][1] * XYZ.y;
  rgb.z += xyz_to_rgb[2][2] * XYZ.z;
  return rgb;
}

inline float4 Lab_to_prophotorgb(float4 Lab)
{
  float4 XYZ = Lab_to_XYZ(Lab);
  return XYZ_to_prophotorgb(XYZ);
}

inline float4 prophotorgb_to_Lab(float4 rgb)
{
  float4 XYZ = prophotorgb_to_XYZ(rgb);
  return XYZ_to_Lab(XYZ);
}

inline float4 RGB_2_HSL(const float4 RGB)
{
  float H, S, L;

  // assumes that each channel is scaled to [0; 1]
  float R = RGB.x;
  float G = RGB.y;
  float B = RGB.z;

  float var_Min = fmin(R, fmin(G, B));
  float var_Max = fmax(R, fmax(G, B));
  float del_Max = var_Max - var_Min;

  L = (var_Max + var_Min) / 2.0f;

  if (del_Max < 1e-6f)
  {
    H = 0.0f;
    S = 0.0f;
  }
  else
  {
    if (L < 0.5f) S = del_Max / (var_Max + var_Min);
    else          S = del_Max / (2.0f - var_Max - var_Min);

    float del_R = (((var_Max - R) / 6.0f) + (del_Max / 2.0f)) / del_Max;
    float del_G = (((var_Max - G) / 6.0f) + (del_Max / 2.0f)) / del_Max;
    float del_B = (((var_Max - B) / 6.0f) + (del_Max / 2.0f)) / del_Max;

    if      (R == var_Max) H = del_B - del_G;
    else if (G == var_Max) H = (1.0f / 3.0f) + del_R - del_B;
    else if (B == var_Max) H = (2.0f / 3.0f) + del_G - del_R;

    if (H < 0.0f) H += 1.0f;
    if (H > 1.0f) H -= 1.0f;
  }

  return (float4)(H, S, L, RGB.w);
}



inline float Hue_2_RGB(float v1, float v2, float vH)
{
  if (vH < 0.0f) vH += 1.0f;
  if (vH > 1.0f) vH -= 1.0f;
  if ((6.0f * vH) < 1.0f) return (v1 + (v2 - v1) * 6.0f * vH);
  if ((2.0f * vH) < 1.0f) return (v2);
  if ((3.0f * vH) < 2.0f) return (v1 + (v2 - v1) * ((2.0f / 3.0f) - vH) * 6.0f);
  return (v1);
}



inline float4 HSL_2_RGB(const float4 HSL)
{
  float R, G, B;

  float H = HSL.x;
  float S = HSL.y;
  float L = HSL.z;

  float var_1, var_2;

  if (S < 1e-6f)
  {
    R = B = G = L;
  }
  else
  {
    if (L < 0.5f) var_2 = L * (1.0f + S);
    else          var_2 = (L + S) - (S * L);

    var_1 = 2.0f * L - var_2;

    R = Hue_2_RGB(var_1, var_2, H + (1.0f / 3.0f));
    G = Hue_2_RGB(var_1, var_2, H);
    B = Hue_2_RGB(var_1, var_2, H - (1.0f / 3.0f));
  }

  // returns RGB scaled to [0; 1] for each channel
  return (float4)(R, G, B, HSL.w);
}

inline float4 RGB_2_HSV(const float4 RGB)
{
  float4 HSV;

  float minv = fmin(RGB.x, fmin(RGB.y, RGB.z));
  float maxv = fmax(RGB.x, fmax(RGB.y, RGB.z));
  float delta = maxv - minv;

  HSV.z = maxv;
  HSV.w = RGB.w;

  if (fabs(maxv) > 1e-6f && fabs(delta) > 1e-6f)
  {
    HSV.y = delta / maxv;
  }
  else
  {
    HSV.x = 0.0f;
    HSV.y = 0.0f;
    return HSV;
  }

  if (RGB.x == maxv)
   HSV.x = (RGB.y - RGB.z) / delta;
  else if (RGB.y == maxv)
   HSV.x = 2.0f + (RGB.z - RGB.x) / delta;
  else
   HSV.x = 4.0f + (RGB.x - RGB.y) / delta;

  HSV.x /= 6.0f;

  if(HSV.x < 0)
    HSV.x += 1.0f;

  return HSV;
}

inline float4 HSV_2_RGB(const float4 HSV)
{
  float4 RGB;

  if (fabs(HSV.y) < 1e-6f)
  {
    RGB.x = RGB.y = RGB.z = HSV.z;
    RGB.w = HSV.w;
    return RGB;
  }

  int i = floor(6.0f*HSV.x);
  float v = HSV.z;
  float w = HSV.w;
  float p = v * (1.0f - HSV.y);
  float q = v * (1.0f - HSV.y * (6.0f*HSV.x - i));
  float t = v * (1.0f - HSV.y * (1.0f - (6.0f*HSV.x - i)));

  switch (i)
  {
    case 0:
      RGB = (float4)(v, t, p, w);
      break;
    case 1:
      RGB = (float4)(q, v, p, w);
      break;
    case 2:
      RGB = (float4)(p, v, t, w);
      break;
    case 3:
      RGB = (float4)(p, q, v, w);
      break;
    case 4:
      RGB = (float4)(t, p, v, w);
      break;
    case 5:
    default:
      RGB = (float4)(v, p, q, w);
      break;
  }
  return RGB;
}


// XYZ -> sRGB matrix, D65
inline float4 XYZ_to_sRGB(float4 XYZ)
{
  float4 sRGB;

  sRGB.x =  3.1338561f * XYZ.x - 1.6168667f * XYZ.y - 0.4906146f * XYZ.z;
  sRGB.y = -0.9787684f * XYZ.x + 1.9161415f * XYZ.y + 0.0334540f * XYZ.z;
  sRGB.z =  0.0719453f * XYZ.x - 0.2289914f * XYZ.y + 1.4052427f * XYZ.z;
  sRGB.w = XYZ.w;

  return sRGB;
}


// sRGB -> XYZ matrix, D65
inline float4 sRGB_to_XYZ(float4 sRGB)
{
  float4 XYZ;

  XYZ.x = 0.4360747f * sRGB.x + 0.3850649f * sRGB.y + 0.1430804f * sRGB.z;
  XYZ.y = 0.2225045f * sRGB.x + 0.7168786f * sRGB.y + 0.0606169f * sRGB.z;
  XYZ.z = 0.0139322f * sRGB.x + 0.0971045f * sRGB.y + 0.7141733f * sRGB.z;
  XYZ.w = sRGB.w;

  return XYZ;
}


inline float4 XYZ_to_JzAzBz(float4 XYZ_D65)
{
  const float4 Mx = (float4)(0.41478972f, 0.579999f, 0.0146480f, 0.0f);
  const float4 My = (float4)(-0.2015100f, 1.120649f, 0.0531008f, 0.0f);
  const float4 Mz = (float4)(-0.0166008f, 0.264800f, 0.6684799f, 0.0f);

  const float4 Ax = (float4)(0.5f, 0.5f, 0.0f, 0.0f);
  const float4 Ay = (float4)(3.524000f, -4.066708f, 0.542708f, 0.0f);
  const float4 Az = (float4)(0.199076f, 1.096799f, -1.295875f, 0.0f);

  float4 temp1, temp2;
  // XYZ -> X'Y'Z
  temp1.x = 1.15f * XYZ_D65.x - 0.15f * XYZ_D65.z;
  temp1.y = 0.66f * XYZ_D65.y + 0.34f * XYZ_D65.x;
  temp1.z = XYZ_D65.z;
  // X'Y'Z -> LMS
  temp2.x = Mx.x * temp1.x + Mx.y * temp1.y + Mx.z * temp1.z;
  temp2.y = My.x * temp1.x + My.y * temp1.y + My.z * temp1.z;
  temp2.z = Mz.x * temp1.x + Mz.y * temp1.y + Mz.z * temp1.z;
  // LMS -> L'M'S'
  temp2 = native_powr(fmax(temp2 / 10000.f, 0.0f), 0.159301758f);
  temp2 = native_powr((0.8359375f + 18.8515625f * temp2) / (1.0f + 18.6875f * temp2), 134.034375f);
  // L'M'S' -> Izazbz
  temp1.x = Ax.x * temp2.x + Ax.y * temp2.y;
  temp1.y = Ay.x * temp2.x + Ay.y * temp2.y + Ay.z * temp2.z;
  temp1.z = Az.x * temp2.x + Az.y * temp2.y + Az.z * temp2.z;
  // Iz -> Jz
  temp1.x = 0.44f * temp1.x / (1.0f - 0.56f * temp1.x) - 1.6295499532821566e-11f;
  temp1.w = XYZ_D65.w;
  return temp1;
}

inline float4 JzAzBz_to_JzCzhz(float4 JzAzBz)
{
  float h = atan2(JzAzBz.z, JzAzBz.y) / (2.0f * M_PI_F);
  float4 JzCzhz;
  JzCzhz.x = JzAzBz.x;
  JzCzhz.y = native_sqrt(JzAzBz.y * JzAzBz.y + JzAzBz.z * JzAzBz.z);
  JzCzhz.z = (h >= 0.0f) ? h : 1.0f + h;
  JzCzhz.w = JzAzBz.w;
  return JzCzhz;
}
