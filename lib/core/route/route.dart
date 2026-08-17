import 'package:chanhung/view/screens/auth/forgot_password/forget_password.dart';
import 'package:chanhung/view/screens/auth/login/login_screen.dart';
import 'package:chanhung/view/screens/auth/registration/registration_screen.dart';
import 'package:chanhung/view/screens/contract/contract_details_screen.dart';
import 'package:chanhung/view/screens/contract/contracts_screen.dart';
import 'package:chanhung/view/screens/estimate/estimate_details_screen.dart';
import 'package:chanhung/view/screens/estimate/estimate_screen.dart';
import 'package:chanhung/view/screens/dms/dms_document_details_screen.dart';
import 'package:chanhung/view/screens/dms/dms_pdf_viewer_screen.dart';
import 'package:chanhung/view/screens/dms/dms_screen.dart';
import 'package:chanhung/view/screens/dashboard/main_shell_screen.dart';
import 'package:chanhung/view/screens/hr/hr_screen.dart';
import 'package:chanhung/view/screens/hr/leave_screen.dart';
import 'package:chanhung/view/screens/hr/attendance_screen.dart';
import 'package:chanhung/view/screens/hr/business_trip_screen.dart';
import 'package:chanhung/view/screens/intro_section/onboard_intro_screen.dart';
import 'package:chanhung/view/screens/invoice/invoice_details_screen.dart';
import 'package:chanhung/view/screens/invoice/invoice_screen.dart';
import 'package:chanhung/view/screens/menu/menu_screen.dart';
import 'package:chanhung/view/screens/payment/payment_details_screen.dart';
import 'package:chanhung/view/screens/payment/payment_screen.dart';
import 'package:chanhung/view/screens/privacy_policy/privacy_policy_screen.dart';
import 'package:chanhung/view/screens/profile/profile_screen.dart';
import 'package:chanhung/view/screens/project/project_details_screen.dart';
import 'package:chanhung/view/screens/project/projects_screen.dart';
import 'package:chanhung/view/screens/proposal/proposal_details_screen.dart';
import 'package:chanhung/view/screens/proposal/proposal_screen.dart';
import 'package:chanhung/view/screens/splash/splash_screen.dart';
import 'package:chanhung/view/screens/team_chat/team_chat_room_screen.dart';
import 'package:chanhung/view/screens/team_chat/team_chat_screen.dart';
import 'package:chanhung/view/screens/timeline/timeline_screen.dart';
import 'package:chanhung/view/screens/ticket/ticket_details_screen.dart';
import 'package:chanhung/view/screens/ticket/ticket_screen.dart';
import 'package:chanhung/view/screens/payment_request/payment_requests_screen.dart';
import 'package:chanhung/view/screens/payment_request/payment_request_details_screen.dart';
import 'package:chanhung/view/screens/tasks/my_tasks_screen.dart';
import 'package:chanhung/view/screens/dept_daily_work/dept_daily_work_screen.dart';
import 'package:get/get.dart';

class RouteHelper {
  static const String splashScreen = "/splash_screen";
  static const String onboardScreen = '/onboard_screen';
  static const String loginScreen = "/login_screen";
  static const String registrationScreen = "/registration_screen";
  static const String forgotPasswordScreen = "/forgot_password_screen";

  static const String dashboardScreen = "/dashboard_screen";
  static const String projectScreen = "/project_screen";
  static const String projectDetailsScreen = "/project_details_screen";
  static const String invoiceScreen = "/invoice_screen";
  static const String invoiceDetailsScreen = "/invoice_details_screen";
  static const String contractScreen = "/contract_screen";
  static const String contractDetailsScreen = "/contract_details_screen";
  static const String contractCommentsScreen = "/contract_comments_screen";
  static const String ticketScreen = "/ticket_screen";
  static const String ticketDetailsScreen = "/ticket_details_screen";
  static const String hrScreen = "/hr_screen";
  static const String leaveScreen = "/leave_screen";
  static const String attendanceScreen = "/attendance_screen";
  static const String businessTripScreen = "/business_trip_screen";
  static const String dmsScreen = "/dms_screen";
  static const String dmsDocumentDetailsScreen = "/dms_document_details_screen";
  static const String dmsPdfViewerScreen = "/dms_pdf_viewer_screen";
  static const String estimateScreen = "/estimate_screen";
  static const String estimateDetailsScreen = "/estimate_details_screen";
  static const String paymentScreen = "/payment_screen";
  static const String paymentDetailsScreen = "/payment_details_screen";
  static const String paymentRequestScreen = "/payment_request_screen";
  static const String paymentRequestDetailsScreen =
      "/payment_request_details_screen";
  static const String proposalScreen = "/proposal_screen";
  static const String proposalDetailsScreen = "/proposal_details_screen";
  static const String teamChatScreen = "/team_chat_screen";
  static const String teamChatRoomScreen = "/team_chat_room_screen";
  static const String timelineScreen = "/timeline_screen";
  static const String settingsScreen = "/settings_screen";
  static const String profileScreen = "/profile_screen";
  static const String privacyScreen = "/privacy_screen";
  static const String myTasksScreen = "/my_tasks_screen";
  static const String deptDailyWorkScreen = "/dept_daily_work_screen";

  static String withId(String route, Object? id) {
    return '$route?id=${Uri.encodeComponent(id?.toString() ?? '')}';
  }

  List<GetPage> routes = [
    GetPage(name: splashScreen, page: () => const SplashScreen()),
    GetPage(name: onboardScreen, page: () => const OnBoardIntroScreen()),
    GetPage(name: loginScreen, page: () => const LoginScreen()),
    GetPage(name: registrationScreen, page: () => const RegistrationScreen()),
    GetPage(
        name: forgotPasswordScreen, page: () => const ForgetPasswordScreen()),
    GetPage(name: dashboardScreen, page: () => const MainShellScreen()),
    GetPage(name: projectScreen, page: () => const ProjectsScreen()),
    GetPage(
        name: projectDetailsScreen,
        page: () => ProjectDetailsScreen(id: _routeId())),
    GetPage(name: invoiceScreen, page: () => const InvoicesScreen()),
    GetPage(
        name: invoiceDetailsScreen,
        page: () => InvoiceDetailsScreen(id: _routeId())),
    GetPage(name: contractScreen, page: () => const ContractsScreen()),
    GetPage(
        name: contractDetailsScreen,
        page: () => ContractDetailsScreen(id: _routeId())),
    GetPage(name: ticketScreen, page: () => const TicketsScreen()),
    GetPage(
        name: ticketDetailsScreen,
        page: () => TicketDetailsScreen(id: _routeId())),
    GetPage(name: hrScreen, page: () => const HrScreen()),
    GetPage(name: leaveScreen, page: () => const LeaveScreen()),
    GetPage(name: attendanceScreen, page: () => const AttendanceScreen()),
    GetPage(name: businessTripScreen, page: () => const BusinessTripScreen()),
    GetPage(name: dmsScreen, page: () => const DmsScreen()),
    GetPage(
        name: dmsDocumentDetailsScreen,
        page: () => DmsDocumentDetailsScreen(id: _routeId())),
    GetPage(name: dmsPdfViewerScreen, page: () => const DmsPdfViewerScreen()),
    GetPage(name: estimateScreen, page: () => const EstimateScreen()),
    GetPage(
        name: estimateDetailsScreen,
        page: () => EstimateDetailsScreen(id: _routeId())),
    GetPage(name: paymentScreen, page: () => const PaymentScreen()),
    GetPage(
        name: paymentDetailsScreen,
        page: () => PaymentDetailsScreen(id: _routeId())),
    GetPage(
        name: paymentRequestScreen, page: () => const PaymentRequestsScreen()),
    GetPage(
        name: paymentRequestDetailsScreen,
        page: () => const PaymentRequestDetailsScreen()),
    GetPage(name: proposalScreen, page: () => const ProposalScreen()),
    GetPage(
        name: proposalDetailsScreen,
        page: () => ProposalDetailsScreen(id: _routeId())),
    GetPage(name: teamChatScreen, page: () => const TeamChatScreen()),
    GetPage(name: teamChatRoomScreen, page: () => const TeamChatRoomScreen()),
    GetPage(name: timelineScreen, page: () => const TimelineScreen()),
    GetPage(name: profileScreen, page: () => const ProfileScreen()),
    GetPage(name: settingsScreen, page: () => const MenuScreen()),
    GetPage(name: privacyScreen, page: () => const PrivacyPolicyScreen()),
    GetPage(name: myTasksScreen, page: () => const MyTasksScreen()),
    GetPage(name: deptDailyWorkScreen, page: () => const DeptDailyWorkScreen()),
  ];
}

String _routeId() {
  final argument = Get.arguments;
  if (argument != null) {
    return argument.toString();
  }
  return Get.parameters['id']?.toString() ?? '';
}
