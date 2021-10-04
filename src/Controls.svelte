<script>
  import { fly } from 'svelte/transition';
  import { vec2, mat3 } from "gl-matrix";

  import { view, invView } from "./stores/view.js";
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
    canvasHeight
  } from "./stores/globalControls.js";

  import palettes from "./lib/palettes.js";

  import MenuButton from "./MenuButton.svelte";
  import PaletteInput from "./PaletteInput.svelte";
  import Influence from "./Influence.svelte";

  import ShuffleLine from 'svelte-remixicon/lib/icons/ShuffleLine.svelte';
  import EarthLine from 'svelte-remixicon/lib/icons/EarthLine.svelte';
  import BrushLine from 'svelte-remixicon/lib/icons/BrushLine.svelte';
  import PriceTag3Line from 'svelte-remixicon/lib/icons/PriceTag3Line.svelte';
  import QuestionLine from 'svelte-remixicon/lib/icons/QuestionLine.svelte';
  import ArrowLeftLine from 'svelte-remixicon/lib/icons/ArrowLeftLine.svelte';
  import Loader2Line from 'svelte-remixicon/lib/icons/Loader2Line.svelte';

  let paletteName = "verdant";
  $: paletteName !== "custom" && palette.set([...palettes[paletteName]]);

  function addLabel(text, transform) {
    const overlay = {
      type: "label",
      name: "label" + $overlays.length,
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
    overlays.update(o => [...o, overlay]);
    return overlay;
  }

  function addInfluence(factor, transform) {
    let overlay = {
      type: "influence",
      name: "influence" + $overlays.length,
      factor,
      transform,
      document: {
        position: vec2.create(),
        extent: vec2.create(),
        listeners: {},
      },
    };
    overlays.update(o => [...o, overlay]);
    return overlay;
  }

  addInfluence(1.0, mat3.fromValues(0.6, 0, 0, 0, 0.6, 0, 0.4, 0.4, 0.6));
  addInfluence(-1.0, mat3.fromValues(0.4, 0, 0, 0, 0.4, 0, 0.65, 0.65, 0.4));
  for (let i = 0; i < 7; i++) {
    addInfluence(0.0, mat3.fromValues(0.1, 0, 0, 0, 0.1, 0, -0.075, 0.05 + 0.125 * i, 0.1));
  }

  $: overlays.set($overlays.map((o) => {
    // TODO: I think multiplies here could be another transform

    vec2.transformMat3(o.document.position, vec2.create(), o.transform);
    vec2.transformMat3(o.document.position, o.document.position, $invView);
    vec2.multiply(o.document.position, o.document.position, vec2.fromValues($canvasWidth, $canvasHeight));

    vec2.transformMat3(o.document.extent, vec2.fromValues(1.0, 1.0), o.transform);
    vec2.transformMat3(o.document.extent, o.document.extent, $invView);
    vec2.multiply(o.document.extent, o.document.extent, vec2.fromValues($canvasWidth, $canvasHeight));
    vec2.subtract(o.document.extent, o.document.extent, o.document.position);

    return o;
  }));


  function overlayStartDrag(overlay, e) {
    if (e.button !== 0) {
      return;
    }
    selectedOverlay.set(overlay);
    overlay.document.listeners.stopDrag = () => overlayStopDrag(overlay, e);
    overlay.document.listeners.drag = (e) => overlayDrag(overlay, e);
    addEventListener("mouseup", overlay.document.listeners.stopDrag);
    addEventListener("mousemove", overlay.document.listeners.drag);
  }

  function overlayDrag(overlay, e) {
    // TODO: devicePixelRatio here might be a browser compat issue
    // https://crbug.com/1092358
    let delta = vec2.fromValues(
      (e.movementX / window.devicePixelRatio) / $canvasWidth,
      (e.movementY / window.devicePixelRatio) / $canvasHeight,
    );
    vec2.multiply(delta, delta, vec2.fromValues($view[0], $view[4]));
    vec2.multiply(
      delta,
      delta,
      vec2.fromValues(1.0 / overlay.transform[0], 1.0 / overlay.transform[4])
    );
    mat3.translate(overlay.transform, overlay.transform, delta);
    overlays.set($overlays);
  }

  function overlayStopDrag(overlay, e) {
    if (e.button !== 0) {
      return;
    }
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
    overlays.set($overlays);
  }

  function randomize() {
    fakeHeightFactor.set(0.0, {duration: 400});
    setTimeout(() => {
      seed.set(Math.random());
      fakeHeightFactor.set(1.0, {duration: 1000});
    }, 500);
    console.log($palette);
  }

  function resetMode() {
    mode.set(null);
    selectedOverlay.set(null);
  }

</script>

{#each $overlays as o}
  {#if o.type === "label"}
    <div
      class="overlay label"
      class:selected={$selectedOverlay === o}
      on:mousedown={(e) => $mode === "labels" && overlayStartDrag(o, e)}
      on:dblclick={(e) => {mode.set("labels"); selectedOverlay.set(o);}}
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
    <Influence
      selected={$selectedOverlay === o}
      on:mousedown={(e) => overlayStartDrag(o, e)}
      on:wheel={(e) => overlayScale(o, e)}
      x={o.document.position[0]}
      y={o.document.position[1]}
      width={o.document.extent[0]}
      height={o.document.extent[1]}
      text="{o.factor > 0 ? "+" : ""}{Math.round(o.factor * 100) / 100}"
    />
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
      <PaletteInput bind:palette={$palette} on:input={() => (paletteName = "custom")} />
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
          selectedOverlay.set(addLabel("New label"));
        }}
      >
        + Add label
      </button>
    </div>
  {/if}

  {#if $selectedOverlay !== null}
    <div class="panel" in:fly={{x: 20}}>
      <div><code>{$selectedOverlay.name}</code></div>
      {#if $selectedOverlay.type === "label"}
        <textarea on:keyup={() => overlays.set($overlays)} bind:value={$selectedOverlay.text} />
        <label class="range">
          Size
          <input
            style="padding: 0"
            type="range"
            min="0"
            max="5"
            step="any"
            on:input={() => overlays.set($overlays)}
            bind:value={$selectedOverlay.fontSizeRem}
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
            on:input={() => overlays.set($overlays)}
            bind:value={$selectedOverlay.letterSpacingRem}
          />
        </label>
        <select on:change={() => overlays.set($overlays)} bind:value={$selectedOverlay.textAlign}>
          <option value="left">text left</option>
          <option value="center">text center</option>
          <option value="right">text right</option>
        </select>
        <select on:change={() => overlays.set($overlays)}>
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
      {:else if $selectedOverlay.type === "influence"}
        <div>(to do...)</div>
      {/if}
    </div>
  {/if}

  {#if $mode === null}
    <MenuButton icon={ShuffleLine} label="Random" on:click={randomize} />
    <MenuButton icon={EarthLine} label="Topography" on:click={() => mode.set("topography")} />
    <MenuButton icon={BrushLine} label="Coloring" on:click={() => mode.set("coloring")} />
    <MenuButton icon={PriceTag3Line} label="Labels" on:click={() => mode.set("labels")} />
    <MenuButton icon={Loader2Line} label="Effects" on:click={() => mode.set("effects")} />
  {/if}

  {#if $mode !== null}
    <MenuButton icon={ArrowLeftLine} label="Back" on:click={resetMode} />
  {/if}

  <MenuButton icon={QuestionLine} label="Help" />

</div>

<style>
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
    pointer-events: none;
  }

  .controls > .panel {
    pointer-events: auto;
    padding: 10px;
    background: #0d1017;
    box-shadow: 0 5px 10px hsla(0, 0%, 0%, 0.5);
    color: #bfbdb6;
    border-radius: 3px;
    display: flex;
    flex-direction: column;
    gap: 5px;
    width: 220px;
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
  input[type="range"] {
    width: 100%;
  }
  .panel .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid #333;
    font-weight: bold;
    padding-bottom: 5px;
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

  </style>
