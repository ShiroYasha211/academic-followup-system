/// Thrown when a student attempts to log in from a device that is not
/// authorized for their account. Carries the admin's WhatsApp number
/// so the UI can show a direct-contact button.
class DeviceNotAuthorizedException implements Exception {
  const DeviceNotAuthorizedException({this.whatsappNumber});

  final String? whatsappNumber;

  @override
  String toString() =>
      'هذا الحساب مرتبط بجهاز آخر. يرجى التواصل مع الإدارة لتسجيل جهازك الجديد.';
}
