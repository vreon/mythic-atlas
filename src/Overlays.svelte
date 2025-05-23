<script>
  import { vec2, mat3 } from "gl-matrix";
  import { view, invView } from "./stores/view.js";
  import {
    mode,
    overlays,
    selectedOverlay,
    canvasWidth,
    canvasHeight,
  } from "./stores/globalControls.js";

  import Influence from "./Influence.svelte";
  import Label from "./Label.svelte";

  let previousPointerMoveEvent;

  $: overlays.set(
    $overlays.map((o) => {
      // TODO: I think multiplies here could be another transform

      vec2.transformMat3(o.document.position, vec2.create(), o.transform);
      vec2.transformMat3(o.document.position, o.document.position, $invView);
      vec2.multiply(
        o.document.position,
        o.document.position,
        vec2.fromValues($canvasWidth, $canvasHeight)
      );

      vec2.transformMat3(o.document.extent, vec2.fromValues(1.0, 1.0), o.transform);
      vec2.transformMat3(o.document.extent, o.document.extent, $invView);
      vec2.multiply(
        o.document.extent,
        o.document.extent,
        vec2.fromValues($canvasWidth, $canvasHeight)
      );
      vec2.subtract(o.document.extent, o.document.extent, o.document.position);

      return o;
    })
  );

  function startDrag(overlay, e) {
    if (!e.isPrimary) {
      return;
    }
    selectedOverlay.set(overlay);
    overlay.document.listeners.stopDrag = () => stopDrag(overlay, e);
    overlay.document.listeners.drag = (e) => drag(overlay, e);
    addEventListener("pointermove", overlay.document.listeners.drag);
    addEventListener("pointerup", overlay.document.listeners.stopDrag);
    addEventListener("pointercancel", overlay.document.listeners.stopDrag);
  }

  function drag(overlay, e) {
    if (!e.isPrimary) {
      return;
    }
    if (previousPointerMoveEvent) {
        let delta = vec2.fromValues(
          (e.clientX - previousPointerMoveEvent.clientX) / $canvasWidth,
          (e.clientY - previousPointerMoveEvent.clientY) / $canvasHeight
        );
      vec2.multiply(delta, delta, vec2.fromValues($view[0], $view[4]));
      vec2.multiply(
        delta,
        delta,
        vec2.fromValues(1.0 / overlay.transform[0], 1.0 / overlay.transform[4])
      );
      mat3.translate(overlay.transform, overlay.transform, delta);
      overlays.set($overlays);
    }
    previousPointerMoveEvent = e;
  }

  function stopDrag(overlay, e) {
    if (!e.isPrimary) {
      return;
    }
    previousPointerMoveEvent = null;
    removeEventListener("pointermove", overlay.document.listeners.drag);
    removeEventListener("pointerup", overlay.document.listeners.stopDrag);
    removeEventListener("pointercancel", overlay.document.listeners.stopDrag);
  }

  function scale(overlay, e) {
    let step = 0.1;
    if (e.shiftKey) {
      overlay.factor += step * Math.sign(e.wheelDeltaY);
    } else if (e.ctrlKey) {
      e.preventDefault();
    } else {
      let zoom = 1.0 - Math.sign(e.wheelDeltaY) * -step;
      let scale = vec2.fromValues(zoom, zoom); // <whispers> zoom zoom
      mat3.scale(overlay.transform, overlay.transform, scale);
    }
    overlays.set($overlays);
  }

  function lerp(v0, v1, t) {
    return (1 - t) * v0 + t * v1;
  }
</script>

{#each $overlays as o}
  {#if o.type === "label"}
    <Label
      selected={$selectedOverlay === o}
      interactable={$mode === "labels"}
      on:pointerdown={(e) => $mode === "labels" && startDrag(o, e)}
      x={o.document.position[0]}
      y={o.document.position[1]}
      scale={lerp(1.0, 1.0 / $view[0] * $canvasWidth / 1000, o.zooming)}
      fontSizeRem={o.fontSizeRem}
      letterSpacingRem={o.letterSpacingRem}
      rotationDeg={o.rotationDeg}
      textAlign={o.textAlign}
      text={o.text}
      anchor={o.anchor}
    />
  {:else if o.type === "topoInfluence" && $mode === "topography"}
    <Influence
      selected={$selectedOverlay === o}
      on:pointerdown={(e) => startDrag(o, e)}
      on:wheel={(e) => scale(o, e)}
      x={o.document.position[0]}
      y={o.document.position[1]}
      width={o.document.extent[0]}
      height={o.document.extent[1]}
      text="{o.factor > 0 ? '+' : ''}{Math.round(o.factor * 100) / 100}"
    />
  {/if}
{/each}
