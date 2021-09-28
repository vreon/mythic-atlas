import { writable } from "svelte/store";

export const seed = writable(Math.random());
export const noiseFactor = writable(0.5);
export const reliefFactor = writable(0.5);
export const borderFactor = writable(0.05);
export const showInfluences = writable(false);
export const showLabels = writable(true);