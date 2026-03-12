// presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/titulo.dart';
import '../../data/storage/local_storage.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titulos = ref.watch(titulosProvider);
    final empresa = ref.watch(empresaConfigProvider);
    ref.watch(historicoRefreshProvider);

    final validos = titulos.where((t) => t.status == StatusTitulo.valido).length;
    final pendentes = titulos.where((t) => t.status == StatusTitulo.pendente).length;
    final invalidos = titulos.where((t) => t.status == StatusTitulo.invalido).length;
    final valorTotal = titulos.fold(0.0, (s, t) => s + t.valorNominal);

    // Barra de progresso do fluxo
    final step1 = empresa.isConfigured;
    final step2 = titulos.isNotEmpty;
    final step3 = step2 && validos > 0;
    final step4 = step3 && validos == titulos.length;

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Dashboard',
            subtitle: 'Visão geral do processo de geração de remessa CNAB 240',
          ),
          const SizedBox(height: 24),

          // ── Cards de Métricas ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Total de Títulos',
                  value: titulos.length.toString(),
                  icon: Icons.receipt_long,
                  color: AppColors.info,
                  subtitle: 'na remessa atual',
                  onTap: () => ref.read(currentScreenProvider.notifier).state =
                      AppScreen.titulos,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Valor Total',
                  value: formatarMoeda(valorTotal),
                  icon: Icons.attach_money,
                  color: AppColors.success,
                  subtitle: 'da remessa',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Títulos Válidos',
                  value: validos.toString(),
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  subtitle: 'prontos para CNAB',
                  onTap: () => ref.read(currentScreenProvider.notifier).state =
                      AppScreen.validacao,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Pendências',
                  value: (pendentes + invalidos).toString(),
                  icon: Icons.warning_amber_outlined,
                  color: (pendentes + invalidos) > 0
                      ? AppColors.warning
                      : AppColors.success,
                  subtitle: 'a corrigir',
                  onTap: (pendentes + invalidos) > 0
                      ? () =>
                          ref.read(currentScreenProvider.notifier).state =
                              AppScreen.validacao
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Barra de Progresso do Fluxo ───────────────────
          _FluxoProgressBar(
            step1: step1,
            step2: step2,
            step3: step3,
            step4: step4,
          ),

          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ações Rápidas ──────────────────────────────
              Expanded(
                flex: 2,
                child: _AcoesRapidas(),
              ),
              const SizedBox(width: 24),

              // ── Histórico de Remessas ──────────────────────
              Expanded(
                flex: 3,
                child: _HistoricoRemessas(),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _FluxoProgressBar extends StatelessWidget {
  final bool step1, step2, step3, step4;
  const _FluxoProgressBar({
    required this.step1,
    required this.step2,
    required this.step3,
    required this.step4,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progresso do Fluxo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StepItem(
                  numero: '1',
                  label: 'Configurar\nEmpresa',
                  done: step1,
                  active: !step1,
                ),
                _StepConnector(done: step1),
                _StepItem(
                  numero: '2',
                  label: 'Importar\nTítulos',
                  done: step2,
                  active: step1 && !step2,
                ),
                _StepConnector(done: step2),
                _StepItem(
                  numero: '3',
                  label: 'Revisar e\nValidar',
                  done: step3,
                  active: step2 && !step3,
                ),
                _StepConnector(done: step3),
                _StepItem(
                  numero: '4',
                  label: 'Gerar\nCNAB 240',
                  done: step4,
                  active: step3 && !step4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String numero;
  final String label;
  final bool done;
  final bool active;

  const _StepItem({
    required this.numero,
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    Color circleColor;
    Color textColor;
    Widget content;

    if (done) {
      circleColor = AppColors.success;
      textColor = AppColors.success;
      content = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (active) {
      circleColor = AppColors.primary;
      textColor = AppColors.primary;
      content = Text(
        numero,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    } else {
      circleColor = AppColors.border;
      textColor = AppColors.textSecondary;
      content = Text(
        numero,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: content),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: done || active ? FontWeight.w600 : FontWeight.w400,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool done;
  const _StepConnector({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28),
        color: done ? AppColors.success : AppColors.border,
      ),
    );
  }
}

class _AcoesRapidas extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _QuickAction(
              icon: Icons.business,
              label: 'Configurar Empresa',
              subtitle: 'Dados bancários e cedente',
              color: AppColors.info,
              onTap: () => ref.read(currentScreenProvider.notifier).state =
                  AppScreen.configuracoes,
            ),
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.upload_file,
              label: 'Importar XMLs',
              subtitle: 'NF-e e NFS-e automático',
              color: AppColors.warning,
              onTap: () => ref.read(currentScreenProvider.notifier).state =
                  AppScreen.importarXml,
            ),
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.add_circle,
              label: 'Novo Título Manual',
              subtitle: 'Cadastrar manualmente',
              color: AppColors.success,
              onTap: () => ref.read(currentScreenProvider.notifier).state =
                  AppScreen.titulos,
            ),
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.download,
              label: 'Gerar CNAB 240',
              subtitle: 'Arquivo de remessa',
              color: AppColors.primary,
              onTap: () => ref.read(currentScreenProvider.notifier).state =
                  AppScreen.gerarCnab,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoricoRemessas extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refresh = ref.watch(historicoRefreshProvider);
    final remessas = _loadHistorico(refresh);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Últimas Remessas Geradas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (remessas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Nenhuma remessa gerada ainda',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...remessas.take(5).map((r) => _RemessaItem(remessa: r)),
          ],
        ),
      ),
    );
  }

  List<RemessaHistorico> _loadHistorico(int _) {
    return LocalStorage.carregarHistoricoRemessas();
  }
}

class _RemessaItem extends StatelessWidget {
  final RemessaHistorico remessa;
  const _RemessaItem({required this.remessa});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.insert_drive_file, color: AppColors.info, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remessa.nomeArquivo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${remessa.totalTitulos} títulos · ${formatarMoeda(remessa.valorTotal)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(remessa.dataGeracao),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
