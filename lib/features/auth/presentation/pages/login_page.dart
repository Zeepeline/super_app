import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stack(
          children: [
            // Mesh Background with Radial Gradients
            Positioned.fill(
              child: Stack(
                children: [
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF1CB853).withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    right: -100,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF72FE8F).withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 40.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBrandHeader(context),
                      const SizedBox(height: 48),
                      _buildLoginCard(context),
                      const SizedBox(height: 32),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.kPrimaryContainerColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.kPrimaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(Icons.graphic_eq, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'OBSIDIAN RHYTHM',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Experience the Digital Curator',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.kOnSurfaceVariantColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Please enter your details to continue',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.kOnSurfaceVariantColor,
                  ),
                ),
                const SizedBox(height: 40),
                _buildFieldLabel(context, 'EMAIL ADDRESS'),
                const SizedBox(height: 12),
                _buildTextField(
                  context,
                  controller: _emailController,
                  hint: 'curator@rhythm.io',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel(context, 'PASSWORD'),
                    const Text(
                      'FORGOT PASSWORD?',
                      style: TextStyle(
                        color: AppTheme.kPrimaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  context,
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  isObscure: true,
                ),
                const SizedBox(height: 40),
                _buildSubmitButton(context),
                const SizedBox(height: 32),
                _buildDivider(context),
                const SizedBox(height: 32),
                _buildSocialLogins(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
        color: AppTheme.kOnSurfaceVariantColor,
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerLowColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.kOnSurfaceVariantColor.withValues(alpha: 0.3),
          ),
          prefixIcon: Icon(
            icon,
            color: AppTheme.kOnSurfaceVariantColor,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: state is AuthLoading
              ? null
              : () {
                  context.read<AuthBloc>().add(
                    LoginRequestedEvent(
                      email: _emailController.text,
                      password: _passwordController.text,
                    ),
                  );
                },
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.kPrimaryColor,
                  AppTheme.kPrimaryContainerColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kPrimaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                state is AuthLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                const SizedBox(width: 8),
                if (state is! AuthLoading)
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.black,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppTheme.kOnSurfaceVariantColor.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildSocialLogins(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            context,
            label: 'Google',
            iconUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCQdA-7UrAVbpSccLMACZfnu2FjP1YNnP1j8xeYmVXW5nPAcvVtzTpURCCCit5vGFa3OeaQi0w4tebzH52tfcR4aXz9Fr4RoKT9bCkaHlRZu1xQyR345bKQkHKDIHzDmqVyq6Zb9XRmrfhrJrkDhyOOQbuLHzibRUAZKR9usmL0xWi3WOPrQjLVW3tYKZUzKGmLsOxSGNB_eq3eLLuz9pjrCHTU8eRCe1Cz_E9qrpumRTaGQb2nS6yQEY7MV02_qF-IN1XHsI8wtJA',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSocialButton(
            context,
            label: 'Apple',
            iconData: FontAwesomeIcons.apple,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required String label,
    String? iconUrl,
    IconData? iconData,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconUrl != null)
            Image.network(iconUrl, width: 20, height: 20)
          else if (iconData != null)
            FaIcon(iconData, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: AppTheme.kOnSurfaceVariantColor,
            fontSize: 13,
          ),
        ),
        Text(
          'Sign Up',
          style: TextStyle(
            color: AppTheme.kPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}
