#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_Pos;
in vec4 fs_LightVec;
in vec4 fs_Col;
uniform float u_Time;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.
const vec4 cloudCol = vec4(.6, .6, .6, .5);
const vec4 clear = vec4(0.0, 0.0, 0.0, 0.0);

float fbm(const in vec3 uv);
float noise(in vec3 p);

void main()
{
vec4 diffuseColor = cloudCol;
    float height = fbm(vec3(fs_Pos) * cos(u_Time * .0004));// + vec3(noise(fs_Pos.xyz)));
    if(height > .2) {
        out_Col = cloudCol;
    } else {
        out_Col = clear;
    }
}

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(in vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = vec4(a.x, a.x, a.y, a.y) + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + vec4(a.z, a.z, a.z, a.z);
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float fbm(const in vec3 uv)
{
    float a = .2;
    float f = 7.0;
    float n = 0.;
    int it = 10;
    for(int i = 0; i < 32; i++)
    {
        if(i<it)
        {
            n += noise(uv*f)*a;
            a *= .4;
            f *= 2.;
        }
    }
    return n;
}
