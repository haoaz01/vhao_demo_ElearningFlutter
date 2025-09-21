import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../controllers/pdf_controller.dart';

class PracticeExamDetailScreen extends StatelessWidget {
  final String fileName;

  PracticeExamDetailScreen({Key? key, required this.fileName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PdfController pdfController = Get.put(PdfController(fileName));

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              pdfController.retry();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (pdfController.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải tệp PDF...'),
              ],
            ),
          );
        }

        if (pdfController.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  pdfController.errorMessage.value,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    pdfController.retry();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (pdfController.pdfBytes.value.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 48),
                SizedBox(height: 16),
                Text(
                  "Không thể tải tệp PDF",
                  style: TextStyle(color: Colors.orange, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return SfPdfViewer.memory(
          pdfController.pdfBytes.value,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
        );
      }),
    );
  }
}