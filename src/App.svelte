<script>
  import reglWrapper from "regl";
  import primitiveQuad from "primitive-quad";
  import { vec2, mat3 } from "gl-matrix";
  import { onMount } from "svelte";
  import { fly } from 'svelte/transition';

  import frag from "./frag.glsl";
  import vert from "./vert.glsl";
  import palettes from "./lib/palettes.js";
  import { hexToVec3 } from "./lib/color.js";

  import { view, invView } from "./stores/view.js";
  import {
    mode,
    seed,
    noiseFactor,
    reliefFactor,
    borderFactor,
    fakeHeightFactor,
  } from "./stores/globalControls.js";

  import PaletteInput from "./PaletteInput.svelte";
  import TitleCard from './TitleCard.svelte';
  import ShuffleLine from 'svelte-remixicon/lib/icons/ShuffleLine.svelte';
  import EarthLine from 'svelte-remixicon/lib/icons/EarthLine.svelte';
  import BrushLine from 'svelte-remixicon/lib/icons/BrushLine.svelte';
  import PriceTag3Line from 'svelte-remixicon/lib/icons/PriceTag3Line.svelte';
  import QuestionLine from 'svelte-remixicon/lib/icons/QuestionLine.svelte';
  import ArrowLeftLine from 'svelte-remixicon/lib/icons/ArrowLeftLine.svelte';
  import Loader2Line from 'svelte-remixicon/lib/icons/Loader2Line.svelte';

  const quad = primitiveQuad();
  let gl;
  let element;
  let width = 0;
  let height = 0;
  let regl;

  let canvasDragging = false;

  let paletteName = "verdant";
  let palette = [];

  $: paletteName !== "custom" && (palette = [...palettes[paletteName]]);
  $: paletteRGB = palette.map(hexToVec3);

  let overlays = [];
  let selectedOverlay;

  function addLabel(text, transform) {
    const label = {
      type: "label",
      name: "label" + overlays.length,
      text,
      fontSizeRem: 2,
      letterSpacingRem: 0,
      textAlign: "left",
      transform: transform || mat3.fromValues(1, 0, 0, 0, 1, 0, 0.5, 0.5, 1),
      document: {
        position: vec2.create(),
        extent: vec2.create(),
        listeners: {},
      },
    };
    overlays.push(label);
    overlays = overlays;
    return label;
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
      },
    });
    overlays = overlays;
  }

  addInfluence(1.0, mat3.fromValues(0.6, 0, 0, 0, 0.6, 0, 0.4, 0.4, 0.6));
  addInfluence(-1.0, mat3.fromValues(0.4, 0, 0, 0, 0.4, 0, 0.65, 0.65, 0.4));
  for (let i = 0; i < 7; i++) {
    addInfluence(0.0, mat3.fromValues(0.1, 0, 0, 0, 0.1, 0, -0.075, 0.05 + 0.125 * i, 0.1));
  }

  $: overlays = overlays.map((o) => {
    // TODO: I think multiplies here could be another transform

    vec2.transformMat3(o.document.position, vec2.create(), o.transform);
    vec2.transformMat3(o.document.position, o.document.position, $invView);
    vec2.multiply(o.document.position, o.document.position, vec2.fromValues(width, height));

    vec2.transformMat3(o.document.extent, vec2.fromValues(1.0, 1.0), o.transform);
    vec2.transformMat3(o.document.extent, o.document.extent, $invView);
    vec2.multiply(o.document.extent, o.document.extent, vec2.fromValues(width, height));
    vec2.subtract(o.document.extent, o.document.extent, o.document.position);

    return o;
  });

  $: influenceTransforms = overlays.filter((o) => o.type === "influence").map((o) => o.transform);

  // BUG[uniform1fv]: this should be a float[] but regl chokes
  // See https://github.com/regl-project/regl/issues/611
  $: influenceFactors = overlays
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
    selectedOverlay = null;
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
    view.translate(vec2.negate(vec2.create(), delta));
  }

  function canvasStopDrag() {
    canvasDragging = false;
    removeEventListener("mouseup", canvasStopDrag);
    removeEventListener("mousemove", canvasDrag);
  }

  function canvasZoom(e) {
    let step = 0.1;
    let zoom = 1.0 - Math.sign(e.wheelDeltaY) * step;
    let center = normalizedScreenCoordinates(e.clientX, e.clientY);
    view.zoom(zoom, center);
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
      e.movementY / window.devicePixelRatio
    );
    vec2.multiply(delta, delta, vec2.fromValues($view[0], $view[4]));
    vec2.multiply(
      delta,
      delta,
      vec2.fromValues(1.0 / overlay.transform[0], 1.0 / overlay.transform[4])
    );
    // vec2.multiply(delta, delta, vec2.fromValues(7, 8));
    mat3.translate(overlay.transform, overlay.transform, delta);
    overlays = overlays;
  }

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
    fakeHeightFactor.set(0.0, {duration: 400});
    setTimeout(() => {
      seed.set(Math.random());
      fakeHeightFactor.set(1.0, {duration: 1000});
    }, 500);
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
        // Make the canvas the same size
        width = canvas.width = displayWidth;
        height = canvas.height = displayHeight;
        view.resize(width, height);
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

{#each overlays as o}
  {#if o.type === "label"}
    <div
      class="overlay label"
      class:selected={selectedOverlay === o}
      on:mousedown={(e) => $mode === "labels" && overlayStartDrag(o, e)}
      on:dblclick={(e) => {mode.set("labels"); selectedOverlay = o;}}
      style="
        position: absolute;
        color: white;
        text-shadow: 0 1px 2px rgba(0, 0, 0, 1.0);
        font-size: {o.fontSizeRem}rem;
        line-height: {o.fontSizeRem}rem;
        letter-spacing: {o.letterSpacingRem}rem;
        text-align: {o.textAlign};
        font-family: 'Alegreya', serif;
        font-weight: 800;
        font-style: italic;
        white-space: pre;
        left: {o.document.position[0]}px;
        top: {o.document.position[1]}px;
      "
    >
      {o.text}
    </div>
  {:else if o.type === "influence" && $mode === "topography"}
    <div
      class="overlay influence"
      class:selected={selectedOverlay === o}
      on:mousedown={(e) => overlayStartDrag(o, e)}
      on:mousewheel={(e) => overlayScale(o, e)}
      style="
        position:absolute;
        overflow: hidden;
        cursor: move;
        left: {o.document.position[0] - o.document.extent[0] / 2}px;
        top: {o.document.position[1] - o.document.extent[1] / 2}px;
        width: {o.document.extent[0]}px;
        height: {o.document.extent[1]}px;
      "
    >
      {o.factor > 0 ? "+" : ""}{Math.round(o.factor * 100) / 100}
    </div>
  {/if}
{/each}

<div class="controls">

  {#if $mode === "topography"}
    <div class="panel" in:fly={{x: 20}}>
      <div class="header">
        <EarthLine />
        Topography
      </div>
      <label class="range">
        Warp
        <input style="padding: 0" type="range" min="0" max="1" step="any" bind:value={$noiseFactor} />
      </label>
      <label class="range">
        Relief
        <input
          style="padding: 0"
          type="range"
          min="0"
          max="1"
          step="any"
          bind:value={$reliefFactor}
        />
      </label>
      <button on:click|preventDefault={() => seed.set(Math.random())}>
        <ShuffleLine />
        Random
      </button>      
    </div>
  {:else if $mode === "coloring"}
    <div class="panel" in:fly={{x: 20}}>
      <div class="header">
        <BrushLine />
        Coloring
      </div>
      <PaletteInput bind:palette on:input={() => (paletteName = "custom")} />
      <select bind:value={paletteName}>
        <option value="custom">custom</option>
        {#each Object.keys(palettes) as name}
          <option value={name}>{name}</option>
        {/each}
      </select>
    </div>
  {:else if $mode === "effects"}
    <div class="panel" in:fly={{x: 20}}>
      <div class="header">
        <Loader2Line />
        Effects
      </div>
      <label class="range">
        Border
        <input
          style="padding: 0"
          type="range"
          min="0"
          max="1"
          step="any"
          bind:value={$borderFactor}
        />
      </label>
    </div>
  {:else if $mode === "labels"}
    <div class="panel" in:fly={{x: 20}}>
      <div class="header">
        <PriceTag3Line />
        Labels
      </div>      
      <button
        on:click|preventDefault={() => {
          selectedOverlay = addLabel("New label");
        }}
      >
        + Add label
      </button>
    </div>
  {/if}


  {#if selectedOverlay}
    <div class="panel">
      <div><code>{selectedOverlay.name}</code></div>
      {#if selectedOverlay.type === "label"}
        <textarea on:keyup={() => (overlays = overlays)} bind:value={selectedOverlay.text} />
        <label class="range">
          Size
          <input
            style="padding: 0"
            type="range"
            min="0"
            max="5"
            step="any"
            on:input={() => (overlays = overlays)}
            bind:value={selectedOverlay.fontSizeRem}
          />
        </label>
        <label class="range">
          Tracking
          <input
            style="padding: 0"
            type="range"
            min="0"
            max="5"
            step="any"
            on:input={() => (overlays = overlays)}
            bind:value={selectedOverlay.letterSpacingRem}
          />
        </label>
        <select on:change={() => (overlays = overlays)} bind:value={selectedOverlay.textAlign}>
          <option value="left">text left</option>
          <option value="center">text center</option>
          <option value="right">text right</option>
        </select>
        <select on:change={() => (overlays = overlays)}>
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

  {#if $mode === null}
    <button on:click|preventDefault={randomize}>
      <ShuffleLine style="width: 100%; height: 100%" />
      <p>Random</p>
    </button>
    <button on:click|preventDefault={() => mode.set("topography")}>
      <EarthLine style="width: 100%; height: 100%" />
      <p>Topography</p>
    </button>
    <button on:click|preventDefault={() => mode.set("coloring")}>
      <BrushLine style="width: 100%; height: 100%" />
      <p>Coloring</p>
    </button>
    <button on:click|preventDefault={() => mode.set("labels")}>
      <PriceTag3Line style="width: 100%; height: 100%" />
      <p>Labels</p>
    </button>
    <button on:click|preventDefault={() => mode.set("effects")}>
      <Loader2Line style="width: 100%; height: 100%" />
      <p>Effects</p>
    </button>
  {/if}

  {#if $mode !== null}
    <button on:click|preventDefault={resetMode}>
      <ArrowLeftLine style="width: 100%; height: 100%" />
      <p>Back</p>
    </button>
  {/if}

  <button>
    <QuestionLine style="width: 100%; height: 100%" />
    <p>Help</p>
  </button>

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
    {JSON.stringify($view)}
  </div>
  <div>
    {JSON.stringify($invView)}
  </div>
</div>
-->

<!-- -->
<TitleCard />
<!-- -->

<canvas
  bind:this={element}
  on:mousedown={canvasStartDrag}
  on:mousewheel={canvasZoom}
  on:dblclick={resetMode}
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
  button,
  input,
  select,
  textarea {
    margin: 0;
    padding: 0;
  }

  .controls {
    position: absolute;
    padding: 10px;
    right: 10px;
    top: 10px;
    display: flex;
    flex-direction: column;
    gap: 10px;
    width: 220px;
    pointer-events: none;
  }
  .controls div, .controls button {
    /* Yikes */
    pointer-events: auto;
  }

  .controls > .panel {
    padding: 10px;
    background: #0d1017;
    box-shadow: 0 5px 10px hsla(0, 0%, 0%, 0.5);
    color: #bfbdb6;
    border-radius: 3px;
    display: flex;
    flex-direction: column;
    gap: 5px;
  }
  .panel button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 5px;
  }
  .panel button, .panel select {
    border: 0;
    padding: 5px;
    background: rgb(15, 40, 66);
    color: white;
    box-shadow: 0 2px rgb(10, 27, 44);
  }
  .panel button:hover, .panel select:hover {
    background: rgb(17, 45, 75);
  }
  .panel option {
    color: white;
    background: rgb(15, 40, 66);
  }
  .panel label.range {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 5px;
  }
  .panel .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid #333;
    font-weight: bold;
    padding-bottom: 5px;
  }

  .controls > button {
    width: 4em;
    height: 4rem;
    border: 0;
    padding: 10px;    
    background: rgb(15, 40, 66);
    color: rgb(128, 166, 206);
    border-style: solid;
    border-width: 0 0 4px 0;
    border-color: rgb(10, 27, 44);
    border-radius: 10px;
    transition: all 50ms linear;
    cursor: pointer;
    box-shadow: 0 0 20px 10px rgb(15, 40, 66) inset, 0 5px 10px hsla(0, 0%, 0%, 0.5);
    position: relative;
    align-self: end;
  }

  .controls > button:hover {
    background: rgb(2, 80, 163);
    color: white;
    box-shadow: 0 0 20px 10px rgb(15, 40, 66) inset, 0 5px 10px rgba(5, 12, 73, 0.5);
  }

  .controls > button:active {
    box-shadow: 0 0 10px 5px rgb(15, 40, 66) inset, 0 5px 10px rgba(5, 12, 73, 0.5);
    border-bottom-width: 1px;
    padding-top: 13px;
  }

  .controls > button > p {
    display: none;
    pointer-events: none;
  }

  .controls > button:hover > p {
    pointer-events: none;
    position: absolute;
    margin: 0;
    padding: 0;
    left: 0;
    top: 0;
    height: 100%;
    display: flex;
    justify-content: end;
    align-items: center;
    width: 10rem;
    margin-left: -11rem;
    color: white;
    text-shadow: 0 0 10px black;
    font-size: 1.2rem;
    font-weight: bold;
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
    border-color: rgba(0, 64, 128, 1);
    box-shadow: 0 0 10px rgba(0, 128, 255, 1);
    background: rgba(0, 128, 255, 0.2);
  }
  .influence {
    border: 2px solid rgba(0, 0, 0, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 2rem;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 1);
    border-radius: 99999px;
    font-weight: bold;
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.2);
  }
  .influence:hover {
    border-color: rgba(0, 0, 0, 0.5);
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.4);
  }
  .influence.selected {
    border-color: rgba(0, 64, 128, 1);
    box-shadow: 0 0 10px rgba(0, 128, 255, 1);
  }
</style>
