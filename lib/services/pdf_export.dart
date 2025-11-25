// Conditional export for PDF service
export 'pdf_service.dart'
    if (dart.library.html) 'pdf_service_web.dart';
