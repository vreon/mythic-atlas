<script>
  import { fly } from "svelte/transition";

  export let title = null;
  export let icon = null;
</script>

<section in:fly={{ x: 20 }}>
  {#if title}
    <div class="header">
      <svelte:component this={icon} />
      {title}
    </div>
  {/if}
  <slot />
</section>

<style>
  section {
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
  div {
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid #333;
    font-weight: bold;
    padding-bottom: 5px;
  }

  :global(button),
  :global(input),
  :global(select),
  :global(textarea) {
    margin: 0;
    padding: 0;
  }

  :global(button) {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 5px;
  }
  :global(button),
  :global(select) {
    border: 0;
    padding: 5px;
    background: rgb(15, 40, 66);
    color: white;
    box-shadow: 0 2px rgb(10, 27, 44);
  }
  :global(button:hover),
  :global(select:hover) {
    background: rgb(17, 45, 75);
  }
  :global(button:not(:disabled):active) {
    background: rgb(14, 62, 114);
  }
  :global(option) {
    color: white;
    background: rgb(15, 40, 66);
  }
  :global(label) {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 5px;
  }
  :global(input[type="range"]) {
    width: 100%;
    padding: 0;
  }
</style>
