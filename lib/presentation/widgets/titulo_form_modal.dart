// presentation/widgets/titulo_form_modal.dart
// Modal completo para cadastro/edição de título CNAB 240
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/titulo.dart';
import '../../domain/validators/validators.dart';

class TituloFormModal extends ConsumerStatefulWidget {
  final Titulo? titulo; // null = novo título

  const TituloFormModal({super.key, this.titulo});

  @override
  ConsumerState<TituloFormModal> createState() => _TituloFormModalState();
}

class _TituloFormModalState extends ConsumerState<TituloFormModal> {
  final _formKey = GlobalKey<FormState>();

  // Título
  late TextEditingController _seuNumeroCtrl;
  late TextEditingController _numDocCtrl;
  String _especieTitulo = '01';
  String _aceite = 'N';
  DateTime? _dataEmissao;
  DateTime? _dataVencimento;
  late TextEditingController _valorCtrl;

  // Sacado
  TipoInscricao _tipoInscricaoSacado = TipoInscricao.cnpj;
  late TextEditingController _docSacadoCtrl;
  late TextEditingController _nomeSacadoCtrl;
  late TextEditingController _enderecoSacadoCtrl;
  late TextEditingController _numEndCtrl;
  late TextEditingController _complementoCtrl;
  late TextEditingController _bairroCtrl;
  late TextEditingController _cepCtrl;
  late TextEditingController _cidadeCtrl;
  String _ufSacado = 'SP';

  // Instruções
  String _codigoMulta = '0';
  DateTime? _dataMulta;
  late TextEditingController _valorMultaCtrl;
  String _codigoJuros = '0';
  DateTime? _dataJuros;
  late TextEditingController _valorJurosCtrl;
  String _codigoDesconto1 = '0';
  DateTime? _dataDesconto1;
  late TextEditingController _valorDesconto1Ctrl;

  // Mensagens
  late TextEditingController _mensagem1Ctrl;
  late TextEditingController _mensagem2Ctrl;

  // Avalista
  TipoInscricao _tipoInscricaoAvalista = TipoInscricao.cnpj;
  late TextEditingController _docAvalistaCtrl;
  late TextEditingController _nomeAvalistaCtrl;
  bool _mostrarAvalista = false;

  // Máscaras
  late MaskTextInputFormatter _cnpjFormatter;
  late MaskTextInputFormatter _cpfFormatter;
  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final t = widget.titulo;

    _cnpjFormatter = MaskTextInputFormatter(
      mask: '##.###.###/####-##',
      filter: {'#': RegExp(r'[0-9]')},
    );
    _cpfFormatter = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {'#': RegExp(r'[0-9]')},
    );

    _seuNumeroCtrl = TextEditingController(text: t?.seuNumero ?? '');
    _numDocCtrl = TextEditingController(text: t?.numeroDocumento ?? '');
    _especieTitulo = t?.especieTitulo ?? '01';
    _aceite = t?.aceite ?? 'N';
    _dataEmissao = t?.dataEmissao;
    _dataVencimento = t?.dataVencimento;
    _valorCtrl = TextEditingController(
        text: t != null && t.valorNominal > 0
            ? t.valorNominal.toStringAsFixed(2)
            : '');

    _tipoInscricaoSacado = t?.tipoInscricaoSacado ?? TipoInscricao.cnpj;
    _docSacadoCtrl = TextEditingController(
        text: _formatarDocDisplay(
            t?.cpfCnpjSacado ?? '', t?.tipoInscricaoSacado ?? TipoInscricao.cnpj));
    _nomeSacadoCtrl = TextEditingController(text: t?.nomeSacado ?? '');
    _enderecoSacadoCtrl = TextEditingController(text: t?.enderecoSacado ?? '');
    _numEndCtrl = TextEditingController(text: t?.numeroEnderecoSacado ?? '');
    _complementoCtrl = TextEditingController(text: t?.complementoSacado ?? '');
    _bairroCtrl = TextEditingController(text: t?.bairroSacado ?? '');
    _cepCtrl = TextEditingController(
        text: t?.cepSacado != null && t!.cepSacado.length == 8
            ? '${t.cepSacado.substring(0, 5)}-${t.cepSacado.substring(5)}'
            : (t?.cepSacado ?? ''));
    _cidadeCtrl = TextEditingController(text: t?.cidadeSacado ?? '');
    _ufSacado =
        t?.ufSacado.isNotEmpty == true ? t!.ufSacado : 'SP';

    _codigoMulta = t?.codigoMulta ?? '0';
    _dataMulta = t?.dataMulta;
    _valorMultaCtrl = TextEditingController(
        text: t != null && t.valorMulta > 0
            ? t.valorMulta.toStringAsFixed(2)
            : '');

    _codigoJuros = t?.codigoJuros ?? '0';
    _dataJuros = t?.dataJuros;
    _valorJurosCtrl = TextEditingController(
        text: t != null && t.valorJuros > 0
            ? t.valorJuros.toStringAsFixed(2)
            : '');

    _codigoDesconto1 = t?.codigoDesconto1 ?? '0';
    _dataDesconto1 = t?.dataDesconto1;
    _valorDesconto1Ctrl = TextEditingController(
        text: t != null && t.valorDesconto1 > 0
            ? t.valorDesconto1.toStringAsFixed(2)
            : '');

    _mensagem1Ctrl = TextEditingController(text: t?.mensagem1 ?? '');
    _mensagem2Ctrl = TextEditingController(text: t?.mensagem2 ?? '');

    _tipoInscricaoAvalista =
        t?.tipoInscricaoAvalista ?? TipoInscricao.cnpj;
    _docAvalistaCtrl = TextEditingController(text: t?.cpfCnpjAvalista ?? '');
    _nomeAvalistaCtrl = TextEditingController(text: t?.nomeAvalista ?? '');
    _mostrarAvalista =
        t?.nomeAvalista.isNotEmpty == true;
  }

  @override
  void dispose() {
    _seuNumeroCtrl.dispose();
    _numDocCtrl.dispose();
    _valorCtrl.dispose();
    _docSacadoCtrl.dispose();
    _nomeSacadoCtrl.dispose();
    _enderecoSacadoCtrl.dispose();
    _numEndCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cepCtrl.dispose();
    _cidadeCtrl.dispose();
    _valorMultaCtrl.dispose();
    _valorJurosCtrl.dispose();
    _valorDesconto1Ctrl.dispose();
    _mensagem1Ctrl.dispose();
    _mensagem2Ctrl.dispose();
    _docAvalistaCtrl.dispose();
    _nomeAvalistaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      final titulo = Titulo(
        id: widget.titulo?.id,
        seuNumero: _seuNumeroCtrl.text.trim(),
        numeroDocumento: _numDocCtrl.text.trim(),
        especieTitulo: _especieTitulo,
        aceite: _aceite,
        dataEmissao: _dataEmissao,
        dataVencimento: _dataVencimento,
        valorNominal: double.tryParse(
                _valorCtrl.text.replaceAll(',', '.')) ??
            0.0,
        tipoInscricaoSacado: _tipoInscricaoSacado,
        cpfCnpjSacado:
            _docSacadoCtrl.text.replaceAll(RegExp(r'\D'), ''),
        nomeSacado: _nomeSacadoCtrl.text.trim(),
        enderecoSacado: _enderecoSacadoCtrl.text.trim(),
        numeroEnderecoSacado: _numEndCtrl.text.trim(),
        complementoSacado: _complementoCtrl.text.trim(),
        bairroSacado: _bairroCtrl.text.trim(),
        cepSacado: _cepCtrl.text.replaceAll(RegExp(r'\D'), ''),
        cidadeSacado: _cidadeCtrl.text.trim(),
        ufSacado: _ufSacado,
        codigoMulta: _codigoMulta,
        dataMulta: _dataMulta,
        valorMulta: double.tryParse(
                _valorMultaCtrl.text.replaceAll(',', '.')) ??
            0.0,
        codigoJuros: _codigoJuros,
        dataJuros: _dataJuros,
        valorJuros: double.tryParse(
                _valorJurosCtrl.text.replaceAll(',', '.')) ??
            0.0,
        codigoDesconto1: _codigoDesconto1,
        dataDesconto1: _dataDesconto1,
        valorDesconto1: double.tryParse(
                _valorDesconto1Ctrl.text.replaceAll(',', '.')) ??
            0.0,
        mensagem1: _mensagem1Ctrl.text.trim(),
        mensagem2: _mensagem2Ctrl.text.trim(),
        tipoInscricaoAvalista:
            _mostrarAvalista ? _tipoInscricaoAvalista : null,
        cpfCnpjAvalista: _mostrarAvalista
            ? _docAvalistaCtrl.text.replaceAll(RegExp(r'\D'), '')
            : '',
        nomeAvalista:
            _mostrarAvalista ? _nomeAvalistaCtrl.text.trim() : '',
        origemXml: widget.titulo?.origemXml,
      );

      if (widget.titulo != null) {
        await ref.read(titulosProvider.notifier).atualizar(titulo);
      } else {
        await ref.read(titulosProvider.notifier).adicionar(titulo);
      }

      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(
          context,
          widget.titulo != null
              ? 'Título atualizado!'
              : 'Título adicionado!',
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _selecionarData(
      BuildContext context, Function(DateTime) onSelecionado,
      {DateTime? inicial, bool permitirPassado = true}) async {
    final data = await showDatePicker(
      context: context,
      initialDate: inicial ?? DateTime.now(),
      firstDate:
          permitirPassado ? DateTime(2020) : DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (data != null) onSelecionado(data);
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.titulo != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.all(40),
      child: SizedBox(
        width: 900,
        height: MediaQuery.of(context).size.height * 0.92,
        child: Column(
          children: [
            // ── Header do Modal ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(
                    isEdicao ? Icons.edit : Icons.add_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdicao ? 'Editar Título' : 'Novo Título',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Formulário ────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha 1: Dados do Título
                      const TitledDivider(title: 'DADOS DO TÍTULO'),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: 'Seu Número (Nosso Número)',
                              required: true,
                              tooltip: '[P.038-057] Identificador do título na empresa (15 chars)',
                              child: TextFormField(
                                controller: _seuNumeroCtrl,
                                maxLength: 15,
                                decoration: const InputDecoration(
                                    hintText: '000000000000001',
                                    counterText: ''),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Obrigatório'
                                        : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Número do Documento',
                              tooltip: '[P.063-072] Nº da NF ou referência (10 chars)',
                              child: TextFormField(
                                controller: _numDocCtrl,
                                maxLength: 10,
                                decoration: const InputDecoration(
                                    hintText: 'NF-001',
                                    counterText: ''),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Espécie',
                              tooltip: '[P.102-105] Tipo de documento de cobrança',
                              child: DropdownButtonFormField<String>(
                                value: _especieTitulo,
                                decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12)),
                                items: AppConstants.especiesTitulo.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _especieTitulo = v!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Aceite',
                              tooltip: '[P.106-106] Aceite do título',
                              child: DropdownButtonFormField<String>(
                                value: _aceite,
                                decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12)),
                                items: AppConstants.tiposAceite.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _aceite = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: 'Data de Emissão',
                              tooltip: '[P.107-114] Data de emissão do documento',
                              child: InkWell(
                                onTap: () => _selecionarData(
                                  context,
                                  (d) => setState(() => _dataEmissao = d),
                                  inicial: _dataEmissao,
                                  permitirPassado: true,
                                ),
                                child: InputDecorator(
                                  decoration: const InputDecoration(),
                                  child: Text(
                                    _dataEmissao != null
                                        ? ValidadorData.formatarDisplay(
                                            _dataEmissao)
                                        : 'Selecionar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _dataEmissao != null
                                          ? AppColors.textPrimary
                                          : AppColors.inputBorder,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Data de Vencimento',
                              required: true,
                              tooltip: '[P.073-080] Data de vencimento do boleto (DDMMAAAA)',
                              child: InkWell(
                                onTap: () => _selecionarData(
                                  context,
                                  (d) =>
                                      setState(() => _dataVencimento = d),
                                  inicial: _dataVencimento,
                                  permitirPassado: false,
                                ),
                                child: InputDecorator(
                                  decoration: const InputDecoration(),
                                  child: Text(
                                    _dataVencimento != null
                                        ? ValidadorData.formatarDisplay(
                                            _dataVencimento)
                                        : 'Selecionar data *',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _dataVencimento != null
                                          ? AppColors.textPrimary
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Valor Nominal (R\$)',
                              required: true,
                              tooltip: '[P.081-095] Valor do título em reais (2 decimais)',
                              child: TextFormField(
                                controller: _valorCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9,.]')),
                                ],
                                decoration: const InputDecoration(
                                    hintText: '0,00',
                                    prefixText: 'R\$ '),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Obrigatório';
                                  }
                                  final val = double.tryParse(
                                      v.replaceAll(',', '.'));
                                  if (val == null || val <= 0) {
                                    return 'Valor deve ser maior que zero';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Dados do Sacado
                      const TitledDivider(title: 'DADOS DO SACADO (PAGADOR)'),
                      Row(
                        children: [
                          // Tipo inscrição
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel(
                                  label: 'Tipo Inscrição', required: true),
                              Row(
                                children: [
                                  Radio<TipoInscricao>(
                                    value: TipoInscricao.cpf,
                                    groupValue: _tipoInscricaoSacado,
                                    onChanged: (v) => setState(() {
                                      _tipoInscricaoSacado = v!;
                                      _docSacadoCtrl.clear();
                                    }),
                                    activeColor: AppColors.primary,
                                  ),
                                  const Text('CPF',
                                      style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 16),
                                  Radio<TipoInscricao>(
                                    value: TipoInscricao.cnpj,
                                    groupValue: _tipoInscricaoSacado,
                                    onChanged: (v) => setState(() {
                                      _tipoInscricaoSacado = v!;
                                      _docSacadoCtrl.clear();
                                    }),
                                    activeColor: AppColors.primary,
                                  ),
                                  const Text('CNPJ',
                                      style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: _tipoInscricaoSacado == TipoInscricao.cpf
                                  ? 'CPF do Sacado'
                                  : 'CNPJ do Sacado',
                              required: true,
                              tooltip: '[Q.019-033] Documento do sacado (pagador)',
                              child: TextFormField(
                                controller: _docSacadoCtrl,
                                inputFormatters: [
                                  _tipoInscricaoSacado == TipoInscricao.cnpj
                                      ? _cnpjFormatter
                                      : _cpfFormatter,
                                ],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: _tipoInscricaoSacado ==
                                          TipoInscricao.cnpj
                                      ? '00.000.000/0000-00'
                                      : '000.000.000-00',
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Obrigatório';
                                  }
                                  final limpo = v.replaceAll(
                                      RegExp(r'\D'), '');
                                  if (_tipoInscricaoSacado ==
                                      TipoInscricao.cnpj) {
                                    final r = ValidadorCNPJ.validar(limpo);
                                    return r.isValid ? null : r.error;
                                  } else {
                                    final r = ValidadorCPF.validar(limpo);
                                    return r.isValid ? null : r.error;
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _field(
                              label: 'Nome / Razão Social',
                              required: true,
                              tooltip: '[Q.034-073] Nome do sacado (40 chars)',
                              child: TextFormField(
                                controller: _nomeSacadoCtrl,
                                maxLength: 40,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                    hintText: 'NOME DO PAGADOR',
                                    counterText: ''),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Obrigatório'
                                        : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _field(
                              label: 'Endereço',
                              required: true,
                              tooltip: '[Q.074-113] Logradouro (40 chars)',
                              child: TextFormField(
                                controller: _enderecoSacadoCtrl,
                                maxLength: 40,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                    hintText: 'RUA DAS FLORES',
                                    counterText: ''),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Obrigatório'
                                        : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Número',
                              child: TextFormField(
                                controller: _numEndCtrl,
                                maxLength: 5,
                                decoration: const InputDecoration(
                                    hintText: '100', counterText: ''),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Complemento',
                              child: TextFormField(
                                controller: _complementoCtrl,
                                maxLength: 15,
                                decoration: const InputDecoration(
                                    hintText: 'APT 1',
                                    counterText: ''),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Bairro',
                              child: TextFormField(
                                controller: _bairroCtrl,
                                maxLength: 15,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                    hintText: 'CENTRO',
                                    counterText: ''),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: 'CEP',
                              required: true,
                              tooltip: '[Q.129-136] CEP do sacado (8 dígitos)',
                              child: TextFormField(
                                controller: _cepCtrl,
                                inputFormatters: [_cepFormatter],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    hintText: '00000-000'),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Obrigatório';
                                  final limpo = v.replaceAll(RegExp(r'\D'), '');
                                  if (limpo.length != 8) return 'CEP inválido';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _field(
                              label: 'Cidade',
                              required: true,
                              tooltip: '[Q.137-151] Cidade do sacado (15 chars)',
                              child: TextFormField(
                                controller: _cidadeCtrl,
                                maxLength: 20,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                    hintText: 'SAO PAULO',
                                    counterText: ''),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Obrigatório'
                                        : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'UF',
                              required: true,
                              tooltip: '[Q.152-153] Estado do sacado (2 chars)',
                              child: DropdownButtonFormField<String>(
                                value: _ufSacado,
                                decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12)),
                                items: AppConstants.ufs
                                    .map((uf) => DropdownMenuItem(
                                          value: uf,
                                          child: Text(uf),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _ufSacado = v!),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Instruções de Cobrança
                      const TitledDivider(title: 'INSTRUÇÕES DE COBRANÇA'),
                      Row(
                        children: [
                          // Multa
                          Expanded(
                            child: _field(
                              label: 'Código de Multa',
                              tooltip: '[R.098-099] Tipo de multa pós-vencimento',
                              child: DropdownButtonFormField<String>(
                                value: _codigoMulta,
                                decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12)),
                                items: AppConstants.codigosMulta.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _codigoMulta = v!),
                              ),
                            ),
                          ),
                          if (_codigoMulta != '0') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                label: 'Data da Multa',
                                tooltip: '[R.100-107] Data início da multa (geralmente venc.+1)',
                                child: InkWell(
                                  onTap: () => _selecionarData(
                                    context,
                                    (d) => setState(() => _dataMulta = d),
                                    inicial: _dataMulta,
                                    permitirPassado: false,
                                  ),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(),
                                    child: Text(
                                      _dataMulta != null
                                          ? ValidadorData.formatarDisplay(
                                              _dataMulta)
                                          : 'Selecionar',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                label: _codigoMulta == '1'
                                    ? 'Valor Multa (R\$)'
                                    : 'Percentual Multa (%)',
                                tooltip: '[R.108-122] Valor ou % da multa',
                                child: TextFormField(
                                  controller: _valorMultaCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    hintText: '0,00',
                                    prefixText:
                                        _codigoMulta == '1' ? 'R\$ ' : null,
                                    suffixText:
                                        _codigoMulta == '2' ? '%' : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Juros
                          Expanded(
                            child: _field(
                              label: 'Código de Juros',
                              tooltip: '[P.115-116] Tipo de juros de mora',
                              child: DropdownButtonFormField<String>(
                                value: _codigoJuros,
                                decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12)),
                                items: AppConstants.codigosJuros.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _codigoJuros = v!),
                              ),
                            ),
                          ),
                          if (_codigoJuros != '0' && _codigoJuros != '3') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                label: 'Data Juros',
                                tooltip: '[P.117-124] Data início dos juros',
                                child: InkWell(
                                  onTap: () => _selecionarData(
                                    context,
                                    (d) => setState(() => _dataJuros = d),
                                    inicial: _dataJuros,
                                    permitirPassado: false,
                                  ),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(),
                                    child: Text(
                                      _dataJuros != null
                                          ? ValidadorData.formatarDisplay(
                                              _dataJuros)
                                          : 'Selecionar',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                label: _codigoJuros == '1'
                                    ? 'Valor/Dia (R\$)'
                                    : 'Taxa Mensal (%)',
                                tooltip: '[P.125-139] Juros por dia ou % ao mês',
                                child: TextFormField(
                                  controller: _valorJurosCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    hintText: '0,00',
                                    prefixText:
                                        _codigoJuros == '1' ? 'R\$ ' : null,
                                    suffixText:
                                        _codigoJuros == '2' ? '%' : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Desconto
                          Expanded(
                            child: _field(
                              label: 'Código de Desconto',
                              tooltip: '[P.140-141] Tipo de desconto',
                              child: DropdownButtonFormField<String>(
                                value: _codigoDesconto1,
                                decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12)),
                                items: AppConstants.codigosDesconto.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _codigoDesconto1 = v!),
                              ),
                            ),
                          ),
                          if (_codigoDesconto1 != '0') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                label: 'Data Limite Desconto',
                                tooltip: '[P.142-149] Data limite para desconto',
                                child: InkWell(
                                  onTap: () => _selecionarData(
                                    context,
                                    (d) => setState(
                                        () => _dataDesconto1 = d),
                                    inicial: _dataDesconto1,
                                    permitirPassado: false,
                                  ),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(),
                                    child: Text(
                                      _dataDesconto1 != null
                                          ? ValidadorData.formatarDisplay(
                                              _dataDesconto1)
                                          : 'Selecionar',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                label: _codigoDesconto1 == '1'
                                    ? 'Valor Desconto (R\$)'
                                    : 'Percentual Desconto (%)',
                                tooltip: '[P.150-164] Valor ou % do desconto',
                                child: TextFormField(
                                  controller: _valorDesconto1Ctrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    hintText: '0,00',
                                    prefixText:
                                        _codigoDesconto1 == '1' ? 'R\$ ' : null,
                                    suffixText:
                                        _codigoDesconto1 == '2' ? '%' : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Mensagens
                      const TitledDivider(title: 'INSTRUÇÕES TEXTO'),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: 'Mensagem 1',
                              tooltip: '[R.123-142] Texto impresso no boleto (40 chars)',
                              child: TextFormField(
                                controller: _mensagem1Ctrl,
                                maxLength: 40,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                    hintText: 'Não aceitar após o vencimento',
                                    counterText: ''),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Mensagem 2',
                              tooltip: '[R.143-172] Segunda linha de instrução (40 chars)',
                              child: TextFormField(
                                controller: _mensagem2Ctrl,
                                maxLength: 40,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                    hintText: 'Cobrar multa conforme contrato',
                                    counterText: ''),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Sacador/Avalista
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _mostrarAvalista,
                        onChanged: (v) =>
                            setState(() => _mostrarAvalista = v!),
                        title: const Text(
                          'Informar Sacador/Avalista',
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      if (_mostrarAvalista) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                label: 'Doc. Avalista',
                                tooltip: '[Q.159-173] CPF/CNPJ do sacador/avalista',
                                child: TextFormField(
                                  controller: _docAvalistaCtrl,
                                  maxLength: 14,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: const InputDecoration(
                                      hintText: '00000000000000',
                                      counterText: ''),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _field(
                                label: 'Nome do Avalista',
                                tooltip: '[Q.174-213] Nome do sacador/avalista (40 chars)',
                                child: TextFormField(
                                  controller: _nomeAvalistaCtrl,
                                  maxLength: 40,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                      hintText: 'NOME DO AVALISTA',
                                      counterText: ''),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer do Modal ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Icon(
                            isEdicao ? Icons.save : Icons.add,
                            size: 18,
                          ),
                    label: Text(_salvando
                        ? 'Salvando...'
                        : isEdicao
                            ? 'Salvar Alterações'
                            : 'Adicionar Título'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    bool required = false,
    String? tooltip,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(label: label, required: required, tooltip: tooltip),
        child,
      ],
    );
  }

  String _formatarDocDisplay(String doc, TipoInscricao tipo) {
    final limpo = doc.replaceAll(RegExp(r'\D'), '');
    if (tipo == TipoInscricao.cnpj && limpo.length == 14) {
      return '${limpo.substring(0, 2)}.${limpo.substring(2, 5)}.${limpo.substring(5, 8)}/${limpo.substring(8, 12)}-${limpo.substring(12)}';
    } else if (tipo == TipoInscricao.cpf && limpo.length == 11) {
      return '${limpo.substring(0, 3)}.${limpo.substring(3, 6)}.${limpo.substring(6, 9)}-${limpo.substring(9)}';
    }
    return doc;
  }
}
