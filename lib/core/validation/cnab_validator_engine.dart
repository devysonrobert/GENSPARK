// core/validation/cnab_validator_engine.dart
// Engine orquestradora de validação CNAB 240
// Processa o arquivo em pipeline: estrutural → parsing → headers → segmentos → negócio → algoritmos → Santander
// Suporte a cancelamento e progress bar via Stream

import 'dart:async';
import 'models/validation_error.dart';
import 'models/validation_result.dart';
import 'models/validation_report.dart';
import 'rules/structural_rules.dart';
import 'rules/header_arquivo_rules.dart';
import 'rules/header_lote_rules.dart';
import 'rules/segmento_p_rules.dart';
import 'rules/segmento_q_rules.dart';
import 'rules/segmento_r_rules.dart';
import 'rules/trailer_rules.dart';
import 'rules/business_rules.dart';
import 'rules/algorithm_rules.dart';
import 'rules/santander_specific.dart';

/// Contexto de parsing do arquivo CNAB 240
class CnabParsingContext {
  final List<String> linhas;
  late String headerArquivo;
  late String trailerArquivo;
  final List<_LoteContext> lotes = [];

  String? _headerArquivoNullable;
  String? _trailerArquivoNullable;

  CnabParsingContext(this.linhas);

  String? get headerArquivoNullable => _headerArquivoNullable;
  String? get trailerArquivoNullable => _trailerArquivoNullable;

  // Todos os segmentos P (para validações em lote)
  List<String> get todosSegmentosP =>
      lotes.expand((l) => l.segmentosP).toList();

  List<String> get todosSegmentosQ =>
      lotes.expand((l) => l.segmentosQ).toList();

  List<String> get todosSegmentosR =>
      lotes.expand((l) => l.segmentosR).toList();

  List<int> get todasLinhasP =>
      lotes.expand((l) => l.linhasP).toList();

  List<int> get todasLinhasQ =>
      lotes.expand((l) => l.linhasQ).toList();

  List<int> get todasLinhasR =>
      lotes.expand((l) => l.linhasR).toList();
}

class _LoteContext {
  final int numeroLote;
  final int linhaHeader;
  String headerLinha;
  String? trailerLinha;
  int? linhaTrailer;

  final List<String> segmentosP = [];
  final List<String> segmentosQ = [];
  final List<String> segmentosR = [];
  final List<int> linhasP = [];
  final List<int> linhasQ = [];
  final List<int> linhasR = [];

  int get totalRegistros =>
      1 + segmentosP.length + segmentosQ.length + segmentosR.length + 1;

  _LoteContext({
    required this.numeroLote,
    required this.linhaHeader,
    required this.headerLinha,
  });
}

/// Engine principal de validação CNAB 240
class CnabValidatorEngine {
  bool _cancelado = false;

  // Controller para emitir progresso
  final _progressController = StreamController<EstadoValidacao>.broadcast();
  Stream<EstadoValidacao> get progressoStream => _progressController.stream;

  void cancelar() => _cancelado = true;

  void dispose() {
    _progressController.close();
  }

  void _emitirProgresso(FaseValidacao fase, int percentual, String mensagem) {
    if (!_progressController.isClosed) {
      _progressController.add(EstadoValidacao(
        fase: fase,
        percentual: percentual,
        mensagem: mensagem,
        cancelado: _cancelado,
      ));
    }
  }

  /// Método principal: valida conteúdo de arquivo CNAB 240
  Future<RelatorioValidacao> validar(
    String conteudo, {
    String? nomeArquivo,
  }) async {
    final stopwatch = Stopwatch()..start();
    _cancelado = false;

    final todosResultados = <ResultadoRegra>[];
    final todosErros = <ErroValidacao>[];

    // ── FASE 1: Validação Estrutural ────────────────────────────────────────
    _emitirProgresso(FaseValidacao.estrutural, 5, 'Iniciando validação estrutural...');

    // Normalizar separadores de linha
    final conteudoNorm = conteudo.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final linhas = conteudoNorm
        .split('\n')
        .where((l) => l.isNotEmpty)
        .toList();

    final regraEstruturais = RegraEstrutural.validarTudo(conteudo, linhas);
    todosResultados.addAll(regraEstruturais);
    todosErros.addAll(regraEstruturais.expand((r) => r.erros));

    if (_cancelado) return _criarRelatorioCancelado(nomeArquivo, linhas, todosErros, todosResultados, stopwatch.elapsedMilliseconds);

    // Se há erros fatais estruturais, parar aqui
    final temFatalEstrutural = regraEstruturais.any((r) => r.temFatal);
    if (temFatalEstrutural && linhas.isEmpty) {
      return _criarRelatorio(nomeArquivo, conteudo, linhas, todosErros, todosResultados, stopwatch.elapsedMilliseconds);
    }

    _emitirProgresso(FaseValidacao.estrutural, 15, 'Estrutura básica OK. Iniciando parsing...');

    // ── FASE 2: Parsing ──────────────────────────────────────────────────────
    _emitirProgresso(FaseValidacao.parsing, 20, 'Analisando registros do arquivo...');

    final ctx = _parsearArquivo(linhas);

    if (_cancelado) return _criarRelatorioCancelado(nomeArquivo, linhas, todosErros, todosResultados, stopwatch.elapsedMilliseconds);

    // ── FASE 3: Header de Arquivo ────────────────────────────────────────────
    _emitirProgresso(FaseValidacao.headerArquivo, 25, 'Validando Header de Arquivo...');

    if (ctx.headerArquivoNullable != null) {
      final regrasHeader = RegraHeaderArquivo.validarTudo(ctx.headerArquivoNullable!);
      todosResultados.addAll(regrasHeader);
      todosErros.addAll(regrasHeader.expand((r) => r.erros));
    }

    // ── FASE 4: Lotes (Header + Trailers) ────────────────────────────────────
    _emitirProgresso(FaseValidacao.headerLote, 30, 'Validando Headers/Trailers de Lote...');

    for (final lote in ctx.lotes) {
      if (_cancelado) break;

      final regrasHeaderLote = RegraHeaderLote.validarTudo(lote.headerLinha, lote.linhaHeader);
      todosResultados.addAll(regrasHeaderLote);
      todosErros.addAll(regrasHeaderLote.expand((r) => r.erros));

      if (lote.trailerLinha != null && lote.linhaTrailer != null) {
        final regrasTrailerLote = RegraTrailerLote.validarTudo(
          lote.trailerLinha!,
          lote.linhaTrailer!,
          lote.totalRegistros,
          lote.segmentosP.length,
        );
        todosResultados.addAll(regrasTrailerLote);
        todosErros.addAll(regrasTrailerLote.expand((r) => r.erros));
      }
    }

    // ── FASE 5: Trailer de Arquivo ────────────────────────────────────────────
    _emitirProgresso(FaseValidacao.trailerArquivo, 40, 'Validando Trailer de Arquivo...');

    if (ctx.trailerArquivoNullable != null) {
      final regrasTrailerArq = RegraTrailerArquivo.validarTudo(
        ctx.trailerArquivoNullable!,
        linhas.length,
        ctx.lotes.length,
        linhas.length,
      );
      todosResultados.addAll(regrasTrailerArq);
      todosErros.addAll(regrasTrailerArq.expand((r) => r.erros));
    }

    if (_cancelado) return _criarRelatorioCancelado(nomeArquivo, linhas, todosErros, todosResultados, stopwatch.elapsedMilliseconds);

    // ── FASE 6: Segmentos P ──────────────────────────────────────────────────
    _emitirProgresso(FaseValidacao.segmentoP, 50, 'Validando Segmentos P (${ctx.todosSegmentosP.length} títulos)...');

    final segP = ctx.todosSegmentosP;
    final linhasP = ctx.todasLinhasP;
    int nrSeq = 2; // começa em 2 (header lote = 1, segP = 2)

    for (int i = 0; i < segP.length; i++) {
      if (_cancelado) break;

      final regrasP = RegraSegmentoP.validarTudo(segP[i], i < linhasP.length ? linhasP[i] : 0, i, nrSeq);
      todosResultados.addAll(regrasP);
      todosErros.addAll(regrasP.expand((r) => r.erros));

      // Atualizar progresso a cada 100 títulos
      if (i % 100 == 0 && segP.length > 100) {
        final pct = 50 + ((i / segP.length) * 10).toInt();
        _emitirProgresso(FaseValidacao.segmentoP, pct,
            'Validando Segmento P: ${i + 1}/${segP.length}...');
        await Future.delayed(Duration.zero); // yield para UI
      }
      nrSeq += 3; // P, Q, [R]
    }

    // ── FASE 7: Segmentos Q ──────────────────────────────────────────────────
    _emitirProgresso(FaseValidacao.segmentoQ, 60, 'Validando Segmentos Q...');

    final segQ = ctx.todosSegmentosQ;
    final linhasQ = ctx.todasLinhasQ;

    for (int i = 0; i < segQ.length; i++) {
      if (_cancelado) break;

      final regrasQ = RegraSegmentoQ.validarTudo(segQ[i], i < linhasQ.length ? linhasQ[i] : 0, i);
      todosResultados.addAll(regrasQ);
      todosErros.addAll(regrasQ.expand((r) => r.erros));

      if (i % 100 == 0 && segQ.length > 100) {
        await Future.delayed(Duration.zero);
      }
    }

    // ── FASE 8: Segmentos R ──────────────────────────────────────────────────
    _emitirProgresso(FaseValidacao.segmentoR, 67, 'Validando Segmentos R...');

    final segR = ctx.todosSegmentosR;
    final linhasR = ctx.todasLinhasR;

    // Para validar R precisamos do vencimento do P correspondente
    for (int i = 0; i < segR.length; i++) {
      if (_cancelado) break;

      String dataVenc = '00000000';
      if (i < segP.length && segP[i].length >= 80) {
        dataVenc = segP[i].substring(72, 80);
      }

      final regrasR = RegraSegmentoR.validarTudo(
          segR[i], i < linhasR.length ? linhasR[i] : 0, i, dataVenc);
      todosResultados.addAll(regrasR);
      todosErros.addAll(regrasR.expand((r) => r.erros));
    }

    if (_cancelado) return _criarRelatorioCancelado(nomeArquivo, linhas, todosErros, todosResultados, stopwatch.elapsedMilliseconds);

    // ── FASE 9: Verificações Cruzadas (Negócio) ──────────────────────────────
    _emitirProgresso(FaseValidacao.verificacoesCruzadas, 75, 'Executando verificações cruzadas...');

    final trailerLoteStr = ctx.lotes.isNotEmpty ? ctx.lotes.last.trailerLinha : null;
    final numLinhaTrailerLote = ctx.lotes.isNotEmpty ? (ctx.lotes.last.linhaTrailer ?? linhas.length - 1) : linhas.length - 1;

    final regrasNegocio = RegraNegocios.validarTodo(
      linhas: linhas,
      segmentosP: segP,
      segmentosQ: segQ,
      linhasP: linhasP,
      linhasQ: linhasQ,
      trailerLote: trailerLoteStr,
      numLinhaTrailerLote: numLinhaTrailerLote,
      headerArquivo: ctx.headerArquivoNullable,
      qtdLotes: ctx.lotes.length,
      qtdTitulos: segP.length,
    );
    todosResultados.addAll(regrasNegocio);
    todosErros.addAll(regrasNegocio.expand((r) => r.erros));

    // ── FASE 10: Validações Algorítmicas ─────────────────────────────────────
    _emitirProgresso(FaseValidacao.algoritmicas, 85, 'Executando validações algorítmicas (DAC, CPF, CNPJ)...');

    final regrasAlg = RegraAlgoritmica.validarTodo(
      headerArquivo: ctx.headerArquivoNullable ?? '',
      segmentosP: segP,
      segmentosQ: segQ,
      linhasP: linhasP,
      linhasQ: linhasQ,
    );
    todosResultados.addAll(regrasAlg);
    todosErros.addAll(regrasAlg.expand((r) => r.erros));

    // ── FASE 11: Regras Santander ─────────────────────────────────────────────
    _emitirProgresso(FaseValidacao.santander, 93, 'Aplicando regras específicas Santander...');

    final headerLoteStr = ctx.lotes.isNotEmpty ? ctx.lotes.first.headerLinha : null;

    final regrasSantander = RegraSantanderEspecifica.validarTodo(
      headerArquivo: ctx.headerArquivoNullable,
      headerLote: headerLoteStr,
      segmentosP: segP,
      linhasP: linhasP,
    );
    todosResultados.addAll(regrasSantander);
    todosErros.addAll(regrasSantander.expand((r) => r.erros));

    // ── FASE 12: Concluído ────────────────────────────────────────────────────
    _emitirProgresso(FaseValidacao.concluido, 100, 'Validação concluída!');

    // Calcular estatísticas
    final estatisticas = _calcularEstatisticas(linhas, ctx);

    return RelatorioValidacao(
      timestamp: DateTime.now(),
      nomeArquivo: nomeArquivo,
      conteudoArquivo: conteudo.length > 50000
          ? conteudo.substring(0, 50000)
          : conteudo, // limitar preview a 50KB
      erros: todosErros,
      resultadosPorRegra: todosResultados,
      estatisticas: estatisticas,
      tempoTotalMs: stopwatch.elapsedMilliseconds,
    );
  }

  // ── Parsing do arquivo ────────────────────────────────────────────────────

  CnabParsingContext _parsearArquivo(List<String> linhas) {
    final ctx = CnabParsingContext(linhas);
    _LoteContext? loteAtual;

    for (int i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      if (linha.length < 8) continue;

      final tipoReg = linha.substring(7, 8);
      final segmento = linha.length >= 14 ? linha.substring(13, 14) : '';

      switch (tipoReg) {
        case '0': // Header de Arquivo
          ctx._headerArquivoNullable = linha;
          break;

        case '9': // Trailer de Arquivo
          ctx._trailerArquivoNullable = linha;
          break;

        case '1': // Header de Lote
          final numLote = int.tryParse(linha.substring(3, 7)) ?? ctx.lotes.length + 1;
          loteAtual = _LoteContext(
            numeroLote: numLote,
            linhaHeader: i + 1,
            headerLinha: linha,
          );
          ctx.lotes.add(loteAtual);
          break;

        case '5': // Trailer de Lote
          if (loteAtual != null) {
            loteAtual.trailerLinha = linha;
            loteAtual.linhaTrailer = i + 1;
          }
          loteAtual = null;
          break;

        case '3': // Detalhe (Segmentos P, Q, R)
          if (loteAtual == null) {
            // Detalhe fora de lote — criar lote temporário
            loteAtual = _LoteContext(
              numeroLote: ctx.lotes.length + 1,
              linhaHeader: i,
              headerLinha: '',
            );
            ctx.lotes.add(loteAtual);
          }

          switch (segmento) {
            case 'P':
              loteAtual.segmentosP.add(linha);
              loteAtual.linhasP.add(i + 1);
              break;
            case 'Q':
              loteAtual.segmentosQ.add(linha);
              loteAtual.linhasQ.add(i + 1);
              break;
            case 'R':
              loteAtual.segmentosR.add(linha);
              loteAtual.linhasR.add(i + 1);
              break;
          }
          break;
      }
    }

    return ctx;
  }

  // ── Estatísticas ──────────────────────────────────────────────────────────

  EstatisticasArquivo _calcularEstatisticas(
      List<String> linhas, CnabParsingContext ctx) {
    int valorTotal = 0;
    int titulosComSegR = 0;

    for (final seg in ctx.todosSegmentosP) {
      if (seg.length >= 95) {
        valorTotal += int.tryParse(seg.substring(80, 95)) ?? 0;
      }
    }

    titulosComSegR = ctx.todosSegmentosR.length;

    DateTime? dataGeracao;
    if (ctx.headerArquivoNullable != null &&
        ctx.headerArquivoNullable!.length >= 151) {
      try {
        final ds = ctx.headerArquivoNullable!.substring(143, 151);
        dataGeracao = DateTime(
          int.parse(ds.substring(4, 8)),
          int.parse(ds.substring(2, 4)),
          int.parse(ds.substring(0, 2)),
        );
      } catch (_) {}
    }

    return EstatisticasArquivo(
      totalLinhas: linhas.length,
      totalLotes: ctx.lotes.length,
      totalRegistros: ctx.todosSegmentosP.length +
          ctx.todosSegmentosQ.length +
          ctx.todosSegmentosR.length,
      totalTitulos: ctx.todosSegmentosP.length,
      titulosComSegmentoR: titulosComSegR,
      valorTotal: valorTotal / 100.0,
      dataGeracao: dataGeracao,
    );
  }

  RelatorioValidacao _criarRelatorio(
    String? nomeArquivo,
    String conteudo,
    List<String> linhas,
    List<ErroValidacao> erros,
    List<ResultadoRegra> resultados,
    int tempoMs,
  ) {
    return RelatorioValidacao(
      timestamp: DateTime.now(),
      nomeArquivo: nomeArquivo,
      conteudoArquivo: conteudo.length > 10000 ? conteudo.substring(0, 10000) : conteudo,
      erros: erros,
      resultadosPorRegra: resultados,
      tempoTotalMs: tempoMs,
    );
  }

  RelatorioValidacao _criarRelatorioCancelado(
    String? nomeArquivo,
    List<String> linhas,
    List<ErroValidacao> erros,
    List<ResultadoRegra> resultados,
    int tempoMs,
  ) {
    return RelatorioValidacao(
      timestamp: DateTime.now(),
      nomeArquivo: nomeArquivo,
      erros: erros,
      resultadosPorRegra: resultados,
      tempoTotalMs: tempoMs,
      cancelado: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Validação rápida: para uso no fluxo de geração (pré-download)
// ─────────────────────────────────────────────────────────────────────────────

/// Validação rápida sem stream de progresso — para bloqueio de download
Future<RelatorioValidacao> validarRapido(
    String conteudoCnab, String? nomeArquivo) async {
  final engine = CnabValidatorEngine();
  try {
    return await engine.validar(conteudoCnab, nomeArquivo: nomeArquivo);
  } finally {
    engine.dispose();
  }
}
