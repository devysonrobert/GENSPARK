// core/validation/rules/trailer_lote_rules.dart
// Regras de validação do Trailer de Lote CNAB 240
// FEBRABAN CNAB 240 v10.7 — Registro Trailer de Lote (Tipo 5)

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraTrailerLote {
  // ── Posições FEBRABAN do Trailer de Lote ────────────────────────────────
  // Pos  1- 3: Código do Banco (033)
  // Pos  4- 7: Número do Lote
  // Pos     8: Tipo de Registro (5)
  // Pos  9-17: Uso exclusivo FEBRABAN (brancos)
  // Pos 18-23: Quantidade de Registros no Lote (incluindo header e trailer do lote)
  // Pos 24-29: Quantidade de Títulos em Cobrança
  // Pos 30-46: Valor Total dos Títulos em Carteira (17 dígitos, 2 decimais)
  // Pos 47-62: Quantidade de Títulos em Cobrança Simples
  // Pos 63-79: Valor Total dos Títulos em Cobrança Simples
  // Pos 80-240: (outros contadores — uso Banco)

  /// TL001 — Código do banco deve ser 033
  static ResultadoRegra tL001CodigoBanco(String trailer, int numLinha) {
    final sw = Stopwatch()..start();
    if (trailer.length < 3) {
      return ResultadoRegra.sucesso('TL001', tempoMs: sw.elapsedMilliseconds);
    }

    final banco = trailer.substring(0, 3);
    if (banco != '033') {
      return ResultadoRegra.falha('TL001', [
        ErroValidacao(
          codigo: 'TL001',
          descricao: 'Código do banco inválido no Trailer de Lote',
          detalhe: 'Encontrado: "$banco". Esperado: "033"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.trailerLote,
          linha: numLinha,
          posicaoInicio: 1,
          posicaoFim: 3,
          campoCnab: 'Código do Banco',
          sugestaoCorrecao: 'O código do banco Santander é 033',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('TL001', tempoMs: sw.elapsedMilliseconds);
  }

  /// TL002 — Tipo de registro deve ser 5 (Trailer de Lote)
  static ResultadoRegra tL002TipoRegistro(String trailer, int numLinha) {
    final sw = Stopwatch()..start();
    if (trailer.length < 8) {
      return ResultadoRegra.sucesso('TL002', tempoMs: sw.elapsedMilliseconds);
    }

    final tipo = trailer.substring(7, 8);
    if (tipo != '5') {
      return ResultadoRegra.falha('TL002', [
        ErroValidacao(
          codigo: 'TL002',
          descricao: 'Tipo de registro do Trailer de Lote inválido',
          detalhe: 'Encontrado: "$tipo". Esperado: "5"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.trailerLote,
          linha: numLinha,
          posicaoInicio: 8,
          posicaoFim: 8,
          campoCnab: 'Tipo de Registro',
          sugestaoCorrecao:
              'Trailer de Lote deve ter tipo de registro = 5',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 8: Tipo de Registro = 5',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('TL002', tempoMs: sw.elapsedMilliseconds);
  }

  /// TL003 — Quantidade de registros no lote deve ser numérica e ≥ 4
  static ResultadoRegra tL003QtdRegistros(
      String trailer, int numLinha, int qtdRegistrosEsperada) {
    final sw = Stopwatch()..start();
    if (trailer.length < 23) {
      return ResultadoRegra.sucesso('TL003', tempoMs: sw.elapsedMilliseconds);
    }

    // Posição 18-23 (índice 17-22) = 6 dígitos
    final qtdStr = trailer.substring(17, 23);
    final qtd = int.tryParse(qtdStr);

    if (qtd == null) {
      return ResultadoRegra.falha('TL003', [
        ErroValidacao(
          codigo: 'TL003',
          descricao:
              'Quantidade de registros no Trailer de Lote não é numérico',
          detalhe: 'Valor: "$qtdStr"',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.trailerLote,
          linha: numLinha,
          posicaoInicio: 18,
          posicaoFim: 23,
          campoCnab: 'Quantidade de Registros no Lote',
          sugestaoCorrecao:
              'Use 6 dígitos numéricos (ex: 000006)',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 18-23: Qtd Registros do Lote',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    if (qtd != qtdRegistrosEsperada) {
      return ResultadoRegra.falha('TL003', [
        ErroValidacao(
          codigo: 'TL003',
          descricao:
              'Quantidade de registros no Trailer de Lote diverge da contagem real',
          detalhe:
              'Declarado: $qtd | Contado: $qtdRegistrosEsperada',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.trailerLote,
          linha: numLinha,
          posicaoInicio: 18,
          posicaoFim: 23,
          campoCnab: 'Quantidade de Registros no Lote',
          sugestaoCorrecao:
              'Atualize o contador de registros no Trailer de Lote',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 18-23: Qtd Registros do Lote',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('TL003', tempoMs: sw.elapsedMilliseconds);
  }

  /// TL004 — Quantidade de títulos (cobrança) deve ser numérica
  static ResultadoRegra tL004QtdTitulos(String trailer, int numLinha, int qtdEsperada) {
    final sw = Stopwatch()..start();
    if (trailer.length < 29) {
      return ResultadoRegra.sucesso('TL004', tempoMs: sw.elapsedMilliseconds);
    }

    // Posição 24-29 (índice 23-28) = 6 dígitos
    final qtdStr = trailer.substring(23, 29);
    final qtd = int.tryParse(qtdStr);

    if (qtd == null) {
      return ResultadoRegra.falha('TL004', [
        ErroValidacao(
          codigo: 'TL004',
          descricao: 'Quantidade de títulos no Trailer de Lote não é numérica',
          detalhe: 'Valor: "$qtdStr"',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.trailerLote,
          linha: numLinha,
          posicaoInicio: 24,
          posicaoFim: 29,
          campoCnab: 'Quantidade de Títulos em Cobrança',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    if (qtd != qtdEsperada) {
      return ResultadoRegra.falha('TL004', [
        ErroValidacao(
          codigo: 'TL004',
          descricao: 'Quantidade de títulos no Trailer de Lote diverge da contagem',
          detalhe: 'Declarado: $qtd | Contado: $qtdEsperada',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.trailerLote,
          linha: numLinha,
          posicaoInicio: 24,
          posicaoFim: 29,
          campoCnab: 'Quantidade de Títulos em Cobrança',
          sugestaoCorrecao: 'Atualize a contagem de títulos no Trailer de Lote',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('TL004', tempoMs: sw.elapsedMilliseconds);
  }

  /// TL005 — Valor total dos títulos deve ser numérico e > 0
  static ResultadoRegra tL005ValorTotal(String trailer, int numLinha) {
    final sw = Stopwatch()..start();
    if (trailer.length < 46) {
      return ResultadoRegra.sucesso('TL005', tempoMs: sw.elapsedMilliseconds);
    }

    // Posição 30-46 (índice 29-45) = 17 dígitos
    final valorStr = trailer.substring(29, 46);
    final valor = int.tryParse(valorStr);

    if (valor == null) {
      return ResultadoRegra.falha('TL005', [
        ErroValidacao(
          codigo: 'TL005',
          descricao: 'Valor total no Trailer de Lote não é numérico',
          detalhe: 'Valor: "$valorStr"',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.trailerLote,
          linha: numLinha,
          posicaoInicio: 30,
          posicaoFim: 46,
          campoCnab: 'Valor Total dos Títulos em Carteira',
          sugestaoCorrecao: 'Use 17 dígitos numéricos (15 inteiros + 2 centavos)',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 30-46: Valor Total Cobrança',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    if (valor == 0) {
      return ResultadoRegra.falha('TL005', [
        ErroValidacao(
          codigo: 'TL005',
          descricao: 'Valor total dos títulos zerado no Trailer de Lote',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.trailerLote,
          linha: numLinha,
          posicaoInicio: 30,
          posicaoFim: 46,
          campoCnab: 'Valor Total dos Títulos em Carteira',
          sugestaoCorrecao:
              'Verifique se os valores dos títulos foram preenchidos corretamente',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('TL005', tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras de Trailer de Lote
  static List<ResultadoRegra> validarTudo(
      String trailerLinha, int numLinha, int qtdRegistros, int qtdTitulos) {
    return [
      tL001CodigoBanco(trailerLinha, numLinha),
      tL002TipoRegistro(trailerLinha, numLinha),
      tL003QtdRegistros(trailerLinha, numLinha, qtdRegistros),
      tL004QtdTitulos(trailerLinha, numLinha, qtdTitulos),
      tL005ValorTotal(trailerLinha, numLinha),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// core/validation/rules/trailer_arquivo_rules.dart
// Regras de validação do Trailer de Arquivo CNAB 240
// FEBRABAN CNAB 240 v10.7 — Registro Trailer de Arquivo (Tipo 9)

class RegraTrailerArquivo {
  // ── Posições FEBRABAN do Trailer de Arquivo ─────────────────────────────
  // Pos  1- 3: Código do Banco (033)
  // Pos  4- 7: Lote (9999 para Trailer Arquivo)
  // Pos     8: Tipo de Registro (9)
  // Pos  9-17: Uso exclusivo FEBRABAN (brancos)
  // Pos 18-23: Quantidade de Lotes no Arquivo
  // Pos 24-29: Quantidade de Registros no Arquivo
  // Pos 30-35: Quantidade de Contas Conciliação (uso futuro — zeros)

  /// TA001 — Lote do Trailer de Arquivo deve ser 9999
  static ResultadoRegra tA001LoteTrailerArquivo(String trailer, int numLinha) {
    final sw = Stopwatch()..start();
    if (trailer.length < 7) {
      return ResultadoRegra.sucesso('TA001', tempoMs: sw.elapsedMilliseconds);
    }

    final lote = trailer.substring(3, 7);
    if (lote != '9999') {
      return ResultadoRegra.falha('TA001', [
        ErroValidacao(
          codigo: 'TA001',
          descricao: 'Número de lote do Trailer de Arquivo deve ser 9999',
          detalhe: 'Encontrado: "$lote". Esperado: "9999"',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.trailerArquivo,
          linha: numLinha,
          posicaoInicio: 4,
          posicaoFim: 7,
          campoCnab: 'Lote de Serviço',
          sugestaoCorrecao:
              'Trailer de Arquivo deve ter lote = 9999',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 4-7: Lote = 9999 para Trailer de Arquivo',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('TA001', tempoMs: sw.elapsedMilliseconds);
  }

  /// TA002 — Tipo de registro deve ser 9 (Trailer de Arquivo)
  static ResultadoRegra tA002TipoRegistro(String trailer, int numLinha) {
    final sw = Stopwatch()..start();
    if (trailer.length < 8) {
      return ResultadoRegra.sucesso('TA002', tempoMs: sw.elapsedMilliseconds);
    }

    final tipo = trailer.substring(7, 8);
    if (tipo != '9') {
      return ResultadoRegra.falha('TA002', [
        ErroValidacao(
          codigo: 'TA002',
          descricao: 'Tipo de registro do Trailer de Arquivo inválido',
          detalhe: 'Encontrado: "$tipo". Esperado: "9"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.trailerArquivo,
          linha: numLinha,
          posicaoInicio: 8,
          posicaoFim: 8,
          campoCnab: 'Tipo de Registro',
          sugestaoCorrecao:
              'Trailer de Arquivo deve ter tipo de registro = 9',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 8: Tipo de Registro = 9',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('TA002', tempoMs: sw.elapsedMilliseconds);
  }

  /// TA003 — Quantidade de lotes deve corresponder aos lotes reais
  static ResultadoRegra tA003QtdLotes(
      String trailer, int numLinha, int qtdLotesEsperada) {
    final sw = Stopwatch()..start();
    if (trailer.length < 23) {
      return ResultadoRegra.sucesso('TA003', tempoMs: sw.elapsedMilliseconds);
    }

    // Posição 18-23 (índice 17-22) = 6 dígitos
    final qtdStr = trailer.substring(17, 23);
    final qtd = int.tryParse(qtdStr);

    if (qtd == null || qtd != qtdLotesEsperada) {
      return ResultadoRegra.falha('TA003', [
        ErroValidacao(
          codigo: 'TA003',
          descricao: 'Quantidade de lotes no Trailer de Arquivo não corresponde',
          detalhe:
              'Declarado: "${qtdStr.trim()}" | Contado: $qtdLotesEsperada',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.trailerArquivo,
          linha: numLinha,
          posicaoInicio: 18,
          posicaoFim: 23,
          campoCnab: 'Quantidade de Lotes no Arquivo',
          sugestaoCorrecao:
              'Atualize o contador de lotes no Trailer de Arquivo',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 18-23: Qtd de Lotes no Arquivo',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('TA003', tempoMs: sw.elapsedMilliseconds);
  }

  /// TA004 — Quantidade total de registros deve incluir todos (header+lotes+trailer)
  static ResultadoRegra tA004QtdRegistrosTotais(
      String trailer, int numLinha, int totalRegistrosEsperado) {
    final sw = Stopwatch()..start();
    if (trailer.length < 29) {
      return ResultadoRegra.sucesso('TA004', tempoMs: sw.elapsedMilliseconds);
    }

    // Posição 24-29 (índice 23-28) = 6 dígitos
    final qtdStr = trailer.substring(23, 29);
    final qtd = int.tryParse(qtdStr);

    if (qtd == null || qtd != totalRegistrosEsperado) {
      return ResultadoRegra.falha('TA004', [
        ErroValidacao(
          codigo: 'TA004',
          descricao:
              'Quantidade total de registros no Trailer de Arquivo não corresponde',
          detalhe:
              'Declarado: "${qtdStr.trim()}" | Contado: $totalRegistrosEsperado',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.trailerArquivo,
          linha: numLinha,
          posicaoInicio: 24,
          posicaoFim: 29,
          campoCnab: 'Quantidade de Registros no Arquivo',
          sugestaoCorrecao:
              'Atualize o contador total de registros no Trailer de Arquivo (incluindo header e trailer)',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 24-29: Qtd de Registros no Arquivo',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('TA004', tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras de Trailer de Arquivo
  static List<ResultadoRegra> validarTudo(
      String trailerLinha, int numLinha, int qtdLotes, int qtdRegistros) {
    return [
      tA001LoteTrailerArquivo(trailerLinha, numLinha),
      tA002TipoRegistro(trailerLinha, numLinha),
      tA003QtdLotes(trailerLinha, numLinha, qtdLotes),
      tA004QtdRegistrosTotais(trailerLinha, numLinha, qtdRegistros),
    ];
  }
}
