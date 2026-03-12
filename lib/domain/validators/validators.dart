// domain/validators/validators.dart
// Validadores completos para CNAB 240 Santander

import '../models/titulo.dart';
import '../../core/constants/app_constants.dart';

class ValidationResult {
  final bool isValid;
  final String? error;
  final String? extra;

  const ValidationResult({
    required this.isValid,
    this.error,
    this.extra,
  });

  static const ValidationResult valid = ValidationResult(isValid: true);
}

class ValidadorCNPJ {
  static ValidationResult validar(String cnpj) {
    // Remove caracteres não numéricos
    final numeros = cnpj.replaceAll(RegExp(r'\D'), '');

    if (numeros.length != 14) {
      return const ValidationResult(
          isValid: false, error: 'CNPJ deve ter 14 dígitos');
    }

    // Verifica sequências inválidas
    if (RegExp(r'^(\d)\1+$').hasMatch(numeros)) {
      return const ValidationResult(
          isValid: false, error: 'CNPJ inválido (sequência repetida)');
    }

    // Calcula primeiro dígito verificador
    int soma = 0;
    const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    for (int i = 0; i < 12; i++) {
      soma += int.parse(numeros[i]) * pesos1[i];
    }
    int resto = soma % 11;
    int digito1 = (resto < 2) ? 0 : 11 - resto;

    if (int.parse(numeros[12]) != digito1) {
      return const ValidationResult(
          isValid: false, error: 'CNPJ inválido (primeiro dígito verificador)');
    }

    // Calcula segundo dígito verificador
    soma = 0;
    const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    for (int i = 0; i < 13; i++) {
      soma += int.parse(numeros[i]) * pesos2[i];
    }
    resto = soma % 11;
    int digito2 = (resto < 2) ? 0 : 11 - resto;

    if (int.parse(numeros[13]) != digito2) {
      return const ValidationResult(
          isValid: false, error: 'CNPJ inválido (segundo dígito verificador)');
    }

    return ValidationResult.valid;
  }

  static String formatar(String cnpj) {
    final n = cnpj.replaceAll(RegExp(r'\D'), '');
    if (n.length != 14) return cnpj;
    return '${n.substring(0, 2)}.${n.substring(2, 5)}.${n.substring(5, 8)}/${n.substring(8, 12)}-${n.substring(12, 14)}';
  }

  static String limpar(String cnpj) => cnpj.replaceAll(RegExp(r'\D'), '');
}

class ValidadorCPF {
  static ValidationResult validar(String cpf) {
    final numeros = cpf.replaceAll(RegExp(r'\D'), '');

    if (numeros.length != 11) {
      return const ValidationResult(
          isValid: false, error: 'CPF deve ter 11 dígitos');
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(numeros)) {
      return const ValidationResult(
          isValid: false, error: 'CPF inválido (sequência repetida)');
    }

    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(numeros[i]) * (10 - i);
    }
    int resto = (soma * 10) % 11;
    int digito1 = (resto == 10 || resto == 11) ? 0 : resto;

    if (int.parse(numeros[9]) != digito1) {
      return const ValidationResult(
          isValid: false, error: 'CPF inválido (primeiro dígito verificador)');
    }

    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(numeros[i]) * (11 - i);
    }
    resto = (soma * 10) % 11;
    int digito2 = (resto == 10 || resto == 11) ? 0 : resto;

    if (int.parse(numeros[10]) != digito2) {
      return const ValidationResult(
          isValid: false, error: 'CPF inválido (segundo dígito verificador)');
    }

    return ValidationResult.valid;
  }

  static String formatar(String cpf) {
    final n = cpf.replaceAll(RegExp(r'\D'), '');
    if (n.length != 11) return cpf;
    return '${n.substring(0, 3)}.${n.substring(3, 6)}.${n.substring(6, 9)}-${n.substring(9, 11)}';
  }

  static String limpar(String cpf) => cpf.replaceAll(RegExp(r'\D'), '');
}

class ValidadorContaSantander {
  /// Valida dígito da conta Santander usando Módulo 11 pesos 2-9
  static ValidationResult validarDigitoConta(String conta, String digitoInformado) {
    final contaLimpa = conta.replaceAll(RegExp(r'\D'), '').padLeft(8, '0');

    if (contaLimpa.length != 8) {
      return const ValidationResult(
          isValid: false, error: 'Conta deve ter 8 dígitos');
    }

    const pesos = [9, 8, 7, 6, 5, 4, 3, 2];
    int soma = 0;
    for (int i = 0; i < 8; i++) {
      soma += int.parse(contaLimpa[i]) * pesos[i];
    }

    int resto = soma % 11;
    String digitoCalculado;
    if (resto == 0 || resto == 1) {
      digitoCalculado = '0';
    } else {
      digitoCalculado = (11 - resto).toString();
    }

    if (digitoInformado != digitoCalculado) {
      return ValidationResult(
        isValid: false,
        error: 'Dígito da conta inválido. Esperado: $digitoCalculado',
        extra: digitoCalculado,
      );
    }

    return ValidationResult(isValid: true, extra: digitoCalculado);
  }

  static ValidationResult validarAgencia(String agencia) {
    final limpa = agencia.replaceAll(RegExp(r'\D'), '');
    if (limpa.length != 4) {
      return const ValidationResult(
          isValid: false, error: 'Agência deve ter 4 dígitos');
    }
    return ValidationResult.valid;
  }
}

class ValidadorData {
  /// Valida uma data de vencimento.
  ///
  /// - [permitirPassado]: se true, não rejeita datas anteriores a hoje
  ///   (usado para títulos importados de XML com data original da nota).
  /// - [verificarFeriado]: se true, rejeita feriados bancários nacionais.
  /// - [verificarFimDeSemana]: se true (padrão), rejeita sábado e domingo.
  ///   Para XMLs importados deve ser false pois a data da nota é histórica.
  static ValidationResult validar(
    DateTime? data, {
    bool permitirPassado = false,
    bool verificarFeriado = true,
    bool verificarFimDeSemana = true,
  }) {
    if (data == null) {
      return const ValidationResult(isValid: false, error: 'Data obrigatória');
    }

    final hoje = DateTime.now();
    final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final dataCheck = DateTime(data.year, data.month, data.day);

    if (!permitirPassado && dataCheck.isBefore(dataHoje)) {
      return const ValidationResult(
          isValid: false,
          error: 'Data de vencimento não pode ser anterior a hoje');
    }

    // Verificar fim de semana (somente para títulos manuais)
    if (verificarFimDeSemana &&
        (data.weekday == DateTime.saturday || data.weekday == DateTime.sunday)) {
      final nomeDia = data.weekday == DateTime.saturday ? 'sábado' : 'domingo';
      return ValidationResult(
          isValid: false,
          error: 'Data de vencimento não pode ser $nomeDia');
    }

    // Verificar feriados bancários
    if (verificarFeriado) {
      final dataStr =
          '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      if (AppConstants.feriadosBancarios.contains(dataStr)) {
        return ValidationResult(
            isValid: false,
            error: 'Data $dataStr é feriado bancário nacional');
      }
    }

    return ValidationResult.valid;
  }

  static String formatarCNAB(DateTime? data) {
    if (data == null) return '00000000';
    return '${data.day.toString().padLeft(2, '0')}${data.month.toString().padLeft(2, '0')}${data.year.toString().padLeft(4, '0')}';
  }

  static String formatarDisplay(DateTime? data) {
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  static DateTime? parseDDMMAAAA(String s) {
    try {
      final limpa = s.replaceAll(RegExp(r'\D'), '');
      if (limpa.length != 8) return null;
      final dia = int.parse(limpa.substring(0, 2));
      final mes = int.parse(limpa.substring(2, 4));
      final ano = int.parse(limpa.substring(4, 8));
      return DateTime(ano, mes, dia);
    } catch (_) {
      return null;
    }
  }
}

class ValidadorCamposObrigatorios {
  /// Valida todos os campos obrigatórios de um título.
  ///
  /// Títulos importados de XML (origemXml != null) recebem tratamento
  /// diferenciado: datas no passado, em fim de semana ou feriado são
  /// aceitas pois refletem a data original do documento fiscal.
  static List<String> validarTitulo(Titulo titulo) {
    final erros = <String>[];

    // Detecta se o título veio de importação XML
    final isDeXml = titulo.origemXml != null && titulo.origemXml!.isNotEmpty;

    // ── Campos básicos ──────────────────────────────────────
    if (titulo.seuNumero.trim().isEmpty) {
      erros.add('Seu Número (Nosso Número) é obrigatório');
    }

    if (titulo.valorNominal <= 0) {
      erros.add('Valor Nominal deve ser maior que zero');
    }

    // ── Data de Vencimento ──────────────────────────────────
    if (titulo.dataVencimento == null) {
      erros.add('Data de Vencimento é obrigatória');
    } else {
      // XMLs importados: permitir passado, fim de semana e feriado
      // pois a data é histórica (data original da nota fiscal).
      // Títulos manuais: validação completa.
      final validData = ValidadorData.validar(
        titulo.dataVencimento,
        permitirPassado: isDeXml,
        verificarFeriado: !isDeXml,
        verificarFimDeSemana: !isDeXml,
      );
      if (!validData.isValid) erros.add(validData.error!);
    }

    // ── Sacado — documento ──────────────────────────────────
    final docLimpo = titulo.cpfCnpjSacado.replaceAll(RegExp(r'\D'), '');
    if (docLimpo.isEmpty) {
      erros.add('CPF/CNPJ do Sacado é obrigatório');
    } else {
      if (titulo.tipoInscricaoSacado == TipoInscricao.cnpj) {
        final result = ValidadorCNPJ.validar(docLimpo);
        if (!result.isValid) erros.add('CNPJ do Sacado: ${result.error}');
      } else {
        final result = ValidadorCPF.validar(docLimpo);
        if (!result.isValid) erros.add('CPF do Sacado: ${result.error}');
      }
    }

    // ── Sacado — endereço ───────────────────────────────────
    if (titulo.nomeSacado.trim().isEmpty) {
      erros.add('Nome do Sacado é obrigatório');
    }
    if (titulo.enderecoSacado.trim().isEmpty) {
      erros.add('Endereço do Sacado é obrigatório');
    }
    if (titulo.cepSacado.replaceAll(RegExp(r'\D'), '').length != 8) {
      erros.add('CEP do Sacado inválido (deve ter 8 dígitos)');
    }
    if (titulo.cidadeSacado.trim().isEmpty) {
      erros.add('Cidade do Sacado é obrigatória');
    }
    if (titulo.ufSacado.trim().length != 2) {
      erros.add('UF do Sacado é obrigatória (2 letras)');
    }

    return erros;
  }
}

class ValidadorArquivoFinal {
  static List<ErroArquivo> validar(String conteudo) {
    final erros = <ErroArquivo>[];
    final linhas = conteudo.split('\n');

    for (int i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      if (linha.isEmpty) continue;

      // Remove \r se existir
      final linhaLimpa = linha.replaceAll('\r', '');

      if (linhaLimpa.length != AppConstants.layoutLinhaLength) {
        erros.add(ErroArquivo(
          numeroLinha: i + 1,
          campo: 'Comprimento da linha',
          descricao:
              'Linha tem ${linhaLimpa.length} chars, esperado ${AppConstants.layoutLinhaLength}',
        ));
      }
    }

    return erros;
  }
}

class ErroArquivo {
  final int numeroLinha;
  final String campo;
  final String descricao;

  const ErroArquivo({
    required this.numeroLinha,
    required this.campo,
    required this.descricao,
  });
}

class ErroValidacaoRemessa {
  final String tituloId;
  final String tituloRef;
  final List<String> erros;

  const ErroValidacaoRemessa({
    required this.tituloId,
    required this.tituloRef,
    required this.erros,
  });
}
