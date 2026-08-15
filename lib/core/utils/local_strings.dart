import 'package:chanhung/data/model/language/language_model.dart';

class LocalStrings {
  static const String appName = "ChanHung";

  static List<LanguageModel> appLanguages = [
    LanguageModel(
        languageName: 'Tiếng Việt', countryCode: 'VN', languageCode: 'vi'),
    LanguageModel(
        languageName: 'English', countryCode: 'US', languageCode: 'en'),
    LanguageModel(
        languageName: 'العربية', countryCode: 'SA', languageCode: 'ar'),
    LanguageModel(
        languageName: 'Spanish', countryCode: 'ES', languageCode: 'es'),
    LanguageModel(
        languageName: 'French', countryCode: 'FR', languageCode: 'fr'),
  ];

  // Onboarding Screens
  static const String onboardTitle1 = "Onboarding one";
  static const String onboardSubTitle1 = "Onboarding One Description";
  static const String onboardTitle2 = "Onboarding Two";
  static const String onboardSubTitle2 = "Onboarding Two Description.";
  static const String onboardTitle3 = "Onboarding Three";
  static const String onboardSubTitle3 = "Onboarding Three Description.";
  static const String companyRulesTitle = "Nội quy sử dụng ứng dụng";
  static const String companyRulesBody =
      "Việc sử dụng Chấn Hưng ERP Mobile phải bảo mật dữ liệu nội bộ theo nội quy, quy định của Công ty";
  static const String companyRulesAgree =
      "Tôi đã đọc và đồng ý với nội quy sử dụng ứng dụng";
  static const String companyRulesRequired =
      "Vui lòng đồng ý nội quy để tiếp tục";
  static const String skip = "Skip";
  static const String next = "Next";
  static const String getStarted = "Get Started";

  // Login Screen
  static const String password = "Password";
  static const String rememberMe = "Remember Me";
  static const String forgotPassword = "Forgot Password?";
  static const String forgotPasswordTitle = 'Forgot Password';
  static const String forgotPasswordDesc =
      'Enter your email below to receive a password reset verification link';
  static const String signIn = "Sign In";
  static const String signInWithPasskey = "Sign In With Passkey";
  static const String passkeyLoginUnavailable =
      "Passkey sign-in is not available on this device";
  static const String noPasskeyResponse = "No passkey response returned";
  static const String login = 'Login';
  static const String loginDesc = 'Login to your account';
  static const String doNotHaveAccount = "Don't have an account?";
  static const String createAnAccount = "Create an Account";
  static const String iAgreeWith = "I agree with the";
  static const String policies = 'Policies';
  static const String loginFailedTryAgain = 'Login failed,please try again';

  // Register Screen
  static const String firstName = "First Name";
  static const String enterFirstName = "Enter first name";
  static const String lastName = "Last Name";
  static const String last = "Last";
  static const String enterLastName = "Enter last name";
  static const String mobileNumber = "Mobile Number";
  static const String emailAddress = "Email Address";
  static const String confirmPassword = "Confirm Password";
  static const String firstNameHint = "Enter first Name";
  static const String lastNameHint = "Enter last Name";
  static const String mobileNumberHint = "Your phone number";
  static const String emailAddressHint = "Enter email address";
  static const String emailAddressEmptyMsg = "Email address can't be empty";
  static const String confirmPasswordHint = "Enter confirm Password";
  static const String signUp = "Sign Up";
  static const String alreadyAccount = "Already have an account?";
  static const String signInNow = "Sign In Now";
  static const String signUpNow = "Sign Up Now";
  static const String companyName = "Company Name";
  static const String enterCompanyName = "Enter Company Name";
  static const String email = "Email";
  static const String enterEmail = "Enter email";
  static const String invalidEmailMsg = "Enter valid email";
  static const String enterYourPassword = 'Enter your password';
  static const String passwordMatchError = "Password doesn't match";
  static const String companyAccount = "Organization";
  static const String personalAccount = "Personal";
  static const String agreePolicyMessage =
      "You must agree with our privacy & policies";

  // Change Password
  static const String changePassword = "Change Password";
  static const String currentPassword = "Current Password";
  static const String currentPasswordHint = "Enter current password";
  static const String saveNewPassword = "Save New Password";

  // Home
  static const String home = "Home";
  static const String dashboard = "Dashboard";
  static const String welcome = 'Welcome';
  static const String humanResources = "Human Resources";
  static const String employees = "Employees";
  static const String employee = "Employee";
  static const String employeeDetails = "Employee Details";
  static const String employeeId = "Employee ID";
  static const String jobTitle = "Job Title";
  static const String workType = "Work Type";
  static const String company = "Company";
  static const String active = "Active";
  static const String inactive = "Inactive";
  static const String totalEmployees = "Total Employees";
  static const String newEmployeesThisMonth = "New Employees This Month";
  static const String presentToday = "Present Today";
  static const String attendanceRate = "Attendance Rate";
  static const String averageWorkingHours = "Average Working Hours";
  static const String onLeaveToday = "On Leave Today";
  static const String dmsOffice = "DMS Office";
  static const String documents = "Documents";
  static const String documentDetails = "Document Details";
  static const String incomingDocuments = "Incoming Documents";
  static const String outgoingDocuments = "Outgoing Documents";
  static const String waitingForSignature = "Waiting For Signature";
  static const String documentCode = "Document Code";
  static const String documentType = "Document Type";
  static const String organization = "Organization";
  static const String drafter = "Drafter";
  static const String issuedDate = "Issued Date";
  static const String arrivalDate = "Arrival Date";
  static const String attachments = "Attachments";
  static const String signers = "Signers";
  static const String documentFiles = "Document Files";
  static const String signingFile = "Signing File";
  static const String attachedFiles = "Attached Files";
  static const String viewFile = "View File";
  static const String downloadFile = "Download File";
  static const String digitalSignature = "Digital Signature";
  static const String signDocument = "Ký văn bản";
  static const String signWithEsign = "Sign With eSign";
  static const String signWithPfx = "Ký PFX server";
  static const String rejectSignDocument = "Từ chối ký";
  static const String rejectSignDocumentTitle = "Từ chối ký văn bản";
  static const String rejectSignPaymentRequestTitle = "Từ chối ký ĐNTT/ĐNTU";
  static const String rejectSignReasonLabel = "Lý do từ chối (*)";
  static const String rejectSignReasonHint = "Nhập lý do từ chối ký văn bản";
  static const String rejectSignPaymentRequestReasonHint =
      "Nhập lý do từ chối ký phiếu";
  static const String enterRejectReason = "Vui lòng nhập lý do từ chối";
  static const String confirmRejectSignMessage =
      "Văn bản sẽ bị từ chối và trả về người soạn. Các người ký còn lại sẽ bị hủy lượt.";
  static const String confirmRejectPaymentRequestMessage =
      "Phiếu sẽ bị từ chối và trả về trạng thái nháp để người lập chỉnh sửa. Chuỗi ký sẽ được reset.";
  static const String rejectSignSuccess = "Đã từ chối văn bản.";
  static const String rejectPaymentRequestSuccess =
      "Đã từ chối ký. Phiếu đã trả về trạng thái nháp.";
  static const String serverPfxCertificate = "Chứng thư PFX server";
  static const String pfxNotConfigured = "Chưa cấu hình PFX";
  static const String pfxPasswordNotSaved = "Chưa lưu mật khẩu PFX";
  static const String pfxPasswordRequiredHint =
      "Cần nhập mật khẩu chứng thư mềm khi ký";
  static const String pfxPasswordLabel = "Mật khẩu chứng thư (*)";
  static const String pfxPasswordOptionalLabel =
      "Mật khẩu chứng thư (để trống nếu đã lưu)";
  static const String pfxPasswordHint = "Nhập mật khẩu tệp PFX của bạn";
  static const String pfxPasswordOptionalHint =
      "Nhập mật khẩu, hoặc để trống để dùng mật khẩu đã lưu";
  static const String enterPfxPassword = "Vui lòng nhập mật khẩu chứng thư PFX";
  static const String signingUnavailable = "Chưa thể ký";
  static const String confirmSignDocument = "Xác nhận ký văn bản";
  static const String confirmSignDocumentMessage =
      "Yêu cầu ký sẽ được gửi tới MISA eSign. Vui lòng xác nhận trên app MISA eSign để hoàn tất.";
  static const String confirmPfxSignDocumentMessage =
      "Server sẽ ký văn bản này bằng chứng thư PFX của bạn.";
  static const String esignNotConnected = "eSign Not Connected";
  static const String openFileFailed = "Could Not Open File";
  static const String openInBrowser = "Mở bằng trình duyệt";
  static const String retry = "Thử lại";
  static const String clearSearch = "Clear Search";
  static const String all = "All";
  static const String incoming = "Incoming";
  static const String outgoing = "Outgoing";

  // Profile
  static const String viewProfile = "View Profile";
  static const String name = "Name";
  static const String phone = "Phone";
  static const String address = "Address";

  // Settings
  static const String profile = "Profile";
  static const String theme = "Theme";
  static const String notification = 'Notifications';
  static const String settings = "Settings";
  static const String language = "Language";
  static const String selectLanguage = 'Select Language';
  static const String privacyPolicy = "Privacy & Policy";
  static const String darkmode = "Dark Mode";
  static const String exitTitle = "Are you sure you want to exit the app?";
  static const String logout = "Logout";
  static const String logoutTitle = "Log out";
  static const String logoutSureWarningMSg =
      "Are you sure you want to log out from your account?";
  static const String logoutSuccessMsg = 'Sign Out Successfully';

  // Operations
  static const String search = "Search";
  static const String viewAll = "View All";
  static const String submit = "Submit";
  static const String status = "Status";
  static const String fieldErrorMsg = "Please fill out this field";
  static const String badResponseMsg = 'Bad Response Format!';
  static const String serverError = 'Server Error';
  static const String unAuthorized = 'Unauthorized';
  static const String somethingWentWrong = 'Something went wrong';
  static const String noInternet = 'No internet connection';
  static const String noDataFound = 'Sorry! there are no data to show';
  static const String yes = "Yes";
  static const String no = "No";
  static const String close = "Đóng";
  static const String error = "Lỗi";
  static const String success = "Thành công";
  static const String warning = "Cảnh báo";
  static const String signFailedTitle = "Ký thất bại";
  static const String signSuccessTitle = "Ký thành công";

  // Contract
  static const String contracts = 'Contracts';
  static const String contract = 'Contract';
  static const String contractDetails = 'Contract Details';
  static const String contractValue = 'Contract Value';
  static const String startDate = 'Start Date';
  static const String endDate = 'End Date';
  static const String note = 'Note';

  // Estimate
  static const String estimates = 'Estimates';
  static const String estimate = 'Estimate';
  static const String estimateDetails = 'Estimate Details';
  static const String estimateDate = 'Estimate Date';
  static const String expiryDate = 'Expiry Date';
  static const String price = 'Price';
  static const String subtotal = 'Subtotal';
  static const String total = 'Total';
  static const String balanceDue = 'Balance Due';

  // Project
  static const String project = 'Project';
  static const String projects = 'Projects';
  static const String projectDetails = 'Project Details';
  static const String filter = 'Filter';
  static const String description = 'Description';
  static const String deadline = 'Deadline';
  static const String overview = 'Overview';
  static const String comment = 'Comment';
  static const String comments = 'Comments';
  static const String addComment = 'Add Comment';
  static const String tasks = 'Tasks';
  static const String taskDetails = 'Task Details';
  static const String taskTitle = 'Task Title';
  static const String assignedTo = 'Assigned To';

  // Invoice
  static const String invoice = 'Invoice';
  static const String invoices = 'Invoices';
  static const String invoiceDetails = 'Invoice Details';
  static const String billTo = 'Bill to';
  static const String invoiceDate = 'Invoice Date';
  static const String dueDate = 'Due Date';
  static const String totalPaid = 'Total Paid';
  static const String amountDue = 'Amount Due';
  static const String transactions = 'Transactions';
  static const String id = 'ID';
  static const String qty = 'Qty';
  static const String item = 'Item';
  static const String items = 'Items';
  static const String paymentMode = 'Payment Mode';
  static const String date = 'Date';
  static const String amount = 'Amount';
  static const String tax = 'Tax';
  static const String discount = 'Discount';
  static const String totalInvoiced = 'Total Invoiced';

  // Payments
  static const String payments = 'Payments';
  static const String payment = 'Payment';
  static const String paymentMethod = 'Payment Method';

  // Proposal
  static const String proposal = 'Proposal';
  static const String proposals = 'Proposals';
  static const String proposalDetails = 'Proposal Details';

  // Ticket
  static const String ticket = 'Ticket';
  static const String tickets = 'Tickets';
  static const String ticketDetails = 'Ticket Details';
  static const String title = 'Title';
  static const String openedBy = 'Opened By';
  static const String reply = 'Reply';
  static const String ticketType = 'Ticket Type';
  static const String selectTicketType = 'Select Ticket Type';
  static const String createNewTicket = 'Create New Ticket';
  static const String enterTicketSubject = 'Please, Enter Ticket Subject.';
  static const String enterTicketDescription =
      "Please, fill up Ticket Description field";
  static const String ticketComment = 'Add Ticket Comment';
  static const String ticketComments = 'Ticket Comments';
  static const String ticketMessage = 'Message';
  static const String enterTicketReply = 'Please, Enter Ticket Reply.';
  static const String attachment = "Attachment";
  static const String selectTicketAttachment = "No File Attached";

  // HR – Nghỉ phép
  static const String leaveApplications = "Đơn Nghỉ Phép";
  static const String leaveApplication = "Đơn Nghỉ Phép";
  static const String applyLeave = "Xin Nghỉ Phép";
  static const String leaveType = "Loại Nghỉ";
  static const String selectLeaveType = "Chọn Loại Nghỉ";
  static const String leaveReason = "Lý Do";
  static const String enterLeaveReason = "Nhập lý do nghỉ phép";
  static const String leaveStart = "Ngày Bắt Đầu";
  static const String leaveEnd = "Ngày Kết Thúc";
  static const String halfDay = "Nửa Ngày";
  static const String pending = "Chờ Duyệt";
  static const String approved = "Đã Duyệt";
  static const String rejected = "Từ Chối";
  static const String leaveDuration = "Thời Gian";
  static const String leaveSubmitted = "Đã Gửi Đơn Nghỉ Phép";

  // HR – Chấm công
  static const String attendance = "Chấm Công";
  static const String checkIn = "Chấm Vào";
  static const String checkOut = "Chấm Ra";
  static const String checkInTime = "Giờ Vào";
  static const String checkOutTime = "Giờ Ra";
  static const String workingHours = "Số Giờ Làm";
  static const String attendanceHistory = "Lịch Sử Chấm Công";
  static const String checkedIn = "Đã Chấm Vào";
  static const String notCheckedIn = "Chưa Chấm Vào";
  static const String alreadyCheckedOut = "Đã Chấm Ra";
  static const String checkInSuccess = "Chấm Vào Thành Công";
  static const String checkOutSuccess = "Chấm Ra Thành Công";
  static const String locationRequired = "Cần Quyền Truy Cập Vị Trí";

  // HR – Công tác
  static const String businessTrips = "Công Tác";
  static const String businessTrip = "Công Tác";
  static const String createBusinessTrip = "Tạo Đăng Ký Công Tác";
  static const String tripTitle = "Tên Chuyến Công Tác";
  static const String destination = "Điểm Đến";
  static const String tripPurpose = "Mục Đích";
  static const String tripStart = "Ngày Bắt Đầu";
  static const String tripEnd = "Ngày Kết Thúc";
  static const String totalDays = "Tổng Số Ngày";
  static const String totalAmount = "Tổng Phí";
  static const String tripNotes = "Ghi Chú";
  static const String tripSubmitted = "Đã Gửi Đăng Ký Công Tác";

  // HR menu
  static const String hrMenu = "Nghiệp Vụ HR";
  static const String myLeaves = "Nghỉ Phép Của Tôi";
  static const String myAttendance = "Chấm Công";
  static const String myBusinessTrips = "Công Tác Của Tôi";
}
