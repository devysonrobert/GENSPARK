// presentation/screens/configuracoes_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/empresa_config.dart';
import '../../domain/validators/validators.dart';

class ConfiguracoesScreen extends ConsumerStatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  ConsumerState<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends ConsumerState<ConfiguracoesScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers Dados da Empresa
  late TextEditingController _razaoSocialCtrl;
  late TextEditingController _cnpjCtrl;
  late TextEditingController _enderecoCtrl;
  late TextEditingController _numeroCtrl;
  late TextEditingController _complementoCtrl;
  late TextEditingController _cepCtrl;
  late TextEditingController _cidadeCtrl;
  String _estado = 'SP';

  // Controllers Dados Bancários
  late TextEditingController _agenciaCtrl;
  late TextEditingController _digitoAgenciaCtrl;
  late TextEditingController _contaCorrenteCtrl;
  late TextEditingController _digitoContaCtrl;
  late TextEditingController _codigoCedenteCtrl;
  String _carteira = '101';
  String _modalidade = '01';
  late TextEditingController _numeroSeqCtrl;

  // Máscaras
  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _digitoContaValido = true;
  String? _digitoContaEsperado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(empresaConfigProvider);
    _razaoSocialCtrl = TextEditingController(text: config.razaoSocial);
    _cnpjCtrl = TextEditingController(text: config.cnpj);
    _enderecoCtrl = TextEditingController(text: config.endereco);
    _numeroCtrl = TextEditingController(text: config.numero);
    _complementoCtrl = TextEditingController(text: config.complemento);
    _cepCtrl = TextEditingController(text: config.cep);
    _cidadeCtrl = TextEditingController(text: config.cidade);
    _estado = config.estado.isEmpty ? 'SP' : config.estado;
    _agenciaCtrl = TextEditingController(text: config.agencia);
    _digitoAgenciaCtrl = TextEditingController(text: config.digitoAgencia);
    _contaCorrenteCtrl = TextEditingController(text: config.contaCorrente);
    _digitoContaCtrl = TextEditingController(text: config.digitoConta);
    _codigoCedenteCtrl = TextEditingController(text: config.codigoCedente);
    _codigoTransmissaoCtrl = TextEditingController(text: config.codigoTransmissao);
    _carteira = config.carteira.isEmpty ? '101' : config.carteira;
    _modalidade = config.modalidade.isEmpty ? '01' : config.modalidade;
    _numeroSeqCtrl = TextEditingController(
        text: config.numeroSequencial.toString().padLeft(6, '0'));
  }

  @override
  void dispose() {
    _razaoSocialCtrl.dispose();
    _cnpjCtrl.dispose();
    _enderecoCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _cepCtrl.dispose();
    _cidadeCtrl.dispose();
    _agenciaCtrl.dispose();
    _digitoAgenciaCtrl.dispose();
    _contaCorrenteCtrl.dispose();
    _digitoContaCtrl.dispose();
    _codigoCedenteCtrl.dispose();
    _codigoTransmissaoCtrl.dispose();
    _numeroSeqCtrl.dispose();
    super.dispose();
  }

  void _validarDigitoConta() {
    final conta = _contaCorrenteCtrl.text.replaceAll(RegExp(r'\D'), '');
    final digito = _digitoContaCtrl.text.trim();
    if (conta.length >= 4 && digito.isNotEmpty) {
      final result =
          ValidadorContaSantander.validarDigitoConta(conta, digito);
      setState(() {
        _digitoContaValido = result.isValid;
        _digitoContaEsperado = result.extra;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final config = EmpresaConfig(
        razaoSocial: _razaoSocialCtrl.text.trim(),
        cnpj: _cnpjCtrl.text.trim(),
        endereco: _enderecoCtrl.text.trim(),
        numero: _numeroCtrl.text.trim(),
        complemento: _complementoCtrl.text.trim(),
        cep: _cepCtrl.text.trim(),
        cidade: _cidadeCtrl.text.trim(),
        estado: _estado,
        agencia: _agenciaCtrl.text.trim().padLeft(4, '0'),
        digitoAgencia: _digitoAgenciaCtrl.text.trim(),
        contaCorrente: _contaCorrenteCtrl.text.trim().padLeft(8, '0'),
        digitoConta: _digitoContaCtrl.text.trim(),
        codigoCedente: _codigoCedenteCtrl.text.trim(),
        codigoTransmissao: _codigoTransmissaoCtrl.text.trim(),
        carteira: _carteira,
        modalidade: _modalidade,
        numeroSequencial:
            int.tryParse(_numeroSeqCtrl.text.replaceAll(RegExp(r'\D'), '')) ??
                1,
        tipoServico: '01',
      );

      await ref.read(empresaConfigProvider.notifier).salvar(config);

      if (mounted) {
        showSuccessToast(context, 'Configurações salvas com sucesso!');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentArea(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Configurações da Empresa',
              subtitle: 'Configure os dados da empresa cedente e informações bancárias Santander',
              actions: [
                ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_salvando ? 'Salvando...' : 'Salvar Configurações'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Coluna Esquerda: Dados da Empresa ─────────
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TitledDivider(title: 'DADOS DA EMPRESA'),
                          _buildField(
                            label: 'Razão Social',
                            required: true,
                            tooltip: 'Nome completo da empresa cedente (30 chars)',
                            child: TextFormField(
                              controller: _razaoSocialCtrl,
                              maxLength: 30,
                              decoration: const InputDecoration(
                                hintText: 'Ex: ACME COMERCIO LTDA',
                                counterText: '',
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Razão Social é obrigatória'
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'CNPJ',
                            required: true,
                            tooltip: 'CNPJ da empresa no formato XX.XXX.XXX/XXXX-XX',
                            child: TextFormField(
                              controller: _cnpjCtrl,
                              inputFormatters: [_cnpjFormatter],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '00.000.000/0000-00',
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'CNPJ é obrigatório';
                                }
                                final r = ValidadorCNPJ.validar(v);
                                return r.isValid ? null : r.error;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildField(
                                  label: 'Logradouro',
                                  child: TextFormField(
                                    controller: _enderecoCtrl,
                                    maxLength: 40,
                                    decoration: const InputDecoration(
                                      hintText: 'Rua, Avenida...',
                                      counterText: '',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  label: 'Número',
                                  child: TextFormField(
                                    controller: _numeroCtrl,
                                    maxLength: 5,
                                    decoration: const InputDecoration(
                                      hintText: '100',
                                      counterText: '',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Complemento',
                            child: TextFormField(
                              controller: _complementoCtrl,
                              maxLength: 20,
                              decoration: const InputDecoration(
                                hintText: 'Sala 1, Andar 2...',
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  label: 'CEP',
                                  required: true,
                                  child: TextFormField(
                                    controller: _cepCtrl,
                                    inputFormatters: [_cepFormatter],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '00000-000',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _buildField(
                                  label: 'Cidade',
                                  required: true,
                                  child: TextFormField(
                                    controller: _cidadeCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'São Paulo',
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Cidade obrigatória'
                                            : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  label: 'Estado',
                                  required: true,
                                  child: DropdownButtonFormField<String>(
                                    value: _estado,
                                    decoration:
                                        const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                                    items: AppConstants.ufs
                                        .map((uf) => DropdownMenuItem(
                                              value: uf,
                                              child: Text(uf),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _estado = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // ── Coluna Direita: Dados Bancários ────────────
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TitledDivider(title: 'DADOS BANCÁRIOS SANTANDER'),
                          // Banco — somente leitura
                          _buildField(
                            label: 'Banco',
                            tooltip: 'Código fixo Santander',
                            child: TextFormField(
                              initialValue: '033 — Banco Santander',
                              readOnly: true,
                              decoration: const InputDecoration(
                                fillColor: Color(0xFFF5F5F5),
                                suffixIcon: Icon(Icons.lock_outline, size: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildField(
                                  label: 'Agência',
                                  required: true,
                                  tooltip: '[H.053-057] 4 dígitos, sem dígito verificador',
                                  child: TextFormField(
                                    controller: _agenciaCtrl,
                                    maxLength: 4,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '0001',
                                      counterText: '',
                                    ),
                                    onChanged: (_) => _validarDigitoConta(),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Obrigatório';
                                      final r = ValidadorContaSantander.validarAgencia(v);
                                      return r.isValid ? null : r.error;
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  label: 'Dígito',
                                  tooltip: 'Dígito verificador da agência',
                                  child: TextFormField(
                                    controller: _digitoAgenciaCtrl,
                                    maxLength: 1,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      counterText: '',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildField(
                                  label: 'Conta Corrente',
                                  required: true,
                                  tooltip: '[H.059-070] 8 dígitos numéricos',
                                  child: TextFormField(
                                    controller: _contaCorrenteCtrl,
                                    maxLength: 8,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '12345678',
                                      counterText: '',
                                    ),
                                    onChanged: (_) => _validarDigitoConta(),
                                    validator: (v) =>
                                        v == null || v.isEmpty
                                            ? 'Conta obrigatória'
                                            : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  label: 'Dígito',
                                  required: true,
                                  tooltip: 'Módulo 11 pesos 2-9',
                                  child: TextFormField(
                                    controller: _digitoContaCtrl,
                                    maxLength: 1,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: InputDecoration(
                                      hintText: '9',
                                      counterText: '',
                                      suffixIcon: _digitoContaValido
                                          ? const Icon(Icons.check_circle,
                                              color: AppColors.success, size: 16)
                                          : Tooltip(
                                              message:
                                                  'Esperado: $_digitoContaEsperado',
                                              child: const Icon(Icons.error,
                                                  color: AppColors.error,
                                                  size: 16),
                                            ),
                                    ),
                                    onChanged: (_) => _validarDigitoConta(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Código do Cedente / Convênio',
                            required: true,
                            tooltip: '[H.033-052] Código de 7 dígitos fornecido pelo Santander',
                            child: TextFormField(
                              controller: _codigoCedenteCtrl,
                              maxLength: 7,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                hintText: '1234567',
                                counterText: '',
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty
                                      ? 'Código do Cedente obrigatório'
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Código de Transmissão',
                            required: true,
                            tooltip: '[H.033-047 / Nota 3] 15 chars alfanuméricos fornecidos pelo Santander (ex: 337100000803385)',
                            child: TextFormField(
                              controller: _codigoTransmissaoCtrl,
                              maxLength: 15,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                hintText: '337100000803385',
                                counterText: '',
                                helperText: 'Informado pelo banco na contratação do CNAB',
                              ),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Código de Transmissão obrigatório'
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  label: 'Carteira',
                                  required: true,
                                  tooltip: 'Carteira de cobrança Santander',
                                  child: DropdownButtonFormField<String>(
                                    value: _carteira,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                    ),
                                    items: AppConstants.carteiras.entries
                                        .map((e) => DropdownMenuItem(
                                              value: e.key,
                                              child: Text(e.value),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _carteira = v!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  label: 'Modalidade',
                                  required: true,
                                  tooltip: 'Com ou sem registro',
                                  child: DropdownButtonFormField<String>(
                                    value: _modalidade,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                    ),
                                    items: AppConstants.modalidades.entries
                                        .map((e) => DropdownMenuItem(
                                              value: e.key,
                                              child: Text(
                                                e.value,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _modalidade = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  label: 'Nº Sequencial Arquivo',
                                  required: true,
                                  tooltip: '[H.158-163] Auto-incrementado a cada remessa gerada',
                                  child: TextFormField(
                                    controller: _numeroSeqCtrl,
                                    maxLength: 6,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '000001',
                                      counterText: '',
                                    ),
                                    validator: (v) =>
                                        v == null || v.isEmpty
                                            ? 'Obrigatório'
                                            : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  label: 'Tipo de Serviço',
                                  tooltip: 'Fixo: 01 = Cobrança',
                                  child: TextFormField(
                                    initialValue: '01 — Cobrança',
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      fillColor: Color(0xFFF5F5F5),
                                      suffixIcon: Icon(
                                        Icons.lock_outline,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Botão Validar Conta
                          OutlinedButton.icon(
                            onPressed: () {
                              _validarDigitoConta();
                              if (_digitoContaValido) {
                                showSuccessToast(context,
                                    'Conta Santander válida! Dígito correto.');
                              } else {
                                showErrorToast(
                                  context,
                                  'Dígito inválido. Esperado: $_digitoContaEsperado',
                                );
                              }
                            },
                            icon: const Icon(Icons.verified, size: 18),
                            label: const Text('Validar Conta Santander'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Botão Salvar bottom
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(_salvando
                    ? 'Salvando...'
                    : 'Salvar Configurações'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    bool required = false,
    String? tooltip,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(
          label: label,
          required: required,
          tooltip: tooltip,
        ),
        child,
      ],
    );
  }
}
