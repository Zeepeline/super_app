import '../models/auth_model.dart';
import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login(String email, String password);
}

class MockAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<AuthModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.contains('@') && password.length >= 6) {
      return AuthModel(id: 'u1', email: email, token: 'mock_jwt_token');
    } else {
      throw ServerException('Invalid credentials');
    }
  }
}
