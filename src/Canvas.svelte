<script>
  import reglWrapper from "regl";
  import primitiveQuad from "primitive-quad";
  import { vec2 } from "gl-matrix";
  import { onMount } from "svelte";

  import frag from "./frag.glsl";
  import vert from "./vert.glsl";

  import { hexToVec3 } from "./lib/color.js";

  import { view } from "./stores/view.js";
  import {
    mode,
    seed,
    noiseFactor,
    reliefFactor,
    borderFactor,
    fakeHeightFactor,
    selectedOverlay,
    palette,
    overlays,
    canvasWidth,
    canvasHeight,
  } from "./stores/globalControls.js";

  const quad = primitiveQuad();
  let gl;
  let element;
  let regl;
  let canvasDragging = false;

  $: paletteRGB = $palette.map(hexToVec3);
  $: influenceTransforms = $overlays.filter((o) => o.type === "influence").map((o) => o.transform);

  // BUG[uniform1fv]: this should be a float[] but regl chokes
  // See https://github.com/regl-project/regl/issues/611
  $: influenceFactors = $overlays
    .filter((o) => o.type === "influence")
    .map((o) => vec2.fromValues(o.factor, o.factor));

  onMount(() => {
    const contexts = ["webgl", "experimental-webgl", "moz-webgl", "webkit-3d"];
    for (let j = 0; j < contexts.length; j++) {
      gl = element.getContext(contexts[j]);
      if (gl) {
        break;
      }
    }
  });

  function resetMode() {
    mode.set(null);
    selectedOverlay.set(null);
  }

  function canvasStartDrag(e) {
    if (e.button !== 0) {
      return;
    }
    canvasDragging = true;
    selectedOverlay.set(null);
    addEventListener("mouseup", canvasStopDrag);
    addEventListener("mousemove", canvasDrag);
  }

  function canvasDrag(e) {
    // TODO: devicePixelRatio here might be a browser compat issue
    // https://crbug.com/1092358
    let delta = vec2.fromValues(
      e.movementX / window.devicePixelRatio / $canvasWidth,
      e.movementY / window.devicePixelRatio / $canvasHeight
    );
    view.translate(vec2.negate(vec2.create(), delta));
  }

  function canvasStopDrag(e) {
    if (e.button !== 0) {
      return;
    }
    canvasDragging = false;
    removeEventListener("mouseup", canvasStopDrag);
    removeEventListener("mousemove", canvasDrag);
  }

  function canvasZoom(e) {
    let step = 0.1;
    let zoom = 1.0 - Math.sign(e.wheelDeltaY) * step;
    let center = vec2.fromValues(e.clientX / $canvasHeight, e.clientY / $canvasHeight);
    view.zoom(zoom, center);
  }

  function resize() {
    if (gl) {
      const canvas = gl.canvas;
      // Lookup the size the browser is displaying the canvas.
      const displayWidth = canvas.clientWidth;
      const displayHeight = canvas.clientHeight;

      // Check if the canvas is not the same size.
      if (canvas.width !== displayWidth || canvas.height !== displayHeight) {
        // Make the canvas the same size
        canvas.width = displayWidth;
        canvasWidth.set(displayWidth);
        canvas.height = displayHeight;
        canvasHeight.set(displayHeight);
        view.resize(displayWidth, displayHeight);
      }
      gl.viewport(0, 0, canvas.width, canvas.height);
    }
  }

  function startRegl() {
    if (gl) {
      regl = reglWrapper({
        gl: gl,
        extensions: ["oes_standard_derivatives"],
      });

      const uniforms = {
        time: regl.prop("time"),
        seed: regl.prop("seed"),
        canvasTransform: regl.prop("canvasTransform"),
        noiseFactor: regl.prop("noiseFactor"),
        reliefFactor: regl.prop("reliefFactor"),
        borderFactor: regl.prop("borderFactor"),
        fakeHeightFactor: regl.prop("fakeHeightFactor"),
        paletteDeepWater: regl.prop("paletteDeepWater"),
        paletteShallowWater: regl.prop("paletteShallowWater"),
        paletteShore: regl.prop("paletteShore"),
        paletteLand: regl.prop("paletteLand"),
        paletteMountain: regl.prop("paletteMountain"),
        palettePeak: regl.prop("palettePeak"),
      };

      for (let i = 0; i < influenceTransforms.length; i++) {
        uniforms[`influenceTransforms[${i}]`] = regl.prop(`influenceTransforms[${i}]`);
        uniforms[`influenceFactors[${i}]`] = regl.prop(`influenceFactors[${i}]`);
      }

      const draw = regl({
        frag,
        vert,
        attributes: {
          position: quad.positions,
          uv: quad.uvs,
        },
        elements: quad.cells,
        uniforms,
      });

      regl.frame(({ time }) => {
        // clear contents of the drawing buffer
        regl.clear({
          color: [0, 0, 0, 1.0],
          depth: 1,
        });

        // draw a triangle using the command defined above
        draw({
          time,
          seed: $seed,
          canvasTransform: $view,
          influenceTransforms,
          influenceFactors,
          noiseFactor: $noiseFactor,
          reliefFactor: $reliefFactor,
          borderFactor: $borderFactor,
          fakeHeightFactor: $fakeHeightFactor,
          paletteDeepWater: paletteRGB[0],
          paletteShallowWater: paletteRGB[1],
          paletteShore: paletteRGB[2],
          paletteLand: paletteRGB[3],
          paletteMountain: paletteRGB[4],
          palettePeak: paletteRGB[5],
        });
      });
    }
  }

  $: gl, resize(), startRegl();
</script>

<svelte:window on:resize={resize} />

<canvas
  bind:this={element}
  on:mousedown={canvasStartDrag}
  on:mousewheel={canvasZoom}
  on:dblclick={resetMode}
  class:dragging={canvasDragging}
/>

<style>
  canvas {
    width: 100%;
    height: 100%;
    user-select: none;
    -moz-user-select: none;
    -webkit-user-select: none;
  }
  canvas.dragging {
    cursor: grab;
  }
</style>
