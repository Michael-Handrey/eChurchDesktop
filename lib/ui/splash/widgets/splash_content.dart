import 'package:echurch_desktop/ui/core/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

class const SplashContentWidget({
  super.key,
  required final double progress,
  required final String message,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    const SplashLogoWidget(),
                    const SizedBox(height: 48),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      borderRadius: .circular(3),
                      backgroundColor: AppColors.sidebarHover,
                      color: AppColors.textOnPrimary,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Semantics(
                          key: ValueKey(message),
                          liveRegion: true,
                          child: Text(
                            message,
                            textAlign: .center,
                            style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 15, height: 1.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: .only(bottom: 24),
            child: Text(
              'Ambiente seguro • eChurch Desktop v1.0.0',
              style: TextStyle(color: AppColors.textOnPrimaryMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class const SplashLogoWidget({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const .all(18),
          decoration: BoxDecoration(
            color: AppColors.sidebarHover,
            border: Border.all(color: const Color(0x3DFFFFFF), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.church_outlined, color: AppColors.textOnPrimary, size: 48),
        ),
        const SizedBox(height: 20),
        const Text(
          'eChurch - IMDF',
          style: TextStyle(color: AppColors.textOnPrimary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gestão Eclesiástica',
          style: TextStyle(color: AppColors.textOnPrimaryMuted, fontSize: 14),
        ),
      ],
    );
  }
}
