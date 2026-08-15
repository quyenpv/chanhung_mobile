import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/data/controller/payment_request/payment_request_controller.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';

class CreatePaymentRequestScreen extends StatefulWidget {
  const CreatePaymentRequestScreen({super.key});

  @override
  State<CreatePaymentRequestScreen> createState() =>
      _CreatePaymentRequestScreenState();
}

class _CreatePaymentRequestScreenState
    extends State<CreatePaymentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _beneficiaryNameController = TextEditingController();
  final _beneficiaryBankController = TextEditingController();
  final _beneficiaryAccountController = TextEditingController();

  int? _selectedCompanyId;
  String _selectedPaymentMethod = 'cash';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _beneficiaryNameController.dispose();
    _beneficiaryBankController.dispose();
    _beneficiaryAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Tạo Yêu Cầu Thanh Toán',
      ),
      body: GetBuilder<PaymentRequestsController>(
        builder: (controller) {
          if (controller.companiesList.isEmpty && _selectedCompanyId == null) {
            // Autoselect first company if loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (controller.companiesList.isNotEmpty) {
                setState(() {
                  _selectedCompanyId = controller.companiesList[0]['id'];
                });
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.space20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin đề nghị',
                    style: semiBoldLarge.copyWith(
                        color: ColorResources.primaryColor),
                  ),
                  const SizedBox(height: Dimensions.space15),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.space15),

                  // Company Select
                  DropdownButtonFormField<int>(
                    value: _selectedCompanyId,
                    decoration: InputDecoration(
                      labelText: 'Đơn vị thành viên *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: controller.companiesList.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'],
                        child: Text(c['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCompanyId = val;
                      });
                    },
                    validator: (val) {
                      if (val == null) {
                        return 'Vui lòng chọn đơn vị';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.space15),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền *',
                      suffixText: controller.currency ?? 'đ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập số tiền';
                      }
                      if (double.tryParse(val) == null) {
                        return 'Số tiền không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.space15),

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Nội dung chi tiết',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: Dimensions.space25),

                  Text(
                    'Thông tin thụ hưởng',
                    style: semiBoldLarge.copyWith(
                        color: ColorResources.primaryColor),
                  ),
                  const SizedBox(height: Dimensions.space15),

                  // Payment Method
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Phương thức thanh toán',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                      DropdownMenuItem(
                          value: 'bank_transfer', child: Text('Chuyển khoản')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedPaymentMethod = val ?? 'cash';
                      });
                    },
                  ),
                  const SizedBox(height: Dimensions.space15),

                  // Beneficiary Name
                  TextFormField(
                    controller: _beneficiaryNameController,
                    decoration: InputDecoration(
                      labelText: 'Tên người thụ hưởng *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập tên người thụ hưởng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.space15),

                  if (_selectedPaymentMethod == 'bank_transfer') ...[
                    // Beneficiary Bank
                    TextFormField(
                      controller: _beneficiaryBankController,
                      decoration: InputDecoration(
                        labelText: 'Ngân hàng nhận',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      validator: (val) {
                        if (_selectedPaymentMethod == 'bank_transfer' &&
                            (val == null || val.trim().isEmpty)) {
                          return 'Vui lòng nhập ngân hàng nhận';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Dimensions.space15),

                    // Beneficiary Account
                    TextFormField(
                      controller: _beneficiaryAccountController,
                      decoration: InputDecoration(
                        labelText: 'Số tài khoản nhận',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      validator: (val) {
                        if (_selectedPaymentMethod == 'bank_transfer' &&
                            (val == null || val.trim().isEmpty)) {
                          return 'Vui lòng nhập số tài khoản nhận';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Dimensions.space15),
                  ],

                  const SizedBox(height: Dimensions.space30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorResources.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: controller.isCreating
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                final totalAmount = double.tryParse(
                                    _amountController.text.trim());
                                if (totalAmount == null ||
                                    _selectedCompanyId == null) {
                                  return;
                                }
                                final success = await controller.createRequest(
                                  title: _titleController.text.trim(),
                                  companyId: _selectedCompanyId!,
                                  totalAmount: totalAmount,
                                  description: _descController.text.trim(),
                                  paymentMethodCode: _selectedPaymentMethod,
                                  beneficiaryName:
                                      _beneficiaryNameController.text.trim(),
                                  beneficiaryBank:
                                      _beneficiaryBankController.text.trim(),
                                  beneficiaryAccount:
                                      _beneficiaryAccountController.text.trim(),
                                );
                                if (success) {
                                  Get.back();
                                }
                              }
                            },
                      child: controller.isCreating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'GỬI ĐỀ NGHỊ THANH TOÁN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
