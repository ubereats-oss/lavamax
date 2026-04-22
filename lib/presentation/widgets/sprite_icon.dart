import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
/// Coordenadas de cada ícone dentro do sprite sheet services_sprite.png.
/// Gerado automaticamente — não editar manualmente.
const double _kIconSize = 96.0;
const Map<String, Offset> _kSpriteMap = {
  'customizacao':       Offset(0,   0),
  'funilaria':          Offset(96,  0),
  'higienizacao':       Offset(192, 0),
  'home_car_detail':    Offset(288, 0),
  'lavagem_premium':    Offset(0,   96),
  'limpeza_motor':      Offset(96,  96),
  'martelinho':         Offset(192, 96),
  'peliculas':          Offset(288, 96),
  'polimentos':         Offset(0,   192),
  'ppf':                Offset(96,  192),
  'restauracao_farois': Offset(192, 192),
  'rodas':              Offset(288, 192),
  'vitrificacao':       Offset(0,   288),
};
// Cache global da imagem — carregada uma única vez em toda a sessão.
ui.Image? _cachedSprite;
bool _loading = false;
final List<VoidCallback> _listeners = [];
Future<void> _loadSprite() async {
  if (_cachedSprite != null || _loading) return;
  _loading = true;
  final data = await rootBundle.load('assets/images/services_sprite.png');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  _cachedSprite = frame.image;
  _loading = false;
  for (final cb in _listeners) {
    cb();
  }
  _listeners.clear();
}
/// Exibe um ícone recortado do sprite sheet local services_sprite.png.
/// [iconKey] é o nome do arquivo sem extensão (ex: 'polimentos').
/// [size] é o tamanho de exibição em pixels lógicos.
class SpriteIcon extends StatefulWidget {
  final String iconKey;
  final double size;
  const SpriteIcon({
    super.key,
    required this.iconKey,
    this.size = 40,
  });
  @override
  State<SpriteIcon> createState() => _SpriteIconState();
}
class _SpriteIconState extends State<SpriteIcon> {
  @override
  void initState() {
    super.initState();
    if (_cachedSprite == null) {
      _listeners.add(() {
        if (mounted) setState(() {});
      });
      _loadSprite();
    }
  }
  @override
  Widget build(BuildContext context) {
    final offset = _kSpriteMap[widget.iconKey];
    final sprite = _cachedSprite;
    if (sprite == null || offset == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _SpritePainter(
        sprite: sprite,
        srcOffset: offset,
        iconSize: _kIconSize,
        destSize: widget.size,
      ),
    );
  }
}
class _SpritePainter extends CustomPainter {
  final ui.Image sprite;
  final Offset srcOffset;
  final double iconSize;
  final double destSize;
  const _SpritePainter({
    required this.sprite,
    required this.srcOffset,
    required this.iconSize,
    required this.destSize,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(srcOffset.dx, srcOffset.dy, iconSize, iconSize);
    final dst = Rect.fromLTWH(0, 0, destSize, destSize);
    canvas.drawImageRect(sprite, src, dst, Paint());
  }
  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.sprite != sprite || old.srcOffset != srcOffset || old.destSize != destSize;
}
