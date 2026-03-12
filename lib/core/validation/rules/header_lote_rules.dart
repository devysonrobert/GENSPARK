// core/validation/rules/header_lote_rules.dart
// Regras de validação do Header de Lote CNAB 240
// FEBRABAN CNAB 240 v10.7 — Registro Header de Lote (Tipo 1)
// Santander: Cobrança Simples / Caucionada / Descontada

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraHeaderLote {
  // ── Posições FEBRABAN do Header de Lote ─────────────────────────────────
  // Pos  1- 3: Código do Banco (033)
  // Pos  4- 7: Lote de Serviço (número sequencial do lote)
  // Pos     8: Tipo de Registro (1)
  // Pos     9: Tipo de Operação (C=Crédito/R=Débito)
  // Pos 10-11: Tipo de Serviço (01=Cobrança)
  // Pos 12-13: Forma de Lançamento (01 a 45)
  // Pos 14-16: Versão do Layout de Lote (046 para Santander)
  // Pos 18-19: Tipo de Inscrição da Empresa
  // Pos 20-33: CNPJ/CPF da empresa
  // Pos 34-53: Código do Convênio
  // Pos 54-57: Agência
  // Pos 58-65: Conta
  // Pos 66:    Dígito da Conta
  // Pos 67:    Dígito AG/Conta
  // Pos 68-97: Nome da Empresa
  // Pos 98-107: Informações Adicionais

  /// HL001 — Código do banco deve ser 033
  static ResultadoRegra hL001CodigoBanco(String linhaNr, String lote, int numLinha) {
    final sw = Stopwatch()..start();
    if (lote.length < 3) {
      return ResultadoRegra.sucesso('HL001', tempoMs: sw.elapsedMilliseconds);
    }

    final codigoBanco = lote.substring(0, 3);
    if (codigoBanco != '033') {
      return ResultadoRegra.falha('HL001', [
        ErroValidacao(
          codigo: 'HL001',
          descricao: 'Código do banco no Header de Lote inválido',
          detalhe: 'Encontrado: "$codigoBanco". Esperado: "033"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.headerLote,
          linha: numLinha,
          posicaoInicio: 1,
          posicaoFim: 3,
          campoCnab: 'Código do Banco',
          sugestaoCorrecao: 'O código do banco Santander é 033',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 1-3: Código do Banco',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HL001', tempoMs: sw.elapsedMilliseconds);
  }

  /// HL002 — Número do lote deve ser numérico e > 0
  static ResultadoRegra hL002NumeroLote(String lote, int numLinha) {
    final sw = Stopwatch()..start();
    if (lote.length < 7) {
      return ResultadoRegra.sucesso('HL002', tempoMs: sw.elapsedMilliseconds);
    }

    final numLoteStr = lote.substring(3, 7);
    final numLoteInt = int.tryParse(numLoteStr);

    if (numLoteInt == null || numLoteInt < 1) {
      return ResultadoRegra.falha('HL002', [
        ErroValidacao(
          codigo: 'HL002',
          descricao: 'Número do lote inválido no Header de Lote',
          detalhe: 'Encontrado: "$numLoteStr". Deve ser ≥ 0001',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerLote,
          linha: numLinha,
          posicaoInicio: 4,
          posicaoFim: 7,
          campoCnab: 'Lote de Serviço',
          sugestaoCorrecao: 'Número de lote deve ser sequencial a partir de 0001',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 4-7: Lote de Serviço',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HL002', tempoMs: sw.elapsedMilliseconds);
  }

  /// HL003 — Tipo de registro deve ser 1 (Header de Lote)
  static ResultadoRegra hL003TipoRegistro(String lote, int numLinha) {
    final sw = Stopwatch()..start();
    if (lote.length < 8) {
      return ResultadoRegra.sucesso('HL003', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoReg = lote.substring(7, 8);
    if (tipoReg != '1') {
      return ResultadoRegra.falha('HL003', [
        ErroValidacao(
          codigo: 'HL003',
          descricao: 'Tipo de registro do Header de Lote inválido',
          detalhe: 'Encontrado: "$tipoReg". Esperado: "1"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.headerLote,
          linha: numLinha,
          posicaoInicio: 8,
          posicaoFim: 8,
          campoCnab: 'Tipo de Registro',
          sugestaoCorrecao: 'Header de Lote deve ter tipo de registro = 1',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 8: Tipo de Registro = 1',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HL003', tempoMs: sw.elapsedMilliseconds);
  }

  /// HL004 — Tipo de operação deve ser C (Lançamento a Crédito)
  static ResultadoRegra hL004TipoOperacao(String lote, int numLinha) {
    final sw = Stopwatch()..start();
    if (lote.length < 9) {
      return ResultadoRegra.sucesso('HL004', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoOper = lote.substring(8, 9);
    if (tipoOper != 'C' && tipoOper != 'R') {
      return ResultadoRegra.falha('HL004', [
        ErroValidacao(
          codigo: 'HL004',
          descricao: 'Tipo de operação inválido no Header de Lote',
          detalhe: 'Encontrado: "$tipoOper". Válidos: "C" (Crédito) ou "R" (Débito)',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerLote,
          linha: numLinha,
          posicaoInicio: 9,
          posicaoFim: 9,
          campoCnab: 'Tipo de Operação',
          sugestaoCorrecao: 'Para cobrança use "C" (Crédito)',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 9: Tipo de Operação',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HL004', tempoMs: sw.elapsedMilliseconds);
  }

  /// HL005 — Tipo de serviço deve ser 01 (Cobrança)
  static ResultadoRegra hL005TipoServico(String lote, int numLinha) {
    final sw = Stopwatch()..start();
    if (lote.length < 11) {
      return ResultadoRegra.sucesso('HL005', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoServ = lote.substring(9, 11);
    if (tipoServ != '01') {
      return ResultadoRegra.falha('HL005', [
        ErroValidacao(
          codigo: 'HL005',
          descricao: 'Tipo de serviço inválido no Header de Lote',
          detalhe: 'Encontrado: "$tipoServ". Esperado: "01" (Cobrança)',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerLote,
          linha: numLinha,
          posicaoInicio: 10,
          posicaoFim: 11,
          campoCnab: 'Tipo de Serviço',
          sugestaoCorrecao: 'Para arquivo de cobrança use tipo de serviço "01"',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 10-11: Tipo de Serviço = 01',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HL005', tempoMs: sw.elapsedMilliseconds);
  }

  /// HL006 — Forma de lançamento deve ser código válido (01-45)
  static ResultadoRegra hL006FormaLancamento(String lote, int numLinha) {
    final sw = Stopwatch()..start();
    if (lote.length < 13) {
      return ResultadoRegra.sucesso('HL006', tempoMs: sw.elapsedMilliseconds);
    }

    final formaStr = lote.substring(11, 13);
    final forma = int.tryParse(formaStr);

    if (forma == null || forma < 1 || forma > 45) {
      return ResultadoRegra.falha('HL006', [
        ErroValidacao(
          codigo: 'HL006',
          descricao: 'Forma de lançamento inválida no Header de Lote',
          detalhe: 'Encontrado: "$formaStr". Válido: 01 a 45',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerLote,
          linha: numLinha,
          posicaoInicio: 12,
          posicaoFim: 13,
          campoCnab: 'Forma de Lançamento',
          sugestaoCorrecao:
              'Forma de lançamento deve ser entre 01 e 45. Santander cobrança usa 01',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 12-13: Forma de Lançamento',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HL006', tempoMs: sw.elapsedMilliseconds);
  }

  /// HL007 — Versão do layout de lote deve ser 046 (Santander)
  static ResultadoRegra hL007VersaoLayout(String lote, int numLinha) {
    final sw = Stopwatch()..start();
    if (lote.length < 16) {
      return ResultadoRegra.sucesso('HL007', tempoMs: sw.elapsedMilliseconds);
    }

    final versao = lote.substring(13, 16);
    if (versao != '046' && versao != '040' && versao != '045') {
      return ResultadoRegra.falha('HL007', [
        ErroValidacao(
          codigo: 'HL007',
          descricao: 'Versão do layout de lote não reconhecida',
          detalhe:
              'Encontrado: "$versao". Esperado para Santander: "046"',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerLote,
          linha: numLinha,
          posicaoInicio: 14,
          posicaoFim: 16,
          campoCnab: 'Número da Versão do Layout do Lote',
          sugestaoCorrecao:
              'Santander utiliza versão 046 do layout de lote',
          referenciaFebraban:
              'Santander CNAB 240 — Posição 14-16: Versão Layout Lote = 046',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HL007', tempoMs: sw.elapsedMilliseconds);
  }

  /// HL008 — Nome da empresa no header de lote não pode estar vazio
  static ResultadoRegra hL008NomeEmpresa(String lote, int numLinha) {
    final sw = Stopwatch()..start();
    // Posição 68-97 (índice 67-96)
    if (lote.length < 97) {
      return ResultadoRegra.sucesso('HL008', tempoMs: sw.elapsedMilliseconds);
    }

    final nomeEmpresa = lote.substring(67, 97).trim();
    if (nomeEmpresa.isEmpty) {
      return ResultadoRegra.falha('HL008', [
        ErroValidacao(
          codigo: 'HL008',
          descricao: 'Nome da empresa em branco no Header de Lote',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerLote,
          linha: numLinha,
          posicaoInicio: 68,
          posicaoFim: 97,
          campoCnab: 'Nome da Empresa',
          sugestaoCorrecao: 'Preencha a razão social da empresa cedente',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 68-97: Nome da Empresa',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HL008', tempoMs: sw.elapsedMilliseconds);
  }

  /// HL009 — Número de retorno/remessa deve ser válido
  static ResultadoRegra hL009TipoArquivo(String lote, int numLinha) {
    final sw = Stopwatch()..start();
    // Posição 143 (índice 142) = tipo arquivo: 1=Remessa, 2=Retorno
    if (lote.length < 143) {
      return ResultadoRegra.sucesso('HL009', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoArq = lote.substring(142, 143);
    if (tipoArq != '1' && tipoArq != '2') {
      return ResultadoRegra.falha('HL009', [
        ErroValidacao(
          codigo: 'HL009',
          descricao: 'Tipo de arquivo inválido no Header de Lote',
          detalhe: 'Encontrado: "$tipoArq". Válidos: "1" (Remessa) ou "2" (Retorno)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerLote,
          linha: numLinha,
          posicaoInicio: 143,
          posicaoFim: 143,
          campoCnab: 'Indicativo de Forma de Pagamento',
          sugestaoCorrecao: 'Use "1" para arquivo remessa ou "2" para retorno',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 143: Indicativo de Remessa/Retorno',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HL009', tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras de Header de Lote para um lote específico
  static List<ResultadoRegra> validarTudo(String loteLinha, int numLinha) {
    return [
      hL001CodigoBanco('', loteLinha, numLinha),
      hL002NumeroLote(loteLinha, numLinha),
      hL003TipoRegistro(loteLinha, numLinha),
      hL004TipoOperacao(loteLinha, numLinha),
      hL005TipoServico(loteLinha, numLinha),
      hL006FormaLancamento(loteLinha, numLinha),
      hL007VersaoLayout(loteLinha, numLinha),
      hL008NomeEmpresa(loteLinha, numLinha),
      hL009TipoArquivo(loteLinha, numLinha),
    ];
  }
}
