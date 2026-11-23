/// Default meeting length when a stored meeting has no usable duration.
const int defaultMeetingDurationMinutes = 60;

/// Returns a safe positive whole-minute duration for a stored meeting.
///
/// Supabase/JSON may decode numeric values as [int] or [double], so the raw
/// value is accepted as any finite [num]. Missing, non-numeric, non-finite,
/// zero and negative values fall back to [defaultMeetingDurationMinutes].
int meetingDurationMinutes(Map<String, dynamic> meeting) {
  final raw = meeting['duration_minutes'];
  if (raw is num && raw.isFinite && raw > 0) {
    final wholeMinutes = raw.toInt();
    if (wholeMinutes > 0) return wholeMinutes;
  }
  return defaultMeetingDurationMinutes;
}

/// A single calendar entry for one day occupied by a multi-day meeting.
class MeetingCalendarSegment {
  const MeetingCalendarSegment({
    required this.day,
    required this.start,
    required this.end,
    required this.continued,
  });

  final DateTime day;
  final DateTime start;
  final DateTime end;
  final bool continued;
}

/// Splits a meeting into one segment per occupied calendar date.
///
/// A meeting ending exactly at midnight does not occupy the following date.
List<MeetingCalendarSegment> meetingCalendarSegments(
  DateTime start,
  int durationMinutes,
) {
  final end = start.add(Duration(minutes: durationMinutes));
  final endsAtMidnight = end.hour == 0 &&
      end.minute == 0 &&
      end.second == 0 &&
      end.millisecond == 0 &&
      end.microsecond == 0;
  var lastDay = DateTime(end.year, end.month, end.day);
  if (endsAtMidnight) lastDay = lastDay.subtract(const Duration(days: 1));

  final segments = <MeetingCalendarSegment>[];
  var day = DateTime(start.year, start.month, start.day);
  while (!day.isAfter(lastDay)) {
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59);
    final segmentStart = day.year == start.year &&
            day.month == start.month &&
            day.day == start.day
        ? start
        : day;
    final segmentEnd = end.isBefore(dayEnd) ? end : dayEnd;
    if (segmentStart.isBefore(segmentEnd)) {
      segments.add(MeetingCalendarSegment(
        day: day,
        start: segmentStart,
        end: segmentEnd,
        continued: segments.isNotEmpty ||
            segmentStart.year != start.year ||
            segmentStart.month != start.month ||
            segmentStart.day != start.day,
      ));
    }
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return segments;
}
