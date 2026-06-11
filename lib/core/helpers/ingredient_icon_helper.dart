String getIngredientEmoji(String nombre) {
  final normalized = nombre.trim().toLowerCase();

  if (normalized.contains('tomate')) return '🍅';
  if (normalized.contains('papa')) return '🥔';
  if (normalized.contains('carne')) return '🥩';
  if (normalized.contains('pollo')) return '🍗';
  if (normalized.contains('queso')) return '🧀';
  if (normalized.contains('leche')) return '🥛';
  if (normalized.contains('harina')) return '🌾';
  if (normalized.contains('aceite')) return '🛢️';
  if (normalized.contains('huevo')) return '🥚';

  return '🧺';
}
