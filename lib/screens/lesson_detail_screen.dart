import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../controllers/auth_controller.dart';
import '../model/lesson_content_model.dart';
import '../model/lesson_model.dart';
import '../repositories/subject_repository.dart';
import '../controllers/theory_controller.dart';
import '../controllers/progress_controller.dart'; // THÊM IMPORT NÀY

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  LessonDetailScreen({required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  final TheoryController theoryController = Get.find<TheoryController>();
  final ProgressController progressController = Get.find<ProgressController>(); // THÊM DÒNG NÀY
  final SubjectRepository repository = SubjectRepository();
  final AuthController authController = Get.find<AuthController>();
  bool _isLoading = false;
  bool _isYoutube = false;
  late AnimationController _animController;
  bool _isCompleted = false;
  bool _updated = false;
  bool _isCompleting = false; // THÊM BIẾN MỚI ĐỂ THEO DÕI TRẠNG THÁI ĐANG HOÀN THÀNH

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _loadCompletionStatus(); // THAY ĐỔI: Gọi hàm mới để tải trạng thái từ server
    _initializePlayer();

    if (widget.lesson.contents.isEmpty) {
      _loadContents();
    }
  }

  // HÀM MỚI: Tải trạng thái hoàn thành từ server
  Future<void> _loadCompletionStatus() async {
    try {
      // Ưu tiên kiểm tra từ server trước
      final serverCompleted = await progressController.isLessonCompleted(widget.lesson.id);

      // Đồng bộ với local storage
      final localCompleted = theoryController.isCompleted(
        theoryController.subject,
        theoryController.grade,
        widget.lesson.title,
      );

      // Nếu khác nhau, cập nhật local theo server
      if (serverCompleted != localCompleted) {
        if (serverCompleted) {
          theoryController.markAsCompleted(
            theoryController.subject,
            theoryController.grade,
            widget.lesson.title,
          );
        } else {
          theoryController.markAsUncompleted(
            theoryController.subject,
            theoryController.grade,
            widget.lesson.title,
          );
        }
      }

      setState(() {
        _isCompleted = serverCompleted;
      });
    } catch (e) {
      print("Error loading completion status from server: $e");
      // Fallback: sử dụng local storage nếu API fail
      setState(() {
        _isCompleted = theoryController.isCompleted(
          theoryController.subject,
          theoryController.grade,
          widget.lesson.title,
        );
      });
    }
  }

  Future<void> _initializePlayer() async {
    final videoUrl = widget.lesson.videoUrl;

    if (videoUrl.isEmpty) {
      return;
    }

    String cleanUrl = videoUrl.split('&t=')[0];
    final videoId = YoutubePlayer.convertUrlToId(cleanUrl);

    if (videoId != null) {
      _isYoutube = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    } else {
      try {
        _videoController = VideoPlayerController.network(videoUrl);
        await _videoController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoController!.value.aspectRatio,
        );
      } catch (e) {
        print("Error initializing video: $e");
      }
    }
    setState(() {});
  }

  Future<void> _loadContents() async {
    try {
      setState(() => _isLoading = true);
      final List<LessonContent> contentItems = await repository.getLessonContents(widget.lesson.id);
      setState(() {
        widget.lesson.contents = contentItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    _animController.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    if (_isYoutube && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
      );
    } else if (_chewieController != null && _videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Chewie(controller: _chewieController!),
        ),
      );
    } else if (widget.lesson.videoUrl.isNotEmpty) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2.w),
              SizedBox(height: 8.h),
              Text(
                "Đang tải video...",
                style: TextStyle(fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildContentItem(LessonContent item) {
    switch (item.type) {
      case 'TEXT':
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            item.value,
            style: TextStyle(
              fontSize: 16.sp,
              height: 1.5,
            ),
          ),
        );
      case 'IMAGE':
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.network(
              item.value,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200.h,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 32.sp),
                        SizedBox(height: 8.h),
                        Text(
                          "Lỗi tải hình ảnh",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // HÀM MỚI: Xử lý hoàn thành bài học với API
  Future<void> _toggleCompletion() async {
    if (_isCompleting) return; // Ngăn chặn nhiều lần nhấn

    // Debug log - SỬA LẠI: sử dụng getter đúng
    print('🎯 Toggle completion for lesson: ${widget.lesson.id}');
    print('📊 Current auth status:');
    print('   - UserId: ${progressController.userId.value}'); // SỬA: .value
    print('   - IsLoggedIn: ${progressController.isLoggedIn.value}'); // SỬA: .value

    setState(() {
      _isCompleting = true;
    });

    try {
      if (_isCompleted) {
        // Hủy hoàn thành
        await progressController.uncompleteLesson(widget.lesson.id);
        theoryController.markAsUncompleted(
          theoryController.subject,
          theoryController.grade,
          widget.lesson.title,
        );
      } else {
        // Đánh dấu hoàn thành
        await progressController.completeLesson(widget.lesson.id);
        theoryController.markAsCompleted(
          theoryController.subject,
          theoryController.grade,
          widget.lesson.title,
        );
      }

      setState(() {
        _isCompleted = !_isCompleted;
        _updated = true;
      });

      Get.snackbar(
        'Thành công',
        _isCompleted ? 'Đã đánh dấu bài học hoàn thành' : 'Đã hủy đánh dấu hoàn thành',
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật trạng thái: ${e.toString()}',
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      theoryController.toggleComplete(
        theoryController.subject,
        theoryController.grade,
        widget.lesson.title,
      );

      setState(() {
        _isCompleted = theoryController.isCompleted(
          theoryController.subject,
          theoryController.grade,
          widget.lesson.title,
        );
      });
    } finally {
      setState(() {
        _isCompleting = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF4CAF50);

    return WillPopScope(
      onWillPop: () async {
        Get.back(result: _updated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.lesson.title,
            style: TextStyle(fontSize: 16.sp),
          ),
          backgroundColor: primaryGreen,
        ),
        body: _isLoading
            ? Center(
          child: CircularProgressIndicator(strokeWidth: 2.w),
        )
            : SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: widget.lesson.title,
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    widget.lesson.title,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              if (widget.lesson.videoUrl.isNotEmpty) _buildVideoPlayer(),
              if (widget.lesson.videoUrl.isNotEmpty) SizedBox(height: 20.h),

              ...widget.lesson.contents.map(_buildContentItem).toList(),
              SizedBox(height: 24.h),

              Center(
                child: ScaleTransition(
                  scale: _animController,
                  child: ElevatedButton.icon(
                    onPressed: _isCompleting ? null : _toggleCompletion, // SỬA: dùng hàm mới
                    icon: _isCompleting
                        ? SizedBox(
                      width: 20.sp,
                      height: 20.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Icon(
                      _isCompleted ? Icons.check_circle : Icons.done_all_outlined,
                      size: 20.sp,
                    ),
                    label: Text(
                      _isCompleting
                          ? "Đang xử lý..."
                          : (_isCompleted ? "Đã hoàn thành" : "Đánh dấu hoàn thành"),
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted ? Colors.green : primaryGreen,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}