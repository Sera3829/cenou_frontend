import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Librairie de squelettes de chargement (« shimmer ») à l'image du contenu,
/// façon Facebook — remplace les CircularProgressIndicator pendant le chargement.
///
/// Architecture : les fonds de cartes / conteneurs sont peints normalement
/// (statiques), et seul l'INTÉRIEUR (les formes grises de placeholder) est
/// enveloppé dans un [Shimmer]. Ainsi la bande lumineuse balaie uniquement les
/// formes, pas les fonds — le rendu ressemble bien à « du contenu en cours de
/// chargement dans une vraie carte », et non à un bloc gris uniforme.

// ════════════════════════════════════════════════════════════════════════
// Base : effet shimmer + primitives + carte
// ════════════════════════════════════════════════════════════════════════

/// Fait balayer une bande lumineuse sur les formes opaques de son [child].
/// (Le ShaderMask ne colore que les pixels opaques ; les zones transparentes
/// entre les formes restent transparentes.)
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF2E2E33) : const Color(0xFFE4E7EC);
    final highlight = dark ? const Color(0xFF3C3C44) : const Color(0xFFF4F6F9);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
              transform: _ShimmerSlide(_controller.value * 2 - 1),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Translation horizontale du dégradé pour l'effet de balayage.
class _ShimmerSlide extends GradientTransform {
  final double percent; // -1 → 1
  const _ShimmerSlide(this.percent);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}

/// Forme opaque grise ; sa couleur est remplacée par le dégradé du [Shimmer]
/// parent. Sa couleur propre ne sert que de repli hors shimmer.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? radius;
  final bool circle;
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: circle ? (width ?? height) : height,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2E2E33) : const Color(0xFFE4E7EC),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : (radius ?? BorderRadius.circular(8)),
      ),
    );
  }
}

/// Ligne fine (placeholder de texte).
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  const SkeletonLine({super.key, this.width, this.height = 12});
  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: width, height: height, radius: BorderRadius.circular(6));
}

/// Carte statique (fond + bordure cohérents avec l'app) dont l'intérieur
/// shimmer. C'est le conteneur de base de la plupart des squelettes.
class _SkeletonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _SkeletonCard({required this.child, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Shimmer(child: child),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 1. Tableau de données — Paiements / Signalements / Utilisateurs
// ════════════════════════════════════════════════════════════════════════

class SkeletonDataTable extends StatelessWidget {
  final int rows;
  final int columns;
  const SkeletonDataTable({super.key, this.rows = 8, this.columns = 5});

  @override
  Widget build(BuildContext context) {
    // Conteneur statique + intérieur (en-tête + lignes) en shimmer.
    return LayoutBuilder(builder: (context, constraints) {
      // Remplit la hauteur disponible quand elle est bornée (ex. écran users) ;
      // sinon (dans un sliver, hauteur infinie) on garde `rows` par défaut.
      var rowCount = rows;
      if (constraints.maxHeight.isFinite && constraints.maxHeight > 120) {
        final fit = ((constraints.maxHeight - 56) / 51).floor();
        if (fit > rowCount) rowCount = fit;
      }
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // En-tête (formes seulement, pas de fond opaque -> ne masque rien)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  for (int i = 0; i < columns; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SkeletonLine(width: 64, height: 11),
                      ),
                    ),
                  const SizedBox(width: 72),
                ],
              ),
            ),
            // Lignes
            for (int r = 0; r < rowCount; r++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    for (int c = 0; c < columns; c++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: c == columns - 1
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: SkeletonBox(
                                      width: 74,
                                      height: 22,
                                      radius: BorderRadius.circular(20)),
                                )
                              : SkeletonLine(width: c == 0 ? 90 : 130),
                        ),
                      ),
                    SizedBox(
                      width: 72,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          SkeletonBox(width: 18, height: 18, circle: true),
                          SizedBox(width: 12),
                          SkeletonBox(width: 18, height: 18, circle: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════════════
// 2. Tableau de bord — sections (KPI + graphique)
// ════════════════════════════════════════════════════════════════════════

/// Grille de KPI (section « statistiques » du tableau de bord).
class SkeletonStatsGrid extends StatelessWidget {
  final int count;
  const SkeletonStatsGrid({super.key, this.count = 4});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1000 ? 4 : (c.maxWidth > 620 ? 2 : 1);
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.4,
        children: List.generate(
          count,
          (_) => const _SkeletonCard(
            child: Row(
              children: [
                SkeletonBox(width: 46, height: 46, radius: null),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonLine(width: 70, height: 18),
                      SizedBox(height: 10),
                      SkeletonLine(width: 100, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Carte « graphique » (section revenus / signalements du tableau de bord).
class SkeletonChartCard extends StatelessWidget {
  final double height;
  const SkeletonChartCard({super.key, this.height = 240});
  @override
  Widget build(BuildContext context) {
    return _SkeletonCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 160, height: 14),
          const SizedBox(height: 20),
          SkeletonBox(width: double.infinity, height: height, radius: BorderRadius.circular(12)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 3. Paramètres
// ════════════════════════════════════════════════════════════════════════

class SkeletonSettings extends StatelessWidget {
  const SkeletonSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              for (int s = 0; s < 3; s++) ...[
                _section(items: s == 0 ? 3 : 2),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({required int items}) => _SkeletonCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                SkeletonBox(width: 40, height: 40, radius: null),
                SizedBox(width: 12),
                SkeletonLine(width: 160, height: 15),
              ],
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < items; i++) ...[
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: 140, height: 12),
                        SizedBox(height: 8),
                        SkeletonLine(width: 220, height: 10),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 48, height: 28, radius: BorderRadius.circular(20)),
                ],
              ),
              if (i < items - 1) const SizedBox(height: 18),
            ],
          ],
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════
// 4. Grille de centres / pavillons
// ════════════════════════════════════════════════════════════════════════

class SkeletonCentreGrid extends StatelessWidget {
  final int count;
  const SkeletonCentreGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 1200 ? 3 : (c.maxWidth > 760 ? 2 : 1);
      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 220,
        ),
        itemCount: count,
        itemBuilder: (context, i) => const _SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 44, height: 44, radius: null),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: 120, height: 14),
                        SizedBox(height: 8),
                        SkeletonLine(width: 80, height: 11),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 20, height: 20, circle: true),
                ],
              ),
              Spacer(),
              SkeletonLine(width: 110, height: 10),
              SizedBox(height: 8),
              SkeletonBox(width: double.infinity, height: 8),
              SizedBox(height: 16),
              Row(
                children: [
                  _MiniStat(),
                  _MiniStat(),
                  _MiniStat(),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat();
  @override
  Widget build(BuildContext context) => const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLine(width: 34, height: 15),
            SizedBox(height: 6),
            SkeletonLine(width: 54, height: 9),
          ],
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════
// 5. Liste d'annonces
// ════════════════════════════════════════════════════════════════════════

class SkeletonAnnonceList extends StatelessWidget {
  final int count;
  const SkeletonAnnonceList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) => _SkeletonCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 96, height: 24, radius: BorderRadius.circular(20)),
                const SkeletonLine(width: 110, height: 10),
              ],
            ),
            const SizedBox(height: 14),
            const SkeletonLine(width: 240, height: 16),
            const SizedBox(height: 12),
            const SkeletonLine(width: double.infinity, height: 11),
            const SizedBox(height: 8),
            const SkeletonLine(width: double.infinity, height: 11),
            const SizedBox(height: 8),
            const SkeletonLine(width: 200, height: 11),
            const SizedBox(height: 16),
            const Row(
              children: [
                SkeletonBox(width: 16, height: 16, circle: true),
                SizedBox(width: 8),
                SkeletonLine(width: 90, height: 10),
                SizedBox(width: 20),
                SkeletonBox(width: 16, height: 16, circle: true),
                SizedBox(width: 8),
                SkeletonLine(width: 70, height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
