import { writable } from "svelte/store";
import { tweened } from "svelte/motion";
import { quadOut } from "svelte/easing";

export const seed = writable(Math.random());
export const noiseFactor = writable(0.5);
export const reliefFactor = writable(0.5);
export const borderFactor = writable(0.05);
export const showInfluences = writable(false);
export const showLabels = writable(true);
export const fakeHeightFactor = tweened(1.0, {
  duration: 0,
  easing: quadOut,
});
