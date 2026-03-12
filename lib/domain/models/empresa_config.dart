// domain/models/empresa_config.dart
// Modelo de configuração da empresa cedente

class EmpresaConfig {
  // Dados da Empresa
  final String razaoSocial;
  final String cnpj;
  final String endereco;
  final String numero;
  final String complemento;
  final String cep;
  final String cidade;
  final String estado;

  // Dados Bancários Santander
  final String codigoBanco; // Fixo: 033
  final String agencia; // 4 dígitos
  final String digitoAgencia;
  final String contaCorrente; // 8 dígitos
  final String digitoConta;
  final String codigoCedente; // 7 dígitos (convênio)
  final String carteira; // 101, 102, 104, 201
  final String modalidade; // 01, 02
  final int numeroSequencial; // 6 dígitos auto-incremento
  final String tipoServico; // Fixo: 01

  const EmpresaConfig({
    required this.razaoSocial,
    required this.cnpj,
    required this.endereco,
    required this.numero,
    required this.complemento,
    required this.cep,
    required this.cidade,
    required this.estado,
    this.codigoBanco = '033',
    required this.agencia,
    required this.digitoAgencia,
    required this.contaCorrente,
    required this.digitoConta,
    required this.codigoCedente,
    required this.carteira,
    required this.modalidade,
    required this.numeroSequencial,
    this.tipoServico = '01',
  });

  bool get isConfigured =>
      razaoSocial.isNotEmpty &&
      cnpj.isNotEmpty &&
      agencia.isNotEmpty &&
      contaCorrente.isNotEmpty &&
      codigoCedente.isNotEmpty &&
      carteira.isNotEmpty;

  EmpresaConfig copyWith({
    String? razaoSocial,
    String? cnpj,
    String? endereco,
    String? numero,
    String? complemento,
    String? cep,
    String? cidade,
    String? estado,
    String? codigoBanco,
    String? agencia,
    String? digitoAgencia,
    String? contaCorrente,
    String? digitoConta,
    String? codigoCedente,
    String? carteira,
    String? modalidade,
    int? numeroSequencial,
    String? tipoServico,
  }) {
    return EmpresaConfig(
      razaoSocial: razaoSocial ?? this.razaoSocial,
      cnpj: cnpj ?? this.cnpj,
      endereco: endereco ?? this.endereco,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      cep: cep ?? this.cep,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      codigoBanco: codigoBanco ?? this.codigoBanco,
      agencia: agencia ?? this.agencia,
      digitoAgencia: digitoAgencia ?? this.digitoAgencia,
      contaCorrente: contaCorrente ?? this.contaCorrente,
      digitoConta: digitoConta ?? this.digitoConta,
      codigoCedente: codigoCedente ?? this.codigoCedente,
      carteira: carteira ?? this.carteira,
      modalidade: modalidade ?? this.modalidade,
      numeroSequencial: numeroSequencial ?? this.numeroSequencial,
      tipoServico: tipoServico ?? this.tipoServico,
    );
  }

  Map<String, dynamic> toJson() => {
        'razaoSocial': razaoSocial,
        'cnpj': cnpj,
        'endereco': endereco,
        'numero': numero,
        'complemento': complemento,
        'cep': cep,
        'cidade': cidade,
        'estado': estado,
        'codigoBanco': codigoBanco,
        'agencia': agencia,
        'digitoAgencia': digitoAgencia,
        'contaCorrente': contaCorrente,
        'digitoConta': digitoConta,
        'codigoCedente': codigoCedente,
        'carteira': carteira,
        'modalidade': modalidade,
        'numeroSequencial': numeroSequencial,
        'tipoServico': tipoServico,
      };

  factory EmpresaConfig.fromJson(Map<String, dynamic> json) => EmpresaConfig(
        razaoSocial: json['razaoSocial'] ?? '',
        cnpj: json['cnpj'] ?? '',
        endereco: json['endereco'] ?? '',
        numero: json['numero'] ?? '',
        complemento: json['complemento'] ?? '',
        cep: json['cep'] ?? '',
        cidade: json['cidade'] ?? '',
        estado: json['estado'] ?? '',
        codigoBanco: json['codigoBanco'] ?? '033',
        agencia: json['agencia'] ?? '',
        digitoAgencia: json['digitoAgencia'] ?? '',
        contaCorrente: json['contaCorrente'] ?? '',
        digitoConta: json['digitoConta'] ?? '',
        codigoCedente: json['codigoCedente'] ?? '',
        carteira: json['carteira'] ?? '101',
        modalidade: json['modalidade'] ?? '01',
        numeroSequencial: json['numeroSequencial'] ?? 1,
        tipoServico: json['tipoServico'] ?? '01',
      );

  factory EmpresaConfig.empty() => const EmpresaConfig(
        razaoSocial: '',
        cnpj: '',
        endereco: '',
        numero: '',
        complemento: '',
        cep: '',
        cidade: '',
        estado: 'SP',
        codigoBanco: '033',
        agencia: '',
        digitoAgencia: '',
        contaCorrente: '',
        digitoConta: '',
        codigoCedente: '',
        carteira: '101',
        modalidade: '01',
        numeroSequencial: 1,
        tipoServico: '01',
      );
}
