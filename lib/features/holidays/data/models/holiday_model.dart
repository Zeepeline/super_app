import 'package:super_app/features/holidays/domain/entities/holiday_entity.dart';

class HolidayModel extends HolidayEntity {
  const HolidayModel({
    required super.date,
    required super.name,
    super.isNationalHoliday,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    // Format API Day-Off: {"tanggal": "2024-2-8", "keterangan": "Isra' Mi'raj...", "is_cuti": false}
    // Note: Tanggal bisa format YYYY-M-D, perlu diproses agar aman diparse DateTime
    final dateStr = json['tanggal'] as String;
    final parts = dateStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    
    return HolidayModel(
      date: DateTime(year, month, day),
      name: json['keterangan'] ?? '',
      isNationalHoliday: !(json['is_cuti'] ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal': "${date.year}-${date.month}-${date.day}",
      'keterangan': name,
      'is_cuti': !isNationalHoliday,
    };
  }
}
