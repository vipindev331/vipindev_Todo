import 'package:intl/intl.dart';

/// Compacts large counts the way GitHub does: 1200 -> "1.2k".
String formatCount(int value) {
  if (value < 1000) return '$value';
  if (value < 1000000) {
    final k = value / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }
  final m = value / 1000000;
  return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}m';
}

/// "Updated 3 days ago" style text, falling back to an absolute date for
/// anything older than a year.
String formatRelativeDate(DateTime? date, {DateTime? now}) {
  if (date == null) return 'Unknown';

  final reference = now ?? DateTime.now();
  final diff = reference.difference(date);

  if (diff.isNegative) return 'just now';
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return '${months}mo ago';
  }
  return DateFormat.yMMMd().format(date);
}
