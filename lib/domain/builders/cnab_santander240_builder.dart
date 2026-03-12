// domain/builders/cnab_santander240_builder.dart
// Construtor do arquivo CNAB 240 Santander - Cobrança de Boletos
// Layout H7815 – CNAB 240 Posições – Versão 8.5 – Fev/2026 (Santander)
// Campos verificados campo a campo contra o manual H7815 V8.5

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
    final totalLinhasDetalhe = sequencialRegistro - 1;
    final totalRegistros = 1 + 1 + totalLinhasDetalhe + 1 + 1;
    buffer.write(_buildTrailerArquivo(totalRegistros));
    buffer.write('\r\n');

    return buffer.toString();
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER DE ARQUIVO
  // Layout H7815 V8.5 — Registro Tipo 0
  // ══════════════════════════════════════════════════════════════
  String _buildHeaderArquivo() {
    final sb = StringBuffer();

    // [001-003] Código do Banco na compensação — 3 num → 033 (Santander)
    sb.write('033');

    // [004-007] Lote de serviço = 0000 (header arquivo) — 4 num
    sb.write('0000');

    // [008-008] Tipo de registro = 0 — 1 num
    sb.write('0');

    // [009-016] Reservado (uso Banco) — 8 brancos
    sb.write(_brancos(8));

    // [017-017] Tipo de inscrição da empresa — 1 num
    // 1=CPF, 2=CNPJ
    sb.write('2'); // CNPJ

    // [018-032] Número de inscrição da empresa (CNPJ) — 15 num (zeros + doc)
    sb.write(_numerico(empresa.cnpj.replaceAll(RegExp(r'\D'), ''), 15));

    // [033-047] Código de Transmissão — 15 alfa
    // Santander fornece este código ao contratar o serviço CNAB
    // Usar convênio (7 dígitos) preenchido à direita com brancos = 15 chars
    final conv = _conv7;
    sb.write(_alfa(conv, 15));

    // [048-072] Reservado (uso Banco) — 25 brancos
    sb.write(_brancos(25));

    // [073-102] Nome da empresa — 30 alfa
    sb.write(_alfa(empresa.razaoSocial.toUpperCase(), 30));

    // [103-132] Nome do Banco — 30 alfa
    sb.write(_alfa('BANCO SANTANDER', 30));

    // [133-142] Reservado (uso Banco) — 10 brancos
    sb.write(_brancos(10));

    // [143-143] Código remessa = 1 (Remessa) — 1 num
    sb.write('1');

    // [144-151] Data de geração do arquivo — 8 num (DDMMAAAA)
    sb.write(ValidadorData.formatarCNAB(dataGeracao));

    // [152-157] Reservado (uso Banco) — 6 brancos
    sb.write(_brancos(6));

    // [158-163] Nº sequencial do arquivo — 6 num
    sb.write(_numerico(empresa.numeroSequencial.toString(), 6));

    // [164-166] Nº da versão do layout do arquivo — 3 num
    // H7815 V8.5: versão 040
    sb.write('040');

    // [167-240] Reservado (uso Banco) — 74 brancos
    sb.write(_brancos(74));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Header arquivo: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER DE LOTE
  // Layout H7815 V8.5 — Registro Tipo 1
  // ══════════════════════════════════════════════════════════════
  String get _conv7 {
    final c = empresa.codigoCedente.replaceAll(RegExp(r'\D'), '');
    return c.length >= 7 ? c.substring(c.length - 7) : c.padLeft(7, '0');
  }

  String _buildHeaderLote() {
    final sb = StringBuffer();

    // [001-003] Código do Banco na compensação — 3 num
    sb.write('033');

    // [004-007] Número do lote remessa — 4 num
    sb.write('0001');

    // [008-008] Tipo de registro = 1 — 1 num
    sb.write('1');

    // [009-009] Tipo de operação — 1 alfa → R=Remessa
    sb.write('R');

    // [010-011] Tipo de serviço — 2 num → 01=Cobrança
    sb.write('01');

    // [012-013] Reservado (uso Banco) — 2 brancos
    sb.write(_brancos(2));

    // [014-016] Nº da versão do layout do lote — 3 num → 030
    sb.write('030');

    // [017-017] Reservado (uso Banco) — 1 branco
    sb.write(' ');

    // [018-018] Tipo de inscrição da empresa — 1 num (1=CPF, 2=CNPJ)
    sb.write('2');

    // [019-033] Inscrição da empresa (CNPJ) — 15 num
    sb.write(_numerico(empresa.cnpj.replaceAll(RegExp(r'\D'), ''), 15));

    // [034-053] Reservado (uso Banco) — 20 brancos
    sb.write(_brancos(20));

    // [054-068] Código de Transmissão — 15 alfa
    sb.write(_alfa(_conv7, 15));

    // [069-073] Reservado (uso Banco) — 5 brancos
    sb.write(_brancos(5));

    // [074-103] Nome do Beneficiário — 30 alfa
    sb.write(_alfa(empresa.razaoSocial.toUpperCase(), 30));

    // [104-143] Mensagem 1 — 40 brancos
    sb.write(_brancos(40));

    // [144-183] Mensagem 2 — 40 brancos
    sb.write(_brancos(40));

    // [184-191] Número remessa/retorno — 8 num
    sb.write(_numerico(empresa.numeroSequencial.toString(), 8));

    // [192-199] Data da gravação remessa/retorno — 8 num (DDMMAAAA)
    sb.write(ValidadorData.formatarCNAB(dataGeracao));

    // [200-240] Reservado (uso Banco) — 41 brancos
    sb.write(_brancos(41));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Header lote: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // SEGMENTO P — Dados do Boleto
  // Layout H7815 V8.5 — Registro Tipo 3, Segmento P
  // Posições verificadas campo a campo contra H7815 V8.5
  // ══════════════════════════════════════════════════════════════
  String _buildSegmentoP(Titulo titulo, int seq) {
    final sb = StringBuffer();

    // [001-003] Código do Banco na compensação — 3 num
    sb.write('033');

    // [004-007] Número do lote remessa — 4 num
    sb.write('0001');

    // [008-008] Tipo de registro = 3 — 1 num
    sb.write('3');

    // [009-013] Nº sequencial do registro no lote — 5 num
    sb.write(_numerico(seq.toString(), 5));

    // [014-014] Cód. Segmento do registro detalhe = P — 1 alfa
    sb.write('P');

    // [015-015] Reservado (uso Banco) — 1 branco
    // ATENÇÃO: H7815 reserva esta posição para uso do banco (branco/zero)
    // Código de movimento está em 016-017!
    sb.write(' ');

    // [016-017] Código de movimento remessa — 2 num
    // 01=Entrada de boleto, 02=Baixa, 04=Abatimento, 06=Alteração venc.
    sb.write('01');

    // [018-021] Agência do Destinatária — 4 num
    sb.write(_numerico(empresa.agencia, 4));

    // [022-022] Dígito da Ag do Destinatária — 1 num/alfa
    sb.write(_alfa(empresa.digitoAgencia.isEmpty ? '0' : empresa.digitoAgencia, 1));

    // [023-031] Número da conta corrente — 9 num
    // H7815: conta com 9 posições (Santander usa 8 dígitos + zero à esq.)
    sb.write(_numerico(empresa.contaCorrente, 9));

    // [032-032] Dígito verificador da conta — 1 num
    sb.write(_calcularDigitoConta(
        empresa.agencia.padLeft(4, '0'),
        empresa.contaCorrente.padLeft(9, '0')));

    // [033-041] Conta cobrança Destinatária FIDC — 9 zeros (campo reservado)
    sb.write(_numerico('0', 9));

    // [042-042] Dígito da conta cobrança Destinatária FIDC — 1 zero
    sb.write('0');

    // [043-044] Reservado (uso Banco) — 2 brancos
    sb.write(_brancos(2));

    // [045-057] Identificação do boleto no Banco (Nosso Número) — 13 num
    // H7815 Nota 15: 13 posições composto por Módulo 11
    sb.write(_buildNossoNumeroCNAB(titulo));

    // [058-058] Tipo de cobrança (Carteira) — 1 alfa
    // H7815 Nota 5: '1'=Simples, '3'=Caucionada, '4'=Descontada, '5'=Simples Rápida
    sb.write(_getTipoCobranca());

    // [059-059] Forma de Cadastramento — 1 num
    // 1=Com Registro (arquivo), 2=Sem Cadastramento
    sb.write('1');

    // [060-060] Tipo de documento — 1 num
    // 1=Tradicional, 2=Escritural
    sb.write('2');

    // [061-061] Reservado (uso Banco) — 1 branco
    sb.write(' ');

    // [062-062] Reservado (uso Banco) — 1 branco
    sb.write(' ');

    // [063-077] Nº do documento (Seu Número) — 15 alfa
    sb.write(_alfa(titulo.numeroDocumento, 15));

    // [078-085] Data de vencimento do boleto — 8 num (DDMMAAAA)
    sb.write(ValidadorData.formatarCNAB(titulo.dataVencimento));

    // [086-100] Valor nominal do boleto — 15 num (2 decimais sem separador)
    sb.write(_valor(titulo.valorNominal, 15));

    // [101-104] Agência encarregada da cobrança FIDC — 4 zeros
    sb.write('0000');

    // [105-105] Dígito da Agência do Beneficiário FIDC — 1 zero
    sb.write('0');

    // [106-106] Reservado (uso Banco) — 1 branco
    sb.write(' ');

    // [107-108] Espécie do boleto — 2 num
    // H7815 Nota 20: 02=DM, 04=DS, 12=NP, 17=RC, 97=CH, etc.
    final especie = _mapearEspecie(titulo.especieTitulo);
    sb.write(especie);

    // [109-109] Identificação de boleto Aceito/Não Aceito — 1 alfa
    // 'A'=Aceito, 'N'=Não Aceito
    sb.write(titulo.aceite.isEmpty ? 'N' : titulo.aceite[0].toUpperCase());

    // [110-117] Data da emissão do boleto — 8 num (DDMMAAAA)
    sb.write(ValidadorData.formatarCNAB(titulo.dataEmissao ?? DateTime.now()));

    // [118-118] Código de juros de mora — 1 num
    // 1=Valor por dia, 2=Taxa mensal, 3=Isento
    final codJuros = _normalizarCodJuros(titulo.codigoJuros);
    sb.write(codJuros);

    // [119-126] Data de juros de mora — 8 num (DDMMAAAA)
    if (codJuros != '3' && titulo.dataJuros != null) {
      sb.write(ValidadorData.formatarCNAB(titulo.dataJuros));
    } else {
      sb.write('00000000');
    }

    // [127-141] Valor da mora/dia ou Taxa mensal — 15 num (2 decimais)
    sb.write(_valor(codJuros != '3' ? titulo.valorJuros : 0.0, 15));

    // [142-142] Código do desconto 1 — 1 num
    // 0=Sem, 1=Valor, 2=Percentual
    final codDesc1 = titulo.codigoDesconto1.isEmpty ? '0' : titulo.codigoDesconto1.substring(0, 1);
    sb.write(codDesc1);

    // [143-150] Data de desconto 1 — 8 num (DDMMAAAA)
    if (codDesc1 != '0' && titulo.dataDesconto1 != null) {
      sb.write(ValidadorData.formatarCNAB(titulo.dataDesconto1));
    } else {
      sb.write('00000000');
    }

    // [151-165] Valor ou Percentual do desconto concedido — 15 num (2 decimais)
    sb.write(_valor(
        codDesc1 != '0' ? titulo.valorDesconto1 : 0.0, 15));

    // [166-180] Percentual do IOF a ser recolhido — 15 zeros (5 decimais)
    sb.write(_numerico('0', 15));

    // [181-195] Valor do abatimento — 15 zeros (2 decimais)
    sb.write(_valor(0.0, 15));

    // [196-220] Identificação do boleto na empresa (Seu Número/Controle) — 25 alfa
    // H7815: 25 posições para identificação do boleto na empresa
    sb.write(_alfa(titulo.seuNumero, 25));

    // [221-221] Código para protesto — 1 num
    // H7815 Nota 25: 3=Não protestar
    sb.write('3');

    // [222-223] Número de dias para protesto — 2 num
    sb.write('00');

    // [224-224] Código para Baixa/Devolução — 1 num
    // 1=Baixar após N dias, 2=Devolver após N dias
    sb.write('1');

    // [225-225] Reservado (uso Banco) — 1 branco/zero
    sb.write('0');

    // [226-227] Número de dias para Baixa/Devolução — 2 num
    sb.write('60');

    // [228-229] Código da moeda — 2 num
    // H7815: campo de 2 posições (não 3!) → 09=Real Brasileiro
    sb.write('09');

    // [230-240] Reservado (uso Banco) — 11 brancos
    sb.write(_brancos(11));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Segmento P [${titulo.seuNumero}]: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // SEGMENTO Q — Dados do Sacado/Pagador
  // Layout H7815 V8.5 — Registro Tipo 3, Segmento Q
  // ══════════════════════════════════════════════════════════════
  String _buildSegmentoQ(Titulo titulo, int seq) {
    final sb = StringBuffer();

    // [001-003] Código do Banco na compensação — 3 num
    sb.write('033');

    // [004-007] Número do lote remessa — 4 num
    sb.write('0001');

    // [008-008] Tipo de registro = 3 — 1 num
    sb.write('3');

    // [009-013] Nº sequencial do registro no lote — 5 num
    sb.write(_numerico(seq.toString(), 5));

    // [014-014] Cód. segmento do registro detalhe = Q — 1 alfa
    sb.write('Q');

    // [015-015] Reservado (uso Banco) — 1 branco
    sb.write(' ');

    // [016-017] Código de movimento remessa — 2 num
    sb.write('01');

    // [018-018] Tipo de inscrição do Pagador — 1 num (1=CPF, 2=CNPJ)
    sb.write(titulo.tipoInscricaoSacado == TipoInscricao.cpf ? '1' : '2');

    // [019-033] Inscrição do Pagador (CPF/CNPJ) — 15 num (zeros à esquerda)
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

    // [129-133] CEP do Pagador — 5 num (primeiros 5 dígitos)
    final cepLimpo = titulo.cepSacado.replaceAll(RegExp(r'\D'), '');
    sb.write(_numerico(
        cepLimpo.length >= 5 ? cepLimpo.substring(0, 5) : cepLimpo, 5));

    // [134-136] Sufixo do CEP — 3 num (últimos 3 dígitos)
    sb.write(_numerico(
        cepLimpo.length == 8 ? cepLimpo.substring(5) : '000', 3));

    // [137-151] Cidade do Pagador — 15 alfa
    sb.write(_alfa(titulo.cidadeSacado.toUpperCase(), 15));

    // [152-153] Unidade da Federação do Pagador — 2 alfa
    // Fallback 'SP' se UF inválida
    final uf = titulo.ufSacado.trim().length == 2
        ? titulo.ufSacado.toUpperCase()
        : 'SP';
    sb.write(_alfa(uf, 2));

    // [154-154] Tipo de inscrição Beneficiário Final — 1 num
    // [155-169] Inscrição Beneficiário Final — 15 num
    // [170-209] Nome do Beneficiário Final — 40 alfa
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

    // [210-212] Reservado (uso Banco) — 3 brancos
    sb.write(_brancos(3));

    // [213-215] Reservado (uso Banco) — 3 brancos
    sb.write(_brancos(3));

    // [216-218] Reservado (uso Banco) — 3 brancos
    sb.write(_brancos(3));

    // [219-221] Reservado (uso Banco) — 3 brancos
    sb.write(_brancos(3));

    // [222-240] Reservado (uso Banco) — 19 brancos
    sb.write(_brancos(19));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Segmento Q [${titulo.seuNumero}]: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // SEGMENTO R — Desconto 2/3 / Multa / Mensagens (opcional)
  // Layout H7815 V8.5 — Registro Tipo 3, Segmento R
  // ══════════════════════════════════════════════════════════════
  String _buildSegmentoR(Titulo titulo, int seq) {
    final sb = StringBuffer();

    // [001-003] Código do Banco na compensação — 3 num
    sb.write('033');

    // [004-007] Número do lote remessa — 4 num
    sb.write('0001');

    // [008-008] Tipo de registro = 3 — 1 num
    sb.write('3');

    // [009-013] Nº sequencial do registro no lote — 5 num
    sb.write(_numerico(seq.toString(), 5));

    // [014-014] Cód. segmento = R — 1 alfa
    sb.write('R');

    // [015-015] Reservado (uso Banco) — 1 branco
    sb.write(' ');

    // [016-017] Código de movimento — 2 num
    sb.write('01');

    // [018-018] Código do desconto 2 — 1 num (0=Sem)
    sb.write('0');

    // [019-026] Data do desconto 2 — 8 zeros
    sb.write('00000000');

    // [027-041] Valor/Percentual a ser concedido (desconto 2) — 15 zeros
    sb.write(_valor(0.0, 15));

    // [042-042] Código do desconto 3 — 1 num (0=Sem)
    sb.write('0');

    // [043-050] Data do desconto 3 — 8 zeros
    sb.write('00000000');

    // [051-065] Valor/Percentual a ser concedido (desconto 3) — 15 zeros
    sb.write(_valor(0.0, 15));

    // [066-066] Código da multa — 1 num
    // 0=Sem, 1=Valor fixo, 2=Percentual
    final codMulta = (titulo.codigoMulta.isEmpty || titulo.codigoMulta == '0')
        ? '0'
        : titulo.codigoMulta.substring(0, 1);
    sb.write(codMulta);

    // [067-074] Data da multa — 8 num (DDMMAAAA)
    if (codMulta != '0' && titulo.dataMulta != null) {
      sb.write(ValidadorData.formatarCNAB(titulo.dataMulta));
    } else {
      sb.write('00000000');
    }

    // [075-089] Valor/Percentual a ser aplicado — 15 num
    sb.write(_valor(codMulta != '0' ? titulo.valorMulta : 0.0, 15));

    // [090-099] Reservado (uso Banco) — 10 brancos
    sb.write(_brancos(10));

    // [100-139] Mensagem 3 — 40 alfa
    sb.write(_alfa(titulo.mensagem1, 40));

    // [140-179] Mensagem 4 — 40 alfa
    final msg2 = titulo.mensagem2.length > 40
        ? titulo.mensagem2.substring(0, 40)
        : titulo.mensagem2;
    sb.write(_alfa(msg2, 40));

    // [180-240] Uso FEBRABAN — 61 brancos
    sb.write(_brancos(61));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Segmento R [${titulo.seuNumero}]: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // TRAILER DE LOTE
  // Layout H7815 V8.5 — Registro Tipo 5
  // ══════════════════════════════════════════════════════════════
  String _buildTrailerLote(int proximoSeq) {
    int totalRegistrosDetalhe = 0;
    for (final t in titulos) {
      totalRegistrosDetalhe += t.precisaSegmentoR ? 3 : 2;
    }
    // Total do lote: HL + registros detalhe + TL
    final int totalRegistrosLote = 1 + totalRegistrosDetalhe + 1;

    final sb = StringBuffer();

    // [001-003] Código do Banco na compensação — 3 num
    sb.write('033');

    // [004-007] Número do lote remessa — 4 num
    sb.write('0001');

    // [008-008] Tipo de registro = 5 — 1 num
    sb.write('5');

    // [009-017] Reservado (uso Banco) — 9 brancos
    sb.write(_brancos(9));

    // [018-023] Quantidade de registros do lote — 6 num
    sb.write(_numerico(totalRegistrosLote.toString(), 6));

    // [024-240] Reservado (uso Banco) — 217 brancos
    sb.write(_brancos(217));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Trailer lote: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // TRAILER DE ARQUIVO
  // Layout H7815 V8.5 — Registro Tipo 9
  // ══════════════════════════════════════════════════════════════
  String _buildTrailerArquivo(int totalRegistros) {
    final sb = StringBuffer();

    // [001-003] Código do Banco na compensação — 3 num
    sb.write('033');

    // [004-007] Lote de serviço = 9999 — 4 num
    sb.write('9999');

    // [008-008] Tipo de registro = 9 — 1 num
    sb.write('9');

    // [009-017] Reservado (uso Banco) — 9 brancos
    sb.write(_brancos(9));

    // [018-023] Quantidade de lotes do arquivo — 6 num
    sb.write('000001');

    // [024-029] Quantidade de registros do arquivo — 6 num
    sb.write(_numerico(totalRegistros.toString(), 6));

    // [030-035] Quantidade de contas para conciliação — 6 zeros
    sb.write('000000');

    // [036-240] Reservado (uso Banco) — 205 brancos
    sb.write(_brancos(205));

    final linha = sb.toString();
    assert(linha.length == 240,
        'Trailer arquivo: ${linha.length} chars (esperado 240)');
    return linha;
  }

  // ══════════════════════════════════════════════════════════════
  // NOSSO NÚMERO SANTANDER — H7815 Nota 15
  // Formato: 13 posições numéricas com dígito Módulo 11
  // Fórmula: Nº base (12 dígitos) + DAC (1 dígito) = 13 total
  // ══════════════════════════════════════════════════════════════
  String _buildNossoNumeroCNAB(Titulo titulo) {
    // Extrair apenas dígitos do nosso número
    final nossoNumDigitos = titulo.seuNumero.replaceAll(RegExp(r'\D'), '');

    // Pegar os últimos 12 dígitos (ou preencher com zeros à esquerda)
    final nossoNum12 = nossoNumDigitos.length > 12
        ? nossoNumDigitos.substring(nossoNumDigitos.length - 12)
        : nossoNumDigitos.padLeft(12, '0');

    // Calcular DAC Módulo 11 (pesos 2-9 da direita para a esquerda)
    final dac = _calcularModulo11(nossoNum12);

    // Retornar 13 posições: 12 dígitos + 1 DAC
    return '$nossoNum12$dac';
  }

  // ══════════════════════════════════════════════════════════════
  // TIPO DE COBRANÇA (Carteira) — H7815 Nota 5
  // '1'=Simples, '3'=Caucionada, '4'=Descontada, '5'=Simples Rápida
  // ══════════════════════════════════════════════════════════════
  String _getTipoCobranca() {
    final carteira = empresa.carteira.replaceAll(RegExp(r'\D'), '');
    // Mapeamento: código interno → tipo de cobrança H7815
    switch (carteira) {
      case '101':
      case '1':
        return '1'; // Cobrança Simples
      case '102':
        return '5'; // Cobrança Simples Rápida com Registro
      case '104':
      case '3':
        return '3'; // Cobrança Caucionada
      case '201':
      case '4':
        return '4'; // Cobrança Descontada
      default:
        return '1'; // Default: Cobrança Simples
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ESPÉCIE DO BOLETO — H7815 Nota 20
  // Mapear código interno para código H7815
  // ══════════════════════════════════════════════════════════════
  String _mapearEspecie(String especieInterno) {
    final esp = especieInterno.trim();
    // Códigos internos → H7815
    switch (esp) {
      case '01':
      case '02':
      case 'DM':
        return '02'; // DM - Duplicata Mercantil
      case '03':
      case '04':
      case 'DS':
        return '04'; // DS - Duplicata de Serviço
      case '12':
      case 'NP':
        return '12'; // NP - Nota Promissória
      case '17':
      case 'RC':
        return '17'; // RC - Recibo
      case '97':
      case 'CH':
        return '97'; // CH - Cheque
      default:
        // Se já é um código numérico válido H7815
        final codigo = int.tryParse(esp);
        if (codigo != null) {
          return esp.padLeft(2, '0');
        }
        return '02'; // Default: Duplicata Mercantil
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CÓDIGO DE JUROS — H7815
  // 1=Valor por dia, 2=Taxa mensal, 3=Isento
  // ══════════════════════════════════════════════════════════════
  String _normalizarCodJuros(String codJuros) {
    final cod = codJuros.trim();
    if (cod == '1' || cod == '01') return '1';
    if (cod == '2' || cod == '02') return '2';
    return '3'; // Isento (padrão)
  }

  // ══════════════════════════════════════════════════════════════
  // ALGORITMOS
  // ══════════════════════════════════════════════════════════════

  /// Calcula dígito verificador da conta Santander — Módulo 11 pesos 2-9
  /// Base: Agência(4) + Conta(9) da direita para a esquerda
  String _calcularDigitoConta(String agencia, String conta) {
    // H7815: conta tem 9 posições no segmento P
    final base = '${agencia.padLeft(4, '0')}${conta.padLeft(9, '0')}';
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

  /// Calcula Módulo 11 para Nosso Número (DAC) — H7815 Nota 15
  /// Pesos 2-9 da direita para a esquerda
  /// Resto 0 ou 1 → dígito = 0; Resto 10 → dígito = 1
  static String _calcularModulo11(String numero) {
    int soma = 0;
    int peso = 2;
    for (int i = numero.length - 1; i >= 0; i--) {
      soma += int.parse(numero[i]) * peso;
      peso = peso == 9 ? 2 : peso + 1;
    }
    final int resto = soma % 11;
    if (resto == 0 || resto == 1) return '0';
    if (11 - resto == 10) return '1';
    return (11 - resto).toString();
  }

  /// Calcula DAC Santander — compatibilidade legada
  static String calcularDacSantander(
    String agencia,
    String conta,
    String carteira,
    String nossoNumero,
  ) {
    return _calcularModulo11(nossoNumero.padLeft(12, '0'));
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
  String _valor(double valor, int tamanho) {
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
