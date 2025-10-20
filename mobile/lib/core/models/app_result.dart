/// Result type for handling success and error states in a type-safe way.
///
/// This provides a functional approach to error handling, avoiding exceptions
/// and making error states explicit in the type system.
library;

import 'package:equatable/equatable.dart';

/// Result wrapper that can be either Success or Failure
sealed class Result<T> extends Equatable {
  const Result();

  /// Returns true if this is a Success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a Failure result
  bool get isFailure => this is Failure<T>;

  /// Get the success value, or null if this is a failure
  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    Failure() => null,
  };

  /// Get the error, or null if this is a success
  AppError? get errorOrNull => switch (this) {
    Success() => null,
    Failure(error: final e) => e,
  };

  /// Transform the success value
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(value: final v) => Success(transform(v)),
      Failure(error: final e) => Failure(e),
    };
  }

  /// Execute a callback if this is a success
  Result<T> onSuccess(void Function(T value) callback) {
    if (this case Success(value: final v)) {
      callback(v);
    }
    return this;
  }

  /// Execute a callback if this is a failure
  Result<T> onFailure(void Function(AppError error) callback) {
    if (this case Failure(error: final e)) {
      callback(e);
    }
    return this;
  }

  @override
  List<Object?> get props => [];
}

/// Success result containing a value
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'Success($value)';
}

/// Failure result containing an error
final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];

  @override
  String toString() => 'Failure($error)';
}

/// Base error class for the application
sealed class AppError extends Equatable {
  const AppError({required this.message, this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// Network-related errors
final class NetworkError extends AppError {
  const NetworkError({required super.message, super.code, super.stackTrace});
}

/// Authentication errors
final class AuthError extends AppError {
  const AuthError({required super.message, super.code, super.stackTrace});
}

/// Database errors (Firestore)
final class DatabaseError extends AppError {
  const DatabaseError({required super.message, super.code, super.stackTrace});
}

/// Validation errors (user input, etc.)
final class ValidationError extends AppError {
  const ValidationError({required super.message, super.code, super.stackTrace});
}

/// Permission errors (location, notifications, etc.)
final class PermissionError extends AppError {
  const PermissionError({required super.message, super.code, super.stackTrace});
}

/// Generic/unknown errors
final class UnknownError extends AppError {
  const UnknownError({required super.message, super.code, super.stackTrace});
}

/// Not found errors
final class NotFoundError extends AppError {
  const NotFoundError({required super.message, super.code, super.stackTrace});
}
