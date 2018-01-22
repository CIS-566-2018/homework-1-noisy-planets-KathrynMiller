#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

uniform float u_lightDir;
uniform float u_Time;

float fbm(const in vec3 uv);
float noise(in vec3 p);

out float snow_cap;

float rand(float n){return fract(sin(n) * 43758.5453123);}
float noise(float p){
	float fl = floor(p);
  float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}


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

void main()
{
   fs_Col = vs_Col; 
    fs_Pos = vs_Pos;                

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);  
    float height = pow(1.0 - fbm(vec3(vs_Pos) * 4.0), 3.0) * 0.1 + 0.42;
    vec4 newPos = vs_Pos + (vs_Nor * height);  
    
    //map point to 2d space then to a grid 
    vec2 uvPoint = sphereToUV(vec3(fs_Pos));
    vec2 point = PixelToGrid(uvPoint, 10.0);
    // lower left coordinate
    vec2 lowerLeft = vec2(floor(point.x), floor(point.y));
    float numCraters = 40.0;
    for(float i = 0.0; i < numCraters; i++) {
        vec2 craterCenter = vec2(noise(i), rand(i));
        float radius = noise(sin(i * 63.0) * .07);
        vec2 craterCenter2 = vec2(rand(i * sin(i)), rand(i * 20.0 * cos(i * 45.0)));
        float radius2 = noise(sin(i * 30.0) * cos(i * 20.0) * .1);
        if(length(uvPoint - craterCenter) < radius || length(uvPoint - craterCenter2) < radius2) {
            newPos = vs_Pos + .4 * vs_Nor;// - (.025 * vs_Nor);
            fs_Nor = vec4(normalize(mix((vec3(fs_LightVec) + 1.0 * vec3(vs_Nor) - vec3(vs_Pos)), vec3(vs_Nor), 1.0)), 1.0);
        } 
    }
    vec4 modelposition = u_Model * newPos;  


    mat4 rot = mat4(vec4(cos(u_lightDir), 0.0, sin(u_lightDir), 0.0),
    
    vec4(0.0, 1.0, 0.0, 0.0),
    vec4(-sin(u_lightDir), 0.0, cos(u_lightDir), 0.0),
    vec4(0.0, 0.0, 0.0, 1.0));
    fs_LightVec = (rot * lightPos) - modelposition; 

    gl_Position = u_ViewProj * modelposition;


                                           
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
    float a = 0.2;
    float f = 3.0;
    float n = 0.;
    int it = 16;
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
