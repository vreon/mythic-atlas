<script>
  import reglWrapper from "regl";
  import primitiveQuad from "primitive-quad";
  import { vec2, mat3 } from "gl-matrix";
  import { onMount } from "svelte";

  import frag from "./frag.glsl";
  import vert from "./vert.glsl";
  import palettes from "./palettes.js";

  const quad = primitiveQuad();
  let gl;
  let element;
  let width = 0;
  let height = 0;
  let regl;
  let seed = Math.random();
  let noiseFactor = 0.5;
  let reliefFactor = 0.5;
  let showInfluences = false;
  let showLabels = true;
  let borderFactor = 0.05;
  let canvasDragging = false;
  let canvasTransform = mat3.create();
  let canvasTransformInitialized = false;

  $: invCanvasTransform = mat3.invert(
    invCanvasTransform || (invCanvasTransform = mat3.create()),
    canvasTransform
  );

  let palette = {};
  let paletteName = "plain";

  $: paletteName !== "custom" &&
    (palette = Object.assign({}, palettes[paletteName]));

  $: paletteRGB = {
    deepWater: hexToVec3(palette.deepWater),
    shallowWater: hexToVec3(palette.shallowWater),
    shore: hexToVec3(palette.shore),
    land: hexToVec3(palette.land),
    mountain: hexToVec3(palette.mountain),
    peak: hexToVec3(palette.peak),
  };

  let overlays = [];
  let selectedOverlay;

  function addLabel(text, transform) {
    overlays.push({
      type: "label",
      name: "label" + overlays.length,
      text,
      fontSizeRem: 2,
      textAlign: "left",
      transform: transform || mat3.fromValues(1, 0, 0, 0, 1, 0, 0.5, 0.5, 1),
      document: {
        position: vec2.create(),
        extent: vec2.create(),
        listeners: {},
      }
    });
    overlays = overlays;
  }

  function addInfluence(factor, transform) {
    overlays.push({
      type: "influence",
      name: "influence" + overlays.length,
      factor,
      transform,
      document: {
        position: vec2.create(),
        extent: vec2.create(),
        listeners: {},
      }
    });
    overlays = overlays;
  };

  addInfluence( 1.0, mat3.fromValues(0.5, 0, 0, 0, 0.5, 0, 0.4, 0.4, 0.5));
  addInfluence(-1.0, mat3.fromValues(0.3, 0, 0, 0, 0.3, 0, 0.55, 0.55, 0.3));
  for(let i = 0; i < 7; i++) {
    addInfluence( 0.0, mat3.fromValues(0.1, 0, 0, 0, 0.1, 0, -0.075, 0.05 + 0.125 * i, 0.1));
  }

  $: overlays = overlays.map((o) => {
    // TODO: I think multiplies here could be another transform

    vec2.transformMat3(o.document.position, vec2.create(), o.transform);
    vec2.transformMat3(
      o.document.position,
      o.document.position,
      invCanvasTransform
    );
    vec2.multiply(
      o.document.position,
      o.document.position,
      vec2.fromValues(width, height)
    );

    vec2.transformMat3(
      o.document.extent,
      vec2.fromValues(1.0, 1.0),
      o.transform
    );
    vec2.transformMat3(o.document.extent, o.document.extent, invCanvasTransform);
    vec2.multiply(
      o.document.extent,
      o.document.extent,
      vec2.fromValues(width, height)
    );
    vec2.subtract(o.document.extent, o.document.extent, o.document.position);

    return o;
  });

  $: influenceTransforms = overlays.filter(o => o.type === "influence").map(o => o.transform);

  // BUG[uniform1fv]: this should be a float[] but regl chokes
  // See https://github.com/regl-project/regl/issues/611
  $: influenceFactors = overlays.filter(o => o.type === "influence").map(o => vec2.fromValues(o.factor, o.factor));

  onMount(() => {
    const contexts = ["webgl", "experimental-webgl", "moz-webgl", "webkit-3d"];
    for (let j = 0; j < contexts.length; j++) {
      gl = element.getContext(contexts[j]);
      if (gl) {
        break;
      }
    }
  });

  function hexToVec3(hex) {
    let rgb = parseInt(hex.slice(1), 16);
    return [
      ((rgb & 0xff0000) >> 16) / 255,
      ((rgb & 0x00ff00) >> 8) / 255,
      ((rgb & 0x0000ff) >> 0) / 255,
    ];
  }

  function canvasStartDrag(e) {
    canvasDragging = true;
    selectedOverlay = null;
    addEventListener("mouseup", canvasStopDrag);
    addEventListener("mousemove", canvasDrag);
  }

  function normalizedScreenCoordinates(x, y) {
    return vec2.fromValues(x / width, y / height);
  }

  function canvasDrag(e) {
    // TODO: devicePixelRatio here might be a browser compat issue
    // https://crbug.com/1092358
    let delta = normalizedScreenCoordinates(
      e.movementX / window.devicePixelRatio,
      e.movementY / window.devicePixelRatio
    );
    mat3.translate(
      canvasTransform,
      canvasTransform,
      vec2.negate(vec2.create(), delta)
    );
    canvasTransform = canvasTransform;
  }

  function canvasStopDrag() {
    canvasDragging = false;
    removeEventListener("mouseup", canvasStopDrag);
    removeEventListener("mousemove", canvasDrag);
  }

  function canvasZoom(e) {
    let step = 0.1;
    let zoom = 1.0 - Math.sign(e.wheelDeltaY) * step;
    let scale = vec2.fromValues(zoom, zoom); // <whispers> zoom zoom
    let center = normalizedScreenCoordinates(e.clientX, e.clientY);
    mat3.translate(canvasTransform, canvasTransform, center);
    mat3.scale(canvasTransform, canvasTransform, scale);
    mat3.translate(
      canvasTransform,
      canvasTransform,
      vec2.negate(vec2.create(), center)
    );
    canvasTransform = canvasTransform;
  }

  function overlayStartDrag(overlay, e) {
    selectedOverlay = overlay;
    overlay.document.listeners.stopDrag = () => overlayStopDrag(overlay);
    overlay.document.listeners.drag = (e) => overlayDrag(overlay, e);
    addEventListener("mouseup", overlay.document.listeners.stopDrag);
    addEventListener("mousemove", overlay.document.listeners.drag);
  }

  function overlayDrag(overlay, e) {
    // TODO: devicePixelRatio here might be a browser compat issue
    // https://crbug.com/1092358
    let delta = normalizedScreenCoordinates(
      e.movementX / window.devicePixelRatio,
      e.movementY / window.devicePixelRatio,
    );
    vec2.multiply(
      delta,
      delta,
      vec2.fromValues(canvasTransform[0], canvasTransform[4]),
    );
    vec2.multiply(
      delta,
      delta,
      vec2.fromValues(1.0/overlay.transform[0], 1.0/overlay.transform[4])
    );
    // vec2.multiply(delta, delta, vec2.fromValues(7, 8));
    mat3.translate(overlay.transform, overlay.transform, delta);
    overlays = overlays;
  };

  function overlayStopDrag(overlay) {
    removeEventListener("mouseup", overlay.document.listeners.stopDrag);
    removeEventListener("mousemove", overlay.document.listeners.drag);
  }

  function overlayScale(overlay, e) {
    let step = 0.1;
    if (e.shiftKey) {
      overlay.factor += step * Math.sign(e.wheelDeltaY);
    } else if (e.ctrlKey) {
      e.preventDefault();
    } else {
      let zoom = 1.0 - Math.sign(e.wheelDeltaY) * -step;
      let scale = vec2.fromValues(zoom, zoom); // <whispers> zoom zoom
      mat3.scale(overlay.transform, overlay.transform, scale);
    }
    overlays = overlays;
  }

  function randomize() {
    seed = Math.random();
    console.log(palette);
  }

  function resize() {
    if (gl) {
      const canvas = gl.canvas;
      // Lookup the size the browser is displaying the canvas.
      const displayWidth = canvas.clientWidth;
      const displayHeight = canvas.clientHeight;

      // Check if the canvas is not the same size.
      if (canvas.width !== displayWidth || canvas.height !== displayHeight) {
        if (canvasTransformInitialized) {
          // Undo the previous aspect ratio scaling
          mat3.scale(
            canvasTransform,
            canvasTransform,
            vec2.fromValues(1.0, width / height)
          );
        }

        // Make the canvas the same size
        width = canvas.width = displayWidth;
        height = canvas.height = displayHeight;

        // Scale according to new aspect ratio
        mat3.scale(
          canvasTransform,
          canvasTransform,
          vec2.fromValues(1.0, height / width)
        );

        canvasTransform = canvasTransform;
      }
      gl.viewport(0, 0, canvas.width, canvas.height);

      canvasTransformInitialized = true;
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
          seed,
          canvasTransform,
          influenceTransforms,
          influenceFactors,
          noiseFactor,
          reliefFactor,
          borderFactor,
          paletteDeepWater: paletteRGB.deepWater,
          paletteShallowWater: paletteRGB.shallowWater,
          paletteShore: paletteRGB.shore,
          paletteLand: paletteRGB.land,
          paletteMountain: paletteRGB.mountain,
          palettePeak: paletteRGB.peak,
        });
      });
    }
  }

  $: gl, resize(), startRegl();
</script>

<svelte:window on:resize={resize} />

{#each overlays as o}
  {#if o.type === "label" && showLabels}
    <div
      class="overlay label"
      class:selected={selectedOverlay === o}
      on:mousedown={(e) => overlayStartDrag(o, e)}
      style="
        position: absolute;
        color: white;
        text-shadow: 0 1px 2px rgba(0, 0, 0, 1.0);
        font-size: {o.fontSizeRem}rem;
        line-height: {o.fontSizeRem}rem;
        text-align: {o.textAlign};
        font-family: 'Alegreya', serif;
        font-weight: 800;
        font-style: italic;
        white-space: pre;
        left: {o.document.position[0]}px;
        top: {o.document.position[1]}px;
      "
    >{o.text}</div>
  {:else if o.type === "influence" && showInfluences}
    <div
      class="overlay influence"
      class:selected={selectedOverlay === o}
      on:mousedown={(e) => overlayStartDrag(o, e)}
      on:mousewheel={(e) => overlayScale(o, e)}
      style="
        position:absolute;
        overflow: hidden;
        cursor: move;
        left: {o.document.position[0] - (o.document.extent[0] / 2)}px;
        top: {o.document.position[1] - (o.document.extent[1] / 2)}px;
        width: {o.document.extent[0]}px;
        height: {o.document.extent[1]}px;
      "
    >
      {o.factor > 0 ? "+" : ""}{(Math.round(o.factor*100))/100}
    </div>
  {/if}
{/each}

<div class="controls-area">
  <div class="main-controls">
    <label class="range">
      Warp
      <input
        style="padding: 0"
        type="range"
        min="0"
        max="1"
        step="any"
        bind:value={noiseFactor}
      />
    </label>
    <label class="range">
      Relief
      <input
        style="padding: 0"
        type="range"
        min="0"
        max="1"
        step="any"
        bind:value={reliefFactor}
      />
    </label>
    <label class="range">
      Border
      <input
        style="padding: 0"
        type="range"
        min="0"
        max="1"
        step="any"
        bind:value={borderFactor}
      />
    </label>
    <div>
      {#each Object.keys(palette) as key}
        <input
          style="padding: 0; width: 30px; height: 30px"
          type="color"
          bind:value={palette[key]}
          on:change={() => (paletteName = "custom")}
        />
      {/each}
    </div>
    <select bind:value={paletteName}>
      <option value="custom">custom</option>
      {#each Object.keys(palettes) as paletteKey}
        <option value={paletteKey}>{paletteKey}</option>
      {/each}
    </select>
    <label><input type="checkbox" bind:checked={showInfluences} /> Show influences</label>
    <label><input type="checkbox" bind:checked={showLabels} /> Show labels</label>
    <button on:click|preventDefault={randomize}>Randomize</button>
  </div>

  <div>
    <button on:click|preventDefault={() => {showLabels = true; addLabel("New label")}}>+ Add label</button>
  </div>

  {#if selectedOverlay}
    <div>
      <div><code>{selectedOverlay.name}</code></div>      
      {#if selectedOverlay.type === "label"}
        <textarea
          on:keyup={() => overlays = overlays}
          bind:value={selectedOverlay.text}
        ></textarea>
        <label class="range">
          Size
          <input
            style="padding: 0"
            type="range"
            min="0"
            max="5"
            step="any"
            on:input={() => overlays = overlays}
            bind:value={selectedOverlay.fontSizeRem}
          />
        </label>
        <select
          on:change={() => overlays = overlays}
          bind:value={selectedOverlay.textAlign}
        >
          <option value="left">text left</option>
          <option value="center">text center</option>
          <option value="right">text right</option>
        </select>
        <select
          on:change={() => overlays = overlays}
        >
          <option value="top-left">anchor top left</option>
          <option value="top">anchor top</option>
          <option value="top-right">anchor top right</option>
          <option value="left">anchor left</option>
          <option value="center">anchor center</option>
          <option value="right">anchor right</option>
          <option value="bottom-left">anchor bottom left</option>
          <option value="bottom">anchor bottom</option>
          <option value="bottom-right">anchor bottom right</option>
        </select>        
      {:else if selectedOverlay.type === "influence"}
        <div>(to do...)</div>
      {/if}
    </div>
  {/if}
</div>

<!--
<div
  style="
    position:absolute;
    padding: 5px;
    left:0;
    bottom: 0;
    background:rgba(255, 255, 255, 0.5);
    display: flex;
    flex-direction: column;
  "
>
  <div>
    {JSON.stringify(canvasTransform)}
  </div>
</div>
-->

<canvas
  bind:this={element}
  on:mousedown={canvasStartDrag}
  on:mousewheel={canvasZoom}
  class:dragging={canvasDragging}
/>

<style>
  :global(body) {
    padding: 0;
    overflow: hidden;
    touch-action: none;
  }
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
  button, input, select, textarea {
    margin: 0;
  }
  label.range {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 5px;
  }
  .controls-area {
    position: absolute;
    padding: 10px;
    right: 10px;
    top: 10px;
    display: flex;
    flex-direction: column;    
    gap: 10px;
    width: 210px;
  }
  .controls-area > div {
    padding: 10px;    
    background: rgba(255, 255, 255, 0.5);
    border: 2px solid rgba(255, 255, 255, 0.5);
    border-radius: 5px;
    display: flex;
    flex-direction: column;
    gap: 5px;
  }  
  .overlay {
    user-select: none;
    -moz-user-select: none;
    -webkit-user-select: none;    
  }
  .overlay.label {
    border: 2px solid transparent;
    padding: 5px;
  }
  .overlay.label:hover {
    border-color: rgba(0, 0, 0, 0.5);
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.4);
  }
  .overlay.label.selected {
    border-color: rgba(0, 64, 128, 1.0);
    box-shadow: 0 0 10px rgba(0, 128, 255, 1.0);
    background: rgba(0, 128, 255, 0.2);
  }
  .influence {
    border: 2px solid rgba(0, 0, 0, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 2rem;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 1.0);
    border-radius: 99999px;
    font-weight: bold;
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.2);
  }
  .influence:hover {
    border-color: rgba(0, 0, 0, 0.5);
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.4);
  }
  .influence.selected {
    border-color: rgba(0, 64, 128, 1.0);
    box-shadow: 0 0 10px rgba(0, 128, 255, 1.0);
  }
</style>
