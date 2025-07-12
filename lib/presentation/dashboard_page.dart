import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:totpfy/core/totp/totp_service_impl.dart';
import 'package:totpfy/providers/dashboard_provider.dart';
import '../common/widgets/otp_card.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadOtpEntries();
    });
  }

  Future<void> loadOtpEntries() async {
    context.read<DashboardProvider>().loadOtpEntries();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? TotpfyTheme.surfaceDark : TotpfyTheme.lightGray,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? TotpfyTheme.surfaceDark : TotpfyTheme.surfaceWhite,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Totpfy',
                style: TextStyle(
                  color: isDark ? TotpfyTheme.surfaceWhite : TotpfyTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            TotpfyTheme.surfaceDark,
                            TotpfyTheme.surfaceDark.withOpacity(0.8),
                          ]
                        : [
                            TotpfyTheme.surfaceWhite,
                            TotpfyTheme.lightGray,
                          ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/qr-scanner');
                },
                icon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: isDark ? TotpfyTheme.surfaceWhite : TotpfyTheme.primaryBlue,
                  size: 28,
                ),
                tooltip: 'Scan QR Code',
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // Stats Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TotpfyTheme.primaryBlue,
                    TotpfyTheme.secondaryBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: TotpfyTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<DashboardProvider>(
                          builder: (context, provider, child) {
                            return Text(
                              '${provider.otpEntriesCount}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: TotpfyTheme.surfaceWhite,
                              ),
                            );
                          },
                        ),
                        const Text(
                          'Active Accounts',
                          style: TextStyle(
                            fontSize: 16,
                            color: TotpfyTheme.surfaceWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TotpfyTheme.surfaceWhite.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: TotpfyTheme.surfaceWhite,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.key_rounded,
                    color: TotpfyTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your OTP Codes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? TotpfyTheme.surfaceWhite : TotpfyTheme.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              if(provider.otpEntries.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text('No OTP codes found. Scan a QR code to add one.',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? TotpfyTheme.surfaceWhite : TotpfyTheme.darkGray,
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: provider.otpEntries.length,
                  (context, index) {
                    final entry = provider.otpEntries.entries.toList()[index];
                    final issuer = entry.key;
                    final valuePair = entry.value.split(':');
                    final secretKey = valuePair.first;
                    final username = valuePair.last;
                    return OtpCard(
                      secretKey: secretKey,
                      totpService: TotpServiceImpl(),
                      issuer: issuer,
                      accountName: username,
                      onTap: () {
                        
                      },
                      onCopy: (String otpValue) async {
                        await Clipboard.setData(ClipboardData(text: otpValue));
                      },
                      onDelete: () async {
                        await SecureStorageService().deleteSecretKey(issuer: entry.key);
                        loadOtpEntries();
                      },
                    );
                  },
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
