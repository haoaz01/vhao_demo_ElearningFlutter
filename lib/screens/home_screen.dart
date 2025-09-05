import 'package:flutter/material.dart';
import 'package:flutter_elearning_application/controllers/auth_controller.dart';
import 'package:flutter_elearning_application/screens/subject_detail_screen.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  HomeScreen({super.key});

  final Map<String, IconData> subjectIcons = {
    'Toán': Icons.calculate,
    'Lý': Icons.science,
    'Văn': Icons.menu_book,
    'Anh': Icons.language,
  };

  final Map<String, Color> subjectColors = {
    'Toán': Colors.blue,
    'Lý': Colors.green,
    'Văn': Colors.orange,
    'Anh': Colors.purple,
  };

  void _showClassSelector() {
    Get.bottomSheet(
      Obx(() {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Chọn lớp học của bạn",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: authController.classes.map((String value) {
                  final isSelected =
                      authController.selectedClass.value == value;
                  return GestureDetector(
                    onTap: () {
                      authController.setSelectedClass(value);
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blueAccent
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                            : [],
                      ),
                      child: Text(
                        "Lớp $value",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (!authController.isClassSelected.value)
                const Text(
                  "⚠ Bạn phải chọn lớp để tiếp tục",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      }),
      isDismissible: false,
      enableDrag: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authController.isClassSelected.value) {
        _showClassSelector();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== Thanh tìm kiếm ==========
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Tìm kiếm môn học...",
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {},
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ========== Tiêu đề ==========
                Text(
                  "Xin chào, ${authController.username.value} 👋",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Chào mừng bạn quay trở lại E-learning App!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // ========== Dashboard Card ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDashboardCard(
                        title: "Quiz",
                        value: "12",
                        icon: Icons.quiz,
                        color: Colors.blue),
                    _buildDashboardCard(
                        title: "Videos",
                        value: "8",
                        icon: Icons.play_circle_fill,
                        color: Colors.green),
                    _buildDashboardCard(
                        title: "Điểm cao",
                        value: "95",
                        icon: Icons.star,
                        color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 20),

                // ========== Danh sách môn học ==========
                if (authController.isClassSelected.value) ...[
                  Text(
                    "Lớp ${authController.selectedClass.value}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: authController.subjects.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (context, index) {
                      final subject = authController.subjects[index];
                      return _buildSubjectCard(subject);
                    },
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  // ===== Dashboard Card =====
  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 35),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Card môn học =====
  Widget _buildSubjectCard(String subject) {
    return GestureDetector(
      onTap: () {
        final grade = int.tryParse(authController.selectedClass.value) ?? 0;
        Get.to(() => SubjectDetailScreen(grade: grade, subject: subject));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: subjectColors[subject]!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: subjectColors[subject]!.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: subjectColors[subject]!.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(subjectIcons[subject],
                color: subjectColors[subject], size: 30),
            const SizedBox(width: 8),
            Text(
              subject,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: subjectColors[subject],
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
