import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rajyo_darpan_publisher/core/constants/app_colors.dart';
import 'package:rajyo_darpan_publisher/presentation/providers/auth_provider.dart';
import 'package:rajyo_darpan_publisher/presentation/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _urlController = TextEditingController(text: 'https://rajyodarpan.in/admin_rajyo');

  bool _otpSent = false;
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.newspaper_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'রাজ্য দর্পণ প্রকাশক',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _otpSent ? 'আপনার ইমেইলে প্রেরিত ৬ সংখ্যার ওটিপি লিখুন' : 'লগইন করতে আপনার প্যানেলের ইমেইল লিখুন',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Error Message
                if (auth.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Field
                TextField(
                  controller: _emailController,
                  enabled: !_otpSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'ইমেইল এড্রেস (Email)',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                // OTP Field (Shows after OTP is sent)
                if (_otpSent) ...[
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: const InputDecoration(
                      labelText: '৬-সংখ্যার ওটিপি কোড (OTP)',
                      hintText: '• • • • • •',
                      prefixIcon: Icon(Icons.pin_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _otpSent = false),
                        child: const Text('ইমেইল পরিবর্তন করুন'),
                      ),
                      TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                await auth.sendOtp(_emailController.text, customUrl: _urlController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('পুনরায় ওটিপি পাঠানো হয়েছে')),
                                );
                              },
                        child: const Text('পুনরায় ওটিপি পাঠান'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Advanced Server URL
                InkWell(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _showAdvanced ? 'সার্ভার সেটিংস লুকান' : 'সার্ভার সেটিংস',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Icon(
                          _showAdvanced ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showAdvanced) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'সার্ভার প্যানেল URL',
                      hintText: 'https://rajyodarpan.in/admin_rajyo',
                      prefixIcon: Icon(Icons.link, color: AppColors.textMuted),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Submit Button
                if (!_otpSent)
                  PrimaryButton(
                    text: 'ওটিপি কোড পাঠান (Send OTP)',
                    isLoading: auth.isLoading,
                    icon: Icons.send_rounded,
                    onPressed: () async {
                      if (_emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('অনুগ্রহ করে আপনার ইমেইল প্রদান করুন')),
                        );
                        return;
                      }

                      final success = await auth.sendOtp(
                        _emailController.text,
                        customUrl: _urlController.text,
                      );
                      if (success) {
                        setState(() => _otpSent = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('আপনার ইমেইলে ওটিপি পাঠানো হয়েছে')),
                        );
                      }
                    },
                  )
                else
                  PrimaryButton(
                    text: 'ওটিপি যাচাই করে লগইন করুন',
                    isLoading: auth.isLoading,
                    icon: Icons.login_rounded,
                    onPressed: () async {
                      if (_otpController.text.trim().length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('সঠিক ৬ সংখ্যার ওটিপি প্রদান করুন')),
                        );
                        return;
                      }

                      await auth.verifyOtp(
                        _emailController.text,
                        _otpController.text,
                      );
                    },
                  ),

                const SizedBox(height: 24),
                const Text(
                  'রাজ্য দর্পণ অফিসিয়াল পাবলিশার • OTP লগইন সিস্টেম',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
