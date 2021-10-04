<script>
  export let selected = false;
  export let x;
  export let y;
  export let text;
  export let fontSizeRem;
  export let letterSpacingRem;
  export let textAlign;
</script>

<div
  class:selected
  on:mousedown
  on:dblclick
  style="
    color: white;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 1.0);
    font-size: {fontSizeRem}rem;
    line-height: {fontSizeRem}rem;
    letter-spacing: {letterSpacingRem}rem;
    text-align: {textAlign};
    font-family: 'Alegreya', serif;
    font-weight: 800;
    font-style: italic;
    transform: translate({x}px, {y}px);
  "
>
  {text}
</div>

<style>
  div {
    position: absolute;
    user-select: none;
    -moz-user-select: none;
    -webkit-user-select: none;
    border: 2px solid transparent;
    padding: 5px;
    white-space: pre;
  }
  div:hover {
    border-color: rgba(0, 0, 0, 0.5);
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.4);
  }
  div.selected {
    border-color: rgba(0, 64, 128, 1);
    box-shadow: 0 0 10px rgba(0, 128, 255, 1);
    background: rgba(0, 128, 255, 0.2);
  }
</style>
