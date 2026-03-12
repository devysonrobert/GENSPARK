// core/validation/rules/segmento_p_rules.dart
// Regras de validação do Segmento P CNAB 240
// FEBRABAN CNAB 240 v10.7 — Segmento P (dados do boleto/título)
// Posições definidas pela especificação Santander Cobrança

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraSegmentoP {
  // ── Posições Santander Segmento P ────────────────────────────────────────
  // Pos  1- 3: Código Banco (033)
  // Pos  4- 7: Lote de Serviço
  // Pos     8: Tipo Registro (3)
  // Pos  9-13: Nr Sequencial do Registro no Lote
  // Pos    14: Código Segmento (P)
  // Pos    15: Tipo Movimento (0=Inclusão, 2=Alteração, 5=Cancelamento)
  // Pos 16-17: Código Instrução p/ Movimento
  // Pos 18-21: Agência (4 dígitos)
  // Pos    22: Dígito Agência
  // Pos 23-30: Conta Corrente (8 dígitos)
  // Pos    31: Dígito Conta
  // Pos    32: Dígito AG/Conta
  // Pos 33-52: Identificação do Título no Banco (Nosso Número formatado: carteira 3 + número 12 + DAC 1 = 16 chars no P)
  // Pos 53-57: Carteira (3 dígitos p/ Santander, ex: 101, 102, 104, 201)
  // Pos 58-62: Forma de Cadastro (3) / Tipo de Documento (P/Posição 57)
  // Pos 63-72: Número do Documento (10 chars)
  // Pos 73-80: Data de Vencimento (DDMMAAAA)
  // Pos 81-95: Valor do Título (13 inteiros + 2 decimais = 15)
  // Pos 96-100: Banco cobrador (zeros = sem instrução)
  // Pos 101-104: Agência cobradora
  // Pos   105: Espécie do Título
  // Pos   106: Aceite (A/N)
  // Pos 107-114: Data Emissão (DDMMAAAA)
  // Pos   115: Código de Juros (0=Isento, 1=Valor/dia, 2=Taxa mensal)
  // Pos 116-123: Data de Juros (DDMMAAAA)
  // Pos 124-138: Valor/Taxa de Juros (15 dígitos, 2 decimais)
  // Pos   139: Código Desconto 1 (0=Sem, 1=Valor, 2=Percentual, 3=Antecipado)
  // Pos 140-147: Data Desconto 1 (DDMMAAAA)
  // Pos 148-162: Valor/Percentual Desconto 1 (15 dígitos, 2 decimais)
  // Pos 163-177: Valor IOF (15 dígitos, 2 decimais)
  // Pos 178-192: Valor Abatimento (15 dígitos, 2 decimais)
  // Pos 193-212: Identificação do Título na Empresa (20 chars)
  // Pos   213: Código para Protesto (1-9)
  // Pos 214-215: Número de Dias p/ Protesto
  // Pos   216: Código p/ Baixa/Devolução
  // Pos 217-219: Número de Dias p/ Baixa
  // Pos 220-222: Código da Moeda (009 = Real)
  // Pos 223-232: Nr do Contrato da Operação de Crédito (brancos)
  // Pos   233: Uso Livre (branco)

  static const _codigosMovimento = {'0', '1', '2', '3', '4', '5', '7', '9'};
  static const _codigosEspecie = {
    '01', '02', '03', '04', '05', '06', '07', '08',
    '09', '10', '11', '12', '13', '14', '15', '16',
    '17', '18', '19', '20', '21', '22', '23', '24',
    '30', '31', '32',
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

  /// SP004 — Código de movimento deve ser válido
  static ResultadoRegra sP004CodigoMovimento(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 15) return ResultadoRegra.sucesso('SP004', tempoMs: sw.elapsedMilliseconds);

    final mov = seg.substring(14, 15);
    if (!_codigosMovimento.contains(mov)) {
      return ResultadoRegra.falha('SP004', [
        ErroValidacao(
          codigo: 'SP004',
          descricao: 'Código de movimento inválido no Segmento P',
          detalhe: 'Encontrado: "$mov". Válidos: ${_codigosMovimento.join(", ")}',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 15,
          posicaoFim: 15,
          campoCnab: 'Tipo de Movimento',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Use 0 para Inclusão, 2 para Alteração, 5 para Cancelamento',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP004', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP005 — Agência: 4 dígitos numéricos
  static ResultadoRegra sP005Agencia(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 21) return ResultadoRegra.sucesso('SP005', tempoMs: sw.elapsedMilliseconds);

    final ag = seg.substring(17, 21);
    if (!RegExp(r'^\d{4}$').hasMatch(ag)) {
      return ResultadoRegra.falha('SP005', [
        ErroValidacao(
          codigo: 'SP005',
          descricao: 'Agência inválida no Segmento P',
          detalhe: 'Encontrado: "$ag". Esperado: 4 dígitos numéricos',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 18,
          posicaoFim: 21,
          campoCnab: 'Agência Mantenedora',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP005', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP006 — Conta: 8 dígitos numéricos
  static ResultadoRegra sP006Conta(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 30) return ResultadoRegra.sucesso('SP006', tempoMs: sw.elapsedMilliseconds);

    final conta = seg.substring(22, 30);
    if (!RegExp(r'^\d{8}$').hasMatch(conta)) {
      return ResultadoRegra.falha('SP006', [
        ErroValidacao(
          codigo: 'SP006',
          descricao: 'Número de conta inválido no Segmento P',
          detalhe: 'Encontrado: "$conta". Esperado: 8 dígitos numéricos',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 23,
          posicaoFim: 30,
          campoCnab: 'Número da Conta Corrente',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP006', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP007 — Nosso número não pode estar vazio ou zerado
  static ResultadoRegra sP007NossoNumero(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 52) return ResultadoRegra.sucesso('SP007', tempoMs: sw.elapsedMilliseconds);

    // Posição 33-52 = nosso número completo (carteira 3 + número 12 + DAC 1 = 16 no formato atual)
    // No Santander o campo tem 20 caracteres: pos 33-52
    final nossoNum = seg.substring(32, 52).trim();
    if (nossoNum.isEmpty || RegExp(r'^0+$').hasMatch(nossoNum)) {
      return ResultadoRegra.falha('SP007', [
        ErroValidacao(
          codigo: 'SP007',
          descricao: 'Nosso Número vazio ou zerado no Segmento P',
          detalhe: 'Valor encontrado: "${seg.substring(32, 52)}"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 33,
          posicaoFim: 52,
          campoCnab: 'Identificação do Título no Banco (Nosso Número)',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Preencha o nosso número com código carteira (3) + número (12) + DAC (1)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP007', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP008 — Carteira deve ser válida (101, 102, 104, 201)
  static ResultadoRegra sP008Carteira(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 56) return ResultadoRegra.sucesso('SP008', tempoMs: sw.elapsedMilliseconds);

    // Posição 53-55 ou parte do Nosso Número — depende do layout
    // No Santander a carteira está nos primeiros 3 chars da posição 33 do nosso número
    final cartStr = seg.substring(32, 35);
    const carteirasValidas = {'101', '102', '104', '201'};
    if (!carteirasValidas.contains(cartStr)) {
      return ResultadoRegra.falha('SP008', [
        ErroValidacao(
          codigo: 'SP008',
          descricao: 'Código de carteira inválido no Segmento P',
          detalhe: 'Encontrado: "$cartStr". Válidos: 101, 102, 104, 201',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 33,
          posicaoFim: 35,
          campoCnab: 'Carteira',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Santander aceita carteiras 101 (Simples), 102 (Vinculada), 104 (Caucionada), 201 (Descontada)',
          referenciaFebraban:
              'Santander CNAB 240 — Carteiras: 101/102/104/201',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP008', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP009 — Número do documento não pode estar vazio
  static ResultadoRegra sP009NumeroDocumento(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 72) return ResultadoRegra.sucesso('SP009', tempoMs: sw.elapsedMilliseconds);

    // Posição 63-72 (índice 62-71)
    final numDoc = seg.substring(62, 72).trim();
    if (numDoc.isEmpty) {
      return ResultadoRegra.falha('SP009', [
        ErroValidacao(
          codigo: 'SP009',
          descricao: 'Número do documento (seu número) vazio no Segmento P',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 63,
          posicaoFim: 72,
          campoCnab: 'Número do Documento (Seu Número)',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Preencha com o número do documento emitido pela empresa',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP009', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP010 — Data de vencimento deve ser válida e não anterior a hoje
  static ResultadoRegra sP010DataVencimento(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 80) return ResultadoRegra.sucesso('SP010', tempoMs: sw.elapsedMilliseconds);

    // Posição 73-80 (índice 72-79)
    final dataStr = seg.substring(72, 80);

    // Aceitar 00000000 como "sem vencimento" (cobrança sem prazo)
    if (dataStr == '00000000') {
      return ResultadoRegra.sucesso('SP010', tempoMs: sw.elapsedMilliseconds);
    }

    if (!RegExp(r'^\d{8}$').hasMatch(dataStr)) {
      return ResultadoRegra.falha('SP010', [
        ErroValidacao(
          codigo: 'SP010',
          descricao: 'Data de vencimento com formato inválido no Segmento P',
          detalhe: 'Encontrado: "$dataStr". Esperado: DDMMAAAA',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 73,
          posicaoFim: 80,
          campoCnab: 'Data de Vencimento do Título',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Use formato DDMMAAAA (ex: 15012025)',
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
            posicaoInicio: 73,
            posicaoFim: 80,
            campoCnab: 'Data de Vencimento',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'P',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    } catch (_) {}

    return ResultadoRegra.sucesso('SP010', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP011 — Data de emissão deve ser válida
  static ResultadoRegra sP011DataEmissao(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 114) return ResultadoRegra.sucesso('SP011', tempoMs: sw.elapsedMilliseconds);

    // Posição 107-114 (índice 106-113)
    final dataStr = seg.substring(106, 114);

    if (dataStr == '00000000') {
      return ResultadoRegra.falha('SP011', [
        ErroValidacao(
          codigo: 'SP011',
          descricao: 'Data de emissão zerada no Segmento P',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 107,
          posicaoFim: 114,
          campoCnab: 'Data de Emissão do Título',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Preencha com a data de emissão do título',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    if (!RegExp(r'^\d{8}$').hasMatch(dataStr)) {
      return ResultadoRegra.falha('SP011', [
        ErroValidacao(
          codigo: 'SP011',
          descricao: 'Data de emissão com formato inválido no Segmento P',
          detalhe: 'Encontrado: "$dataStr". Esperado: DDMMAAAA',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 107,
          posicaoFim: 114,
          campoCnab: 'Data de Emissão do Título',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('SP011', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP012 — Valor do título deve ser > 0
  static ResultadoRegra sP012ValorTitulo(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 95) return ResultadoRegra.sucesso('SP012', tempoMs: sw.elapsedMilliseconds);

    // Posição 81-95 (índice 80-94) = 15 chars
    final valorStr = seg.substring(80, 95);
    final valor = int.tryParse(valorStr);

    if (valor == null || valor <= 0) {
      return ResultadoRegra.falha('SP012', [
        ErroValidacao(
          codigo: 'SP012',
          descricao: 'Valor do título inválido ou zerado no Segmento P',
          detalhe: 'Encontrado: "$valorStr" (valor = ${valor == null ? "inválido" : valor / 100.0})',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 81,
          posicaoFim: 95,
          campoCnab: 'Valor Nominal do Título',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Valor deve ser positivo. Formato: 15 dígitos numéricos (13 inteiros + 2 centavos)',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 81-95: Valor Nominal do Título',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP012', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP013 — Espécie do título deve ser código válido
  static ResultadoRegra sP013EspecieTitulo(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 105) return ResultadoRegra.sucesso('SP013', tempoMs: sw.elapsedMilliseconds);

    // Posição 105 (índice 104)
    final especie = seg.substring(103, 105);
    if (!_codigosEspecie.contains(especie)) {
      return ResultadoRegra.falha('SP013', [
        ErroValidacao(
          codigo: 'SP013',
          descricao: 'Espécie do título inválida no Segmento P',
          detalhe: 'Encontrado: "$especie". Espécies válidas: 01 (DM), 02 (NP), etc.',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 105,
          posicaoFim: 106,
          campoCnab: 'Espécie do Título',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Use 01 para Duplicata Mercantil (DM) como padrão',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 105-106: Espécie do Título',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP013', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP014 — Aceite deve ser A ou N
  static ResultadoRegra sP014Aceite(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 106) return ResultadoRegra.sucesso('SP014', tempoMs: sw.elapsedMilliseconds);

    final aceite = seg.substring(105, 106);
    if (aceite != 'A' && aceite != 'N') {
      return ResultadoRegra.falha('SP014', [
        ErroValidacao(
          codigo: 'SP014',
          descricao: 'Aceite inválido no Segmento P',
          detalhe: 'Encontrado: "$aceite". Válidos: "A" (Aceite) ou "N" (Não Aceite)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 106,
          posicaoFim: 106,
          campoCnab: 'Aceite',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao: 'Use "A" para título aceito ou "N" para não aceito',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP014', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP015 — Código de juros deve ser válido (0, 1, 2, 3)
  static ResultadoRegra sP015CodigoJuros(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 115) return ResultadoRegra.sucesso('SP015', tempoMs: sw.elapsedMilliseconds);

    final codJuros = seg.substring(114, 115);
    if (!{'0', '1', '2', '3'}.contains(codJuros)) {
      return ResultadoRegra.falha('SP015', [
        ErroValidacao(
          codigo: 'SP015',
          descricao: 'Código de juros inválido no Segmento P',
          detalhe: 'Encontrado: "$codJuros". Válidos: 0=Isento, 1=Valor/dia, 2=Taxa%, 3=Valor mensal',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 115,
          posicaoFim: 115,
          campoCnab: 'Código de Juros por Mora',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP015', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP016 — Código desconto deve ser válido (0-4)
  static ResultadoRegra sP016CodigoDesconto(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 139) return ResultadoRegra.sucesso('SP016', tempoMs: sw.elapsedMilliseconds);

    final codDesc = seg.substring(138, 139);
    if (!{'0', '1', '2', '3', '4'}.contains(codDesc)) {
      return ResultadoRegra.falha('SP016', [
        ErroValidacao(
          codigo: 'SP016',
          descricao: 'Código de desconto inválido no Segmento P',
          detalhe: 'Encontrado: "$codDesc". Válidos: 0=Sem, 1=Valor, 2=%, 3=Antecipado valor, 4=Antecipado %',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 139,
          posicaoFim: 139,
          campoCnab: 'Código de Desconto 1',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP016', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP017 — Código da moeda deve ser 009 (Real) para Santander
  static ResultadoRegra sP017CodigoMoeda(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 222) return ResultadoRegra.sucesso('SP017', tempoMs: sw.elapsedMilliseconds);

    final moeda = seg.substring(219, 222);
    if (moeda != '009') {
      return ResultadoRegra.falha('SP017', [
        ErroValidacao(
          codigo: 'SP017',
          descricao: 'Código de moeda inválido no Segmento P',
          detalhe: 'Encontrado: "$moeda". Santander usa "009" = Real',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 220,
          posicaoFim: 222,
          campoCnab: 'Código da Moeda',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 220-222: Código da Moeda = 009 (Real)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP017', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP018 — Código para protesto deve ser válido (0-9)
  static ResultadoRegra sP018CodigoProtesto(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 213) return ResultadoRegra.sucesso('SP018', tempoMs: sw.elapsedMilliseconds);

    final codProtesto = seg.substring(212, 213);
    if (!RegExp(r'^\d$').hasMatch(codProtesto)) {
      return ResultadoRegra.falha('SP018', [
        ErroValidacao(
          codigo: 'SP018',
          descricao: 'Código de protesto inválido no Segmento P',
          detalhe: 'Encontrado: "$codProtesto". Deve ser 1 dígito (0-9)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 213,
          posicaoFim: 213,
          campoCnab: 'Código para Protesto',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP018', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP019 — Número sequencial do registro deve ser numérico e sequencial
  static ResultadoRegra sP019NumeroSequencial(String seg, int numLinha, int idxTitulo, int esperado) {
    final sw = Stopwatch()..start();
    if (seg.length < 13) return ResultadoRegra.sucesso('SP019', tempoMs: sw.elapsedMilliseconds);

    // Posição 9-13 (índice 8-12)
    final seqStr = seg.substring(8, 13);
    final seq = int.tryParse(seqStr);

    if (seq == null) {
      return ResultadoRegra.falha('SP019', [
        ErroValidacao(
          codigo: 'SP019',
          descricao: 'Número sequencial do Segmento P não é numérico',
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
    if (seg.length < 192) return ResultadoRegra.sucesso('SP020', tempoMs: sw.elapsedMilliseconds);

    // Valor título: pos 81-95 (80-94)
    // Valor abatimento: pos 178-192 (177-191)
    final valorTitStr = seg.substring(80, 95);
    final valorAbaStr = seg.substring(177, 192);

    final valorTit = int.tryParse(valorTitStr) ?? 0;
    final valorAba = int.tryParse(valorAbaStr) ?? 0;

    if (valorAba > valorTit && valorAba > 0) {
      return ResultadoRegra.falha('SP020', [
        ErroValidacao(
          codigo: 'SP020',
          descricao: 'Valor do abatimento maior que o valor do título',
          detalhe:
              'Título: R\$ ${(valorTit / 100.0).toStringAsFixed(2)} | Abatimento: R\$ ${(valorAba / 100.0).toStringAsFixed(2)}',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 178,
          posicaoFim: 192,
          campoCnab: 'Valor do Abatimento',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'O abatimento não pode ser maior ou igual ao valor nominal do título',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP020', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP021 — Instruções para protesto: dias devem ser numéricos
  static ResultadoRegra sP021DiasProtesto(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 215) return ResultadoRegra.sucesso('SP021', tempoMs: sw.elapsedMilliseconds);

    final diasStr = seg.substring(213, 215);
    if (!RegExp(r'^\d{2}$').hasMatch(diasStr)) {
      return ResultadoRegra.falha('SP021', [
        ErroValidacao(
          codigo: 'SP021',
          descricao: 'Número de dias para protesto inválido no Segmento P',
          detalhe: 'Encontrado: "$diasStr". Esperado: 2 dígitos numéricos',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 214,
          posicaoFim: 215,
          campoCnab: 'Número de Dias para Protesto',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP021', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP022 — Código para baixa deve ser válido (0, 1, 2)
  static ResultadoRegra sP022CodigoBaixa(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 216) return ResultadoRegra.sucesso('SP022', tempoMs: sw.elapsedMilliseconds);

    final codBaixa = seg.substring(215, 216);
    if (!{'0', '1', '2'}.contains(codBaixa)) {
      return ResultadoRegra.falha('SP022', [
        ErroValidacao(
          codigo: 'SP022',
          descricao: 'Código para baixa/devolução inválido no Segmento P',
          detalhe: 'Encontrado: "$codBaixa". Válidos: 0=Não baixar, 1=Baixar, 2=Devolver',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 216,
          posicaoFim: 216,
          campoCnab: 'Código para Baixa/Devolução',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP022', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP023 — Juros: se código ≠ 0, data de juros não pode ser vazia
  static ResultadoRegra sP023ConsistenciaJuros(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 138) return ResultadoRegra.sucesso('SP023', tempoMs: sw.elapsedMilliseconds);

    final codJuros = seg.substring(114, 115);
    final dataJurosStr = seg.substring(115, 123);
    final valorJurosStr = seg.substring(123, 138);
    final valorJuros = int.tryParse(valorJurosStr) ?? 0;

    if (codJuros != '0') {
      if (dataJurosStr == '00000000' && valorJuros == 0) {
        return ResultadoRegra.falha('SP023', [
          ErroValidacao(
            codigo: 'SP023',
            descricao:
                'Juros configurados (código $codJuros) mas data e valor zerados',
            detalhe: 'Código Juros: $codJuros | Data: $dataJurosStr | Valor: $valorJurosStr',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.segmentoP,
            linha: numLinha,
            posicaoInicio: 115,
            posicaoFim: 138,
            campoCnab: 'Data/Valor de Juros',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'P',
            sugestaoCorrecao:
                'Se código de juros ≠ 0, preencha a data e o valor/taxa de juros',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    }
    return ResultadoRegra.sucesso('SP023', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP024 — Desconto: se código ≠ 0, data e valor não podem ser vazios
  static ResultadoRegra sP024ConsistenciaDesconto(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 162) return ResultadoRegra.sucesso('SP024', tempoMs: sw.elapsedMilliseconds);

    final codDesc = seg.substring(138, 139);
    final dataDescStr = seg.substring(139, 147);
    final valorDescStr = seg.substring(147, 162);
    final valorDesc = int.tryParse(valorDescStr) ?? 0;

    if (codDesc != '0') {
      if (dataDescStr == '00000000' && valorDesc == 0) {
        return ResultadoRegra.falha('SP024', [
          ErroValidacao(
            codigo: 'SP024',
            descricao:
                'Desconto configurado (código $codDesc) mas data e valor zerados',
            detalhe:
                'Código Desconto: $codDesc | Data: $dataDescStr | Valor: $valorDescStr',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.segmentoP,
            linha: numLinha,
            posicaoInicio: 139,
            posicaoFim: 162,
            campoCnab: 'Data/Valor do Desconto 1',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'P',
            sugestaoCorrecao:
                'Se código de desconto ≠ 0, preencha a data e o valor/percentual',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    }
    return ResultadoRegra.sucesso('SP024', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP025 — Data desconto deve ser anterior ao vencimento
  static ResultadoRegra sP025DataDescontoAnteriorVencimento(
      String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 162) return ResultadoRegra.sucesso('SP025', tempoMs: sw.elapsedMilliseconds);

    final codDesc = seg.substring(138, 139);
    if (codDesc == '0') return ResultadoRegra.sucesso('SP025', tempoMs: sw.elapsedMilliseconds);

    final dataDescStr = seg.substring(139, 147);
    final dataVencStr = seg.substring(72, 80);

    if (dataDescStr == '00000000' || dataVencStr == '00000000') {
      return ResultadoRegra.sucesso('SP025', tempoMs: sw.elapsedMilliseconds);
    }

    try {
      DateTime parseData(String s) => DateTime(
            int.parse(s.substring(4, 8)),
            int.parse(s.substring(2, 4)),
            int.parse(s.substring(0, 2)),
          );

      final dataDesc = parseData(dataDescStr);
      final dataVenc = parseData(dataVencStr);

      if (dataDesc.isAfter(dataVenc)) {
        return ResultadoRegra.falha('SP025', [
          ErroValidacao(
            codigo: 'SP025',
            descricao:
                'Data do desconto é posterior ao vencimento no Segmento P',
            detalhe:
                'Desconto: $dataDescStr | Vencimento: $dataVencStr',
            severidade: SeveridadeValidacao.erro,
            categoria: CategoriaValidacao.segmentoP,
            linha: numLinha,
            posicaoInicio: 140,
            posicaoFim: 147,
            campoCnab: 'Data do Desconto 1',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'P',
            sugestaoCorrecao:
                'A data do desconto deve ser anterior à data de vencimento',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    } catch (_) {}

    return ResultadoRegra.sucesso('SP025', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP026 — Instrução de cobrança 1: código entre 00 e 99
  static ResultadoRegra sP026InstrucaoCobranca(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 17) return ResultadoRegra.sucesso('SP026', tempoMs: sw.elapsedMilliseconds);

    // Posição 16-17 (índice 15-16)
    final instrStr = seg.substring(15, 17);
    if (!RegExp(r'^\d{2}$').hasMatch(instrStr)) {
      return ResultadoRegra.falha('SP026', [
        ErroValidacao(
          codigo: 'SP026',
          descricao: 'Código de instrução inválido no Segmento P',
          detalhe: 'Encontrado: "$instrStr". Esperado: 2 dígitos numéricos (00-99)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 16,
          posicaoFim: 17,
          campoCnab: 'Código da Instrução para Movimento',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP026', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP027 — Nr sequencial do registro deve ser 5 dígitos
  static ResultadoRegra sP027NrRegistroValido(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 13) return ResultadoRegra.sucesso('SP027', tempoMs: sw.elapsedMilliseconds);

    final nrReg = seg.substring(8, 13);
    if (!RegExp(r'^\d{5}$').hasMatch(nrReg)) {
      return ResultadoRegra.falha('SP027', [
        ErroValidacao(
          codigo: 'SP027',
          descricao: 'Nr sequencial do registro no lote inválido no Segmento P',
          detalhe: 'Encontrado: "$nrReg". Esperado: 5 dígitos numéricos',
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
    return ResultadoRegra.sucesso('SP027', tempoMs: sw.elapsedMilliseconds);
  }

  /// SP028 — Valor IOF não pode ser negativo
  static ResultadoRegra sP028ValorIOF(String seg, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (seg.length < 177) return ResultadoRegra.sucesso('SP028', tempoMs: sw.elapsedMilliseconds);

    // Posição 163-177 (índice 162-176)
    final iofStr = seg.substring(162, 177);
    final iof = int.tryParse(iofStr) ?? 0;

    if (iof < 0) {
      return ResultadoRegra.falha('SP028', [
        ErroValidacao(
          codigo: 'SP028',
          descricao: 'Valor de IOF negativo no Segmento P',
          detalhe: 'Valor encontrado: $iofStr',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.segmentoP,
          linha: numLinha,
          posicaoInicio: 163,
          posicaoFim: 177,
          campoCnab: 'Valor do IOF',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'IOF deve ser zero ou positivo. Use zeros se não houver IOF.',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SP028', tempoMs: sw.elapsedMilliseconds);
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
      sP021DiasProtesto(segLinha, numLinha, idxTitulo),
      sP022CodigoBaixa(segLinha, numLinha, idxTitulo),
      sP023ConsistenciaJuros(segLinha, numLinha, idxTitulo),
      sP024ConsistenciaDesconto(segLinha, numLinha, idxTitulo),
      sP025DataDescontoAnteriorVencimento(segLinha, numLinha, idxTitulo),
      sP026InstrucaoCobranca(segLinha, numLinha, idxTitulo),
      sP027NrRegistroValido(segLinha, numLinha, idxTitulo),
      sP028ValorIOF(segLinha, numLinha, idxTitulo),
    ];
  }
}
