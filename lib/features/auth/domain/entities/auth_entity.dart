import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String id;
  final String email;
  final String token;

  const AuthEntity({
    required this.id,
    required this.email,
    required this.token,
  });

  @override
  List<Object?> get props => [id, email, token];
}
