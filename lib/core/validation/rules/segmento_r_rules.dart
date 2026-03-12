// core/validation/rules/segmento_r_rules.dart
// Regras de validação do Segmento R CNAB 240
// FEBRABAN CNAB 240 v10.7 — Segmento R (desconto/multa/mensagens adicionais)
// Santander: desconto adicional, multa, mensagens livres no boleto

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraSegmentoR {
  // ── Posições Santander Segmento R ────────────────────────────────────────
  // Pos  1- 3: Código Banco (033)
  // Pos  4- 7: Lote de Serviço
  // Pos     8: Tipo Registro (3)
  // Pos  9-13: Nr Sequencial do Registro no Lote
  // Pos    14: Código Segmento (R)
  // Pos    15: Tipo Movimento
  // Pos 16-17: Código Instrução para Movimento
  // Pos 18: Código do Desconto 2 (0=Sem, 1=Valor, 2=%, 3=Antecipado V, 4=Antecipado %)
  // Pos 19-26: Data do Desconto 2 (DDMMAAAA)
  // Pos 27-41: Valor/Taxa do Desconto 2 (15 chars)
  // Pos 42: Código do Desconto 3 (0=Sem, 1=Valor, 2=%, 3=Antecipado V, 4=Antecipado %)
  // Pos 43-50: Data do Desconto 3 (DDMMAAAA)
  // Pos 51-65: Valor/Taxa do Desconto 3 (15 chars)
  // Pos 66: Código da Multa (0=Sem, 1=Valor, 2=Percentual)
  // Pos 67-74: Data da Multa (DDMMAAAA)
  // Pos 75-89: Valor/Taxa da Multa (15 chars)
  // Pos 90-129: Informação ao Pagador (Mensagem 1) — 40 chars
  // Pos 130-169: Informação ao Pagador (Mensagem 2) — 40 chars
  // Pos 170-179: Uso exclusivo FEBRABAN (brancos)
  // Pos 180-194: Código de Ocorrência do Retorno — 5 posições
  // Pos 195-240: Uso exclusivo Banco (brancos)

  /// SR001 — Código do banco deve ser 033 no Segmento R
  static ResultadoRegra sR001CodigoBanco(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 3) return ResultadoRegra.sucesso('SR001', tempoMs: sw.elapsedMilliseconds);

    final banco = seg.substring(0, 3);
    if (banco != '033') {
      return ResultadoRegra.falha('SR001', [
        ErroValidacao(
          codigo: 'SR001',
          descricao: 'Código do banco inválido no Segmento R',
          detalhe: 'Encontrado: "$banco". Esperado: "033"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoR,
          linha: numLinha,
          posicaoInicio: 1,
          posicaoFim: 3,
          campoCnab: 'Código do Banco',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'R',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SR001', tempoMs: sw.elapsedMilliseconds);
  }

  /// SR002 — Tipo de registro deve ser 3 no Segmento R
  static ResultadoRegra sR002TipoRegistro(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 8) return ResultadoRegra.sucesso('SR002', tempoMs: sw.elapsedMilliseconds);

    final tipo = seg.substring(7, 8);
    if (tipo != '3') {
      return ResultadoRegra.falha('SR002', [
        ErroValidacao(
          codigo: 'SR002',
          descricao: 'Tipo de registro do Segmento R deve ser 3',
          detalhe: 'Encontrado: "$tipo"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoR,
          linha: numLinha,
          posicaoInicio: 8,
          posicaoFim: 8,
          campoCnab: 'Tipo de Registro',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'R',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SR002', tempoMs: sw.elapsedMilliseconds);
  }

  /// SR003 — Código de segmento deve ser R
  static ResultadoRegra sR003CodigoSegmento(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 14) return ResultadoRegra.sucesso('SR003', tempoMs: sw.elapsedMilliseconds);

    final codSeg = seg.substring(13, 14);
    if (codSeg != 'R') {
      return ResultadoRegra.falha('SR003', [
        ErroValidacao(
          codigo: 'SR003',
          descricao: 'Código de segmento inválido (esperado R)',
          detalhe: 'Encontrado: "$codSeg"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoR,
          linha: numLinha,
          posicaoInicio: 14,
          posicaoFim: 14,
          campoCnab: 'Código do Segmento',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'R',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SR003', tempoMs: sw.elapsedMilliseconds);
  }

  /// SR004 — Código de multa deve ser 0, 1 ou 2
  static ResultadoRegra sR004CodigoMulta(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 66) return ResultadoRegra.sucesso('SR004', tempoMs: sw.elapsedMilliseconds);

    // Posição 66 (índice 65)
    final codMulta = seg.substring(65, 66);
    if (!{'0', '1', '2'}.contains(codMulta)) {
      return ResultadoRegra.falha('SR004', [
        ErroValidacao(
          codigo: 'SR004',
          descricao: 'Código de multa inválido no Segmento R',
          detalhe: 'Encontrado: "$codMulta". Válidos: 0=Sem multa, 1=Valor fixo, 2=Percentual',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoR,
          linha: numLinha,
          posicaoInicio: 66,
          posicaoFim: 66,
          campoCnab: 'Código da Multa',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'R',
          sugestaoCorrecao:
              'Use 0 para sem multa, 1 para valor fixo ou 2 para percentual',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 66: Código da Multa',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SR004', tempoMs: sw.elapsedMilliseconds);
  }

  /// SR005 — Se multa configurada, data e valor não podem ser zerados
  static ResultadoRegra sR005ConsistenciaMulta(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 89) return ResultadoRegra.sucesso('SR005', tempoMs: sw.elapsedMilliseconds);

    final codMulta = seg.substring(65, 66);
    final dataMultaStr = seg.substring(66, 74);
    final valorMultaStr = seg.substring(74, 89);
    final valorMulta = int.tryParse(valorMultaStr) ?? 0;

    if (codMulta != '0') {
      if (dataMultaStr == '00000000' || valorMulta == 0) {
        return ResultadoRegra.falha('SR005', [
          ErroValidacao(
            codigo: 'SR005',
            descricao:
                'Multa configurada (código $codMulta) mas data ou valor zerados',
            detalhe:
                'Código: $codMulta | Data: $dataMultaStr | Valor: $valorMultaStr',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.segmentoR,
            linha: numLinha,
            posicaoInicio: 66,
            posicaoFim: 89,
            campoCnab: 'Data/Valor da Multa',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'R',
            sugestaoCorrecao:
                'Se código de multa ≠ 0, preencha a data e o valor/percentual',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    }
    return ResultadoRegra.sucesso('SR005', tempoMs: sw.elapsedMilliseconds);
  }

  /// SR006 — Data da multa deve ser posterior ao vencimento
  static ResultadoRegra sR006DataMultaPosteriorVencimento(
      String seg, int numLinha, int idxTitulo, String dataVencStr) {
    final sw = Stopwatch()..start();
    if (seg.length < 74) return ResultadoRegra.sucesso('SR006', tempoMs: sw.elapsedMilliseconds);

    final codMulta = seg.substring(65, 66);
    if (codMulta == '0') return ResultadoRegra.sucesso('SR006', tempoMs: sw.elapsedMilliseconds);

    final dataMultaStr = seg.substring(66, 74);

    if (dataMultaStr == '00000000' || dataVencStr == '00000000') {
      return ResultadoRegra.sucesso('SR006', tempoMs: sw.elapsedMilliseconds);
    }

    try {
      DateTime parseData(String s) => DateTime(
            int.parse(s.substring(4, 8)),
            int.parse(s.substring(2, 4)),
            int.parse(s.substring(0, 2)),
          );

      final dataMulta = parseData(dataMultaStr);
      final dataVenc = parseData(dataVencStr);

      if (dataMulta.isBefore(dataVenc) || dataMulta.isAtSameMomentAs(dataVenc)) {
        return ResultadoRegra.falha('SR006', [
          ErroValidacao(
            codigo: 'SR006',
            descricao:
                'Data da multa deve ser posterior ao vencimento no Segmento R',
            detalhe:
                'Multa: $dataMultaStr | Vencimento: $dataVencStr',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.segmentoR,
            linha: numLinha,
            posicaoInicio: 67,
            posicaoFim: 74,
            campoCnab: 'Data da Multa',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'R',
            sugestaoCorrecao:
                'A data de início da multa deve ser após o vencimento do boleto',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    } catch (_) {}

    return ResultadoRegra.sucesso('SR006', tempoMs: sw.elapsedMilliseconds);
  }

  /// SR007 — Multa percentual não pode exceder 2% (Santander limite)
  static ResultadoRegra sR007PercentualMultaSantander(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 89) return ResultadoRegra.sucesso('SR007', tempoMs: sw.elapsedMilliseconds);

    final codMulta = seg.substring(65, 66);
    if (codMulta != '2') return ResultadoRegra.sucesso('SR007', tempoMs: sw.elapsedMilliseconds);

    // Valor percentual: 15 chars, 2 decimais implícitos
    final percentualStr = seg.substring(74, 89);
    final percentual = (int.tryParse(percentualStr) ?? 0) / 100.0;

    if (percentual > 2.0) {
      return ResultadoRegra.falha('SR007', [
        ErroValidacao(
          codigo: 'SR007',
          descricao: 'Percentual de multa acima do limite legal (2%) no Segmento R',
          detalhe:
              'Multa encontrada: ${percentual.toStringAsFixed(2)}% | Limite: 2%',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoR,
          linha: numLinha,
          posicaoInicio: 75,
          posicaoFim: 89,
          campoCnab: 'Valor da Multa (Percentual)',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'R',
          sugestaoCorrecao:
              'A multa por atraso é limitada a 2% pelo Código de Defesa do Consumidor (Lei 8078/90)',
          referenciaFebraban:
              'CDC Art. 52 § 1º — Multa mora máxima 2%',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SR007', tempoMs: sw.elapsedMilliseconds);
  }

  /// SR008 — Mensagem 1: máximo 40 caracteres (já garantido pelo tamanho fixo)
  static ResultadoRegra sR008Mensagem1(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 129) return ResultadoRegra.sucesso('SR008', tempoMs: sw.elapsedMilliseconds);

    // Posição 90-129 (índice 89-128) = 40 chars
    final msg1 = seg.substring(89, 129);

    // Verificar caracteres não ASCII
    for (int i = 0; i < msg1.length; i++) {
      final c = msg1.codeUnitAt(i);
      if (c > 126 || (c < 32 && c != 0)) {
        return ResultadoRegra.falha('SR008', [
          ErroValidacao(
            codigo: 'SR008',
            descricao:
                'Mensagem 1 do Segmento R contém caracteres inválidos',
            detalhe:
                'Caractere Unicode ${msg1.codeUnitAt(i)} na posição ${89 + i + 1}',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.segmentoR,
            linha: numLinha,
            posicaoInicio: 90,
            posicaoFim: 129,
            campoCnab: 'Mensagem 1',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'R',
            sugestaoCorrecao:
                'Use apenas caracteres ASCII (sem acentos, cedilha ou caracteres especiais)',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    }
    return ResultadoRegra.sucesso('SR008', tempoMs: sw.elapsedMilliseconds);
  }

  /// SR009 — Mensagem 2: máximo 40 caracteres ASCII
  static ResultadoRegra sR009Mensagem2(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 169) return ResultadoRegra.sucesso('SR009', tempoMs: sw.elapsedMilliseconds);

    // Posição 130-169 (índice 129-168) = 40 chars
    final msg2 = seg.substring(129, 169);

    for (int i = 0; i < msg2.length; i++) {
      final c = msg2.codeUnitAt(i);
      if (c > 126 || (c < 32 && c != 0)) {
        return ResultadoRegra.falha('SR009', [
          ErroValidacao(
            codigo: 'SR009',
            descricao:
                'Mensagem 2 do Segmento R contém caracteres inválidos',
            detalhe:
                'Caractere Unicode ${msg2.codeUnitAt(i)} na posição ${129 + i + 1}',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.segmentoR,
            linha: numLinha,
            posicaoInicio: 130,
            posicaoFim: 169,
            campoCnab: 'Mensagem 2',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'R',
            sugestaoCorrecao:
                'Use apenas caracteres ASCII (sem acentos ou caracteres especiais)',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    }
    return ResultadoRegra.sucesso('SR009', tempoMs: sw.elapsedMilliseconds);
  }

  /// SR010 — Código de desconto 2 deve ser válido (0-4)
  static ResultadoRegra sR010CodigoDesconto2(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 18) return ResultadoRegra.sucesso('SR010', tempoMs: sw.elapsedMilliseconds);

    // Posição 18 (índice 17)
    final codDesc2 = seg.substring(17, 18);
    if (!{'0', '1', '2', '3', '4'}.contains(codDesc2)) {
      return ResultadoRegra.falha('SR010', [
        ErroValidacao(
          codigo: 'SR010',
          descricao: 'Código de desconto 2 inválido no Segmento R',
          detalhe: 'Encontrado: "$codDesc2". Válidos: 0=Sem, 1=Valor, 2=%, 3=Ant-V, 4=Ant-%',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoR,
          linha: numLinha,
          posicaoInicio: 18,
          posicaoFim: 18,
          campoCnab: 'Código do Desconto 2',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'R',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SR010', tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras de Segmento R
  static List<ResultadoRegra> validarTudo(
      String segLinha, int numLinha, int idxTitulo, String dataVencStr) {
    return [
      sR001CodigoBanco(segLinha, numLinha, idxTitulo),
      sR002TipoRegistro(segLinha, numLinha, idxTitulo),
      sR003CodigoSegmento(segLinha, numLinha, idxTitulo),
      sR004CodigoMulta(segLinha, numLinha, idxTitulo),
      sR005ConsistenciaMulta(segLinha, numLinha, idxTitulo),
      sR006DataMultaPosteriorVencimento(segLinha, numLinha, idxTitulo, dataVencStr),
      sR007PercentualMultaSantander(segLinha, numLinha, idxTitulo),
      sR008Mensagem1(segLinha, numLinha, idxTitulo),
      sR009Mensagem2(segLinha, numLinha, idxTitulo),
      sR010CodigoDesconto2(segLinha, numLinha, idxTitulo),
    ];
  }
}
