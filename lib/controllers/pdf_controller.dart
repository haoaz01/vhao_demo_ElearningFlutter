import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class PdfController extends GetxController {
  final Dio _dio = Dio();
  final String fileName;

  PdfController(this.fileName);

  Rx<Uint8List> pdfBytes = Rx<Uint8List>(Uint8List(0));
  RxBool isLoading = true.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPdf(fileName);
  }

  String _getBaseUrl() {
    if (kIsWeb) {
      return "http://192.168.1.50:8080/api";
    } else if (Platform.isAndroid) {
      if (_isGenymotion()) {
        return "http://192.168.1.50:8080/api";
      } else if (_isEmulator()) {
        return "http://192.168.1.50:8080/api";
      } else {
        return "http://192.168.1.50:8080/api";
      }
    } else if (Platform.isIOS) {
      return "http://localhost:8080/api";
    } else {
      return "http://192.168.1.50:8080/api";
    }
  }

  bool _isEmulator() {
    return Platform.isAndroid &&
        (Platform.environment.containsKey('EMULATOR_DEVICE') ||
            Platform.environment.containsKey('ANDROID_EMULATOR'));
  }

  bool _isGenymotion() {
    return Platform.isAndroid &&
        Platform.environment.containsKey('GENYMOTION');
  }

  Future<void> fetchPdf(String fileName) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final baseUrl = _getBaseUrl();
      final url = '$baseUrl/pdf/$fileName';

      print('Fetching PDF from: $url');

      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/pdf',
          },
        ),
      );

      if (response.statusCode == 200) {
        pdfBytes.value = Uint8List.fromList(response.data);
        print('PDF loaded successfully, size: ${pdfBytes.value.length} bytes');
      } else {
        errorMessage.value = 'Không thể tải PDF: ${response.statusCode}';
        print('Error loading PDF: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage.value = 'Kết nối quá hạn. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage.value = 'Mất kết nối đến máy chủ.';
      } else if (e.response != null) {
        errorMessage.value = 'Lỗi từ máy chủ: ${e.response?.statusCode}';
      } else {
        errorMessage.value = 'Lỗi khi tải PDF: ${e.message}';
      }
    } catch (e) {
      print('Unexpected error: $e');
      errorMessage.value = 'Lỗi không xác định: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void retry() {
    fetchPdf(fileName);
  }
}
