// presentation/screens/validacao_screen.dart
// Tela de validação CNAB 240 com engine completa
// Suporte a: upload de arquivo externo, validação em tempo real, PDF, bloqueio de download

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/validation/cnab_validator_engine.dart';
import '../../core/validation/models/validation_error.dart';
import '../../core/validation/models/validation_report.dart';
import '../../core/validation/models/validation_result.dart';
import '../../core/validation/widgets/validation_widgets.dart';
import '../../core/validation/rules/santander_specific.dart';
import '../../presentation/providers/app_providers.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ValidacaoScreen extends ConsumerStatefulWidget {
  const ValidacaoScreen({super.key});

  @override
  ConsumerState<ValidacaoScreen> createState() => _ValidacaoScreenState();
}

class _ValidacaoScreenState extends ConsumerState<ValidacaoScreen> {
  RelatorioValidacao? _relatorio;
  bool _validando = false;
  EstadoValidacao? _estadoAtual;
  CnabValidatorEngine? _engine;
  StreamSubscription<EstadoValidacao>? _progressSub;
  String? _nomeArquivoCarregado;
  String? _conteudoArquivoExterno;
  bool _usarArquivoGerado = true;

  // Dicionário de ocorrências para arquivo retorno
  bool _mostrarDicionario = false;

  @override
  void dispose() {
    _engine?.cancelar();
    _progressSub?.cancel();
    _engine?.dispose();
    super.dispose();
  }

  Future<void> _executarValidacao() async {
    final titulos = ref.read(titulosProvider);
    final empresa = ref.read(empresaConfigProvider);

    String? conteudo;

    if (_usarArquivoGerado) {
      // Validar arquivo gerado
      if (titulos.isEmpty) {
        _mostrarSnack('Nenhum título para validar. Adicione títulos primeiro.', Colors.orange);
        return;
      }
      if (!empresa.isConfigured) {
        _mostrarSnack('Configure os dados da empresa antes de validar.', Colors.orange);
        return;
      }

      // Gerar conteúdo CNAB para validar
      try {
        final ultimoArquivo = ref.read(ultimoArquivoGeradoProvider);
        if (ultimoArquivo != null) {
          conteudo = ultimoArquivo;
          _nomeArquivoCarregado = 'arquivo_gerado_cnab240.rem';
        } else {
          _mostrarSnack('Gere o arquivo CNAB primeiro para validar.', Colors.orange);
          return;
        }
      } catch (e) {
        _mostrarSnack('Erro ao acessar arquivo gerado: $e', Colors.red);
        return;
      }
    } else {
      // Validar arquivo externo carregado
      if (_conteudoArquivoExterno == null) {
        _mostrarSnack('Carregue um arquivo .rem/.ret/.txt/.cnab para validar.', Colors.orange);
        return;
      }
      conteudo = _conteudoArquivoExterno!;
    }

    // Cancelar validação anterior
    _engine?.cancelar();
    _progressSub?.cancel();
    _engine?.dispose();

    final engine = CnabValidatorEngine();
    _engine = engine;

    setState(() {
      _validando = true;
      _relatorio = null;
      _estadoAtual = const EstadoValidacao(
        fase: FaseValidacao.estrutural,
        percentual: 0,
        mensagem: 'Iniciando validação...',
      );
    });

    _progressSub = engine.progressoStream.listen((estado) {
      if (mounted) {
        setState(() => _estadoAtual = estado);
      }
    });

    try {
      final relatorio = await engine.validar(
        conteudo,
        nomeArquivo: _nomeArquivoCarregado,
      );

      if (mounted) {
        setState(() {
          _relatorio = relatorio;
          _validando = false;
          _estadoAtual = null;
        });

        // Mostrar toast com resultado
        if (relatorio.aprovado) {
          _mostrarSnack('✅ Arquivo aprovado! Score: ${relatorio.qualityScore}/100', const Color(0xFF4CAF50));
        } else if (relatorio.totalFatais > 0) {
          _mostrarSnack('❌ ${relatorio.totalFatais} erro(s) FATAL(is) encontrado(s). Download bloqueado.', const Color(0xFFB00020));
        } else {
          _mostrarSnack('⚠️ ${relatorio.totalErros} erro(s) encontrado(s). Revise antes de enviar.', Colors.orange);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validando = false;
          _estadoAtual = null;
        });
        _mostrarSnack('Erro durante validação: $e', Colors.red);
      }
    } finally {
      _progressSub?.cancel();
    }
  }

  void _cancelarValidacao() {
    _engine?.cancelar();
    setState(() {
      _validando = false;
      _estadoAtual = null;
    });
    _mostrarSnack('Validação cancelada pelo usuário.', Colors.grey);
  }

  void _carregarArquivoExterno() {
    final input = html.FileUploadInputElement()
      ..accept = '.rem,.ret,.txt,.cnab,.240'
      ..multiple = false;
    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) return;

      final file = files.first;
      _nomeArquivoCarregado = file.name;

      final reader = html.FileReader();
      reader.readAsText(file);

      reader.onLoad.listen((_) {
        final content = reader.result as String;
        setState(() {
          _conteudoArquivoExterno = content;
          _usarArquivoGerado = false;
        });
        _mostrarSnack('Arquivo "${file.name}" carregado (${file.size} bytes).', const Color(0xFF2196F3));
      });
    });
  }

  void _exportarPdfRelatorio() {
    if (_relatorio == null) return;

    // Gerar relatório como texto formatado e download como .txt (PDF real requer lib pdf)
    final buffer = StringBuffer();
    buffer.writeln('=' * 60);
    buffer.writeln('RELATÓRIO DE VALIDAÇÃO CNAB 240 — SANTANDER');
    buffer.writeln('=' * 60);
    buffer.writeln('Data: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('Arquivo: ${_relatorio!.nomeArquivo ?? "não informado"}');
    buffer.writeln('Status: ${_relatorio!.statusLabel}');
    buffer.writeln('Score de Qualidade: ${_relatorio!.qualityScore}/100');
    buffer.writeln('Tempo de validação: ${_relatorio!.tempoTotalMs}ms');
    buffer.writeln('');
    buffer.writeln('RESUMO:');
    buffer.writeln('  Fatais: ${_relatorio!.totalFatais}');
    buffer.writeln('  Erros:  ${_relatorio!.totalErros}');
    buffer.writeln('  Avisos: ${_relatorio!.totalAvisos}');
    buffer.writeln('  Infos:  ${_relatorio!.totalInfos}');

    if (_relatorio!.estatisticas != null) {
      final est = _relatorio!.estatisticas!;
      buffer.writeln('');
      buffer.writeln('ESTATÍSTICAS DO ARQUIVO:');
      buffer.writeln('  Total de linhas: ${est.totalLinhas}');
      buffer.writeln('  Total de lotes: ${est.totalLotes}');
      buffer.writeln('  Total de títulos: ${est.totalTitulos}');
      buffer.writeln('  Valor total: R\$ ${est.valorTotal.toStringAsFixed(2)}');
    }

    buffer.writeln('');
    buffer.writeln('CHECKLIST OBRIGATÓRIO:');
    _relatorio!.checklistObrigatorio.forEach((k, v) {
      buffer.writeln('  [${v ? 'OK' : 'FALHOU'}] $k');
    });

    buffer.writeln('');
    buffer.writeln('OCORRÊNCIAS:');
    buffer.writeln('-' * 60);

    for (final erro in _relatorio!.erros) {
      buffer.writeln('');
      buffer.writeln('[${erro.labelSeveridade}] ${erro.codigo} — ${erro.descricao}');
      if (erro.detalhe != null) buffer.writeln('  Detalhe: ${erro.detalhe}');
      if (erro.linha != null) buffer.writeln('  Linha: ${erro.linha}');
      if (erro.posicaoInicio != null) {
        buffer.writeln('  Posição FEBRABAN: ${erro.posicaoInicio}${erro.posicaoFim != null ? '-${erro.posicaoFim}' : ''}');
      }
      if (erro.campoCnab != null) buffer.writeln('  Campo CNAB: ${erro.campoCnab}');
      if (erro.sugestaoCorrecao != null) buffer.writeln('  Sugestão: ${erro.sugestaoCorrecao}');
      if (erro.referenciaFebraban != null) buffer.writeln('  Ref: ${erro.referenciaFebraban}');
    }

    buffer.writeln('');
    buffer.writeln('=' * 60);
    buffer.writeln('FIM DO RELATÓRIO');

    // Download como .txt
    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = 'relatorio_validacao_cnab240_${DateTime.now().millisecondsSinceEpoch}.txt'
      ..click();
    html.Url.revokeObjectUrl(url);

    _mostrarSnack('Relatório exportado com sucesso!', const Color(0xFF4CAF50));
  }

  void _mostrarSnack(String msg, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: cor,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Column(
        children: [
          // ── Header da tela ────────────────────────────────────────────────
          _buildHeader(),

          // ── Conteúdo principal ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seletor de fonte do arquivo
                  _seletorFonte(),
                  const SizedBox(height: 20),

                  // Painel de progresso (durante validação)
                  if (_validando && _estadoAtual != null)
                    ValidationProgressWidget(
                      estado: _estadoAtual!,
                      onCancelar: _cancelarValidacao,
                    ),

                  // Resultado da validação
                  if (!_validando && _relatorio != null)
                    ValidationPanel(
                      relatorio: _relatorio!,
                      onRevalidar: _executarValidacao,
                      onExportarPdf: _exportarPdfRelatorio,
                      onGerarCnab: _relatorio!.aprovado || _relatorio!.temApenasAvisos
                          ? () {
                              ref.read(currentScreenProvider.notifier).state = AppScreen.gerarCnab;
                            }
                          : null,
                      onCorrigirErro: (erro) {
                        if (erro.indiceTitulo != null) {
                          ref.read(currentScreenProvider.notifier).state = AppScreen.titulos;
                          _mostrarSnack(
                            'Navegando para lista de títulos — corrija o título #${erro.indiceTitulo! + 1}',
                            Colors.orange,
                          );
                        }
                      },
                    ),

                  // Estado inicial (sem validação executada)
                  if (!_validando && _relatorio == null)
                    _estadoInicial(),

                  const SizedBox(height: 20),

                  // Dicionário de ocorrências de retorno
                  _dicionarioOcorrencias(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFFEC0000), size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Validação CNAB 240',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Engine completa FEBRABAN/Santander — 80+ regras',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          // Badge com número de erros (se há relatório)
          if (_relatorio != null)
            Row(
              children: [
                if (_relatorio!.totalFatais > 0)
                  _badgeContador(_relatorio!.totalFatais, 'Fatal', const Color(0xFFB00020)),
                if (_relatorio!.totalErros > 0)
                  _badgeContador(_relatorio!.totalErros, 'Erros', const Color(0xFFF44336)),
                if (_relatorio!.totalAvisos > 0)
                  _badgeContador(_relatorio!.totalAvisos, 'Avisos', const Color(0xFFFF9800)),
              ],
            ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _validando ? null : _executarValidacao,
            icon: _validando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(_validando ? 'Validando...' : 'Executar Validação'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeContador(int count, String label, Color cor) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _seletorFonte() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fonte do arquivo para validação',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _opcaoFonte(
                    titulo: 'Arquivo Gerado',
                    subtitulo: 'Valida o último arquivo CNAB gerado nesta sessão',
                    icone: Icons.receipt_long_rounded,
                    selecionado: _usarArquivoGerado,
                    onTap: () => setState(() => _usarArquivoGerado = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _opcaoFonte(
                    titulo: 'Upload de Arquivo',
                    subtitulo: 'Valida arquivo externo (.rem, .ret, .txt, .cnab)',
                    icone: Icons.upload_file_rounded,
                    selecionado: !_usarArquivoGerado,
                    onTap: () {
                      setState(() => _usarArquivoGerado = false);
                      _carregarArquivoExterno();
                    },
                    badge: _conteudoArquivoExterno != null ? _nomeArquivoCarregado : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _opcaoFonte({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required bool selecionado,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado ? const Color(0xFFEC0000) : const Color(0xFFE0E0E0),
            width: selecionado ? 2 : 1,
          ),
          color: selecionado
              ? const Color(0xFFEC0000).withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icone,
              color: selecionado ? const Color(0xFFEC0000) : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selecionado ? const Color(0xFFEC0000) : Colors.black87,
                    ),
                  ),
                  Text(
                    badge != null ? badge : subtitulo,
                    style: TextStyle(
                      fontSize: 11,
                      color: badge != null ? const Color(0xFF4CAF50) : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selecionado)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFFEC0000), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _estadoInicial() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFEC0000).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFFEC0000),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pronto para Validar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Clique em "Executar Validação" para verificar o arquivo CNAB 240\n'
              'contra as regras FEBRABAN e específicas do Santander.\n\n'
              '• 80+ regras verificadas automaticamente\n'
              '• Estrutural, algoritmos (DAC, CPF, CNPJ), negócio\n'
              '• Score de qualidade 0-100\n'
              '• Download bloqueado em caso de erros fatais',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chipInfo(Icons.timer_outlined, '< 500ms para 1000 títulos'),
                const SizedBox(width: 12),
                _chipInfo(Icons.cancel_outlined, 'Cancelamento suportado'),
                const SizedBox(width: 12),
                _chipInfo(Icons.picture_as_pdf_outlined, 'Relatório exportável'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _dicionarioOcorrencias() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => setState(() => _mostrarDicionario = !_mostrarDicionario),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFFEC0000), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dicionário de Ocorrências de Retorno Santander',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Códigos 01 a 74 — Consulte o significado de cada ocorrência no arquivo de retorno',
                          style: TextStyle(fontSize: 11, color: Color(0xFF757575)),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _mostrarDicionario ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (_mostrarDicionario) ...[
                const Divider(height: 20),
                SizedBox(
                  height: 400,
                  child: ListView(
                    children: DicionarioOcorrenciasSantander.ocorrencias.entries
                        .map((e) => ListTile(
                              dense: true,
                              leading: Container(
                                width: 36,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _corOcorrencia(e.key).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _corOcorrencia(e.key).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  e.key,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _corOcorrencia(e.key),
                                  ),
                                ),
                              ),
                              title: Text(e.value, style: const TextStyle(fontSize: 12)),
                              subtitle: _labelOcorrencia(e.key),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _corOcorrencia(String codigo) {
    if (DicionarioOcorrenciasSantander.isLiquidado(codigo)) return const Color(0xFF4CAF50);
    if (DicionarioOcorrenciasSantander.isRejeitado(codigo)) return const Color(0xFFF44336);
    if (DicionarioOcorrenciasSantander.isBaixado(codigo)) return const Color(0xFFFF9800);
    return const Color(0xFF2196F3);
  }

  Widget? _labelOcorrencia(String codigo) {
    if (DicionarioOcorrenciasSantander.isLiquidado(codigo)) {
      return const Text('Liquidado', style: TextStyle(fontSize: 10, color: Color(0xFF4CAF50)));
    }
    if (DicionarioOcorrenciasSantander.isRejeitado(codigo)) {
      return const Text('Rejeitado', style: TextStyle(fontSize: 10, color: Color(0xFFF44336)));
    }
    if (DicionarioOcorrenciasSantander.isBaixado(codigo)) {
      return const Text('Baixado', style: TextStyle(fontSize: 10, color: Color(0xFFFF9800)));
    }
    return null;
  }
}
