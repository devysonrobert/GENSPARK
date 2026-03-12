// domain/builders/cnab_santander240_builder.dart
// Construtor do arquivo CNAB 240 Santander - Cobrança de Boletos
// Implementação completa conforme manual FEBRABAN/Santander

import '../models/empresa_config.dart';
import '../models/titulo.dart';
import '../validators/validators.dart';

class CnabSantander240Builder {
  final EmpresaConfig empresa;
  final List<Titulo> titulos;
  final DateTime dataGeracao;

  CnabSantander240Builder({
    required this.empresa,
    required this.titulos,
    DateTime? dataGeracao,
  }) : dataGeracao = dataGeracao ?? DateTime.now();

  /// Gera o arquivo CNAB 240 completo como String
  /// Cada linha tem exatamente 240 chars + CRLF (\r\n)
  String gerar() {
    final buffer = StringBuffer();

    // [HEADER DE ARQUIVO] — 1 registro
    buffer.write(_buildHeaderArquivo());
    buffer.write('\r\n');

    // [HEADER DE LOTE] — 1 registro
    buffer.write(_buildHeaderLote());
    buffer.write('\r\n');

    // Registros de detalhe: P, Q e opcionalmente R
    int sequencialRegistro = 1;
    for (final titulo in titulos) {
      // [SEGMENTO P] — dados do boleto
      buffer.write(_buildSegmentoP(titulo, sequencialRegistro));
      buffer.write('\r\n');
      sequencialRegistro++;

      // [SEGMENTO Q] — dados do sacado
      buffer.write(_buildSegmentoQ(titulo, sequencialRegistro));
      buffer.write('\r\n');
      sequencialRegistro++;

      // [SEGMENTO R] — desconto/juros/multa (somente se necessário)
      if (titulo.precisaSegmentoR) {
        buffer.write(_buildSegmentoR(titulo, sequencialRegistro));
        buffer.write('\r\n');
        sequencialRegistro++;
      }
    }

    // [TRAILER DE LOTE] — 1 registro
    buffer.write(_buildTrailerLote(sequencialRegistro));
    buffer.write('\r\n');

    // [TRAILER DE ARQUIVO] — 1 registro
    buffer.write(_buildTrailerArquivo(sequencialRegistro + 2));
    buffer.write('\r\n');

    return buffer.toString();
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER DE ARQUIVO
  // ══════════════════════════════════════════════════════════════
  String _buildHeaderArquivo() {
    final sb = StringBuffer();

    // [H.001-003] Código do Banco — 3 num
    sb.write(_numerico('033', 3));

    // [H.004-007] Lote de Serviço = 0000 (header arquivo) — 4 num
    sb.write(_numerico('0000', 4));

    // [H.008-008] Tipo de Registro = 0 — 1 num
    sb.write('0');

    // [H.009-017] Uso FEBRABAN — 9 brancos
    sb.write(_brancos(9));

    // [H.018-018] Tipo de Inscrição = 2 (CNPJ) — 1 num
    sb.write('2');

    // [H.019-032] CNPJ da Empresa — 14 num
    sb.write(_numerico(empresa.cnpj.replaceAll(RegExp(r'\D'), ''), 14));

    // [H.033-052] Código do Convênio/Cedente — 20 alfa
    sb.write(_alfa(empresa.codigoCedente, 20));

    // [H.053-057] Agência — 5 num
    sb.write(_numerico(empresa.agencia, 5));

    // [H.058-058] Dígito da Agência — 1 alfa
    sb.write(_alfa(empresa.digitoAgencia, 1));

    // [H.059-070] Conta Corrente — 12 num
    sb.write(_numerico(empresa.contaCorrente, 12));

    // [H.071-071] Dígito da Conta — 1 alfa
    sb.write(_alfa(empresa.digitoConta, 1));

    // [H.072-072] Dígito Agência/Conta — 1 branco
    sb.write(' ');

    // [H.073-102] Nome da Empresa — 30 alfa
    sb.write(_alfa(empresa.razaoSocial.toUpperCase(), 30));

    // [H.103-132] Nome do Banco — 30 alfa
    sb.write(_alfa('BANCO SANTANDER', 30));

    // [H.133-142] Uso FEBRABAN — 10 brancos
    sb.write(_brancos(10));

    // [H.143-143] Código Remessa = 1 — 1 num
    sb.write('1');

    // [H.144-151] Data de Geração (DDMMAAAA) — 8 num
    sb.write(ValidadorData.formatarCNAB(dataGeracao));

    // [H.152-157] Hora de Geração (HHMMSS) — 6 num
    sb.write(_numerico(
        '${dataGeracao.hour.toString().padLeft(2, '0')}${dataGeracao.minute.toString().padLeft(2, '0')}${dataGeracao.second.toString().padLeft(2, '0')}',
        6));

    // [H.158-163] Número Sequencial do Arquivo — 6 num
    sb.write(_numerico(empresa.numeroSequencial.toString(), 6));

    // [H.164-166] Versão Layout FEBRABAN = 089 — 3 num
    sb.write('089');

    // [H.167-171] Densidade = 01600 — 5 num
    sb.write('01600');

    // [H.172-191] Reservado Banco — 20 brancos
    sb.write(_brancos(20));

    // [H.192-211] Reservado Empresa — 20 brancos
    sb.write(_brancos(20));

    // [H.212-240] Uso FEBRABAN — 29 brancos
    sb.write(_brancos(29));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Header arquivo: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER DE LOTE
  // ══════════════════════════════════════════════════════════════
  String _buildHeaderLote() {
    final sb = StringBuffer();

    // [HL.001-003] Código do Banco — 3 num
    sb.write(_numerico('033', 3));

    // [HL.004-007] Lote de Serviço = 0001 — 4 num
    sb.write('0001');

    // [HL.008-008] Tipo de Registro = 1 — 1 num
    sb.write('1');

    // [HL.009-009] Tipo de Operação = R (remessa) — 1 alfa
    sb.write('R');

    // [HL.010-011] Tipo de Serviço = 01 (cobrança) — 2 num
    sb.write('01');

    // [HL.012-013] Forma de Lançamento = 01 — 2 num
    sb.write('01');

    // [HL.014-016] Versão Layout do Lote = 040 — 3 num
    sb.write('040');

    // [HL.017-017] Uso FEBRABAN — 1 branco
    sb.write(' ');

    // [HL.018-018] Tipo de Inscrição = 2 (CNPJ) — 1 num
    sb.write('2');

    // [HL.019-032] CNPJ — 14 num
    sb.write(_numerico(empresa.cnpj.replaceAll(RegExp(r'\D'), ''), 14));

    // [HL.033-052] Código do Convênio — 20 alfa
    sb.write(_alfa(empresa.codigoCedente, 20));

    // [HL.053-057] Agência — 5 num
    sb.write(_numerico(empresa.agencia, 5));

    // [HL.058-058] Dígito Agência — 1 alfa
    sb.write(_alfa(empresa.digitoAgencia, 1));

    // [HL.059-070] Conta Corrente — 12 num
    sb.write(_numerico(empresa.contaCorrente, 12));

    // [HL.071-071] Dígito Conta — 1 alfa
    sb.write(_alfa(empresa.digitoConta, 1));

    // [HL.072-072] Branco — 1
    sb.write(' ');

    // [HL.073-102] Nome da Empresa — 30 alfa
    sb.write(_alfa(empresa.razaoSocial.toUpperCase(), 30));

    // [HL.103-142] Informações 1 — 40 brancos
    sb.write(_brancos(40));

    // [HL.143-172] Informações 2 — 30 brancos
    sb.write(_brancos(30));

    // [HL.173-177] Número Remessa — 5 num
    sb.write(_numerico(empresa.numeroSequencial.toString(), 5));

    // [HL.178-185] Data de Gravação (DDMMAAAA) — 8 num
    sb.write(ValidadorData.formatarCNAB(dataGeracao));

    // [HL.186-193] Data de Crédito — 8 zeros
    sb.write('00000000');

    // [HL.194-240] Uso FEBRABAN — 47 brancos
    sb.write(_brancos(47));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Header lote: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // SEGMENTO P — Dados do Título
  // ══════════════════════════════════════════════════════════════
  String _buildSegmentoP(Titulo titulo, int seq) {
    final sb = StringBuffer();

    // [P.001-003] Código do Banco — 3 num
    sb.write('033');

    // [P.004-007] Número do Lote — 4 num
    sb.write('0001');

    // [P.008-008] Tipo de Registro = 3 — 1 num
    sb.write('3');

    // [P.009-013] Número Sequencial do Registro no Lote — 5 num
    sb.write(_numerico(seq.toString(), 5));

    // [P.014-014] Segmento = P — 1 alfa
    sb.write('P');

    // [P.015-015] Uso FEBRABAN — 1 branco
    sb.write(' ');

    // [P.016-017] Código do Movimento Remessa = 01 (entrada) — 2 num
    sb.write('01');

    // [P.018-022] Agência — 5 num (zeros à esquerda)
    sb.write(_numerico(empresa.agencia, 5));

    // [P.023-023] Dígito da Agência — 1 alfa
    sb.write(_alfa(empresa.digitoAgencia, 1));

    // [P.024-035] Conta Corrente — 12 num
    sb.write(_numerico(empresa.contaCorrente, 12));

    // [P.036-036] Dígito da Conta — 1 alfa
    sb.write(_alfa(empresa.digitoConta, 1));

    // [P.037-037] Branco — 1
    sb.write(' ');

    // [P.038-057] Código do Cedente/Nosso Número — 20 alfa
    // Santander: Carteira(3) + NossoNumero(12) + DAC(1) = 16 chars, restante brancos
    final nossoNumFormatado = _buildNossoNumeroCNAB(titulo);
    sb.write(_alfa(nossoNumFormatado, 20));

    // [P.058-058] Código da Carteira = 1 (registrada) — 1 num
    sb.write('1');

    // [P.059-059] Forma de Cadastramento = 1 (com cadastramento) — 1 num
    sb.write('1');

    // [P.060-060] Tipo do Documento = 2 (escritural) — 1 num
    sb.write('2');

    // [P.061-061] Emissão do Boleto = 2 (cliente emite) — 1 num
    sb.write('2');

    // [P.062-062] Distribuição do Boleto = 2 (cliente distribui) — 1 num
    sb.write('2');

    // [P.063-072] Número do Documento — 10 alfa
    sb.write(_alfa(titulo.numeroDocumento, 10));

    // [P.073-080] Data de Vencimento (DDMMAAAA) — 8 num
    sb.write(ValidadorData.formatarCNAB(titulo.dataVencimento));

    // [P.081-095] Valor do Título (15 num, 2 decimais, sem vírgula) — 15 num
    sb.write(_valor(titulo.valorNominal, 15));

    // [P.096-100] Agência Cobradora — 5 zeros
    sb.write('00000');

    // [P.101-101] Dígito Agência Cobradora — 1 branco
    sb.write(' ');

    // [P.102-105] Espécie do Título — 2 num + 2 brancos
    sb.write(_numerico(titulo.especieTitulo, 2));
    sb.write('  ');

    // [P.106-106] Aceite (A ou N) — 1 alfa
    sb.write(titulo.aceite.isEmpty ? 'N' : titulo.aceite[0]);

    // [P.107-114] Data de Emissão (DDMMAAAA) — 8 num
    sb.write(ValidadorData.formatarCNAB(titulo.dataEmissao ?? DateTime.now()));

    // [P.115-116] Código de Juros — 2 num
    final codJuros = titulo.codigoJuros == '0' || titulo.codigoJuros == '3'
        ? '03'
        : titulo.codigoJuros.padLeft(2, '0');
    sb.write(codJuros);

    // [P.117-124] Data de Juros (DDMMAAAA ou zeros) — 8 num
    if (titulo.codigoJuros != '0' && titulo.dataJuros != null) {
      sb.write(ValidadorData.formatarCNAB(titulo.dataJuros));
    } else {
      sb.write('00000000');
    }

    // [P.125-139] Valor de Juros por Dia — 15 num
    sb.write(_valor(titulo.codigoJuros != '0' ? titulo.valorJuros : 0.0, 15));

    // [P.140-141] Código Desconto 1 — 2 num
    sb.write(_numerico(titulo.codigoDesconto1, 2));

    // [P.142-149] Data Desconto 1 (DDMMAAAA) — 8 num
    if (titulo.codigoDesconto1 != '0' && titulo.dataDesconto1 != null) {
      sb.write(ValidadorData.formatarCNAB(titulo.dataDesconto1));
    } else {
      sb.write('00000000');
    }

    // [P.150-164] Valor/Percentual Desconto 1 — 15 num
    sb.write(_valor(
        titulo.codigoDesconto1 != '0' ? titulo.valorDesconto1 : 0.0, 15));

    // [P.165-179] IOF — 15 zeros
    sb.write(_valor(0.0, 15));

    // [P.180-194] Abatimento — 15 zeros
    sb.write(_valor(0.0, 15));

    // [P.195-209] Identificação do Título na Empresa (Nosso Número) — 15 alfa
    sb.write(_alfa(titulo.seuNumero, 15));

    // [P.210-211] Código de Protesto = 03 (não protestar) — 2 num
    sb.write('03');

    // [P.212-213] Número de Dias para Protesto = 00 — 2 num
    sb.write('00');

    // [P.214-215] Código Baixa/Devolução = 01 — 2 num
    sb.write('01');

    // [P.216-218] Número de Dias para Baixa = 060 — 3 num
    sb.write('060');

    // [P.219-220] Código Moeda = 09 (Real) — 2 num
    sb.write('09');

    // [P.221-230] Número do Contrato — 10 zeros
    sb.write('0000000000');

    // [P.231-231] Branco — 1
    sb.write(' ');

    // [P.232-240] Uso FEBRABAN — 9 brancos
    sb.write(_brancos(9));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Segmento P [${titulo.seuNumero}]: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // SEGMENTO Q — Dados do Sacado
  // ══════════════════════════════════════════════════════════════
  String _buildSegmentoQ(Titulo titulo, int seq) {
    final sb = StringBuffer();

    // [Q.001-003] Código do Banco — 3 num
    sb.write('033');

    // [Q.004-007] Número do Lote — 4 num
    sb.write('0001');

    // [Q.008-008] Tipo de Registro = 3 — 1 num
    sb.write('3');

    // [Q.009-013] Número Sequencial do Registro no Lote — 5 num
    sb.write(_numerico(seq.toString(), 5));

    // [Q.014-014] Segmento = Q — 1 alfa
    sb.write('Q');

    // [Q.015-015] Uso FEBRABAN — 1 branco
    sb.write(' ');

    // [Q.016-017] Código do Movimento = 01 — 2 num
    sb.write('01');

    // [Q.018-018] Tipo de Inscrição Sacado — 1 num (1=CPF, 2=CNPJ)
    sb.write(titulo.tipoInscricaoSacado == TipoInscricao.cpf ? '1' : '2');

    // [Q.019-033] CPF/CNPJ do Sacado — 15 num (zeros à esquerda)
    sb.write(
        _numerico(titulo.cpfCnpjSacado.replaceAll(RegExp(r'\D'), ''), 15));

    // [Q.034-073] Nome do Sacado — 40 alfa
    sb.write(_alfa(titulo.nomeSacado.toUpperCase(), 40));

    // [Q.074-113] Endereço do Sacado — 40 alfa
    final endCompleto =
        '${titulo.enderecoSacado} ${titulo.numeroEnderecoSacado} ${titulo.complementoSacado}'
            .trim();
    sb.write(_alfa(endCompleto.toUpperCase(), 40));

    // [Q.114-128] Bairro do Sacado — 15 alfa
    sb.write(_alfa(titulo.bairroSacado.toUpperCase(), 15));

    // [Q.129-133] CEP do Sacado (5 primeiros dígitos) — 5 num
    final cepLimpo = titulo.cepSacado.replaceAll(RegExp(r'\D'), '');
    sb.write(_numerico(cepLimpo.length >= 5 ? cepLimpo.substring(0, 5) : cepLimpo, 5));

    // [Q.134-136] Sufixo do CEP (3 últimos dígitos) — 3 num
    sb.write(_numerico(cepLimpo.length == 8 ? cepLimpo.substring(5) : '000', 3));

    // [Q.137-151] Cidade do Sacado — 15 alfa
    sb.write(_alfa(titulo.cidadeSacado.toUpperCase(), 15));

    // [Q.152-153] UF do Sacado — 2 alfa
    sb.write(_alfa(titulo.ufSacado.toUpperCase(), 2));

    // [Q.154-158] Tipo de Inscrição Sacador/Avalista — 1 num + zeros
    if (titulo.nomeAvalista.isNotEmpty && titulo.cpfCnpjAvalista.isNotEmpty) {
      sb.write(titulo.tipoInscricaoAvalista == TipoInscricao.cpf ? '1' : '2');

      // [Q.159-173] CPF/CNPJ Sacador/Avalista — 15 num
      sb.write(_numerico(
          titulo.cpfCnpjAvalista.replaceAll(RegExp(r'\D'), ''), 15));

      // [Q.174-213] Nome Sacador/Avalista — 40 alfa
      sb.write(_alfa(titulo.nomeAvalista.toUpperCase(), 40));
    } else {
      sb.write('0');
      sb.write(_numerico('0', 15));
      sb.write(_brancos(40));
    }

    // [Q.214-216] Código do Banco Correspondente — 3 zeros
    sb.write('000');

    // [Q.217-231] Nosso Número no Banco Correspondente — 15 brancos
    sb.write(_brancos(15));

    // [Q.232-240] Uso FEBRABAN — 9 brancos
    sb.write(_brancos(9));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Segmento Q [${titulo.seuNumero}]: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // SEGMENTO R — Desconto / Juros / Multa
  // ══════════════════════════════════════════════════════════════
  String _buildSegmentoR(Titulo titulo, int seq) {
    final sb = StringBuffer();

    // [R.001-003] Código do Banco — 3 num
    sb.write('033');

    // [R.004-007] Número do Lote — 4 num
    sb.write('0001');

    // [R.008-008] Tipo de Registro = 3 — 1 num
    sb.write('3');

    // [R.009-013] Número Sequencial do Registro — 5 num
    sb.write(_numerico(seq.toString(), 5));

    // [R.014-014] Segmento = R — 1 alfa
    sb.write('R');

    // [R.015-015] Uso FEBRABAN — 1 branco
    sb.write(' ');

    // [R.016-017] Código do Movimento = 01 — 2 num
    sb.write('01');

    // [R.018-019] Código Desconto 2 = 00 — 2 num
    sb.write('00');

    // [R.020-027] Data Desconto 2 — 8 zeros
    sb.write('00000000');

    // [R.028-042] Valor Desconto 2 — 15 zeros
    sb.write(_valor(0.0, 15));

    // [R.043-044] Código Desconto 3 = 00 — 2 num
    sb.write('00');

    // [R.045-052] Data Desconto 3 — 8 zeros
    sb.write('00000000');

    // [R.053-067] Valor Desconto 3 — 15 zeros
    sb.write(_valor(0.0, 15));

    // [R.068-082] Valor IOF — 15 zeros
    sb.write(_valor(0.0, 15));

    // [R.083-097] Valor Abatimento — 15 zeros
    sb.write(_valor(0.0, 15));

    // [R.098-099] Código Multa — 2 num (00=Sem, 01=Valor, 02=Percentual)
    final codMulta = titulo.codigoMulta == '0'
        ? '00'
        : titulo.codigoMulta.padLeft(2, '0');
    sb.write(codMulta);

    // [R.100-107] Data da Multa (DDMMAAAA) — 8 num
    if (titulo.codigoMulta != '0' && titulo.dataMulta != null) {
      sb.write(ValidadorData.formatarCNAB(titulo.dataMulta));
    } else {
      sb.write('00000000');
    }

    // [R.108-122] Valor/Percentual Multa — 15 num
    sb.write(
        _valor(titulo.codigoMulta != '0' ? titulo.valorMulta : 0.0, 15));

    // [R.123-142] Informação ao Sacado linha 1 — 20 alfa
    sb.write(_alfa(titulo.mensagem1, 20));

    // [R.143-172] Mensagem 3 — 30 alfa
    final msg2 = titulo.mensagem2.length > 30
        ? titulo.mensagem2.substring(0, 30)
        : titulo.mensagem2;
    sb.write(_alfa(msg2, 30));

    // [R.173-202] Mensagem 4 — 30 brancos
    sb.write(_brancos(30));

    // [R.203-212] Brancos — 10
    sb.write(_brancos(10));

    // [R.213-217] Código Ocorrência do Sacado — 5 brancos
    sb.write(_brancos(5));

    // [R.218-240] Uso FEBRABAN — 23 brancos
    sb.write(_brancos(23));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Segmento R [${titulo.seuNumero}]: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // TRAILER DE LOTE
  // ══════════════════════════════════════════════════════════════
  String _buildTrailerLote(int proximoSeq) {
    final sb = StringBuffer();

    // Total de registros no lote: headers + detalhe + trailers
    int totalRegistrosDetalhe = 0;
    for (final t in titulos) {
      totalRegistrosDetalhe += t.precisaSegmentoR ? 3 : 2;
    }
    // 1 header lote + detalhes + 1 trailer lote
    int totalRegistrosLote = 1 + totalRegistrosDetalhe + 1;

    double valorTotal = titulos.fold(0.0, (s, t) => s + t.valorNominal);

    // [TL.001-003] Código do Banco — 3 num
    sb.write('033');

    // [TL.004-007] Número do Lote — 4 num
    sb.write('0001');

    // [TL.008-008] Tipo de Registro = 5 — 1 num
    sb.write('5');

    // [TL.009-017] Uso FEBRABAN — 9 brancos
    sb.write(_brancos(9));

    // [TL.018-023] Quantidade de Registros no Lote — 6 num
    sb.write(_numerico(totalRegistrosLote.toString(), 6));

    // [TL.024-041] Quantidade de Títulos Cobrança Simples — 18 num
    sb.write(_numerico(titulos.length.toString(), 18));

    // [TL.042-059] Valor Total dos Títulos — 18 num (2 decimais)
    sb.write(_valorLong(valorTotal, 18));

    // [TL.060-077] Qtd Títulos em Carteira — 18 num
    sb.write(_numerico(titulos.length.toString(), 18));

    // [TL.078-095] Valor em Carteira — 18 num
    sb.write(_valorLong(valorTotal, 18));

    // [TL.096-113] Qtd Títulos Cobrança Simples — 18 num
    sb.write(_numerico(titulos.length.toString(), 18));

    // [TL.114-131] Valor Cobrança Simples — 18 num
    sb.write(_valorLong(valorTotal, 18));

    // [TL.132-240] Brancos — 109 brancos
    sb.write(_brancos(109));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Trailer lote: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // TRAILER DE ARQUIVO
  // ══════════════════════════════════════════════════════════════
  String _buildTrailerArquivo(int totalRegistros) {
    final sb = StringBuffer();

    // [TA.001-003] Código do Banco — 3 num
    sb.write('033');

    // [TA.004-007] Lote = 9999 — 4 num
    sb.write('9999');

    // [TA.008-008] Tipo de Registro = 9 — 1 num
    sb.write('9');

    // [TA.009-017] Uso FEBRABAN — 9 brancos
    sb.write(_brancos(9));

    // [TA.018-023] Quantidade de Lotes = 000001 — 6 num
    sb.write('000001');

    // [TA.024-029] Quantidade de Registros (total arquivo) — 6 num
    sb.write(_numerico(totalRegistros.toString(), 6));

    // [TA.030-035] Qtd Contas para Conciliação — 6 zeros
    sb.write('000000');

    // [TA.036-240] Uso FEBRABAN — 205 brancos
    sb.write(_brancos(205));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Trailer arquivo: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // NOSSO NÚMERO SANTANDER
  // ══════════════════════════════════════════════════════════════
  /// Monta o campo Nosso Número no formato Santander:
  /// Carteira(3) + NossoNumero(12) + DAC(1) = 16 chars
  String _buildNossoNumeroCNAB(Titulo titulo) {
    final carteira = empresa.carteira.padLeft(3, '0');
    final nossoNum = titulo.seuNumero
        .replaceAll(RegExp(r'\D'), '')
        .padLeft(12, '0')
        .substring(0,
            titulo.seuNumero.replaceAll(RegExp(r'\D'), '').length > 12
                ? 12
                : titulo.seuNumero.replaceAll(RegExp(r'\D'), '').length > 12
                    ? 12
                    : titulo.seuNumero.replaceAll(RegExp(r'\D'), '').length);
    final nossoNumPadded = nossoNum.padLeft(12, '0').substring(
        nossoNum.padLeft(12, '0').length > 12
            ? nossoNum.padLeft(12, '0').length - 12
            : 0);

    final dac = calcularDacSantander(
      empresa.agencia.padLeft(4, '0'),
      empresa.contaCorrente.padLeft(8, '0'),
      carteira,
      nossoNumPadded,
    );

    return '$carteira$nossoNumPadded$dac';
  }

  /// Calcula o DAC (Dígito de Auto-Conferência) Santander
  /// Base: Agência(4) + Conta(8) + Carteira(3) + NossoNumero(12)
  /// Algoritmo: Módulo 11 pesos 2-9 ciclicamente da direita para a esquerda
  static String calcularDacSantander(
    String agencia,
    String conta,
    String carteira,
    String nossoNumero,
  ) {
    final base = '${agencia.padLeft(4, '0')}'
        '${conta.padLeft(8, '0')}'
        '${carteira.padLeft(3, '0')}'
        '${nossoNumero.padLeft(12, '0')}';

    int soma = 0;
    int peso = 2;
    for (int i = base.length - 1; i >= 0; i--) {
      soma += int.parse(base[i]) * peso;
      peso = peso == 9 ? 2 : peso + 1;
    }

    int resto = soma % 11;
    if (resto == 0 || resto == 1) return '0';
    return (11 - resto).toString();
  }

  // ══════════════════════════════════════════════════════════════
  // HELPERS DE FORMATAÇÃO
  // ══════════════════════════════════════════════════════════════

  /// Formata string alfanumérica: trunca ou preenche com espaços à direita
  String _alfa(String valor, int tamanho) {
    final limpo = valor
        .replaceAll(RegExp(r'[^\x20-\x7E\u00C0-\u024F]'), ' ')
        .trim();
    if (limpo.length >= tamanho) return limpo.substring(0, tamanho);
    return limpo.padRight(tamanho);
  }

  /// Formata valor numérico: zeros à esquerda
  String _numerico(String valor, int tamanho) {
    final apenasNum = valor.replaceAll(RegExp(r'\D'), '');
    if (apenasNum.length >= tamanho) {
      return apenasNum.substring(apenasNum.length - tamanho);
    }
    return apenasNum.padLeft(tamanho, '0');
  }

  /// Formata brancos
  String _brancos(int quantidade) => ' ' * quantidade;

  /// Formata valor monetário: remove vírgula/ponto, preenche zeros à esquerda
  /// Ex: 1234.56 → "000000000123456" (15 dígitos)
  String _valor(double valor, int tamanho) {
    final centavos = (valor * 100).round();
    return centavos.toString().padLeft(tamanho, '0');
  }

  /// Formata valor monetário para campos de 18 dígitos (trailer)
  String _valorLong(double valor, int tamanho) {
    final centavos = (valor * 100).round();
    return centavos.toString().padLeft(tamanho, '0');
  }

  /// Retorna nome do arquivo no padrão Santander: CB033AAAAMMDD_NNN.REM
  String getNomeArquivo() {
    final data =
        '${dataGeracao.year}${dataGeracao.month.toString().padLeft(2, '0')}${dataGeracao.day.toString().padLeft(2, '0')}';
    final seq = empresa.numeroSequencial.toString().padLeft(3, '0');
    return 'CB033${data}_$seq.REM';
  }

  /// Calcula total de linhas do arquivo
  int getTotalLinhas() {
    int linhasDetalhe = 0;
    for (final t in titulos) {
      linhasDetalhe += t.precisaSegmentoR ? 3 : 2;
    }
    return 1 + 1 + linhasDetalhe + 1 + 1; // HA + HL + detalhe + TL + TA
  }
}
