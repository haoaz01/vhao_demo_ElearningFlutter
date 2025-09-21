import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../model/practice_exam_model.dart';

class PracticeExamController extends GetxController {
  final Dio _dio = Dio();
  final RxList<PracticeExam> exams = <PracticeExam>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  Future<void> loadExams(String subject, String grade, {String? examType}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      String formattedSubject = _convertSubjectToApiFormat(subject);
      String url = 'http://192.168.0.144:8080/api/pdf/list?subject=$formattedSubject&grade=$grade';

      if (examType != null) {
        url += '&examType=$examType';
      }

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        exams.value = (response.data as List)
            .map((item) => PracticeExam.fromJson(item))
            .toList();
      } else {
        errorMessage.value = 'Failed to load exams: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error loading exams: $e';
      print('Error details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _convertSubjectToApiFormat(String subject) {
    switch (subject.toLowerCase()) {
      case 'toán':
        return 'toan';
      case 'khoa học tự nhiên':
        return 'khoahoctunhien';
      case 'ngữ văn':
        return 'nguvan';
      case 'tiếng anh':
        return 'tienganh';
      default:
        return subject.toLowerCase();
    }
  }
}
