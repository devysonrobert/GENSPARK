// presentation/screens/importar_xml_screen.dart
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../data/parsers/xml_parser.dart';
import '../../data/parsers/excel_parser.dart';
class ImportarXmlScreen extends ConsumerStatefulWidget {
  const ImportarXmlScreen({super.key});

  @override
  ConsumerState<ImportarXmlScreen> createState() => _ImportarXmlScreenState();
}

class _ImportarXmlScreenState extends ConsumerState<ImportarXmlScreen> {
  final List<XmlParseResult> _resultados = [];
  bool _processando = false;

  // ── Selecionar arquivos ───────────────────────────────────────
  void _selecionarArquivos() {
    final input = html.FileUploadInputElement()
      ..accept = '.xml'
      ..multiple = true;
    input.click();
    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        _processarArquivosLista(files.cast<html.File>());
      }
    });
  }

  Future<void> _processarArquivosLista(List<html.File> files) async {
    setState(() => _processando = true);
    for (final file in files) {
      final reader = html.FileReader();
      final completer = Completer<String>();
      reader.onLoadEnd.listen((_) => completer.complete(reader.result as String));
      reader.onError.listen((_) => completer.completeError('Erro ao ler arquivo'));
      reader.readAsText(file);
      try {
        final conteudo = await completer.future;
        final resultado = XmlNfeParser.parsarXml(conteudo, file.name);
        setState(() {
          _resultados.removeWhere((r) => r.nomeArquivo == resultado.nomeArquivo);
          _resultados.add(resultado);
        });
      } catch (e) {
        setState(() {
          _resultados.add(XmlParseResult(
            nomeArquivo: file.name,
            error: 'Erro ao ler arquivo: $e',
          ));
        });
      }
    }
    setState(() => _processando = false);
  }

  // ── Adicionar todos à remessa ─────────────────────────────────
  Future<void> _adicionarTodos() async {
    // Coleta TODOS os títulos de todos os XMLs válidos (todas as parcelas)
    final todos = _resultados
        .where((r) => r.sucesso)
        .expand((r) => r.titulos)
        .toList();

    if (todos.isEmpty) {
      showWarningToast(context, 'Nenhum XML válido para adicionar');
      return;
    }

    await ref.read(titulosProvider.notifier).adicionarVarios(todos);

    if (mounted) {
      final arquivos = _resultados.where((r) => r.sucesso).length;
      showSuccessToast(
        context,
        '${todos.length} título(s) adicionados de $arquivos XML(s)!',
      );
      ref.read(currentScreenProvider.notifier).state = AppScreen.titulos;
    }
  }

  // ── Adicionar só um XML (todas as parcelas desse XML) ─────────
  Future<void> _adicionarXml(XmlParseResult resultado) async {
    await ref.read(titulosProvider.notifier).adicionarVarios(resultado.titulos);
    if (mounted) {
      showSuccessToast(
        context,
        '${resultado.titulos.length} parcela(s) de "${resultado.nomeArquivo}" adicionada(s)!',
      );
    }
  }

  // ── Excel ─────────────────────────────────────────────────────
  void _importarExcel() {
    final input = html.FileUploadInputElement()..accept = '.xlsx,.xls';
    input.click();
    input.onChange.listen((event) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files.cast<html.File>().first;
      final reader = html.FileReader();
      final completer = Completer<List<int>>();
      reader.onLoadEnd.listen((_) {
        try {
          final buf = reader.result;
          completer.complete(buf is List<int>
              ? buf
              : (buf as dynamic).asUint8List() as List<int>);
        } catch (e) {
          completer.completeError(e);
        }
      });
      reader.readAsArrayBuffer(file);
      try {
        final bytes = await completer.future;
        final resultado = ExcelParser.importar(bytes);
        if (resultado.titulos.isNotEmpty) {
          await ref.read(titulosProvider.notifier).adicionarVarios(resultado.titulos);
          if (mounted) {
            showSuccessToast(context,
                '${resultado.titulos.length} título(s) importado(s) do Excel!');
          }
        }
        if (resultado.erros.isNotEmpty && mounted) {
          showWarningToast(
              context, '${resultado.erros.length} linha(s) com erro na planilha');
        }
      } catch (e) {
        if (mounted) showErrorToast(context, 'Erro ao importar Excel: $e');
      }
    });
  }

  void _baixarTemplate() {
    final bytes = ExcelParser.gerarTemplate();
    final blob = html.Blob(
        [bytes],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'modelo_titulos_cnab240.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
    showInfoToast(context, 'Template Excel baixado!');
  }

  // ── Totais ────────────────────────────────────────────────────
  int get _totalTitulos =>
      _resultados.where((r) => r.sucesso).expand((r) => r.titulos).length;

  double get _valorTotalGeral =>
      _resultados.where((r) => r.sucesso).expand((r) => r.titulos).fold(
          0.0, (s, t) => s + t.valorNominal);

  @override
  Widget build(BuildContext context) {
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Importar XMLs',
            subtitle:
                'NF-e (v4.00) e NFS-e (ABRASF 2.04) — todas as parcelas são importadas automaticamente',
            actions: [
              OutlinedButton.icon(
                onPressed: _baixarTemplate,
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Template Excel'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _importarExcel,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Importar Excel'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Drop Zone ─────────────────────────────────────
          _DropZone(processando: _processando, onTap: _selecionarArquivos),

          const SizedBox(height: 24),

          // ── Resultados ────────────────────────────────────
          if (_resultados.isNotEmpty) ...[
            // Barra de resumo geral
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  _resumoBadge(
                    Icons.description_outlined,
                    '${_resultados.where((r) => r.sucesso).length} XML(s)',
                    AppColors.info,
                  ),
                  const SizedBox(width: 20),
                  _resumoBadge(
                    Icons.receipt_long_outlined,
                    '$_totalTitulos parcela(s)',
                    AppColors.success,
                  ),
                  const SizedBox(width: 20),
                  _resumoBadge(
                    Icons.attach_money,
                    formatarMoeda(_valorTotalGeral),
                    AppColors.primary,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _resultados.clear()),
                    child: const Text('Limpar lista'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _totalTitulos > 0 ? _adicionarTodos : null,
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: Text('Adicionar $_totalTitulos título(s) à remessa'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Aviso sobre XMLs com erro
            if (_resultados.any((r) => !r.sucesso))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      '${_resultados.where((r) => !r.sucesso).length} arquivo(s) com erro não serão importados',
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ],
                ),
              ),

            // Lista de XMLs com suas parcelas
            ..._resultados.map((r) => _XmlResultCard(
                  resultado: r,
                  onAdicionar: r.sucesso ? () => _adicionarXml(r) : null,
                )),
          ] else ...[
            const SizedBox(height: 32),
            const EmptyState(
              icon: Icons.upload_file_outlined,
              title: 'Nenhum arquivo importado',
              message:
                  'Clique no botão acima para importar XMLs de NF-e ou NFS-e.\nCada nota pode ter múltiplas parcelas — todas serão importadas.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _resumoBadge(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CARD POR XML — mostra resumo + lista de parcelas expansível
// ══════════════════════════════════════════════════════════════

class _XmlResultCard extends StatefulWidget {
  final XmlParseResult resultado;
  final VoidCallback? onAdicionar;

  const _XmlResultCard({required this.resultado, this.onAdicionar});

  @override
  State<_XmlResultCard> createState() => _XmlResultCardState();
}

class _XmlResultCardState extends State<_XmlResultCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.resultado;
    final sucesso = r.sucesso;

    // Valor total das parcelas deste XML
    final valorTotal = r.titulos.fold(0.0, (s, t) => s + t.valorNominal);
    // Primeiro e último vencimento
    final datas = r.titulos
        .where((t) => t.dataVencimento != null)
        .map((t) => t.dataVencimento!)
        .toList()
      ..sort();
    final primeiroVenc = datas.isNotEmpty ? datas.first : null;
    final ultimoVenc = datas.isNotEmpty ? datas.last : null;
    final sacado = r.titulo?.nomeSacado ?? '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Cabeçalho do XML ────────────────────────────
          InkWell(
            onTap: sucesso ? () => setState(() => _expandido = !_expandido) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: sucesso
                  ? AppColors.background
                  : AppColors.errorLight.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Icon(
                    sucesso ? Icons.description : Icons.error_outline,
                    size: 18,
                    color: sucesso ? AppColors.info : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  // Nome do arquivo
                  SizedBox(
                    width: 220,
                    child: Text(
                      r.nomeArquivo,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sacado
                  if (sucesso) ...[
                    SizedBox(
                      width: 180,
                      child: Text(
                        sacado,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Parcelas
                    _chip(
                      '${r.titulos.length} parcela(s)',
                      AppColors.info,
                      Icons.receipt_long,
                    ),
                    const SizedBox(width: 8),
                    // Valor total
                    _chip(
                      formatarMoeda(valorTotal),
                      AppColors.primary,
                      Icons.attach_money,
                    ),
                    const SizedBox(width: 8),
                    // Período de vencimentos
                    if (primeiroVenc != null)
                      _chip(
                        primeiroVenc == ultimoVenc
                            ? DateFormat('dd/MM/yyyy').format(primeiroVenc)
                            : '${DateFormat('dd/MM/yy').format(primeiroVenc)} → ${DateFormat('dd/MM/yy').format(ultimoVenc!)}',
                        AppColors.textSecondary,
                        Icons.calendar_today,
                      ),
                    const Spacer(),
                    // Botão adicionar este XML
                    TextButton.icon(
                      onPressed: widget.onAdicionar,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Adicionar', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Expandir/colapsar
                    Icon(
                      _expandido ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        r.error ?? 'Erro desconhecido',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.error),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Tabela de parcelas (quando expandido) ────────
          if (sucesso && _expandido) ...[
            const Divider(height: 1),
            // Header da tabela de parcelas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: const Row(
                children: [
                  SizedBox(width: 40, child: Text('#', style: _hStyle)),
                  SizedBox(width: 180, child: Text('Nosso Número', style: _hStyle)),
                  SizedBox(width: 140, child: Text('Vencimento', style: _hStyle)),
                  SizedBox(width: 140, child: Text('Valor Parcela', style: _hStyle)),
                  SizedBox(width: 120, child: Text('Espécie', style: _hStyle)),
                  Spacer(),
                ],
              ),
            ),
            const Divider(height: 1),
            // Linhas das parcelas
            ...r.titulos.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              return Container(
                color: i.isEven ? AppColors.surface : AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    SizedBox(
                      width: 180,
                      child: Text(t.seuNumero,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(
                      width: 140,
                      child: t.dataVencimento != null
                          ? Text(
                              DateFormat('dd/MM/yyyy').format(t.dataVencimento!),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500),
                            )
                          : const Text('—',
                              style:
                                  TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        formatarMoeda(t.valorNominal),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        t.especieTitulo == '01'
                            ? 'DM - Duplicata'
                            : t.especieTitulo == '02'
                                ? 'DS - Serviço'
                                : t.especieTitulo,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t.mensagem1,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Rodapé da tabela
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.04),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const SizedBox(
                    width: 180,
                    child: Text('TOTAL',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 140),
                  SizedBox(
                    width: 140,
                    child: Text(
                      formatarMoeda(valorTotal),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  Text(
                    '${r.titulos.length} parcela(s)',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DROP ZONE
// ══════════════════════════════════════════════════════════════

class _DropZone extends StatelessWidget {
  final bool processando;
  final VoidCallback onTap;
  const _DropZone({required this.processando, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder, width: 1.5),
          ),
          child: processando
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('Processando arquivos XML...'),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file,
                        size: 52, color: AppColors.inputBorder),
                    const SizedBox(height: 12),
                    const Text(
                      'Clique para selecionar arquivos XML',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'NF-e (v4.00) e NFS-e (ABRASF 2.04) — múltiplas parcelas por nota',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('Selecionar Arquivos XML'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

const _hStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppColors.textSecondary,
  letterSpacing: 0.4,
);
