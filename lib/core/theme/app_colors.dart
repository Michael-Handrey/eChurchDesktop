import 'package:flutter/widgets.dart';

/// Paleta de cores oficial do eChurch Desktop.
/// Baseada na cor primária institucional [#023B0B] e na teoria das cores
/// com harmonias análogas, complementares divididas e neutros cromáticos.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // 1. Marca & Identidade Primária (Forest Green Palette)
  // ---------------------------------------------------------------------------
  /// Cor base institucional (Verde Floresta Profundo)
  static const primary = Color(0xFF023B0B);
  static const primaryDark = Color(0xFF012407);
  static const primaryLight = Color(0xFF0A5816);
  static const primarySubtle = Color(0xFFE8F5EB);

  // ---------------------------------------------------------------------------
  // 2. Elementos de Superfície e Fundo (Neutros Cromáticos / Sage Neutrals)
  // ---------------------------------------------------------------------------
  /// Fundo geral da aplicação (off-white suave com temperatura sálvia)
  static const background = Color(0xFFF7F9F7);

  /// Cartões, modais e áreas elevadas
  static const surface = Color(0xFFFFFFFF);

  /// Superfície secundária (cards de estatística, fundo de banners)
  static const surfaceSubtle = Color(0xFFF0F5F1);

  /// Bordas sutis de cartões e inputs
  static const border = Color(0xFFE2E8E3);
  static const borderSubtle = Color(0xFFEEF2EF);

  // ---------------------------------------------------------------------------
  // 3. Tipografia & Contraste (WCAG AAA)
  // ---------------------------------------------------------------------------
  /// Títulos e textos de alta ênfase (Grafite profundo)
  static const textPrimary = Color(0xFF131D15);

  /// Descrições, legendas e textos de apoio
  static const textSecondary = Color(0xFF5A685D);

  /// Placeholders, timestamps e textos inativos
  static const textMuted = Color(0xFF8C9B90);

  /// Textos claros sobre fundos escuros (ex: Sidebar, Topbar e botões primários)
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textOnPrimaryMuted = Color(0xFFADC7B3);

  // ---------------------------------------------------------------------------
  // 4. Componentes de Navegação & Shell Desktop
  // ---------------------------------------------------------------------------
  /// Fundo de itens selecionados na Sidebar (translúcido sobre verde)
  static const sidebarActive = Color(0x2EFFFFFF); // Branco a ~18%
  static const sidebarHover = Color(0x1AFFFFFF);  // Branco a ~10%

  /// Campo de busca global integrado ao header verde
  static const searchBarBackground = Color(0x1F000000);
  static const searchBarBorder = Color(0x3DFFFFFF);

  // ---------------------------------------------------------------------------
  // 5. Cores Semânticas dos Módulos (Identidade Eclesiástica)
  // ---------------------------------------------------------------------------
  // Membros (Verde Esmeralda - Harmonia com a marca)
  static const membersIcon = Color(0xFF1B873F);
  static const membersBg = Color(0xFFE6F5EB);

  // Crianças / Ministério Infantil (Azul Cobalto - Harmonia análoga: confiança e cuidado)
  static const childrenIcon = Color(0xFF1E6FD9);
  static const childrenBg = Color(0xFFE9F2FD);

  // Pedidos de Oração (Púrpura / Violeta - Harmonia complementar dividida: devoção e reverência)
  static const prayerIcon = Color(0xFF7E38B7);
  static const prayerBg = Color(0xFFF4EBFA);

  // ---------------------------------------------------------------------------
  // 6. Feedback & Estados do Sistema
  // ---------------------------------------------------------------------------
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);

  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFEF3C7);

  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEE2E2);

  static const info = Color(0xFF0284C7);
  static const infoBg = Color(0xFFE0F2FE);

  // ---------------------------------------------------------------------------
  // 7. Gradientes Decorativos
  // ---------------------------------------------------------------------------
  /// Gradiente suave do card de Boas-Vindas da Secretaria
  static const welcomeGradientStart = Color(0xFFEDF6F0);
  static const welcomeGradientEnd = Color(0xFFF8FBF8);
}
