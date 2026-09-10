import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Wraps the app and shows a thin "No internet connection" banner whenever
/// connectivity drops — required by the assignment's error-handling section.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted) setState(() => _offline = offline);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_offline)
          Container(
            width: double.infinity,
            color: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: const SafeArea(
              bottom: false,
              child: Text(
                'No internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
