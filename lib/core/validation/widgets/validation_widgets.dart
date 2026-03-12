// core/validation/widgets/validation_widgets.dart
// Widgets de UI para validação CNAB 240 — painel, cards de erro, progresso, resumo
// Cores Santander: primário #EC0000, dark #A30000

import 'package:flutter/material.dart';
import '../models/validation_error.dart';
import '../models/validation_report.dart';
import '../models/validation_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cores e helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _corSeveridade(SeveridadeValidacao sev) {
  switch (sev) {
    case SeveridadeValidacao.fatal:
      return const Color(0xFFB00020);
    case SeveridadeValidacao.erro:
      return const Color(0xFFF44336);
    case SeveridadeValidacao.aviso:
      return const Color(0xFFFF9800);
    case SeveridadeValidacao.info:
      return const Color(0xFF2196F3);
  }
}

IconData _iconeSeveridade(SeveridadeValidacao sev) {
  switch (sev) {
    case SeveridadeValidacao.fatal:
      return Icons.dangerous_rounded;
    case SeveridadeValidacao.erro:
      return Icons.error_rounded;
    case SeveridadeValidacao.aviso:
      return Icons.warning_rounded;
    case SeveridadeValidacao.info:
      return Icons.info_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ValidationSummaryCard — Resumo do quality score
// ─────────────────────────────────────────────────────────────────────────────

class ValidationSummaryCard extends StatelessWidget {
  final RelatorioValidacao relatorio;

  const ValidationSummaryCard({super.key, required this.relatorio});

  @override
  Widget build(BuildContext context) {
    final score = relatorio.qualityScore;
    final corScore = score >= 80
        ? const Color(0xFF4CAF50)
        : score >= 50
            ? const Color(0xFFFF9800)
            : const Color(0xFFF44336);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título e status
            Row(
              children: [
                Icon(
                  relatorio.aprovado ? Icons.verified_rounded : Icons.shield_rounded,
                  color: Color(int.parse(relatorio.corStatus.replaceFirst('#', '0xFF'))),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relatorio.statusLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse(relatorio.corStatus.replaceFirst('#', '0xFF'))),
                        ),
                      ),
                      if (relatorio.nomeArquivo != null)
                        Text(
                          relatorio.nomeArquivo!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                // Quality Score circular
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100.0,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(corScore),
                      ),
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: corScore,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de qualidade
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100.0,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(corScore),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score de Qualidade', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text('${score}/100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: corScore)),
              ],
            ),

            const Divider(height: 24),

            // Contadores por severidade
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _contadorBadge('FATAL', relatorio.totalFatais, const Color(0xFFB00020)),
                _contadorBadge('ERROS', relatorio.totalErros, const Color(0xFFF44336)),
                _contadorBadge('AVISOS', relatorio.totalAvisos, const Color(0xFFFF9800)),
                _contadorBadge('INFO', relatorio.totalInfos, const Color(0xFF2196F3)),
              ],
            ),

            if (relatorio.estatisticas != null) ...[
              const Divider(height: 24),
              _estatisticasArquivo(relatorio.estatisticas!),
            ],

            const SizedBox(height: 8),
            Text(
              'Validação em ${relatorio.tempoTotalMs}ms • ${DateTime.now().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contadorBadge(String label, int count, Color cor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cor.withValues(alpha: 0.4)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _estatisticasArquivo(EstatisticasArquivo est) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _statChip(Icons.list_alt, '${est.totalLinhas} linhas'),
        _statChip(Icons.folder_open, '${est.totalLotes} lotes'),
        _statChip(Icons.receipt_long, '${est.totalTitulos} títulos'),
        _statChip(Icons.attach_money,
            'R\$ ${est.valorTotal.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
      ],
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ErrorDetailCard — Card expansível de detalhe de erro
// ─────────────────────────────────────────────────────────────────────────────

class ErrorDetailCard extends StatelessWidget {
  final ErroValidacao erro;
  final VoidCallback? onCorrigir;

  const ErrorDetailCard({
    super.key,
    required this.erro,
    this.onCorrigir,
  });

  @override
  Widget build(BuildContext context) {
    final cor = _corSeveridade(erro.severidade);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cor.withValues(alpha: 0.3), width: 1),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(_iconeSeveridade(erro.severidade), color: cor, size: 18),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                erro.codigo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                erro.descricao,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  erro.labelSeveridade,
                  style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                erro.labelCategoria,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              if (erro.linha != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Linha ${erro.linha}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
              if (erro.posicaoInicio != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Pos ${erro.posicaoInicio}${erro.posicaoFim != null && erro.posicaoFim != erro.posicaoInicio ? '-${erro.posicaoFim}' : ''}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (erro.detalhe != null) ...[
                  _labelValor('Detalhe', erro.detalhe!),
                  const SizedBox(height: 6),
                ],
                if (erro.campoCnab != null) ...[
                  _labelValor('Campo CNAB', erro.campoCnab!),
                  const SizedBox(height: 6),
                ],
                if (erro.sugestaoCorrecao != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          erro.sugestaoCorrecao!,
                          style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                if (erro.referenciaFebraban != null) ...[
                  Row(
                    children: [
                      Icon(Icons.book_outlined, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          erro.referenciaFebraban!,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                if (onCorrigir != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onCorrigir,
                      icon: const Icon(Icons.build_rounded, size: 14),
                      label: const Text('Corrigir', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFEC0000)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelValor(String label, String valor) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Colors.black87),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          TextSpan(text: valor),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ValidationProgressWidget — Barra de progresso em tempo real
// ─────────────────────────────────────────────────────────────────────────────

class ValidationProgressWidget extends StatelessWidget {
  final EstadoValidacao estado;
  final VoidCallback? onCancelar;

  const ValidationProgressWidget({
    super.key,
    required this.estado,
    this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC0000)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    estado.labelFase,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${estado.percentual}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEC0000),
                  ),
                ),
                if (onCancelar != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.stop_circle_outlined, color: Colors.grey),
                    tooltip: 'Cancelar validação',
                    onPressed: onCancelar,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: estado.percentual / 100.0,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC0000)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              estado.mensagem,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ValidationPanel — Painel completo de validação com listas colapsáveis
// ─────────────────────────────────────────────────────────────────────────────

class ValidationPanel extends StatefulWidget {
  final RelatorioValidacao relatorio;
  final VoidCallback? onRevalidar;
  final VoidCallback? onGerarCnab;
  final VoidCallback? onExportarPdf;
  final Function(ErroValidacao)? onCorrigirErro;

  const ValidationPanel({
    super.key,
    required this.relatorio,
    this.onRevalidar,
    this.onGerarCnab,
    this.onExportarPdf,
    this.onCorrigirErro,
  });

  @override
  State<ValidationPanel> createState() => _ValidationPanelState();
}

class _ValidationPanelState extends State<ValidationPanel> {
  String _filtroSeveridade = 'todos';
  String _filtroCategoria = 'todas';
  bool _mostrarChecklist = false;

  List<ErroValidacao> get _errosFiltrados {
    var erros = widget.relatorio.erros;

    if (_filtroSeveridade != 'todos') {
      final sev = SeveridadeValidacao.values.firstWhere(
        (s) => s.name == _filtroSeveridade,
        orElse: () => SeveridadeValidacao.info,
      );
      erros = erros.where((e) => e.severidade == sev).toList();
    }

    if (_filtroCategoria != 'todas') {
      final cat = CategoriaValidacao.values.firstWhere(
        (c) => c.name == _filtroCategoria,
        orElse: () => CategoriaValidacao.estrutural,
      );
      erros = erros.where((e) => e.categoria == cat).toList();
    }

    return erros;
  }

  @override
  Widget build(BuildContext context) {
    final relatorio = widget.relatorio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Resumo ─────────────────────────────────────────────────────────
        ValidationSummaryCard(relatorio: relatorio),
        const SizedBox(height: 16),

        // ── Botões de ação ─────────────────────────────────────────────────
        _botoesAcao(relatorio),
        const SizedBox(height: 16),

        // ── Checklist obrigatório ──────────────────────────────────────────
        _checklistCard(relatorio),
        const SizedBox(height: 16),

        // ── Filtros ─────────────────────────────────────────────────────────
        _painelFiltros(),
        const SizedBox(height: 12),

        // ── Lista de erros ─────────────────────────────────────────────────
        if (_errosFiltrados.isEmpty)
          _semErros()
        else
          ..._gruposDeErros(),
      ],
    );
  }

  Widget _botoesAcao(RelatorioValidacao relatorio) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: widget.onRevalidar,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Revalidar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEC0000),
            foregroundColor: Colors.white,
          ),
        ),
        OutlinedButton.icon(
          onPressed: widget.onExportarPdf,
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
          label: const Text('Exportar PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEC0000),
            side: const BorderSide(color: Color(0xFFEC0000)),
          ),
        ),
        if (relatorio.aprovado || relatorio.temApenasAvisos)
          ElevatedButton.icon(
            onPressed: widget.onGerarCnab,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Gerar CNAB'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
          )
        else
          Tooltip(
            message: 'Corrija os erros antes de gerar o arquivo',
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.block_rounded, size: 16),
              label: const Text('Download Bloqueado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
              ),
            ),
          ),
      ],
    );
  }

  Widget _checklistCard(RelatorioValidacao relatorio) {
    final checklist = relatorio.checklistObrigatorio;
    final total = checklist.length;
    final passaram = checklist.values.where((v) => v).length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => setState(() => _mostrarChecklist = !_mostrarChecklist),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    color: passaram == total ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Checklist Obrigatório — $passaram/$total validações aprovadas',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(_mostrarChecklist ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              if (_mostrarChecklist) ...[
                const Divider(height: 16),
                ...checklist.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            e.value ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: e.value ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(e.key, style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _painelFiltros() {
    return Row(
      children: [
        const Text('Filtrar:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _filtroSeveridade,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'todos', child: Text('Todos', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'fatal', child: Text('Fatal', style: TextStyle(fontSize: 13, color: Color(0xFFB00020)))),
            DropdownMenuItem(value: 'erro', child: Text('Erro', style: TextStyle(fontSize: 13, color: Color(0xFFF44336)))),
            DropdownMenuItem(value: 'aviso', child: Text('Aviso', style: TextStyle(fontSize: 13, color: Color(0xFFFF9800)))),
            DropdownMenuItem(value: 'info', child: Text('Info', style: TextStyle(fontSize: 13, color: Color(0xFF2196F3)))),
          ],
          onChanged: (v) => setState(() => _filtroSeveridade = v ?? 'todos'),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _filtroCategoria,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'todas', child: Text('Todas categorias', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'estrutural', child: Text('Estrutural', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'headerArquivo', child: Text('Header Arquivo', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'headerLote', child: Text('Header Lote', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'segmentoP', child: Text('Segmento P', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'segmentoQ', child: Text('Segmento Q', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'segmentoR', child: Text('Segmento R', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'negocio', child: Text('Negócio', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'algoritmo', child: Text('Algoritmo', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'santander', child: Text('Santander', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (v) => setState(() => _filtroCategoria = v ?? 'todas'),
        ),
        const Spacer(),
        Text(
          '${_errosFiltrados.length} ocorrências',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  List<Widget> _gruposDeErros() {
    final grupos = <SeveridadeValidacao, List<ErroValidacao>>{
      SeveridadeValidacao.fatal: [],
      SeveridadeValidacao.erro: [],
      SeveridadeValidacao.aviso: [],
      SeveridadeValidacao.info: [],
    };

    for (final erro in _errosFiltrados) {
      grupos[erro.severidade]?.add(erro);
    }

    final widgets = <Widget>[];

    for (final entry in grupos.entries) {
      if (entry.value.isEmpty) continue;

      final cor = _corSeveridade(entry.key);
      final icone = _iconeSeveridade(entry.key);
      final label = entry.value.first.labelSeveridade;

      widgets.add(_grupoExpandivel(label, icone, cor, entry.value));
      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  Widget _grupoExpandivel(
      String titulo, IconData icone, Color cor, List<ErroValidacao> erros) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cor.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        leading: Icon(icone, color: cor, size: 20),
        title: Row(
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${erros.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        initiallyExpanded: erros.first.severidade == SeveridadeValidacao.fatal,
        children: erros
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: ErrorDetailCard(
                    erro: e,
                    onCorrigir: widget.onCorrigirErro != null
                        ? () => widget.onCorrigirErro!(e)
                        : null,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _semErros() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF4CAF50), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Nenhum problema encontrado!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 8),
            Text(
              _filtroSeveridade != 'todos' || _filtroCategoria != 'todas'
                  ? 'Nenhuma ocorrência para os filtros selecionados'
                  : 'O arquivo CNAB 240 está em conformidade com as regras FEBRABAN/Santander',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
