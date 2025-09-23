// screens/search_screen.dart
import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../model/lesson_model.dart';
import '../controllers/search_controller.dart';

class SearchScreen extends StatelessWidget {
  final SearchController searchController = Get.put(SearchController());
  final AuthController authController = Get.find<AuthController>();
  final Color primaryGreen = const Color(0xFF4CAF50);
  SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm Bài học'),
        backgroundColor: primaryGreen,
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          _buildFilterSection(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Nhập từ khóa tìm kiếm...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onChanged: (value) {
          if (value.length >= 2) {
            _performSearch(value);
          } else if (value.isEmpty) {
            searchController.clearSearch();
          }
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _performSearch(value);
          }
        },
      ),
    );
  }

  void _performSearch(String keyword) {
    final grade = int.tryParse(authController.selectedClass.value);
    searchController.searchLessons(
      keyword,
      subjectId: searchController.selectedSubjectId.value,
      grade: grade,
    );
  }

  Widget _buildFilterSection() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Text('Lọc theo môn: ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            DropdownButton<int?>(
              value: searchController.selectedSubjectId.value,
              hint: const Text('Tất cả môn'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả môn')),
                ...authController.subjects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subject = entry.value;
                  return DropdownMenuItem(
                    value: index + 1, // giả sử ID bắt đầu từ 1
                    child: Text(subject),
                  );
                }),
              ],
              onChanged: (value) {
                searchController.setSelectedSubject(value);
                final currentKeyword = _getCurrentSearchKeyword();
                _performSearchWithCurrentFilters(currentKeyword);
              },
            ),
          ],
        ),
      );
    });
  }

  String _getCurrentSearchKeyword() {
    // Nếu muốn lưu keyword hiện tại thì thêm TextEditingController
    return '';
  }

  void _performSearchWithCurrentFilters(String keyword) {
    final grade = int.tryParse(authController.selectedClass.value);
    searchController.searchLessons(
      keyword,
      subjectId: searchController.selectedSubjectId.value,
      grade: grade,
    );
  }

  Widget _buildResults() {
    return Obx(() {
      if (searchController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (searchController.errorMessage.isNotEmpty) {
        return Center(
          child: Text(
            searchController.errorMessage.value,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        );
      }

      if (searchController.searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icon/icon_search.png', width: 64, height: 64),
              const SizedBox(height: 16),
              const Text(
                'Nhập từ khóa để tìm kiếm bài học',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: searchController.searchResults.length,
        itemBuilder: (context, index) {
          final lesson = searchController.searchResults[index];
          return _buildLessonCard(lesson);
        },
      );
    });
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline, color: Colors.blue),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lesson.subjectName != null)
              Text('Môn: ${lesson.subjectName}'),
            if (lesson.chapterName != null)
              Text('Chương: ${lesson.chapterName}'),
            if (lesson.grade != null)
              Text('Lớp: ${lesson.grade}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Get.toNamed(AppRoutes.lessonDetail, arguments: {'lesson': lesson});
        },
      ),
    );
  }
}
