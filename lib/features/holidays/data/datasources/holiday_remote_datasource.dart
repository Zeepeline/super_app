import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/holiday_model.dart';

abstract class HolidayRemoteDataSource {
  Future<List<HolidayModel>> getHolidays(int year);
}

class HolidayRemoteDataSourceImpl implements HolidayRemoteDataSource {
  final Dio dio;

  HolidayRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<HolidayModel>> getHolidays(int year) async {
    try {
      // Using Day-Off API which is comprehensive for Indonesian holidays (SKB 3 Menteri)
      final response = await dio.get(
        'https://day-off-api.vercel.app/api',
        queryParameters: {'year': year},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => HolidayModel.fromJson(json)).toList();
      } else {
        throw ServerException();
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw TimeoutException(e.message);
      }
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }
}
