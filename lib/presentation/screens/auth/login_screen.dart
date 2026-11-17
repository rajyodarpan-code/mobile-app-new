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
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpMode = false;
  bool _otpSent = false;
  bool _obscurePassword = true;

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
                  _isOtpMode
                      ? (_otpSent ? 'আপনার ইমেইলে প্রেরিত ৬ সংখ্যার ওটিপি লিখুন' : 'ওটিপি পেতে ইমেইল এড্রেস লিখুন')
                      : 'লগইন করতে আপনার প্যানেলের ইমেইল ও পাসওয়ার্ড লিখুন',
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

                // Password Mode
                if (!_isOtpMode) ...[
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'পাসওয়ার্ড (Password)',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'লগইন করুন',
                    isLoading: auth.isLoading,
                    icon: Icons.login_rounded,
                    onPressed: () async {
                      if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ইমেইল ও পাসওয়ার্ড প্রদান করুন')),
                        );
                        return;
                      }

                      await auth.login(
                        _emailController.text,
                        _passwordController.text,
                      );
                    },
                  ),
                ],

                // OTP Mode
                if (_isOtpMode) ...[
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
                    const SizedBox(height: 16),
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
                  ] else ...[
                    PrimaryButton(
                      text: 'ওটিপি কোড পাঠান (Send OTP)',
                      isLoading: auth.isLoading,
                      icon: Icons.send_rounded,
                      onPressed: () async {
                        if (_emailController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ইমেইল এড্রেস লিখুন')),
                          );
                          return;
                        }

                        final success = await auth.sendOtp(_emailController.text);
                        if (success) {
                          setState(() => _otpSent = true);
                        }
                      },
                    ),
                  ],
                ],

                const SizedBox(height: 16),

                // Switch between Password and OTP Login
                Center(
                  child: TextButton.icon(
                    icon: Icon(_isOtpMode ? Icons.lock_outline : Icons.mark_email_read_outlined, size: 18),
                    label: Text(_isOtpMode ? 'পাসওয়ার্ড দিয়ে লগইন করুন' : 'ইমেইল ওটিপি (OTP) দিয়ে লগইন করুন'),
                    onPressed: () {
                      setState(() {
                        _isOtpMode = !_isOtpMode;
                        _otpSent = false;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'রাজ্য দর্পণ অফিসিয়াল পাবলিশার • রাজযোগাযোগ ব্যবস্থা',
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
