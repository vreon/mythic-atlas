<script>
  export let selected = false;
  export let interactable = true;
  export let x;
  export let y;
  export let text;
  export let fontSizeRem;
  export let letterSpacingRem;
  export let rotationDeg;
  export let textAlign;
  export let anchor = "c";
  export let scale = 1.0;

  let offsetX;
  let offsetY;

  let w;
  let h;

  $: if (anchor === "nw" || anchor === "w" || anchor === "sw") {
    offsetX = 0;
  } else if (anchor === "n" || anchor === "c" || anchor === "s") {
    offsetX = -w / 2;
  } else if (anchor === "ne" || anchor === "e" || anchor === "se") {
    offsetX = -w;
  }

  $: if (anchor === "nw" || anchor === "n" || anchor === "ne") {
    offsetY = 0;
  } else if (anchor === "w" || anchor === "c" || anchor === "e") {
    offsetY = -h / 2;
  } else if (anchor === "sw" || anchor === "s" || anchor === "se") {
    offsetY = -h;
  }
</script>

<div
  class:selected
  class:interactable
  on:pointerdown
  bind:clientWidth={w}
  bind:clientHeight={h}
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
    transform: translate({x + offsetX}px, {y + offsetY}px) rotate({rotationDeg}deg) scale({scale});
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
    pointer-events: none;
  }
  div.interactable {
    pointer-events: auto;
    border-color: rgba(0, 0, 0, 0.1);
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.2);
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
