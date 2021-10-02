import { writable } from "svelte/store";
import { tweened } from "svelte/motion";
import { quadOut } from "svelte/easing";

export const mode = writable(null);
export const seed = writable(Math.random());
export const noiseFactor = writable(0.5);
export const reliefFactor = writable(0.5);
export const borderFactor = writable(0.05);
export const fakeHeightFactor = tweened(1.0, {
  duration: 0,
  easing: quadOut,
});
export const selectedOverlay = writable(null);
export const palette = writable([]);
export const overlays = writable([]);