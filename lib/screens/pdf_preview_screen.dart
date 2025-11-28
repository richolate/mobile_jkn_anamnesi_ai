import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';

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

  Future<void> _sharePdf() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/${widget.fileName}');
      await file.writeAsBytes(widget.pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: widget.title,
        text: 'Laporan dari Mobile JKN Anamnesa AI',
      );
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
          // Share button
          IconButton(
            onPressed: _isProcessing ? null : _sharePdf,
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
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
                onPressed: _isProcessing ? null : _sharePdf,
                icon: const Icon(Icons.share),
                label: const Text('Share PDF'),
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
