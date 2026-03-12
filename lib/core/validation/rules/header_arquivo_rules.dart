// core/validation/rules/header_arquivo_rules.dart
// Regras de validação do Header de Arquivo CNAB 240
// FEBRABAN CNAB 240 v10.7 — Registro Header de Arquivo (Tipo 0)

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraHeaderArquivo {
  // ── Posições FEBRABAN do Header de Arquivo ──────────────────────────────
  // Pos  1- 3: Código do Banco (033 = Santander)
  // Pos  4- 7: Lote de Serviço (0000 para Header)
  // Pos     8: Tipo de Registro (0)
  // Pos  9-17: CNPJ da empresa (9 dígitos do CNPJ sem separadores — em alguns layouts)
  // Pos 18-21: Código do Convênio (7 chars)
  // Pos  1- 3: Código Banco
  // Pos  4- 7: Lote 0000
  // Pos     8: Tipo 0
  // Pos  9-17: Uso FEBRABAN (brancos)
  // Pos 18-21: Tipo de Inscrição (01=CPF, 02=CNPJ)
  // Pos 22-35: CNPJ/CPF da empresa (14 dígitos)
  // Pos 36-55: Código do Convênio (20 chars)
  // Pos 56-58: Agência (sem dígito) — primeiros 4 são número
  // Pos 73-88: Nome da empresa (30 chars no padrão)
  // Pos 89-98: Nome do banco (10 chars)

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
          descricao: 'Código do banco inválido',
          detalhe: 'Encontrado: "$codigoBanco". Esperado: "033" (Santander)',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 1,
          posicaoFim: 3,
          campoCnab: 'Código do Banco',
          sugestaoCorrecao: 'O código do banco Santander é 033',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 1-3: Código do Banco = 033',
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
          sugestaoCorrecao:
              'Header de Arquivo deve ter lote preenchido com zeros (0000)',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 4-7: Lote = 0000 para Header de Arquivo',
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
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 8: Tipo de Registro = 0',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA003', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA004 — Tipo de inscrição da empresa (01=CPF, 02=CNPJ)
  static ResultadoRegra hA004TipoInscricao(String headerLinha) {
    final sw = Stopwatch()..start();
    // Posição 18-19 (índice 17-18)
    if (headerLinha.length < 19) {
      return ResultadoRegra.sucesso('HA004', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoInsc = headerLinha.substring(17, 19);
    if (tipoInsc != '01' && tipoInsc != '02') {
      return ResultadoRegra.falha('HA004', [
        ErroValidacao(
          codigo: 'HA004',
          descricao: 'Tipo de inscrição inválido no Header de Arquivo',
          detalhe: 'Encontrado: "$tipoInsc". Válidos: "01" (CPF) ou "02" (CNPJ)',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 18,
          posicaoFim: 19,
          campoCnab: 'Tipo de Inscrição da Empresa',
          sugestaoCorrecao: 'Use 01 para CPF ou 02 para CNPJ',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 18-19: Tipo Inscrição Empresa',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA004', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA005 — CNPJ/CPF da empresa deve ter 14 dígitos numéricos
  static ResultadoRegra hA005CnpjEmpresa(String headerLinha) {
    final sw = Stopwatch()..start();
    // Posição 20-33 (índice 19-32) = 14 chars
    if (headerLinha.length < 34) {
      return ResultadoRegra.sucesso('HA005', tempoMs: sw.elapsedMilliseconds);
    }

    final cnpj = headerLinha.substring(19, 33);
    final apenasDigitos = RegExp(r'^\d{14}$').hasMatch(cnpj);
    if (!apenasDigitos) {
      return ResultadoRegra.falha('HA005', [
        ErroValidacao(
          codigo: 'HA005',
          descricao: 'CNPJ/CPF da empresa no Header de Arquivo inválido',
          detalhe: 'Encontrado: "$cnpj". Esperado: 14 dígitos numéricos',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 20,
          posicaoFim: 33,
          campoCnab: 'Número de Inscrição da Empresa',
          sugestaoCorrecao:
              'CNPJ deve ter 14 dígitos numéricos sem formatação (ex: 12345678000195)',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 20-33: Nr de Inscrição da Empresa',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA005', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA006 — Nome da empresa não pode estar vazio
  static ResultadoRegra hA006NomeEmpresa(String headerLinha) {
    final sw = Stopwatch()..start();
    // Posição 73-102 (índice 72-101) = 30 chars
    if (headerLinha.length < 102) {
      return ResultadoRegra.sucesso('HA006', tempoMs: sw.elapsedMilliseconds);
    }

    final nomeEmpresa = headerLinha.substring(72, 102).trim();
    if (nomeEmpresa.isEmpty) {
      return ResultadoRegra.falha('HA006', [
        const ErroValidacao(
          codigo: 'HA006',
          descricao: 'Nome da empresa em branco no Header de Arquivo',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 73,
          posicaoFim: 102,
          campoCnab: 'Nome da Empresa',
          sugestaoCorrecao: 'Preencha a razão social da empresa cedente',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 73-102: Nome da Empresa',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA006', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA007 — Agência deve ter 4 dígitos numéricos
  static ResultadoRegra hA007Agencia(String headerLinha) {
    final sw = Stopwatch()..start();
    // Posição 53-56 (índice 52-55) no layout Santander
    if (headerLinha.length < 57) {
      return ResultadoRegra.sucesso('HA007', tempoMs: sw.elapsedMilliseconds);
    }

    final agencia = headerLinha.substring(52, 56);
    if (!RegExp(r'^\d{4}$').hasMatch(agencia)) {
      return ResultadoRegra.falha('HA007', [
        ErroValidacao(
          codigo: 'HA007',
          descricao: 'Agência inválida no Header de Arquivo',
          detalhe: 'Encontrado: "$agencia". Esperado: 4 dígitos numéricos',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 53,
          posicaoFim: 56,
          campoCnab: 'Agência Mantenedora',
          sugestaoCorrecao: 'Agência Santander deve ter 4 dígitos numéricos',
          referenciaFebraban:
              'Santander CNAB 240 — Posição 53-56: Agência sem dígito',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA007', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA008 — Conta deve ter 8 dígitos numéricos
  static ResultadoRegra hA008Conta(String headerLinha) {
    final sw = Stopwatch()..start();
    // Posição 58-65 (índice 57-64)
    if (headerLinha.length < 66) {
      return ResultadoRegra.sucesso('HA008', tempoMs: sw.elapsedMilliseconds);
    }

    final conta = headerLinha.substring(57, 65);
    if (!RegExp(r'^\d{8}$').hasMatch(conta)) {
      return ResultadoRegra.falha('HA008', [
        ErroValidacao(
          codigo: 'HA008',
          descricao: 'Número de conta inválido no Header de Arquivo',
          detalhe: 'Encontrado: "$conta". Esperado: 8 dígitos numéricos',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 58,
          posicaoFim: 65,
          campoCnab: 'Número da Conta Corrente',
          sugestaoCorrecao: 'Conta Santander deve ter 8 dígitos numéricos',
          referenciaFebraban:
              'Santander CNAB 240 — Posição 58-65: Conta sem dígito verificador',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA008', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA009 — Código do convênio deve ter 7 dígitos
  static ResultadoRegra hA009Convenio(String headerLinha) {
    final sw = Stopwatch()..start();
    // Posição 36-42 (índice 35-41) = convênio no layout Santander
    if (headerLinha.length < 55) {
      return ResultadoRegra.sucesso('HA009', tempoMs: sw.elapsedMilliseconds);
    }

    // Convênio em posições 36-55 (20 chars), mas Santander usa os 7 primeiros
    final convenio = headerLinha.substring(35, 42).trim();
    if (!RegExp(r'^\d{7}$').hasMatch(convenio)) {
      return ResultadoRegra.falha('HA009', [
        ErroValidacao(
          codigo: 'HA009',
          descricao: 'Código do convênio inválido no Header de Arquivo',
          detalhe: 'Encontrado: "$convenio". Esperado: 7 dígitos numéricos',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 36,
          posicaoFim: 42,
          campoCnab: 'Código do Convênio',
          sugestaoCorrecao:
              'Convênio Santander deve ter 7 dígitos numéricos',
          referenciaFebraban:
              'Santander CNAB 240 — Posição 36-42: Código do Convênio (7 dígitos)',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA009', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA010 — Data de geração deve ser válida (DDMMAAAA)
  static ResultadoRegra hA010DataGeracao(String headerLinha) {
    final sw = Stopwatch()..start();
    // Posição 144-151 (índice 143-150)
    if (headerLinha.length < 151) {
      return ResultadoRegra.sucesso('HA010', tempoMs: sw.elapsedMilliseconds);
    }

    final dataStr = headerLinha.substring(143, 151);
    if (!RegExp(r'^\d{8}$').hasMatch(dataStr)) {
      return ResultadoRegra.falha('HA010', [
        ErroValidacao(
          codigo: 'HA010',
          descricao: 'Data de geração inválida no Header de Arquivo',
          detalhe: 'Encontrado: "$dataStr". Esperado: DDMMAAAA (8 dígitos)',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 144,
          posicaoFim: 151,
          campoCnab: 'Data de Geração do Arquivo',
          sugestaoCorrecao: 'Use formato DDMMAAAA (ex: 15012025)',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 144-151: Data de Geração',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    // Validar data real
    try {
      final dia = int.parse(dataStr.substring(0, 2));
      final mes = int.parse(dataStr.substring(2, 4));
      final ano = int.parse(dataStr.substring(4, 8));
      final data = DateTime(ano, mes, dia);
      if (data.day != dia || data.month != mes || data.year != ano) {
        return ResultadoRegra.falha('HA010', [
          ErroValidacao(
            codigo: 'HA010',
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
    } catch (_) {
      // Ignorar erros de parse aqui
    }

    return ResultadoRegra.sucesso('HA010', tempoMs: sw.elapsedMilliseconds);
  }

  /// HA011 — Número sequencial do arquivo deve ser de 1 a 999999
  static ResultadoRegra hA011NumeroSequencial(String headerLinha) {
    final sw = Stopwatch()..start();
    // Posição 158-163 (índice 157-162)
    if (headerLinha.length < 163) {
      return ResultadoRegra.sucesso('HA011', tempoMs: sw.elapsedMilliseconds);
    }

    final seqStr = headerLinha.substring(157, 163);
    final seq = int.tryParse(seqStr);
    if (seq == null || seq < 1 || seq > 999999) {
      return ResultadoRegra.falha('HA011', [
        ErroValidacao(
          codigo: 'HA011',
          descricao: 'Número sequencial do arquivo inválido',
          detalhe: 'Encontrado: "$seqStr". Deve ser de 000001 a 999999',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.headerArquivo,
          linha: 1,
          posicaoInicio: 158,
          posicaoFim: 163,
          campoCnab: 'Número Sequencial do Arquivo',
          sugestaoCorrecao: 'Use número sequencial entre 000001 e 999999',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 158-163: Nr Sequencial do Arquivo',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('HA011', tempoMs: sw.elapsedMilliseconds);
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
      hA007Agencia(headerLinha),
      hA008Conta(headerLinha),
      hA009Convenio(headerLinha),
      hA010DataGeracao(headerLinha),
      hA011NumeroSequencial(headerLinha),
    ];
  }
}
