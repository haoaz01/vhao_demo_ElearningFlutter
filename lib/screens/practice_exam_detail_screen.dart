import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        title: Text(
          fileName,
          style: TextStyle(fontSize: 16.sp),
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 24.sp),
            onPressed: () {
              pdfController.retry();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (pdfController.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 2.w),
                SizedBox(height: 16.h),
                Text(
                  'Đang tải tệp PDF...',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          );
        }

        if (pdfController.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
                SizedBox(height: 16.h),
                Text(
                  pdfController.errorMessage.value,
                  style: TextStyle(color: Colors.red, fontSize: 16.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    pdfController.retry();
                  },
                  child: Text(
                    'Thử lại',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          );
        }

        if (pdfController.pdfBytes.value.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 48.sp),
                SizedBox(height: 16.h),
                Text(
                  "Không thể tải tệp PDF",
                  style: TextStyle(color: Colors.orange, fontSize: 16.sp),
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