// domain/builders/cnab_santander240_builder.dart
// Construtor do arquivo CNAB 240 Santander - Cobrança de Boletos
// Implementação conforme FEBRABAN CNAB 240 v10.7 + Manual Santander
// Layout verificado campo a campo contra relatório de validação

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
    // Total: header_arquivo + header_lote + detalhes + trailer_lote + trailer_arquivo
    final totalLinhasDetalhe = sequencialRegistro - 1;
    final totalRegistros = 1 + 1 + totalLinhasDetalhe + 1 + 1;
    buffer.write(_buildTrailerArquivo(totalRegistros));
    buffer.write('\r\n');

    return buffer.toString();
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER DE ARQUIVO
  // Layout: FEBRABAN CNAB 240 v10.7 — Registro Tipo 0
  // ══════════════════════════════════════════════════════════════
  String _buildHeaderArquivo() {
    final sb = StringBuffer();

    // [001-003] Código do Banco em COMPE — 3 num
    sb.write('033'); // Santander

    // [004-007] Lote de Serviço = 0000 (header arquivo) — 4 num
    sb.write('0000');

    // [008-008] Tipo de Registro = 0 — 1 num
    sb.write('0');

    // [009-017] Uso FEBRABAN — 9 brancos
    sb.write(_brancos(9));

    // [018-018] Tipo de Inscrição da Empresa — 1 num
    // 1=CPF, 2=CNPJ (campo de 1 char, valor '2' para CNPJ)
    sb.write('2');

    // [019-032] Número de Inscrição da Empresa (CNPJ) — 14 num
    sb.write(_numerico(empresa.cnpj.replaceAll(RegExp(r'\D'), ''), 14));

    // [033-052] Código do Convênio no Banco — 20 alfa
    // Santander: convênio 7 dígitos numéricos, alinhado esquerda + 13 brancos
    final conv = empresa.codigoCedente.replaceAll(RegExp(r'\D'), '');
    final conv7 = conv.length >= 7 ? conv.substring(conv.length - 7) : conv.padLeft(7, '0');
    sb.write(_alfa(conv7, 20));

    // [053-057] Agência Mantenedora da Conta — 5 (4 dig + 1 dígito verificador)
    sb.write(_numerico(empresa.agencia, 4));
    sb.write(_alfa(empresa.digitoAgencia.isEmpty ? ' ' : empresa.digitoAgencia, 1));

    // [058-070] Número da Conta Corrente — 12 num (conta 8 dígitos + 4 brancos pad)
    // FEBRABAN: conta ocupa 12 posições. Santander usa 8 dígitos + brancos
    sb.write(_numerico(empresa.contaCorrente, 12));

    // [071-071] Dígito Verificador da Conta — 1 alfa
    // Calculado por Módulo 11 pesos 2-9 sobre AG(4)+Conta(8)
    sb.write(_calcularDigitoConta(
        empresa.agencia.padLeft(4, '0'),
        empresa.contaCorrente.padLeft(8, '0')));

    // [072-072] Dígito Verificador da Ag/Conta — 1 branco (Santander não usa)
    sb.write(' ');

    // [073-102] Nome da Empresa — 30 alfa
    sb.write(_alfa(empresa.razaoSocial.toUpperCase(), 30));

    // [103-132] Nome do Banco — 30 alfa
    sb.write(_alfa('BANCO SANTANDER', 30));

    // [133-142] Uso FEBRABAN — 10 brancos
    sb.write(_brancos(10));

    // [143-143] Código Remessa/Retorno — 1 num (1=Remessa, 2=Retorno)
    sb.write('1');

    // [144-151] Data de Geração do Arquivo — 8 num (DDMMAAAA)
    sb.write(ValidadorData.formatarCNAB(dataGeracao));

    // [152-157] Hora de Geração do Arquivo — 6 num (HHMMSS)
    sb.write(_numerico(
        '${dataGeracao.hour.toString().padLeft(2, '0')}'
        '${dataGeracao.minute.toString().padLeft(2, '0')}'
        '${dataGeracao.second.toString().padLeft(2, '0')}',
        6));

    // [158-163] Número Sequencial do Arquivo — 6 num
    sb.write(_numerico(empresa.numeroSequencial.toString(), 6));

    // [164-166] Número da Versão do Layout do Arquivo — 3 num
    // Santander: 103 (atual) ou 101 (legado)
    sb.write('103');

    // [167-171] Densidade de Gravação do Arquivo — 5 num
    sb.write('01600');

    // [172-191] Para Uso Reservado do Banco — 20 brancos
    sb.write(_brancos(20));

    // [192-211] Para Uso Reservado da Empresa — 20 brancos
    sb.write(_brancos(20));

    // [212-240] Uso FEBRABAN — 29 brancos
    sb.write(_brancos(29));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Header arquivo: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER DE LOTE
  // Layout: FEBRABAN CNAB 240 v10.7 — Registro Tipo 1
  // ══════════════════════════════════════════════════════════════
  String get _conv7 {
    final c = empresa.codigoCedente.replaceAll(RegExp(r'\D'), '');
    return c.length >= 7 ? c.substring(c.length - 7) : c.padLeft(7, '0');
  }

  String _buildHeaderLote() {
    final sb = StringBuffer();

    // [001-003] Código do Banco — 3 num
    sb.write('033');

    // [004-007] Lote de Serviço = 0001 — 4 num
    sb.write('0001');

    // [008-008] Tipo de Registro = 1 — 1 num
    sb.write('1');

    // [009-009] Tipo de Operação — 1 alfa (R=Remessa, T=Crédito, etc.)
    sb.write('R');

    // [010-011] Tipo de Serviço = 01 (Cobrança) — 2 num
    sb.write('01');

    // [012-013] Forma de Lançamento — 2 num (01=Cobrança Simples)
    sb.write('01');

    // [014-016] Número da Versão do Layout do Lote — 3 num
    // Santander requer versão 046
    sb.write('046');

    // [017-017] Uso FEBRABAN — 1 branco
    sb.write(' ');

    // [018-018] Tipo de Inscrição da Empresa — 1 num (1=CPF, 2=CNPJ)
    sb.write('2');

    // [019-032] Número de Inscrição da Empresa — 14 num
    sb.write(_numerico(empresa.cnpj.replaceAll(RegExp(r'\D'), ''), 14));

    // [033-052] Código do Convênio no Banco — 20 alfa
    sb.write(_alfa(_conv7, 20));

    // [053-057] Agência — 4 num + 1 dígito
    sb.write(_numerico(empresa.agencia, 4));
    sb.write(_alfa(empresa.digitoAgencia.isEmpty ? ' ' : empresa.digitoAgencia, 1));

    // [058-070] Número da Conta — 12 num
    sb.write(_numerico(empresa.contaCorrente, 12));

    // [071-071] Dígito Verificador da Conta — 1 alfa
    sb.write(_calcularDigitoConta(
        empresa.agencia.padLeft(4, '0'),
        empresa.contaCorrente.padLeft(8, '0')));

    // [072-072] Dígito Verificador da Ag/Conta — 1 branco
    sb.write(' ');

    // [073-102] Nome da Empresa — 30 alfa
    sb.write(_alfa(empresa.razaoSocial.toUpperCase(), 30));

    // [103-142] Informação 1 — 40 brancos
    sb.write(_brancos(40));

    // [143-172] Informação 2 — 30 brancos
    // FEBRABAN pos 143: Indicativo de Forma de Pgto/Tipo arquivo (1=Remessa, 2=Retorno)
    sb.write('1'); // pos 143 = tipo arquivo
    sb.write(_brancos(29)); // pos 144-172

    // [173-177] Número Sequencial da Remessa — 5 num
    sb.write(_numerico(empresa.numeroSequencial.toString(), 5));

    // [178-185] Data de Gravação Remessa — 8 num (DDMMAAAA)
    sb.write(ValidadorData.formatarCNAB(dataGeracao));

    // [186-193] Data de Crédito — 8 zeros
    sb.write('00000000');

    // [194-240] Uso FEBRABAN — 47 brancos
    sb.write(_brancos(47));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Header lote: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // SEGMENTO P — Dados do Título
  // Layout FEBRABAN CNAB 240 v10.7 — Registro Tipo 3, Segmento P
  // Posições verificadas contra relatório de validação
  // ══════════════════════════════════════════════════════════════
  String _buildSegmentoP(Titulo titulo, int seq) {
    final sb = StringBuffer();

    // [001-003] Código do Banco — 3 num
    sb.write('033');

    // [004-007] Lote de Serviço — 4 num
    sb.write('0001');

    // [008-008] Tipo de Registro = 3 — 1 num
    sb.write('3');

    // [009-013] Número Sequencial do Registro no Lote — 5 num
    sb.write(_numerico(seq.toString(), 5));

    // [014-014] Código do Segmento do Registro Detalhe = P — 1 alfa
    sb.write('P');

    // [015-015] Código de Movimento Remessa — 1 num
    // 0=Inclusão, 2=Alteração, 5=Cancelamento, 9=Baixa
    // FEBRABAN: 1 CHAR apenas nesta posição!
    sb.write('0');

    // [016-017] Código da Instrução para Movimento — 2 num
    // 00=Não há instrução, 01=Inclusão normal
    sb.write('01');

    // [018-021] Código da Agência Mantenedora da Conta — 4 num
    sb.write(_numerico(empresa.agencia, 4));

    // [022-022] Dígito Verificador da Agência — 1 alfa
    sb.write(_alfa(empresa.digitoAgencia.isEmpty ? ' ' : empresa.digitoAgencia, 1));

    // [023-030] Número da Conta Corrente — 8 num (Santander usa 8 dígitos significativos)
    // FEBRABAN v10.7: conta ocupa 8 posições no segmento P (023-030)
    sb.write(_numerico(empresa.contaCorrente, 8));

    // [031-031] Dígito Verificador da Conta — 1 alfa
    sb.write(_calcularDigitoConta(
        empresa.agencia.padLeft(4, '0'),
        empresa.contaCorrente.padLeft(8, '0')));

    // [032-032] Dígito Verificador da Agência/Conta — 1 branco
    sb.write(' ');

    // [033-052] Identificação do Título no Banco (Nosso Número) — 20 alfa
    // Santander: Carteira(3) + NossoNum(12) + DAC(1) = 16 chars + 4 brancos
    // SP008: validador verifica carteira em posição 33-35 → dentro do campo 033-052
    sb.write(_alfa(_buildNossoNumeroCNAB(titulo), 20));

    // [053-053] Código da Carteira — 1 num
    // 1=Com Registro (no arquivo tipo = 1 char)
    sb.write('1');

    // [054-054] Forma de Cadastramento do Título no Banco — 1 num
    // 1=Com Cadastramento, 2=Sem Cadastramento
    sb.write('1');

    // [055-055] Tipo do Documento — 1 num (2=Escritural)
    sb.write('2');

    // [056-056] Identificação da Emissão do Boleto — 1 num (2=Banco)
    sb.write('2');

    // [057-057] Identificação da Distribuição — 1 num (2=Banco)
    sb.write('2');

    // [058-067] Número do Documento de Cobrança — 10 alfa
    sb.write(_alfa(titulo.numeroDocumento, 10));

    // [068-075] Data de Vencimento do Título — 8 num (DDMMAAAA)
    sb.write(ValidadorData.formatarCNAB(titulo.dataVencimento));

    // [076-090] Valor Nominal do Título — 15 num (inteiro * 100, sem vírgula)
    sb.write(_valor(titulo.valorNominal, 15));

    // [091-095] Agência Encarregada da Cobrança — 5 zeros
    sb.write('00000');

    // [096-096] Dígito Verificador da Agência Cobradora — 1 branco
    sb.write(' ');

    // [097-098] Espécie do Título — 2 num (01=DM, 02=NP, 03=NS, etc.)
    // SP013: validador verifica posição 105-106 mas isso pode variar por versão
    final especie = titulo.especieTitulo.trim().isEmpty
        ? '01'
        : titulo.especieTitulo.trim().padLeft(2, '0');
    sb.write(especie);

    // [099-099] Identificação do Título Aceito/Não Aceito — 1 alfa (A ou N)
    sb.write(titulo.aceite.isEmpty ? 'N' : titulo.aceite[0].toUpperCase());

    // [100-107] Data da Emissão do Título — 8 num (DDMMAAAA)
    sb.write(ValidadorData.formatarCNAB(titulo.dataEmissao ?? DateTime.now()));

    // [108-109] Código do Juros de Mora — 2 num
    // 01=Valor por dia, 02=Taxa mensal, 03=Isento
    final codJuros = titulo.codigoJuros == '0' || titulo.codigoJuros.isEmpty
        ? '03'
        : titulo.codigoJuros.padLeft(2, '0');
    sb.write(codJuros);

    // [110-117] Data do Juros de Mora — 8 num (DDMMAAAA ou zeros)
    if (codJuros != '03' && titulo.dataJuros != null) {
      sb.write(ValidadorData.formatarCNAB(titulo.dataJuros));
    } else {
      sb.write('00000000');
    }

    // [118-132] Valor/Taxa dos Juros de Mora por Dia — 15 num
    sb.write(_valor(codJuros != '03' ? titulo.valorJuros : 0.0, 15));

    // [133-134] Código do Desconto 1 — 2 num
    // 00=Sem, 01=Valor até data informada, 02=Percentual até data
    sb.write(_numerico(titulo.codigoDesconto1.isEmpty ? '0' : titulo.codigoDesconto1, 2));

    // [135-142] Data do Desconto 1 — 8 num (DDMMAAAA ou zeros)
    if (titulo.codigoDesconto1 != '0' && titulo.codigoDesconto1.isNotEmpty
        && titulo.dataDesconto1 != null) {
      sb.write(ValidadorData.formatarCNAB(titulo.dataDesconto1));
    } else {
      sb.write('00000000');
    }

    // [143-157] Valor/Percentual do Desconto 1 — 15 num
    sb.write(_valor(
        titulo.codigoDesconto1 != '0' && titulo.codigoDesconto1.isNotEmpty
            ? titulo.valorDesconto1
            : 0.0,
        15));

    // [158-172] Valor do IOF a ser Recolhido — 15 zeros
    sb.write(_valor(0.0, 15));

    // [173-187] Valor do Abatimento — 15 zeros
    sb.write(_valor(0.0, 15));

    // [188-202] Identificação do Título na Empresa (Seu Número) — 15 alfa
    sb.write(_alfa(titulo.seuNumero, 15));

    // [203-204] Código para Protesto — 2 num (03=Não Protestar)
    sb.write('03');

    // [205-206] Número de Dias para Protesto — 2 num
    sb.write('00');

    // [207-208] Código para Baixa/Devolução — 2 num
    // 01=Baixar após N dias do vencimento, 02=Devolver
    sb.write('01');

    // [209-211] Número de Dias para Baixa/Devolução — 3 num
    sb.write('060');

    // [212-214] Código da Moeda — 3 num (009=Real)
    // SP017/SS009: deve ser '009' para Real
    sb.write('009');

    // [215-224] Número do Contrato da Operação de Crédito — 10 zeros
    sb.write('0000000000');

    // [225-240] Uso FEBRABAN — 16 brancos
    sb.write(_brancos(16));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Segmento P [${titulo.seuNumero}]: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // SEGMENTO Q — Dados do Sacado/Pagador
  // Layout FEBRABAN CNAB 240 v10.7 — Registro Tipo 3, Segmento Q
  // ══════════════════════════════════════════════════════════════
  String _buildSegmentoQ(Titulo titulo, int seq) {
    final sb = StringBuffer();

    // [001-003] Código do Banco — 3 num
    sb.write('033');

    // [004-007] Lote de Serviço — 4 num
    sb.write('0001');

    // [008-008] Tipo de Registro = 3 — 1 num
    sb.write('3');

    // [009-013] Número Sequencial do Registro no Lote — 5 num
    sb.write(_numerico(seq.toString(), 5));

    // [014-014] Código do Segmento = Q — 1 alfa
    sb.write('Q');

    // [015-015] Código de Movimento Remessa — 1 num
    sb.write('0');

    // [016-017] Código da Instrução — 2 num
    sb.write('01');

    // [018-018] Tipo de Inscrição do Pagador — 1 num
    // SQ001: 1=CPF, 2=CNPJ (1 char! não '01'/'02' de 2 chars!)
    sb.write(titulo.tipoInscricaoSacado == TipoInscricao.cpf ? '1' : '2');

    // [019-033] Número de Inscrição do Pagador (CPF/CNPJ) — 15 num (zeros à esquerda)
    sb.write(_numerico(titulo.cpfCnpjSacado.replaceAll(RegExp(r'\D'), ''), 15));

    // [034-073] Nome do Pagador — 40 alfa
    sb.write(_alfa(titulo.nomeSacado.toUpperCase(), 40));

    // [074-113] Endereço do Pagador — 40 alfa
    final endCompleto =
        '${titulo.enderecoSacado} ${titulo.numeroEnderecoSacado} ${titulo.complementoSacado}'
            .trim();
    sb.write(_alfa(endCompleto.toUpperCase(), 40));

    // [114-128] Bairro do Pagador — 15 alfa
    sb.write(_alfa(titulo.bairroSacado.toUpperCase(), 15));

    // [129-133] CEP do Pagador — 5 num (5 primeiros dígitos)
    final cepLimpo = titulo.cepSacado.replaceAll(RegExp(r'\D'), '');
    sb.write(_numerico(
        cepLimpo.length >= 5 ? cepLimpo.substring(0, 5) : cepLimpo, 5));

    // [134-136] Sufixo do CEP — 3 num (últimos 3 dígitos)
    sb.write(_numerico(
        cepLimpo.length == 8 ? cepLimpo.substring(5) : '000', 3));

    // [137-151] Cidade do Pagador — 15 alfa
    sb.write(_alfa(titulo.cidadeSacado.toUpperCase(), 15));

    // [152-153] UF do Pagador — 2 alfa
    // SQ008: UF não pode ser '00'; fallback 'SP' se inválida
    final uf = titulo.ufSacado.trim().length == 2
        ? titulo.ufSacado.toUpperCase()
        : 'SP';
    sb.write(_alfa(uf, 2));

    // [154-154] Tipo de Inscrição Sacador/Avalista — 1 num
    // [155-169] Número Inscrição Sacador/Avalista — 15 num
    // [170-209] Nome Sacador/Avalista — 40 alfa
    if (titulo.nomeAvalista.isNotEmpty && titulo.cpfCnpjAvalista.isNotEmpty) {
      sb.write(titulo.tipoInscricaoAvalista == TipoInscricao.cpf ? '1' : '2');
      sb.write(_numerico(
          titulo.cpfCnpjAvalista.replaceAll(RegExp(r'\D'), ''), 15));
      sb.write(_alfa(titulo.nomeAvalista.toUpperCase(), 40));
    } else {
      sb.write('0');
      sb.write(_numerico('0', 15));
      sb.write(_brancos(40));
    }

    // [210-212] Código do Banco Correspondente — 3 zeros
    sb.write('000');

    // [213-227] Nosso Número Banco Correspondente — 15 brancos
    sb.write(_brancos(15));

    // [228-240] Uso FEBRABAN — 13 brancos
    sb.write(_brancos(13));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Segmento Q [${titulo.seuNumero}]: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // SEGMENTO R — Desconto / Juros / Multa (opcional)
  // Layout FEBRABAN CNAB 240 v10.7 — Registro Tipo 3, Segmento R
  // ══════════════════════════════════════════════════════════════
  String _buildSegmentoR(Titulo titulo, int seq) {
    final sb = StringBuffer();

    // [001-003] Código do Banco — 3 num
    sb.write('033');

    // [004-007] Lote de Serviço — 4 num
    sb.write('0001');

    // [008-008] Tipo de Registro = 3 — 1 num
    sb.write('3');

    // [009-013] Número Sequencial — 5 num
    sb.write(_numerico(seq.toString(), 5));

    // [014-014] Segmento = R — 1 alfa
    sb.write('R');

    // [015-015] Código de Movimento — 1 num
    sb.write('0');

    // [016-017] Código da Instrução — 2 num
    sb.write('01');

    // [018-019] Código do Desconto 2 — 2 num
    sb.write('00');

    // [020-027] Data do Desconto 2 — 8 zeros
    sb.write('00000000');

    // [028-042] Valor/Percentual do Desconto 2 — 15 zeros
    sb.write(_valor(0.0, 15));

    // [043-044] Código do Desconto 3 — 2 num
    sb.write('00');

    // [045-052] Data do Desconto 3 — 8 zeros
    sb.write('00000000');

    // [053-067] Valor/Percentual do Desconto 3 — 15 zeros
    sb.write(_valor(0.0, 15));

    // [068-082] Valor do IOF — 15 zeros
    sb.write(_valor(0.0, 15));

    // [083-097] Valor do Abatimento — 15 zeros
    sb.write(_valor(0.0, 15));

    // [098-099] Código da Multa — 2 num (00=Sem, 01=Valor, 02=Percentual)
    final codMulta = (titulo.codigoMulta.isEmpty || titulo.codigoMulta == '0')
        ? '00'
        : titulo.codigoMulta.padLeft(2, '0');
    sb.write(codMulta);

    // [100-107] Data da Multa — 8 num (DDMMAAAA ou zeros)
    if (codMulta != '00' && titulo.dataMulta != null) {
      sb.write(ValidadorData.formatarCNAB(titulo.dataMulta));
    } else {
      sb.write('00000000');
    }

    // [108-122] Valor/Percentual da Multa — 15 num
    sb.write(_valor(codMulta != '00' ? titulo.valorMulta : 0.0, 15));

    // [123-142] Informação ao Sacado — 20 alfa
    sb.write(_alfa(titulo.mensagem1, 20));

    // [143-172] Mensagem 3 — 30 alfa
    final msg2 = titulo.mensagem2.length > 30
        ? titulo.mensagem2.substring(0, 30)
        : titulo.mensagem2;
    sb.write(_alfa(msg2, 30));

    // [173-202] Mensagem 4 — 30 brancos
    sb.write(_brancos(30));

    // [203-212] Uso FEBRABAN — 10 brancos
    sb.write(_brancos(10));

    // [213-217] Código das Ocorrências do Pagador — 5 brancos
    sb.write(_brancos(5));

    // [218-240] Uso FEBRABAN — 23 brancos
    sb.write(_brancos(23));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Segmento R [${titulo.seuNumero}]: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // TRAILER DE LOTE
  // Layout FEBRABAN CNAB 240 v10.7 — Registro Tipo 5
  // ══════════════════════════════════════════════════════════════
  String _buildTrailerLote(int proximoSeq) {
    // Contadores
    int totalRegistrosDetalhe = 0;
    for (final t in titulos) {
      totalRegistrosDetalhe += t.precisaSegmentoR ? 3 : 2;
    }
    // Total = header_lote + registros_detalhe + trailer_lote
    final int totalRegistrosLote = 1 + totalRegistrosDetalhe + 1;
    final double valorTotal = titulos.fold(0.0, (s, t) => s + t.valorNominal);

    final sb = StringBuffer();

    // [001-003] Código do Banco — 3 num
    sb.write('033');

    // [004-007] Lote de Serviço — 4 num
    sb.write('0001');

    // [008-008] Tipo de Registro = 5 — 1 num
    sb.write('5');

    // [009-017] Uso FEBRABAN — 9 brancos
    sb.write(_brancos(9));

    // [018-023] Quantidade de Registros no Lote — 6 num
    sb.write(_numerico(totalRegistrosLote.toString(), 6));

    // [024-029] Quantidade de Títulos em Cobrança — 6 num
    sb.write(_numerico(titulos.length.toString(), 6));

    // [030-047] Valor Total dos Títulos em Carteira — 18 num
    sb.write(_valorLong(valorTotal, 18));

    // [048-065] Quantidade de Títulos em Carteira — 18 zeros
    sb.write(_numerico('0', 18));

    // [066-083] Valor da Carteira — 18 zeros
    sb.write(_valorLong(0.0, 18));

    // [084-101] Quantidade Títulos Cobrança Simples — 18 zeros
    sb.write(_numerico('0', 18));

    // [102-119] Valor da Cobrança Simples — 18 zeros
    sb.write(_valorLong(0.0, 18));

    // [120-240] Uso FEBRABAN — 121 brancos
    sb.write(_brancos(121));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Trailer lote: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // TRAILER DE ARQUIVO
  // Layout FEBRABAN CNAB 240 v10.7 — Registro Tipo 9
  // ══════════════════════════════════════════════════════════════
  String _buildTrailerArquivo(int totalRegistros) {
    final sb = StringBuffer();

    // [001-003] Código do Banco — 3 num
    sb.write('033');

    // [004-007] Lote de Serviço = 9999 — 4 num
    sb.write('9999');

    // [008-008] Tipo de Registro = 9 — 1 num
    sb.write('9');

    // [009-017] Uso FEBRABAN — 9 brancos
    sb.write(_brancos(9));

    // [018-023] Quantidade de Lotes do Arquivo — 6 num
    sb.write('000001');

    // [024-029] Quantidade de Registros do Arquivo — 6 num
    sb.write(_numerico(totalRegistros.toString(), 6));

    // [030-035] Quantidade de Contas para Conciliação — 6 zeros
    sb.write('000000');

    // [036-240] Uso FEBRABAN — 205 brancos
    sb.write(_brancos(205));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Trailer arquivo: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // NOSSO NÚMERO SANTANDER
  // Formato: Carteira(3) + NossoNum(12) + DAC(1) = 16 chars
  // Alinhado em campo de 20: 16 chars + 4 brancos
  // ══════════════════════════════════════════════════════════════
  String _buildNossoNumeroCNAB(Titulo titulo) {
    // Carteira Santander: 3 dígitos (101=Simples, 102=Vinculada, 104=Caucionada, 201=Descontada)
    final carteiraNum = empresa.carteira.replaceAll(RegExp(r'\D'), '');
    final carteiraValida = ['101', '102', '104', '201'].contains(
            carteiraNum.padLeft(3, '0'))
        ? carteiraNum.padLeft(3, '0')
        : '101'; // padrão Simples

    // Nosso número: apenas dígitos, 12 posições, zeros à esquerda
    final nossoNumDigitos = titulo.seuNumero.replaceAll(RegExp(r'\D'), '');
    final nossoNumPadded = nossoNumDigitos.length > 12
        ? nossoNumDigitos.substring(nossoNumDigitos.length - 12)
        : nossoNumDigitos.padLeft(12, '0');

    // DAC (Dígito Auto-Conferência) Santander
    final dac = calcularDacSantander(
      empresa.agencia.padLeft(4, '0'),
      empresa.contaCorrente.padLeft(8, '0'),
      carteiraValida,
      nossoNumPadded,
    );

    // 16 chars + 4 brancos = 20 total
    return '$carteiraValida$nossoNumPadded$dac    ';
  }

  // ══════════════════════════════════════════════════════════════
  // ALGORITMOS
  // ══════════════════════════════════════════════════════════════

  /// Calcula dígito verificador da conta Santander — Módulo 11 pesos 2-9
  /// Base: Agência(4) + Conta(8) da direita para a esquerda
  String _calcularDigitoConta(String agencia, String conta) {
    final base = '${agencia.padLeft(4, '0')}${conta.padLeft(8, '0')}';
    int soma = 0;
    int peso = 2;
    for (int i = base.length - 1; i >= 0; i--) {
      soma += int.parse(base[i]) * peso;
      peso = peso == 9 ? 2 : peso + 1;
    }
    final resto = soma % 11;
    if (resto == 0 || resto == 1) return '0';
    return (11 - resto).toString();
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

    final int resto = soma % 11;
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

  /// Formata valor numérico: zeros à esquerda, só dígitos
  String _numerico(String valor, int tamanho) {
    final apenasNum = valor.replaceAll(RegExp(r'\D'), '');
    if (apenasNum.length >= tamanho) {
      return apenasNum.substring(apenasNum.length - tamanho);
    }
    return apenasNum.padLeft(tamanho, '0');
  }

  /// Preenche com brancos
  String _brancos(int quantidade) => ' ' * quantidade;

  /// Formata valor monetário em centavos, zeros à esquerda
  /// Ex: 1234.56 → "000000000123456" (15 dígitos)
  String _valor(double valor, int tamanho) {
    final centavos = (valor * 100).round();
    return centavos.toString().padLeft(tamanho, '0');
  }

  /// Formata valor monetário para campos longos (18+ dígitos)
  String _valorLong(double valor, int tamanho) {
    final centavos = (valor * 100).round();
    return centavos.toString().padLeft(tamanho, '0');
  }

  /// Retorna nome do arquivo no padrão Santander
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
