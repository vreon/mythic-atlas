<script>
  import Canvas from './Canvas.svelte';
  import Controls from './Controls.svelte';
  import TitleCard from './TitleCard.svelte';
</script>

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