import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

/// Modal nhập mật khẩu PFX.
/// Dùng [showDialog] + root navigator — tránh crash `Get.dialog` khi Overlay
/// chưa sẵn sàng hoặc đang mở bottom sheet.
class PfxPasswordDialog extends StatefulWidget {
  const PfxPasswordDialog({super.key});

  /// Trả về mật khẩu (đã trim). `null` = người dùng hủy / không mở được dialog.
  static Future<String?> show({BuildContext? context}) async {
    BuildContext? ctx = context;
    if (ctx == null || !ctx.mounted) {
      await SchedulerBinding.instance.endOfFrame;
      ctx = Get.overlayContext ?? Get.context ?? Get.key.currentContext;
    }
    if (ctx == null || !ctx.mounted) {
      return null;
    }

    try {
      return await showDialog<String>(
        context: ctx,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => const PfxPasswordDialog(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  State<PfxPasswordDialog> createState() => _PfxPasswordDialogState();
}

class _PfxPasswordDialogState extends State<PfxPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    // Chờ IME commit text trên một số máy Android.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }

    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorText = LocalStrings.enterPfxPassword.tr;
      });
      return;
    }

    Navigator.of(context).pop(password);
  }

  void _cancel() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocalStrings.confirmSignDocument.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocalStrings.confirmPfxSignDocumentMessage.tr),
            const SizedBox(height: Dimensions.space15),
            Text(
              LocalStrings.pfxPasswordLabel.tr,
              style: mediumDefault,
            ),
            const SizedBox(height: Dimensions.space8),
            TextField(
              controller: _passwordController,
              focusNode: _focusNode,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              decoration: InputDecoration(
                hintText: LocalStrings.pfxPasswordHint.tr,
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: Text(LocalStrings.no.tr),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(LocalStrings.yes.tr),
        ),
      ],
    );
  }
}
