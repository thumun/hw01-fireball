import {vec3, vec4} from 'gl-matrix';
//const Stats = require('stats-js');
import * as DAT from 'dat.gui';
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
  tesselations: 5,
  octaves: 8,
  'Load Scene': loadScene, // A function pointer, essentially
  'Reset Scene': resetScene,
  color : [6.0, 6.0, 23.0, 1.0],
  color2 : [165.0, 48.0, 48.0, 1.0],
  worldColor : [74.0,189.0,255.0,1.0],
};

/*
class test {
  color: vec4 
  constructor(){
    this.color = [1, 1, 1, 1.0]
  }
};
*/

let deltaTime: number = 0.0; 

let icosphere: Icosphere;
let icosphere2: Icosphere;
let square: Square;
let cube: Cube;

let prevTesselations: number = 5;
let prevOctaves: number = 8;
let prevColor: number[] = [6.0, 6.0, 23.0, 1.0];
let prevColor2: number[] = [165.0, 48.0, 48.0, 1.0];
let prevWorldColor: number[] = [74.0,189.0,255.0,1.0];

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  icosphere2 = new Icosphere(vec3.fromValues(0, 0, -20), 20, 5);
  icosphere2.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function resetScene(){
  controls.tesselations = 5; 
  controls.octaves = 8;
  controls.color = [6.0, 6.0, 23.0, 1.0];
  controls.color2 = [165.0, 48.0, 48.0, 1.0];
  controls.worldColor = [74.0,189.0,255.0,1.0];
  deltaTime = 0.0;
}

function main() {
  // Initial display for framerate
  //const stats = Stats();
  //stats.setMode(0);
  //stats.domElement.style.position = 'absolute';
  //stats.domElement.style.left = '0px';
  //stats.domElement.style.top = '0px';
  //document.body.appendChild(stats.domElement);

  //var testObj = new test();
  //var colortest = vec4.fromValues(1, 0, 0, 1);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');

  gui.add(controls, 'Reset Scene');
  gui.add(controls, 'octaves');
  gui.addColor(controls, 'color');
  gui.addColor(controls, 'color2');
  gui.addColor(controls, 'worldColor');

  //const colorFolder = gui.addFolder("Color");
  //const color = colorFolder.addColor(testObj, 'color');
  //color.onChange((value) => {colortest = [value[0]/255.0, value[1]/255.0, value[2]/255.0, 1]});

  //console.log(testObj.color);

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
  renderer.setClearColor(0.0, 0.0, 0.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const noise = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/noise-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/noise-frag.glsl')),
  ]);
  
  const fire = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fire-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fire-frag.glsl')),
  ]);

  const bg = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/bg-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/bg-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    deltaTime += 0.01;
    camera.update();
    //stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    if(controls.octaves != prevOctaves)
    {
      prevOctaves = controls.octaves;
    }

    if(controls.color != prevColor)
    {
      prevColor = controls.color;
    }

    if(controls.color2 != prevColor2)
    {
      prevColor2 = controls.color2;
    }

    if(controls.worldColor != prevWorldColor)
    {
      prevWorldColor = controls.worldColor;
    }

    renderer.render(camera, bg, 0, controls.worldColor, [], deltaTime, [
      icosphere2,
      //square
      ]);

    renderer.render(camera, fire, controls.octaves, controls.color, controls.color2, deltaTime,[
      //cube
      icosphere,
      //square,
    ]);

    //stats.end();

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