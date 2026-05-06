import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<DashboardModel> getDashboardData() async {
    try {
      final response = await dio.get(
        'https://api.sonic-superapp.com/v1/dashboard',
        // In a real app, you would add headers like Authorization here
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return DashboardModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Failed to load dashboard data: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // The server responded with a non-2xx status code
        throw ServerException(
          e.response?.data['message'] ?? 'Server error occurred',
        );
      } else {
        // Something happened in setting up or sending the request
        throw ServerException('Connection error: ${e.message}');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
