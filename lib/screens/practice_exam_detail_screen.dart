import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../controllers/pdf_controller.dart';

class PracticeExamDetailScreen extends StatelessWidget {
  final String fileName;
  final PdfController pdfController;

  PracticeExamDetailScreen({Key? key, required this.fileName})
      : pdfController = Get.put(PdfController(fileName)),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Implement download functionality if needed
            },
          ),
        ],
      ),
      body: Obx(() {
        if (pdfController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pdfController.errorMessage.isNotEmpty) {
          return Center(
            child: Text(
              pdfController.errorMessage.value,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (pdfController.pdfBytes.value.isEmpty) {
          return const Center(
            child: Text("Không thể tải tệp PDF"),
          );
        }

        return SfPdfViewer.memory(
          pdfController.pdfBytes.value,
          canShowScrollHead: true,
          canShowScrollStatus: true,
        );
      }),
    );
  }
}