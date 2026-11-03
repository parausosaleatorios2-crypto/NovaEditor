//
//  Shaders.metal
//  NovaRenderKit — biblioteca completa de shaders Metal
//
//  Convenções:
//    - todas as passes trabalham sobre um quad full-screen (vertex passthrough)
//    - entrada: texture2d<float, access::sample> src [[texture(0)]]
//    - outra entrada opcional em texture(1) (ex: lut, mask)
//    - parâmetros vêm em constant Uniforms& [[buffer(0)]]
//    - saída: half4 ou float4
//
//  Convenções de coordenadas:
//    - fragmentos recebem uv ∈ [0,1], (0,0) = topo-esquerdo (iOS)
//    - resolução vem via uniforms (uRes.xy em pixels)
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

// =============================================================
// Vertex: quad full-screen
// =============================================================

struct VSIn  { float2 pos [[attribute(0)]]; float2 uv [[attribute(1)]]; };
struct VSOut { float4 pos [[position]];     float2 uv; };

vertex VSOut vs_passthrough(uint vid [[vertex_id]]) {
    // 2 tris, 6 verts, cobrem [-1,1]² em NDC
    float2 verts[6] = {
        float2(-1,-1), float2( 1,-1), float2(-1, 1),
        float2(-1, 1), float2( 1,-1), float2( 1, 1)
    };
    float2 uvs[6]   = {
        float2(0,1), float2(1,1), float2(0,0),
        float2(0,0), float2(1,1), float2(1,0)
    };
    VSOut o;
    o.pos = float4(verts[vid], 0, 1);
    o.uv  = uvs[vid];
    return o;
}

// =============================================================
// Fragments
// =============================================================

constexpr sampler smp(mag_filter::linear, min_filter::linear,
                      s_address::clamp_to_edge, t_address::clamp_to_edge);

struct U_Common { float2 res; float time; float _pad; };

// 1. passthrough -----------------------------------------------
fragment float4 fs_passthrough(VSOut v [[stage_in]],
                               texture2d<float> src [[texture(0)]]) {
    return src.sample(smp, v.uv);
}

// 2. tint (apply layer opacity + optional color) --------------
struct U_Tint { float4 color; float opacity; float _pad[3]; };
fragment float4 fs_tint(VSOut v [[stage_in]],
                        texture2d<float> src [[texture(0)]],
                        constant U_Tint& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    c.rgb = mix(c.rgb, u.color.rgb, u.color.a);
    c.a *= u.opacity;
    return c;
}

// 3. gaussian blur separable ----------------------------------
// 9 taps, sigma passado em pixels. horizontal se dir=(1,0), vert se (0,1).
struct U_Blur { float2 res; float sigma; float _pad; float2 dir; float2 _pad2; };
fragment float4 fs_blur(VSOut v [[stage_in]],
                        texture2d<float> src [[texture(0)]],
                        constant U_Blur& u [[buffer(0)]]) {
    float2 texel = u.dir / u.res;
    float sigma = max(u.sigma, 0.0001);
    float sum = 0.0;
    float weights[9];
    for (int i=0;i<9;i++){
        float x = float(i-4);
        weights[i] = exp(-(x*x)/(2.0*sigma*sigma));
        sum += weights[i];
    }
    float4 c = float4(0);
    for (int i=0;i<9;i++){
        float2 off = texel * float(i-4) * sigma * 0.6;
        c += src.sample(smp, v.uv + off) * (weights[i]/sum);
    }
    return c;
}

// 4. bright pass (threshold luminance pra bloom) ---------------
struct U_Bright { float threshold; float knee; float _pad[2]; };
fragment float4 fs_bright(VSOut v [[stage_in]],
                          texture2d<float> src [[texture(0)]],
                          constant U_Bright& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    float l = dot(c.rgb, float3(0.2126, 0.7152, 0.0722));
    float m = smoothstep(u.threshold, u.threshold + u.knee + 0.0001, l);
    return float4(c.rgb * m, c.a);
}

// 5. additive combine (glow sum) -------------------------------
struct U_Add { float gain; float _pad[3]; };
fragment float4 fs_add(VSOut v [[stage_in]],
                       texture2d<float> a [[texture(0)]],
                       texture2d<float> b [[texture(1)]],
                       constant U_Add& u [[buffer(0)]]) {
    float4 A = a.sample(smp, v.uv);
    float4 B = b.sample(smp, v.uv) * u.gain;
    return float4(A.rgb + B.rgb, A.a);
}

// 6. color grade (brightness/contrast/saturation/temperature/tint) ----
struct U_Grade {
    float brightness;    // -1..1
    float contrast;      // 0..2 (1 = neutro)
    float saturation;    // 0..2
    float gamma;         // 0.1..4 (1 = neutro)
    float temperature;   // -1..1  (negativo frio, positivo quente)
    float tintG;         // -1..1  (magenta - verde)
    float exposure;      // -2..2 (stops)
    float _pad;
};
fragment float4 fs_grade(VSOut v [[stage_in]],
                         texture2d<float> src [[texture(0)]],
                         constant U_Grade& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    // exposure
    c.rgb *= exp2(u.exposure);
    // temperature (R up, B down for warm)
    c.r += u.temperature * 0.08;
    c.b -= u.temperature * 0.08;
    // tint (G axis)
    c.g += u.tintG * 0.08;
    // brightness/contrast
    c.rgb = (c.rgb - 0.5) * u.contrast + 0.5 + u.brightness;
    // gamma
    c.rgb = pow(max(c.rgb, 0.0), float3(1.0 / max(u.gamma, 0.01)));
    // saturation
    float l = dot(c.rgb, float3(0.2126, 0.7152, 0.0722));
    c.rgb = mix(float3(l), c.rgb, u.saturation);
    return float4(saturate(c.rgb), c.a);
}

// 7. LUT 3D (Apply Color LUT .cube) ----------------------------
// LUT vem como texture3d<float>. tap trilinear + strength blend.
struct U_LUT { float strength; float _pad[3]; };
fragment float4 fs_lut(VSOut v [[stage_in]],
                       texture2d<float> src [[texture(0)]],
                       texture3d<float> lut [[texture(1)]],
                       constant U_LUT& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    float4 g = lut.sample(smp, saturate(c.rgb));
    return float4(mix(c.rgb, g.rgb, saturate(u.strength)), c.a);
}

// 8. chroma key (HSL distance to key) --------------------------
struct U_Chroma {
    float4 key;         // keyed color (rgb used)
    float tolerance;    // 0..1
    float softness;     // 0..1
    float spill;        // 0..1 (spill suppression)
    float _pad;
};
float3 rgb2ycbcr(float3 c) {
    float y  = dot(c, float3(0.299, 0.587, 0.114));
    float cb = (c.b - y) * 0.564 + 0.5;
    float cr = (c.r - y) * 0.713 + 0.5;
    return float3(y, cb, cr);
}
fragment float4 fs_chroma(VSOut v [[stage_in]],
                          texture2d<float> src [[texture(0)]],
                          constant U_Chroma& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    float3 cyc  = rgb2ycbcr(c.rgb);
    float3 kyc  = rgb2ycbcr(u.key.rgb);
    float d = length(cyc.yz - kyc.yz); // só croma, Y livre
    float a = smoothstep(u.tolerance, u.tolerance + u.softness + 0.0001, d);
    // spill: zera componentes do key proporcionalmente onde a cor se parece com o key
    float spillAmt = (1.0 - saturate(d / (u.tolerance + u.softness + 0.0001))) * u.spill;
    c.rgb = mix(c.rgb, dot(c.rgb, float3(0.333)) * float3(1), spillAmt);
    return float4(c.rgb, c.a * a);
}

// 9. HSL / Hue shift -------------------------------------------
struct U_HSL { float hue; float sat; float lum; float _pad; };
float3 rgb2hsl(float3 c) {
    float M = max(c.r, max(c.g, c.b));
    float m = min(c.r, min(c.g, c.b));
    float d = M - m;
    float l = (M + m) * 0.5;
    float s = d < 1e-5 ? 0 : d / (1 - abs(2*l - 1));
    float h = 0;
    if (d > 1e-5) {
        if (M == c.r)      h = fmod((c.g - c.b) / d, 6.0);
        else if (M == c.g) h = (c.b - c.r) / d + 2.0;
        else               h = (c.r - c.g) / d + 4.0;
        h *= 60.0;
        if (h < 0) h += 360.0;
    }
    return float3(h, s, l);
}
float3 hsl2rgb(float3 hsl) {
    float h = hsl.x, s = hsl.y, l = hsl.z;
    float c = (1 - abs(2*l - 1)) * s;
    float x = c * (1 - abs(fmod(h/60.0, 2.0) - 1));
    float m = l - c * 0.5;
    float3 rgb;
    if      (h < 60)  rgb = float3(c,x,0);
    else if (h < 120) rgb = float3(x,c,0);
    else if (h < 180) rgb = float3(0,c,x);
    else if (h < 240) rgb = float3(0,x,c);
    else if (h < 300) rgb = float3(x,0,c);
    else              rgb = float3(c,0,x);
    return rgb + m;
}
fragment float4 fs_hsl(VSOut v [[stage_in]],
                       texture2d<float> src [[texture(0)]],
                       constant U_HSL& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    float3 h = rgb2hsl(c.rgb);
    h.x = fmod(h.x + u.hue + 360.0, 360.0);
    h.y = saturate(h.y * (1 + u.sat));
    h.z = saturate(h.z + u.lum);
    return float4(hsl2rgb(h), c.a);
}

// 10. levels ---------------------------------------------------
struct U_Levels { float inLo; float inHi; float gamma; float outLo; float outHi; float _pad[3]; };
fragment float4 fs_levels(VSOut v [[stage_in]],
                          texture2d<float> src [[texture(0)]],
                          constant U_Levels& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    float3 r = (c.rgb - u.inLo) / max(u.inHi - u.inLo, 1e-4);
    r = pow(max(r, 0.0), float3(1.0 / max(u.gamma, 0.01)));
    r = r * (u.outHi - u.outLo) + u.outLo;
    return float4(saturate(r), c.a);
}

// 11. sharpen (unsharp mask) -----------------------------------
struct U_Sharp { float amount; float _pad[3]; };
fragment float4 fs_sharpen(VSOut v [[stage_in]],
                           texture2d<float> src [[texture(0)]],  // original
                           texture2d<float> blurred [[texture(1)]], // blurred
                           constant U_Sharp& u [[buffer(0)]]) {
    float4 o = src.sample(smp, v.uv);
    float4 b = blurred.sample(smp, v.uv);
    return float4(o.rgb + (o.rgb - b.rgb) * u.amount, o.a);
}

// 12. film grain (hash noise) ----------------------------------
struct U_Grain { float intensity; float size; float time; float _pad; };
float hash12(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
fragment float4 fs_grain(VSOut v [[stage_in]],
                         texture2d<float> src [[texture(0)]],
                         constant U_Grain& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    float2 p = floor(v.uv * (src.get_width() / max(u.size, 1.0)));
    float n = hash12(p + u.time) - 0.5;
    return float4(c.rgb + n * u.intensity, c.a);
}

// 13. vignette --------------------------------------------------
struct U_Vignette { float radius; float softness; float strength; float _pad; };
fragment float4 fs_vignette(VSOut v [[stage_in]],
                            texture2d<float> src [[texture(0)]],
                            constant U_Vignette& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    float2 d = v.uv - 0.5;
    float r = length(d);
    float m = smoothstep(u.radius, u.radius + u.softness + 0.0001, r);
    return float4(c.rgb * mix(1.0, 1.0 - u.strength, m), c.a);
}

// 14. chromatic aberration -------------------------------------
struct U_Chrom { float amount; float2 center; float _pad; };
fragment float4 fs_chrom(VSOut v [[stage_in]],
                         texture2d<float> src [[texture(0)]],
                         constant U_Chrom& u [[buffer(0)]]) {
    float2 d = v.uv - u.center;
    float r = src.sample(smp, v.uv - d * u.amount).r;
    float g = src.sample(smp, v.uv).g;
    float b = src.sample(smp, v.uv + d * u.amount).b;
    return float4(r, g, b, 1);
}

// 15. VHS (scanlines + chroma shift + jitter + noise) ----------
struct U_VHS { float scanAmount; float chromaShift; float jitter; float noise; float time; float _pad[3]; };
fragment float4 fs_vhs(VSOut v [[stage_in]],
                       texture2d<float> src [[texture(0)]],
                       constant U_VHS& u [[buffer(0)]]) {
    float2 uv = v.uv;
    // vertical jitter in bands
    float band = sin(uv.y * 400.0 + u.time * 10.0);
    uv.x += (hash12(float2(floor(uv.y * 100.0), u.time)) - 0.5) * u.jitter * step(0.9, abs(band));
    float r = src.sample(smp, uv + float2( u.chromaShift, 0)).r;
    float g = src.sample(smp, uv).g;
    float b = src.sample(smp, uv - float2( u.chromaShift, 0)).b;
    float3 c = float3(r,g,b);
    // scanlines
    float scan = 0.5 + 0.5 * cos(uv.y * src.get_height() * 3.14);
    c *= mix(1.0, scan, u.scanAmount);
    // noise
    float n = hash12(uv * 500.0 + u.time) - 0.5;
    c += n * u.noise;
    return float4(saturate(c), 1);
}

// 16. pixelate --------------------------------------------------
struct U_Pixel { float size; float _pad[3]; };
fragment float4 fs_pixelate(VSOut v [[stage_in]],
                            texture2d<float> src [[texture(0)]],
                            constant U_Pixel& u [[buffer(0)]]) {
    float sz = max(u.size, 1.0);
    float2 res = float2(src.get_width(), src.get_height());
    float2 uv  = floor(v.uv * res / sz) * sz / res + (sz * 0.5 / res);
    return src.sample(smp, uv);
}

// 17. mirror / invert / threshold ------------------------------
fragment float4 fs_mirrorX(VSOut v [[stage_in]], texture2d<float> src [[texture(0)]]) {
    return src.sample(smp, float2(1.0 - v.uv.x, v.uv.y));
}
fragment float4 fs_mirrorY(VSOut v [[stage_in]], texture2d<float> src [[texture(0)]]) {
    return src.sample(smp, float2(v.uv.x, 1.0 - v.uv.y));
}
fragment float4 fs_invert(VSOut v [[stage_in]], texture2d<float> src [[texture(0)]]) {
    float4 c = src.sample(smp, v.uv);
    return float4(1.0 - c.rgb, c.a);
}
struct U_Th { float threshold; float _pad[3]; };
fragment float4 fs_threshold(VSOut v [[stage_in]],
                             texture2d<float> src [[texture(0)]],
                             constant U_Th& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    float l = dot(c.rgb, float3(0.2126, 0.7152, 0.0722));
    float m = step(u.threshold, l);
    return float4(float3(m), c.a);
}

// 18. directional motion blur ----------------------------------
struct U_MBlur { float2 dir; float samples; float strength; float _pad[2]; };
fragment float4 fs_motion(VSOut v [[stage_in]],
                          texture2d<float> src [[texture(0)]],
                          constant U_MBlur& u [[buffer(0)]]) {
    int n = int(max(u.samples, 1.0));
    float4 acc = float4(0);
    for (int i=-n; i<=n; i++) {
        float t = float(i) / float(n);
        acc += src.sample(smp, v.uv + u.dir * t * u.strength);
    }
    return acc / float(2*n + 1);
}

// 19. tilt-shift (center sharp, edges blurred) ------------------
// uses already-blurred texture(1) and mixes radially
struct U_Tilt { float center; float width; float _pad[2]; };
fragment float4 fs_tilt(VSOut v [[stage_in]],
                        texture2d<float> sharp [[texture(0)]],
                        texture2d<float> blur  [[texture(1)]],
                        constant U_Tilt& u [[buffer(0)]]) {
    float4 s = sharp.sample(smp, v.uv);
    float4 b = blur.sample(smp, v.uv);
    float d = abs(v.uv.y - u.center);
    float m = smoothstep(u.width * 0.5, u.width, d);
    return mix(s, b, m);
}

// 20. mask composite (video * mask) -----------------------------
fragment float4 fs_mask(VSOut v [[stage_in]],
                        texture2d<float> src  [[texture(0)]],
                        texture2d<float> mask [[texture(1)]]) {
    float4 c = src.sample(smp, v.uv);
    float4 m = mask.sample(smp, v.uv);
    return float4(c.rgb, c.a * m.r);
}

// 21. transform-aware blit (translate/scale/rotate in UV) -------
// vertex path that handles transform:
struct U_Xform {
    float4x4 mvp;      // model-view-proj
    float    opacity;
    float    _pad[3];
};
struct XVOut { float4 pos [[position]]; float2 uv; };
vertex XVOut vs_xform(uint vid [[vertex_id]],
                      constant U_Xform& u [[buffer(0)]]) {
    float2 verts[6] = {
        float2(-0.5,-0.5), float2( 0.5,-0.5), float2(-0.5, 0.5),
        float2(-0.5, 0.5), float2( 0.5,-0.5), float2( 0.5, 0.5)
    };
    float2 uvs[6] = {
        float2(0,1), float2(1,1), float2(0,0),
        float2(0,0), float2(1,1), float2(1,0)
    };
    XVOut o;
    o.pos = u.mvp * float4(verts[vid], 0, 1);
    o.uv  = uvs[vid];
    return o;
}
fragment float4 fs_xform(XVOut v [[stage_in]],
                         texture2d<float> src [[texture(0)]],
                         constant U_Xform& u [[buffer(0)]]) {
    float4 c = src.sample(smp, v.uv);
    return float4(c.rgb, c.a * u.opacity);
}

// 22. blend modes (two layers A over B) -------------------------
// mode encoded as int; chamador seleciona pipeline específico ou passa flag.
struct U_Blend { int mode; float opacity; float _pad[2]; };
float4 blend_over(float4 a, float4 b)         { return float4(a.rgb * a.a + b.rgb * (1 - a.a), a.a + b.a * (1 - a.a)); }
float4 blend_mul(float4 a, float4 b)          { return float4(a.rgb * b.rgb, a.a); }
float4 blend_screen(float4 a, float4 b)       { return float4(1 - (1 - a.rgb) * (1 - b.rgb), a.a); }
float4 blend_overlay(float4 a, float4 b)      {
    float3 r;
    r.r = b.r < 0.5 ? 2*a.r*b.r : 1 - 2*(1-a.r)*(1-b.r);
    r.g = b.g < 0.5 ? 2*a.g*b.g : 1 - 2*(1-a.g)*(1-b.g);
    r.b = b.b < 0.5 ? 2*a.b*b.b : 1 - 2*(1-a.b)*(1-b.b);
    return float4(r, a.a);
}
float4 blend_lighten(float4 a, float4 b)      { return float4(max(a.rgb, b.rgb), a.a); }
float4 blend_darken(float4 a, float4 b)       { return float4(min(a.rgb, b.rgb), a.a); }
float4 blend_diff(float4 a, float4 b)         { return float4(abs(a.rgb - b.rgb), a.a); }
float4 blend_add(float4 a, float4 b)          { return float4(a.rgb + b.rgb, a.a); }

fragment float4 fs_blend(VSOut v [[stage_in]],
                         texture2d<float> top [[texture(0)]],
                         texture2d<float> bot [[texture(1)]],
                         constant U_Blend& u [[buffer(0)]]) {
    float4 a = top.sample(smp, v.uv); a.a *= u.opacity;
    float4 b = bot.sample(smp, v.uv);
    switch (u.mode) {
        case 1:  return blend_mul(a, b);
        case 2:  return blend_screen(a, b);
        case 3:  return blend_overlay(a, b);
        case 4:  return blend_lighten(a, b);
        case 5:  return blend_darken(a, b);
        case 6:  return blend_diff(a, b);
        case 7:  return blend_add(a, b);
        default: return blend_over(a, b);
    }
}
