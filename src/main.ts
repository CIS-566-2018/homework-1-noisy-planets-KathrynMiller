import {vec3, vec4} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  lightDirection: 0,
  craterSize: 1,
  craterDensity: 1,
  showClouds: false
};

let clouds: Icosphere;
let icosphere: Icosphere;
let skyBox: Icosphere;
let square: Square;
let cube: Cube;
let time: number = 0;
let currShader: ShaderProgram;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, 6);
  icosphere.create();
  clouds = new Icosphere(vec3.fromValues(0, 0, 0), 1.1, 6);
  clouds.create();
  skyBox = new Icosphere(vec3.fromValues(0, 0, 0), 100, 6);
  skyBox.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  var lightDir = gui.add(controls, 'lightDirection', 0.0, 360.0);
  var craterSize = gui.add(controls, 'craterSize', 1.0, 2.0);
  var craterDensity = gui.add(controls, 'craterDensity', 1.0, 4.0); 
  var showClouds = gui.add(controls, 'showClouds', false);
 
  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);
  gl.enable(gl.BLEND);
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

 
  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const cloud = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/cloud-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/cloud-frag.glsl')),
  ]);

  const sky = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/sky-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/sky-frag.glsl')),
  ])
  

  // initialize time in shader
  cloud.setTime(time);
  lambert.setTime(time);
  lambert.setCraterNum(1.0);
  lambert.setCraterRad(1.0);
  sky.setTime(time);
  time++;
  
  // This function will be called every frame
  function tick() {
    camera.update();

    cloud.setTime(time);
    lambert.setTime(time);
    sky.setTime(time);
    time++;

    let angle: number = controls.lightDirection.valueOf();
    let radians: number = angle * 3.14159 / 180.0
    cloud.setLightDir(radians);
    lambert.setLightDir(radians);
    sky.setLightDir(radians);

    //set crater attributes
    lambert.setCraterNum(controls.craterDensity.valueOf());
    lambert.setCraterRad(controls.craterSize.valueOf());

    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
  
    renderer.render(camera, lambert, [
       icosphere
    ]);
    // show clouds based on gui selection
    if(controls.showClouds.valueOf() == true) {
      renderer.render(camera, cloud, [
        clouds
      ]);
  }
    renderer.render(camera, sky, [
     skyBox,
   ]);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
