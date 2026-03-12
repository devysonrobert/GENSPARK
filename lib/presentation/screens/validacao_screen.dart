// presentation/screens/validacao_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/titulo.dart';
import '../../domain/validators/validators.dart';

class ValidacaoScreen extends ConsumerStatefulWidget {
  const ValidacaoScreen({super.key});

  @override
  ConsumerState<ValidacaoScreen> createState() => _ValidacaoScreenState();
}

class _ValidacaoScreenState extends ConsumerState<ValidacaoScreen> {
  bool _validado = false;
  bool _validando = false;
  List<ErroValidacaoRemessa> _erros = [];

  Future<void> _validarRemessa() async {
    setState(() {
      _validando = true;
      _validado = false;
      _erros = [];
    });

    // Simula delay de validação
    await Future.delayed(const Duration(milliseconds: 600));

    final titulos = ref.read(titulosProvider);
    final empresa = ref.read(empresaConfigProvider);
    final erros = <ErroValidacaoRemessa>[];

    // Valida configuração da empresa
    if (!empresa.isConfigured) {
      erros.add(const ErroValidacaoRemessa(
        tituloId: 'empresa',
        tituloRef: 'Configuração da Empresa',
        erros: ['Empresa cedente não configurada. Configure os dados bancários.'],
      ));
    }

    // Valida CNPJ da empresa
    if (empresa.cnpj.isNotEmpty) {
      final r = ValidadorCNPJ.validar(empresa.cnpj);
      if (!r.isValid) {
        erros.add(ErroValidacaoRemessa(
          tituloId: 'empresa',
          tituloRef: 'CNPJ da Empresa',
          erros: ['CNPJ inválido: ${r.error}'],
        ));
      }
    }

    if (titulos.isEmpty) {
      erros.add(const ErroValidacaoRemessa(
        tituloId: 'lista',
        tituloRef: 'Lista de Títulos',
        erros: ['Nenhum título cadastrado na remessa.'],
      ));
    }

    // Verifica nosso número duplicado
    final nossoNumeros = <String, List<String>>{};
    for (final t in titulos) {
      nossoNumeros.putIfAbsent(t.seuNumero, () => []).add(t.id);
    }
    for (final entry in nossoNumeros.entries) {
      if (entry.value.length > 1) {
        erros.add(ErroValidacaoRemessa(
          tituloId: entry.value[0],
          tituloRef: 'Nosso Número: ${entry.key}',
          erros: [
            'Nosso Número "${entry.key}" duplicado em ${entry.value.length} títulos!'
          ],
        ));
      }
    }

    // Valida cada título
    for (final titulo in titulos) {
      final errosTitulo = ValidadorCamposObrigatorios.validarTitulo(titulo);
      if (errosTitulo.isNotEmpty) {
        erros.add(ErroValidacaoRemessa(
          tituloId: titulo.id,
          tituloRef:
              'Título: ${titulo.seuNumero} (${titulo.nomeSacado})',
          erros: errosTitulo,
        ));
      }
    }

    setState(() {
      _erros = erros;
      _validado = true;
      _validando = false;
    });

    // Atualiza status de todos os títulos
    for (final t in titulos) {
      final errosTitulo = ValidadorCamposObrigatorios.validarTitulo(t);
      if (errosTitulo.isEmpty) {
        await ref
            .read(titulosProvider.notifier)
            .atualizar(t.copyWith(status: StatusTitulo.valido, erros: []));
      } else {
        final temGrave = errosTitulo.any((e) =>
            e.contains('inválido') || e.contains('CNPJ') || e.contains('CPF'));
        await ref
            .read(titulosProvider.notifier)
            .atualizar(t.copyWith(
              status:
                  temGrave ? StatusTitulo.invalido : StatusTitulo.pendente,
              erros: errosTitulo,
            ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulos = ref.watch(titulosProvider);
    final empresa = ref.watch(empresaConfigProvider);
    final validos =
        titulos.where((t) => t.status == StatusTitulo.valido).length;
    final invalidos =
        titulos.where((t) => t.status == StatusTitulo.invalido).length;
    final pendentes =
        titulos.where((t) => t.status == StatusTitulo.pendente).length;

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Validação da Remessa',
            subtitle:
                'Verifique se todos os títulos estão corretos antes de gerar o CNAB 240',
          ),
          const SizedBox(height: 24),

          // ── Cards de Status ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  title: 'Empresa',
                  status: empresa.isConfigured ? 'OK' : 'Pendente',
                  ok: empresa.isConfigured,
                  icon: Icons.business,
                  desc: empresa.isConfigured
                      ? empresa.razaoSocial
                      : 'Configurar empresa',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusCard(
                  title: 'Títulos Válidos',
                  status: '$validos de ${titulos.length}',
                  ok: validos == titulos.length && titulos.isNotEmpty,
                  icon: Icons.check_circle,
                  desc: validos == titulos.length && titulos.isNotEmpty
                      ? 'Todos prontos para gerar CNAB'
                      : 'Há títulos com pendências',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusCard(
                  title: 'Inválidos / Pendentes',
                  status: '${invalidos + pendentes}',
                  ok: (invalidos + pendentes) == 0,
                  icon: Icons.warning_amber,
                  desc: (invalidos + pendentes) == 0
                      ? 'Sem pendências'
                      : '$invalidos inválido(s), $pendentes pendente(s)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusCard(
                  title: 'Pronto para CNAB',
                  status: (empresa.isConfigured &&
                          validos > 0 &&
                          validos == titulos.length)
                      ? 'SIM'
                      : 'NÃO',
                  ok: empresa.isConfigured &&
                      validos > 0 &&
                      validos == titulos.length,
                  icon: Icons.download,
                  desc: 'Clique em Validar Remessa',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Botão Validar ────────────────────────────────────
          Center(
            child: ElevatedButton.icon(
              onPressed: _validando ? null : _validarRemessa,
              icon: _validando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified, size: 22),
              label: Text(
                _validando ? 'Validando...' : 'Validar Remessa Completa',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(280, 52),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Resultado da Validação ───────────────────────────
          if (_validado) ...[
            if (_erros.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remessa válida e pronta para geração!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            '$validos título(s) prontos para gerar o arquivo CNAB 240',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(currentScreenProvider.notifier)
                          .state = AppScreen.gerarCnab,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Gerar CNAB 240'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: AppColors.error, size: 32),
                    const SizedBox(width: 16),
                    Text(
                      '${_erros.length} problema(s) encontrado(s). '
                      'Corrija antes de gerar o CNAB.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(
                            'Lista de Erros (${_erros.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...(_erros.map((e) => _ErroItem(
                          erro: e,
                          onCorrigir: e.tituloId != 'empresa' &&
                                  e.tituloId != 'lista'
                              ? () {
                                  ref
                                      .read(currentScreenProvider.notifier)
                                      .state = AppScreen.titulos;
                                }
                              : e.tituloId == 'empresa'
                                  ? () {
                                      ref
                                          .read(currentScreenProvider.notifier)
                                          .state = AppScreen.configuracoes;
                                    }
                                  : null,
                        ))),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final bool ok;
  final IconData icon;
  final String desc;

  const _StatusCard({
    required this.title,
    required this.status,
    required this.ok,
    required this.icon,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.warning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              status,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErroItem extends StatelessWidget {
  final ErroValidacaoRemessa erro;
  final VoidCallback? onCorrigir;

  const _ErroItem({required this.erro, this.onCorrigir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  erro.tituloRef,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                ...erro.erros.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(color: AppColors.error)),
                          Expanded(
                            child: Text(
                              e,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          if (onCorrigir != null)
            TextButton.icon(
              onPressed: onCorrigir,
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Corrigir'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
