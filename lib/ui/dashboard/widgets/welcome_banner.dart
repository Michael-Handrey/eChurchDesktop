import 'package:echurch_desktop/core/auth/auth_session_notifier.dart';
import 'package:echurch_desktop/domain/models/auth/auth_session.dart';
import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class WelcomeBannerWidget extends StatelessWidget {
  const WelcomeBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.welcomeGradientStart,
            AppColors.welcomeGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: const [
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              width: 220,
              child: ChurchIllustrationWidget(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: WelcomeBannerTextWidget(),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: WelcomeBannerVerseWidget(),
                  ),
                  SizedBox(width: 140),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeBannerTextWidget extends StatelessWidget {
  const WelcomeBannerTextWidget({super.key});

  /// Saudação pela hora do dia.
  static String greetingAt(DateTime now) => switch (now.hour) {
    >= 5 && < 12 => 'Bom dia',
    >= 12 && < 18 => 'Boa tarde',
    _ => 'Boa noite',
  };

  /// O que a pessoa costuma fazer no sistema, conforme o perfil dela.
  static String subtitleFor(AuthSessionUser? user) {
    final roles = user?.roles ?? const [];
    if (roles.contains(AuthSessionUser.adminRole)) {
      return 'Acompanhe a igreja e gerencie quem acessa o sistema.';
    }
    if (roles.contains('ROLE_SECRETARIA')) {
      return 'Gerencie os membros, crianças e pedidos de oração da nossa igreja.';
    }
    if (user != null && !user.canSeeMembers && user.isMinistryLeader) {
      return 'Acompanhe os membros dos ministérios que você lidera.';
    }
    return 'Consulte os membros, aniversariantes e eventos da nossa igreja.';
  }

  /// Primeiro nome; sem nome cadastrado, o login.
  static String firstNameOf(AuthSessionUser? user) {
    final name = (user?.name ?? '').trim();
    if (name.isEmpty) return user?.login ?? '';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthSessionNotifier>().user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${greetingAt(DateTime.now()).toUpperCase()},',
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          firstNameOf(user),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitleFor(user),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class WelcomeBannerVerseWidget extends StatelessWidget {
  const WelcomeBannerVerseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          '“E tudo o que fizerem,\nseja de coração, como para o Senhor\ne não para os homens.”',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Colossenses 3:23',
          style: TextStyle(
            color: AppColors.primaryLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ChurchIllustrationWidget extends StatelessWidget {
  const ChurchIllustrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChurchHillPainter(),
    );
  }
}

class _ChurchHillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final hillPaint1 = Paint()
      ..color = const Color(0xFFC7E2D0).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final hillPaint2 = Paint()
      ..color = const Color(0xFF9DC7A9).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final hillPaint3 = Paint()
      ..color = const Color(0xFF7FA88B)
      ..style = PaintingStyle.fill;

    // Back Hill
    final path1 = Path();
    path1.moveTo(0, size.height);
    path1.quadraticBezierTo(size.width * 0.4, size.height * 0.45, size.width, size.height * 0.7);
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, hillPaint1);

    // Mid Hill
    final path2 = Path();
    path2.moveTo(size.width * 0.25, size.height);
    path2.quadraticBezierTo(size.width * 0.65, size.height * 0.4, size.width, size.height * 0.5);
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, hillPaint2);

    // Church drawing on the hill
    final churchPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final churchRoofPaint = Paint()
      ..color = const Color(0xFF0A5816)
      ..style = PaintingStyle.fill;

    final churchX = size.width * 0.65;
    final churchY = size.height * 0.38;
    final churchW = 34.0;
    final churchH = 38.0;

    // Church body
    final churchRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(churchX - churchW / 2, churchY, churchW, churchH),
      const Radius.circular(3),
    );
    canvas.drawRRect(churchRect, churchPaint);

    // Church Roof / Spire
    final roofPath = Path();
    roofPath.moveTo(churchX - churchW / 2 - 3, churchY);
    roofPath.lineTo(churchX, churchY - 22);
    roofPath.lineTo(churchX + churchW / 2 + 3, churchY);
    roofPath.close();
    canvas.drawPath(roofPath, churchRoofPaint);

    // Cross
    final crossPaint = Paint()
      ..color = const Color(0xFF0A5816)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(churchX, churchY - 22),
      Offset(churchX, churchY - 34),
      crossPaint,
    );
    canvas.drawLine(
      Offset(churchX - 5, churchY - 29),
      Offset(churchX + 5, churchY - 29),
      crossPaint,
    );

    // Church Door (Arched)
    final doorPaint = Paint()
      ..color = const Color(0xFF0A5816)
      ..style = PaintingStyle.fill;

    final doorRect = Rect.fromLTWH(churchX - 5, churchY + 18, 10, 20);
    canvas.drawRRect(
      RRect.fromRectAndCorners(doorRect, topLeft: const Radius.circular(5), topRight: const Radius.circular(5)),
      doorPaint,
    );

    // Foreground Hill
    final path3 = Path();
    path3.moveTo(size.width * 0.35, size.height);
    path3.quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width, size.height * 0.7);
    path3.lineTo(size.width, size.height);
    path3.close();
    canvas.drawPath(path3, hillPaint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
