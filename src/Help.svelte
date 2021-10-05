<script>
  import { mode } from "./stores/globalControls";
  import { fly } from 'svelte/transition';
</script>

<div
  on:click={() => mode.set(null)}
  transition:fly={{y:100}}
>
  <h1>Mythic Atlas - Help</h1>

  <h2>About</h2>
  
  <h2>How to use</h2>
  <h3>Navigation</h3>
  <h3>Mode: Topography</h3>
  <h3>Mode: Colors</h3>
  <h3>Mode: Labels</h3>
  <h3>Mode: Effects</h3>

  <h2>Contributing</h2>

  <h2>Known issues</h2>

  <h2>Changelog</h2>
</div>

<style>
  div {
    --margin: 20px;
    position: absolute;
    left: 0;
    top: 0;
    width: calc(100% - var(--margin) * 2);
    height: calc(100% - var(--margin) * 2);
    margin: var(--margin);
    background: white;
    overflow-y: auto;
    z-index: 9999;
  }
</style>