import 'package:flutter/material.dart';

import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';

class LoginGate extends StatefulWidget {
  const LoginGate({
    super.key,
    required this.controller,
    required this.onUnlocked,
  });

  final MotivationController controller;
  final VoidCallback onUnlocked;

  @override
  State<LoginGate> createState() => _LoginGateState();
}

class _LoginGateState extends State<LoginGate> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  String _message = '';
  String _recoveryCode = '';

  bool get _passcodeExists => widget.controller.hasAppPasscode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _message = 'Enter your passcode.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = '';
    });

    try {
      if (!_passcodeExists) {
        final recoveryCode = widget.controller.generateRecoveryCode();
        _recoveryCode = recoveryCode;
        await widget.controller.setAppPasscode(
          value,
          recoveryCode: recoveryCode,
        );
        if (mounted) {
          _showRecoveryCodeDialog();
          widget.onUnlocked();
        }
        return;
      }

      final isValid = await widget.controller.validateAppPasscode(value);
      if (!isValid) {
        if (mounted) {
          setState(() => _message = 'Incorrect passcode.');
        }
        return;
      }

      if (mounted) widget.onUnlocked();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showRecoveryCodeDialog({String? codeOverride}) {
    final code =
        codeOverride ??
        (_recoveryCode.isNotEmpty
            ? _recoveryCode
            : widget.controller.appRecoveryCode);
    if (code.isEmpty) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Recovery code'),
        content: SelectableText(
          code,
          style: const TextStyle(fontFamilyFallback: AppTheme.mono),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I saved it'),
          ),
        ],
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final recoveryController = TextEditingController();
    final newPasscodeController = TextEditingController();
    final confirmPasscodeController = TextEditingController();
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Reset passcode'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your recovery code and choose a new passcode.',
                style: TextStyle(color: AppTheme.textMid),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recoveryController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Recovery code',
                  hintText: 'QUEST-123456-654321',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasscodeController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New passcode',
                  hintText: '••••',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasscodeController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new passcode',
                  hintText: '••••',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final recovery = recoveryController.text.trim();
              final newPasscode = newPasscodeController.text.trim();
              final confirmPasscode = confirmPasscodeController.text.trim();
              if (recovery.isEmpty ||
                  newPasscode.isEmpty ||
                  confirmPasscode.isEmpty) {
                return;
              }
              if (newPasscode != confirmPasscode) {
                return;
              }
              Navigator.of(
                context,
              ).pop({'recovery': recovery, 'newPasscode': newPasscode});
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final recovery = result['recovery']!;
    final newPasscode = result['newPasscode']!;

    try {
      await widget.controller.resetAppPasscode(
        recoveryCode: recovery,
        newPasscode: newPasscode,
      );
      if (mounted) {
        setState(() => _message = 'Passcode reset. You can sign in again.');
        _controller.clear();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _passcodeExists ? 'Enter your passcode' : 'Set a passcode';
    final subtitle = _passcodeExists
        ? 'This app is locked to keep your habits private.'
        : 'Create a local passcode for this device.';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: AppTheme.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 42,
                      color: AppTheme.amberBright,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textHigh,
                        fontFamilyFallback: AppTheme.mono,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMid),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(color: AppTheme.textHigh),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.bg,
                        hintText: '••••',
                        hintStyle: const TextStyle(color: AppTheme.textLow),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.hairline,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.hairline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.amberBright,
                          ),
                        ),
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.amberBright),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(_isSubmitting ? 'Checking...' : 'Enter'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.amberBright,
                        foregroundColor: AppTheme.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    if (_passcodeExists) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _showRecoveryCodeDialog(
                          codeOverride: widget.controller.appRecoveryCode,
                        ),
                        child: const Text('View recovery code'),
                      ),
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot passcode?'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
