/// Mô hình hóa khung giờ học (TimeSlot)
/// Tuân thủ quy định:
/// - [dayOfWeek]: 2 (Thứ 2) -> 7 (Thứ 7), 8: Chủ Nhật
/// - [startPeriod]: Tiết bắt đầu (1 -> 12)
/// - [length]: Số tiết học liên tục
/// - [room]: Phòng học / Giảng đường / Phòng Lab
class TimeSlot {
  final int dayOfWeek; // 2 -> 7, 8: CN
  final int startPeriod; // 1 -> 12
  final int length; // Số tiết
  final String room;

  const TimeSlot({
    required this.dayOfWeek,
    required this.startPeriod,
    required this.length,
    required this.room,
  })  : assert(dayOfWeek >= 2 && dayOfWeek <= 8, 'dayOfWeek phải từ 2 đến 8'),
        assert(startPeriod >= 1 && startPeriod <= 12, 'startPeriod phải từ 1 đến 12'),
        assert(length >= 1 && length <= 6, 'length phải từ 1 đến 6');

  int get endPeriod => startPeriod + length - 1;

  /// Kiểm tra buổi học: Sáng (tiết 1-5), Chiều (tiết 6-10), Tối (tiết 11-12)
  bool get isMorning => startPeriod <= 5;
  bool get isAfternoon => startPeriod >= 6 && startPeriod <= 10;
  bool get isEvening => startPeriod >= 11;

  /// Kiểm tra xung đột thời gian giữa 2 khung giờ
  /// Trùng nhau khi cùng ngày và khoảng tiết giao nhau:
  /// !(endA < startB || endB < startA)
  bool conflictsWith(TimeSlot other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    final endA = endPeriod;
    final endB = other.endPeriod;
    return !(endA < other.startPeriod || endB < startPeriod);
  }

  String get dayName {
    switch (dayOfWeek) {
      case 2:
        return 'Thứ 2';
      case 3:
        return 'Thứ 3';
      case 4:
        return 'Thứ 4';
      case 5:
        return 'Thứ 5';
      case 6:
        return 'Thứ 6';
      case 7:
        return 'Thứ 7';
      case 8:
        return 'Chủ Nhật';
      default:
        return 'Thứ $dayOfWeek';
    }
  }

  String get periodString => 'Tiết $startPeriod-$endPeriod';

  String get periodTimeFormatted => estimatedTimeString;

  /// Giờ ước tính theo tiết học chuẩn ĐH Tây Nguyên
  String get estimatedTimeString {
    String getPeriodStartTime(int p) {
      switch (p) {
        case 1:
          return '07:00';
        case 2:
          return '07:50';
        case 3:
          return '08:50';
        case 4:
          return '09:40';
        case 5:
          return '10:30';
        case 6:
          return '13:00';
        case 7:
          return '13:50';
        case 8:
          return '14:50';
        case 9:
          return '15:40';
        case 10:
          return '16:30';
        case 11:
          return '17:30';
        case 12:
          return '18:20';
        default:
          return '07:00';
      }
    }

    String getPeriodEndTime(int p) {
      switch (p) {
        case 1:
          return '07:45';
        case 2:
          return '08:35';
        case 3:
          return '09:35';
        case 4:
          return '10:25';
        case 5:
          return '11:15';
        case 6:
          return '13:45';
        case 7:
          return '14:35';
        case 8:
          return '15:35';
        case 9:
          return '16:25';
        case 10:
          return '17:15';
        case 11:
          return '18:15';
        case 12:
          return '19:05';
        default:
          return '11:15';
      }
    }

    return '${getPeriodStartTime(startPeriod)} - ${getPeriodEndTime(endPeriod)}';
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startPeriod': startPeriod,
        'length': length,
        'room': room,
      };

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        dayOfWeek: json['dayOfWeek'] as int,
        startPeriod: json['startPeriod'] as int,
        length: json['length'] as int,
        room: json['room'] as String? ?? 'Chưa xếp phòng',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          dayOfWeek == other.dayOfWeek &&
          startPeriod == other.startPeriod &&
          length == other.length &&
          room == other.room;

  @override
  int get hashCode => Object.hash(dayOfWeek, startPeriod, length, room);
}
