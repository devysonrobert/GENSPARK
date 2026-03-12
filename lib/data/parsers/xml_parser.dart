// data/parsers/xml_parser.dart
// Parser completo de NF-e (v4.00) e NFS-e (ABRASF 2.04)

import 'package:xml/xml.dart';
import '../../domain/models/titulo.dart';

class XmlParseResult {
  final Titulo? titulo;
  final String? error;
  final String nomeArquivo;
  final String? cnpjEmitente;
  final String? razaoEmitente;

  const XmlParseResult({
    this.titulo,
    this.error,
    required this.nomeArquivo,
    this.cnpjEmitente,
    this.razaoEmitente,
  });

  bool get sucesso => titulo != null && error == null;
}

class XmlNfeParser {
  /// Faz parsing de um XML NF-e versão 4.00
  static XmlParseResult parsarNFe(String conteudoXml, String nomeArquivo) {
    try {
      final doc = XmlDocument.parse(conteudoXml);

      // Localiza o elemento NFe ou nfeProc
      XmlElement? infNFe = _findElement(doc, 'infNFe');
      if (infNFe == null) {
        return XmlParseResult(
          nomeArquivo: nomeArquivo,
          error: 'Elemento <infNFe> não encontrado. Verifique se o arquivo é uma NF-e válida.',
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

      // ── Identificação da NF-e ─────────────────────────────
      final ide = infNFe.findElements('ide').firstOrNull;
      final nNF = _getTextPath(ide, 'nNF') ?? '';
      final serie = _getTextPath(ide, 'serie') ?? '';
      final dhEmi = _getTextPath(ide, 'dhEmi') ?? _getTextPath(ide, 'dEmi') ?? '';

      // Data de emissão
      DateTime? dataEmissao;
      try {
        if (dhEmi.isNotEmpty) {
          dataEmissao = DateTime.parse(dhEmi.substring(0, 10));
        }
      } catch (_) {
        dataEmissao = DateTime.now();
      }

      // ── Data de Vencimento ────────────────────────────────
      // A NF-e pode ter cobranças (cobr > dup > dVenc) com a data real
      // Caso não exista, calculamos +30 dias da emissão como padrão
      DateTime? dataVencimento;
      try {
        // Tenta extrair do bloco <cobr><dup><dVenc>
        final cobr = infNFe.findElements('cobr').firstOrNull;
        if (cobr != null) {
          final dup = cobr.findElements('dup').firstOrNull;
          if (dup != null) {
            final dVenc = _getTextPath(dup, 'dVenc') ?? '';
            if (dVenc.isNotEmpty) {
              dataVencimento = DateTime.parse(dVenc.substring(0, 10));
            }
          }
        }
        // Tenta tag <dVenc> diretamente em qualquer nível
        if (dataVencimento == null) {
          final dVencStr = _findTextDeep(infNFe, 'dVenc') ?? '';
          if (dVencStr.isNotEmpty) {
            dataVencimento = DateTime.parse(dVencStr.substring(0, 10));
          }
        }
        // Tenta tag <dataVencimento> (alguns layouts específicos)
        if (dataVencimento == null) {
          final dVencStr2 = _findTextDeep(infNFe, 'dataVencimento') ?? '';
          if (dVencStr2.isNotEmpty) {
            dataVencimento = DateTime.parse(dVencStr2.substring(0, 10));
          }
        }
      } catch (_) {}
      // Fallback: +30 dias a partir da data de emissão
      dataVencimento ??= (dataEmissao ?? DateTime.now()).add(const Duration(days: 30));

      // ── Valores ───────────────────────────────────────────
      final total = infNFe.findElements('total').firstOrNull;
      final icmsTot = total?.findElements('ICMSTot').firstOrNull;
      final vNF = _getTextPath(icmsTot, 'vNF') ?? '0';
      final valorNominal = double.tryParse(vNF) ?? 0.0;

      // Chave de acesso
      final chaveAcesso = infNFe.getAttribute('Id') ?? '';
      final chaveNum = chaveAcesso.replaceAll('NFe', '');

      // Nosso número baseado no número da NF
      final nossoNumero = nNF.padLeft(15, '0');
      final numDoc = nNF.padLeft(10, '0');

      final titulo = Titulo(
        seuNumero: nossoNumero,
        numeroDocumento: numDoc,
        especieTitulo: '01', // Duplicata Mercantil
        aceite: 'N',
        dataEmissao: dataEmissao,
        dataVencimento: dataVencimento,
        valorNominal: valorNominal,
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
        mensagem2: chaveNum.length >= 20
            ? 'CHAVE: ${chaveNum.substring(0, 20)}'
            : '',
        origemXml: nomeArquivo,
        status: StatusTitulo.pendente,
      );

      return XmlParseResult(
        titulo: titulo,
        nomeArquivo: nomeArquivo,
        cnpjEmitente: cnpjEmitente,
        razaoEmitente: razaoEmitente,
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

  /// Faz parsing de um XML NFS-e padrão ABRASF 2.04
  static XmlParseResult parsarNFSe(String conteudoXml, String nomeArquivo) {
    try {
      final doc = XmlDocument.parse(conteudoXml);

      // Procura elementos típicos de NFS-e ABRASF
      XmlElement? compNfse = _findElement(doc, 'CompNfse') ??
          _findElement(doc, 'NFSe') ??
          _findElement(doc, 'Nfse');

      XmlElement? infNfse = _findElement(doc, 'InfNfse') ??
          _findElement(doc, 'Nfse');

      if (compNfse == null && infNfse == null) {
        return XmlParseResult(
          nomeArquivo: nomeArquivo,
          error: 'Não é uma NFS-e ABRASF válida. Elementos esperados não encontrados.',
        );
      }

      final rootNfse = infNfse ?? compNfse!;

      // ── Prestador ─────────────────────────────────────────
      final prestador = _findElementDeep(rootNfse, 'PrestadorServico') ??
          _findElementDeep(rootNfse, 'Prestador');
      final cnpjPrestador =
          _findTextDeep(prestador, 'Cnpj') ?? _findTextDeep(prestador, 'CNPJ') ?? '';
      final razaoPrestador =
          _findTextDeep(prestador, 'RazaoSocial') ?? _findTextDeep(prestador, 'NomeFantasia') ?? '';

      // ── Tomador ───────────────────────────────────────────
      final tomador = _findElementDeep(rootNfse, 'TomadorServico') ??
          _findElementDeep(rootNfse, 'Tomador');

      final identTomador = _findElementDeep(tomador, 'IdentificacaoTomador');
      final cnpjTomador = _findTextDeep(identTomador, 'Cnpj') ?? '';
      final cpfTomador = _findTextDeep(identTomador, 'Cpf') ?? '';
      final isDestCnpj = cnpjTomador.isNotEmpty;
      final docTomador =
          isDestCnpj ? cnpjTomador : cpfTomador;
      final nomeTomador =
          _findTextDeep(tomador, 'RazaoSocial') ?? _findTextDeep(tomador, 'NomeFantasia') ?? '';

      final enderTomador = _findElementDeep(tomador, 'Endereco');
      final logradouro = _findTextDeep(enderTomador, 'Endereco') ?? '';
      final numEnd = _findTextDeep(enderTomador, 'Numero') ?? '';
      final complemento = _findTextDeep(enderTomador, 'Complemento') ?? '';
      final bairro = _findTextDeep(enderTomador, 'Bairro') ?? '';
      final cepRaw = _findTextDeep(enderTomador, 'Cep') ?? '';
      final cep = cepRaw.replaceAll(RegExp(r'\D'), '');
      final cidade = _findTextDeep(enderTomador, 'Municipio') ??
          _findTextDeep(enderTomador, 'xMun') ?? '';
      final uf = _findTextDeep(enderTomador, 'Uf') ?? '';

      // ── Dados da NFS-e ────────────────────────────────────
      final numero = _findTextDeep(rootNfse, 'Numero') ?? '';
      final dataEmissaoStr = _findTextDeep(rootNfse, 'DataEmissao') ??
          _findTextDeep(rootNfse, 'DhEmi') ?? '';

      DateTime? dataEmissao;
      try {
        if (dataEmissaoStr.isNotEmpty) {
          dataEmissao = DateTime.parse(dataEmissaoStr.substring(0, 10));
        }
      } catch (_) {
        dataEmissao = DateTime.now();
      }

      // ── Data de Vencimento NFS-e ──────────────────────────
      // NFS-e pode ter DataVencimento, DtVencimento ou similar
      DateTime? dataVencimento;
      try {
        final dVencStr = _findTextDeep(rootNfse, 'DataVencimento') ??
            _findTextDeep(rootNfse, 'DtVencimento') ??
            _findTextDeep(rootNfse, 'dVenc') ??
            _findTextDeep(rootNfse, 'DataPagamento') ?? '';
        if (dVencStr.isNotEmpty) {
          dataVencimento = DateTime.parse(dVencStr.substring(0, 10));
        }
      } catch (_) {}
      // Fallback: +30 dias da emissão
      dataVencimento ??= (dataEmissao ?? DateTime.now()).add(const Duration(days: 30));

      // Valor
      final servico = _findElementDeep(rootNfse, 'Servico') ??
          _findElementDeep(rootNfse, 'Valores');
      final vServicos = _findTextDeep(servico, 'ValorServicos') ??
          _findTextDeep(servico, 'ValorLiquidoNfse') ?? '0';
      final valorNominal = double.tryParse(vServicos) ?? 0.0;

      // Discriminação
      final discriminacao = _findTextDeep(servico, 'Discriminacao') ?? '';
      final descricao = discriminacao.length > 40
          ? discriminacao.substring(0, 40)
          : discriminacao;

      final nossoNumero = numero.padLeft(15, '0');

      final titulo = Titulo(
        seuNumero: nossoNumero,
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
        titulo: titulo,
        nomeArquivo: nomeArquivo,
        cnpjEmitente: cnpjPrestador,
        razaoEmitente: razaoPrestador,
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

  /// Detecta o tipo de XML (NF-e ou NFS-e) e faz o parsing correto
  static XmlParseResult parsarXml(String conteudo, String nomeArquivo) {
    try {
      final doc = XmlDocument.parse(conteudo);

      // Verifica se é NF-e
      if (_findElement(doc, 'infNFe') != null ||
          _findElement(doc, 'nfeProc') != null ||
          _findElement(doc, 'NFe') != null) {
        return parsarNFe(conteudo, nomeArquivo);
      }

      // Verifica se é NFS-e
      if (_findElement(doc, 'CompNfse') != null ||
          _findElement(doc, 'NFSe') != null ||
          _findElement(doc, 'Nfse') != null ||
          _findElement(doc, 'InfNfse') != null) {
        return parsarNFSe(conteudo, nomeArquivo);
      }

      return XmlParseResult(
        nomeArquivo: nomeArquivo,
        error: 'Tipo de XML não reconhecido. Use NF-e (versão 4.00) ou NFS-e (ABRASF 2.04)',
      );
    } catch (e) {
      return XmlParseResult(
        nomeArquivo: nomeArquivo,
        error: 'Erro ao ler XML: $e',
      );
    }
  }

  // ── Helpers XML ──────────────────────────────────────────────

  static XmlElement? _findElement(XmlNode node, String name) {
    try {
      for (final descendant in node.descendants) {
        if (descendant is XmlElement && descendant.localName == name) {
          return descendant;
        }
      }
    } catch (_) {}
    return null;
  }

  static XmlElement? _findElementDeep(XmlElement? node, String name) {
    if (node == null) return null;
    try {
      for (final descendant in node.descendants) {
        if (descendant is XmlElement && descendant.localName == name) {
          return descendant;
        }
      }
    } catch (_) {}
    return null;
  }

  static String? _getTextPath(XmlElement? element, String childName) {
    try {
      final child = element?.findElements(childName).firstOrNull;
      return child?.innerText.trim();
    } catch (_) {
      return null;
    }
  }

  static String? _findTextDeep(XmlElement? node, String name) {
    if (node == null) return null;
    try {
      for (final descendant in node.descendants) {
        if (descendant is XmlElement && descendant.localName == name) {
          return descendant.innerText.trim();
        }
      }
    } catch (_) {}
    return null;
  }
}
