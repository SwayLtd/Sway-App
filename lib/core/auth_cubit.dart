// lib/core/bloc/auth_cubit.dart

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class UserAuthState {
  final AuthStatus status;
  final User? user;

  UserAuthState({required this.status, this.user});

  factory UserAuthState.initial() => UserAuthState(status: AuthStatus.loading);
  factory UserAuthState.authenticated(User user) =>
      UserAuthState(status: AuthStatus.authenticated, user: user);
  factory UserAuthState.unauthenticated() =>
      UserAuthState(status: AuthStatus.unauthenticated);
}

class AuthCubit extends Cubit<UserAuthState> {
  final SupabaseClient supabase;

  late final StreamSubscription<AuthState> _authSubscription;

  AuthCubit({required this.supabase}) : super(UserAuthState.initial()) {
    _authSubscription =
        supabase.auth.onAuthStateChange.listen(_onAuthStateChange);
    _initialize();
  }

  Future<void> _initialize() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      emit(UserAuthState.authenticated(user));
    } else {
      try {
        await supabase.auth.signInAnonymously();
        final newUser = supabase.auth.currentUser;
        if (newUser != null) {
          emit(UserAuthState.authenticated(newUser));
        } else {
          emit(UserAuthState.unauthenticated());
        }
      } catch (e) {
        emit(UserAuthState.unauthenticated());
      }
    }
  }

  void _onAuthStateChange(AuthState authState) {
    if (authState.event == AuthChangeEvent.signedIn &&
        authState.session?.user != null) {
      emit(UserAuthState.authenticated(authState.session!.user));
    } else if (authState.event == AuthChangeEvent.signedOut) {
      emit(UserAuthState.unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
