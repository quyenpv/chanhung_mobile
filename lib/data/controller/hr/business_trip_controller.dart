import 'dart:convert';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/model/hr/business_trip_model.dart';
import 'package:chanhung/data/repo/hr/business_trip_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class BusinessTripController extends GetxController {
  final BusinessTripRepo businessTripRepo;
  BusinessTripController({required this.businessTripRepo});

  bool isLoading = true;
  bool isSubmitting = false;

  BusinessTripsModel tripsModel = const BusinessTripsModel(trips: [], total: 0);
  String selectedStatus = '';

  final List<Map<String, String>> statusFilters = [
    {'label': 'Tất Cả', 'value': ''},
    {'label': LocalStrings.pending, 'value': 'pending'},
    {'label': LocalStrings.approved, 'value': 'approved'},
    {'label': LocalStrings.rejected, 'value': 'rejected'},
  ];
  int selectedFilterIndex = 0;

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    update();
    await loadTrips();
    isLoading = false;
    update();
  }

  Future<void> loadTrips() async {
    ResponseModel response = await businessTripRepo.getTrips(
      status: selectedStatus,
      limit: 100,
    );
    if (response.statusCode == 200) {
      try {
        tripsModel =
            BusinessTripsModel.fromJson(jsonDecode(response.responseJson));
      } catch (_) {
        tripsModel = const BusinessTripsModel(trips: [], total: 0);
      }
    } else {
      tripsModel = const BusinessTripsModel(trips: [], total: 0);
    }
    update();
  }

  void setFilter(int index) {
    selectedFilterIndex = index;
    selectedStatus = statusFilters[index]['value'] ?? '';
    update();
    loadTrips();
  }

  Future<bool> createTrip({
    required String title,
    required String startDate,
    required String endDate,
    String destination = '',
    String purpose = '',
    String notes = '',
  }) async {
    isSubmitting = true;
    update();

    ResponseModel response = await businessTripRepo.createTrip(
      title: title,
      startDate: startDate,
      endDate: endDate,
      destination: destination,
      purpose: purpose,
      notes: notes,
    );

    isSubmitting = false;
    update();

    if (response.statusCode == 201 || response.statusCode == 200) {
      CustomSnackBar.success(successList: [LocalStrings.tripSubmitted.tr]);
      await loadTrips();
      return true;
    } else {
      CustomSnackBar.error(errorList: [
        response.message.isNotEmpty
            ? response.message
            : LocalStrings.somethingWentWrong.tr
      ]);
      return false;
    }
  }

  Future<bool> approveTrip(int id) async {
    isSubmitting = true;
    update();

    ResponseModel response = await businessTripRepo.approveTrip(id);

    isSubmitting = false;
    update();

    if (response.statusCode == 200) {
      CustomSnackBar.success(successList: ['Duyệt yêu cầu công tác thành công']);
      await loadTrips();
      return true;
    } else {
      CustomSnackBar.error(errorList: [
        response.message.isNotEmpty
            ? response.message
            : LocalStrings.somethingWentWrong.tr
      ]);
      return false;
    }
  }

  Future<bool> rejectTrip(int id) async {
    isSubmitting = true;
    update();

    ResponseModel response = await businessTripRepo.rejectTrip(id);

    isSubmitting = false;
    update();

    if (response.statusCode == 200) {
      CustomSnackBar.success(successList: ['Từ chối yêu cầu công tác thành công']);
      await loadTrips();
      return true;
    } else {
      CustomSnackBar.error(errorList: [
        response.message.isNotEmpty
            ? response.message
            : LocalStrings.somethingWentWrong.tr
      ]);
      return false;
    }
  }

  Future<BusinessTripModel?> loadTripDetails(int id) async {
    ResponseModel response = await businessTripRepo.getTrip(id);
    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.responseJson);
        final data = decoded['business_trip'];
        if (data != null) {
          return BusinessTripModel.fromJson(data);
        }
      } catch (_) {}
    }
    return null;
  }
}
