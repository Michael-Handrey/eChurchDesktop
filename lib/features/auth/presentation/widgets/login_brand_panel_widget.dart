import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';

class LoginBrandPanelWidget extends StatelessWidget {
  const LoginBrandPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoginBrandHeaderWidget(),
          Spacer(),
          LoginBrandQuoteWidget(),
          Spacer(),
          LoginBrandFooterWidget(),
        ],
      ),
    );
  }
}

class LoginBrandHeaderWidget extends StatelessWidget {
  const LoginBrandHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.sidebarHover,
            border: Border.all(color: const Color(0x3DFFFFFF), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.church_outlined,
            color: AppColors.textOnPrimary,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'eChurch - IMDF',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Gestão Eclesiástica',
              style: TextStyle(
                color: AppColors.textOnPrimaryMuted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class LoginBrandQuoteWidget extends StatelessWidget {
  const LoginBrandQuoteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.sidebarHover,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'ÁREA RESTRITA',
            style: TextStyle(
              color: AppColors.textOnPrimaryMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Conectando vidas e fortalecendo o ministério.',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x26FFFFFF), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '“Alegrei-me quando me disseram: Vamos à casa do Senhor.”',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Salmos 122:1',
                style: TextStyle(
                  color: AppColors.textOnPrimaryMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LoginBrandFooterWidget extends StatelessWidget {
  const LoginBrandFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(
          Icons.shield_outlined,
          color: AppColors.textOnPrimaryMuted,
          size: 16,
        ),
        SizedBox(width: 8),
        Text(
          'Ambiente seguro • eChurch Desktop v1.0.0',
          style: TextStyle(
            color: AppColors.textOnPrimaryMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
