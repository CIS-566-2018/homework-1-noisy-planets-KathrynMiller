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

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.
//returns base color based on y value
vec4 getRingColor();

vec4 tan = vec4(145.0 / 255.0, 121.0 / 255.0, 80.0 / 255.0, 1.0);
vec4 light_tan = vec4(172.0 / 255.0, 167.0 / 255.0, 147.0 / 255.0, 1.0);
vec4 light_blue = vec4(182.0 / 255.0, 203.0 / 255.0, 200.0 / 255.0, 1.0);
vec4 grey_blue = vec4(116.0 / 255.0, 138.0 / 255.0, 130.0 / 255.0, 1.0);
vec4 gold = vec4(190.0 / 255.0, 122.0 / 255.0, 17.0 / 255.0, 1.0);
vec4 brown = vec4(92.0 / 255.0, 66.0 / 255.0, 22.0 / 255.0, 1.0);
vec4 med_blue = vec4(89.0 / 255.0, 141.0 / 255.0, 151.0 / 255.0, 1.0);
vec4 yellow = vec4(246.0 / 255.0, 154.0 / 255.0, 14.0 / 255.0, 1.0);

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;
    out_Col = getRingColor();





/*
        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
        */
}

vec4 getRingColor() {
    // starting from bottom ring going to top
    if(fs_Pos.y < -7.0 / 10.0) { // -1 to -7/10
        return mix(brown, light_tan, (fs_Pos.y + 1.0) / (3.0 / 10.0));

    } else if(fs_Pos.y < -6.0 / 10.0) { // -7/10 to -6/10
        return mix(light_tan, tan, (fs_Pos.y + (7.0 / 10.0)) / (1.0 / 10.0));

    } else if (fs_Pos.y < -5.0 / 10.0) { // -6/10 to -5/10
        return mix(gold, tan, (fs_Pos.y + (6.0 / 10.0)) / (1.0 / 10.0));

    } else if (fs_Pos.y < -3.0 / 10.0) { // -5/10 to -3/10
        return mix(tan, light_blue, (fs_Pos.y + (5.0 / 10.0)) / (2.0 / 10.0));

    } else if (fs_Pos.y < 0.0) { // -3/10 to 0
        return mix(light_blue, gold, (fs_Pos.y + (3.0 / 10.0)) / (3.0 / 10.0));

    } else if (fs_Pos.y < 3.0 / 10.0) { // 0 to 3/10
        return mix(gold, med_blue, (fs_Pos.y) / (3.0 / 10.0));

    } else if (fs_Pos.y < 5.0 / 10.0) { // 3/10 to 5/10
        return mix(med_blue, gold, (fs_Pos.y - (3.0 / 10.0)) / (2.0 / 10.0));

    } else if (fs_Pos.y < 6.0 / 10.0) { // 5/10 to 6/10
        return mix(gold, light_blue, (fs_Pos.y - (5.0 / 10.0)) / (1.0 / 10.0));

    } else if (fs_Pos.y < 7.0 / 10.0) { // 6/10 to 7/10
        return mix(light_blue, gold, (fs_Pos.y - (6.0 / 10.0)) / (1.0 / 10.0));

    } else if (fs_Pos.y < 8.0 / 10.0) { // 7/10 to 8/10
        return mix(gold, light_blue, (fs_Pos.y - (7.0 / 10.0)) / (1.0 / 10.0));

    } 
    // 8/10 to 1
    return mix(light_blue, tan, (fs_Pos.y - (8.0 / 10.0)) / (2.0 / 10.0));
}
