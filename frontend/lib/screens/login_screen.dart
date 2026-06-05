import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'chat_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _emailSignIn() async {
    setState(() => _isLoading = true);
    try {
      final AuthResponse response =
          await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (response.user != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(username: response.user?.email ?? 'User'),
          ),
        );
      } else {
        throw 'Invalid credentials';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        await Supabase.instance.client.auth
            .signInWithOAuth(OAuthProvider.google);
        return;
      }
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '1014929119340-219om093r2p6od1sjofcd9fghi84af7c.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw 'Google sign in aborted';
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      if (accessToken == null || idToken == null) throw 'No Access Token found';
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(username: googleUser.email)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google Sign-In Error: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _facebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        await Supabase.instance.client.auth
            .signInWithOAuth(OAuthProvider.facebook);
        return;
      }
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AuthResponse response =
            await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.facebook,
          idToken: result.accessToken!.tokenString,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(username: response.user?.email ?? 'facebook_user'),
          ),
        );
      } else {
        throw result.message ?? 'Facebook login failed';
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Facebook Sign-In Error: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBrandMark({double logoSize = 40, double fontSize = 22}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
    final textSecondary =
        isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C6EF8), Color(0xFF4ECDC4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(logoSize * 0.28),
          ),
          child: Center(
            child: Text(
              'P',
              style: GoogleFonts.plusJakartaSans(
                fontSize: logoSize * 0.52,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PsyBuddy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              'Mental Wellness',
              style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0D0D12) : const Color(0xFFF8F8FD);
    final surfaceVar =
        isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF0F0F8);
    final borderColor =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE4E4EF);
    final textPrimary =
        isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0D0D12);
    final textSecondary =
        isDark ? const Color(0xFF8B8BA7) : const Color(0xFF6B6B85);
    final textTertiary =
        isDark ? const Color(0xFF5A5A72) : const Color(0xFF9898B0);
    final primary =
        isDark ? const Color(0xFF7C6EF8) : const Color(0xFF6B5EE8);

    return Container(
      color: isDesktop ? (isDark ? const Color(0xFF16161F) : Colors.white) : bgColor,
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48 : 28, vertical: isDesktop ? 0 : 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 48 : 0,
                horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isDesktop) ...[
                  const SizedBox(height: 64),
                  _buildBrandMark(),
                  const SizedBox(height: 48),
                ],
                Text(
                  'Welcome back',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your journey',
                  style: GoogleFonts.inter(fontSize: 15, color: textSecondary),
                ),
                const SizedBox(height: 40),
                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(fontSize: 15, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.inter(
                        fontSize: 14, color: textSecondary),
                    filled: true,
                    fillColor: surfaceVar,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 1.5)),
                    prefixIcon:
                        Icon(Icons.mail_outline, color: textTertiary, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.inter(fontSize: 15, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.inter(
                        fontSize: 14, color: textSecondary),
                    filled: true,
                    fillColor: surfaceVar,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 1.5)),
                    prefixIcon:
                        Icon(Icons.lock_outline, color: textTertiary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: textTertiary,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onSubmitted: (_) => _emailSignIn(),
                ),
                const SizedBox(height: 32),
                // Sign in button
                GestureDetector(
                  onTap: _isLoading ? null : _emailSignIn,
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C6EF8), Color(0xFF5B8AF5), Color(0xFF4ECDC4)],
                      ),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'Sign In',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Divider(color: borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or continue with',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: textTertiary)),
                  ),
                  Expanded(child: Divider(color: borderColor)),
                ]),
                const SizedBox(height: 24),
                // Social buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _googleSignIn,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: borderColor),
                          backgroundColor: isDark
                              ? const Color(0xFF1E1E2A)
                              : Colors.white,
                        ),
                        icon: const Icon(Icons.g_mobiledata,
                            size: 24, color: Color(0xFFEA4335)),
                        label: Text('Google',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _facebookSignIn,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: borderColor),
                          backgroundColor: isDark
                              ? const Color(0xFF1E1E2A)
                              : Colors.white,
                        ),
                        icon: const Icon(Icons.facebook,
                            size: 22, color: Color(0xFF1877F2)),
                        label: Text('Facebook',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: GoogleFonts.inter(
                            fontSize: 14, color: textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0D0D12) : const Color(0xFFF8F8FD);

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          if (isDesktop) {
            return Row(
              children: [
                // Left branding panel
                Flexible(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C6EF8), Color(0xFF5B8AF5), Color(0xFF4ECDC4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'P',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'PsyBuddy',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your AI-powered mental\nwellness companion',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 48),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: ['AI Chat', 'Mood Tracking', 'Dream Journal']
                                  .map((f) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.4)),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(f,
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500)),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Right form panel
                Flexible(
                  flex: 4,
                  child: SafeArea(child: _buildForm(true)),
                ),
              ],
            );
          }
          return SafeArea(
            child: _buildForm(false),
          );
        },
      ),
    );
  }
}
