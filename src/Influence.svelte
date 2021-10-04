<script>
  export let selected = false;
  export let x;
  export let y;
  export let width;
  export let height;
  export let text;
</script>

<div
  class:selected
  on:mousedown
  on:wheel
  style="
    transform: translate({x - width / 2}px, {y - height / 2}px);
    width: {width}px;
    height: {height}px;
  "
>
  {text}
</div>

<style>
  div {
    user-select: none;
    -moz-user-select: none;
    -webkit-user-select: none;
    position: absolute;
    overflow: hidden;
    cursor: move;
    border: 2px solid rgba(0, 0, 0, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 2rem;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 1);
    border-radius: 99999px;
    font-weight: bold;
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.2);
  }
  div:hover {
    border-color: rgba(0, 0, 0, 0.5);
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.4);
  }
  div.selected {
    border-color: rgba(0, 64, 128, 1);
    box-shadow: 0 0 10px rgba(0, 128, 255, 1);
  }
</style>
