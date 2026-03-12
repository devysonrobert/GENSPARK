// presentation/screens/titulos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/titulo_form_modal.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/titulo.dart';
import 'package:intl/intl.dart';

class TitulosScreen extends ConsumerStatefulWidget {
  const TitulosScreen({super.key});

  @override
  ConsumerState<TitulosScreen> createState() => _TitulosScreenState();
}

class _TitulosScreenState extends ConsumerState<TitulosScreen> {
  final Set<String> _selecionados = {};
  final TextEditingController _buscaCtrl = TextEditingController();
  int _pagina = 0;
  static const int _itensPorPagina = 20;

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _abrirFormulario({Titulo? titulo}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TituloFormModal(titulo: titulo),
    );
  }

  Future<void> _removerSelecionados() async {
    final confirmado = await _confirmarRemocao(context, _selecionados.length);
    if (!confirmado || !mounted) return;
    await ref.read(titulosProvider.notifier).removerSelecionados(
        _selecionados.toList());
    setState(() => _selecionados.clear());
    showSuccessToast(context, 'Títulos removidos!');
  }

  Future<bool> _confirmarRemocao(BuildContext ctx, int qtd) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar Remoção'),
            content: Text(
                'Deseja remover $qtd título(s) selecionado(s)?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text('Remover'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final filtro = ref.watch(filtroTitulosProvider);
    final titulosFiltrados = ref.watch(titulosFiltradosProvider);
    final todosTitulos = ref.watch(titulosProvider);

    // Paginação
    final totalPaginas =
        (titulosFiltrados.length / _itensPorPagina).ceil();
    final inicio = _pagina * _itensPorPagina;
    final fim = (inicio + _itensPorPagina).clamp(0, titulosFiltrados.length);
    final titulosPagina = titulosFiltrados.sublist(
        inicio.clamp(0, titulosFiltrados.length),
        fim);

    // Stats
    final validos =
        todosTitulos.where((t) => t.status == StatusTitulo.valido).length;
    final valorTotal = todosTitulos.fold(0.0, (s, t) => s + t.valorNominal);

    return Column(
      children: [
        // ── Barra de Ações ───────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Título'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(currentScreenProvider.notifier)
                    .state = AppScreen.importarXml,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Importar XML'),
              ),
              const Spacer(),
              // Busca
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _buscaCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome, doc, número...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    suffixIcon: filtro.busca.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _buscaCtrl.clear();
                              ref
                                  .read(filtroTitulosProvider.notifier)
                                  .state = filtro.copyWith(busca: '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    ref.read(filtroTitulosProvider.notifier).state =
                        filtro.copyWith(busca: v, pagina: 0);
                    setState(() => _pagina = 0);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Filtro por status
              DropdownButton<StatusTitulo?>(
                value: filtro.status,
                hint: const Text('Todos'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos os status'),
                  ),
                  ...StatusTitulo.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name.toUpperCase()),
                      )),
                ],
                onChanged: (v) {
                  ref.read(filtroTitulosProvider.notifier).state =
                      filtro.copyWith(status: v, clearStatus: v == null);
                  setState(() => _pagina = 0);
                },
              ),
              if (_selecionados.isNotEmpty) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _removerSelecionados,
                  icon: const Icon(Icons.delete, size: 16),
                  label: Text('Remover (${_selecionados.length})'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Tabela ───────────────────────────────────────────
        Expanded(
          child: todosTitulos.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Nenhum título cadastrado',
                  message:
                      'Importe XMLs de NF-e/NFS-e ou cadastre títulos manualmente.',
                  action: ElevatedButton.icon(
                    onPressed: () => _abrirFormulario(),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Título'),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Header da Tabela ──────────────────
                      _TabelaHeader(
                        todosSelecionados: _selecionados.length ==
                            titulosPagina.length && titulosPagina.isNotEmpty,
                        onSelecionarTodos: (v) {
                          setState(() {
                            if (v == true) {
                              _selecionados.addAll(
                                  titulosPagina.map((t) => t.id));
                            } else {
                              _selecionados.removeAll(
                                  titulosPagina.map((t) => t.id));
                            }
                          });
                        },
                        filtro: filtro,
                        onOrdenar: (campo) {
                          final ascendente =
                              filtro.ordenarPor == campo
                                  ? !filtro.ordenarAscendente
                                  : true;
                          ref
                              .read(filtroTitulosProvider.notifier)
                              .state = filtro.copyWith(
                            ordenarPor: campo,
                            ordenarAscendente: ascendente,
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // ── Linhas ────────────────────────────
                      if (titulosPagina.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Nenhum título encontrado com os filtros aplicados',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...titulosPagina.asMap().entries.map((entry) {
                          final i = entry.key;
                          final t = entry.value;
                          return _TituloRow(
                            titulo: t,
                            index: inicio + i + 1,
                            selecionado: _selecionados.contains(t.id),
                            onSelecionar: (v) => setState(() {
                              if (v == true) {
                                _selecionados.add(t.id);
                              } else {
                                _selecionados.remove(t.id);
                              }
                            }),
                            onEditar: () => _abrirFormulario(titulo: t),
                            onDuplicar: () async {
                              await ref
                                  .read(titulosProvider.notifier)
                                  .duplicar(t.id);
                              showInfoToast(
                                  context, 'Título duplicado!');
                            },
                            onRemover: () async {
                              final ok = await _confirmarRemocao(context, 1);
                              if (ok) {
                                await ref
                                    .read(titulosProvider.notifier)
                                    .remover(t.id);
                                showSuccessToast(
                                    context, 'Título removido!');
                              }
                            },
                          );
                        }),
                    ],
                  ),
                ),
        ),

        // ── Rodapé com Paginação e Totais ────────────────────
        Container(
          color: AppColors.surface,
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Text(
                '${todosTitulos.length} título(s) · '
                '${formatarMoeda(valorTotal)} · '
                '$validos válido(s)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (totalPaginas > 1) ...[
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _pagina > 0 ? () => setState(() => _pagina--) : null,
                  iconSize: 20,
                ),
                Text(
                  'Pág. ${_pagina + 1} de $totalPaginas',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _pagina < totalPaginas - 1
                      ? () => setState(() => _pagina++)
                      : null,
                  iconSize: 20,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TabelaHeader extends StatelessWidget {
  final bool todosSelecionados;
  final Function(bool?) onSelecionarTodos;
  final FiltroTitulosState filtro;
  final Function(String) onOrdenar;

  const _TabelaHeader({
    required this.todosSelecionados,
    required this.onSelecionarTodos,
    required this.filtro,
    required this.onOrdenar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: todosSelecionados,
              onChanged: onSelecionarTodos,
            ),
          ),
          SizedBox(
              width: 48,
              child: const Text('#', style: _hStyle)),
          _SortHeader(
            label: 'Seu Número',
            campo: 'seuNumero',
            width: 140,
            filtro: filtro,
            onOrdenar: onOrdenar,
          ),
          _SortHeader(
            label: 'Nº Doc',
            campo: 'numeroDocumento',
            width: 100,
            filtro: filtro,
            onOrdenar: onOrdenar,
          ),
          _SortHeader(
            label: 'Sacado',
            campo: 'nomeSacado',
            width: 200,
            filtro: filtro,
            onOrdenar: onOrdenar,
          ),
          const SizedBox(
            width: 150,
            child: Text('CPF/CNPJ', style: _hStyle),
          ),
          _SortHeader(
            label: 'Vencimento',
            campo: 'dataVencimento',
            width: 110,
            filtro: filtro,
            onOrdenar: onOrdenar,
          ),
          _SortHeader(
            label: 'Valor',
            campo: 'valorNominal',
            width: 120,
            filtro: filtro,
            onOrdenar: onOrdenar,
          ),
          _SortHeader(
            label: 'Status',
            campo: 'status',
            width: 100,
            filtro: filtro,
            onOrdenar: onOrdenar,
          ),
          const SizedBox(width: 100, child: Text('Ações', style: _hStyle)),
        ],
      ),
    );
  }
}

class _SortHeader extends StatelessWidget {
  final String label;
  final String campo;
  final double width;
  final FiltroTitulosState filtro;
  final Function(String) onOrdenar;

  const _SortHeader({
    required this.label,
    required this.campo,
    required this.width,
    required this.filtro,
    required this.onOrdenar,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = filtro.ordenarPor == campo;
    return InkWell(
      onTap: () => onOrdenar(campo),
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            Text(
              label,
              style: _hStyle.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            if (isActive)
              Icon(
                filtro.ordenarAscendente
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 12,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

const _hStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppColors.textSecondary,
  letterSpacing: 0.5,
);

class _TituloRow extends StatefulWidget {
  final Titulo titulo;
  final int index;
  final bool selecionado;
  final Function(bool?) onSelecionar;
  final VoidCallback onEditar;
  final VoidCallback onDuplicar;
  final VoidCallback onRemover;

  const _TituloRow({
    required this.titulo,
    required this.index,
    required this.selecionado,
    required this.onSelecionar,
    required this.onEditar,
    required this.onDuplicar,
    required this.onRemover,
  });

  @override
  State<_TituloRow> createState() => _TituloRowState();
}

class _TituloRowState extends State<_TituloRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.titulo;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: widget.selecionado
            ? AppColors.primary.withValues(alpha: 0.04)
            : _hovered
                ? AppColors.background
                : AppColors.surface,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: widget.selecionado,
                onChanged: widget.onSelecionar,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${widget.index}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                t.seuNumero,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                t.numeroDocumento,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (t.origemXml != null && t.origemXml!.isNotEmpty)
                        Tooltip(
                          message: 'Importado de XML: ${t.origemXml}',
                          child: const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.description_outlined,
                              size: 12,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          t.nomeSacado,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (t.cidadeSacado.isNotEmpty)
                    Text(
                      '${t.cidadeSacado}/${t.ufSacado}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 150,
              child: Text(
                _formatarDoc(
                    t.cpfCnpjSacado, t.tipoInscricaoSacado),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(
              width: 110,
              child: t.dataVencimento != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy')
                              .format(t.dataVencimento!),
                          style: TextStyle(
                            fontSize: 12,
                            color: _vencimentoColor(
                                t.dataVencimento!,
                                isXml: t.origemXml != null &&
                                    t.origemXml!.isNotEmpty),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Indicador visual para XMLs com data vencida
                        if ((t.origemXml != null && t.origemXml!.isNotEmpty) &&
                            t.dataVencimento!.isBefore(DateTime.now()))
                          const Text(
                            'orig. NF-e',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    )
                  : const Text(
                      '⚠ Pendente',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                formatarMoeda(t.valorNominal),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: t.erros.isEmpty
                  ? StatusBadge(status: t.status)
                  : Tooltip(
                      message: t.erros.join('\n'),
                      child: StatusBadge(status: t.status),
                    ),
            ),
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    color: AppColors.info,
                    onPressed: widget.onEditar,
                    tooltip: 'Editar título',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    color: AppColors.textSecondary,
                    onPressed: widget.onDuplicar,
                    tooltip: 'Duplicar título',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: AppColors.error,
                    onPressed: widget.onRemover,
                    tooltip: 'Remover título',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cor do vencimento.
  /// - XMLs importados: datas no passado ficam em laranja (informativo),
  ///   não em vermelho (erro) — pois a data é histórica.
  /// - Títulos manuais: passado = vermelho, próximo 5 dias = laranja.
  Color _vencimentoColor(DateTime data, {bool isXml = false}) {
    final hoje = DateTime.now();
    final diff = data.difference(hoje).inDays;
    if (diff < 0) return isXml ? AppColors.warning : AppColors.error;
    if (diff <= 5) return AppColors.warning;
    return AppColors.textPrimary;
  }

  String _formatarDoc(String doc, TipoInscricao tipo) {
    final limpo = doc.replaceAll(RegExp(r'\D'), '');
    if (tipo == TipoInscricao.cnpj && limpo.length == 14) {
      return '${limpo.substring(0, 2)}.${limpo.substring(2, 5)}.${limpo.substring(5, 8)}/${limpo.substring(8, 12)}-${limpo.substring(12)}';
    } else if (tipo == TipoInscricao.cpf && limpo.length == 11) {
      return '${limpo.substring(0, 3)}.${limpo.substring(3, 6)}.${limpo.substring(6, 9)}-${limpo.substring(9)}';
    }
    return doc;
  }
}
