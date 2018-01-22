Name: Kathryn Miller
Pennkey: kamill

External Resources:
https://github.com/ashima/webgl-noise/blob/master/src/noise3Dgrad.glsl
I also used another sites noise functions but closed the tab and now can't find it amongst all my history

Implmentation

For the base color of the planet/asteroid thing I made, I created an array of 8 handpicked colors and then indexed to them based on mod(fs_Pos.y, 8). This caused very uniform stripes on the sphere so I took the y position and offset it by a number generated by fbm multiplied by some constant to get the spotted pattern that is more condensed at the poles. However, this caused a straight line at the center so I manually blended the two colors at y = 0. For the general terrain I didnt want it to be too bumpy (wanted it to overall still look fairly flat so the craters were visible) so I just used fbm to determine an offset height from the vertex normals to get slight bumpy-ness. To vary the overall shape more I used a small perlin offset to make the shape less symmetrical (although it is super super super slight).

In the vertex shader, I wanted to create craters since I was going for a more moon/asteroid object. So, I converted the sphere coordinates to uv coordinates then divided it into a grid. Similar to worley noise, I randomly selected a 2 crater centers for each grid piece and randomly generated a radius to go with it. Then I checked the 9 surrounding squares in the grid and if the point was within the radius of one of those crater centers, it would be sunken in relative to the rest of the terrain. Because the colors are so noisy, they distracted from the craters, which weren't very visible and whose sides looked too straight up and down. So took the vector from the light direction to the crater's center's normal and mixed that vector with the points original normal to offset the crater normals and make them look more shadowed inside.

I also wanted to do clouds although I wasn't completely pleased with how they turned out because they are still just flat (which is why i made them an option to turn on and off). They were made by creating an isosphere slightly larger than the planet with the same basic fbm applied to the surface. Then I enabled the alpha channel and sampled fbm again to determine if a cloud should be drawn or not (above a certain height gets a semi-transparent value and the rest are clear). Then I varied it by time to get the blobs to move.

To change the light I just took in an angle and rotated the light position by the angle specified in the gui.
The stars were also determined by an fbm height and have a time component so that some twinkle in and out.
I also added a specular intensity to the lightest color in the the diffuse base so that it looked like some sort of glinting metal or ice on the surface when the light is moved