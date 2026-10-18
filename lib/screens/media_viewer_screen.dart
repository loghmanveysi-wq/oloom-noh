// نمایش تمام‌صفحه‌ی تصویر (با زوم) و پخش ویدیو
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class ImageViewerScreen extends StatelessWidget {
  final String url;

  const ImageViewerScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({super.key, required this.url, this.title = ''});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _c;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _c.play();
    }).catchError((_) {
      if (mounted) setState(() => _error = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title.isEmpty ? 'ویدیو' : widget.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: _error
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'پخش ویدیو ممکن نشد. اینترنت را بررسی کنید یا ویدیو را با فرمت MP4 آپلود کنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              )
            : !_c.value.isInitialized
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(aspectRatio: _c.value.aspectRatio, child: VideoPlayer(_c)),
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _c,
                        builder: (context, v, _) => Column(
                          children: [
                            VideoProgressIndicator(
                              _c,
                              allowScrubbing: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_fmt(v.position), style: const TextStyle(color: Colors.white70)),
                                const SizedBox(width: 8),
                                IconButton(
                                  color: Colors.white,
                                  icon: const Icon(Icons.replay_10),
                                  onPressed: () => _c.seekTo(v.position - const Duration(seconds: 10)),
                                ),
                                IconButton(
                                  color: Colors.white,
                                  iconSize: 48,
                                  icon: Icon(v.isPlaying ? Icons.pause_circle : Icons.play_circle),
                                  onPressed: () => v.isPlaying ? _c.pause() : _c.play(),
                                ),
                                IconButton(
                                  color: Colors.white,
                                  icon: const Icon(Icons.forward_10),
                                  onPressed: () => _c.seekTo(v.position + const Duration(seconds: 10)),
                                ),
                                const SizedBox(width: 8),
                                Text(_fmt(v.duration), style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
