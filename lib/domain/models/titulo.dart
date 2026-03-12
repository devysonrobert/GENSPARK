// domain/models/titulo.dart
// Modelo completo de um título de cobrança para CNAB 240

import 'package:uuid/uuid.dart';

enum StatusTitulo { valido, pendente, invalido }

enum TipoInscricao { cpf, cnpj }

class Titulo {
  final String id;

  // Dados do título
  final String seuNumero; // Nosso número — 15 chars
  final String numeroDocumento; // Número do documento — 10 chars
  final String especieTitulo; // Código da espécie
  final String aceite; // A ou N
  final DateTime? dataEmissao;
  final DateTime? dataVencimento;
  final double valorNominal;

  // Dados do sacado
  final TipoInscricao tipoInscricaoSacado;
  final String cpfCnpjSacado; // Sem máscara
  final String nomeSacado; // 40 chars
  final String enderecoSacado; // 40 chars
  final String numeroEnderecoSacado; // 5 chars
  final String complementoSacado; // 15 chars
  final String bairroSacado; // 15 chars
  final String cepSacado; // 8 dígitos sem hífen
  final String cidadeSacado; // 20 chars
  final String ufSacado; // 2 chars

  // Instruções de cobrança
  final String codigoMulta; // 0=Sem, 1=Valor, 2=Percentual
  final DateTime? dataMulta;
  final double valorMulta;

  final String codigoJuros; // 0=Isento, 1=Valor/dia, 2=%/mês
  final DateTime? dataJuros;
  final double valorJuros;

  final String codigoDesconto1; // 0=Sem, 1=Valor, 2=%, 3=Antecipado
  final DateTime? dataDesconto1;
  final double valorDesconto1;

  // Instruções texto livre
  final String mensagem1; // 40 chars
  final String mensagem2; // 40 chars

  // Sacador/Avalista (opcional)
  final TipoInscricao? tipoInscricaoAvalista;
  final String cpfCnpjAvalista;
  final String nomeAvalista; // 40 chars

  // Metadata
  final String? origemXml; // Nome do arquivo XML de origem
  final DateTime criadoEm;
  final StatusTitulo status;
  final List<String> erros;

  Titulo({
    String? id,
    required this.seuNumero,
    required this.numeroDocumento,
    this.especieTitulo = '01',
    this.aceite = 'N',
    this.dataEmissao,
    this.dataVencimento,
    required this.valorNominal,
    this.tipoInscricaoSacado = TipoInscricao.cnpj,
    required this.cpfCnpjSacado,
    required this.nomeSacado,
    this.enderecoSacado = '',
    this.numeroEnderecoSacado = '',
    this.complementoSacado = '',
    this.bairroSacado = '',
    this.cepSacado = '',
    this.cidadeSacado = '',
    this.ufSacado = '',
    this.codigoMulta = '0',
    this.dataMulta,
    this.valorMulta = 0.0,
    this.codigoJuros = '0',
    this.dataJuros,
    this.valorJuros = 0.0,
    this.codigoDesconto1 = '0',
    this.dataDesconto1,
    this.valorDesconto1 = 0.0,
    this.mensagem1 = '',
    this.mensagem2 = '',
    this.tipoInscricaoAvalista,
    this.cpfCnpjAvalista = '',
    this.nomeAvalista = '',
    this.origemXml,
    DateTime? criadoEm,
    this.status = StatusTitulo.pendente,
    this.erros = const [],
  })  : id = id ?? const Uuid().v4(),
        criadoEm = criadoEm ?? DateTime.now();

  bool get precisaSegmentoR =>
      codigoMulta != '0' ||
      codigoDesconto1 != '0' ||
      mensagem1.isNotEmpty ||
      mensagem2.isNotEmpty;

  Titulo copyWith({
    String? id,
    String? seuNumero,
    String? numeroDocumento,
    String? especieTitulo,
    String? aceite,
    DateTime? dataEmissao,
    DateTime? dataVencimento,
    double? valorNominal,
    TipoInscricao? tipoInscricaoSacado,
    String? cpfCnpjSacado,
    String? nomeSacado,
    String? enderecoSacado,
    String? numeroEnderecoSacado,
    String? complementoSacado,
    String? bairroSacado,
    String? cepSacado,
    String? cidadeSacado,
    String? ufSacado,
    String? codigoMulta,
    DateTime? dataMulta,
    double? valorMulta,
    String? codigoJuros,
    DateTime? dataJuros,
    double? valorJuros,
    String? codigoDesconto1,
    DateTime? dataDesconto1,
    double? valorDesconto1,
    String? mensagem1,
    String? mensagem2,
    TipoInscricao? tipoInscricaoAvalista,
    String? cpfCnpjAvalista,
    String? nomeAvalista,
    String? origemXml,
    DateTime? criadoEm,
    StatusTitulo? status,
    List<String>? erros,
  }) {
    return Titulo(
      id: id ?? this.id,
      seuNumero: seuNumero ?? this.seuNumero,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      especieTitulo: especieTitulo ?? this.especieTitulo,
      aceite: aceite ?? this.aceite,
      dataEmissao: dataEmissao ?? this.dataEmissao,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      valorNominal: valorNominal ?? this.valorNominal,
      tipoInscricaoSacado: tipoInscricaoSacado ?? this.tipoInscricaoSacado,
      cpfCnpjSacado: cpfCnpjSacado ?? this.cpfCnpjSacado,
      nomeSacado: nomeSacado ?? this.nomeSacado,
      enderecoSacado: enderecoSacado ?? this.enderecoSacado,
      numeroEnderecoSacado: numeroEnderecoSacado ?? this.numeroEnderecoSacado,
      complementoSacado: complementoSacado ?? this.complementoSacado,
      bairroSacado: bairroSacado ?? this.bairroSacado,
      cepSacado: cepSacado ?? this.cepSacado,
      cidadeSacado: cidadeSacado ?? this.cidadeSacado,
      ufSacado: ufSacado ?? this.ufSacado,
      codigoMulta: codigoMulta ?? this.codigoMulta,
      dataMulta: dataMulta ?? this.dataMulta,
      valorMulta: valorMulta ?? this.valorMulta,
      codigoJuros: codigoJuros ?? this.codigoJuros,
      dataJuros: dataJuros ?? this.dataJuros,
      valorJuros: valorJuros ?? this.valorJuros,
      codigoDesconto1: codigoDesconto1 ?? this.codigoDesconto1,
      dataDesconto1: dataDesconto1 ?? this.dataDesconto1,
      valorDesconto1: valorDesconto1 ?? this.valorDesconto1,
      mensagem1: mensagem1 ?? this.mensagem1,
      mensagem2: mensagem2 ?? this.mensagem2,
      tipoInscricaoAvalista: tipoInscricaoAvalista ?? this.tipoInscricaoAvalista,
      cpfCnpjAvalista: cpfCnpjAvalista ?? this.cpfCnpjAvalista,
      nomeAvalista: nomeAvalista ?? this.nomeAvalista,
      origemXml: origemXml ?? this.origemXml,
      criadoEm: criadoEm ?? this.criadoEm,
      status: status ?? this.status,
      erros: erros ?? this.erros,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seuNumero': seuNumero,
        'numeroDocumento': numeroDocumento,
        'especieTitulo': especieTitulo,
        'aceite': aceite,
        'dataEmissao': dataEmissao?.toIso8601String(),
        'dataVencimento': dataVencimento?.toIso8601String(),
        'valorNominal': valorNominal,
        'tipoInscricaoSacado': tipoInscricaoSacado.name,
        'cpfCnpjSacado': cpfCnpjSacado,
        'nomeSacado': nomeSacado,
        'enderecoSacado': enderecoSacado,
        'numeroEnderecoSacado': numeroEnderecoSacado,
        'complementoSacado': complementoSacado,
        'bairroSacado': bairroSacado,
        'cepSacado': cepSacado,
        'cidadeSacado': cidadeSacado,
        'ufSacado': ufSacado,
        'codigoMulta': codigoMulta,
        'dataMulta': dataMulta?.toIso8601String(),
        'valorMulta': valorMulta,
        'codigoJuros': codigoJuros,
        'dataJuros': dataJuros?.toIso8601String(),
        'valorJuros': valorJuros,
        'codigoDesconto1': codigoDesconto1,
        'dataDesconto1': dataDesconto1?.toIso8601String(),
        'valorDesconto1': valorDesconto1,
        'mensagem1': mensagem1,
        'mensagem2': mensagem2,
        'tipoInscricaoAvalista': tipoInscricaoAvalista?.name,
        'cpfCnpjAvalista': cpfCnpjAvalista,
        'nomeAvalista': nomeAvalista,
        'origemXml': origemXml,
        'criadoEm': criadoEm.toIso8601String(),
        'status': status.name,
        'erros': erros,
      };

  factory Titulo.fromJson(Map<String, dynamic> json) => Titulo(
        id: json['id'],
        seuNumero: json['seuNumero'] ?? '',
        numeroDocumento: json['numeroDocumento'] ?? '',
        especieTitulo: json['especieTitulo'] ?? '01',
        aceite: json['aceite'] ?? 'N',
        dataEmissao: json['dataEmissao'] != null
            ? DateTime.parse(json['dataEmissao'])
            : null,
        dataVencimento: json['dataVencimento'] != null
            ? DateTime.parse(json['dataVencimento'])
            : null,
        valorNominal: (json['valorNominal'] ?? 0.0).toDouble(),
        tipoInscricaoSacado: json['tipoInscricaoSacado'] == 'cpf'
            ? TipoInscricao.cpf
            : TipoInscricao.cnpj,
        cpfCnpjSacado: json['cpfCnpjSacado'] ?? '',
        nomeSacado: json['nomeSacado'] ?? '',
        enderecoSacado: json['enderecoSacado'] ?? '',
        numeroEnderecoSacado: json['numeroEnderecoSacado'] ?? '',
        complementoSacado: json['complementoSacado'] ?? '',
        bairroSacado: json['bairroSacado'] ?? '',
        cepSacado: json['cepSacado'] ?? '',
        cidadeSacado: json['cidadeSacado'] ?? '',
        ufSacado: json['ufSacado'] ?? '',
        codigoMulta: json['codigoMulta'] ?? '0',
        dataMulta:
            json['dataMulta'] != null ? DateTime.parse(json['dataMulta']) : null,
        valorMulta: (json['valorMulta'] ?? 0.0).toDouble(),
        codigoJuros: json['codigoJuros'] ?? '0',
        dataJuros:
            json['dataJuros'] != null ? DateTime.parse(json['dataJuros']) : null,
        valorJuros: (json['valorJuros'] ?? 0.0).toDouble(),
        codigoDesconto1: json['codigoDesconto1'] ?? '0',
        dataDesconto1: json['dataDesconto1'] != null
            ? DateTime.parse(json['dataDesconto1'])
            : null,
        valorDesconto1: (json['valorDesconto1'] ?? 0.0).toDouble(),
        mensagem1: json['mensagem1'] ?? '',
        mensagem2: json['mensagem2'] ?? '',
        tipoInscricaoAvalista: json['tipoInscricaoAvalista'] == 'cpf'
            ? TipoInscricao.cpf
            : json['tipoInscricaoAvalista'] == 'cnpj'
                ? TipoInscricao.cnpj
                : null,
        cpfCnpjAvalista: json['cpfCnpjAvalista'] ?? '',
        nomeAvalista: json['nomeAvalista'] ?? '',
        origemXml: json['origemXml'],
        criadoEm: json['criadoEm'] != null
            ? DateTime.parse(json['criadoEm'])
            : DateTime.now(),
        status: StatusTitulo.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => StatusTitulo.pendente,
        ),
        erros: List<String>.from(json['erros'] ?? []),
      );
}
