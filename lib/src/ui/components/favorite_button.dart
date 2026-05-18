import 'package:flutter/material.dart';
import '../../services/favorites_service.dart';

/// An icon button that toggles the favorite state of a scan result.
/// Manages its own async state internally.
class FavoriteButton {
  FavoriteButton._();

  /// Returns a stateful [FavoriteIconButton] for the given [rawValue].
  static Widget forValue(String rawValue, {Color? activeColor}) =>
      _FavoriteIconButton(rawValue: rawValue, activeColor: activeColor);
}

class _FavoriteIconButton extends StatefulWidget {
  final String rawValue;
  final Color? activeColor;

  const _FavoriteIconButton({required this.rawValue, this.activeColor});

  @override
  State<_FavoriteIconButton> createState() => _FavoriteIconButtonState();
}

class _FavoriteIconButtonState extends State<_FavoriteIconButton>
    with SingleTickerProviderStateMixin {
  bool _isFav = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _load();
  }

  Future<void> _load() async {
    final fav = await FavoritesService.isFavorite(widget.rawValue);
    if (mounted) setState(() => _isFav = fav);
  }

  Future<void> _toggle() async {
    await FavoritesService.toggle(widget.rawValue);
    if (!mounted) return;
    setState(() => _isFav = !_isFav);
    _ctrl.forward().then((_) => _ctrl.reverse());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor ?? Colors.amber;
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        icon: Icon(
          _isFav ? Icons.bookmark : Icons.bookmark_border,
          color: _isFav ? active : null,
        ),
        tooltip: _isFav ? 'Remove from favorites' : 'Add to favorites',
        onPressed: _toggle,
      ),
    );
  }
}
