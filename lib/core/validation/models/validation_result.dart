// core/validation/models/validation_result.dart
// Resultado de uma regra de validação individual

import 'validation_error.dart';

/// Resultado da execução de uma regra de validação
class ResultadoRegra {
  /// Nome da regra executada
  final String nomeRegra;

  /// Erros encontrados pela regra (vazio = passou)
  final List<ErroValidacao> erros;

  /// Tempo de execução em milissegundos
  final int tempoExecucaoMs;

  const ResultadoRegra({
    required this.nomeRegra,
    required this.erros,
    this.tempoExecucaoMs = 0,
  });

  bool get passou => erros.isEmpty;

  bool get temFatal =>
      erros.any((e) => e.severidade == SeveridadeValidacao.fatal);

  bool get temErro =>
      erros.any((e) => e.severidade == SeveridadeValidacao.erro);

  factory ResultadoRegra.sucesso(String nomeRegra, {int tempoMs = 0}) =>
      ResultadoRegra(
        nomeRegra: nomeRegra,
        erros: const [],
        tempoExecucaoMs: tempoMs,
      );

  factory ResultadoRegra.falha(
    String nomeRegra,
    List<ErroValidacao> erros, {
    int tempoMs = 0,
  }) =>
      ResultadoRegra(
        nomeRegra: nomeRegra,
        erros: erros,
        tempoExecucaoMs: tempoMs,
      );
}

/// Fase de validação no pipeline
enum FaseValidacao {
  estrutural,
  parsing,
  headerArquivo,
  trailerArquivo,
  headerLote,
  trailerLote,
  segmentoP,
  segmentoQ,
  segmentoR,
  verificacoesCruzadas,
  regrasNegocio,
  algoritmicas,
  santander,
  concluido,
}

/// Estado atual da validação (para progress bar)
class EstadoValidacao {
  final FaseValidacao fase;
  final int percentual; // 0-100
  final String mensagem;
  final bool cancelado;

  const EstadoValidacao({
    required this.fase,
    required this.percentual,
    required this.mensagem,
    this.cancelado = false,
  });

  String get labelFase {
    switch (fase) {
      case FaseValidacao.estrutural:
        return 'Validação estrutural';
      case FaseValidacao.parsing:
        return 'Parsing do arquivo';
      case FaseValidacao.headerArquivo:
        return 'Validando Header de Arquivo';
      case FaseValidacao.trailerArquivo:
        return 'Validando Trailer de Arquivo';
      case FaseValidacao.headerLote:
        return 'Validando Header de Lote';
      case FaseValidacao.trailerLote:
        return 'Validando Trailer de Lote';
      case FaseValidacao.segmentoP:
        return 'Validando Segmentos P';
      case FaseValidacao.segmentoQ:
        return 'Validando Segmentos Q';
      case FaseValidacao.segmentoR:
        return 'Validando Segmentos R';
      case FaseValidacao.verificacoesCruzadas:
        return 'Verificações cruzadas';
      case FaseValidacao.regrasNegocio:
        return 'Regras de negócio';
      case FaseValidacao.algoritmicas:
        return 'Validações algorítmicas';
      case FaseValidacao.santander:
        return 'Regras específicas Santander';
      case FaseValidacao.concluido:
        return 'Validação concluída';
    }
  }
}
