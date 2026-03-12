// core/validation/rules/santander_specific.dart
// Regras específicas do Santander e dicionário de ocorrências de retorno
// Baseado no manual Santander CNAB 240 Cobrança

import '../models/validation_error.dart';
import '../models/validation_result.dart';

/// Dicionário de ocorrências de retorno Santander CNAB 240
class DicionarioOcorrenciasSantander {
  static const Map<String, String> ocorrencias = {
    '01': 'Entrada de Título em Cobrança (Instrução inicial aceita)',
    '02': 'Entrada Confirmada — Título registrado no banco',
    '03': 'Entrada Rejeitada — Verificar pendências nos códigos de erros',
    '06': 'Liquidação Normal — Título pago no vencimento',
    '07': 'Liquidação Parcial — Pagamento parcial do título',
    '09': 'Baixa Automática — Título baixado por decurso de prazo',
    '10': 'Baixa Confirmada — Solicitação de baixa processada',
    '11': 'Baixa Rejeitada — Verifique os dados do título',
    '12': 'Abatimento Concedido — Valor de abatimento aplicado',
    '13': 'Abatimento Cancelado — Cancelamento de abatimento processado',
    '14': 'Vencimento Alterado — Nova data de vencimento registrada',
    '15': 'Desconto Concedido — Instrução de desconto aceita',
    '16': 'Instrução Rejeitada — Código de instrução não processado',
    '17': 'Alteração de Dados Rejeitada — Dados inválidos para alteração',
    '18': 'Acerto de Depósito — Ajuste de valor processado',
    '19': 'Confirmação de Recebimento de Instrução de Protesto',
    '20': 'Confirmação de Recebimento de Instrução de Sustação',
    '21': 'Confirmação de Recebimento de Instrução de Não Protestar',
    '22': 'Título com Pagamento Cancelado',
    '23': 'Remessa a Cartório',
    '24': 'Retirada de Cartório e Manutenção em Carteira',
    '25': 'Protestado e Baixado (Baixa por ter sido protestado)',
    '26': 'Instrução de Protesto Rejeitada',
    '27': 'Confirmação do Pedido de Alteração de Outros Dados',
    '28': 'Débito de Tarifas/Custas',
    '29': 'Ocorrência do Pagador',
    '30': 'Alteração de Outros Dados Rejeitada',
    '31': 'Confirmação da Alteração de Dados de Pagamento',
    '32': 'Confirmação da Alteração da Opção de Pagamento Parcial',
    '33': 'Confirmação de E-mail/SMS Enviado ao Pagador',
    '34': 'Confirmação de Cancelamento de E-mail/SMS',
    '35': 'Desagendamento do Débito Automático Confirmado',
    '36': 'Agendamento de Débito Automático',
    '37': 'Liquidação por Conta (Pagamento Parcial em Cartório)',
    '38': 'Liquidação por Saldo (Liquidação com Saldo)',
    '39': 'Título Cancelado por Instrução do Cedente',
    '40': 'Baixa Programada — Título baixado por prazo',
    '41': 'Transferência de Carteira/Modalidade',
    '42': 'Entrada em Negativação Expressa',
    '43': 'Confirmação de Recebimento de Instrução para Negativação',
    '44': 'Confirmação de Exclusão de Instrução de Negativação',
    '45': 'Negativação Expressa Confirmada',
    '46': 'Exclusão de Negativação Expressa Confirmada',
    '47': 'Negativação Expressa Rejeitada',
    '48': 'Exclusão de Negativação Expressa Rejeitada',
    '49': 'Baixa por Dação em Pagamento',
    '50': 'Transferência Cedente — Título transferido para outro cedente',
    '51': 'Tarifa de Manutenção de Títulos Vencidos',
    '52': 'Débito de Custo de Transferência',
    '53': 'Registro Rejeitado — Título já existe na base',
    '54': 'Título Transformado em Regime de Negativação',
    '55': 'Transferência para Negativação Rejeitada',
    '56': 'Cancelamento da Negativação Confirmado',
    '57': 'Cancelamento da Negativação Rejeitado',
    '58': 'Exclusão do Registro de Negativação Confirmado',
    '59': 'Exclusão do Registro de Negativação Rejeitado',
    '60': 'Processo de Negativação Suspenso',
    '61': 'Suspensão do Processo de Negativação Rejeitada',
    '62': 'Baixa por Cheque Devolvido',
    '63': 'Título Colocado em Perdas e Danos',
    '64': 'Liquidação Extrajudicial',
    '65': 'Liquidação em Cartório',
    '66': 'Liquidação por Pagamento em Cheque em Cartório',
    '67': 'Cancelamento de Título Negativado',
    '68': 'Liquidação de Título Negativado',
    '69': 'Liquidação Parcial de Título Negativado',
    '70': 'Manutenção de Título Vencido — Tarifa Cobrada',
    '71': 'Alteração de Dados Acata — Alteração executada',
    '72': 'Instrução Aceita — Instrução de cobrança registrada',
    '73': 'Confirmação de Entrada de Título em Cobrança Especial',
    '74': 'Confirmação de Entrada em Cobrança Simples — Título ativo',
  };

  /// Retorna a descrição de um código de ocorrência
  static String descricao(String codigo) {
    return ocorrencias[codigo] ??
        'Código de ocorrência desconhecido: $codigo';
  }

  /// Verifica se é ocorrência de sucesso (liquidação)
  static bool isLiquidado(String codigo) {
    return {'06', '07', '37', '38', '65', '66', '68', '69'}.contains(codigo);
  }

  /// Verifica se é ocorrência de rejeição
  static bool isRejeitado(String codigo) {
    return {
      '03', '11', '16', '17', '26', '30', '47',
      '48', '53', '57', '59', '61',
    }.contains(codigo);
  }

  /// Verifica se é ocorrência de baixa
  static bool isBaixado(String codigo) {
    return {'09', '10', '25', '39', '40', '49'}.contains(codigo);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class RegraSantanderEspecifica {
  /// SS001 — Código banco Santander deve ser 033 (não 033 nem qualquer outro)
  static ResultadoRegra sS001CodigoBancoSantander033(
      String headerArquivo, int numLinha) {
    final sw = Stopwatch()..start();
    if (headerArquivo.length < 3) {
      return ResultadoRegra.sucesso('SS001', tempoMs: sw.elapsedMilliseconds);
    }

    final banco = headerArquivo.substring(0, 3);
    if (banco != '033') {
      return ResultadoRegra.falha('SS001', [
        ErroValidacao(
          codigo: 'SS001',
          descricao: 'Arquivo não pertence ao Santander',
          detalhe:
              'Código banco encontrado: "$banco". Este módulo valida apenas arquivos Santander (033)',
          severidade: SeveridadeValidacao.fatal,
          categoria: CategoriaValidacao.santander,
          linha: numLinha,
          posicaoInicio: 1,
          posicaoFim: 3,
          campoCnab: 'Código do Banco',
          sugestaoCorrecao:
              'Use este validador apenas para arquivos CNAB 240 Santander (033)',
          referenciaFebraban: 'Santander: Código Banco = 033',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SS001', tempoMs: sw.elapsedMilliseconds);
  }

  /// SS002 — Convênio deve ter exatamente 7 dígitos (Santander)
  static ResultadoRegra sS002ConvenioSeteSDigitos(
      String headerArquivo, int numLinha) {
    final sw = Stopwatch()..start();
    if (headerArquivo.length < 42) {
      return ResultadoRegra.sucesso('SS002', tempoMs: sw.elapsedMilliseconds);
    }

    // Posição 36-42 (índice 35-41)
    final convenio = headerArquivo.substring(35, 42);
    if (!RegExp(r'^\d{7}$').hasMatch(convenio)) {
      return ResultadoRegra.falha('SS002', [
        ErroValidacao(
          codigo: 'SS002',
          descricao: 'Convênio Santander deve ter exatamente 7 dígitos numéricos',
          detalhe: 'Encontrado: "$convenio"',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.santander,
          linha: numLinha,
          posicaoInicio: 36,
          posicaoFim: 42,
          campoCnab: 'Código do Convênio Santander',
          sugestaoCorrecao:
              'O código de convênio Santander tem 7 dígitos. Consulte seu gerente',
          referenciaFebraban: 'Santander CNAB 240 — Convênio = 7 dígitos',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SS002', tempoMs: sw.elapsedMilliseconds);
  }

  /// SS003 — Carteiras válidas Santander: 101, 102, 104, 201
  static ResultadoRegra sS003CarteirasValidas(List<String> segmentosP) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];
    const validas = {'101', '102', '104', '201'};

    for (int i = 0; i < segmentosP.length; i++) {
      final seg = segmentosP[i];
      if (seg.length < 35) continue;

      final cart = seg.substring(32, 35);
      if (!validas.contains(cart)) {
        erros.add(ErroValidacao(
          codigo: 'SS003',
          descricao: 'Código de carteira inválido para Santander',
          detalhe:
              'Carteira: "$cart" | Carteiras aceitas: 101, 102, 104, 201',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.santander,
          posicaoInicio: 33,
          posicaoFim: 35,
          campoCnab: 'Carteira Santander',
          indiceTitulo: i,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              '101=Simples, 102=Vinculada, 104=Caucionada, 201=Descontada',
          referenciaFebraban: 'Santander CNAB 240 — Carteiras: 101/102/104/201',
        ));
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('SS003', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('SS003', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// SS004 — Modalidade deve ser 01 ou 02
  static ResultadoRegra sS004Modalidade(String headerLote, int numLinha) {
    final sw = Stopwatch()..start();
    // Santander usa modalidade na posição do header de lote — verificação específica
    // Aqui verificamos o campo forma de lançamento (pos 12-13)
    if (headerLote.length < 13) {
      return ResultadoRegra.sucesso('SS004', tempoMs: sw.elapsedMilliseconds);
    }

    final modalidade = headerLote.substring(11, 13);
    if (modalidade != '01' && modalidade != '02') {
      return ResultadoRegra.falha('SS004', [
        ErroValidacao(
          codigo: 'SS004',
          descricao: 'Modalidade de lançamento Santander inválida',
          detalhe: 'Encontrado: "$modalidade". Válidos: 01 ou 02',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.santander,
          linha: numLinha,
          posicaoInicio: 12,
          posicaoFim: 13,
          campoCnab: 'Forma de Lançamento',
          sugestaoCorrecao: 'Use 01 para Cobrança Simples ou 02 para Cobrança Caucionada',
          referenciaFebraban: 'Santander CNAB 240 — Modalidade: 01=Simples, 02=Caucionada',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SS004', tempoMs: sw.elapsedMilliseconds);
  }

  /// SS005 — Versão do layout do lote Santander deve ser 046
  static ResultadoRegra sS005VersaoLayoutLote046(
      String headerLote, int numLinha) {
    final sw = Stopwatch()..start();
    if (headerLote.length < 16) {
      return ResultadoRegra.sucesso('SS005', tempoMs: sw.elapsedMilliseconds);
    }

    final versao = headerLote.substring(13, 16);
    if (versao != '046') {
      return ResultadoRegra.falha('SS005', [
        ErroValidacao(
          codigo: 'SS005',
          descricao: 'Versão do layout de lote diferente de 046 (padrão Santander)',
          detalhe: 'Encontrado: "$versao". Esperado: "046"',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.santander,
          linha: numLinha,
          posicaoInicio: 14,
          posicaoFim: 16,
          campoCnab: 'Nr da Versão do Layout do Lote',
          sugestaoCorrecao: 'Santander requer versão 046 do layout de lote',
          referenciaFebraban:
              'Santander CNAB 240 — Versão Layout Lote = 046',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SS005', tempoMs: sw.elapsedMilliseconds);
  }

  /// SS006 — Agência Santander deve ter 4 dígitos (não 5 dígitos como alguns bancos)
  static ResultadoRegra sS006AgenciaQuatroDigitos(
      List<String> segmentosP, List<int> linhasP) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];

    for (int i = 0; i < segmentosP.length; i++) {
      final seg = segmentosP[i];
      if (seg.length < 21) continue;

      final agencia = seg.substring(17, 21);
      if (!RegExp(r'^\d{4}$').hasMatch(agencia)) {
        erros.add(ErroValidacao(
          codigo: 'SS006',
          descricao: 'Agência Santander deve ter exatamente 4 dígitos',
          detalhe: 'Encontrado: "$agencia"',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.santander,
          linha: i < linhasP.length ? linhasP[i] : null,
          posicaoInicio: 18,
          posicaoFim: 21,
          campoCnab: 'Agência Mantenedora',
          indiceTitulo: i,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Santander: agência tem 4 dígitos (sem o dígito verificador neste campo)',
        ));
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('SS006', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('SS006', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// SS007 — Conta Santander deve ter 8 dígitos (sem dígito verificador)
  static ResultadoRegra sS007ContaOitoDigitos(
      List<String> segmentosP, List<int> linhasP) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];

    for (int i = 0; i < segmentosP.length; i++) {
      final seg = segmentosP[i];
      if (seg.length < 30) continue;

      final conta = seg.substring(22, 30);
      if (!RegExp(r'^\d{8}$').hasMatch(conta)) {
        erros.add(ErroValidacao(
          codigo: 'SS007',
          descricao: 'Conta Santander deve ter exatamente 8 dígitos no campo correto',
          detalhe: 'Encontrado: "$conta"',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.santander,
          linha: i < linhasP.length ? linhasP[i] : null,
          posicaoInicio: 23,
          posicaoFim: 30,
          campoCnab: 'Número da Conta Corrente',
          indiceTitulo: i,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Santander: campo conta = 8 dígitos (sem dígito verificador)',
        ));
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('SS007', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('SS007', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// SS008 — Tipo de serviço no header de lote deve ser 01 (Cobrança)
  static ResultadoRegra sS008TipoServicoCobranca(
      String headerLote, int numLinha) {
    final sw = Stopwatch()..start();
    if (headerLote.length < 11) {
      return ResultadoRegra.sucesso('SS008', tempoMs: sw.elapsedMilliseconds);
    }

    final tipoServico = headerLote.substring(9, 11);
    if (tipoServico != '01') {
      return ResultadoRegra.falha('SS008', [
        ErroValidacao(
          codigo: 'SS008',
          descricao: 'Tipo de serviço no Header de Lote deve ser 01 (Cobrança) para Santander',
          detalhe: 'Encontrado: "$tipoServico"',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.santander,
          linha: numLinha,
          posicaoInicio: 10,
          posicaoFim: 11,
          campoCnab: 'Tipo de Serviço',
          sugestaoCorrecao:
              'Para cobrança de boletos Santander use tipo de serviço 01',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SS008', tempoMs: sw.elapsedMilliseconds);
  }

  /// SS009 — Código da moeda deve ser 009 (Real) em todos os segmentos P
  static ResultadoRegra sS009MoedaReal(
      List<String> segmentosP, List<int> linhasP) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];

    for (int i = 0; i < segmentosP.length; i++) {
      final seg = segmentosP[i];
      if (seg.length < 222) continue;

      final moeda = seg.substring(219, 222);
      if (moeda != '009') {
        erros.add(ErroValidacao(
          codigo: 'SS009',
          descricao: 'Código de moeda deve ser 009 (Real) no Segmento P',
          detalhe: 'Encontrado: "$moeda"',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.santander,
          linha: i < linhasP.length ? linhasP[i] : null,
          posicaoInicio: 220,
          posicaoFim: 222,
          campoCnab: 'Código da Moeda',
          indiceTitulo: i,
          tipoSegmento: 'P',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 220-222: Código da Moeda = 009 (Real)',
        ));
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('SS009', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('SS009', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// SS010 — Versão do layout do arquivo Santander deve ser 103
  static ResultadoRegra sS010VersaoArquivo(
      String headerArquivo, int numLinha) {
    final sw = Stopwatch()..start();
    // Versão do layout do arquivo está na posição 164-166 (índice 163-165)
    if (headerArquivo.length < 166) {
      return ResultadoRegra.sucesso('SS010', tempoMs: sw.elapsedMilliseconds);
    }

    final versao = headerArquivo.substring(163, 166);
    if (versao != '103' && versao != '101' && versao != '000') {
      return ResultadoRegra.falha('SS010', [
        ErroValidacao(
          codigo: 'SS010',
          descricao: 'Versão do layout do arquivo não reconhecida pelo Santander',
          detalhe: 'Encontrado: "$versao". Santander aceita: 103 (atual), 101 (legado)',
          severidade: SeveridadeValidacao.info,
          categoria: CategoriaValidacao.santander,
          linha: numLinha,
          posicaoInicio: 164,
          posicaoFim: 166,
          campoCnab: 'Nr da Versão do Layout do Arquivo',
          sugestaoCorrecao:
              'Use versão 103 para o layout atual do Santander',
          referenciaFebraban:
              'Santander CNAB 240 — Versão Layout Arquivo = 103',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('SS010', tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras específicas Santander
  static List<ResultadoRegra> validarTodo({
    required String? headerArquivo,
    required String? headerLote,
    required List<String> segmentosP,
    required List<int> linhasP,
    int numLinhaHeader = 1,
    int numLinhaHeaderLote = 2,
  }) {
    final resultados = <ResultadoRegra>[];

    if (headerArquivo != null) {
      resultados.add(sS001CodigoBancoSantander033(headerArquivo, numLinhaHeader));
      resultados.add(sS002ConvenioSeteSDigitos(headerArquivo, numLinhaHeader));
      resultados.add(sS010VersaoArquivo(headerArquivo, numLinhaHeader));
    }

    if (headerLote != null) {
      resultados.add(sS004Modalidade(headerLote, numLinhaHeaderLote));
      resultados.add(sS005VersaoLayoutLote046(headerLote, numLinhaHeaderLote));
      resultados.add(sS008TipoServicoCobranca(headerLote, numLinhaHeaderLote));
    }

    resultados.add(sS003CarteirasValidas(segmentosP));
    resultados.add(sS006AgenciaQuatroDigitos(segmentosP, linhasP));
    resultados.add(sS007ContaOitoDigitos(segmentosP, linhasP));
    resultados.add(sS009MoedaReal(segmentosP, linhasP));

    return resultados;
  }
}
