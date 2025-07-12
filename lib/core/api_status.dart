enum ApiStatus {
  initial,
  success,
  error,
  loading,
  empty,
}

extension ApiStatusX on ApiStatus {
  bool get isInitial => this == ApiStatus.initial;
  bool get isSuccess => this == ApiStatus.success;
  bool get isError => this == ApiStatus.error;
  bool get isLoading => this == ApiStatus.loading;
}