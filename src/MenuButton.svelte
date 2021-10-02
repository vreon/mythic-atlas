<script>
  export let icon;
  export let label;
</script>

<button on:click>
  <svelte:component this={icon} style="width: 100%; height: 100%" />
  {#if label}
    <p>{label}</p>
  {/if}
</button>

<style>
  button {
    pointer-events: auto; /* TODO hmm */
    width: 4em;
    height: 4rem;
    border: 0;
    margin: 0;
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

  button:hover {
    background: rgb(2, 80, 163);
    color: white;
    box-shadow: 0 0 20px 10px rgb(15, 40, 66) inset, 0 5px 10px rgba(5, 12, 73, 0.5);
  }

  button:active {
    box-shadow: 0 0 10px 5px rgb(15, 40, 66) inset, 0 5px 10px rgba(5, 12, 73, 0.5);
    border-bottom-width: 1px;
    padding-top: 13px;
  }

  button > p {
    display: none;
    pointer-events: none;
  }

  button:hover > p {
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
</style>
