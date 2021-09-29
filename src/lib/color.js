export function hexToVec3(hex) {
  let rgb = parseInt(hex.slice(1), 16);
  return [
    ((rgb & 0xff0000) >> 16) / 255,
    ((rgb & 0x00ff00) >> 8) / 255,
    ((rgb & 0x0000ff) >> 0) / 255,
  ];
}