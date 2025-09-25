import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/theory_controller.dart';

class TheoryScreen extends StatelessWidget {
  final String subject;
  final int grade;
  final String mode;
  final Color primaryGreen = const Color(0xFF4CAF50);

  TheoryScreen({Key? key, required this.subject, required this.grade})
      : mode = Get.arguments?['mode'] ?? 'theory',
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final TheoryController theoryController = Get.put(TheoryController());
    theoryController.loadTheory(subject, grade);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          mode == 'theory'
              ? "Lý thuyết $subject - Khối $grade"
              : "Giải bài tập $subject - Khối $grade",
          style: TextStyle(fontSize: 16.sp),
        ),
        backgroundColor: primaryGreen,
      ),
      body: Obx(() {
        if (theoryController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
            ),
          );
        }

        if (theoryController.chapters.isEmpty) {
          return Center(
            child: Text(
              "Chưa có dữ liệu cho môn học này",
              style: TextStyle(fontSize: 16.sp),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(12.w),
          itemCount: theoryController.chapters.length,
          itemBuilder: (context, index) {
            final chapter = theoryController.chapters[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: primaryGreen,
                  radius: 20.r,
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                title: Text(
                  chapter.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp
                  ),
                ),
                children: List.generate(chapter.lessons.length, (lessonIndex) {
                  final lesson = chapter.lessons[lessonIndex];
                  final isDone = theoryController.isCompleted(
                      theoryController.subject,
                      theoryController.grade,
                      lesson.title
                  );
                  return ListTile(
                    leading: Hero(
                      tag: lesson.title,
                      child: Icon(
                        Icons.menu_book,
                        size: 24.sp,
                        color: isDone ? primaryGreen : Colors.blue,
                      ),
                    ),
                    title: Text(
                      lesson.title,
                      style: TextStyle(
                        color: isDone ? primaryGreen : Colors.black87,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    trailing: Icon(
                      isDone ? Icons.check_circle : Icons.arrow_forward_ios,
                      size: 20.sp,
                      color: isDone ? Colors.green : Colors.grey,
                    ),
                    onTap: () async {
                      if (mode == 'theory') {
                        final result = await Get.toNamed(
                          AppRoutes.lessonDetail,
                          arguments: {'lesson': lesson},
                        );
                        if (result == true) {
                          theoryController.loadTheory(subject, grade);
                        }
                      } else {
                        await Get.toNamed(
                          AppRoutes.solveExercisesDetail,
                          arguments: {'lessonId': lesson.id},
                        );
                      }
                    },
                  );
                }),
              ),
            );
          },
        );
      }),
    );
  }
}
