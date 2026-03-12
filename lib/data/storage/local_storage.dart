// data/storage/local_storage.dart
// Persistência local com SharedPreferences

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/empresa_config.dart';
import '../../domain/models/titulo.dart';
import '../../core/constants/app_constants.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    assert(_prefs != null, 'LocalStorage.init() deve ser chamado antes do uso');
    return _prefs!;
  }

  // ── Empresa Config ───────────────────────────────────────────

  static Future<void> salvarEmpresaConfig(EmpresaConfig config) async {
    final json = jsonEncode(config.toJson());
    await prefs.setString(AppConstants.keyEmpresaConfig, json);
  }

  static EmpresaConfig? carregarEmpresaConfig() {
    final json = prefs.getString(AppConstants.keyEmpresaConfig);
    if (json == null || json.isEmpty) return null;
    try {
      return EmpresaConfig.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  // ── Títulos ──────────────────────────────────────────────────

  static Future<void> salvarTitulos(List<Titulo> titulos) async {
    final jsonList = titulos.map((t) => t.toJson()).toList();
    await prefs.setString(AppConstants.keyTitulos, jsonEncode(jsonList));
  }

  static List<Titulo> carregarTitulos() {
    final json = prefs.getString(AppConstants.keyTitulos);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((j) => Titulo.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Número Sequencial ────────────────────────────────────────

  static Future<int> incrementarNumeroSequencial() async {
    final atual = prefs.getInt(AppConstants.keyNumeroSequencial) ?? 1;
    final proximo = atual + 1;
    await prefs.setInt(AppConstants.keyNumeroSequencial, proximo);
    return proximo;
  }

  static int obterNumeroSequencial() {
    return prefs.getInt(AppConstants.keyNumeroSequencial) ?? 1;
  }

  // ── Histórico de Remessas ────────────────────────────────────

  static Future<void> salvarHistoricoRemessa(RemessaHistorico remessa) async {
    final lista = carregarHistoricoRemessas();
    lista.insert(0, remessa);
    // Mantém apenas os últimos 50 registros
    final limitada = lista.take(50).toList();
    await prefs.setString(
      AppConstants.keyHistoricoRemessas,
      jsonEncode(limitada.map((r) => r.toJson()).toList()),
    );
  }

  static List<RemessaHistorico> carregarHistoricoRemessas() {
    final json = prefs.getString(AppConstants.keyHistoricoRemessas);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((j) => RemessaHistorico.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> limparTitulos() async {
    await prefs.remove(AppConstants.keyTitulos);
  }
}

class RemessaHistorico {
  final String nomeArquivo;
  final DateTime dataGeracao;
  final int totalTitulos;
  final double valorTotal;
  final int totalLinhas;
  final int numeroSequencial;

  const RemessaHistorico({
    required this.nomeArquivo,
    required this.dataGeracao,
    required this.totalTitulos,
    required this.valorTotal,
    required this.totalLinhas,
    required this.numeroSequencial,
  });

  Map<String, dynamic> toJson() => {
        'nomeArquivo': nomeArquivo,
        'dataGeracao': dataGeracao.toIso8601String(),
        'totalTitulos': totalTitulos,
        'valorTotal': valorTotal,
        'totalLinhas': totalLinhas,
        'numeroSequencial': numeroSequencial,
      };

  factory RemessaHistorico.fromJson(Map<String, dynamic> json) =>
      RemessaHistorico(
        nomeArquivo: json['nomeArquivo'] ?? '',
        dataGeracao: json['dataGeracao'] != null
            ? DateTime.parse(json['dataGeracao'])
            : DateTime.now(),
        totalTitulos: json['totalTitulos'] ?? 0,
        valorTotal: (json['valorTotal'] ?? 0.0).toDouble(),
        totalLinhas: json['totalLinhas'] ?? 0,
        numeroSequencial: json['numeroSequencial'] ?? 1,
      );
}
