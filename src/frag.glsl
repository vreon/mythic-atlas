#extension GL_OES_standard_derivatives : enable

#define NUM_INFLUENCES 10

precision mediump float;
varying vec2 vUv;
uniform float time;
uniform float seed;
uniform mat3 canvasTransform;
uniform mat3 influenceTransforms[NUM_INFLUENCES];
// BUG[uniform1fv]: this should be a float[] but regl chokes
// See https://github.com/regl-project/regl/issues/611
uniform vec2 influenceFactors[NUM_INFLUENCES];
uniform float noiseFactor;
uniform float reliefFactor;
uniform float borderFactor;

uniform vec3 paletteDeepWater;
uniform vec3 paletteShallowWater;
uniform vec3 paletteShore;
uniform vec3 paletteLand;
uniform vec3 paletteMountain;
uniform vec3 palettePeak;

const float p_colormap_0_pos = 0.000000000;
const float p_colormap_1_pos = 0.089701000;
const float p_colormap_2_pos = 0.094684000;
const float p_colormap_3_pos = 0.187708000;
const float p_colormap_4_pos = 0.906977000;
const float p_colormap_5_pos = 1.000000000;

vec3 colormap(float x) {
    if (x < p_colormap_0_pos) {
        return paletteDeepWater;
    } else if (x < p_colormap_1_pos) {
        return mix(paletteDeepWater, paletteShallowWater, ((x-p_colormap_0_pos)/(p_colormap_1_pos-p_colormap_0_pos)));
    } else if (x < p_colormap_2_pos) {
        return mix(paletteShallowWater, paletteShore, ((x-p_colormap_1_pos)/(p_colormap_2_pos-p_colormap_1_pos)));
    } else if (x < p_colormap_3_pos) {
        return mix(paletteShore, paletteLand, ((x-p_colormap_2_pos)/(p_colormap_3_pos-p_colormap_2_pos)));
    } else if (x < p_colormap_4_pos) {
        return mix(paletteLand, paletteMountain, ((x-p_colormap_3_pos)/(p_colormap_4_pos-p_colormap_3_pos)));
    } else if (x < p_colormap_5_pos) {
        return mix(paletteMountain, palettePeak, ((x-p_colormap_4_pos)/(p_colormap_5_pos-p_colormap_4_pos)));
    }
    return palettePeak;
}

float rand(vec2 x) {
    return fract(cos(mod(dot(x, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}

vec2 rand2(vec2 x) {
    return fract(cos(mod(vec2(dot(x, vec2(13.9898, 8.141)),
        dot(x, vec2(3.4562, 17.398))), vec2(3.14))) * 43758.5453);
}

vec3 rand3(vec2 x) {
    return fract(cos(mod(vec3(dot(x, vec2(13.9898, 8.141)),
        dot(x, vec2(3.4562, 17.398)),
        dot(x, vec2(13.254, 5.867))), vec3(3.14))) * 43758.5453);
}

float perlin(vec2 uv, vec2 size, float persistence, float seed) {
    vec2 seed2 = rand2(vec2(seed, 1.0-seed));
    float rv = 0.0;
    float coef = 1.0;
    float acc = 0.0;
    for (int i = 0; i < 10; ++i) {
        vec2 step = vec2(1.0)/size;
        vec2 xy = floor(uv*size);
        float f0 = rand(seed2+mod(xy, size));
        float f1 = rand(seed2+mod(xy+vec2(1.0, 0.0), size));
        float f2 = rand(seed2+mod(xy+vec2(0.0, 1.0), size));
        float f3 = rand(seed2+mod(xy+vec2(1.0, 1.0), size));
        vec2 mixval = smoothstep(0.0, 1.0, fract(uv*size));
        rv += coef * mix(mix(f0, f1, mixval.x), mix(f2, f3, mixval.x), mixval.y);
        acc += coef;
        size *= 2.0;
        coef *= persistence;
    }
    return rv / acc;
}

vec2 perlin_warp(vec2 uv, float amount, vec2 size, float persistence, float seed) {
    float epsilon = 0.1;
    return uv + amount * vec2(
        perlin(fract(uv+vec2(epsilon, 0.0)), size, persistence, seed) - perlin(fract(uv-vec2(epsilon, 0.0)), size, persistence, seed),
        perlin(fract(uv+vec2(0.0, epsilon)), size, persistence, seed) - perlin(fract(uv-vec2(0.0, epsilon)), size, persistence, seed)
    );
}

float shape_circle(vec2 uv, float size, float edge) {
    uv = 2.0*uv-1.0;
    edge = max(edge, 1.0e-8);
    float distance = length(uv);
    return clamp((1.0-distance/size)/edge, 0.0, 1.0);
}

float blend_overlay_f(float c1, float c2) {
    return (c1 < 0.5) ? (2.0*c1*c2) : (1.0-2.0*(1.0-c1)*(1.0-c2));
}

vec3 blend_overlay(vec3 c1, vec3 c2, float opacity) {
    return opacity*vec3(blend_overlay_f(c1.x, c2.x), blend_overlay_f(c1.y, c2.y), blend_overlay_f(c1.z, c2.z)) + (1.0-opacity)*c2;
}

float waves(vec2 uv, float amplitude, float frequency, float phase) {
    return 1.0-abs(2.0*(uv.y-0.5)-amplitude*sin((frequency*uv.x+phase)*6.28318530718));
}

void main() {
    vec2 uv = vUv;
    uv = (canvasTransform * vec3(uv, 1.0)).xy;

    vec2 warped_uv = perlin_warp(uv, noiseFactor, vec2(4.0), 0.5, seed);

    float heightmap = 0.0;
    for (int i = 0; i < NUM_INFLUENCES; i++) {
        vec2 influencePos = vec2(influenceTransforms[i][2][0], influenceTransforms[i][2][1]);
        float influenceScale = influenceTransforms[i][0][0];
        float influenceFactor = influenceFactors[i][0];

        vec2 offset_warped_uv = warped_uv - influencePos + vec2(0.5, 0.5);
        heightmap += shape_circle(offset_warped_uv, influenceScale, 1.0) * influenceFactor;
    }
    
    float land_mask = heightmap; // todo clamp?
    float land_mask_hard = step(0.094, land_mask);

    // todo use pixel to texel ratio instead of constant 30.0
    float fake_normal = clamp((dFdx(land_mask) + dFdy(-1.0 * land_mask)) * (20.0/canvasTransform[0][0]) + 0.5, 0.0, 1.0);

    fake_normal = mix(0.5, fake_normal, reliefFactor);

    vec3 col = blend_overlay(vec3(fake_normal), colormap(land_mask), 0.5 * land_mask_hard);

    float border = step(0.0, uv.x) * (1.0 - step(1.0, uv.x)) * step(0.0, uv.y) * (1.0 - step(1.0, uv.y));

    col *= mix(1.0 - borderFactor, 1.0, border);

    // temp hack: add waves
    col -= (1.0 - land_mask_hard) * 0.1 * vec3(smoothstep(0.8, 1.0, waves(vec2(uv.x * 30.0 * (1.0/canvasTransform[0][0]), fract(uv.y * 100.0 * (1.0/canvasTransform[0][0]))), 0.3, 2.0, 0.0)));

    gl_FragColor = vec4(col, 1.0);
}
