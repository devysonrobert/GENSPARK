// core/validation/rules/structural_rules.dart
// Regras de validação estrutural do arquivo CNAB 240
// FEBRABAN CNAB 240 v10.7 — Capítulo 2: Estrutura Geral

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraEstrutural {
  /// STR001 — Arquivo não pode ser vazio
  static ResultadoRegra stR001ArquivoVazio(String conteudo) {
    final sw = Stopwatch()..start();
    if (conteudo.trim().isEmpty) {
      return ResultadoRegra.falha('STR001', [
        const ErroValidacao(
          codigo: 'STR001',
          descricao: 'Arquivo CNAB vazio ou sem conteúdo',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.estrutural,
          sugestaoCorrecao: 'Gere o arquivo CNAB antes de validar',
          referenciaFebraban: 'FEBRABAN CNAB 240 v10.7 — Seção 2.1',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('STR001', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR002 — Cada linha deve ter exatamente 240 caracteres (antes do CRLF)
  static ResultadoRegra stR002TamanhoLinha(List<String> linhas) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];

    for (int i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      if (linha.length != 240) {
        erros.add(ErroValidacao(
          codigo: 'STR002',
          descricao: 'Linha com tamanho inválido: ${linha.length} caracteres (esperado: 240)',
          detalhe: 'Linha ${i + 1}: tamanho = ${linha.length}',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.estrutural,
          linha: i + 1,
          sugestaoCorrecao:
              'Corrija o gerador para garantir exatamente 240 caracteres por linha',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Seção 2.1: Cada registro = 240 posições',
        ));
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('STR002', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('STR002', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// STR003 — Arquivo deve usar terminador CRLF (\\r\\n)
  static ResultadoRegra stR003TerminadorCrlf(String conteudo) {
    final sw = Stopwatch()..start();

    // Verificar se tem pelo menos um \r\n
    if (!conteudo.contains('\r\n')) {
      // Pode ser só \n (Unix) — avisar
      if (conteudo.contains('\n')) {
        return ResultadoRegra.falha('STR003', [
          const ErroValidacao(
            codigo: 'STR003',
            descricao:
                'Arquivo usa terminador LF (Unix) ao invés de CRLF (Windows/FEBRABAN)',
            detalhe: 'Encontrado: \\n (0x0A). Esperado: \\r\\n (0x0D 0x0A)',
            severidade: SeveridadeValidacao.erro,
            categoria: CategoriaValidacao.estrutural,
            sugestaoCorrecao:
                'Use CRLF (\\r\\n) como terminador de linha conforme padrão FEBRABAN',
            referenciaFebraban:
                'FEBRABAN CNAB 240 v10.7 — Seção 2.1: Terminador = CR LF',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
      return ResultadoRegra.falha('STR003', [
        const ErroValidacao(
          codigo: 'STR003',
          descricao: 'Arquivo sem terminadores de linha reconhecidos',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.estrutural,
          sugestaoCorrecao: 'Verifique a codificação do arquivo',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('STR003', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR004 — Primeiro registro deve ser Header de Arquivo (tipo 0)
  static ResultadoRegra stR004PrimeiroRegistroHeaderArquivo(List<String> linhas) {
    final sw = Stopwatch()..start();

    if (linhas.isEmpty) {
      return ResultadoRegra.sucesso('STR004', tempoMs: sw.elapsedMilliseconds);
    }

    final primLinha = linhas.first;
    if (primLinha.length >= 8) {
      // Posição 8 (índice 7) = tipo de registro: 0 = Header Arquivo
      final tipoReg = primLinha.substring(7, 8);
      if (tipoReg != '0') {
        return ResultadoRegra.falha('STR004', [
          ErroValidacao(
            codigo: 'STR004',
            descricao: 'Primeiro registro não é Header de Arquivo (tipo 0)',
            detalhe: 'Tipo encontrado na posição 8: "$tipoReg"',
            severidade: SeveridadeValidacao.fatal,
            categoria: CategoriaValidacao.estrutural,
            linha: 1,
            posicaoInicio: 8,
            posicaoFim: 8,
            campoCnab: 'Código do Registro',
            sugestaoCorrecao:
                'O primeiro registro deve ser o Header de Arquivo com código 0',
            referenciaFebraban:
                'FEBRABAN CNAB 240 v10.7 — Posição 8: Código do Registro Header = 0',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    }

    return ResultadoRegra.sucesso('STR004', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR005 — Último registro deve ser Trailer de Arquivo (tipo 9)
  static ResultadoRegra stR005UltimoRegistroTrailerArquivo(List<String> linhas) {
    final sw = Stopwatch()..start();

    if (linhas.isEmpty) {
      return ResultadoRegra.sucesso('STR005', tempoMs: sw.elapsedMilliseconds);
    }

    final ultLinha = linhas.last;
    if (ultLinha.length >= 8) {
      final tipoReg = ultLinha.substring(7, 8);
      if (tipoReg != '9') {
        return ResultadoRegra.falha('STR005', [
          ErroValidacao(
            codigo: 'STR005',
            descricao: 'Último registro não é Trailer de Arquivo (tipo 9)',
            detalhe: 'Tipo encontrado na posição 8: "$tipoReg" (linha ${linhas.length})',
            severidade: SeveridadeValidacao.fatal,
            categoria: CategoriaValidacao.estrutural,
            linha: linhas.length,
            posicaoInicio: 8,
            posicaoFim: 8,
            campoCnab: 'Código do Registro',
            sugestaoCorrecao:
                'O último registro deve ser o Trailer de Arquivo com código 9',
            referenciaFebraban:
                'FEBRABAN CNAB 240 v10.7 — Posição 8: Código do Registro Trailer = 9',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    }

    return ResultadoRegra.sucesso('STR005', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR006 — Deve existir pelo menos um Header de Lote (tipo 1 na posição 8)
  static ResultadoRegra stR006HeaderLotePresente(List<String> linhas) {
    final sw = Stopwatch()..start();

    final temHeaderLote = linhas.any(
        (l) => l.length >= 8 && l.substring(7, 8) == '1');

    if (!temHeaderLote) {
      return ResultadoRegra.falha('STR006', [
        const ErroValidacao(
          codigo: 'STR006',
          descricao: 'Nenhum Header de Lote encontrado no arquivo',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.estrutural,
          sugestaoCorrecao:
              'Todo arquivo CNAB 240 deve conter ao menos um lote de cobrança',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Seção 2.2: Estrutura por lotes',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('STR006', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR007 — Deve existir pelo menos um Trailer de Lote (tipo 5 na posição 8)
  static ResultadoRegra stR007TrailerLotePresente(List<String> linhas) {
    final sw = Stopwatch()..start();

    final temTrailerLote = linhas.any(
        (l) => l.length >= 8 && l.substring(7, 8) == '5');

    if (!temTrailerLote) {
      return ResultadoRegra.falha('STR007', [
        const ErroValidacao(
          codigo: 'STR007',
          descricao: 'Nenhum Trailer de Lote encontrado no arquivo',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.estrutural,
          sugestaoCorrecao:
              'Cada lote deve ter seu respectivo Trailer de Lote (código 5)',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Seção 2.2: Estrutura por lotes',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('STR007', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR008 — Deve existir pelo menos um Segmento P (tipo 3, seg P)
  static ResultadoRegra stR008SegmentoPPresente(List<String> linhas) {
    final sw = Stopwatch()..start();

    // Segmento P: posição 8 = '3' e posição 14 = 'P'
    final temSegP = linhas.any(
        (l) => l.length >= 14 && l.substring(7, 8) == '3' && l.substring(13, 14) == 'P');

    if (!temSegP) {
      return ResultadoRegra.falha('STR008', [
        const ErroValidacao(
          codigo: 'STR008',
          descricao: 'Nenhum Segmento P encontrado no arquivo',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.estrutural,
          posicaoInicio: 14,
          posicaoFim: 14,
          campoCnab: 'Código de Segmento',
          sugestaoCorrecao:
              'Segmento P é obrigatório para cobrança Santander',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 14: Código do Segmento = P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('STR008', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR009 — Deve existir pelo menos um Segmento Q (tipo 3, seg Q)
  static ResultadoRegra stR009SegmentoQPresente(List<String> linhas) {
    final sw = Stopwatch()..start();

    final temSegQ = linhas.any(
        (l) => l.length >= 14 && l.substring(7, 8) == '3' && l.substring(13, 14) == 'Q');

    if (!temSegQ) {
      return ResultadoRegra.falha('STR009', [
        const ErroValidacao(
          codigo: 'STR009',
          descricao: 'Nenhum Segmento Q encontrado no arquivo',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.estrutural,
          posicaoInicio: 14,
          posicaoFim: 14,
          campoCnab: 'Código de Segmento',
          sugestaoCorrecao:
              'Segmento Q é obrigatório — contém dados do sacado',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 14: Código do Segmento = Q',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('STR009', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR010 — Headers de lote e trailers de lote devem ser balanceados
  static ResultadoRegra stR010LotesBalanceados(List<String> linhas) {
    final sw = Stopwatch()..start();

    int headers = 0, trailers = 0;
    for (final l in linhas) {
      if (l.length < 8) continue;
      final tipo = l.substring(7, 8);
      if (tipo == '1') headers++;
      if (tipo == '5') trailers++;
    }

    if (headers != trailers) {
      return ResultadoRegra.falha('STR010', [
        ErroValidacao(
          codigo: 'STR010',
          descricao:
              'Lotes desbalanceados: $headers Header(s) de Lote vs $trailers Trailer(s) de Lote',
          detalhe: 'Headers: $headers | Trailers: $trailers',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.estrutural,
          sugestaoCorrecao:
              'Cada Header de Lote deve ter exatamente um Trailer de Lote correspondente',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Seção 2.2: Estrutura por lotes',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('STR010', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR011 — Número mínimo de registros (header + pelo menos 1 P+Q + trailer)
  static ResultadoRegra stR011NumeroMinimoRegistros(List<String> linhas) {
    final sw = Stopwatch()..start();

    // Mínimo: 1 header arquivo + 1 header lote + 1 segP + 1 segQ + 1 trailer lote + 1 trailer arquivo = 6
    if (linhas.length < 6) {
      return ResultadoRegra.falha('STR011', [
        ErroValidacao(
          codigo: 'STR011',
          descricao:
              'Arquivo com número insuficiente de registros: ${linhas.length} (mínimo: 6)',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.estrutural,
          sugestaoCorrecao:
              'Arquivo deve conter: Header Arquivo + Header Lote + Segmento P + Segmento Q + Trailer Lote + Trailer Arquivo',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('STR011', tempoMs: sw.elapsedMilliseconds);
  }

  /// STR012 — Verificar se há apenas caracteres ASCII imprimíveis
  static ResultadoRegra stR012CaracteresAscii(List<String> linhas) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];

    for (int i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      for (int j = 0; j < linha.length; j++) {
        final codeUnit = linha.codeUnitAt(j);
        // Permitir apenas ASCII imprimível (32-126) e espaços
        if (codeUnit < 32 || codeUnit > 126) {
          erros.add(ErroValidacao(
            codigo: 'STR012',
            descricao:
                'Caractere não-ASCII encontrado na linha ${i + 1}, posição ${j + 1}',
            detalhe:
                'Código Unicode: ${codeUnit} (0x${codeUnit.toRadixString(16).toUpperCase()})',
            severidade: SeveridadeValidacao.erro,
            categoria: CategoriaValidacao.estrutural,
            linha: i + 1,
            posicaoInicio: j + 1,
            posicaoFim: j + 1,
            sugestaoCorrecao:
                'Use apenas caracteres ASCII imprimíveis (32-126). Remova acentos e caracteres especiais',
            referenciaFebraban:
                'FEBRABAN CNAB 240 v10.7 — Codificação: ASCII sem acentos',
          ));

          // Limitar a 5 erros por linha para não sobrecarregar
          if (erros.length >= 20) break;
        }
      }
      if (erros.length >= 20) break;
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('STR012', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('STR012', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras estruturais
  static List<ResultadoRegra> validarTudo(String conteudo, List<String> linhas) {
    return [
      stR001ArquivoVazio(conteudo),
      stR002TamanhoLinha(linhas),
      stR003TerminadorCrlf(conteudo),
      stR004PrimeiroRegistroHeaderArquivo(linhas),
      stR005UltimoRegistroTrailerArquivo(linhas),
      stR006HeaderLotePresente(linhas),
      stR007TrailerLotePresente(linhas),
      stR008SegmentoPPresente(linhas),
      stR009SegmentoQPresente(linhas),
      stR010LotesBalanceados(linhas),
      stR011NumeroMinimoRegistros(linhas),
      stR012CaracteresAscii(linhas),
    ];
  }
}
