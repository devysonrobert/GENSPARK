// presentation/providers/app_providers.dart
// Providers Riverpod para gerenciamento de estado global

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/empresa_config.dart';
import '../../domain/models/titulo.dart';
import '../../domain/validators/validators.dart';
import '../../data/storage/local_storage.dart';

// ══════════════════════════════════════════════════════════════
// EMPRESA CONFIG PROVIDER
// ══════════════════════════════════════════════════════════════

class EmpresaConfigNotifier extends StateNotifier<EmpresaConfig> {
  EmpresaConfigNotifier() : super(EmpresaConfig.empty()) {
    _carregarDoStorage();
  }

  void _carregarDoStorage() {
    final salvo = LocalStorage.carregarEmpresaConfig();
    if (salvo != null) state = salvo;
  }

  Future<void> salvar(EmpresaConfig config) async {
    state = config;
    await LocalStorage.salvarEmpresaConfig(config);
  }

  Future<void> incrementarSequencial() async {
    final proximo = await LocalStorage.incrementarNumeroSequencial();
    state = state.copyWith(numeroSequencial: proximo);
    await LocalStorage.salvarEmpresaConfig(state);
  }
}

final empresaConfigProvider =
    StateNotifierProvider<EmpresaConfigNotifier, EmpresaConfig>(
  (ref) => EmpresaConfigNotifier(),
);

// ══════════════════════════════════════════════════════════════
// TÍTULOS PROVIDER
// ══════════════════════════════════════════════════════════════

class TitulosNotifier extends StateNotifier<List<Titulo>> {
  TitulosNotifier() : super([]) {
    _carregarDoStorage();
  }

  void _carregarDoStorage() {
    state = LocalStorage.carregarTitulos();
    _revalidarTodos();
  }

  Future<void> adicionar(Titulo titulo) async {
    final validado = _validar(titulo);
    state = [...state, validado];
    await _persistir();
  }

  Future<void> adicionarVarios(List<Titulo> titulos) async {
    final validados = titulos.map(_validar).toList();
    state = [...state, ...validados];
    await _persistir();
  }

  Future<void> atualizar(Titulo titulo) async {
    final validado = _validar(titulo);
    state = state.map((t) => t.id == titulo.id ? validado : t).toList();
    await _persistir();
  }

  Future<void> remover(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _persistir();
  }

  Future<void> removerSelecionados(List<String> ids) async {
    state = state.where((t) => !ids.contains(t.id)).toList();
    await _persistir();
  }

  Future<void> limparTodos() async {
    state = [];
    await LocalStorage.limparTitulos();
  }

  Future<void> duplicar(String id) async {
    final original = state.firstWhere((t) => t.id == id);
    final copia = Titulo(
      seuNumero: '${original.seuNumero}_C',
      numeroDocumento: original.numeroDocumento,
      especieTitulo: original.especieTitulo,
      aceite: original.aceite,
      dataEmissao: original.dataEmissao,
      dataVencimento: original.dataVencimento,
      valorNominal: original.valorNominal,
      tipoInscricaoSacado: original.tipoInscricaoSacado,
      cpfCnpjSacado: original.cpfCnpjSacado,
      nomeSacado: original.nomeSacado,
      enderecoSacado: original.enderecoSacado,
      numeroEnderecoSacado: original.numeroEnderecoSacado,
      complementoSacado: original.complementoSacado,
      bairroSacado: original.bairroSacado,
      cepSacado: original.cepSacado,
      cidadeSacado: original.cidadeSacado,
      ufSacado: original.ufSacado,
      codigoMulta: original.codigoMulta,
      dataMulta: original.dataMulta,
      valorMulta: original.valorMulta,
      codigoJuros: original.codigoJuros,
      dataJuros: original.dataJuros,
      valorJuros: original.valorJuros,
      codigoDesconto1: original.codigoDesconto1,
      dataDesconto1: original.dataDesconto1,
      valorDesconto1: original.valorDesconto1,
      mensagem1: original.mensagem1,
      mensagem2: original.mensagem2,
      origemXml: original.origemXml,
    );
    final validado = _validar(copia);
    state = [...state, validado];
    await _persistir();
  }

  void _revalidarTodos() {
    state = state.map(_validar).toList();
  }

  Titulo _validar(Titulo titulo) {
    final erros = ValidadorCamposObrigatorios.validarTitulo(titulo);
    StatusTitulo status;
    if (erros.isEmpty) {
      status = StatusTitulo.valido;
    } else {
      final temErroGrave = erros.any((e) =>
          e.contains('inválido') ||
          e.contains('CNPJ') ||
          e.contains('CPF'));
      status = temErroGrave ? StatusTitulo.invalido : StatusTitulo.pendente;
    }
    return titulo.copyWith(status: status, erros: erros);
  }

  Future<void> _persistir() async {
    await LocalStorage.salvarTitulos(state);
  }

  // Getters computados
  List<Titulo> get validos => state.where((t) => t.status == StatusTitulo.valido).toList();
  List<Titulo> get pendentes => state.where((t) => t.status == StatusTitulo.pendente).toList();
  List<Titulo> get invalidos => state.where((t) => t.status == StatusTitulo.invalido).toList();
  double get valorTotal => state.fold(0.0, (s, t) => s + t.valorNominal);
}

final titulosProvider =
    StateNotifierProvider<TitulosNotifier, List<Titulo>>(
  (ref) => TitulosNotifier(),
);

// ══════════════════════════════════════════════════════════════
// NAVEGAÇÃO PROVIDER
// ══════════════════════════════════════════════════════════════

enum AppScreen {
  dashboard,
  configuracoes,
  importarXml,
  titulos,
  validacao,
  gerarCnab,
}

final currentScreenProvider = StateProvider<AppScreen>(
  (ref) => AppScreen.dashboard,
);

// ══════════════════════════════════════════════════════════════
// FILTRO / BUSCA DE TÍTULOS
// ══════════════════════════════════════════════════════════════

class FiltroTitulosState {
  final String busca;
  final StatusTitulo? status;
  final String ordenarPor;
  final bool ordenarAscendente;
  final int pagina;
  final int itensPorPagina;

  const FiltroTitulosState({
    this.busca = '',
    this.status,
    this.ordenarPor = 'criadoEm',
    this.ordenarAscendente = false,
    this.pagina = 0,
    this.itensPorPagina = 20,
  });

  FiltroTitulosState copyWith({
    String? busca,
    StatusTitulo? status,
    bool clearStatus = false,
    String? ordenarPor,
    bool? ordenarAscendente,
    int? pagina,
    int? itensPorPagina,
  }) {
    return FiltroTitulosState(
      busca: busca ?? this.busca,
      status: clearStatus ? null : (status ?? this.status),
      ordenarPor: ordenarPor ?? this.ordenarPor,
      ordenarAscendente: ordenarAscendente ?? this.ordenarAscendente,
      pagina: pagina ?? this.pagina,
      itensPorPagina: itensPorPagina ?? this.itensPorPagina,
    );
  }
}

final filtroTitulosProvider =
    StateProvider<FiltroTitulosState>((ref) => const FiltroTitulosState());

final titulosFiltradosProvider = Provider<List<Titulo>>((ref) {
  final todos = ref.watch(titulosProvider);
  final filtro = ref.watch(filtroTitulosProvider);

  var lista = todos.toList();

  // Filtro por status
  if (filtro.status != null) {
    lista = lista.where((t) => t.status == filtro.status).toList();
  }

  // Filtro por busca
  if (filtro.busca.isNotEmpty) {
    final busca = filtro.busca.toLowerCase();
    lista = lista.where((t) {
      return t.nomeSacado.toLowerCase().contains(busca) ||
          t.cpfCnpjSacado.contains(busca) ||
          t.seuNumero.toLowerCase().contains(busca) ||
          t.numeroDocumento.toLowerCase().contains(busca);
    }).toList();
  }

  // Ordenação
  lista.sort((a, b) {
    int cmp = 0;
    switch (filtro.ordenarPor) {
      case 'nomeSacado':
        cmp = a.nomeSacado.compareTo(b.nomeSacado);
        break;
      case 'valorNominal':
        cmp = a.valorNominal.compareTo(b.valorNominal);
        break;
      case 'dataVencimento':
        final da = a.dataVencimento ?? DateTime(2099);
        final db = b.dataVencimento ?? DateTime(2099);
        cmp = da.compareTo(db);
        break;
      case 'seuNumero':
        cmp = a.seuNumero.compareTo(b.seuNumero);
        break;
      case 'status':
        cmp = a.status.index.compareTo(b.status.index);
        break;
      default:
        cmp = a.criadoEm.compareTo(b.criadoEm);
    }
    return filtro.ordenarAscendente ? cmp : -cmp;
  });

  return lista;
});

// ══════════════════════════════════════════════════════════════
// RESULTADO DA ÚLTIMA GERAÇÃO CNAB
// ══════════════════════════════════════════════════════════════

class CnabGeradoState {
  final String? conteudo;
  final String? nomeArquivo;
  final DateTime? dataGeracao;
  final int totalLinhas;
  final int totalBytes;

  const CnabGeradoState({
    this.conteudo,
    this.nomeArquivo,
    this.dataGeracao,
    this.totalLinhas = 0,
    this.totalBytes = 0,
  });

  bool get gerado => conteudo != null;
}

final cnabGeradoProvider =
    StateProvider<CnabGeradoState>((ref) => const CnabGeradoState());

// ══════════════════════════════════════════════════════════════
// HISTÓRICO DE REMESSAS
// ══════════════════════════════════════════════════════════════

final historicoRemessasProvider = Provider<List<RemessaHistorico>>((ref) {
  return LocalStorage.carregarHistoricoRemessas();
});

final historicoRefreshProvider = StateProvider<int>((ref) => 0);

// ══════════════════════════════════════════════════════════════
// ÚLTIMO ARQUIVO GERADO (para validação)
// ══════════════════════════════════════════════════════════════

/// Expõe o conteúdo do último arquivo CNAB gerado para a tela de validação
final ultimoArquivoGeradoProvider = Provider<String?>((ref) {
  final cnabGerado = ref.watch(cnabGeradoProvider);
  return cnabGerado.conteudo;
});

// ══════════════════════════════════════════════════════════════
// ÍNDICE DE PÁGINA ATUAL (para navegação programática)
// ══════════════════════════════════════════════════════════════

/// Provider que mapeia índice inteiro → AppScreen para compatibilidade
/// com código que usa índice numérico de navegação
final currentPageIndexProvider = StateProvider<int>((ref) {
  final screen = ref.watch(currentScreenProvider);
  return screen.index;
});

// ══════════════════════════════════════════════════════════════
// RELATÓRIO DE VALIDAÇÃO (para integração com geração)
// ══════════════════════════════════════════════════════════════

// Importado aqui para uso nos providers de integração
// RelatorioValidacao é importado inline onde necessário
