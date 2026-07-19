class UrlContainer {
  static const String domainUrl = 'https://erp.chanhungltd.info.vn';

  // if your domain have index.php at the end please add it to the domain url too
  // Example: https://your-domain.com/index.php

  static const String baseUrl = '$domainUrl/api/v1/';
  static const String attachmentUrl = '$domainUrl/files/timeline_files/';
  static const String profileImgUrl = '$domainUrl/files/profile_images/';
  static const String systemImgUrl = '$domainUrl/files/system/';

  static RegExp emailValidatorRegExp =
      RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  // Authentication
  static const String loginUrl = 'auth/login';
  static const String passkeyOptionsUrl = 'auth/passkey/options';
  static const String passkeyVerifyUrl = 'auth/passkey/verify';
  static const String registrationUrl = 'auth/register';
  static const String forgotPasswordUrl = 'auth/forgot-password';

  // Dashboard
  static const String overviewUrl = 'overview';
  static const String dashboardUrl = 'dashboard';

  // Pages
  static const String projectsUrl = 'projects';
  static const String tasksUrl = 'tasks';
  static const String usersUrl = 'users';
  static const String hrDashboardUrl = 'hr_dashboard';
  static const String documentsUrl = 'documents';
  static const String invoicesUrl = 'invoices';
  static const String contractsUrl = 'contracts';
  static const String estimatesUrl = 'estimates';
  static const String proposalsUrl = 'proposals';
  static const String paymentsUrl = 'payments';
  static const String paymentRequestsUrl = 'payment_requests';
  static const String ticketsUrl = 'tickets';
  static const String profileUrl = 'profile';
  static const String privacyPolicyUrl = 'knowledge_base/privacy-policy';

  // HR - Leaves
  static const String leavesUrl = 'leaves';
  static const String leaveTypesUrl = 'leaves/types';

  // HR - Attendance
  static const String attendanceTodayUrl = 'attendance/today-status';
  static const String attendanceCheckInUrl = 'attendance/check-in';
  static const String attendanceCheckOutUrl = 'attendance/check-out';
  static const String attendanceHistoryUrl = 'attendance/history';
  static const String saveDeviceTokenUrl = 'attendance/save-device-token';

  // HR - Business Trips
  static const String businessTripsUrl = 'business_trips';

  static const String teamChatBootstrapUrl = 'team_chat/bootstrap';
  static const String teamChatMessagesUrl = 'team_chat/messages';
  static const String teamChatSendUrl = 'team_chat/send';
  static const String teamChatVideoUrl = 'team_chat/video_meeting';
}
