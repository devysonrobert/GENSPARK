// presentation/shell/app_shell.dart
// Shell principal da aplicação com Header + Sidebar + Content

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../screens/dashboard_screen.dart';
import '../screens/configuracoes_screen.dart';
import '../screens/importar_xml_screen.dart';
import '../screens/titulos_screen.dart';
import '../screens/validacao_screen.dart';
import '../screens/gerar_cnab_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/titulo.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScreen = ref.watch(currentScreenProvider);
    final empresa = ref.watch(empresaConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header fixo ──────────────────────────────────────
          _AppHeader(empresaConfigurada: empresa.isConfigured),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sidebar fixa ──────────────────────────────
                _AppSidebar(currentScreen: currentScreen),

                // ── Content Area ──────────────────────────────
                Expanded(
                  child: _buildContent(currentScreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppScreen screen) {
    switch (screen) {
      case AppScreen.dashboard:
        return const DashboardScreen();
      case AppScreen.configuracoes:
        return const ConfiguracoesScreen();
      case AppScreen.importarXml:
        return const ImportarXmlScreen();
      case AppScreen.titulos:
        return const TitulosScreen();
      case AppScreen.validacao:
        return const ValidacaoScreen();
      case AppScreen.gerarCnab:
        return const GerarCnabScreen();
    }
  }
}

// ══════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════

class _AppHeader extends StatelessWidget {
  final bool empresaConfigurada;
  const _AppHeader({required this.empresaConfigurada});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.surface,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Logo Santander
          _SantanderLogo(),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 24,
            color: AppColors.border,
          ),
          const SizedBox(width: 16),
          Text(
            'CNAB 240 — Cobrança de Boletos',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Status empresa
          if (empresaConfigurada)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'Empresa configurada',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, size: 14, color: AppColors.warning),
                  SizedBox(width: 6),
                  Text(
                    'Configure a empresa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 16),
          Text(
            'v1.0.0',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SantanderLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chama SVG Santander (texto estilizado em SVG customizado)
        CustomPaint(
          size: const Size(28, 28),
          painter: _SantanderFlamePainter(),
        ),
        const SizedBox(width: 10),
        const Text(
          'Santander',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _SantanderFlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final path = Path();
    // Chama Santander simplificada
    path.moveTo(size.width * 0.5, size.height * 0.05);
    path.cubicTo(
      size.width * 0.9, size.height * 0.1,
      size.width * 0.95, size.height * 0.4,
      size.width * 0.7, size.height * 0.55,
    );
    path.cubicTo(
      size.width * 0.5, size.height * 0.65,
      size.width * 0.3, size.height * 0.7,
      size.width * 0.2, size.height * 0.85,
    );
    path.cubicTo(
      size.width * 0.1, size.height * 0.95,
      size.width * 0.05, size.height * 0.8,
      size.width * 0.15, size.height * 0.6,
    );
    path.cubicTo(
      size.width * 0.25, size.height * 0.45,
      size.width * 0.45, size.height * 0.35,
      size.width * 0.5, size.height * 0.05,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════
// SIDEBAR
// ══════════════════════════════════════════════════════════════

class _AppSidebar extends ConsumerWidget {
  final AppScreen currentScreen;
  const _AppSidebar({required this.currentScreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titulos = ref.watch(titulosProvider);
    final validos = titulos.where((t) => t.status == StatusTitulo.valido).length;
    final pendentes = titulos.where((t) => t.status != StatusTitulo.valido).length;

    return Container(
      width: 240,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            screen: AppScreen.dashboard,
            isActive: currentScreen == AppScreen.dashboard,
          ),
          _NavItem(
            icon: Icons.business_outlined,
            label: 'Configurações',
            screen: AppScreen.configuracoes,
            isActive: currentScreen == AppScreen.configuracoes,
          ),
          _NavItem(
            icon: Icons.upload_file_outlined,
            label: 'Importar XMLs',
            screen: AppScreen.importarXml,
            isActive: currentScreen == AppScreen.importarXml,
          ),
          _NavItem(
            icon: Icons.list_alt_outlined,
            label: 'Títulos',
            screen: AppScreen.titulos,
            isActive: currentScreen == AppScreen.titulos,
            badge: titulos.isNotEmpty ? titulos.length.toString() : null,
          ),
          _NavItem(
            icon: Icons.check_circle_outline,
            label: 'Validação',
            screen: AppScreen.validacao,
            isActive: currentScreen == AppScreen.validacao,
            badgeColor: pendentes > 0 ? AppColors.warning : AppColors.success,
          ),
          _NavItem(
            icon: Icons.download_outlined,
            label: 'Gerar CNAB 240',
            screen: AppScreen.gerarCnab,
            isActive: currentScreen == AppScreen.gerarCnab,
            highlight: true,
          ),
          const Spacer(),
          // Rodapé sidebar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Color(0xFF333333)),
                const SizedBox(height: 8),
                if (titulos.isNotEmpty) ...[
                  _SidebarStat(
                    label: 'Títulos válidos',
                    value: '$validos/${titulos.length}',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 4),
                ],
                const Text(
                  'CNAB Master © 2025',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final AppScreen screen;
  final bool isActive;
  final String? badge;
  final Color? badgeColor;
  final bool highlight;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    required this.isActive,
    this.badge,
    this.badgeColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(currentScreenProvider.notifier).state = screen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.15)
                : highlight && !isActive
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
            border: isActive
                ? const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? AppColors.primaryLight
                    : highlight
                        ? AppColors.primary
                        : AppColors.sidebarText.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.sidebarText
                        : highlight
                            ? AppColors.primaryLight
                            : AppColors.sidebarText.withValues(alpha: 0.7),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SidebarStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
