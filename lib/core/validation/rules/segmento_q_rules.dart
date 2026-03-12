// core/validation/rules/segmento_q_rules.dart
// Regras de validação do Segmento Q CNAB 240
// FEBRABAN CNAB 240 v10.7 — Segmento Q (dados do sacado e avalista)
// Santander: dados do pagador (sacado), endereço e sacador/avalista

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraSegmentoQ {
  // ── Posições Santander Segmento Q ────────────────────────────────────────
  // Pos  1- 3: Código Banco (033)
  // Pos  4- 7: Lote de Serviço
  // Pos     8: Tipo Registro (3)
  // Pos  9-13: Nr Sequencial do Registro no Lote
  // Pos    14: Código Segmento (Q)
  // Pos    15: Tipo Movimento
  // Pos 16-17: Código Instrução p/ Movimento
  // Pos 18-19: Tipo Inscrição Sacado (01=CPF, 02=CNPJ)
  // Pos 20-33: Nr Inscrição Sacado (CPF 11 com zeros, ou CNPJ 14)
  // Pos 34-73: Nome do Sacado (40 chars)
  // Pos 74-113: Endereço do Sacado (40 chars)
  // Pos 114-128: Bairro do Sacado (15 chars)
  // Pos 129-136: CEP (8 dígitos)
  // Pos 137-136+1 : Sufixo CEP (pos 137)
  // Pos 138-157: Cidade do Sacado (20 chars)
  // Pos 158-159: UF do Sacado (2 chars)
  // Pos 160-161: Tipo Inscrição Sacador/Avalista (00=Não presente, 01=CPF, 02=CNPJ)
  // Pos 162-175: Nr Inscrição Sacador/Avalista (14 dígitos)
  // Pos 176-215: Nome Sacador/Avalista (40 chars)
  // Pos 216-240: Uso exclusivo Banco (brancos)

  static const _ufsValidas = {
    'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR',
    'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO',
  };

  /// SQ001 — Tipo de inscrição do sacado deve ser 01 (CPF) ou 02 (CNPJ)
  static ResultadoRegra sQ001TipoInscricaoSacado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 19) return ResultadoRegra.sucesso('SQ001', tempoMs: sw.elapsedMilliseconds);

    final tipoInsc = seg.substring(17, 19);
    if (tipoInsc != '01' && tipoInsc != '02') {
      return ResultadoRegra.falha('SQ001', [
        ErroValidacao(
          codigo: 'SQ001',
          descricao: 'Tipo de inscrição do sacado inválido no Segmento Q',
          detalhe: 'Encontrado: "$tipoInsc". Válidos: "01" (CPF) ou "02" (CNPJ)',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 18,
          posicaoFim: 19,
          campoCnab: 'Tipo de Inscrição do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'Use 01 para CPF ou 02 para CNPJ',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 18-19: Tipo Inscrição Pagador',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ001', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ002 — Nr inscrição do sacado deve ter 14 dígitos numéricos
  static ResultadoRegra sQ002NrInscricaoSacado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 33) return ResultadoRegra.sucesso('SQ002', tempoMs: sw.elapsedMilliseconds);

    // Posição 20-33 (índice 19-32) = 14 chars
    final nrInsc = seg.substring(19, 33);

    if (!RegExp(r'^\d{14}$').hasMatch(nrInsc)) {
      return ResultadoRegra.falha('SQ002', [
        ErroValidacao(
          codigo: 'SQ002',
          descricao: 'Nr de inscrição do sacado inválido no Segmento Q',
          detalhe:
              'Encontrado: "$nrInsc". Esperado: 14 dígitos (CPF com zeros à esquerda ou CNPJ)',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 20,
          posicaoFim: 33,
          campoCnab: 'Nr de Inscrição do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao:
              'CPF deve ter 11 dígitos precedido de 3 zeros. CNPJ deve ter 14 dígitos',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 20-33: Nr Inscrição do Pagador',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ002', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ003 — CPF/CNPJ do sacado não pode ser todos zeros
  static ResultadoRegra sQ003CpfCnpjNaoZerado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 33) return ResultadoRegra.sucesso('SQ003', tempoMs: sw.elapsedMilliseconds);

    final nrInsc = seg.substring(19, 33);
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

  /// SQ006 — CEP deve ter 8 dígitos numéricos
  static ResultadoRegra sQ006Cep(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 136) return ResultadoRegra.sucesso('SQ006', tempoMs: sw.elapsedMilliseconds);

    // Posição 129-136 (índice 128-135) = 8 chars
    final cep = seg.substring(128, 136);
    if (!RegExp(r'^\d{8}$').hasMatch(cep) && cep != '00000000') {
      return ResultadoRegra.falha('SQ006', [
        ErroValidacao(
          codigo: 'SQ006',
          descricao: 'CEP do sacado inválido no Segmento Q',
          detalhe: 'Encontrado: "$cep". Esperado: 8 dígitos numéricos sem hífen',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 129,
          posicaoFim: 136,
          campoCnab: 'CEP do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'CEP deve ter 8 dígitos sem hífen (ex: 01310100)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ006', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ007 — Cidade do sacado não pode estar vazia
  static ResultadoRegra sQ007CidadeSacado(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 157) return ResultadoRegra.sucesso('SQ007', tempoMs: sw.elapsedMilliseconds);

    // Posição 138-157 (índice 137-156) = 20 chars
    final cidade = seg.substring(137, 157).trim();
    if (cidade.isEmpty) {
      return ResultadoRegra.falha('SQ007', [
        ErroValidacao(
          codigo: 'SQ007',
          descricao: 'Cidade do sacado vazia no Segmento Q',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 138,
          posicaoFim: 157,
          campoCnab: 'Cidade do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'Preencha a cidade do sacado',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ007', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ008 — UF do sacado deve ser válida (2 letras maiúsculas)
  static ResultadoRegra sQ008UfSacado(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 159) return ResultadoRegra.sucesso('SQ008', tempoMs: sw.elapsedMilliseconds);

    // Posição 158-159 (índice 157-158) = 2 chars
    final uf = seg.substring(157, 159);
    if (uf.trim().isNotEmpty && !_ufsValidas.contains(uf)) {
      return ResultadoRegra.falha('SQ008', [
        ErroValidacao(
          codigo: 'SQ008',
          descricao: 'UF do sacado inválida no Segmento Q',
          detalhe: 'Encontrado: "$uf". Use a sigla do estado (ex: SP, RJ, MG)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 158,
          posicaoFim: 159,
          campoCnab: 'UF/Estado do Pagador',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao: 'Use a sigla de 2 letras do estado (SP, RJ, MG, etc.)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ008', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ009 — Tipo inscrição sacador: se preenchido, deve ser 01 ou 02
  static ResultadoRegra sQ009TipoInscricaoAvalista(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 161) return ResultadoRegra.sucesso('SQ009', tempoMs: sw.elapsedMilliseconds);

    // Posição 160-161 (índice 159-160) = tipo do sacador/avalista
    // 00 = não presente, 01 = CPF, 02 = CNPJ
    final tipoAval = seg.substring(159, 161);
    if (tipoAval != '00' && tipoAval != '01' && tipoAval != '02') {
      return ResultadoRegra.falha('SQ009', [
        ErroValidacao(
          codigo: 'SQ009',
          descricao: 'Tipo de inscrição do sacador/avalista inválido no Segmento Q',
          detalhe: 'Encontrado: "$tipoAval". Válidos: 00=Não presente, 01=CPF, 02=CNPJ',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoQ,
          linha: numLinha,
          posicaoInicio: 160,
          posicaoFim: 161,
          campoCnab: 'Tipo de Inscrição do Sacador/Avalista',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SQ009', tempoMs: sw.elapsedMilliseconds);
  }

  /// SQ010 — Se sacador/avalista presente, nome não pode ser vazio
  static ResultadoRegra sQ010NomeAvalista(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 215) return ResultadoRegra.sucesso('SQ010', tempoMs: sw.elapsedMilliseconds);

    final tipoAval = seg.length >= 161 ? seg.substring(159, 161) : '00';

    if (tipoAval != '00') {
      // Posição 176-215 (índice 175-214) = 40 chars
      final nomeAval = seg.substring(175, 215).trim();
      if (nomeAval.isEmpty) {
        return ResultadoRegra.falha('SQ010', [
          ErroValidacao(
            codigo: 'SQ010',
            descricao: 'Nome do sacador/avalista vazio apesar de tipo indicado no Segmento Q',
            detalhe: 'Tipo inscrição sacador: $tipoAval',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.segmentoQ,
            linha: numLinha,
            posicaoInicio: 176,
            posicaoFim: 215,
            campoCnab: 'Nome do Sacador/Avalista',
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
