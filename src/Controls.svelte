<script>
  import { vec2, mat3 } from "gl-matrix";
  
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
  } from "./stores/globalControls.js";

  import palettes from "./lib/palettes.js";

  import MenuButton from "./MenuButton.svelte";
  import PaletteInput from "./PaletteInput.svelte";
  import ControlPanel from "./ControlPanel.svelte";

  import ShuffleLine from "svelte-remixicon/lib/icons/ShuffleLine.svelte";
  import EarthLine from "svelte-remixicon/lib/icons/EarthLine.svelte";
  import BrushLine from "svelte-remixicon/lib/icons/BrushLine.svelte";
  import PriceTag3Line from "svelte-remixicon/lib/icons/PriceTag3Line.svelte";
  import QuestionLine from "svelte-remixicon/lib/icons/QuestionLine.svelte";
  import ArrowLeftLine from "svelte-remixicon/lib/icons/ArrowLeftLine.svelte";
  import Loader2Line from "svelte-remixicon/lib/icons/Loader2Line.svelte";

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
    overlays.update((o) => [...o, overlay]);
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
    overlays.update((o) => [...o, overlay]);
    return overlay;
  }

  addInfluence(1.0, mat3.fromValues(0.6, 0, 0, 0, 0.6, 0, 0.4, 0.4, 0.6));
  addInfluence(-1.0, mat3.fromValues(0.4, 0, 0, 0, 0.4, 0, 0.65, 0.65, 0.4));
  for (let i = 0; i < 7; i++) {
    addInfluence(0.0, mat3.fromValues(0.1, 0, 0, 0, 0.1, 0, -0.075, 0.05 + 0.125 * i, 0.1));
  }

  function randomize() {
    fakeHeightFactor.set(0.0, { duration: 400 });
    setTimeout(() => {
      seed.set(Math.random());
      fakeHeightFactor.set(1.0, { duration: 1000 });
    }, 500);
    console.log($palette);
  }

  function resetMode() {
    mode.set(null);
    selectedOverlay.set(null);
  }
</script>

<div class="controls">
  {#if $mode === "topography"}
    <ControlPanel title="Topography" icon={EarthLine}>
      <label class="range">
        Warp
        <input type="range" min="0" max="1" step="any" bind:value={$noiseFactor} />
      </label>
      <label class="range">
        Relief
        <input type="range" min="0" max="1" step="any" bind:value={$reliefFactor} />
      </label>
      <button on:click|preventDefault={() => seed.set(Math.random())}>
        <ShuffleLine />
        Random
      </button>
    </ControlPanel>
  {:else if $mode === "colors"}
    <ControlPanel title="Colors" icon={BrushLine}>
      <PaletteInput bind:palette={$palette} on:input={() => (paletteName = "custom")} />
      <select bind:value={paletteName}>
        <option value="custom">custom</option>
        {#each Object.keys(palettes) as name}
          <option value={name}>{name}</option>
        {/each}
      </select>
    </ControlPanel>
  {:else if $mode === "effects"}
    <ControlPanel title="Effects" icon={Loader2Line}>
      <label class="range">
        Border
        <input type="range" min="0" max="1" step="any" bind:value={$borderFactor} />
      </label>
    </ControlPanel>
  {:else if $mode === "labels"}
    <ControlPanel title="Labels" icon={PriceTag3Line}>
      <button
        on:click|preventDefault={() => {
          selectedOverlay.set(addLabel("New label"));
        }}
      >
        + Add label
      </button>
    </ControlPanel>
  {/if}

  {#if $selectedOverlay !== null}
    <ControlPanel>
      <div><code>{$selectedOverlay.name}</code></div>
      {#if $selectedOverlay.type === "label"}
        <textarea on:keyup={() => overlays.set($overlays)} bind:value={$selectedOverlay.text} />
        <label class="range">
          Size
          <input
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
    </ControlPanel>
  {/if}

  {#if $mode === null}
    <MenuButton icon={ShuffleLine} label="Random" on:click={randomize} />
    <MenuButton icon={EarthLine} label="Topography" on:click={() => mode.set("topography")} />
    <MenuButton icon={BrushLine} label="Colors" on:click={() => mode.set("colors")} />
    <MenuButton icon={PriceTag3Line} label="Labels" on:click={() => mode.set("labels")} />
    <MenuButton icon={Loader2Line} label="Effects" on:click={() => mode.set("effects")} />
  {/if}

  {#if $mode !== null}
    <MenuButton icon={ArrowLeftLine} label="Back" on:click={resetMode} />
  {/if}

  <MenuButton icon={QuestionLine} label="Help" />
</div>

<style>
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
</style>
