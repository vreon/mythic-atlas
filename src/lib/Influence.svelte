<script>
  export let hue = 0;
</script>

<div
  style="--hue: {hue}"
  on:click
>
  <slot></slot>
</div>

<style>
  div { 
    user-select: none;
    -moz-user-select: none;
    -webkit-user-select: none;
    font-size: 2rem;
    border-radius: 9999px;
    position: absolute;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: move;
    text-shadow: 0 0 10px black;
    color: hsla(var(--hue), 100%, 50%, 1.0);
    background: radial-gradient(hsla(var(--hue), 100%, 50%, 0.5), transparent 80%);
    width: 100%;
    height: 100%;
  }
</style>
