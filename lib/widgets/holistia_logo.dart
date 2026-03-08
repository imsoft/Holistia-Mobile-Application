import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/assets.dart';

/// Logo de Holistia. Elige automáticamente light/dark según el tema.
class HolistiaLogo extends StatelessWidget {
  const HolistiaLogo({
    super.key,
    this.width = 120,
    this.height,
    this.fit = BoxFit.contain,
    this.usePrimary = false,
  });

  /// Ancho deseado.
  final double width;

  /// Alto deseado. Si null, se mantiene la proporción.
  final double? height;

  /// Ajuste de la imagen.
  final BoxFit fit;

  /// Si true, usa logo_holistia (blanco sobre violeta). Si false, usa light/dark según tema.
  final bool usePrimary;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final String asset;
    if (usePrimary) {
      asset = Assets.logoHolistia;
    } else {
      asset = brightness == Brightness.dark
          ? Assets.logoHolistiaDark
          : Assets.logoHolistiaLight;
    }
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
