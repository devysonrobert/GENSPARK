// core/validation/rules/header_arquivo_rules.dart
// Regras de validação do Header de Arquivo CNAB 240
// Layout H7815 V8.5 Fev/2026 — Santander Cobrança CNAB 240 Posições

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraHeaderArquivo {
  // ── Posições H7815 V8.5 do Header de Arquivo ────────────────────────────
  // Pos  1-  3: Código do Banco (033 = Santander)
  // Pos  4-  7: Lote de Serviço (0000 para Header)
  // Pos     8: Tipo de Registro (0)
  // Pos  9- 16: Reservado uso Banco (8 brancos)
  // Pos    17: Tipo de Inscrição (1=CPF, 2=CNPJ) — 1 char!
  // Pos 18- 32: Número de Inscrição (CNPJ/CPF) — 15 num
  // Pos 33- 47: Código de Transmissão — 15 alfa
  // Pos 48- 72: Reservado uso Banco (25 brancos)
  // Pos 73-102: Nome da Empresa — 30 alfa
  // Pos 103-132: Nome do Banco (BANCO SANTANDER) — 30 alfa
  // Pos 133-142: Reservado uso Banco (10 brancos)
  // Pos    143: Código Remessa (1=Remessa) — 1 num
  // Pos 144-151: Data de Geração (DDMMAAAA) — 8 num
  // Pos 152-157: Reservado uso Banco (6 brancos)
  // Pos 158-163: Nr Sequencial do Arquivo — 6 num
  // Pos 164-166: Nr da Versão do Layout (040) — 3 num
  // Pos 167-240: Reservado uso Banco (74 brancos)

  /// HA001 — Código do banco deve ser 033 (Santander)
  static ResultadoRegra hA001CodigoBanco(String headerLinha) {
    final sw = Stopwatch()..start();
    if (headerLinha.length < 3) {
      return ResultadoRegra.sucesso('HA001', tempoMs: sw.elapsedMilliseconds);
    }

    final codigoBanco = headerLinha.substring(0, 3);
    if (codigoBanco != '033') {
      return ResultadoRegra.falha('HA001', [
        ErroValidacao(
          codigo: 'HA001',
          descricao: 'Código do banco inválido no Header de Arquivo',
          detalhe: 'Encontrado: "$codigoBanco". Esperado: "033" (Santander)',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 1,
          posicaoFim: 3,
          campoCnab: 'Código do Banco na Compensação',
          sugestaoCorrecao: 'O código do banco Santander é 033',
          referenciaFebraban: 'H7815 V8.5 — Posição 1-3: Código do Banco = 033',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA001', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA002 — Lote do header de arquivo deve ser 0000
  static ResultadoRegra hA002LoteHeaderArquivo(String headerLinha) {
    final sw = Stopwatch()..start();
    if (headerLinha.length < 7) {
      return ResultadoRegra.sucesso('HA002', tempoMs: sw.elapsedMilliseconds);
    }

    final lote = headerLinha.substring(3, 7);
    if (lote != '0000') {
      return ResultadoRegra.falha('HA002', [
        ErroValidacao(
          codigo: 'HA002',
          descricao: 'Número de lote do Header de Arquivo deve ser 0000',
          detalhe: 'Encontrado: "$lote"',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 4,
          posicaoFim: 7,
          campoCnab: 'Lote de Serviço',
          sugestaoCorrecao: 'Header de Arquivo deve ter lote preenchido com zeros (0000)',
          referenciaFebraban: 'H7815 V8.5 — Posição 4-7: Lote = 0000 para Header de Arquivo',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA002', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA003 — Tipo de registro deve ser 0 (Header de Arquivo)
  static ResultadoRegra hA003TipoRegistro(String headerLinha) {
    final sw = Stopwatch()..start();
    if (headerLinha.length < 8) {
      return ResultadoRegra.sucesso('HA003', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoReg = headerLinha.substring(7, 8);
    if (tipoReg != '0') {
      return ResultadoRegra.falha('HA003', [
        ErroValidacao(
          codigo: 'HA003',
          descricao: 'Tipo de registro do Header de Arquivo inválido',
          detalhe: 'Encontrado: "$tipoReg". Esperado: "0"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 8,
          posicaoFim: 8,
          campoCnab: 'Tipo de Registro',
          sugestaoCorrecao: 'Header de Arquivo deve ter tipo de registro = 0',
          referenciaFebraban: 'H7815 V8.5 — Posição 8: Tipo de Registro = 0',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA003', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA004 — Tipo de inscrição da empresa: posição 17 (1 char: 1=CPF, 2=CNPJ)
  /// H7815: 1 char, não 2! (diferente do FEBRABAN padrão que usa 2 chars)
  static ResultadoRegra hA004TipoInscricao(String headerLinha) {
    final sw = Stopwatch()..start();
    // H7815: Posição 17 (índice 16) — 1 char
    if (headerLinha.length < 17) {
      return ResultadoRegra.sucesso('HA004', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoInsc = headerLinha.substring(16, 17);
    if (tipoInsc != '1' && tipoInsc != '2') {
      return ResultadoRegra.falha('HA004', [
        ErroValidacao(
          codigo: 'HA004',
          descricao: 'Tipo de inscrição inválido no Header de Arquivo (posição 17)',
          detalhe: 'Encontrado: "$tipoInsc". H7815: "1" (CPF) ou "2" (CNPJ)',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 17,
          posicaoFim: 17,
          campoCnab: 'Tipo de Inscrição da Empresa',
          sugestaoCorrecao: 'H7815 usa 1 char: 1=CPF, 2=CNPJ',
          referenciaFebraban: 'H7815 V8.5 — Posição 17: Tipo de Inscrição (1 char)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA004', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA005 — CNPJ/CPF da empresa: posição 18-32 (15 num) — H7815
  static ResultadoRegra hA005CnpjEmpresa(String headerLinha) {
    final sw = Stopwatch()..start();
    // H7815: Posição 18-32 (índice 17-31) = 15 chars (zeros + CNPJ 14 dígitos)
    if (headerLinha.length < 32) {
      return ResultadoRegra.sucesso('HA005', tempoMs: sw.elapsedMilliseconds);
    }

    final inscricao = headerLinha.substring(17, 32);
    if (!RegExp(r'^\d{15}$').hasMatch(inscricao)) {
      return ResultadoRegra.falha('HA005', [
        ErroValidacao(
          codigo: 'HA005',
          descricao: 'Número de inscrição da empresa inválido no Header de Arquivo (posição 18-32)',
          detalhe: 'Encontrado: "$inscricao". H7815: 15 dígitos numéricos (zeros + CNPJ)',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 18,
          posicaoFim: 32,
          campoCnab: 'Número de Inscrição da Empresa',
          sugestaoCorrecao: 'CNPJ 14 dígitos com zero à esquerda: 012345678000195',
          referenciaFebraban: 'H7815 V8.5 — Posição 18-32: Nr de Inscrição (15 posições)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA005', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA006 — Nome da empresa: posição 73-102 (30 alfa) — H7815
  static ResultadoRegra hA006NomeEmpresa(String headerLinha) {
    final sw = Stopwatch()..start();
    if (headerLinha.length < 102) {
      return ResultadoRegra.sucesso('HA006', tempoMs: sw.elapsedMilliseconds);
    }

    final nomeEmpresa = headerLinha.substring(72, 102).trim();
    if (nomeEmpresa.isEmpty) {
      return ResultadoRegra.falha('HA006', [
        const ErroValidacao(
          codigo: 'HA006',
          descricao: 'Nome da empresa em branco no Header de Arquivo (posição 73-102)',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 73,
          posicaoFim: 102,
          campoCnab: 'Nome da Empresa',
          sugestaoCorrecao: 'Preencha a razão social da empresa (até 30 chars)',
          referenciaFebraban: 'H7815 V8.5 — Posição 73-102: Nome da Empresa',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA006', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA007 — Código de Transmissão: posição 33-47 (15 alfa) — H7815 Nota 3
  static ResultadoRegra hA007CodigoTransmissao(String headerLinha) {
    final sw = Stopwatch()..start();
    // H7815: posição 33-47 = Código de Transmissão (15 chars)
    if (headerLinha.length < 47) {
      return ResultadoRegra.sucesso('HA007', tempoMs: sw.elapsedMilliseconds);
    }

    final codTrans = headerLinha.substring(32, 47).trim();
    if (codTrans.isEmpty) {
      return ResultadoRegra.falha('HA007', [
        ErroValidacao(
          codigo: 'HA007',
          descricao: 'Código de Transmissão em branco no Header de Arquivo (posição 33-47)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 33,
          posicaoFim: 47,
          campoCnab: 'Código de Transmissão',
          sugestaoCorrecao: 'H7815 Nota 3: Código cedido pelo Santander na contratação do serviço',
          referenciaFebraban: 'H7815 V8.5 Nota 3 — Código de Transmissão (15 posições)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA007', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA008 — Data de geração deve ser válida: posição 144-151 (DDMMAAAA) — H7815
  static ResultadoRegra hA008DataGeracao(String headerLinha) {
    final sw = Stopwatch()..start();
    if (headerLinha.length < 151) {
      return ResultadoRegra.sucesso('HA008', tempoMs: sw.elapsedMilliseconds);
    }

    final dataStr = headerLinha.substring(143, 151);
    if (!RegExp(r'^\d{8}$').hasMatch(dataStr)) {
      return ResultadoRegra.falha('HA008', [
        ErroValidacao(
          codigo: 'HA008',
          descricao: 'Data de geração inválida no Header de Arquivo (posição 144-151)',
          detalhe: 'Encontrado: "$dataStr". Esperado: DDMMAAAA (8 dígitos)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 144,
          posicaoFim: 151,
          campoCnab: 'Data de Geração do Arquivo',
          sugestaoCorrecao: 'Use formato DDMMAAAA (ex: 15042026)',
          referenciaFebraban: 'H7815 V8.5 — Posição 144-151: Data de Geração',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    try {
      final dia = int.parse(dataStr.substring(0, 2));
      final mes = int.parse(dataStr.substring(2, 4));
      final ano = int.parse(dataStr.substring(4, 8));
      final data = DateTime(ano, mes, dia);
      if (data.day != dia || data.month != mes || data.year != ano) {
        return ResultadoRegra.falha('HA008', [
          ErroValidacao(
            codigo: 'HA008',
            descricao: 'Data de geração inválida (data inexistente)',
            detalhe: 'Data: $dataStr',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.headerArquivo,
            linha: 1,
            posicaoInicio: 144,
            posicaoFim: 151,
            campoCnab: 'Data de Geração do Arquivo',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    } catch (_) {}

    return ResultadoRegra.sucesso('HA008', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA009 — Número sequencial do arquivo: posição 158-163 (6 num) — H7815
  static ResultadoRegra hA009NumeroSequencial(String headerLinha) {
    final sw = Stopwatch()..start();
    if (headerLinha.length < 163) {
      return ResultadoRegra.sucesso('HA009', tempoMs: sw.elapsedMilliseconds);
    }

    final seqStr = headerLinha.substring(157, 163);
    final seq = int.tryParse(seqStr);
    if (seq == null || seq < 1 || seq > 999999) {
      return ResultadoRegra.falha('HA009', [
        ErroValidacao(
          codigo: 'HA009',
          descricao: 'Número sequencial do arquivo inválido (posição 158-163)',
          detalhe: 'Encontrado: "$seqStr". H7815 Nota 4: Deve ser de 000001 a 999999',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 158,
          posicaoFim: 163,
          campoCnab: 'Nr Sequencial do Arquivo',
          sugestaoCorrecao: 'Use número sequencial entre 000001 e 999999',
          referenciaFebraban: 'H7815 V8.5 Nota 4 — Nr Sequencial do Arquivo',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA009', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA010 — Versão do layout: posição 164-166 (3 num: 040) — H7815 V8.5
  static ResultadoRegra hA010VersaoLayout(String headerLinha) {
    final sw = Stopwatch()..start();
    if (headerLinha.length < 166) {
      return ResultadoRegra.sucesso('HA010', tempoMs: sw.elapsedMilliseconds);
    }

    final versao = headerLinha.substring(163, 166);
    // H7815 aceita versão 040 (padrão atual)
    if (!RegExp(r'^\d{3}$').hasMatch(versao)) {
      return ResultadoRegra.falha('HA010', [
        ErroValidacao(
          codigo: 'HA010',
          descricao: 'Versão do layout do arquivo inválida (posição 164-166)',
          detalhe: 'Encontrado: "$versao". H7815 V8.5: "040"',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 164,
          posicaoFim: 166,
          campoCnab: 'Nr da Versão do Layout do Arquivo',
          sugestaoCorrecao: 'H7815 V8.5: Use versão 040',
          referenciaFebraban: 'H7815 V8.5 — Posição 164-166: Versão do Layout = 040',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA010', tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras de Header de Arquivo
  static List<ResultadoRegra> validarTudo(String headerLinha) {
    return [
      hA001CodigoBanco(headerLinha),
      hA002LoteHeaderArquivo(headerLinha),
      hA003TipoRegistro(headerLinha),
      hA004TipoInscricao(headerLinha),
      hA005CnpjEmpresa(headerLinha),
      hA006NomeEmpresa(headerLinha),
      hA007CodigoTransmissao(headerLinha),
      hA008DataGeracao(headerLinha),
      hA009NumeroSequencial(headerLinha),
      hA010VersaoLayout(headerLinha),
    ];
  }
}
