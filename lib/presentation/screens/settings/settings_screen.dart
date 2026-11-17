import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/article_provider.dart';
import '../widgets/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isTesting = false;
  String? _wpStatus;
  String? _backendStatus;

  Future<void> _testConnections() async {
    setState(() {
      _isTesting = true;
      _wpStatus = 'যাচাই করা হচ্ছে...';
      _backendStatus = 'যাচাই করা হচ্ছে...';
    });

    try {
      // 1. Backend ping via auth/user
      await _apiClient.get(ApiConstants.user);
      _backendStatus = 'সংযুক্ত (Online)';
    } catch (_) {
      _backendStatus = 'সংযোগ বিচ্ছিন্ন (Offline)';
    }

    try {
      // 2. WP status
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      final wpPlatform = articleProvider.selectedPlatform;
      if (wpPlatform != null) {
        final res = await _apiClient.get(ApiConstants.platformStatus(wpPlatform.id));
        if (res != null && res['data'] != null && res['data']['connected'] == true) {
          _wpStatus = 'সংযুক্ত (Connected)';
        } else {
          _wpStatus = 'কানেকশন সমস্যা';
        }
      } else {
        _wpStatus = 'প্লাটফর্ম পাওয়া যায়নি';
      }
    } catch (_) {
      _wpStatus = 'কানেকশন এরর';
    }

    setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিংস ও প্রোফাইল', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'ব্যবহারকারী',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          if (user?.role != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user!.role!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connection Diagnostic
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('কানেকশন ডায়াগনস্টিকস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.dns_outlined, color: AppColors.primary),
                      title: const Text('লারাভেল ব্যাকএন্ড সার্ভার'),
                      subtitle: Text(_backendStatus ?? 'চেক করতে নিচের বাটনে চাপ দিন'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                      title: const Text('ওয়ার্ডপ্রেস ওয়েবসাইট (rajyodarpan.in)'),
                      subtitle: Text(_wpStatus ?? 'চেক করতে নিচের বাটনে চাপ দিন'),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: 'সার্ভার ও সাইট কানেকশন টেস্ট করুন',
                      isOutlined: true,
                      isLoading: _isTesting,
                      icon: Icons.network_check_rounded,
                      onPressed: _testConnections,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Info
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
                    title: Text('অ্যাপ সংস্করণ'),
                    trailing: Text('v1.0.0 (Build 1)'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security, color: AppColors.textSecondary),
                    title: const Text('এনক্রিপশন ও সিকিউরিটি'),
                    subtitle: const Text('AES-256 Token Storage Enabled'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout
            PrimaryButton(
              text: 'লগআউট করুন',
              color: AppColors.danger,
              icon: Icons.logout_rounded,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('লগআউট নিশ্চিতকরণ'),
                    content: const Text('আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('না')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        onPressed: () {
                          Navigator.pop(context);
                          auth.logout();
                        },
                        child: const Text('হ্যাঁ, লগআউট'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
