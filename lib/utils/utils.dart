double remap(
  double minOld,
  double maxOld,
  double minNew,
  double maxNew,
  double v,
) {
  return minNew + (v-minOld) * (maxNew - minNew) / (maxOld-minOld);
}
