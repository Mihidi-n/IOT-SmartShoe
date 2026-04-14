import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'bluetooth_service.dart';
import 'home_screen.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  final String userKey;

  /// When [showBackButton] is true the screen was opened from the dashboard
  /// (Navigator.push) — show a back arrow and "Back to Dashboard".
  /// When false it was opened right after login — use pushReplacement to
  /// go forward to HomeScreen.
  final bool showBackButton;

  const BluetoothConnectionScreen({
    super.key,
    required this.userKey,
    this.showBackButton = false,
  });

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState
    extends State<BluetoothConnectionScreen> {
  final ble = BluetoothService.instance;

  bool _isConnecting = false;
  String _statusMessage =
      "Tap the button below to connect to your Smart Shoe.";

  @override
  void initState() {
    super.initState();
    if (ble.isConnected) {
      _statusMessage = "Smart Shoe is connected!";
    }
  }

  Future<void> _connect() async {
    if (_isConnecting || ble.isConnected) return;

    setState(() {
      _isConnecting = true;
      _statusMessage = "Scanning for Smart Shoe...";
    });

    await ble.connectAndListen();

    // Poll up to 12 s for a connection result
    int elapsed = 0;
    const interval = 500;
    while (elapsed < 12000) {
      await Future.delayed(const Duration(milliseconds: interval));
      elapsed += interval;
      if (!mounted) return;
      if (ble.isConnected) {
        setState(() {
          _isConnecting = false;
          _statusMessage = "Smart Shoe is connected!";
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isConnecting = false;
      _statusMessage =
      "Could not find the Smart Shoe. Make sure it is powered on and nearby, then try again.";
    });
  }

  Future<void> _disconnect() async {
    await ble.disconnect();
    if (!mounted) return;
    setState(() {
      _statusMessage = "Disconnected from Smart Shoe.";
    });
  }

  void _proceed() {
    if (widget.showBackButton) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userKey: widget.userKey),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = ble.isConnected;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.main),
        child: SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                // ── Header row ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.showBackButton) ...[
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white38, width: 1.2),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bluetooth",
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          "Connection",
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Manage your Smart Shoe Bluetooth connection here.",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Central animated icon ────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected
                        ? Colors.green.withOpacity(0.18)
                        : Colors.white.withOpacity(0.10),
                    border: Border.all(
                      color: connected
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.3),
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      connected
                          ? Icons.bluetooth_connected_rounded
                          : Icons.bluetooth_rounded,
                      size: 76,
                      color: connected
                          ? Colors.greenAccent
                          : Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Status pill ──────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: connected
                        ? Colors.green.withOpacity(0.22)
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: connected
                          ? Colors.greenAccent.withOpacity(0.6)
                          : Colors.white.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isConnecting
                            ? const SizedBox(
                          key: ValueKey('spinner'),
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Icon(
                          key: const ValueKey('dot'),
                          Icons.circle,
                          size: 10,
                          color: connected
                              ? Colors.greenAccent
                              : Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        connected
                            ? "Connected"
                            : _isConnecting
                            ? "Connecting..."
                            : "Not Connected",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Status message ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Action buttons ───────────────────────────────────
                if (!connected) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isConnecting ? null : _connect,
                      icon: const Icon(
                          Icons.bluetooth_searching_rounded),
                      label: Text(
                        _isConnecting
                            ? "Searching..."
                            : "Connect to Shoe",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                        disabledBackgroundColor:
                        Colors.white.withOpacity(0.4),
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _proceed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Colors.white54, width: 1.2),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        widget.showBackButton
                            ? "Back to Dashboard"
                            : "Skip & Continue Without Shoe",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _proceed,
                      icon: Icon(widget.showBackButton
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded),
                      label: Text(
                        widget.showBackButton
                            ? "Back to Dashboard"
                            : "Go to Dashboard",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: AppColors.navy,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(
                          Icons.bluetooth_disabled_rounded,
                          size: 18),
                      label: Text(
                        "Disconnect",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(
                            color: Colors.white30, width: 1.2),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}