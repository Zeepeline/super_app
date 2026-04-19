import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc({required this.loginUseCase}) : super(AuthInitial()) {
    on<LoginRequestedEvent>((event, emit) async {
      emit(AuthLoading());

      final result = await loginUseCase(LoginParams(
        email: event.email,
        password: event.password,
      ));

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(Authenticated(user)),
      );
    });

    on<LogoutRequestedEvent>((event, emit) {
      emit(Unauthenticated());
    });
  }
}
