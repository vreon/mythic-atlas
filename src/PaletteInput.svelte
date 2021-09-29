<script>
  export let palette = [];
</script>

<div class="palette">
  {#each palette as color}
    <input type="color" bind:value={color} on:change on:input />
  {/each}
</div>

<style>
  div {
    display: flex;
    gap: 1px;
  }
  input[type="color"] {
    flex: 1;
    background: none;
    border: 0;
    padding: 0;
    margin: 0;
    height: 30px;
  }
  input[type="color"]::-webkit-color-swatch {
    border: 2px solid rgba(0, 0, 0, 0.2);
    border-radius: 2px;
    margin: 0;
    padding: 0;
  }
  input[type="color"]::-webkit-color-swatch-wrapper {
    padding: 0;
  }
</style>
