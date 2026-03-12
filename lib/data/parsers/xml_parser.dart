// data/parsers/xml_parser.dart
// Parser completo de NF-e (v4.00) e NFS-e (ABRASF 2.04)
// Suporta MÚLTIPLAS DUPLICATAS por XML — gera 1 Titulo por parcela <dup>

import 'package:xml/xml.dart';
import '../../domain/models/titulo.dart';

// ══════════════════════════════════════════════════════════════
// MODELO DE RESULTADO — suporta múltiplos títulos por XML
// ══════════════════════════════════════════════════════════════

class XmlParseResult {
  /// Lista de títulos gerados (1 por duplicata/parcela).
  /// Mantemos [titulo] para compatibilidade com código legado que usa .sucesso
  final List<Titulo> titulos;
  final String? error;
  final String nomeArquivo;
  final String? cnpjEmitente;
  final String? razaoEmitente;
  final int totalParcelas;

  const XmlParseResult({
    this.titulos = const [],
    this.error,
    required this.nomeArquivo,
    this.cnpjEmitente,
    this.razaoEmitente,
    this.totalParcelas = 0,
  });

  /// Compatibilidade legada — retorna o primeiro título
  Titulo? get titulo => titulos.isNotEmpty ? titulos.first : null;

  bool get sucesso => titulos.isNotEmpty && error == null;

  /// Número de parcelas geradas
  int get quantidadeTitulos => titulos.length;
}

// ══════════════════════════════════════════════════════════════
// PARSER PRINCIPAL
// ══════════════════════════════════════════════════════════════

class XmlNfeParser {
  // ─────────────────────────────────────────────────────────────
  // NF-e versão 4.00
  // Gera 1 Titulo por <dup> dentro de <cobr>.
  // Se não houver duplicatas, gera 1 Titulo com o valor total.
  // ─────────────────────────────────────────────────────────────
  static XmlParseResult parsarNFe(String conteudoXml, String nomeArquivo) {
    try {
      final doc = XmlDocument.parse(conteudoXml);

      XmlElement? infNFe = _findElement(doc, 'infNFe');
      if (infNFe == null) {
        return XmlParseResult(
          nomeArquivo: nomeArquivo,
          error:
              'Elemento <infNFe> não encontrado. Verifique se o arquivo é uma NF-e válida.',
        );
      }

      // ── Emitente ──────────────────────────────────────────
      final emit = infNFe.findElements('emit').firstOrNull;
      final cnpjEmitente = _getTextPath(emit, 'CNPJ') ?? '';
      final razaoEmitente = _getTextPath(emit, 'xNome') ?? '';

      // ── Destinatário ──────────────────────────────────────
      final dest = infNFe.findElements('dest').firstOrNull;
      final cnpjDest = _getTextPath(dest, 'CNPJ') ?? '';
      final cpfDest = _getTextPath(dest, 'CPF') ?? '';
      final isDestCnpj = cnpjDest.isNotEmpty;
      final docDest = isDestCnpj ? cnpjDest : cpfDest;
      final nomeDest = _getTextPath(dest, 'xNome') ?? '';

      // Endereço do destinatário
      final enderDest = dest?.findElements('enderDest').firstOrNull;
      final logradouro = _getTextPath(enderDest, 'xLgr') ?? '';
      final numEnd = _getTextPath(enderDest, 'nro') ?? '';
      final complemento = _getTextPath(enderDest, 'xCpl') ?? '';
      final bairro = _getTextPath(enderDest, 'xBairro') ?? '';
      final cepRaw = _getTextPath(enderDest, 'CEP') ?? '';
      final cep = cepRaw.replaceAll(RegExp(r'\D'), '');
      final cidade = _getTextPath(enderDest, 'xMun') ?? '';
      final uf = _getTextPath(enderDest, 'UF') ?? '';

      // ── Identificação ────────────────────────────────────
      final ide = infNFe.findElements('ide').firstOrNull;
      final nNF = _getTextPath(ide, 'nNF') ?? '';
      final serie = _getTextPath(ide, 'serie') ?? '';
      final dhEmi =
          _getTextPath(ide, 'dhEmi') ?? _getTextPath(ide, 'dEmi') ?? '';

      DateTime? dataEmissao;
      try {
        if (dhEmi.isNotEmpty) {
          dataEmissao = DateTime.parse(dhEmi.substring(0, 10));
        }
      } catch (_) {
        dataEmissao = DateTime.now();
      }

      // ── Chave de acesso ───────────────────────────────────
      final chaveAcesso = infNFe.getAttribute('Id') ?? '';
      final chaveNum = chaveAcesso.replaceAll('NFe', '');
      final chaveMsg = chaveNum.length >= 20
          ? 'CHAVE: ${chaveNum.substring(0, 20)}'
          : '';

      // ── Valor total da NF ─────────────────────────────────
      final total = infNFe.findElements('total').firstOrNull;
      final icmsTot = total?.findElements('ICMSTot').firstOrNull;
      final vNF = _getTextPath(icmsTot, 'vNF') ?? '0';
      final valorTotal = double.tryParse(vNF) ?? 0.0;

      // ── Duplicatas <cobr><dup> ────────────────────────────
      // Cada <dup> gera um Titulo separado com seu vencimento e valor
      final cobr = infNFe.findElements('cobr').firstOrNull;
      final dups = cobr?.findElements('dup').toList() ?? [];

      final titulos = <Titulo>[];

      if (dups.isNotEmpty) {
        // ✅ Modo parcelas: 1 Titulo por <dup>
        for (int i = 0; i < dups.length; i++) {
          final dup = dups[i];
          final nDup = _getTextPath(dup, 'nDup') ?? '${i + 1}';
          final dVencStr = _getTextPath(dup, 'dVenc') ?? '';
          final vDupStr = _getTextPath(dup, 'vDup') ?? '0';

          DateTime? dataVencimento;
          try {
            if (dVencStr.isNotEmpty) {
              dataVencimento = DateTime.parse(dVencStr.substring(0, 10));
            }
          } catch (_) {}
          // Fallback: +30 dias da emissão
          dataVencimento ??=
              (dataEmissao ?? DateTime.now()).add(const Duration(days: 30));

          final valorParcela = double.tryParse(vDupStr) ?? 0.0;

          // Nosso número: NNNNNNNNNN/PPP  ex: 0000014687/001
          final nossoNumero =
              '${nNF.padLeft(10, '0')}/${nDup.padLeft(3, '0')}';
          // Número documento: NF + parcela
          final numDoc = '${nNF.padLeft(7, '0')}/${nDup.padLeft(3, '0')}';

          titulos.add(Titulo(
            seuNumero: nossoNumero,
            numeroDocumento: numDoc,
            especieTitulo: '01', // Duplicata Mercantil
            aceite: 'N',
            dataEmissao: dataEmissao,
            dataVencimento: dataVencimento,
            valorNominal: valorParcela,
            tipoInscricaoSacado:
                isDestCnpj ? TipoInscricao.cnpj : TipoInscricao.cpf,
            cpfCnpjSacado: docDest.replaceAll(RegExp(r'\D'), ''),
            nomeSacado: nomeDest,
            enderecoSacado: logradouro,
            numeroEnderecoSacado: numEnd,
            complementoSacado: complemento,
            bairroSacado: bairro,
            cepSacado: cep,
            cidadeSacado: cidade,
            ufSacado: uf,
            mensagem1: 'NF-e $nNF SERIE $serie PARC $nDup/${dups.length}',
            mensagem2: chaveMsg,
            origemXml: nomeArquivo,
            status: StatusTitulo.pendente,
          ));
        }
      } else {
        // ✅ Sem duplicatas: gera 1 Titulo com valor total
        DateTime? dataVencimento;
        try {
          final dVencStr = _findTextDeep(infNFe, 'dVenc') ??
              _findTextDeep(infNFe, 'dataVencimento') ??
              '';
          if (dVencStr.isNotEmpty) {
            dataVencimento = DateTime.parse(dVencStr.substring(0, 10));
          }
        } catch (_) {}
        dataVencimento ??=
            (dataEmissao ?? DateTime.now()).add(const Duration(days: 30));

        titulos.add(Titulo(
          seuNumero: nNF.padLeft(15, '0'),
          numeroDocumento: nNF.padLeft(10, '0'),
          especieTitulo: '01',
          aceite: 'N',
          dataEmissao: dataEmissao,
          dataVencimento: dataVencimento,
          valorNominal: valorTotal,
          tipoInscricaoSacado:
              isDestCnpj ? TipoInscricao.cnpj : TipoInscricao.cpf,
          cpfCnpjSacado: docDest.replaceAll(RegExp(r'\D'), ''),
          nomeSacado: nomeDest,
          enderecoSacado: logradouro,
          numeroEnderecoSacado: numEnd,
          complementoSacado: complemento,
          bairroSacado: bairro,
          cepSacado: cep,
          cidadeSacado: cidade,
          ufSacado: uf,
          mensagem1: 'NF-e $nNF SERIE $serie',
          mensagem2: chaveMsg,
          origemXml: nomeArquivo,
          status: StatusTitulo.pendente,
        ));
      }

      return XmlParseResult(
        titulos: titulos,
        nomeArquivo: nomeArquivo,
        cnpjEmitente: cnpjEmitente,
        razaoEmitente: razaoEmitente,
        totalParcelas: titulos.length,
      );
    } on XmlParserException catch (e) {
      return XmlParseResult(
        nomeArquivo: nomeArquivo,
        error: 'XML malformado: ${e.message}',
      );
    } catch (e) {
      return XmlParseResult(
        nomeArquivo: nomeArquivo,
        error: 'Erro ao processar NF-e: $e',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NFS-e ABRASF 2.04
  // NFS-e geralmente não tem duplicatas; gera 1 Titulo por serviço.
  // ─────────────────────────────────────────────────────────────
  static XmlParseResult parsarNFSe(String conteudoXml, String nomeArquivo) {
    try {
      final doc = XmlDocument.parse(conteudoXml);

      XmlElement? compNfse = _findElement(doc, 'CompNfse') ??
          _findElement(doc, 'NFSe') ??
          _findElement(doc, 'Nfse');

      XmlElement? infNfse =
          _findElement(doc, 'InfNfse') ?? _findElement(doc, 'Nfse');

      if (compNfse == null && infNfse == null) {
        return XmlParseResult(
          nomeArquivo: nomeArquivo,
          error:
              'Não é uma NFS-e ABRASF válida. Elementos esperados não encontrados.',
        );
      }

      final rootNfse = infNfse ?? compNfse!;

      // ── Prestador ─────────────────────────────────────────
      final prestador = _findElementDeep(rootNfse, 'PrestadorServico') ??
          _findElementDeep(rootNfse, 'Prestador');
      final cnpjPrestador = _findTextDeep(prestador, 'Cnpj') ??
          _findTextDeep(prestador, 'CNPJ') ??
          '';
      final razaoPrestador =
          _findTextDeep(prestador, 'RazaoSocial') ??
          _findTextDeep(prestador, 'NomeFantasia') ??
          '';

      // ── Tomador ───────────────────────────────────────────
      final tomador = _findElementDeep(rootNfse, 'TomadorServico') ??
          _findElementDeep(rootNfse, 'Tomador');
      final identTomador = _findElementDeep(tomador, 'IdentificacaoTomador');
      final cnpjTomador = _findTextDeep(identTomador, 'Cnpj') ?? '';
      final cpfTomador = _findTextDeep(identTomador, 'Cpf') ?? '';
      final isDestCnpj = cnpjTomador.isNotEmpty;
      final docTomador = isDestCnpj ? cnpjTomador : cpfTomador;
      final nomeTomador = _findTextDeep(tomador, 'RazaoSocial') ??
          _findTextDeep(tomador, 'NomeFantasia') ??
          '';

      final enderTomador = _findElementDeep(tomador, 'Endereco');
      final logradouro = _findTextDeep(enderTomador, 'Endereco') ?? '';
      final numEnd = _findTextDeep(enderTomador, 'Numero') ?? '';
      final complemento = _findTextDeep(enderTomador, 'Complemento') ?? '';
      final bairro = _findTextDeep(enderTomador, 'Bairro') ?? '';
      final cepRaw = _findTextDeep(enderTomador, 'Cep') ?? '';
      final cep = cepRaw.replaceAll(RegExp(r'\D'), '');
      final cidade = _findTextDeep(enderTomador, 'Municipio') ??
          _findTextDeep(enderTomador, 'xMun') ??
          '';
      final uf = _findTextDeep(enderTomador, 'Uf') ?? '';

      // ── Número e datas ────────────────────────────────────
      final numero = _findTextDeep(rootNfse, 'Numero') ?? '';
      final dataEmissaoStr = _findTextDeep(rootNfse, 'DataEmissao') ??
          _findTextDeep(rootNfse, 'DhEmi') ??
          '';

      DateTime? dataEmissao;
      try {
        if (dataEmissaoStr.isNotEmpty) {
          dataEmissao = DateTime.parse(dataEmissaoStr.substring(0, 10));
        }
      } catch (_) {
        dataEmissao = DateTime.now();
      }

      DateTime? dataVencimento;
      try {
        final dVencStr = _findTextDeep(rootNfse, 'DataVencimento') ??
            _findTextDeep(rootNfse, 'DtVencimento') ??
            _findTextDeep(rootNfse, 'dVenc') ??
            _findTextDeep(rootNfse, 'DataPagamento') ??
            '';
        if (dVencStr.isNotEmpty) {
          dataVencimento = DateTime.parse(dVencStr.substring(0, 10));
        }
      } catch (_) {}
      dataVencimento ??=
          (dataEmissao ?? DateTime.now()).add(const Duration(days: 30));

      // ── Valor ─────────────────────────────────────────────
      final servico = _findElementDeep(rootNfse, 'Servico') ??
          _findElementDeep(rootNfse, 'Valores');
      final vServicos = _findTextDeep(servico, 'ValorServicos') ??
          _findTextDeep(servico, 'ValorLiquidoNfse') ??
          '0';
      final valorNominal = double.tryParse(vServicos) ?? 0.0;

      final discriminacao = _findTextDeep(servico, 'Discriminacao') ?? '';
      final descricao = discriminacao.length > 40
          ? discriminacao.substring(0, 40)
          : discriminacao;

      final titulo = Titulo(
        seuNumero: numero.padLeft(15, '0'),
        numeroDocumento: numero.padLeft(10, '0'),
        especieTitulo: '02', // Duplicata de Serviço
        aceite: 'N',
        dataEmissao: dataEmissao,
        dataVencimento: dataVencimento,
        valorNominal: valorNominal,
        tipoInscricaoSacado:
            isDestCnpj ? TipoInscricao.cnpj : TipoInscricao.cpf,
        cpfCnpjSacado: docTomador.replaceAll(RegExp(r'\D'), ''),
        nomeSacado: nomeTomador,
        enderecoSacado: logradouro,
        numeroEnderecoSacado: numEnd,
        complementoSacado: complemento,
        bairroSacado: bairro,
        cepSacado: cep,
        cidadeSacado: cidade,
        ufSacado: uf,
        mensagem1: 'NFS-e $numero',
        mensagem2: descricao,
        origemXml: nomeArquivo,
        status: StatusTitulo.pendente,
      );

      return XmlParseResult(
        titulos: [titulo],
        nomeArquivo: nomeArquivo,
        cnpjEmitente: cnpjPrestador,
        razaoEmitente: razaoPrestador,
        totalParcelas: 1,
      );
    } on XmlParserException catch (e) {
      return XmlParseResult(
        nomeArquivo: nomeArquivo,
        error: 'XML malformado: ${e.message}',
      );
    } catch (e) {
      return XmlParseResult(
        nomeArquivo: nomeArquivo,
        error: 'Erro ao processar NFS-e: $e',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Auto-detecção NF-e / NFS-e
  // ─────────────────────────────────────────────────────────────
  static XmlParseResult parsarXml(String conteudo, String nomeArquivo) {
    try {
      final doc = XmlDocument.parse(conteudo);

      if (_findElement(doc, 'infNFe') != null ||
          _findElement(doc, 'nfeProc') != null ||
          _findElement(doc, 'NFe') != null) {
        return parsarNFe(conteudo, nomeArquivo);
      }

      if (_findElement(doc, 'CompNfse') != null ||
          _findElement(doc, 'NFSe') != null ||
          _findElement(doc, 'Nfse') != null ||
          _findElement(doc, 'InfNfse') != null) {
        return parsarNFSe(conteudo, nomeArquivo);
      }

      return XmlParseResult(
        nomeArquivo: nomeArquivo,
        error:
            'Tipo de XML não reconhecido. Use NF-e (versão 4.00) ou NFS-e (ABRASF 2.04)',
      );
    } catch (e) {
      return XmlParseResult(
        nomeArquivo: nomeArquivo,
        error: 'Erro ao ler XML: $e',
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  static XmlElement? _findElement(XmlNode node, String name) {
    try {
      for (final d in node.descendants) {
        if (d is XmlElement && d.localName == name) return d;
      }
    } catch (_) {}
    return null;
  }

  static XmlElement? _findElementDeep(XmlElement? node, String name) {
    if (node == null) return null;
    try {
      for (final d in node.descendants) {
        if (d is XmlElement && d.localName == name) return d;
      }
    } catch (_) {}
    return null;
  }

  static String? _getTextPath(XmlElement? element, String childName) {
    try {
      return element?.findElements(childName).firstOrNull?.innerText.trim();
    } catch (_) {
      return null;
    }
  }

  static String? _findTextDeep(XmlElement? node, String name) {
    if (node == null) return null;
    try {
      for (final d in node.descendants) {
        if (d is XmlElement && d.localName == name) return d.innerText.trim();
      }
    } catch (_) {}
    return null;
  }
}
