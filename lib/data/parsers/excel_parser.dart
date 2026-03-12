// data/parsers/excel_parser.dart
// Parser de planilha Excel modelo para importação de títulos

import 'package:excel/excel.dart';
import '../../domain/models/titulo.dart';
import '../../domain/validators/validators.dart';

class ExcelImportResult {
  final List<Titulo> titulos;
  final List<ExcelRowError> erros;
  final int totalLinhas;

  const ExcelImportResult({
    required this.titulos,
    required this.erros,
    required this.totalLinhas,
  });
}

class ExcelRowError {
  final int linha;
  final String coluna;
  final String descricao;

  const ExcelRowError({
    required this.linha,
    required this.coluna,
    required this.descricao,
  });
}

class ExcelParser {
  static const List<String> colunas = [
    'nosso_numero',
    'numero_documento',
    'especie',
    'aceite',
    'data_emissao',
    'data_vencimento',
    'valor',
    'sacado_tipo',
    'sacado_documento',
    'sacado_nome',
    'sacado_endereco',
    'sacado_numero',
    'sacado_complemento',
    'sacado_bairro',
    'sacado_cep',
    'sacado_cidade',
    'sacado_uf',
    'codigo_juros',
    'data_juros',
    'valor_juros',
    'codigo_multa',
    'data_multa',
    'valor_multa',
    'codigo_desconto1',
    'data_desconto1',
    'valor_desconto1',
    'mensagem1',
    'mensagem2',
  ];

  static ExcelImportResult importar(List<int> bytes) {
    final titulos = <Titulo>[];
    final erros = <ExcelRowError>[];

    try {
      final excel = Excel.decodeBytes(bytes);

      Sheet? sheet;
      for (final name in excel.tables.keys) {
        sheet = excel.tables[name];
        break;
      }

      if (sheet == null) {
        return ExcelImportResult(
          titulos: [],
          erros: [
            const ExcelRowError(
              linha: 0,
              coluna: 'Arquivo',
              descricao: 'Planilha não encontrada',
            )
          ],
          totalLinhas: 0,
        );
      }

      final rows = sheet.rows;
      if (rows.isEmpty) {
        return ExcelImportResult(
          titulos: [],
          erros: [],
          totalLinhas: 0,
        );
      }

      // Mapeia cabeçalhos
      final headers = <String, int>{};
      final headerRow = rows[0];
      for (int i = 0; i < headerRow.length; i++) {
        final val = headerRow[i]?.value?.toString().toLowerCase().trim() ?? '';
        if (val.isNotEmpty) headers[val] = i;
      }

      int totalLinhas = rows.length - 1;

      for (int rowIdx = 1; rowIdx < rows.length; rowIdx++) {
        final row = rows[rowIdx];
        final rowErros = <ExcelRowError>[];

        String get(String col) {
          final idx = headers[col];
          if (idx == null) return '';
          final cell = row.length > idx ? row[idx] : null;
          return cell?.value?.toString().trim() ?? '';
        }

        final nossoNumero = get('nosso_numero');
        if (nossoNumero.isEmpty) {
          rowErros.add(ExcelRowError(
            linha: rowIdx + 1,
            coluna: 'nosso_numero',
            descricao: 'Nosso Número é obrigatório',
          ));
        }

        final dataVencimentoStr = get('data_vencimento');
        final dataVencimento =
            ValidadorData.parseDDMMAAAA(dataVencimentoStr);
        if (dataVencimento == null && dataVencimentoStr.isNotEmpty) {
          rowErros.add(ExcelRowError(
            linha: rowIdx + 1,
            coluna: 'data_vencimento',
            descricao:
                'Data de vencimento inválida: $dataVencimentoStr (esperado DD/MM/AAAA)',
          ));
        }

        final valorStr = get('valor').replaceAll(',', '.');
        final valor = double.tryParse(valorStr) ?? 0.0;
        if (valor <= 0) {
          rowErros.add(ExcelRowError(
            linha: rowIdx + 1,
            coluna: 'valor',
            descricao: 'Valor deve ser maior que zero',
          ));
        }

        final sacadoDoc = get('sacado_documento').replaceAll(RegExp(r'\D'), '');
        final sacadoTipo = get('sacado_tipo').toUpperCase();
        final isCnpj = sacadoTipo == 'CNPJ' || sacadoDoc.length == 14;

        if (isCnpj) {
          final v = ValidadorCNPJ.validar(sacadoDoc);
          if (!v.isValid) {
            rowErros.add(ExcelRowError(
              linha: rowIdx + 1,
              coluna: 'sacado_documento',
              descricao: v.error ?? 'CNPJ inválido',
            ));
          }
        } else {
          final v = ValidadorCPF.validar(sacadoDoc);
          if (!v.isValid) {
            rowErros.add(ExcelRowError(
              linha: rowIdx + 1,
              coluna: 'sacado_documento',
              descricao: v.error ?? 'CPF inválido',
            ));
          }
        }

        erros.addAll(rowErros);

        if (rowErros.isEmpty) {
          final dataEmissaoStr = get('data_emissao');
          final dataEmissao = ValidadorData.parseDDMMAAAA(dataEmissaoStr);

          final dataJurosStr = get('data_juros');
          final dataJuros = ValidadorData.parseDDMMAAAA(dataJurosStr);

          final dataMultaStr = get('data_multa');
          final dataMulta = ValidadorData.parseDDMMAAAA(dataMultaStr);

          final dataDesc1Str = get('data_desconto1');
          final dataDesc1 = ValidadorData.parseDDMMAAAA(dataDesc1Str);

          final titulo = Titulo(
            seuNumero: nossoNumero.substring(
                0, nossoNumero.length > 15 ? 15 : nossoNumero.length),
            numeroDocumento: get('numero_documento'),
            especieTitulo: get('especie').isEmpty ? '01' : get('especie'),
            aceite: get('aceite').isEmpty ? 'N' : get('aceite'),
            dataEmissao: dataEmissao ?? DateTime.now(),
            dataVencimento: dataVencimento,
            valorNominal: valor,
            tipoInscricaoSacado:
                isCnpj ? TipoInscricao.cnpj : TipoInscricao.cpf,
            cpfCnpjSacado: sacadoDoc,
            nomeSacado: get('sacado_nome'),
            enderecoSacado: get('sacado_endereco'),
            numeroEnderecoSacado: get('sacado_numero'),
            complementoSacado: get('sacado_complemento'),
            bairroSacado: get('sacado_bairro'),
            cepSacado: get('sacado_cep').replaceAll(RegExp(r'\D'), ''),
            cidadeSacado: get('sacado_cidade'),
            ufSacado: get('sacado_uf'),
            codigoJuros: get('codigo_juros').isEmpty ? '0' : get('codigo_juros'),
            dataJuros: dataJuros,
            valorJuros: double.tryParse(
                    get('valor_juros').replaceAll(',', '.')) ??
                0.0,
            codigoMulta:
                get('codigo_multa').isEmpty ? '0' : get('codigo_multa'),
            dataMulta: dataMulta,
            valorMulta: double.tryParse(
                    get('valor_multa').replaceAll(',', '.')) ??
                0.0,
            codigoDesconto1: get('codigo_desconto1').isEmpty
                ? '0'
                : get('codigo_desconto1'),
            dataDesconto1: dataDesc1,
            valorDesconto1: double.tryParse(
                    get('valor_desconto1').replaceAll(',', '.')) ??
                0.0,
            mensagem1: get('mensagem1'),
            mensagem2: get('mensagem2'),
            origemXml: 'Importação Excel',
            status: StatusTitulo.pendente,
          );
          titulos.add(titulo);
        }
      }

      return ExcelImportResult(
        titulos: titulos,
        erros: erros,
        totalLinhas: totalLinhas,
      );
    } catch (e) {
      return ExcelImportResult(
        titulos: [],
        erros: [
          ExcelRowError(
            linha: 0,
            coluna: 'Arquivo',
            descricao: 'Erro ao ler planilha: $e',
          )
        ],
        totalLinhas: 0,
      );
    }
  }

  /// Gera bytes de um arquivo Excel template com as colunas padrão
  static List<int> gerarTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Títulos'];

    // Cabeçalhos
    final headers = [
      'nosso_numero', 'numero_documento', 'especie', 'aceite',
      'data_emissao', 'data_vencimento', 'valor',
      'sacado_tipo', 'sacado_documento', 'sacado_nome',
      'sacado_endereco', 'sacado_numero', 'sacado_complemento',
      'sacado_bairro', 'sacado_cep', 'sacado_cidade', 'sacado_uf',
      'codigo_juros', 'data_juros', 'valor_juros',
      'codigo_multa', 'data_multa', 'valor_multa',
      'codigo_desconto1', 'data_desconto1', 'valor_desconto1',
      'mensagem1', 'mensagem2',
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        TextCellValue(headers[i]),
      );
    }

    // Linha de exemplo
    final exemplo = [
      '000000000000001', 'NF001', '01', 'N',
      '01/01/2025', '30/01/2025', '1500.00',
      'CNPJ', '12345678000195', 'EMPRESA EXEMPLO LTDA',
      'RUA DAS FLORES', '100', 'APT 1', 'CENTRO',
      '01310100', 'SAO PAULO', 'SP',
      '0', '', '0',
      '2', '31/01/2025', '2.00',
      '0', '', '0',
      'REF NF-e 001', '',
    ];

    for (int i = 0; i < exemplo.length; i++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
        TextCellValue(exemplo[i]),
      );
    }

    return excel.encode() ?? [];
  }
}
