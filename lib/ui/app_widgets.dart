import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';

abstract final class AppAssets {
  static const welcome = 'assets/images/welcome.png';
  static const joinGroup = 'assets/images/join_group.png';
  static const tripCover = 'assets/images/trip_cover.png';
  static const imageFallback = 'assets/images/image_fallback.png';
}

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    this.asset,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String? asset;
  final String? imageUrl;
  final BoxFit fit;
  final String? semanticLabel;

  Widget _fallback() => Image.asset(
    AppAssets.imageFallback,
    fit: fit,
    semanticLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
  );

  Widget _localImage(String path) => Image.asset(
    path,
    fit: fit,
    semanticLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
    errorBuilder: (context, error, stackTrace) => _fallback(),
  );

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final local = asset;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        errorBuilder: (context, error, stackTrace) =>
            local == null ? _fallback() : _localImage(local),
      );
    }
    return local == null ? _fallback() : _localImage(local);
  }
}

class PendingStep22Screen extends StatelessWidget {
  const PendingStep22Screen(this.title, {super.key, this.embedded = false});

  final String title;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final message = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Text('$title is in development.', textAlign: TextAlign.center),
      ),
    );
    if (embedded) return message;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: message,
    );
  }
}
