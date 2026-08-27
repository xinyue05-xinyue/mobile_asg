String eventDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

String eventSchedule(DateTime start, DateTime end) =>
    'Starts: ${eventDateTime(start)}\nEnds: ${eventDateTime(end)}';
