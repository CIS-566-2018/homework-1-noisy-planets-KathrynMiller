#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
uniform float u_Time;
in float snow_cap;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.
//returns base color based on y value
vec3 getRingColor(vec2 uv);

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

vec2 sphereToUV(vec3 p)
{
    float phi = atan(p.z, p.x); // Returns atan(z/x)
    if(phi < 0.0)
    {
        phi += TWO_PI; // [0, TWO_PI] range now
    }
    // ^^ Could also just add PI to phi, but this shifts where the UV loop from X = 1 to Z = -1.
    float theta = acos(p.y); // [0, PI]
    return vec2(1.0 - phi / TWO_PI, 1.0 - theta / PI);
}

vec2 PixelToGrid(vec2 pixel, float size)
{
    vec2 uv = pixel.xy;
    // Determine number of cells (NxN)
    uv *= size;
    return uv;
}

const vec4 tan = vec4(145.0 / 255.0, 121.0 / 255.0, 80.0 / 255.0, 1.0);
const vec4 light_tan = vec4(172.0 / 255.0, 167.0 / 255.0, 147.0 / 255.0, 1.0);
const vec4 light_blue = vec4(182.0 / 255.0, 203.0 / 255.0, 200.0 / 255.0, 1.0);
const vec4 grey_blue = vec4(116.0 / 255.0, 138.0 / 255.0, 130.0 / 255.0, 1.0);
const vec4 gold = vec4(190.0 / 255.0, 122.0 / 255.0, 17.0 / 255.0, 1.0);
const vec4 brown = vec4(92.0 / 255.0, 66.0 / 255.0, 22.0 / 255.0, 1.0);
const vec4 med_blue = vec4(89.0 / 255.0, 141.0 / 255.0, 151.0 / 255.0, 1.0);
const vec4 yellow = vec4(246.0 / 255.0, 154.0 / 255.0, 14.0 / 255.0, 1.0);

const vec3 c1 = vec3(161.0 / 255.0, 159.0 / 255.0, 181.0 / 255.0);
const vec3 c2 = vec3(163.0 / 255.0, 178.0 / 255.0, 195.0 / 255.0);
const vec3 c3 = vec3(152.0 / 255.0, 150.0 / 255.0, 162.0 / 255.0);
const vec3 c4 = vec3(127.0 / 255.0, 123.0 / 255.0, 141.0 / 255.0);
const vec3 c5 = vec3(182.0 / 255.0, 178.0 / 255.0, 198.0 / 255.0);
const vec3 c6 = vec3(180.0 / 255.0, 191.0 / 255.0, 217.0 / 255.0);
const vec3 c7 = vec3(198.0 / 255.0, 208.0 / 255.0, 229.0 / 255.0);
const vec3 c8 = vec3(171.0 / 255.0, 176.0 / 255.0, 190.0 / 255.0);


//const vec4 planetCol[7] = vec4[](tan, light_tan, light_blue, grey_blue, gold, med_blue, yellow);
const vec3 planetCol[8] = vec3[](c1, c2, c3, c4, c5, c6, c7, c8);
float rand(float n);
float fbm(const in vec3 uv);
float noise(in vec3 p);
float noise(float p);
float noise(vec3 position, int octaves, float frequency, float persistence);
float ridgedNoise(vec3 position, int octaves, float frequency, float persistence);

void main()
{
    vec3 uv = vec3(fs_Pos);
    if(abs(fs_Pos.y) <  0.001) {
        float f = mod(fs_Pos.x, 2.0);
        f = mod(noise(f), 2.0);
        if(f == 1.0) {
            uv.y = -.9;
        } 
    }
    // calculate threshold for "storm dots" and calculate it in with noise n
        float s = 0.6;
float t1 = noise(vec3(fs_Nor) * 2.0) - s;
float t2 = noise((vec3(fs_Nor) + 800.0) * 2.0) - s;
float t3 = noise((vec3(fs_Nor) + 1600.0) * 2.0) - s;
float threshold = max(t1 * t2 * t3, 0.0);
float n3 = noise(vec3(fs_Nor) * 0.1) * threshold;

    float n1 = noise(vec3(fs_Nor), 6, 10.0, 0.8) * 0.01;
    float n2 = ridgedNoise(vec3(fs_Nor), 5, 5.8, 0.75) * 0.015 - 0.01;
    float n = n1 + n2 + n3;

    float fbm = fbm(uv);
    float det = mod(uv.y * 50.0 * fbm, 8.0);
    vec4 color = vec4(planetCol[int(det)], 1.0); 
    //color = vec4(getRingColor(uv.xy), 1.0);
    //map point to 2d space then to a grid 
    vec2 uvPoint = sphereToUV(vec3(fs_Pos));
    vec2 point = PixelToGrid(uvPoint, 10.0);
    // lower left coordinate
    vec2 lowerLeft = vec2(floor(point.x), floor(point.y));
    float numCraters = 20.0;
    for(float i = 0.0; i < numCraters; i++) {
        vec2 craterCenter = vec2(noise(i), rand(i));
        float radius = noise(sin(i * 63.0) * .07);
        vec2 craterCenter2 = vec2(rand(i * sin(i)), rand(i * 20.0 * cos(i * 45.0)));
        float radius2 = noise(sin(i * 30.0) * cos(i * 20.0) * .1);
        if(length(uvPoint - craterCenter) < radius || length(uvPoint - craterCenter2) < radius2) {
           // color = color - vec4(.2, .2, .2, .1);
        }
    }
        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
         diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
         float ambientTerm = 0.2;
        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(color.rgb * lightIntensity, color.a);

}

float rand(float n){return fract(sin(n) * 43758.5453123);}

float noise(float p){
	float fl = floor(p);
  float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}
 float noise(vec3 position, int octaves, float frequency, float persistence) {
    float total = 0.0; // Total value so far
    float maxAmplitude = 0.0; // Accumulates highest theoretical amplitude
    float amplitude = 1.0;
    for (int i = 0; i < octaves; i++) {

        // Get the noise sample
        total += noise(position * frequency) * amplitude;

        // Make the wavelength twice as small
        frequency *= 2.0;

        // Add to our maximum possible amplitude
        maxAmplitude += amplitude;

        // Reduce amplitude according to persistence for the next octave
        amplitude *= persistence;
    }

    // Scale the result by the maximum amplitude
    return total / maxAmplitude;
}

float ridgedNoise(vec3 position, int octaves, float frequency, float persistence) {
    float total = 0.0; // Total value so far
    float maxAmplitude = 0.0; // Accumulates highest theoretical amplitude
    float amplitude = 1.0;
    for (int i = 0; i < octaves; i++) {

        // Get the noise sample
        total += ((1.0 - abs(noise(position * frequency))) * 2.0 - 1.0) * amplitude;

        // Make the wavelength twice as small
        frequency *= 2.0;

        // Add to our maximum possible amplitude
        maxAmplitude += amplitude;

        // Reduce amplitude according to persistence for the next octave
        amplitude *= persistence;
    }

    // Scale the result by the maximum amplitude
    return total / maxAmplitude;
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
    float a = 0.3;
    float f = 9.0;
    float n = 0.;
    int it = 8;
    for(int i = 0; i < 32; i++)
    {
        if(i<it)
        {
            n += noise(uv*f)*a;
            a *= .5;
            f *= 2.;
        }
    }
    return n;
}

vec3 getRingColor(vec2 uv) {
    // starting from bottom ring going to top
    if(uv.y < -7.0 / 10.0) { // -1 to -7/10
        return mix(c1, c2, (uv.y + 1.0) / (3.0 / 10.0));
    } else if(uv.y < -6.0 / 10.0) { // -7/10 to -6/10
       return mix(c2, c3, (uv.y + (7.0 / 10.0)) / (1.0 / 10.0));
    } else if (uv.y < -5.0 / 10.0) { // -6/10 to -5/10
       return mix(c3, c4, (uv.y + (6.0 / 10.0)) / (1.0 / 10.0));
    } else if (uv.y < -3.0 / 10.0) { // -5/10 to -3/10
        return mix(c4, c5, (uv.y + (5.0 / 10.0)) / (2.0 / 10.0));
    } else if (uv.y < 0.0) { // -3/10 to 0
        return mix(c5, c6, (uv.y + (3.0 / 10.0)) / (3.0 / 10.0));
    } else if (uv.y < 3.0 / 10.0) { // 0 to 3/10
        return mix(c6, c7, (uv.y) / (3.0 / 10.0));
    } else if (uv.y < 5.0 / 10.0) { // 3/10 to 5/10
        return mix(c7, c8, (uv.y - (3.0 / 10.0)) / (2.0 / 10.0));
    } else if (uv.y < 6.0 / 10.0) { // 5/10 to 6/10
        return mix(c8, c5, (uv.y - (5.0 / 10.0)) / (1.0 / 10.0));
    } else if (uv.y < 7.0 / 10.0) { // 6/10 to 7/10
        return mix(c5, c3, (uv.y - (6.0 / 10.0)) / (1.0 / 10.0));
    } else if (uv.y < 8.0 / 10.0) { // 7/10 to 8/10
       return mix(c3, c2, (uv.y - (7.0 / 10.0)) / (1.0 / 10.0));
    } 
    // 8/10 to 1
    return mix(c2, c4, (uv.y - (8.0 / 10.0)) / (2.0 / 10.0));
}


