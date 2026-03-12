// core/validation/rules/segmento_p_rules.dart
// Regras de validação do Segmento P CNAB 240
// Layout H7815 V8.5 Fev/2026 — Santander Cobrança CNAB 240 Posições

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraSegmentoP {
  // ── Mapa de Posições H7815 V8.5 — Segmento P ──────────────────────────────
  // Pos  1-  3: Código Banco (033)
  // Pos  4-  7: Lote de Serviço (0001)
  // Pos     8: Tipo Registro (3)
  // Pos  9- 13: Nr Sequencial do Registro no Lote
  // Pos    14: Código Segmento (P)
  // Pos    15: Reservado (uso Banco — branco)
  // Pos 16- 17: Código de Movimento Remessa (2 chars: 01=Entrada)
  // Pos 18- 21: Agência (4 dígitos)
  // Pos    22: Dígito Agência
  // Pos 23- 31: Conta Corrente (9 dígitos) — H7815
  // Pos    32: Dígito Verificador da Conta
  // Pos 33- 41: Conta cobrança Destinatária FIDC (9 zeros)
  // Pos    42: Dígito conta FIDC (zero)
  // Pos 43- 44: Reservado (2 brancos)
  // Pos 45- 57: Nosso Número — 13 posições numéricas (H7815 Nota 15)
  // Pos    58: Tipo de Cobrança/Carteira (1=Simples, 3=Caucionada, 4=Descontada, 5=Simples Rápida)
  // Pos    59: Forma de Cadastramento (1=Com Registro)
  // Pos    60: Tipo de Documento (2=Escritural)
  // Pos 61- 62: Reservado (2 brancos)
  // Pos 63- 77: Número do Documento/Seu Número (15 alfa)
  // Pos 78- 85: Data de Vencimento (DDMMAAAA)
  // Pos 86-100: Valor Nominal (15 num, 2 decimais)
  // Pos 101-104: Agência Encarregada Cobrança FIDC (4 zeros)
  // Pos   105: Dígito Ag Cobradora FIDC (zero)
  // Pos   106: Reservado (branco)
  // Pos 107-108: Espécie do Boleto (2 num: 02=DM, 04=DS, 12=NP, etc.)
  // Pos   109: Aceite (A/N)
  // Pos 110-117: Data Emissão (DDMMAAAA)
  // Pos   118: Código Juros (1=Valor/dia, 2=Taxa%, 3=Isento)
  // Pos 119-126: Data Juros (DDMMAAAA)
  // Pos 127-141: Valor/Taxa Juros (15 num)
  // Pos   142: Código Desconto 1 (0=Sem, 1=Valor, 2=%)
  // Pos 143-150: Data Desconto 1 (DDMMAAAA)
  // Pos 151-165: Valor/Percentual Desconto 1 (15 num)
  // Pos 166-180: IOF (15 zeros)
  // Pos 181-195: Abatimento (15 zeros)
  // Pos 196-220: Identificação na Empresa/Seu Número (25 alfa)
  // Pos   221: Código Protesto (3=Não Protestar)
  // Pos 222-223: Dias Protesto (2 num)
  // Pos   224: Código Baixa (1=Baixar)
  // Pos   225: Reservado (zero)
  // Pos 226-227: Dias Baixa (2 num)
  // Pos 228-229: Código Moeda (2 num: 09=Real — H7815 usa 2 chars)
  // Pos 230-240: Reservado (11 brancos)

  static const _codigosMovimento = {'01', '02', '04', '05', '06', '07', '08', '09', '10', '11', '12', '15', '16', '17'};
  
  // H7815 Nota 20: Espécies válidas
  static const _codigosEspecie = {
    '02', '04', '07', '12', '13', '17', '20', '30', '31', '32', '33', '97', '98',
  };

  /// SP001 — Código do banco deve ser 033
  static ResultadoRegra sP001CodigoBanco(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 3) return ResultadoRegra.sucesso('SP001', tempoMs: sw.elapsedMilliseconds);

    final banco = seg.substring(0, 3);
    if (banco != '033') {
      return ResultadoRegra.falha('SP001', [
        ErroValidacao(
          codigo: 'SP001',
          descricao: 'Código do banco inválido no Segmento P',
          detalhe: 'Encontrado: "$banco". Esperado: "033"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 1,
          posicaoFim: 3,
          campoCnab: 'Código do Banco',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP001', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP002 — Tipo de registro deve ser 3 (Detalhe)
  static ResultadoRegra sP002TipoRegistro(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 8) return ResultadoRegra.sucesso('SP002', tempoMs: sw.elapsedMilliseconds);

    final tipo = seg.substring(7, 8);
    if (tipo != '3') {
      return ResultadoRegra.falha('SP002', [
        ErroValidacao(
          codigo: 'SP002',
          descricao: 'Tipo de registro do Segmento P inválido',
          detalhe: 'Encontrado: "$tipo". Esperado: "3"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 8,
          posicaoFim: 8,
          campoCnab: 'Tipo de Registro',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP002', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP003 — Código de segmento deve ser P
  static ResultadoRegra sP003CodigoSegmento(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 14) return ResultadoRegra.sucesso('SP003', tempoMs: sw.elapsedMilliseconds);

    final codSeg = seg.substring(13, 14);
    if (codSeg != 'P') {
      return ResultadoRegra.falha('SP003', [
        ErroValidacao(
          codigo: 'SP003',
          descricao: 'Código de segmento inválido (esperado P)',
          detalhe: 'Encontrado: "$codSeg"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 14,
          posicaoFim: 14,
          campoCnab: 'Código do Segmento',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP003', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP004 — Código de movimento: posição 16-17 (2 chars), válidos: 01..17
  static ResultadoRegra sP004CodigoMovimento(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 17) return ResultadoRegra.sucesso('SP004', tempoMs: sw.elapsedMilliseconds);

    // H7815: posição 15 é reservada (branco), posição 16-17 = código movimento
    final mov = seg.substring(15, 17);
    if (!_codigosMovimento.contains(mov)) {
      return ResultadoRegra.falha('SP004', [
        ErroValidacao(
          codigo: 'SP004',
          descricao: 'Código de movimento inválido no Segmento P (posição 16-17)',
          detalhe: 'Encontrado: "$mov". H7815 Nota 14: 01=Entrada, 02=Baixa, 04=Abatimento...',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 16,
          posicaoFim: 17,
          campoCnab: 'Código de Movimento Remessa',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Use 01 para Entrada de Boleto (Nota 14 H7815 V8.5)',
          referenciaFebraban: 'H7815 V8.5 Nota 14 — Código de Movimento para Remessa',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP004', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP005 — Agência: posição 18-21 (4 dígitos)
  static ResultadoRegra sP005Agencia(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 21) return ResultadoRegra.sucesso('SP005', tempoMs: sw.elapsedMilliseconds);

    final ag = seg.substring(17, 21);
    if (!RegExp(r'^\d{4}$').hasMatch(ag)) {
      return ResultadoRegra.falha('SP005', [
        ErroValidacao(
          codigo: 'SP005',
          descricao: 'Agência inválida no Segmento P (posição 18-21)',
          detalhe: 'Encontrado: "$ag". Esperado: 4 dígitos numéricos',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 18,
          posicaoFim: 21,
          campoCnab: 'Agência do Destinatária',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP005', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP006 — Conta Corrente: posição 23-31 (9 dígitos) — H7815 V8.5
  static ResultadoRegra sP006Conta(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 31) return ResultadoRegra.sucesso('SP006', tempoMs: sw.elapsedMilliseconds);

    final conta = seg.substring(22, 31);
    if (!RegExp(r'^\d{9}$').hasMatch(conta)) {
      return ResultadoRegra.falha('SP006', [
        ErroValidacao(
          codigo: 'SP006',
          descricao: 'Número de conta inválido no Segmento P (posição 23-31)',
          detalhe: 'Encontrado: "$conta". H7815: 9 dígitos numéricos',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 23,
          posicaoFim: 31,
          campoCnab: 'Número da Conta Corrente',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          referenciaFebraban: 'H7815 V8.5 — Posição 23-31: Conta 9 dígitos',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP006', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP007 — Nosso Número: posição 45-57 (13 dígitos) — H7815 Nota 15
  static ResultadoRegra sP007NossoNumero(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 57) return ResultadoRegra.sucesso('SP007', tempoMs: sw.elapsedMilliseconds);

    // H7815 Nota 15: posição 45-57 = 13 posições numéricas (Nosso Número)
    final nossoNum = seg.substring(44, 57);
    if (!RegExp(r'^\d{13}$').hasMatch(nossoNum) || RegExp(r'^0+$').hasMatch(nossoNum)) {
      return ResultadoRegra.falha('SP007', [
        ErroValidacao(
          codigo: 'SP007',
          descricao: 'Nosso Número inválido ou zerado no Segmento P (posição 45-57)',
          detalhe: 'Encontrado: "$nossoNum". H7815: 13 dígitos numéricos com DAC Módulo 11',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 45,
          posicaoFim: 57,
          campoCnab: 'Identificação do Boleto no Banco (Nosso Número)',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'H7815 Nota 15: Nosso Número = 12 dígitos + 1 DAC Módulo 11',
          referenciaFebraban: 'H7815 V8.5 Nota 15 — Nosso Número: 13 posições',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP007', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP008 — Tipo de Cobrança (Carteira): posição 58 (1 char)
  /// H7815 Nota 5: '1'=Simples, '3'=Caucionada, '4'=Descontada, '5'=Simples Rápida
  static ResultadoRegra sP008Carteira(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 58) return ResultadoRegra.sucesso('SP008', tempoMs: sw.elapsedMilliseconds);

    final tipoCobranca = seg.substring(57, 58);
    const tiposValidos = {'1', '3', '4', '5', '6', '7', '8', '9', 'B'};
    if (!tiposValidos.contains(tipoCobranca)) {
      return ResultadoRegra.falha('SP008', [
        ErroValidacao(
          codigo: 'SP008',
          descricao: 'Tipo de Cobrança (Carteira) inválido no Segmento P (posição 58)',
          detalhe: 'Encontrado: "$tipoCobranca". H7815 Nota 5: 1=Simples, 3=Caucionada, 4=Descontada, 5=Simples Rápida',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 58,
          posicaoFim: 58,
          campoCnab: 'Tipo de Cobrança (Carteira)',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Use 1=Simples (mais comum) conforme H7815 Nota 5',
          referenciaFebraban: 'H7815 V8.5 Nota 5 — Tipo de Cobrança',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP008', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP009 — Número do documento: posição 63-77 (15 alfa) — H7815 Nota 16
  static ResultadoRegra sP009NumeroDocumento(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 77) return ResultadoRegra.sucesso('SP009', tempoMs: sw.elapsedMilliseconds);

    final numDoc = seg.substring(62, 77).trim();
    if (numDoc.isEmpty) {
      return ResultadoRegra.falha('SP009', [
        ErroValidacao(
          codigo: 'SP009',
          descricao: 'Número do documento (seu número) vazio no Segmento P (posição 63-77)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 63,
          posicaoFim: 77,
          campoCnab: 'Número do Documento (Seu Número)',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'H7815 Nota 16: Preencha com número da duplicata ou identificador',
          referenciaFebraban: 'H7815 V8.5 Nota 16 — Número do Documento',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP009', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP010 — Data de vencimento: posição 78-85 (DDMMAAAA) — H7815
  static ResultadoRegra sP010DataVencimento(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 85) return ResultadoRegra.sucesso('SP010', tempoMs: sw.elapsedMilliseconds);

    final dataStr = seg.substring(77, 85);

    if (dataStr == '00000000') {
      return ResultadoRegra.sucesso('SP010', tempoMs: sw.elapsedMilliseconds);
    }

    if (!RegExp(r'^\d{8}$').hasMatch(dataStr)) {
      return ResultadoRegra.falha('SP010', [
        ErroValidacao(
          codigo: 'SP010',
          descricao: 'Data de vencimento com formato inválido no Segmento P (posição 78-85)',
          detalhe: 'Encontrado: "$dataStr". Esperado: DDMMAAAA',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 78,
          posicaoFim: 85,
          campoCnab: 'Data de Vencimento do Boleto',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Use formato DDMMAAAA (ex: 10042026)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    try {
      final dia = int.parse(dataStr.substring(0, 2));
      final mes = int.parse(dataStr.substring(2, 4));
      final ano = int.parse(dataStr.substring(4, 8));
      final vencimento = DateTime(ano, mes, dia);

      if (vencimento.day != dia || vencimento.month != mes || vencimento.year != ano) {
        return ResultadoRegra.falha('SP010', [
          ErroValidacao(
            codigo: 'SP010',
            descricao: 'Data de vencimento inválida (data inexistente)',
            detalhe: 'Data: $dataStr',
            severidade: SeveridadeValidacao.fatal,
            categoria: CategoriaValidacao.segmentoP,
            linha: numLinha,
            posicaoInicio: 78,
            posicaoFim: 85,
            campoCnab: 'Data de Vencimento',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'P',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    } catch (_) {}

    return ResultadoRegra.sucesso('SP010', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP011 — Data de emissão: posição 110-117 (DDMMAAAA) — H7815
  static ResultadoRegra sP011DataEmissao(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 117) return ResultadoRegra.sucesso('SP011', tempoMs: sw.elapsedMilliseconds);

    final dataStr = seg.substring(109, 117);

    if (dataStr == '00000000') {
      return ResultadoRegra.falha('SP011', [
        ErroValidacao(
          codigo: 'SP011',
          descricao: 'Data de emissão zerada no Segmento P (posição 110-117)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 110,
          posicaoFim: 117,
          campoCnab: 'Data da Emissão do Boleto',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Preencha com a data de emissão do boleto',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    if (!RegExp(r'^\d{8}$').hasMatch(dataStr)) {
      return ResultadoRegra.falha('SP011', [
        ErroValidacao(
          codigo: 'SP011',
          descricao: 'Data de emissão com formato inválido no Segmento P (posição 110-117)',
          detalhe: 'Encontrado: "$dataStr". Esperado: DDMMAAAA',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 110,
          posicaoFim: 117,
          campoCnab: 'Data da Emissão do Boleto',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('SP011', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP012 — Valor do título: posição 86-100 (15 num, 2 decimais) — H7815
  static ResultadoRegra sP012ValorTitulo(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 100) return ResultadoRegra.sucesso('SP012', tempoMs: sw.elapsedMilliseconds);

    final valorStr = seg.substring(85, 100);
    final valor = int.tryParse(valorStr);

    if (valor == null || valor <= 0) {
      return ResultadoRegra.falha('SP012', [
        ErroValidacao(
          codigo: 'SP012',
          descricao: 'Valor do boleto inválido ou zerado no Segmento P (posição 86-100)',
          detalhe: 'Encontrado: "$valorStr" (= ${valor == null ? "inválido" : (valor / 100.0).toStringAsFixed(2)})',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 86,
          posicaoFim: 100,
          campoCnab: 'Valor Nominal do Boleto',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Valor deve ser positivo. 15 dígitos com 2 decimais implícitos.',
          referenciaFebraban: 'H7815 V8.5 — Posição 86-100: Valor Nominal',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP012', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP013 — Espécie do boleto: posição 107-108 (2 num) — H7815 Nota 20
  /// Válidos: 02=DM, 04=DS, 12=NP, 13=NR, 17=RC, 20=AP, 31=BCC, 97=CH, 98=ND
  static ResultadoRegra sP013EspecieTitulo(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 108) return ResultadoRegra.sucesso('SP013', tempoMs: sw.elapsedMilliseconds);

    final especie = seg.substring(106, 108);
    if (!_codigosEspecie.contains(especie)) {
      return ResultadoRegra.falha('SP013', [
        ErroValidacao(
          codigo: 'SP013',
          descricao: 'Espécie do boleto inválida no Segmento P (posição 107-108)',
          detalhe: 'Encontrado: "$especie". H7815 Nota 20: 02=DM, 04=DS, 12=NP, 17=RC, 97=CH',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 107,
          posicaoFim: 108,
          campoCnab: 'Espécie do Boleto',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Use 02 (DM — Duplicata Mercantil) ou 04 (DS — Duplicata de Serviço)',
          referenciaFebraban: 'H7815 V8.5 Nota 20 — Espécie do Boleto',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP013', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP014 — Aceite: posição 109 (A/N) — H7815
  static ResultadoRegra sP014Aceite(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 109) return ResultadoRegra.sucesso('SP014', tempoMs: sw.elapsedMilliseconds);

    final aceite = seg.substring(108, 109);
    if (aceite != 'A' && aceite != 'N') {
      return ResultadoRegra.falha('SP014', [
        ErroValidacao(
          codigo: 'SP014',
          descricao: 'Aceite inválido no Segmento P (posição 109)',
          detalhe: 'Encontrado: "$aceite". Válidos: "A" (Aceito) ou "N" (Não Aceito)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 109,
          posicaoFim: 109,
          campoCnab: 'Identificação de Boleto Aceito/Não Aceito',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Use "N" para não aceito (padrão)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP014', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP015 — Código de juros: posição 118 (1=Valor/dia, 2=Taxa%, 3=Isento) — H7815
  static ResultadoRegra sP015CodigoJuros(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 118) return ResultadoRegra.sucesso('SP015', tempoMs: sw.elapsedMilliseconds);

    final codJuros = seg.substring(117, 118);
    if (!{'1', '2', '3'}.contains(codJuros)) {
      return ResultadoRegra.falha('SP015', [
        ErroValidacao(
          codigo: 'SP015',
          descricao: 'Código de juros inválido no Segmento P (posição 118)',
          detalhe: 'Encontrado: "$codJuros". H7815: 1=Valor/dia, 2=Taxa mensal%, 3=Isento',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 118,
          posicaoFim: 118,
          campoCnab: 'Código de Juros de Mora',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Use 3 para isento de juros',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP015', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP016 — Código desconto 1: posição 142 (0=Sem, 1=Valor, 2=%) — H7815
  static ResultadoRegra sP016CodigoDesconto(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 142) return ResultadoRegra.sucesso('SP016', tempoMs: sw.elapsedMilliseconds);

    final codDesc = seg.substring(141, 142);
    if (!{'0', '1', '2'}.contains(codDesc)) {
      return ResultadoRegra.falha('SP016', [
        ErroValidacao(
          codigo: 'SP016',
          descricao: 'Código de desconto 1 inválido no Segmento P (posição 142)',
          detalhe: 'Encontrado: "$codDesc". H7815: 0=Sem, 1=Valor fixo, 2=Percentual',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 142,
          posicaoFim: 142,
          campoCnab: 'Código do Desconto 1',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP016', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP017 — Código da moeda: posição 228-229 (2 chars: 09=Real) — H7815
  /// ATENÇÃO: H7815 usa 2 chars (09), não 3 como FEBRABAN padrão (009)!
  static ResultadoRegra sP017CodigoMoeda(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 229) return ResultadoRegra.sucesso('SP017', tempoMs: sw.elapsedMilliseconds);

    final moeda = seg.substring(227, 229);
    if (moeda != '09') {
      return ResultadoRegra.falha('SP017', [
        ErroValidacao(
          codigo: 'SP017',
          descricao: 'Código de moeda inválido no Segmento P (posição 228-229)',
          detalhe: 'Encontrado: "$moeda". H7815 usa "09" = Real Brasileiro (2 chars)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 228,
          posicaoFim: 229,
          campoCnab: 'Código da Moeda',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          referenciaFebraban: 'H7815 V8.5 — Posição 228-229: Código Moeda = 09 (Real)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP017', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP018 — Código para protesto: posição 221 (1 char) — H7815 Nota 25
  static ResultadoRegra sP018CodigoProtesto(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 221) return ResultadoRegra.sucesso('SP018', tempoMs: sw.elapsedMilliseconds);

    final codProtesto = seg.substring(220, 221);
    if (!RegExp(r'^\d$').hasMatch(codProtesto)) {
      return ResultadoRegra.falha('SP018', [
        ErroValidacao(
          codigo: 'SP018',
          descricao: 'Código de protesto inválido no Segmento P (posição 221)',
          detalhe: 'Encontrado: "$codProtesto". H7815 Nota 25: 1=Protestar, 2=Dev, 3=Não Protestar',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 221,
          posicaoFim: 221,
          campoCnab: 'Código para Protesto',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          referenciaFebraban: 'H7815 V8.5 Nota 25 — Código para Protesto',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP018', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP019 — Número sequencial do registro deve ser numérico e sequencial
  static ResultadoRegra sP019NumeroSequencial(String seg, int numLinha, int idxTitulo, int esperado) {
    final sw = Stopwatch()..start();
    if (seg.length < 13) return ResultadoRegra.sucesso('SP019', tempoMs: sw.elapsedMilliseconds);

    final seqStr = seg.substring(8, 13);
    final seq = int.tryParse(seqStr);

    if (seq == null) {
      return ResultadoRegra.falha('SP019', [
        ErroValidacao(
          codigo: 'SP019',
          descricao: 'Número sequencial do Segmento P não é numérico (posição 9-13)',
          detalhe: 'Valor: "$seqStr"',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 9,
          posicaoFim: 13,
          campoCnab: 'Nr Sequencial do Registro no Lote',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    if (seq != esperado) {
      return ResultadoRegra.falha('SP019', [
        ErroValidacao(
          codigo: 'SP019',
          descricao: 'Número sequencial fora de ordem no Segmento P',
          detalhe: 'Encontrado: $seq. Esperado: $esperado',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 9,
          posicaoFim: 13,
          campoCnab: 'Nr Sequencial do Registro no Lote',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('SP019', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP020 — Valor do abatimento não pode ser maior que o valor do título
  static ResultadoRegra sP020ValorAbatimento(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 195) return ResultadoRegra.sucesso('SP020', tempoMs: sw.elapsedMilliseconds);

    // Valor título: pos 86-100 (85-99)
    // Valor abatimento: pos 181-195 (180-194)
    final valorTitStr = seg.substring(85, 100);
    final valorAbaStr = seg.substring(180, 195);

    final valorTit = int.tryParse(valorTitStr) ?? 0;
    final valorAba = int.tryParse(valorAbaStr) ?? 0;

    if (valorAba > valorTit && valorAba > 0) {
      return ResultadoRegra.falha('SP020', [
        ErroValidacao(
          codigo: 'SP020',
          descricao: 'Valor do abatimento maior que o valor do boleto (pos 181-195)',
          detalhe: 'Boleto: R\$ ${(valorTit / 100.0).toStringAsFixed(2)} | Abatimento: R\$ ${(valorAba / 100.0).toStringAsFixed(2)}',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 181,
          posicaoFim: 195,
          campoCnab: 'Valor do Abatimento',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP020', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP021 — Identificação na empresa (Seu Número): posição 196-220 (25 alfa) — H7815
  static ResultadoRegra sP021IdentificacaoEmpresa(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 220) return ResultadoRegra.sucesso('SP021', tempoMs: sw.elapsedMilliseconds);

    final seuNum = seg.substring(195, 220).trim();
    if (seuNum.isEmpty) {
      return ResultadoRegra.falha('SP021', [
        ErroValidacao(
          codigo: 'SP021',
          descricao: 'Identificação do boleto na empresa em branco (posição 196-220)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 196,
          posicaoFim: 220,
          campoCnab: 'Identificação do Boleto na Empresa (Seu Número)',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Preencha com o número de controle do boleto na empresa (até 25 chars)',
          referenciaFebraban: 'H7815 V8.5 — Posição 196-220: Identificação na Empresa (25 posições)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP021', tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras de Segmento P
  static List<ResultadoRegra> validarTudo(
      String segLinha, int numLinha, int idxTitulo, int nrSeqEsperado) {
    return [
      sP001CodigoBanco(segLinha, numLinha, idxTitulo),
      sP002TipoRegistro(segLinha, numLinha, idxTitulo),
      sP003CodigoSegmento(segLinha, numLinha, idxTitulo),
      sP004CodigoMovimento(segLinha, numLinha, idxTitulo),
      sP005Agencia(segLinha, numLinha, idxTitulo),
      sP006Conta(segLinha, numLinha, idxTitulo),
      sP007NossoNumero(segLinha, numLinha, idxTitulo),
      sP008Carteira(segLinha, numLinha, idxTitulo),
      sP009NumeroDocumento(segLinha, numLinha, idxTitulo),
      sP010DataVencimento(segLinha, numLinha, idxTitulo),
      sP011DataEmissao(segLinha, numLinha, idxTitulo),
      sP012ValorTitulo(segLinha, numLinha, idxTitulo),
      sP013EspecieTitulo(segLinha, numLinha, idxTitulo),
      sP014Aceite(segLinha, numLinha, idxTitulo),
      sP015CodigoJuros(segLinha, numLinha, idxTitulo),
      sP016CodigoDesconto(segLinha, numLinha, idxTitulo),
      sP017CodigoMoeda(segLinha, numLinha, idxTitulo),
      sP018CodigoProtesto(segLinha, numLinha, idxTitulo),
      sP019NumeroSequencial(segLinha, numLinha, idxTitulo, nrSeqEsperado),
      sP020ValorAbatimento(segLinha, numLinha, idxTitulo),
      sP021IdentificacaoEmpresa(segLinha, numLinha, idxTitulo),
    ];
  }
}
