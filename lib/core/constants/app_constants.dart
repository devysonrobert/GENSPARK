// core/constants/app_constants.dart
// Constantes globais da aplicação CNAB Master

class AppConstants {
  AppConstants._();

  // Banco Santander
  static const String codigoBanco = '033';
  static const String nomeBanco = 'BANCO SANTANDER';
  static const String versaoLayout = '089';
  static const String versaoLayoutLote = '040';
  static const String densidade = '01600';
  static const String tipoServico = '01'; // Cobrança
  static const String formaLancamento = '01';
  static const String tipoOperacaoRemessa = 'R';
  static const int layoutLinhaLength = 240;

  // Carteiras Santander
  static const Map<String, String> carteiras = {
    '101': 'Simples (101)',
    '102': 'Desconto (102)',
    '104': 'Vendor (104)',
    '201': 'Penhor (201)',
  };

  // Modalidades de carteira
  static const Map<String, String> modalidades = {
    '01': '01 - Simples Com Registro',
    '02': '02 - Simples Sem Registro',
  };

  // Espécies de título
  static const Map<String, String> especiesTitulo = {
    '01': '01 - Duplicata Mercantil',
    '02': '02 - Duplicata de Serviço',
    '03': '03 - Duplicata Rural',
    '04': '04 - Letra de Câmbio',
    '05': '05 - Bilhete de Câmbio',
    '06': '06 - Letra Hipotecária',
    '07': '07 - Letra de Crédito de Exportação',
    '12': '12 - NP - Nota Promissória',
    '17': '17 - Recibo',
    '20': '20 - Apólice de Seguro',
    '98': '98 - Outros',
  };

  // Aceite
  static const Map<String, String> tiposAceite = {
    'A': 'A - Aceite',
    'N': 'N - Não Aceite',
  };

  // Código de juros
  static const Map<String, String> codigosJuros = {
    '0': '0 - Isento',
    '1': '1 - Valor por Dia (RS)',
    '2': '2 - Taxa Mensal (%)',
    '3': '3 - Isento',
  };

  // Código de multa
  static const Map<String, String> codigosMulta = {
    '0': '0 - Sem Multa',
    '1': '1 - Valor Fixo (RS)',
    '2': '2 - Percentual (%)',
  };

  // Código de desconto
  static const Map<String, String> codigosDesconto = {
    '0': '0 - Sem Desconto',
    '1': '1 - Valor Fixo ate Data',
    '2': '2 - Percentual ate Data',
    '3': '3 - Desconto Antecipado por Dia',
  };

  // Código protesto
  static const String codigoSemProtesto = '03';
  static const String codigoProtestarDiasCorridos = '01';

  // Código baixa/devolução
  static const String codigoBaixar = '01';
  static const int diasParaBaixa = 60;

  // Código moeda Real
  static const String codigoMoedaReal = '09';

  // Movimento remessa
  static const String movimentoEntrada = '01';
  static const String movimentoBaixa = '02';
  static const String movimentoProtestar = '03';
  static const String movimentoSustarProtesto = '04';
  static const String movimentoAlterarVencimento = '06';

  // UFs brasileiras
  static const List<String> ufs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  // SharedPreferences keys
  static const String keyEmpresaConfig = 'empresa_config';
  static const String keyTitulos = 'titulos_list';
  static const String keyNumeroSequencial = 'numero_sequencial';
  static const String keyHistoricoRemessas = 'historico_remessas';

  // Feriados bancários 2025 e 2026 (AAAA-MM-DD)
  static const List<String> feriadosBancarios = [
    // 2025
    '2025-01-01', // Ano Novo
    '2025-03-03', // Carnaval (segunda)
    '2025-03-04', // Carnaval (terça)
    '2025-04-18', // Sexta-feira Santa
    '2025-04-19', // Páscoa
    '2025-04-21', // Tiradentes
    '2025-05-01', // Dia do Trabalho
    '2025-06-19', // Corpus Christi
    '2025-09-07', // Independência do Brasil
    '2025-10-12', // Nossa Sra. Aparecida
    '2025-11-02', // Finados
    '2025-11-15', // Proclamação da República
    '2025-11-20', // Consciência Negra
    '2025-12-25', // Natal
    // 2026
    '2026-01-01', // Ano Novo
    '2026-02-16', // Carnaval (segunda)
    '2026-02-17', // Carnaval (terça)
    '2026-04-03', // Sexta-feira Santa
    '2026-04-05', // Páscoa
    '2026-04-21', // Tiradentes
    '2026-05-01', // Dia do Trabalho
    '2026-06-04', // Corpus Christi
    '2026-09-07', // Independência do Brasil
    '2026-10-12', // Nossa Sra. Aparecida
    '2026-11-02', // Finados
    '2026-11-15', // Proclamação da República
    '2026-11-20', // Consciência Negra
    '2026-12-25', // Natal
  ];
}
