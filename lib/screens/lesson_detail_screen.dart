import 'dart:convert';
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
  bool _isLoading = true;
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
    _loadContents(); // ✅ tự fetch nội dung lesson
  }

  Future<void> _initializePlayer() async {
    final videoUrl = widget.lesson.videoUrl;
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
      final res = await repository.getLessonContents(widget.lesson.id);
      final list = (json.decode(res as String) as List)
          .map((x) => ContentItem.fromJson(x))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        widget.lesson.contents = list;
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
      return YoutubePlayer(controller: _youtubeController!, showVideoProgressIndicator: true);
    } else if (_chewieController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Chewie(controller: _chewieController!),
        ),
      );
    } else {
      return const Center(child: Text("Không thể phát video"));
    }
  }

  Widget _buildContentItem(ContentItem item) {
    switch (item.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(item.value, style: const TextStyle(fontSize: 16, height: 1.5)),
        );
      case 'image':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(item.value, fit: BoxFit.cover),
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
                child: Text(widget.lesson.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            _buildVideoPlayer(),
            const SizedBox(height: 20),
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
