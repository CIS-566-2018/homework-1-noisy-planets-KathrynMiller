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
out vec4 fs_lightPos;
uniform float u_lightDir;
uniform float u_Time;
uniform float u_craterRad;
uniform float u_craterNum;

float fbm(const in vec3 uv);
float noise(in vec3 p);
float snoise(vec3 v);

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
    
    // make craters
    //map point to 2d space then to a grid 
    vec2 uvPoint = sphereToUV(vec3(fs_Pos));
    vec2 point = PixelToGrid(uvPoint, 10.0);
    // lower left coordinate
    vec2 lowerLeft = vec2(floor(point.x), floor(point.y));
    float numCraters = 20.0 * u_craterNum;
    for(float i = 0.0; i < numCraters; i++) {
        vec2 craterCenter = vec2(noise(i), rand(i));
        float radius = noise(sin(i * 63.0) * .07);
        vec2 craterCenter2 = vec2(rand(i * sin(i)), rand(i * 20.0 * cos(i * 45.0)));
        float radius2 = noise(sin(i * 30.0) * cos(i * 20.0) * .1) * u_craterRad;
        if(length(uvPoint - craterCenter) < radius || length(uvPoint - craterCenter2) < radius2) {
            newPos = vs_Pos + .4 * vs_Nor;// - (.025 * vs_Nor);
            fs_Nor = vec4(normalize(mix((vec3(fs_LightVec) + 1.0 * vec3(vs_Nor) - vec3(vs_Pos)), vec3(vs_Nor), 1.0)), 1.0);
        } 
    }

    //float perlin = snoise(vs_Pos.xyz * 1.5);
    vec3 offset1 = vec3(snoise(vs_Pos.xyz + cos(0.01)), snoise(vs_Pos.xyz + vec3(5.2, 1.3, 1.4)), snoise(vs_Pos.xyz + vec3(5.2, 1.3, 1.4)));
   // vec2 offset2 = vec2(PerlinNoise(uv + offset1 + vec2(1.7, 9.2)), PerlinNoise(uv + sin(u_Time * 3.14159 * 0.01) + offset1 + vec2(8.3, 2.8)));
    float perlin = snoise(vs_Pos.xyz + offset1);
    newPos = vec4(newPos.xyz + vs_Nor.xyz * vec3((perlin + .4) * .06), 1.0);
    //newPos = vec4(newPos.xyz + vs_Nor.xyz * (vec3(1.0) - vec3(abs(perlin) * .3)), 1.0);

    vec4 modelposition = u_Model * newPos;  

    // change light direction
    mat4 rot = mat4(vec4(cos(u_lightDir), 0.0, sin(u_lightDir), 0.0),
    vec4(0.0, 1.0, 0.0, 0.0),
    vec4(-sin(u_lightDir), 0.0, cos(u_lightDir), 0.0),
    vec4(0.0, 0.0, 0.0, 1.0));
    fs_lightPos = rot * lightPos;
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

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v)
{
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289(i); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  vec4 m2 = m * m;
  vec4 m4 = m2 * m2;
  vec4 pdotx = vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3));

// Determine noise gradient
  vec4 temp = m2 * m * pdotx;
  vec3 gradient = -8.0 * (temp.x * x0 + temp.y * x1 + temp.z * x2 + temp.w * x3);
  gradient += m4.x * p0 + m4.y * p1 + m4.z * p2 + m4.w * p3;
  gradient *= 42.0;

  return 42.0 * dot(m4, pdotx);
}
