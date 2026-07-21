// lib/features/authentication/presentation/screens/sign_up_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_north/core/theme/app_typography.dart';
import 'package:project_north/core/widgets/no_stretch_scroll_behavior.dart';

class SignUpResult {
  const SignUpResult({
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.onAccountCreated});

  final Future<void> Function(SignUpResult result) onAccountCreated;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Enter your full name';
    }

    if (name.length < 2) {
      return 'Name is too short';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Enter your email';
    }

    final emailPattern = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Enter a password';
    }

    if (password.length < 6) {
      return 'Use at least 6 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmation = value ?? '';

    if (confirmation.isEmpty) {
      return 'Confirm your password';
    }

    if (confirmation != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onAccountCreated(
        SignUpResult(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardBottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF040617),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SignUpBackground(),
          const _SignUpOverlay(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _SignUpLayout.fromConstraints(constraints);

                return Stack(
                  children: [
                    ScrollConfiguration(
                      behavior: const NoStretchScrollBehavior(),
                      child: SingleChildScrollView(
                        physics: isKeyboardOpen
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          layout.horizontalPadding,
                          0,
                          layout.horizontalPadding,
                          isKeyboardOpen
                              ? keyboardBottom + layout.bottomPadding
                              : 0,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  SizedBox(height: layout.topSpacing),
                                  _SignUpBrand(
                                    logoHeight: layout.logoHeight,
                                    logoScale: layout.logoScale,
                                    subtitleOffset: layout.subtitleOffset,
                                  ),
                                  const Spacer(),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 480,
                                    ),
                                    child: Column(
                                      children: [
                                        _SignUpForm(
                                          nameController: _nameController,
                                          emailController: _emailController,
                                          passwordController:
                                              _passwordController,
                                          confirmPasswordController:
                                              _confirmPasswordController,
                                          nameFocusNode: _nameFocusNode,
                                          emailFocusNode: _emailFocusNode,
                                          passwordFocusNode: _passwordFocusNode,
                                          confirmPasswordFocusNode:
                                              _confirmPasswordFocusNode,
                                          obscurePassword: _obscurePassword,
                                          obscureConfirmPassword:
                                              _obscureConfirmPassword,
                                          isSubmitting: _isSubmitting,
                                          fieldSpacing: layout.fieldSpacing,
                                          validateName: _validateName,
                                          validateEmail: _validateEmail,
                                          validatePassword: _validatePassword,
                                          validateConfirmPassword:
                                              _validateConfirmPassword,
                                          onPasswordVisibilityPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          onConfirmPasswordVisibilityPressed:
                                              () {
                                                setState(() {
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword;
                                                });
                                              },
                                          onCreateAccountPressed:
                                              _createAccount,
                                        ),
                                        SizedBox(
                                          height: layout.signInLinkSpacing,
                                        ),
                                        _SignInLink(
                                          onPressed: _isSubmitting
                                              ? null
                                              : () {
                                                  Navigator.of(
                                                    context,
                                                  ).maybePop();
                                                },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: layout.formBottomSpacing),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 16,
                      child: _BackButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                Navigator.of(context).maybePop();
                              },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpLayout {
  const _SignUpLayout({
    required this.horizontalPadding,
    required this.topSpacing,
    required this.logoHeight,
    required this.logoScale,
    required this.subtitleOffset,
    required this.fieldSpacing,
    required this.signInLinkSpacing,
    required this.formBottomSpacing,
    required this.bottomPadding,
  });

  final double horizontalPadding;
  final double topSpacing;
  final double logoHeight;
  final double logoScale;
  final double subtitleOffset;
  final double fieldSpacing;
  final double signInLinkSpacing;
  final double formBottomSpacing;
  final double bottomPadding;

  factory _SignUpLayout.fromConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    final isShortScreen = height < 720;
    final isCompactScreen = height < 820;

    return _SignUpLayout(
      horizontalPadding: (width * 0.07).clamp(20.0, 36.0).toDouble(),
      topSpacing: isShortScreen
          ? 8
          : isCompactScreen
          ? 16
          : 50,
      logoHeight: (height * 0.32).clamp(240.0, 320.0).toDouble(),
      logoScale: width < 320
          ? 1.42
          : width > 520
          ? 1.48
          : 1.58,
      subtitleOffset: isShortScreen ? -18 : -24,
      fieldSpacing: isShortScreen ? 6 : 12,
      signInLinkSpacing: 4,
      formBottomSpacing: isShortScreen
          ? 0
          : isCompactScreen
          ? 2
          : 4,
      bottomPadding: isShortScreen ? 8 : 12,
    );
  }
}

class _SignUpBackground extends StatelessWidget {
  const _SignUpBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/welcome_camp_background.jpg',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.high,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF102B43),
                    Color(0xFF0A1D32),
                    Color(0xFF07101D),
                    Color(0xFF040617),
                  ],
                ),
              ),
            );
          },
    );
  }
}

class _SignUpOverlay extends StatelessWidget {
  const _SignUpOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x11000000),
            Color(0x22000000),
            Color(0x7710182B),
            Color(0xDD040617),
            Color(0xFF040617),
          ],
          stops: [0, 0.34, 0.58, 0.82, 1],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
        backgroundColor: Colors.black.withValues(alpha: 0.20),
        side: BorderSide(
          color: Colors.white.withValues(
            alpha: onPressed == null ? 0.30 : 0.65,
          ),
        ),
      ),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}

class _SignUpBrand extends StatelessWidget {
  const _SignUpBrand({
    required this.logoHeight,
    required this.logoScale,
    required this.subtitleOffset,
  });

  final double logoHeight;
  final double logoScale;
  final double subtitleOffset;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        SizedBox(
          width: screenWidth,
          height: logoHeight,
          child: Transform.scale(
            scale: logoScale,
            child: Image.asset(
              'assets/images/project_north_welcome_logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return Center(
                      child: Text(
                        'PROJECT\nNORTH',
                        textAlign: TextAlign.center,
                        style: AppTypography.heading1.copyWith(
                          color: Colors.white,
                          fontSize: 66,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                          height: 0.88,
                        ),
                      ),
                    );
                  },
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, subtitleOffset),
          child: Text(
            'LIVE THE ADVENTURE',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.6,
              height: -1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nameFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isSubmitting,
    required this.fieldSpacing,
    required this.validateName,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateConfirmPassword,
    required this.onPasswordVisibilityPressed,
    required this.onConfirmPasswordVisibilityPressed,
    required this.onCreateAccountPressed,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final FocusNode nameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;

  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isSubmitting;
  final double fieldSpacing;

  final FormFieldValidator<String> validateName;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateConfirmPassword;

  final VoidCallback onPasswordVisibilityPressed;
  final VoidCallback onConfirmPasswordVisibilityPressed;
  final VoidCallback onCreateAccountPressed;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        children: [
          _SignUpTextField(
            controller: nameController,
            focusNode: nameFocusNode,
            hintText: 'Full name',
            icon: Icons.person_rounded,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: validateName,
            autofillHints: const [AutofillHints.name],
            onSubmitted: (_) {
              emailFocusNode.requestFocus();
            },
          ),
          SizedBox(height: fieldSpacing),
          _SignUpTextField(
            controller: emailController,
            focusNode: emailFocusNode,
            hintText: 'Email',
            icon: Icons.mail_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: validateEmail,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) {
              passwordFocusNode.requestFocus();
            },
          ),
          SizedBox(height: fieldSpacing),
          _SignUpTextField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            hintText: 'Password',
            icon: Icons.lock_rounded,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            obscureText: obscurePassword,
            validator: validatePassword,
            autofillHints: const [AutofillHints.newPassword],
            trailing: IconButton(
              onPressed: isSubmitting ? null : onPasswordVisibilityPressed,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onSubmitted: (_) {
              confirmPasswordFocusNode.requestFocus();
            },
          ),
          SizedBox(height: fieldSpacing),
          _SignUpTextField(
            controller: confirmPasswordController,
            focusNode: confirmPasswordFocusNode,
            hintText: 'Confirm password',
            icon: Icons.verified_user_rounded,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            obscureText: obscureConfirmPassword,
            validator: validateConfirmPassword,
            autofillHints: const [AutofillHints.newPassword],
            trailing: IconButton(
              onPressed: isSubmitting
                  ? null
                  : onConfirmPasswordVisibilityPressed,
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onSubmitted: (_) {
              if (!isSubmitting) {
                onCreateAccountPressed();
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: isSubmitting ? null : onCreateAccountPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.55),
                backgroundColor: Colors.black.withValues(alpha: 0.05),
                side: BorderSide(
                  color: Colors.white.withValues(
                    alpha: isSubmitting ? 0.45 : 1,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpTextField extends StatelessWidget {
  const _SignUpTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    required this.keyboardType,
    required this.textInputAction,
    required this.validator,
    required this.autofillHints,
    this.obscureText = false,
    this.trailing,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String> validator;
  final Iterable<String> autofillHints;
  final bool obscureText;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      enabled: true,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      cursorColor: Colors.white,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFFB4B4),
          fontSize: 11,
          height: 1,
        ),
        prefixIcon: Icon(icon, color: Colors.white, size: 23),
        suffixIcon: trailing,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.8),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFFB4B4)),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFFB4B4), width: 1.8),
        ),
      ),
    );
  }
}

class _SignInLink extends StatelessWidget {
  const _SignInLink({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
          ),
          child: const Text(
            'Sign in',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
