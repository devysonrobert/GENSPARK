// core/validation/rules/segmento_q_rules.dart
// Regras de validação do Segmento Q CNAB 240
// FEBRABAN CNAB 240 v10.7 — Segmento Q (dados do sacado e avalista)
// Santander: dados do pagador (sacado), endereço e sacador/avalista

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraSegmentoQ {
  // ── Posições H7815 V8.5 Segmento Q ───────────────────────────────────────
  // Pos  1-  3: Código Banco (033)
  // Pos  4-  7: Lote de Serviço
  // Pos      8: Tipo Registro (3)
  // Pos  9- 13: Nr Sequencial do Registro no Lote
  // Pos     14: Código Segmento (Q)
  // Pos     15: Reservado uso Banco (branco)
  // Pos 16- 17: Código de Movimento Remessa (2 num: 01=Entrada)
  // Pos     18: Tipo Inscrição do Pagador (1=CPF, 2=CNPJ) — H7815: 1 char!
  // Pos 19- 33: Nr Inscrição do Pagador — 15 num (zeros + CPF/CNPJ)
  // Pos 34- 73: Nome do Pagador — 40 alfa
  // Pos 74-113: Endereço do Pagador — 40 alfa
  // Pos 114-128: Bairro do Pagador — 15 alfa
  // Pos 129-133: CEP — 5 num
  // Pos 134-136: Sufixo CEP — 3 num
  // Pos 137-151: Cidade — 15 alfa
  // Pos 152-153: UF do Pagador — 2 alfa
  // Pos 154: Tipo Inscrição Beneficiário Final (0/1/2) — 1 char!
  // Pos 155-169: Nr Inscrição Beneficiário Final — 15 num
  // Pos 170-209: Nome do Beneficiário Final — 40 alfa
  // Pos 210-212: Reservado uso Banco — 3 brancos
  // Pos 213-215: Reservado uso Banco — 3 brancos
  // Pos 216-218: Reservado uso Banco — 3 brancos
  // Pos 219-221: Reservado uso Banco — 3 brancos
  // Pos 222-240: Reservado uso Banco — 19 brancos

  static const _ufsValidas = {
    'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR',
    'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO',
  };

  /// SQ001 — Tipo de inscrição do sacado: posição 18 (1 char: 1=CPF, 2=CNPJ) — H7815
  static ResultadoRegra sQ001TipoInscricaoSacado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 18) return ResultadoRegra.sucesso('SQ001', tempoMs: sw.elapsedMilliseconds);

    // H7815: posição 18 = 1 char (1=CPF, 2=CNPJ)
    final tipoInsc = seg.substring(17, 18);
    if (tipoInsc != '1' && tipoInsc != '2') {
      return ResultadoRegra.falha('SQ001', [
        ErroValidacao(
          codigo: 'SQ001',
          descricao: 'Tipo de inscrição do pagador inválido no Segmento Q (posição 18)',
          detalhe: 'Encontrado: "$tipoInsc". H7815: "1" (CPF) ou "2" (CNPJ)',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 18,
          posicaoFim: 18,
          campoCnab: 'Tipo de Inscrição do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'H7815: 1 char — use 1=CPF ou 2=CNPJ',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 18-19: Tipo Inscrição Pagador',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ001', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ002 — Nr inscrição do pagador: posição 19-33 (15 num) — H7815
  static ResultadoRegra sQ002NrInscricaoSacado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 33) return ResultadoRegra.sucesso('SQ002', tempoMs: sw.elapsedMilliseconds);

    // H7815: posição 19-33 (15 chars = zeros + CNPJ/CPF)
    final nrInsc = seg.substring(18, 33);

    if (!RegExp(r'^\d{15}$').hasMatch(nrInsc)) {
      return ResultadoRegra.falha('SQ002', [
        ErroValidacao(
          codigo: 'SQ002',
          descricao: 'Nr de inscrição do pagador inválido no Segmento Q (posição 19-33)',
          detalhe:
              'Encontrado: "$nrInsc". H7815: 15 dígitos (zeros + CPF 11 ou CNPJ 14)',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 19,
          posicaoFim: 33,
          campoCnab: 'Nr de Inscrição do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao:
              'CPF 11 dígitos com 4 zeros à esq. CNPJ 14 dígitos com 1 zero à esq.',
          referenciaFebraban:
              'H7815 V8.5 — Posição 19-33: Nr Inscrição do Pagador (15 posições)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ002', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ003 — CPF/CNPJ do pagador não pode ser todos zeros (posição 19-33)
  static ResultadoRegra sQ003CpfCnpjNaoZerado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 33) return ResultadoRegra.sucesso('SQ003', tempoMs: sw.elapsedMilliseconds);

    final nrInsc = seg.substring(18, 33);
    if (RegExp(r'^0+$').hasMatch(nrInsc)) {
      return ResultadoRegra.falha('SQ003', [
        ErroValidacao(
          codigo: 'SQ003',
          descricao: 'CPF/CNPJ do sacado zerado no Segmento Q',
          detalhe: 'Todos os dígitos são zero — dado obrigatório',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 20,
          posicaoFim: 33,
          campoCnab: 'Nr de Inscrição do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'Preencha o CPF ou CNPJ do sacado',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ003', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ004 — Nome do sacado não pode estar vazio
  static ResultadoRegra sQ004NomeSacado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 73) return ResultadoRegra.sucesso('SQ004', tempoMs: sw.elapsedMilliseconds);

    // Posição 34-73 (índice 33-72) = 40 chars
    final nome = seg.substring(33, 73).trim();
    if (nome.isEmpty) {
      return ResultadoRegra.falha('SQ004', [
        ErroValidacao(
          codigo: 'SQ004',
          descricao: 'Nome do sacado vazio no Segmento Q',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 34,
          posicaoFim: 73,
          campoCnab: 'Nome do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'Preencha o nome/razão social do sacado',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 34-73: Nome do Pagador (obrigatório)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ004', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ005 — Endereço do sacado não pode estar vazio
  static ResultadoRegra sQ005EnderecoSacado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 113) return ResultadoRegra.sucesso('SQ005', tempoMs: sw.elapsedMilliseconds);

    // Posição 74-113 (índice 73-112) = 40 chars
    final endereco = seg.substring(73, 113).trim();
    if (endereco.isEmpty) {
      return ResultadoRegra.falha('SQ005', [
        ErroValidacao(
          codigo: 'SQ005',
          descricao: 'Endereço do sacado vazio no Segmento Q',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 74,
          posicaoFim: 113,
          campoCnab: 'Endereço do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'Preencha o endereço do sacado para impressão no boleto',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ005', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ006 — CEP: posição 129-136 (8 chars = 5+3 separados) — H7815
  static ResultadoRegra sQ006Cep(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 136) return ResultadoRegra.sucesso('SQ006', tempoMs: sw.elapsedMilliseconds);

    // H7815: CEP = posição 129-133 (5 num) + sufixo 134-136 (3 num)
    final cep5 = seg.substring(128, 133);
    final suf3 = seg.substring(133, 136);
    final cepCompleto = cep5 + suf3;
    if (!RegExp(r'^\d{5}$').hasMatch(cep5) || !RegExp(r'^\d{3}$').hasMatch(suf3)) {
      return ResultadoRegra.falha('SQ006', [
        ErroValidacao(
          codigo: 'SQ006',
          descricao: 'CEP do pagador inválido no Segmento Q (posição 129-136)',
          detalhe: 'Encontrado: "$cepCompleto". H7815: 5 num (CEP) + 3 num (sufixo)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 129,
          posicaoFim: 136,
          campoCnab: 'CEP e Sufixo do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'CEP sem hífen em 2 partes: 5 dígitos + 3 dígitos (ex: 06460 070)',
          referenciaFebraban: 'H7815 V8.5 — Posição 129-136: CEP (5) + Sufixo (3)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ006', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ007 — Cidade do pagador: posição 137-151 (15 alfa) — H7815
  static ResultadoRegra sQ007CidadeSacado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 151) return ResultadoRegra.sucesso('SQ007', tempoMs: sw.elapsedMilliseconds);

    // H7815: posição 137-151 (15 chars) — difere do layout anterior (138-157, 20 chars)
    final cidade = seg.substring(136, 151).trim();
    if (cidade.isEmpty) {
      return ResultadoRegra.falha('SQ007', [
        ErroValidacao(
          codigo: 'SQ007',
          descricao: 'Cidade do pagador vazia no Segmento Q (posição 137-151)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 137,
          posicaoFim: 151,
          campoCnab: 'Cidade do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'Preencha a cidade do pagador (até 15 chars)',
          referenciaFebraban: 'H7815 V8.5 — Posição 137-151: Cidade do Pagador (15 posições)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ007', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ008 — UF do pagador: posição 152-153 (2 alfa) — H7815
  static ResultadoRegra sQ008UfSacado(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 153) return ResultadoRegra.sucesso('SQ008', tempoMs: sw.elapsedMilliseconds);

    // H7815: posição 152-153 (índice 151-152) = 2 chars
    final uf = seg.substring(151, 153);
    if (uf.trim().isNotEmpty && !_ufsValidas.contains(uf)) {
      return ResultadoRegra.falha('SQ008', [
        ErroValidacao(
          codigo: 'SQ008',
          descricao: 'UF do pagador inválida no Segmento Q (posição 152-153)',
          detalhe: 'Encontrado: "$uf". Use a sigla do estado (ex: SP, RJ, MG)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 152,
          posicaoFim: 153,
          campoCnab: 'Unidade da Federação do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'Use a sigla de 2 letras do estado (SP, RJ, MG, etc.)',
          referenciaFebraban: 'H7815 V8.5 — Posição 152-153: UF do Pagador',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ008', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ009 — Tipo inscrição Beneficiário Final: posição 154 (1 char) — H7815
  static ResultadoRegra sQ009TipoInscricaoAvalista(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 154) return ResultadoRegra.sucesso('SQ009', tempoMs: sw.elapsedMilliseconds);

    // H7815: posição 154 (1 char) = 0=não presente, 1=CPF, 2=CNPJ
    final tipoAval = seg.substring(153, 154);
    if (tipoAval != '0' && tipoAval != '1' && tipoAval != '2') {
      return ResultadoRegra.falha('SQ009', [
        ErroValidacao(
          codigo: 'SQ009',
          descricao: 'Tipo de inscrição do Beneficiário Final inválido no Segmento Q (posição 154)',
          detalhe: 'Encontrado: "$tipoAval". H7815: 0=Não presente, 1=CPF, 2=CNPJ',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 154,
          posicaoFim: 154,
          campoCnab: 'Tipo de Inscrição do Beneficiário Final',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          referenciaFebraban: 'H7815 V8.5 — Posição 154: Tipo Inscrição Beneficiário Final (1 char)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ009', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ010 — Se Beneficiário Final presente, nome não pode ser vazio (posição 170-209)
  static ResultadoRegra sQ010NomeAvalista(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 209) return ResultadoRegra.sucesso('SQ010', tempoMs: sw.elapsedMilliseconds);

    // H7815: tipo Benef. Final é 1 char na posição 154
    final tipoAval = seg.length >= 154 ? seg.substring(153, 154) : '0';

    if (tipoAval != '0') {
      // H7815 posição 170-209 = Nome do Beneficiário Final (40 chars)
      final nomeAval = seg.substring(169, 209).trim();
      if (nomeAval.isEmpty) {
        return ResultadoRegra.falha('SQ010', [
          ErroValidacao(
            codigo: 'SQ010',
            descricao: 'Nome do Beneficiário Final vazio no Segmento Q (posição 170-209)',
            detalhe: 'Tipo inscrição Benef. Final: $tipoAval',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.segmentoQ,
            linha: numLinha,
            posicaoInicio: 170,
            posicaoFim: 209,
            campoCnab: 'Nome do Beneficiário Final',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'Q',
            sugestaoCorrecao:
                'Se tipo de inscrição do sacador ≠ 00, preencha o nome',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    }
    return ResultadoRegra.sucesso('SQ010', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ011 — Código do banco deve ser 033 no Segmento Q
  static ResultadoRegra sQ011CodigoBanco(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 3) return ResultadoRegra.sucesso('SQ011', tempoMs: sw.elapsedMilliseconds);

    final banco = seg.substring(0, 3);
    if (banco != '033') {
      return ResultadoRegra.falha('SQ011', [
        ErroValidacao(
          codigo: 'SQ011',
          descricao: 'Código do banco inválido no Segmento Q',
          detalhe: 'Encontrado: "$banco". Esperado: "033"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 1,
          posicaoFim: 3,
          campoCnab: 'Código do Banco',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ011', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ012 — Tipo de registro do Segmento Q deve ser 3
  static ResultadoRegra sQ012TipoRegistro(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 8) return ResultadoRegra.sucesso('SQ012', tempoMs: sw.elapsedMilliseconds);

    final tipo = seg.substring(7, 8);
    if (tipo != '3') {
      return ResultadoRegra.falha('SQ012', [
        ErroValidacao(
          codigo: 'SQ012',
          descricao: 'Tipo de registro do Segmento Q deve ser 3',
          detalhe: 'Encontrado: "$tipo"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 8,
          posicaoFim: 8,
          campoCnab: 'Tipo de Registro',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ012', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ013 — Código de segmento deve ser Q
  static ResultadoRegra sQ013CodigoSegmento(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 14) return ResultadoRegra.sucesso('SQ013', tempoMs: sw.elapsedMilliseconds);

    final codSeg = seg.substring(13, 14);
    if (codSeg != 'Q') {
      return ResultadoRegra.falha('SQ013', [
        ErroValidacao(
          codigo: 'SQ013',
          descricao: 'Código de segmento inválido (esperado Q)',
          detalhe: 'Encontrado: "$codSeg"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 14,
          posicaoFim: 14,
          campoCnab: 'Código do Segmento',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ013', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ014 — Consistência: CPF com tipo 01 deve ter os 3 primeiros dígitos zerados
  static ResultadoRegra sQ014ConsistenciaCpfCnpj(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 33) return ResultadoRegra.sucesso('SQ014', tempoMs: sw.elapsedMilliseconds);

    final tipoInsc = seg.substring(17, 19);
    final nrInsc = seg.substring(19, 33);

    if (tipoInsc == '01') {
      // CPF: 14 chars, os 3 primeiros devem ser '000'
      if (!nrInsc.startsWith('000')) {
        return ResultadoRegra.falha('SQ014', [
          ErroValidacao(
            codigo: 'SQ014',
            descricao:
                'CPF do sacado não está no formato correto (14 chars: 000 + 11 dígitos)',
            detalhe:
                'Tipo: CPF (01) | Valor: "$nrInsc" — deve começar com 000',
            severidade: SeveridadeValidacao.erro,
            categoria: CategoriaValidacao.segmentoQ,
            linha: numLinha,
            posicaoInicio: 20,
            posicaoFim: 33,
            campoCnab: 'Nr de Inscrição do Pagador',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'Q',
            sugestaoCorrecao:
                'Para CPF, preencha: 000 + CPF sem formatação (11 dígitos). Ex: 00012345678901',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    }
    return ResultadoRegra.sucesso('SQ014', tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras de Segmento Q
  static List<ResultadoRegra> validarTudo(
      String segLinha, int numLinha, int idxTitulo) {
    return [
      sQ001TipoInscricaoSacado(segLinha, numLinha, idxTitulo),
      sQ002NrInscricaoSacado(segLinha, numLinha, idxTitulo),
      sQ003CpfCnpjNaoZerado(segLinha, numLinha, idxTitulo),
      sQ004NomeSacado(segLinha, numLinha, idxTitulo),
      sQ005EnderecoSacado(segLinha, numLinha, idxTitulo),
      sQ006Cep(segLinha, numLinha, idxTitulo),
      sQ007CidadeSacado(segLinha, numLinha, idxTitulo),
      sQ008UfSacado(segLinha, numLinha, idxTitulo),
      sQ009TipoInscricaoAvalista(segLinha, numLinha, idxTitulo),
      sQ010NomeAvalista(segLinha, numLinha, idxTitulo),
      sQ011CodigoBanco(segLinha, numLinha, idxTitulo),
      sQ012TipoRegistro(segLinha, numLinha, idxTitulo),
      sQ013CodigoSegmento(segLinha, numLinha, idxTitulo),
      sQ014ConsistenciaCpfCnpj(segLinha, numLinha, idxTitulo),
    ];
  }
}
