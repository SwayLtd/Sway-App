import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway_events/features/auth/auth_event.dart';
import 'package:sway_events/features/auth/auth_state.dart' as auth_state;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(auth_state.AuthInitial() as AuthState) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileRequested>(_onProfileRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(auth_state.AuthLoading() as AuthState);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      if (response.session == null) {
        emit(const auth_state.AuthError('Login failed') as AuthState);
      } else {
        emit(auth_state.AuthAuthenticated(response.user!) as AuthState);
      }
    } catch (e) {
      emit(auth_state.AuthError(e.toString()) as AuthState);
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await Supabase.instance.client.auth.signOut();
    emit(auth_state.AuthUnauthenticated() as AuthState);
  }

  Future<void> _onProfileRequested(
    AuthProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      emit(auth_state.AuthAuthenticated(user) as AuthState);
    } else {
      emit(auth_state.AuthUnauthenticated() as AuthState);
    }
  }
}
