// controllers/search_controller.dart
import 'package:get/get.dart';
import '../model/lesson_model.dart';
import '../repositories/search_repository.dart';

class SearchController extends GetxController {
  final SearchRepository _searchRepository = SearchRepository();

  var searchResults = <Lesson>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var selectedSubjectId = Rx<int?>(null);
  var selectedGrade = Rx<int?>(null);

  Future<void> searchLessons(String keyword, {int? subjectId, int? grade}) async {
    try {
      isLoading(true);
      errorMessage('');
      final results = await _searchRepository.searchLessons(
          keyword,
          subjectId: subjectId,
          grade: grade
      );
      searchResults.assignAll(results);
    } catch (e) {
      errorMessage('Lỗi tìm kiếm: $e');
      searchResults.clear();
    } finally {
      isLoading(false);
    }
  }

  void setSelectedSubject(int? subjectId) {
    selectedSubjectId.value = subjectId;
  }

  void setSelectedGrade(int? grade) {
    selectedGrade.value = grade;
  }

  void clearSearch() {
    searchResults.clear();
    errorMessage('');
    selectedSubjectId.value = null;
    selectedGrade.value = null;
  }
}