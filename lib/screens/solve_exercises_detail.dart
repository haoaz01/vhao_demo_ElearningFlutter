import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../model/lesson_model.dart';
import '../model/exercise_model.dart';
import '../controllers/theory_controller.dart';

class SolveExercisesDetailScreen extends StatelessWidget {
  final int lessonId;
  final Color primaryGreen = const Color(0xFF4CAF50);
  final TheoryController theoryController = Get.find<TheoryController>();

  SolveExercisesDetailScreen({required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final Lesson? lesson = theoryController.getLessonById(lessonId);

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Bài tập",
            style: TextStyle(fontSize: 16.sp),
          ),
          backgroundColor: primaryGreen,
        ),
        body: Center(
          child: Text(
            "Không tìm thấy bài học.",
            style: TextStyle(fontSize: 16.sp),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Giải bài tập - ${lesson.title}",
          style: TextStyle(fontSize: 16.sp),
        ),
        backgroundColor: primaryGreen,
      ),
      body: lesson.exercises.isEmpty
          ? Center(
        child: Text(
          "Không có bài tập nào cho bài học này.",
          style: TextStyle(fontSize: 16.sp),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(12.w),
        itemCount: lesson.exercises.length,
        itemBuilder: (context, index) {
          final exercise = lesson.exercises[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Text(
                    "${index + 1}. ${exercise.question}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Solutions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: exercise.solutions.map((solution) {
                      if (solution.type.toLowerCase() == 'text') {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Text(
                            "- ${solution.value}",
                            style: TextStyle(fontSize: 15.sp),
                          ),
                        );
                      } else if (solution.type.toLowerCase() == 'image') {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Image.network(
                            solution.value,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(strokeWidth: 2.w),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.broken_image, size: 32.sp),
                          ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    }).toList(),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}