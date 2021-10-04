<script>
  import Canvas from './Canvas.svelte';
  import Controls from './Controls.svelte';
  import Overlays from './Overlays.svelte';
  import TitleCard from './TitleCard.svelte';
</script>

<Overlays />
<Controls />
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