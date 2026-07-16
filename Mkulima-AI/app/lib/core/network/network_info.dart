import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over connectivity so data sources / repositories can decide
/// whether to hit the network or fall back to the local Isar/Hive cache.
///
/// This matters a lot for Mkulima AI specifically: farmers in rural Uganda
/// frequently have intermittent 2G/3G connectivity, so every feature
/// (weather, market prices, disease detection) needs an explicit
/// offline-first fallback rather than assuming connectivity.
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(_hasConnection);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
