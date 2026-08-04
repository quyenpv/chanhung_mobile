import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/controller/dms/dms_controller.dart';
import 'package:chanhung/data/model/dms/dms_document_model.dart';
import 'package:chanhung/data/repo/dms/dms_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal stand-in of the signing card logic used on document details.
class _PfxSignCardHarness extends StatelessWidget {
  const _PfxSignCardHarness({
    required this.document,
    required this.controller,
  });

  final DmsDocument document;
  final DmsController controller;

  @override
  Widget build(BuildContext context) {
    final permission = document.signPermission;
    final hasPfxCertificate = permission?.hasPfxCertificate == true;
    final hasPfxSavedPassword = permission?.hasPfxSavedPassword == true;
    final canSubmitPfx =
        document.canSign && hasPfxCertificate && !controller.isSigning;

    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Column(
              children: [
                if (document.canSign &&
                    hasPfxCertificate &&
                    !hasPfxSavedPassword)
                  Text(LocalStrings.pfxPasswordRequiredHint),
                ElevatedButton(
                  onPressed: canSubmitPfx
                      ? () async {
                          final needsPassword =
                              permission?.hasPfxSavedPassword != true &&
                                  permission?.selectedPfxProfile
                                          ?.hasSavedPassword !=
                                      true;
                          final passwordController = TextEditingController();
                          await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: Text(LocalStrings.confirmSignDocument),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(LocalStrings
                                        .confirmPfxSignDocumentMessage),
                                    if (needsPassword) ...[
                                      Text(LocalStrings.pfxPasswordLabel),
                                      TextField(
                                        controller: passwordController,
                                        decoration: const InputDecoration(
                                          hintText:
                                              LocalStrings.pfxPasswordHint,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              );
                            },
                          );
                          passwordController.dispose();
                        }
                      : null,
                  child: Text(LocalStrings.signWithPfx),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DmsController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(ApiClient(sharedPreferences: await SharedPreferences.getInstance()));
    Get.put(DmsRepo(apiClient: Get.find()));
    controller = Get.put(DmsController(dmsRepo: Get.find()));
  });

  tearDown(() {
    Get.reset();
  });

  DmsDocument buildDoc({
    required bool canSign,
    required bool hasCert,
    required bool hasSavedPassword,
  }) {
    final doc = DmsDocument();
    doc.canSign = canSign;
    final permission = DmsSignPermission();
    permission.canStartPfx = false; // simulate old/broken API flag
    permission.hasPfxCertificate = hasCert;
    permission.hasPfxSavedPassword = hasSavedPassword;
    permission.pfxProfiles = [
      DmsPfxProfile()
        ..slug = 'default'
        ..label = 'Công ty chính / vai trò chính'
        ..hasCertificate = hasCert
        ..hasSavedPassword = hasSavedPassword,
    ];
    permission.suggestedPfxProfileSlug = 'default';
    doc.signPermission = permission;
    doc.signers = [DmsSigner()..userName = 'Tester'];
    return doc;
  }

  testWidgets('PFX button enabled and opens password modal when password not saved',
      (tester) async {
    final doc = buildDoc(
      canSign: true,
      hasCert: true,
      hasSavedPassword: false,
    );

    await tester.pumpWidget(
      _PfxSignCardHarness(document: doc, controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text(LocalStrings.pfxPasswordRequiredHint), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, LocalStrings.signWithPfx),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text(LocalStrings.signWithPfx));
    await tester.pumpAndSettle();

    expect(find.text(LocalStrings.confirmSignDocument), findsOneWidget);
    expect(find.text(LocalStrings.pfxPasswordLabel), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('PFX button stays disabled when certificate missing',
      (tester) async {
    final doc = buildDoc(
      canSign: true,
      hasCert: false,
      hasSavedPassword: false,
    );

    await tester.pumpWidget(
      _PfxSignCardHarness(document: doc, controller: controller),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, LocalStrings.signWithPfx),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Saved password skips password field in confirm dialog',
      (tester) async {
    final doc = buildDoc(
      canSign: true,
      hasCert: true,
      hasSavedPassword: true,
    );

    await tester.pumpWidget(
      _PfxSignCardHarness(document: doc, controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text(LocalStrings.pfxPasswordRequiredHint), findsNothing);

    await tester.tap(find.text(LocalStrings.signWithPfx));
    await tester.pumpAndSettle();

    expect(find.text(LocalStrings.confirmSignDocument), findsOneWidget);
    expect(find.text(LocalStrings.pfxPasswordLabel), findsNothing);
  });
}
