/// Formats a timestamp the way a feed does: short, relative, and readable at a
/// glance.
///
/// Falls back to an absolute date once "weeks ago" stops being useful.
/// Wording lives here rather than in each widget so T16 has one place to
/// localize.
String timeAgo(DateTime timestamp, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final Duration elapsed = reference.difference(timestamp);

  if (elapsed.isNegative) return 'now';
  if (elapsed.inSeconds < 60) return 'now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d';
  if (elapsed.inDays < 28) return '${elapsed.inDays ~/ 7}w';

  return '${timestamp.day} ${_month(timestamp.month)}'
      '${timestamp.year == reference.year ? '' : ' ${timestamp.year}'}';
}

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _month(int month) => _months[month - 1];
