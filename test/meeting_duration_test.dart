import 'package:flutter_test/flutter_test.dart';

import 'package:ell_ena/services/meeting_duration.dart';

void main() {
  group('meetingDurationMinutes', () {
    test('uses the stored whole-minute duration', () {
      expect(meetingDurationMinutes({'duration_minutes': 90}), 90);
    });

    test('accepts a JSON-decoded double', () {
      expect(meetingDurationMinutes({'duration_minutes': 90.0}), 90);
    });

    test('uses the default for missing or invalid values', () {
      expect(meetingDurationMinutes({}), defaultMeetingDurationMinutes);
      expect(
        meetingDurationMinutes({'duration_minutes': '90'}),
        defaultMeetingDurationMinutes,
      );
      expect(
        meetingDurationMinutes({'duration_minutes': 0}),
        defaultMeetingDurationMinutes,
      );
      expect(
        meetingDurationMinutes({'duration_minutes': -30}),
        defaultMeetingDurationMinutes,
      );
      expect(
        meetingDurationMinutes({'duration_minutes': double.nan}),
        defaultMeetingDurationMinutes,
      );
    });

    test('falls back when a fractional duration truncates to zero', () {
      expect(
        meetingDurationMinutes({'duration_minutes': 0.5}),
        defaultMeetingDurationMinutes,
      );
    });
  });

  group('meetingCalendarSegments', () {
    test('does not create a continuation when a meeting ends at midnight', () {
      final segments = meetingCalendarSegments(
        DateTime(2026, 1, 10, 23, 0),
        60,
      );

      expect(segments, hasLength(1));
      expect(segments.single.day, DateTime(2026, 1, 10));
      expect(segments.single.end, DateTime(2026, 1, 10, 23, 59));
      expect(segments.single.continued, isFalse);
    });

    test('creates one segment for every occupied date', () {
      final segments = meetingCalendarSegments(
        DateTime(2026, 1, 10, 10, 0),
        2880,
      );

      expect(segments.map((s) => s.day), [
        DateTime(2026, 1, 10),
        DateTime(2026, 1, 11),
        DateTime(2026, 1, 12),
      ]);
      expect(segments.first.start, DateTime(2026, 1, 10, 10, 0));
      expect(segments[1].start, DateTime(2026, 1, 11));
      expect(segments.last.end, DateTime(2026, 1, 12, 10, 0));
      expect(segments.skip(1).every((s) => s.continued), isTrue);
    });
  });
}

