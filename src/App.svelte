<script>
  import Canvas from "./Canvas.svelte";
  import Menu from "./Menu.svelte";
  import Overlays from "./Overlays.svelte";
  import TitleCard from "./TitleCard.svelte";
  import Help from "./Help.svelte";

  import { mode } from "./stores/globalControls";
</script>

{#if $mode === "help"}
  <Help />
{/if}

<Overlays />
<Menu />
<!-- -->
<TitleCard />
<!-- -->
<Canvas />

<style>
  :global(body) {
    padding: 0;
    overflow: hidden;
    touch-action: none;
  }
</style>
