// SearchScreen
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        title: Text(
          'Tìm kiếm Bài học',
          style: TextStyle(fontSize: 18.sp),
        ),
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
      padding: EdgeInsets.all(16.0.w),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Nhập từ khóa tìm kiếm...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
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
        padding: EdgeInsets.all(16.0.w),
        child: Row(
          children: [
            Text(
              'Lọc theo môn: ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(width: 10.w),
            DropdownButton<int?>(
              value: searchController.selectedSubjectId.value,
              hint: Text('Tất cả môn', style: TextStyle(fontSize: 14.sp)),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('Tất cả môn', style: TextStyle(fontSize: 14.sp)),
                ),
                ...authController.subjects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subject = entry.value;
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(subject, style: TextStyle(fontSize: 14.sp)),
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
        return Center(child: CircularProgressIndicator());
      }

      if (searchController.errorMessage.isNotEmpty) {
        return Center(
          child: Text(
            searchController.errorMessage.value,
            style: TextStyle(color: Colors.red, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        );
      }

      if (searchController.searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon/icon_search.png',
                width: 64.w,
                height: 64.h,
              ),
              SizedBox(height: 16.h),
              Text(
                'Nhập từ khóa để tìm kiếm bài học',
                style: TextStyle(color: Colors.grey, fontSize: 16.sp),
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
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListTile(
        leading: Icon(Icons.play_circle_outline, color: Colors.blue, size: 24.w),
        title: Text(
          lesson.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lesson.subjectName != null)
              Text(
                'Môn: ${lesson.subjectName}',
                style: TextStyle(fontSize: 12.sp),
              ),
            if (lesson.chapterName != null)
              Text(
                'Chương: ${lesson.chapterName}',
                style: TextStyle(fontSize: 12.sp),
              ),
            if (lesson.grade != null)
              Text(
                'Lớp: ${lesson.grade}',
                style: TextStyle(fontSize: 12.sp),
              ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16.w),
        onTap: () {
          Get.toNamed(AppRoutes.lessonDetail, arguments: {'lesson': lesson});
        },
      ),
    );
  }
}