import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../config/routes/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isRegister = false;
  final _nameCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(authControllerProvider.notifier);
    final ok = _isRegister
        ? await controller.register(_nameCtrl.text, _identifierCtrl.text, _passwordCtrl.text)
        : await controller.signIn(_identifierCtrl.text, _passwordCtrl.text);
    if (ok && mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spaceXl),
              Icon(Icons.eco_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppConstants.spaceMd),
              Text(
                _isRegister ? 'Create your account' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppConstants.spaceSm),
              Text(
                _isRegister
                    ? 'Set up your farm profile to get personalized weather, disease, and market advice.'
                    : 'Sign in to see today\'s weather, alerts, and market prices for your farm.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.spaceLg),
              if (_isRegister) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: AppConstants.spaceMd),
              ],
              TextField(
                controller: _identifierCtrl,
                decoration: const InputDecoration(labelText: 'Phone number or email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppConstants.spaceMd),
              TextField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              if (authState.errorMessage != null) ...[
                const SizedBox(height: AppConstants.spaceSm),
                Text(authState.errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: AppConstants.spaceLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isRegister ? 'Create account' : 'Sign in'),
                ),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isRegister = !_isRegister),
                  child: Text(_isRegister
                      ? 'Already have an account? Sign in'
                      : 'New to Mkulima AI? Create an account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
