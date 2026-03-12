// presentation/screens/gerar_cnab_screen.dart
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validation/cnab_validator_engine.dart';
import '../../core/validation/models/validation_report.dart';
import '../../domain/models/titulo.dart';
import '../../domain/builders/cnab_santander240_builder.dart';
import '../../data/storage/local_storage.dart';
import 'package:intl/intl.dart';

class GerarCnabScreen extends ConsumerStatefulWidget {
  const GerarCnabScreen({super.key});

  @override
  ConsumerState<GerarCnabScreen> createState() => _GerarCnabScreenState();
}

class _GerarCnabScreenState extends ConsumerState<GerarCnabScreen> {
  bool _gerando = false;
  bool _validandoPos = false;
  RelatorioValidacao? _ultimoRelatorio;
  late TextEditingController _numArquivoCtrl;

  @override
  void initState() {
    super.initState();
    final empresa = ref.read(empresaConfigProvider);
    _numArquivoCtrl = TextEditingController(
        text: empresa.numeroSequencial.toString().padLeft(6, '0'));
  }

  @override
  void dispose() {
    _numArquivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _gerarCnab() async {
    final empresa = ref.read(empresaConfigProvider);
    final titulos = ref.read(titulosProvider);
    final validos =
        titulos.where((t) => t.status == StatusTitulo.valido).toList();

    if (!empresa.isConfigured) {
      showErrorToast(context, 'Configure os dados da empresa antes de gerar!');
      ref.read(currentScreenProvider.notifier).state = AppScreen.configuracoes;
      return;
    }

    if (validos.isEmpty) {
      showErrorToast(context,
          'Nenhum título válido na remessa. Valide os títulos primeiro.');
      ref.read(currentScreenProvider.notifier).state = AppScreen.validacao;
      return;
    }

    setState(() => _gerando = true);

    try {
      final numSeq =
          int.tryParse(_numArquivoCtrl.text) ?? empresa.numeroSequencial;
      final empresaComSeq = empresa.copyWith(numeroSequencial: numSeq);
      final agora = DateTime.now();

      final builder = CnabSantander240Builder(
        empresa: empresaComSeq,
        titulos: validos,
        dataGeracao: agora,
      );

      final conteudo = builder.gerar();
      final nomeArquivo = builder.getNomeArquivo();
      final totalLinhas = builder.getTotalLinhas();
      final totalBytes = utf8.encode(conteudo).length;

      // Atualiza provider com resultado
      ref.read(cnabGeradoProvider.notifier).state = CnabGeradoState(
        conteudo: conteudo,
        nomeArquivo: nomeArquivo,
        dataGeracao: agora,
        totalLinhas: totalLinhas,
        totalBytes: totalBytes,
      );

      // Salva histórico
      await LocalStorage.salvarHistoricoRemessa(RemessaHistorico(
        nomeArquivo: nomeArquivo,
        dataGeracao: agora,
        totalTitulos: validos.length,
        valorTotal: validos.fold(0.0, (s, t) => s + t.valorNominal),
        totalLinhas: totalLinhas,
        numeroSequencial: numSeq,
      ));

      // Incrementa sequencial
      await ref
          .read(empresaConfigProvider.notifier)
          .incrementarSequencial();
      _numArquivoCtrl.text =
          ref.read(empresaConfigProvider).numeroSequencial.toString().padLeft(6, '0');

      // Notifica atualização de histórico
      ref.read(historicoRefreshProvider.notifier).state++;

      // ── Validação pós-geração ──────────────────────────────────────────────
      if (mounted) setState(() { _gerando = false; _validandoPos = true; });

      RelatorioValidacao relatorio;
      try {
        relatorio = await validarRapido(conteudo, nomeArquivo);
        _ultimoRelatorio = relatorio;
      } catch (e) {
        if (mounted) setState(() => _validandoPos = false);
        // Em caso de erro na validação, permite download mesmo assim
        _baixarArquivo(conteudo, nomeArquivo);
        showSuccessToast(context, 'Arquivo $nomeArquivo gerado (validação indisponível)!');
        return;
      }

      if (mounted) setState(() => _validandoPos = false);

      // ── Decisão baseada no resultado da validação ─────────────────────────
      if (relatorio.totalFatais > 0) {
        // BLOQUEIO: erros fatais impedem download
        if (mounted) {
          _mostrarDialogoValidacao(relatorio, conteudo, nomeArquivo, bloqueado: true);
        }
      } else if (relatorio.totalErros > 0) {
        // AVISOS CRÍTICOS: erros não-fatais, permite download com alerta
        if (mounted) {
          _mostrarDialogoValidacao(relatorio, conteudo, nomeArquivo, bloqueado: false);
        }
      } else if (relatorio.totalAvisos > 0) {
        // AVISOS: permite download com snack de alerta
        _baixarArquivo(conteudo, nomeArquivo);
        if (mounted) {
          showWarningToast(
            context,
            '⚠️ Arquivo gerado com ${relatorio.totalAvisos} aviso(s). Score: ${relatorio.qualityScore}/100',
          );
        }
      } else {
        // APROVADO: download direto
        _baixarArquivo(conteudo, nomeArquivo);
        if (mounted) {
          showSuccessToast(context,
              '✅ Arquivo $nomeArquivo gerado! Score: ${relatorio.qualityScore}/100');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Erro ao gerar CNAB: $e');
      }
    } finally {
      if (mounted) setState(() { _gerando = false; _validandoPos = false; });
    }
  }

  /// Mostra diálogo com resultado da validação pós-geração
  void _mostrarDialogoValidacao(
    RelatorioValidacao relatorio,
    String conteudo,
    String nomeArquivo, {
    required bool bloqueado,
  }) {
    final cor = bloqueado ? const Color(0xFFB00020) : const Color(0xFFF44336);
    final titulo = bloqueado
        ? '❌ Download Bloqueado — Erros Fatais'
        : '⚠️ Arquivo Gerado com Erros';
    final icone = bloqueado ? Icons.block_rounded : Icons.warning_amber_rounded;

    showDialog(
      context: context,
      barrierDismissible: !bloqueado,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: cor.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
              Icon(icone, color: cor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cor),
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score
              Row(
                children: [
                  Text(
                    'Score de Qualidade: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    '${relatorio.qualityScore}/100',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: relatorio.qualityScore >= 50 ? const Color(0xFFFF9800) : cor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Contadores
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (relatorio.totalFatais > 0)
                    _badgeResumo('${relatorio.totalFatais} FATAL', const Color(0xFFB00020)),
                  if (relatorio.totalErros > 0)
                    _badgeResumo('${relatorio.totalErros} ERRO(S)', const Color(0xFFF44336)),
                  if (relatorio.totalAvisos > 0)
                    _badgeResumo('${relatorio.totalAvisos} AVISO(S)', const Color(0xFFFF9800)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              // Lista dos primeiros erros
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: (relatorio.errosFatais + relatorio.errosGraves).take(5).length,
                  itemBuilder: (_, i) {
                    final erros = [...relatorio.errosFatais, ...relatorio.errosGraves];
                    if (i >= erros.length) return const SizedBox.shrink();
                    final erro = erros[i];
                    final c = erro.severidade.name == 'fatal'
                        ? const Color(0xFFB00020)
                        : const Color(0xFFF44336);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              erro.codigo,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              erro.descricao,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (bloqueado) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB00020).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFB00020).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, color: Color(0xFFB00020), size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'O download está bloqueado até que os erros fatais sejam corrigidos.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFB00020)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(currentScreenProvider.notifier).state = AppScreen.validacao;
            },
            icon: const Icon(Icons.verified_rounded, size: 16),
            label: const Text('Ver Relatório Completo'),
          ),
          if (!bloqueado)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _baixarArquivo(conteudo, nomeArquivo);
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Baixar Mesmo Assim'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
            ),
          if (bloqueado)
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Corrigir e Regenerar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC0000),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _badgeResumo(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cor),
      ),
    );
  }

  void _baixarArquivo(String conteudo, String nomeArquivo) {
    final bytes = utf8.encode(conteudo);
    final blob = html.Blob([bytes], 'text/plain');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', nomeArquivo)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _copiarConteudo(String conteudo) async {
    await Clipboard.setData(ClipboardData(text: conteudo));
    if (mounted) {
      showInfoToast(context, 'Conteúdo copiado para a área de transferência!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresa = ref.watch(empresaConfigProvider);
    final titulos = ref.watch(titulosProvider);
    final validos =
        titulos.where((t) => t.status == StatusTitulo.valido).toList();
    final cnabGerado = ref.watch(cnabGeradoProvider);
    final valorTotal = validos.fold(0.0, (s, t) => s + t.valorNominal);
    final segmentosR =
        validos.where((t) => t.precisaSegmentoR).length;

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Gerar CNAB 240',
            subtitle: 'Geração e download do arquivo de remessa Santander',
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Resumo da Remessa ────────────────────────────
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TitledDivider(title: 'RESUMO DA REMESSA'),
                        _InfoRow(
                          label: 'Empresa',
                          value: empresa.razaoSocial.toUpperCase(),
                          icon: Icons.business,
                        ),
                        _InfoRow(
                          label: 'CNPJ',
                          value: _formatarCNPJ(empresa.cnpj),
                          icon: Icons.badge,
                        ),
                        _InfoRow(
                          label: 'Agência / Conta',
                          value:
                              '${empresa.agencia}-${empresa.digitoAgencia} / ${empresa.contaCorrente}-${empresa.digitoConta}',
                          icon: Icons.account_balance,
                        ),
                        _InfoRow(
                          label: 'Carteira',
                          value: empresa.carteira,
                          icon: Icons.folder,
                        ),
                        _InfoRow(
                          label: 'Código Cedente',
                          value: empresa.codigoCedente,
                          icon: Icons.numbers,
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Data de Geração',
                          value: DateFormat('dd/MM/yyyy HH:mm:ss')
                              .format(DateTime.now()),
                          icon: Icons.calendar_today,
                        ),
                        _InfoRow(
                          label: 'Total de Títulos',
                          value: '${validos.length} título(s)',
                          icon: Icons.receipt_long,
                          highlight: true,
                        ),
                        _InfoRow(
                          label: 'Valor Total',
                          value: formatarMoeda(valorTotal),
                          icon: Icons.attach_money,
                          highlight: true,
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Estrutura do Arquivo',
                          value:
                              '1 Header + 1 Lote + ${validos.length} (P) + ${validos.length} (Q) + $segmentosR (R) + Trailers',
                          icon: Icons.description,
                        ),

                        const SizedBox(height: 16),
                        const TitledDivider(title: 'CONFIGURAÇÃO DO ARQUIVO'),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormFieldLabel(
                                    label: 'Número do Arquivo',
                                    tooltip:
                                        '[H.158-163] Sequencial da remessa (6 dígitos)',
                                  ),
                                  TextFormField(
                                    controller: _numArquivoCtrl,
                                    maxLength: 6,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      hintText: '000001',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormFieldLabel(
                                      label: 'Nome do Arquivo'),
                                  Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.inputBorder),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      color: const Color(0xFFF5F5F5),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'CB033${DateFormat('yyyyMMdd').format(DateTime.now())}_${_numArquivoCtrl.text.padLeft(3, '0')}.REM',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // ── Botão de Geração ──────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Status check
                            _CheckItem(
                              label: 'Empresa configurada',
                              ok: empresa.isConfigured,
                            ),
                            _CheckItem(
                              label: 'Títulos válidos: ${validos.length}',
                              ok: validos.isNotEmpty,
                            ),
                            _CheckItem(
                              label:
                                  'CNPJ válido: ${empresa.cnpj.isNotEmpty ? '✓' : '✗'}',
                              ok: empresa.cnpj.isNotEmpty,
                            ),
                            _CheckItem(
                              label:
                                  'Conta: ${empresa.contaCorrente.isNotEmpty ? '✓' : '✗'}',
                              ok: empresa.contaCorrente.isNotEmpty,
                            ),
                            const SizedBox(height: 24),

                            // Botão principal
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _gerando || _validandoPos ||
                                        validos.isEmpty ||
                                        !empresa.isConfigured
                                    ? null
                                    : _gerarCnab,
                                icon: (_gerando || _validandoPos)
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(Icons.download, size: 24),
                                label: Text(
                                  _gerando
                                      ? 'Gerando...'
                                      : _validandoPos
                                          ? 'Validando arquivo...'
                                          : 'GERAR E BAIXAR CNAB 240',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            if (validos.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'Nenhum título válido. Valide a remessa primeiro.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            if (!empresa.isConfigured)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Configure a empresa cedente primeiro.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ── Estatísticas após geração ──────────────
                    if (cnabGerado.gerado) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TitledDivider(title: 'ÚLTIMO ARQUIVO GERADO'),
                              // Badge de validação
                              if (_ultimoRelatorio != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(
                                            _ultimoRelatorio!.corStatus
                                                .replaceFirst('#', '0xFF')))
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Color(int.parse(
                                              _ultimoRelatorio!.corStatus
                                                  .replaceFirst('#', '0xFF')))
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _ultimoRelatorio!.aprovado
                                            ? Icons.verified_rounded
                                            : _ultimoRelatorio!.totalFatais > 0
                                                ? Icons.block_rounded
                                                : Icons.warning_rounded,
                                        size: 16,
                                        color: Color(int.parse(
                                            _ultimoRelatorio!.corStatus
                                                .replaceFirst('#', '0xFF'))),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${_ultimoRelatorio!.statusLabel} — Score ${_ultimoRelatorio!.qualityScore}/100',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(int.parse(
                                                _ultimoRelatorio!.corStatus
                                                    .replaceFirst('#', '0xFF'))),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              _InfoRow(
                                label: 'Nome',
                                value: cnabGerado.nomeArquivo ?? '—',
                                icon: Icons.file_present,
                              ),
                              _InfoRow(
                                label: 'Total de linhas',
                                value: '${cnabGerado.totalLinhas}',
                                icon: Icons.format_list_numbered,
                              ),
                              _InfoRow(
                                label: 'Tamanho',
                                value:
                                    '${(cnabGerado.totalBytes / 1024).toStringAsFixed(1)} KB',
                                icon: Icons.storage,
                              ),
                              _InfoRow(
                                label: 'Gerado em',
                                value: cnabGerado.dataGeracao != null
                                    ? DateFormat('dd/MM/yyyy HH:mm:ss')
                                        .format(cnabGerado.dataGeracao!)
                                    : '—',
                                icon: Icons.access_time,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _copiarConteudo(
                                          cnabGerado.conteudo!),
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text('Copiar'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _baixarArquivo(
                                          cnabGerado.conteudo!,
                                          cnabGerado.nomeArquivo!),
                                      icon: const Icon(Icons.download,
                                          size: 16),
                                      label: const Text('Baixar'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Preview do Arquivo ───────────────────────────────
          if (cnabGerado.gerado) ...[
            const SizedBox(height: 24),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.sidebarBg,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.code,
                            color: AppColors.primaryLight, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Preview do Arquivo CNAB 240 (primeiras 10 linhas)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          cnabGerado.nomeArquivo ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1E1E1E),
                    child: SelectableText(
                      _buildPreview(cnabGerado.conteudo!),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.primaryLight,
                        letterSpacing: 0.5,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildPreview(String conteudo) {
    final linhas = conteudo.split('\r\n').where((l) => l.isNotEmpty).take(10);
    final sb = StringBuffer();
    int i = 1;
    for (final linha in linhas) {
      sb.writeln('${i.toString().padLeft(3, '0')} │ $linha');
      i++;
    }
    return sb.toString();
  }

  String _formatarCNPJ(String cnpj) {
    final n = cnpj.replaceAll(RegExp(r'\D'), '');
    if (n.length != 14) return cnpj;
    return '${n.substring(0, 2)}.${n.substring(2, 5)}.${n.substring(5, 8)}/${n.substring(8, 12)}-${n.substring(12, 14)}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool ok;

  const _CheckItem({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: ok ? AppColors.success : AppColors.inputBorder,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: ok ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
