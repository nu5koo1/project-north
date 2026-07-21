import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_north/core/theme/app_typography.dart';
import 'package:project_north/core/widgets/no_stretch_scroll_behavior.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.onSignUpPressed,
    this.onSignInPressed,
    this.onForgotPasswordPressed,
  });

  final VoidCallback? onSignUpPressed;

  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignInPressed;

  final Future<void> Function(String email)? onForgotPasswordPressed;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isSigningIn = false;
  bool _isSendingPasswordReset = false;

  bool get _isBusy {
    return _isSigningIn || _isSendingPasswordReset;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
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
      return 'Enter your password';
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

  void _resetSignInForm() {
    FocusScope.of(context).unfocus();

    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();

    setState(() {
      _formKey = GlobalKey<FormState>();
      _obscurePassword = true;
    });
  }

  void _handleSignUp() {
    if (_isBusy) {
      return;
    }

    _resetSignInForm();

    final callback = widget.onSignUpPressed;

    if (callback != null) {
      callback();
      return;
    }

    _showMessage('Create account screen is unavailable.');
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isBusy) {
      return;
    }

    final callback = widget.onSignInPressed;

    if (callback == null) {
      _showMessage('Sign in is unavailable.');
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      await callback(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();

    if (_isBusy) {
      return;
    }

    final emailError = _validateEmail(_emailController.text);

    if (emailError != null) {
      _formKey.currentState?.validate();
      _showMessage('Enter your email first.');
      return;
    }

    final callback = widget.onForgotPasswordPressed;

    if (callback == null) {
      _showMessage('Password recovery is unavailable.');
      return;
    }

    setState(() {
      _isSendingPasswordReset = true;
    });

    try {
      await callback(_emailController.text.trim());

      if (!mounted) {
        return;
      }

      _showMessage('Password reset email sent. Check your inbox.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSendingPasswordReset = false;
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
          const _WelcomeBackground(),
          const _WelcomeOverlay(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _AuthLayout.fromConstraints(constraints);

                return ScrollConfiguration(
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
                        child: Column(
                          children: [
                            SizedBox(height: layout.topSpacing),
                            _AuthBrand(
                              logoHeight: layout.logoHeight,
                              logoScale: layout.logoScale,
                              subtitleOffset: layout.subtitleOffset,
                            ),
                            const Spacer(),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Form(
                                key: _formKey,
                                child: _AuthenticationForm(
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  emailFocusNode: _emailFocusNode,
                                  passwordFocusNode: _passwordFocusNode,
                                  obscurePassword: _obscurePassword,
                                  fieldSpacing: layout.fieldSpacing,
                                  buttonSpacing: layout.buttonSpacing,
                                  isSigningIn: _isSigningIn,
                                  isSendingPasswordReset:
                                      _isSendingPasswordReset,
                                  validateEmail: _validateEmail,
                                  validatePassword: _validatePassword,
                                  onPasswordVisibilityPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  onSignUpPressed: _handleSignUp,
                                  onSignInPressed: _handleSignIn,
                                  onForgotPasswordPressed:
                                      _handleForgotPassword,
                                ),
                              ),
                            ),
                            SizedBox(height: layout.formBottomSpacing),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLayout {
  const _AuthLayout({
    required this.horizontalPadding,
    required this.topSpacing,
    required this.logoHeight,
    required this.logoScale,
    required this.subtitleOffset,
    required this.fieldSpacing,
    required this.buttonSpacing,
    required this.formBottomSpacing,
    required this.bottomPadding,
  });

  final double horizontalPadding;
  final double topSpacing;
  final double logoHeight;
  final double logoScale;
  final double subtitleOffset;
  final double fieldSpacing;
  final double buttonSpacing;
  final double formBottomSpacing;
  final double bottomPadding;

  factory _AuthLayout.fromConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    final isShortScreen = height < 720;
    final isCompactScreen = height < 820;

    return _AuthLayout(
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
      fieldSpacing: isShortScreen ? 10 : 20,
      buttonSpacing: isShortScreen ? 16 : 26,
      formBottomSpacing: isShortScreen
          ? 6
          : isCompactScreen
          ? 10
          : 20,
      bottomPadding: isShortScreen ? 8 : 12,
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

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

class _WelcomeOverlay extends StatelessWidget {
  const _WelcomeOverlay();

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

class _AuthBrand extends StatelessWidget {
  const _AuthBrand({
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
            'STAY WILD',
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

class _AuthenticationForm extends StatelessWidget {
  const _AuthenticationForm({
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.fieldSpacing,
    required this.buttonSpacing,
    required this.isSigningIn,
    required this.isSendingPasswordReset,
    required this.validateEmail,
    required this.validatePassword,
    required this.onPasswordVisibilityPressed,
    required this.onSignUpPressed,
    required this.onSignInPressed,
    required this.onForgotPasswordPressed,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;

  final bool obscurePassword;
  final double fieldSpacing;
  final double buttonSpacing;
  final bool isSigningIn;
  final bool isSendingPasswordReset;

  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;

  final VoidCallback onPasswordVisibilityPressed;
  final VoidCallback onSignUpPressed;
  final VoidCallback onSignInPressed;
  final VoidCallback onForgotPasswordPressed;

  bool get _isBusy {
    return isSigningIn || isSendingPasswordReset;
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        children: [
          _AuthTextField(
            controller: emailController,
            focusNode: emailFocusNode,
            hintText: 'Email',
            icon: Icons.mail_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: validateEmail,
            enabled: !_isBusy,
            onSubmitted: (_) {
              passwordFocusNode.requestFocus();
            },
          ),
          SizedBox(height: fieldSpacing),
          _AuthTextField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            hintText: 'Password',
            icon: Icons.lock_rounded,
            keyboardType: TextInputType.visiblePassword,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: validatePassword,
            enabled: !_isBusy,
            onSubmitted: (_) {
              onSignInPressed();
            },
            trailing: IconButton(
              onPressed: _isBusy ? null : onPasswordVisibilityPressed,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(height: buttonSpacing),
          Row(
            children: [
              Expanded(
                child: _OutlinedAuthButton(
                  label: 'Sign up',
                  onPressed: _isBusy ? null : onSignUpPressed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OutlinedAuthButton(
                  label: 'Sign in',
                  onPressed: _isBusy ? null : onSignInPressed,
                  isLoading: isSigningIn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isBusy ? null : onForgotPasswordPressed,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: isSendingPasswordReset
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Forgot Password?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    required this.keyboardType,
    required this.textInputAction,
    required this.autofillHints,
    required this.validator,
    required this.enabled,
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
  final Iterable<String> autofillHints;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final bool obscureText;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.8),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
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

class _OutlinedAuthButton extends StatelessWidget {
  const _OutlinedAuthButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
          backgroundColor: Colors.black.withValues(alpha: 0.05),
          side: BorderSide(
            color: Colors.white.withValues(alpha: onPressed == null ? 0.45 : 1),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
