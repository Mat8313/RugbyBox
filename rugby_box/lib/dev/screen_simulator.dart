import 'package:flutter/material.dart';

/// Affiche l'app dans un cadre de la taille de l'écran du Pi, mis à
/// l'échelle de la fenêtre du PC, avec un bouton pour le faire pivoter.
/// Développement uniquement.
///
/// Taille par défaut : le Touch Display 2 (1280×720) avec un
/// `devicePixelRatio` de 1,5 (option `--pixelratio` de flutter-pi), soit
/// 853×480 pixels logiques.
class ScreenSimulator extends StatefulWidget {
  const ScreenSimulator({
    super.key,
    required this.child,
    this.landscapeSize = const Size(853, 480),
  });

  final Widget child;
  final Size landscapeSize;

  @override
  State<ScreenSimulator> createState() => _ScreenSimulatorState();
}

class _ScreenSimulatorState extends State<ScreenSimulator> {
  bool _isLandscape = true;

  @override
  Widget build(BuildContext context) {
    final size = _isLandscape
        ? widget.landscapeSize
        : widget.landscapeSize.flipped;

    // Hors de `MaterialApp` : pas de thème ni de sens d'écriture, on les
    // fournit à la main pour le bouton.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF3A3F4B),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FittedBox(
                  child: SizedBox.fromSize(
                    size: size,
                    child: ClipRect(
                      child: MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(size: size, devicePixelRatio: 1),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () => setState(() => _isLandscape = !_isLandscape),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isLandscape ? '⟳ Portrait' : '⟳ Paysage',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
