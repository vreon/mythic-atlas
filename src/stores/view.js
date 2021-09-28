import { derived, writable } from "svelte/store";
import { vec2, mat3 } from "gl-matrix";

function createView() {
  const { subscribe, update } = writable(mat3.create());

  let previousAspectRatio = null;

  return {
    subscribe,
    translate: (vec) => {
      return update((mat) => {
        const clone = mat3.clone(mat);
        mat3.translate(clone, clone, vec);
        return clone;
      });
    },
    zoom: (scalar, center) => {
      return update((mat) => {
        const clone = mat3.clone(mat);
        const scale = vec2.fromValues(scalar, scalar);
        const negCenter = vec2.negate(vec2.create(), center);
        mat3.translate(clone, clone, center);
        mat3.scale(clone, clone, scale);
        mat3.translate(clone, clone, negCenter);
        return clone;
      });
    },
    resize: (width, height) => {
      return update((mat) => {
        let clone = mat3.clone(mat);
        if (previousAspectRatio !== null) {
          mat3.scale(clone, clone, vec2.fromValues(1.0, 1.0 / previousAspectRatio));
        }
        mat3.scale(clone, clone, vec2.fromValues(1.0, height / width));
        previousAspectRatio = height / width;
        return clone;
      });
    },
  };
}

export const view = createView();
export const invView = derived(
  view,
  $view => {
    let clone = mat3.clone($view);
    mat3.invert(clone, clone);
    return clone;
  }
);