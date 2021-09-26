precision mediump float;
attribute vec3 position;
attribute vec2 uv;
varying vec2 vUv;

void main() {
    // TODO: unclear why I have to flip the Y axis here...
    vUv = vec2(uv.x, 1.0 - uv.y);
    gl_Position = vec4(position.xyz, 1);
}