import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:totpfy/core/totp/totp_service.dart';
import '../../core/theme.dart';

class OtpCard extends StatefulWidget {
  final String issuer;
  final String accountName;
  final String secretKey;
  final VoidCallback? onTap;
  final Function(String)? onCopy;
  final VoidCallback? onDelete;
  final TotpService totpService;

  const OtpCard({
    super.key,
    required this.issuer,
    required this.accountName,
    required this.secretKey,
    this.onTap,
    this.onCopy,
    this.onDelete,
    required this.totpService,
  });

  @override
  State<OtpCard> createState() => _OtpCardState();
}

class _OtpCardState extends State<OtpCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  // OTP and timer state
  String _currentOtp = '';
  int _timeRemaining = 30;
  Timer? _timer;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize OTP and start timer
    _generateOtp();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _generateOtp() async {
    try {
      final otp = await widget.totpService.generateOtp(secretKey: widget.secretKey);
      setState(() {
        _currentOtp = otp;
        _timeRemaining = 30;
        _isExpired = false;
      });
    } catch (e) {
      setState(() {
        _currentOtp = 'ERROR';
        _isExpired = true;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _generateOtp(); // Generate new OTP when time expires
        }
      });
    });
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _copyOtp() {
    Clipboard.setData(ClipboardData(text: _currentOtp));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('OTP copied to clipboard'),
        backgroundColor: TotpfyTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
    widget.onCopy?.call(_currentOtp);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isExpired
                      ? [
                          isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          isDark ? Colors.grey[700]! : Colors.grey[200]!,
                        ]
                      : [
                          isDark ? TotpfyTheme.surfaceDark : TotpfyTheme.surfaceWhite,
                          isDark 
                              ? TotpfyTheme.surfaceDark.withOpacity(0.8)
                              : TotpfyTheme.lightGray,
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: TotpfyTheme.primaryBlue.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: TotpfyTheme.primaryBlue.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: _isExpired
                      ? Colors.grey.withOpacity(0.3)
                      : TotpfyTheme.primaryBlue.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with issuer and actions
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.issuer,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _isExpired
                                          ? Colors.grey[600]
                                          : isDark
                                              ? TotpfyTheme.surfaceWhite
                                              : TotpfyTheme.darkGray,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (widget.accountName.isNotEmpty)
                                    Text(
                                      widget.accountName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _isExpired
                                            ? Colors.grey[500]
                                            : TotpfyTheme.neutralGray,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Action buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Copy button
                                IconButton(
                                  onPressed: _isExpired ? null : _copyOtp,
                                  icon: Icon(
                                    Icons.copy_rounded,
                                    size: 20,
                                    color: _isExpired
                                        ? Colors.grey[500]
                                        : TotpfyTheme.primaryBlue,
                                  ),
                                  tooltip: 'Copy OTP',
                                  style: IconButton.styleFrom(
                                    backgroundColor: _isExpired
                                        ? Colors.grey[200]
                                        : TotpfyTheme.primaryBlue.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Delete button
                                if (widget.onDelete != null)
                                  IconButton(
                                    onPressed: widget.onDelete,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: TotpfyTheme.errorRed,
                                    ),
                                    tooltip: 'Delete',
                                    style: IconButton.styleFrom(
                                      backgroundColor: TotpfyTheme.errorRed.withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // OTP Display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: _isExpired
                                ? Colors.grey[100]
                                : isDark
                                    ? TotpfyTheme.surfaceDark.withOpacity(0.5)
                                    : TotpfyTheme.lightGray,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isExpired
                                  ? Colors.grey[300]!
                                  : TotpfyTheme.primaryBlue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _currentOtp,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  letterSpacing: 4,
                                  color: _isExpired
                                      ? Colors.grey[600]
                                      : isDark
                                          ? TotpfyTheme.surfaceWhite
                                          : TotpfyTheme.darkGray,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Time remaining indicator
                              if (!_isExpired)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: TotpfyTheme.neutralGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_timeRemaining}s',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: TotpfyTheme.neutralGray,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer_off_outlined,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Expired',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Progress bar for time remaining
                        if (!_isExpired)
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _timeRemaining / 30, // 30-second intervals
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      TotpfyTheme.successGreen,
                                      TotpfyTheme.warningOrange,
                                      TotpfyTheme.errorRed,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}