// core/validation/models/validation_report.dart
// Relatório completo de validação de arquivo CNAB 240

import 'validation_error.dart';
import 'validation_result.dart';

/// Estatísticas do arquivo CNAB validado
class EstatisticasArquivo {
  final int totalLinhas;
  final int totalLotes;
  final int totalRegistros; // Segmentos P, Q, R
  final int totalTitulos;
  final int titulosComSegmentoR;
  final double valorTotal;
  final String? nomeArquivo;
  final int? tamanhoBytes;
  final DateTime? dataGeracao;

  const EstatisticasArquivo({
    required this.totalLinhas,
    required this.totalLotes,
    required this.totalRegistros,
    required this.totalTitulos,
    required this.titulosComSegmentoR,
    required this.valorTotal,
    this.nomeArquivo,
    this.tamanhoBytes,
    this.dataGeracao,
  });
}

/// Relatório completo de validação
class RelatorioValidacao {
  /// Timestamp da validação
  final DateTime timestamp;

  /// Nome do arquivo validado
  final String? nomeArquivo;

  /// Conteúdo do arquivo (para exibição de preview)
  final String? conteudoArquivo;

  /// Todos os erros encontrados
  final List<ErroValidacao> erros;

  /// Resultados por regra
  final List<ResultadoRegra> resultadosPorRegra;

  /// Estatísticas do arquivo
  final EstatisticasArquivo? estatisticas;

  /// Tempo total de validação em ms
  final int tempoTotalMs;

  /// Se a validação foi cancelada pelo usuário
  final bool cancelado;

  const RelatorioValidacao({
    required this.timestamp,
    this.nomeArquivo,
    this.conteudoArquivo,
    required this.erros,
    required this.resultadosPorRegra,
    this.estatisticas,
    required this.tempoTotalMs,
    this.cancelado = false,
  });

  // ── Contadores por severidade ──────────────────────────────────────────────

  int get totalFatais =>
      erros.where((e) => e.severidade == SeveridadeValidacao.fatal).length;

  int get totalErros =>
      erros.where((e) => e.severidade == SeveridadeValidacao.erro).length;

  int get totalAvisos =>
      erros.where((e) => e.severidade == SeveridadeValidacao.aviso).length;

  int get totalInfos =>
      erros.where((e) => e.severidade == SeveridadeValidacao.info).length;

  int get totalProblemas => totalFatais + totalErros;

  bool get aprovado => totalFatais == 0 && totalErros == 0;

  bool get temApenasAvisos => totalFatais == 0 && totalErros == 0 && totalAvisos > 0;

  // ── Quality Score ──────────────────────────────────────────────────────────

  /// Score de qualidade de 0 a 100
  int get qualityScore {
    if (cancelado) return 0;

    int score = 100;

    // Fatais: -20 pontos cada (máximo -60)
    final penalFatais = (totalFatais * 20).clamp(0, 60);
    score -= penalFatais;

    // Erros: -8 pontos cada (máximo -25)
    final penalErros = (totalErros * 8).clamp(0, 25);
    score -= penalErros;

    // Avisos: -2 pontos cada (máximo -10)
    final penalAvisos = (totalAvisos * 2).clamp(0, 10);
    score -= penalAvisos;

    return score.clamp(0, 100);
  }

  /// Rótulo do status baseado no score e aprovação
  String get statusLabel {
    if (cancelado) return 'Cancelado';
    if (totalFatais > 0) return 'Inválido — Bloqueado';
    if (totalErros > 0) return 'Com Erros — Revisar';
    if (totalAvisos > 0) return 'Aprovado com Avisos';
    return 'Aprovado ✓';
  }

  /// Cor de status (hex string para UI)
  String get corStatus {
    if (cancelado) return '#9E9E9E';
    if (totalFatais > 0) return '#B00020';
    if (totalErros > 0) return '#F44336';
    if (totalAvisos > 0) return '#FF9800';
    return '#4CAF50';
  }

  // ── Filtros por categoria ─────────────────────────────────────────────────

  List<ErroValidacao> get errosFatais =>
      erros.where((e) => e.severidade == SeveridadeValidacao.fatal).toList();

  List<ErroValidacao> get errosGraves =>
      erros.where((e) => e.severidade == SeveridadeValidacao.erro).toList();

  List<ErroValidacao> get avisos =>
      erros.where((e) => e.severidade == SeveridadeValidacao.aviso).toList();

  List<ErroValidacao> get infos =>
      erros.where((e) => e.severidade == SeveridadeValidacao.info).toList();

  List<ErroValidacao> errosPorCategoria(CategoriaValidacao categoria) =>
      erros.where((e) => e.categoria == categoria).toList();

  // ── Checklist de validações obrigatórias ─────────────────────────────────

  /// Checklist dos itens obrigatórios do arquivo CNAB
  Map<String, bool> get checklistObrigatorio {
    final codigosErroPresentes = erros.map((e) => e.codigo).toSet();
    return {
      'Tamanho de linha 240 chars': !codigosErroPresentes.contains('STR002'),
      'Terminador CRLF': !codigosErroPresentes.contains('STR003'),
      'Header de Arquivo presente': !codigosErroPresentes.contains('STR004'),
      'Trailer de Arquivo presente': !codigosErroPresentes.contains('STR005'),
      'Código banco 033 correto': !codigosErroPresentes.contains('HA001'),
      'CNPJ do cedente válido': !codigosErroPresentes.contains('HA005'),
      'Agência Santander 4 dígitos': !codigosErroPresentes.contains('HA007'),
      'Conta 8 dígitos': !codigosErroPresentes.contains('HA008'),
      'Convênio 7 dígitos': !codigosErroPresentes.contains('HA009'),
      'Header de Lote presente': !codigosErroPresentes.contains('STR006'),
      'Trailer de Lote presente': !codigosErroPresentes.contains('STR007'),
      'Segmentos P presentes': !codigosErroPresentes.contains('STR008'),
      'Segmentos Q presentes': !codigosErroPresentes.contains('STR009'),
      'DAC calculado corretamente': !codigosErroPresentes.contains('ALG001'),
      'Datas de vencimento válidas': !codigosErroPresentes.contains('SP010'),
      'Valores positivos': !codigosErroPresentes.contains('SP012'),
      'CPF/CNPJ sacado válido': !codigosErroPresentes.contains('SQ001'),
      'Nome sacado preenchido': !codigosErroPresentes.contains('SQ004'),
      'Contadores de trailer corretos': !codigosErroPresentes.contains('TA001'),
    };
  }

  /// Exporta para JSON (para histórico)
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'nomeArquivo': nomeArquivo,
        'tempoTotalMs': tempoTotalMs,
        'qualityScore': qualityScore,
        'statusLabel': statusLabel,
        'totalFatais': totalFatais,
        'totalErros': totalErros,
        'totalAvisos': totalAvisos,
        'totalInfos': totalInfos,
        'aprovado': aprovado,
        'cancelado': cancelado,
        'estatisticas': estatisticas == null
            ? null
            : {
                'totalLinhas': estatisticas!.totalLinhas,
                'totalLotes': estatisticas!.totalLotes,
                'totalTitulos': estatisticas!.totalTitulos,
                'valorTotal': estatisticas!.valorTotal,
              },
      };
}
