import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PdfPreviewScreen extends StatefulWidget {
  final String title;
  final Uint8List pdfBytes;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isProcessing = false;

  void _downloadPdf() {
    setState(() {
      _isProcessing = true;
    });

    try {
      final blob = html.Blob([widget.pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', widget.fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF berhasil diunduh!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _printPdf() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => widget.pdfBytes,
        name: widget.fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Print button
          IconButton(
            onPressed: _isProcessing ? null : _printPdf,
            icon: const Icon(Icons.print),
            tooltip: 'Print PDF',
          ),
          // Download button
          IconButton(
            onPressed: _isProcessing ? null : _downloadPdf,
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF Preview
          PdfPreview(
            build: (format) => widget.pdfBytes,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            pdfFileName: widget.fileName,
            loadingWidget: const Center(child: CircularProgressIndicator()),
          ),
          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memproses...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _printPdf,
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _downloadPdf,
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
