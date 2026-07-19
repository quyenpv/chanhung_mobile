/// Converts status codes returned by the DMS API into Vietnamese labels.
///
/// The API can return the same value with different casing or whitespace, so
/// status labels are normalized before being displayed.
String dmsStatusLabel(String? status) {
  switch (status?.trim().toLowerCase()) {
    case 'draft':
      return 'Bản nháp';
    case 'pending':
      return 'Chờ duyệt';
    case 'processing':
      return 'Đang xử lý';
    case 'completed':
      return 'Hoàn thành';
    case 'published':
      return 'Đã ban hành';
    case 'cancelled':
      return 'Đã hủy';
    case 'waiting':
      return 'Chờ ký';
    case 'signed':
      return 'Đã ký';
    case 'reviewing':
      return 'Đang xem xét';
    case 'rejected':
      return 'Từ chối';
    case 'success':
      return 'Thành công';
    case 'failed':
      return 'Thất bại';
    case 'expired':
      return 'Đã hết hạn';
    default:
      return status?.trim() ?? '';
  }
}

String dmsSignerActionLabel(String? action) {
  switch (action?.trim().toLowerCase()) {
    case 'sign':
      return 'Ký duyệt';
    case 'flash_sign':
      return 'Ký nháy';
    case 'review':
      return 'Xem xét';
    case 'approval':
      return 'Phê duyệt';
    case 'release':
      return 'Phát hành';
    case 'initial':
      return 'Ký nháy';
    default:
      return action?.trim() ?? '';
  }
}
