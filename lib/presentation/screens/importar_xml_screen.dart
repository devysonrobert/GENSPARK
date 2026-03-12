// presentation/screens/importar_xml_screen.dart
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../data/parsers/xml_parser.dart';
import '../../data/parsers/excel_parser.dart';
import '../../domain/models/titulo.dart';

class ImportarXmlScreen extends ConsumerStatefulWidget {
  const ImportarXmlScreen({super.key});

  @override
  ConsumerState<ImportarXmlScreen> createState() =>
      _ImportarXmlScreenState();
}

class _ImportarXmlScreenState extends ConsumerState<ImportarXmlScreen> {
  final List<XmlParseResult> _resultados = [];
  bool _processando = false;
  bool _isDragging = false;

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

      reader.onLoadEnd.listen((_) {
        completer.complete(reader.result as String);
      });
      reader.onError.listen((_) {
        completer.completeError('Erro ao ler arquivo');
      });
      reader.readAsText(file);

      try {
        final conteudo = await completer.future;
        final resultado = XmlNfeParser.parsarXml(conteudo, file.name);
        setState(() {
          _resultados.removeWhere(
              (r) => r.nomeArquivo == resultado.nomeArquivo);
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

  Future<void> _adicionarSelecionados() async {
    final validos = _resultados
        .where((r) => r.sucesso)
        .map((r) => r.titulo!)
        .toList();

    if (validos.isEmpty) {
      showWarningToast(context, 'Nenhum XML válido para adicionar');
      return;
    }

    await ref.read(titulosProvider.notifier).adicionarVarios(validos);

    if (mounted) {
      showSuccessToast(
        context,
        '${validos.length} título(s) adicionado(s) à remessa!',
      );
      ref.read(currentScreenProvider.notifier).state = AppScreen.titulos;
    }
  }

  void _importarExcel() {
    final input = html.FileUploadInputElement()
      ..accept = '.xlsx,.xls';
    input.click();
    input.onChange.listen((event) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final fileList = files.cast<html.File>();
      if (fileList.isEmpty) return;
      final file = fileList.first;

      final reader = html.FileReader();
      final completer = Completer<List<int>>();
      reader.onLoadEnd.listen((_) {
        try {
          final buf = reader.result;
          if (buf is List<int>) {
            completer.complete(buf);
          } else {
            // Convert ArrayBuffer-like result
            completer.complete((buf as dynamic).asUint8List() as List<int>);
          }
        } catch (e) {
          completer.completeError(e);
        }
      });
      reader.readAsArrayBuffer(file);

      try {
        final bytes = await completer.future;
        final resultado = ExcelParser.importar(bytes);
        if (resultado.titulos.isNotEmpty) {
          await ref
              .read(titulosProvider.notifier)
              .adicionarVarios(resultado.titulos);
          if (mounted) {
            showSuccessToast(
              context,
              '${resultado.titulos.length} título(s) importado(s) do Excel!',
            );
          }
        }
        if (resultado.erros.isNotEmpty && mounted) {
          showWarningToast(
            context,
            '${resultado.erros.length} linha(s) com erro na planilha',
          );
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
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'modelo_titulos_cnab240.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
    showInfoToast(context, 'Template Excel baixado!');
  }

  @override
  Widget build(BuildContext context) {
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Importar XMLs',
            subtitle:
                'Importe NF-e (versão 4.00) ou NFS-e (ABRASF 2.04) automaticamente',
            actions: [
              OutlinedButton.icon(
                onPressed: _baixarTemplate,
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Baixar Template Excel'),
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
          _DropZone(
            isDragging: _isDragging,
            processando: _processando,
            onTap: _selecionarArquivos,
          ),

          const SizedBox(height: 24),

          // ── Resultados ────────────────────────────────────
          if (_resultados.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_resultados.length} arquivo(s) processado(s) '
                    '· ${_resultados.where((r) => r.sucesso).length} válido(s) '
                    '· ${_resultados.where((r) => !r.sucesso).length} com erro',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _resultados.clear()),
                  child: const Text('Limpar lista'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _adicionarSelecionados,
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text('Adicionar todos à remessa'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                            width: 160,
                            child: Text('Arquivo', style: _hStyle)),
                        SizedBox(
                            width: 180,
                            child: Text('Sacado/Tomador', style: _hStyle)),
                        SizedBox(
                            width: 180,
                            child: Text('CNPJ/CPF', style: _hStyle)),
                        SizedBox(
                            width: 120,
                            child: Text('Valor', style: _hStyle)),
                        SizedBox(
                            width: 120,
                            child: Text('Nº Doc', style: _hStyle)),
                        SizedBox(
                            width: 80, child: Text('Status', style: _hStyle)),
                        Spacer(),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...(_resultados.map((r) => _XmlResultRow(resultado: r))),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 32),
            const EmptyState(
              icon: Icons.upload_file_outlined,
              title: 'Nenhum arquivo importado',
              message:
                  'Clique no botão acima ou em "Selecionar Arquivos" para importar XMLs.',
            ),
          ],
        ],
      ),
    );
  }
}

const _hStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppColors.textSecondary,
  letterSpacing: 0.5,
);

class _DropZone extends StatelessWidget {
  final bool isDragging;
  final bool processando;
  final VoidCallback onTap;

  const _DropZone({
    required this.isDragging,
    required this.processando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 220,
          decoration: BoxDecoration(
            color: isDragging
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDragging ? AppColors.primary : AppColors.inputBorder,
              width: isDragging ? 2 : 1.5,
            ),
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
                    Icon(
                      Icons.upload_file,
                      size: 56,
                      color: isDragging
                          ? AppColors.primary
                          : AppColors.inputBorder,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Clique para selecionar arquivos XML',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDragging
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aceita: NF-e (v4.00) e NFS-e (ABRASF 2.04) — múltiplos arquivos',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
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

class _XmlResultRow extends StatelessWidget {
  final XmlParseResult resultado;
  const _XmlResultRow({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final t = resultado.titulo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Row(
              children: [
                const Icon(Icons.description, size: 16, color: AppColors.info),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    resultado.nomeArquivo,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              t?.nomeSacado ?? '—',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              t != null
                  ? _formatarDoc(t.cpfCnpjSacado, t.tipoInscricaoSacado)
                  : '—',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              t != null ? formatarMoeda(t.valorNominal) : '—',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              t?.numeroDocumento ?? '—',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 80,
            child: resultado.sucesso
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 12, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('OK',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : Tooltip(
                    message: resultado.error ?? 'Erro desconhecido',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error,
                              size: 12, color: AppColors.error),
                          SizedBox(width: 4),
                          Text('Erro',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
          ),
          if (!resultado.sucesso)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  resultado.error ?? '',
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatarDoc(String doc, TipoInscricao tipo) {
    final limpo = doc.replaceAll(RegExp(r'\D'), '');
    if (tipo == TipoInscricao.cnpj && limpo.length == 14) {
      return '${limpo.substring(0, 2)}.${limpo.substring(2, 5)}.${limpo.substring(5, 8)}/${limpo.substring(8, 12)}-${limpo.substring(12)}';
    } else if (tipo == TipoInscricao.cpf && limpo.length == 11) {
      return '${limpo.substring(0, 3)}.${limpo.substring(3, 6)}.${limpo.substring(6, 9)}-${limpo.substring(9)}';
    }
    return doc;
  }
}
