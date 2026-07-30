import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Modal nhập mật khẩu PFX — dùng Get.dialog để luôn hiện trên mọi máy.
class PfxPasswordDialog extends StatefulWidget {
  const PfxPasswordDialog({super.key});

  /// Trả về mật khẩu (đã trim). `null` = người dùng hủy.
  static Future<String?> show() {
    return Get.dialog<String>(
      const PfxPasswordDialog(),
      barrierDismissible: false,
      useSafeArea: true,
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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

    Get.back(result: password);
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
          onPressed: () => Get.back(result: null),
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
