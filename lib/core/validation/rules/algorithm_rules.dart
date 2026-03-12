// core/validation/rules/algorithm_rules.dart
// Regras de validação algorítmica CNAB 240
// Validação de DAC (Dígito de Auto-Conferência), CPF, CNPJ, Módulo 11

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraAlgoritmica {
  // ── Feriados bancários 2025 e 2026 ──────────────────────────────────────
  static const _feriadosBancarios = <String>{
    // 2025
    '01012025', // Confraternização Universal
    '03032025', // Carnaval (segunda)
    '04032025', // Carnaval (terça)
    '05032025', // Quarta de Cinzas (até meio-dia)
    '18042025', // Sexta-feira Santa
    '21042025', // Tiradentes
    '01052025', // Dia do Trabalho
    '19062025', // Corpus Christi
    '07092025', // Independência do Brasil
    '12102025', // Nossa Sra. Aparecida
    '02112025', // Finados
    '15112025', // Proclamação da República
    '20112025', // Dia Nacional de Zumbi
    '25122025', // Natal
    // 2026
    '01012026',
    '16022026', // Carnaval (segunda)
    '17022026', // Carnaval (terça)
    '03042026', // Sexta-feira Santa
    '21042026', // Tiradentes
    '01052026', // Dia do Trabalho
    '04062026', // Corpus Christi
    '07092026', // Independência
    '12102026', // Nossa Sra. Aparecida
    '02112026', // Finados
    '15112026', // Proclamação da República
    '20112026', // Dia Nacional de Zumbi
    '25122026', // Natal
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Algoritmos de cálculo
  // ─────────────────────────────────────────────────────────────────────────

  /// Calcula DAC Santander: módulo 11 com pesos 2-9 (direita para esquerda)
  /// Sobre concatenação: agência(4) + conta(8) + carteira(3) + nossoNumero(12)
  /// DAC = 0 se resto = 0 ou 1, caso contrário 11 - resto
  static int calcularDacSantander(
      String agencia, String conta, String carteira, String nossoNumero) {
    final concatenado =
        agencia.padLeft(4, '0') +
        conta.padLeft(8, '0') +
        carteira.padLeft(3, '0') +
        nossoNumero.padLeft(12, '0');

    int soma = 0;
    int peso = 2;

    for (int i = concatenado.length - 1; i >= 0; i--) {
      final digito = int.tryParse(concatenado[i]) ?? 0;
      soma += digito * peso;
      peso++;
      if (peso > 9) peso = 2;
    }

    final resto = soma % 11;
    if (resto == 0 || resto == 1) return 0;
    return 11 - resto;
  }

  /// Calcula dígito verificador de conta Santander (módulo 11, pesos 2-9)
  static int calcularDigitoContaSantander(String agencia, String conta) {
    final concatenado = agencia.padLeft(4, '0') + conta.padLeft(8, '0');
    int soma = 0;
    int peso = 2;

    for (int i = concatenado.length - 1; i >= 0; i--) {
      final digito = int.tryParse(concatenado[i]) ?? 0;
      soma += digito * peso;
      peso++;
      if (peso > 9) peso = 2;
    }

    final resto = soma % 11;
    if (resto == 0 || resto == 1) return 0;
    return 11 - resto;
  }

  /// Valida CPF (11 dígitos, algoritmo módulo 11)
  static bool validarCpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false; // todos iguais

    // Primeiro dígito verificador
    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(digits[i]) * (10 - i);
    }
    int resto = soma % 11;
    int d1 = (resto < 2) ? 0 : (11 - resto);
    if (int.parse(digits[9]) != d1) return false;

    // Segundo dígito verificador
    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(digits[i]) * (11 - i);
    }
    resto = soma % 11;
    int d2 = (resto < 2) ? 0 : (11 - resto);
    return int.parse(digits[10]) == d2;
  }

  /// Valida CNPJ (14 dígitos, algoritmo específico CNPJ)
  static bool validarCnpj(String cnpj) {
    final digits = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) return false;

    const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    int soma = 0;
    for (int i = 0; i < 12; i++) {
      soma += int.parse(digits[i]) * pesos1[i];
    }
    int resto = soma % 11;
    int d1 = (resto < 2) ? 0 : (11 - resto);
    if (int.parse(digits[12]) != d1) return false;

    soma = 0;
    for (int i = 0; i < 13; i++) {
      soma += int.parse(digits[i]) * pesos2[i];
    }
    resto = soma % 11;
    int d2 = (resto < 2) ? 0 : (11 - resto);
    return int.parse(digits[13]) == d2;
  }

  /// Verifica se uma data é dia útil (não é fim de semana nem feriado bancário)
  static bool isDiaUtil(DateTime data) {
    if (data.weekday == DateTime.saturday || data.weekday == DateTime.sunday) {
      return false;
    }
    final dataStr = '${data.day.toString().padLeft(2, '0')}'
        '${data.month.toString().padLeft(2, '0')}'
        '${data.year.toString().padLeft(4, '0')}';
    return !_feriadosBancarios.contains(dataStr);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Regras ALG
  // ─────────────────────────────────────────────────────────────────────────

  /// ALG001 — Validar DAC do Nosso Número no Segmento P
  static ResultadoRegra aLG001ValidarDac(
      String segP, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (segP.length < 67) {
      return ResultadoRegra.sucesso('ALG001', tempoMs: sw.elapsedMilliseconds);
    }

    // Extrair campos do Segmento P
    final agencia = segP.substring(17, 21);     // pos 18-21
    final conta = segP.substring(22, 30);        // pos 23-30
    final nossoNumCompleto = segP.substring(32, 52); // pos 33-52 (20 chars)

    // No Santander: primeiros 3 = carteira, próximos 12 = nosso número, último 1 = DAC
    if (nossoNumCompleto.length < 16) {
      return ResultadoRegra.sucesso('ALG001', tempoMs: sw.elapsedMilliseconds);
    }

    final carteira = nossoNumCompleto.substring(0, 3);
    final nossoNumero = nossoNumCompleto.substring(3, 15);
    final dacDeclarado = int.tryParse(nossoNumCompleto.substring(15, 16));

    if (dacDeclarado == null) {
      return ResultadoRegra.falha('ALG001', [
        ErroValidacao(
          codigo: 'ALG001',
          descricao: 'DAC do Nosso Número não é numérico no Segmento P',
          detalhe: 'Posição 48 do segmento: "${nossoNumCompleto.substring(15, 16)}"',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.algoritmo,
          linha: numLinha,
          posicaoInicio: 48,
          posicaoFim: 48,
          campoCnab: 'DAC do Nosso Número',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    // Verificar se campos são numéricos antes de calcular
    if (!RegExp(r'^\d+$').hasMatch(agencia) ||
        !RegExp(r'^\d+$').hasMatch(conta) ||
        !RegExp(r'^\d+$').hasMatch(nossoNumero)) {
      return ResultadoRegra.sucesso('ALG001', tempoMs: sw.elapsedMilliseconds);
    }

    final dacCalculado = calcularDacSantander(agencia, conta, carteira, nossoNumero);

    if (dacCalculado != dacDeclarado) {
      return ResultadoRegra.falha('ALG001', [
        ErroValidacao(
          codigo: 'ALG001',
          descricao: 'DAC do Nosso Número incorreto no Segmento P',
          detalhe:
              'DAC declarado: $dacDeclarado | DAC calculado: $dacCalculado '
              '(AG: $agencia | Conta: $conta | Cart: $carteira | NrNosso: $nossoNumero)',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.algoritmo,
          linha: numLinha,
          posicaoInicio: 33,
          posicaoFim: 48,
          campoCnab: 'Nosso Número + DAC',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Recalcule o DAC usando Módulo 11 (pesos 2-9) sobre: '
              'Agência(4) + Conta(8) + Carteira(3) + NossoNúmero(12)',
          referenciaFebraban:
              'Santander CNAB 240 — DAC = Módulo 11 pesos 2-9 (dir-esq) | '
              'Resto 0 ou 1 → DAC=0, senão DAC=11-resto',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('ALG001', tempoMs: sw.elapsedMilliseconds);
  }

  /// ALG002 — Validar CPF do sacado no Segmento Q (tipo 01)
  static ResultadoRegra aLG002ValidarCpfSacado(
      String segQ, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (segQ.length < 33) {
      return ResultadoRegra.sucesso('ALG002', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoInsc = segQ.substring(17, 19);
    if (tipoInsc != '01') {
      return ResultadoRegra.sucesso('ALG002', tempoMs: sw.elapsedMilliseconds);
    }

    final nrInsc = segQ.substring(19, 33);
    // CPF: 3 zeros + 11 dígitos
    final cpf = nrInsc.substring(3); // os 11 últimos

    if (!validarCpf(cpf)) {
      return ResultadoRegra.falha('ALG002', [
        ErroValidacao(
          codigo: 'ALG002',
          descricao: 'CPF do sacado inválido (dígitos verificadores incorretos)',
          detalhe: 'CPF: ${cpf.replaceFirstMapped(
                RegExp(r'^(\d{3})(\d{3})(\d{3})(\d{2})$'),
                (m) => '${m[1]}.${m[2]}.${m[3]}-${m[4]}',
              )}',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.algoritmo,
          linha: numLinha,
          posicaoInicio: 20,
          posicaoFim: 33,
          campoCnab: 'Nr de Inscrição do Pagador (CPF)',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao:
              'Verifique o CPF do sacado — dígitos verificadores inválidos',
          referenciaFebraban:
              'CPF validação: Módulo 11 — dois dígitos verificadores',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('ALG002', tempoMs: sw.elapsedMilliseconds);
  }

  /// ALG003 — Validar CNPJ do sacado no Segmento Q (tipo 02)
  static ResultadoRegra aLG003ValidarCnpjSacado(
      String segQ, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (segQ.length < 33) {
      return ResultadoRegra.sucesso('ALG003', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoInsc = segQ.substring(17, 19);
    if (tipoInsc != '02') {
      return ResultadoRegra.sucesso('ALG003', tempoMs: sw.elapsedMilliseconds);
    }

    final cnpj = segQ.substring(19, 33);

    if (!validarCnpj(cnpj)) {
      return ResultadoRegra.falha('ALG003', [
        ErroValidacao(
          codigo: 'ALG003',
          descricao: 'CNPJ do sacado inválido (dígitos verificadores incorretos)',
          detalhe: 'CNPJ: $cnpj',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.algoritmo,
          linha: numLinha,
          posicaoInicio: 20,
          posicaoFim: 33,
          campoCnab: 'Nr de Inscrição do Pagador (CNPJ)',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'Q',
          sugestaoCorrecao:
              'Verifique o CNPJ do sacado — dígitos verificadores inválidos',
          referenciaFebraban:
              'CNPJ validação: algoritmo CNPJ com dois dígitos verificadores',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('ALG003', tempoMs: sw.elapsedMilliseconds);
  }

  /// ALG004 — Validar CNPJ do cedente no Header de Arquivo (tipo 02)
  static ResultadoRegra aLG004ValidarCnpjCedente(
      String headerArquivo, int numLinha) {
    final sw = Stopwatch()..start();
    if (headerArquivo.length < 33) {
      return ResultadoRegra.sucesso('ALG004', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoInsc = headerArquivo.substring(17, 19);
    if (tipoInsc != '02') {
      return ResultadoRegra.sucesso('ALG004', tempoMs: sw.elapsedMilliseconds);
    }

    final cnpj = headerArquivo.substring(19, 33);

    if (!validarCnpj(cnpj)) {
      return ResultadoRegra.falha('ALG004', [
        ErroValidacao(
          codigo: 'ALG004',
          descricao: 'CNPJ do cedente inválido no Header de Arquivo',
          detalhe: 'CNPJ: $cnpj',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.algoritmo,
          linha: numLinha,
          posicaoInicio: 20,
          posicaoFim: 33,
          campoCnab: 'CNPJ da Empresa Cedente',
          sugestaoCorrecao:
              'Verifique o CNPJ da empresa — dígitos verificadores inválidos',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('ALG004', tempoMs: sw.elapsedMilliseconds);
  }

  /// ALG005 — Data de vencimento não deve cair em feriado bancário ou fim de semana
  static ResultadoRegra aLG005DataUtilVencimento(
      String segP, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (segP.length < 80) {
      return ResultadoRegra.sucesso('ALG005', tempoMs: sw.elapsedMilliseconds);
    }

    final dataStr = segP.substring(72, 80);
    if (dataStr == '00000000' || !RegExp(r'^\d{8}$').hasMatch(dataStr)) {
      return ResultadoRegra.sucesso('ALG005', tempoMs: sw.elapsedMilliseconds);
    }

    try {
      final dia = int.parse(dataStr.substring(0, 2));
      final mes = int.parse(dataStr.substring(2, 4));
      final ano = int.parse(dataStr.substring(4, 8));
      final vencimento = DateTime(ano, mes, dia);

      if (!isDiaUtil(vencimento)) {
        final motivoStr = vencimento.weekday == DateTime.saturday
            ? 'sábado'
            : vencimento.weekday == DateTime.sunday
                ? 'domingo'
                : 'feriado bancário';

        return ResultadoRegra.falha('ALG005', [
          ErroValidacao(
            codigo: 'ALG005',
            descricao:
                'Data de vencimento cai em dia não útil ($motivoStr)',
            detalhe:
                'Data: $dataStr ($dia/${mes}/$ano = $motivoStr)',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.algoritmo,
            linha: numLinha,
            posicaoInicio: 73,
            posicaoFim: 80,
            campoCnab: 'Data de Vencimento',
            indiceTitulo: idxTitulo,
            tipoSegmento: 'P',
            sugestaoCorrecao:
                'Ajuste a data de vencimento para um dia útil bancário',
            referenciaFebraban:
                'Feriados bancários 2025/2026 hard-coded na validação',
          ),
        ], tempoMs: sw.elapsedMilliseconds);
      }
    } catch (_) {}

    return ResultadoRegra.sucesso('ALG005', tempoMs: sw.elapsedMilliseconds);
  }

  /// ALG006 — Dígito verificador da conta Santander
  static ResultadoRegra aLG006DigitoContaSantander(
      String segP, int numLinha, int idxTitulo) {
    final sw = Stopwatch()..start();
    if (segP.length < 32) {
      return ResultadoRegra.sucesso('ALG006', tempoMs: sw.elapsedMilliseconds);
    }

    final agencia = segP.substring(17, 21); // pos 18-21
    final conta = segP.substring(22, 30);    // pos 23-30
    final digitoDeclarado = int.tryParse(segP.substring(30, 31)); // pos 31

    if (digitoDeclarado == null) {
      return ResultadoRegra.sucesso('ALG006', tempoMs: sw.elapsedMilliseconds);
    }

    if (!RegExp(r'^\d+$').hasMatch(agencia) || !RegExp(r'^\d+$').hasMatch(conta)) {
      return ResultadoRegra.sucesso('ALG006', tempoMs: sw.elapsedMilliseconds);
    }

    final digitoCalculado = calcularDigitoContaSantander(agencia, conta);

    if (digitoCalculado != digitoDeclarado) {
      return ResultadoRegra.falha('ALG006', [
        ErroValidacao(
          codigo: 'ALG006',
          descricao: 'Dígito verificador da conta Santander incorreto no Segmento P',
          detalhe:
              'Declarado: $digitoDeclarado | Calculado: $digitoCalculado '
              '(AG: $agencia | Conta: $conta)',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.algoritmo,
          linha: numLinha,
          posicaoInicio: 31,
          posicaoFim: 31,
          campoCnab: 'Dígito da Conta Corrente',
          indiceTitulo: idxTitulo,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Recalcule o dígito da conta usando Módulo 11 (pesos 2-9) sobre: Agência(4) + Conta(8)',
          referenciaFebraban:
              'Santander — Dígito Conta = Módulo 11 pesos 2-9 (dir-esq) sobre AG+Conta',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('ALG006', tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras algorítmicas
  static List<ResultadoRegra> validarTodo({
    required String headerArquivo,
    required List<String> segmentosP,
    required List<String> segmentosQ,
    required List<int> linhasP,
    required List<int> linhasQ,
  }) {
    final resultados = <ResultadoRegra>[];

    // Header do arquivo
    resultados.add(aLG004ValidarCnpjCedente(headerArquivo, 1));

    // Segmentos P e Q pareados
    final minLen = segmentosP.length < segmentosQ.length
        ? segmentosP.length
        : segmentosQ.length;

    for (int i = 0; i < minLen; i++) {
      final segP = segmentosP[i];
      final segQ = segmentosQ[i];
      final linhaP = i < linhasP.length ? linhasP[i] : 0;
      final linhaQ = i < linhasQ.length ? linhasQ[i] : 0;

      resultados.add(aLG001ValidarDac(segP, linhaP, i));
      resultados.add(aLG005DataUtilVencimento(segP, linhaP, i));
      resultados.add(aLG006DigitoContaSantander(segP, linhaP, i));
      resultados.add(aLG002ValidarCpfSacado(segQ, linhaQ, i));
      resultados.add(aLG003ValidarCnpjSacado(segQ, linhaQ, i));
    }

    return resultados;
  }
}
