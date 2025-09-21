import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../model/content_item_model.dart';
import '../model/lesson_model.dart';
import '../repositories/subject_repository.dart';
import '../controllers/theory_controller.dart';

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
  final SubjectRepository repository = SubjectRepository();
  bool _isLoading = false; // Đã có contents nên không cần loading ban đầu
  bool _isYoutube = false;
  late AnimationController _animController;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _isCompleted = theoryController.isCompleted(
      theoryController.subject,
      theoryController.grade,
      widget.lesson.title,
    );

    _initializePlayer();

    // Nếu lesson đã có contents từ API trước đó, không cần load lại
    if (widget.lesson.contents.isEmpty) {
      _loadContents();
    }
  }

  Future<void> _initializePlayer() async {
    final videoUrl = widget.lesson.videoUrl;

    // Debug: In ra videoUrl để kiểm tra
    print("Initializing video player with URL: $videoUrl");

    if (videoUrl.isEmpty) {
      print("Video URL is empty");
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

      final List<ContentItem> contentItems = await repository.getLessonContents(widget.lesson.id);

      setState(() {
        widget.lesson.contents = contentItems;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading lesson contents: $e");
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
          borderRadius: BorderRadius.circular(16),
          child: Chewie(controller: _chewieController!),
        ),
      );
    } else if (widget.lesson.videoUrl.isNotEmpty) {
      // Hiển thị placeholder nếu có video URL nhưng chưa khởi tạo xong
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text("Đang tải video..."),
            ],
          ),
        ),
      );
    } else {
      // Ẩn hoàn toàn phần video nếu không có video
      return SizedBox.shrink();
    }
  }

  Widget _buildContentItem(ContentItem item) {
    switch (item.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
              item.value,
              style: const TextStyle(fontSize: 16, height: 1.5)
          ),
        );
      case 'image':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              item.value,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
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
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(height: 8),
                        Text("Lỗi tải hình ảnh"),
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

  void _toggleCompletion() {
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
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: primaryGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: widget.lesson.title,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  widget.lesson.title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Chỉ hiển thị video player nếu có video URL
            if (widget.lesson.videoUrl.isNotEmpty) _buildVideoPlayer(),
            if (widget.lesson.videoUrl.isNotEmpty) const SizedBox(height: 20),

            ...widget.lesson.contents.map(_buildContentItem).toList(),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _animController,
              child: ElevatedButton.icon(
                onPressed: _isCompleted ? null : _toggleCompletion,
                icon: Icon(
                  _isCompleted ? Icons.check_circle : Icons.done_all_outlined,
                ),
                label: Text(
                  _isCompleted ? "Đã hoàn thành" : "Đánh dấu hoàn thành",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCompleted ? Colors.green : primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}