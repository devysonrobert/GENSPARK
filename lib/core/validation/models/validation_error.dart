// core/validation/models/validation_error.dart
// Modelo de erro/aviso de validação CNAB 240

/// Severidade do erro de validação
enum SeveridadeValidacao {
  fatal,    // Impede geração do arquivo - bloqueia download
  erro,     // Erro grave que deve ser corrigido
  aviso,    // Aviso - pode prosseguir mas recomendável corrigir
  info,     // Informação - apenas orientação
}

/// Categoria do erro de validação
enum CategoriaValidacao {
  estrutural,     // Estrutura do arquivo (tamanho, CRLF, etc.)
  headerArquivo,  // Regras do Header de Arquivo
  headerLote,     // Regras do Header de Lote
  segmentoP,      // Regras do Segmento P
  segmentoQ,      // Regras do Segmento Q
  segmentoR,      // Regras do Segmento R
  trailerLote,    // Regras do Trailer de Lote
  trailerArquivo, // Regras do Trailer de Arquivo
  negocio,        // Regras de negócio (datas, valores, etc.)
  algoritmo,      // Regras algorítmicas (DAC, CPF/CNPJ, módulo 11)
  santander,      // Regras específicas Santander
  retorno,        // Regras de arquivo retorno
}

/// Erro individual de validação
class ErroValidacao {
  /// Código único da regra (ex: STR001, HA001, SP015)
  final String codigo;

  /// Descrição técnica do erro
  final String descricao;

  /// Detalhe adicional (valor encontrado, esperado, etc.)
  final String? detalhe;

  /// Severidade do erro
  final SeveridadeValidacao severidade;

  /// Categoria da validação
  final CategoriaValidacao categoria;

  /// Número da linha no arquivo (1-based, null se não aplicável)
  final int? linha;

  /// Posição inicial no registro (1-based, FEBRABAN)
  final int? posicaoInicio;

  /// Posição final no registro (FEBRABAN)
  final int? posicaoFim;

  /// Nome do campo FEBRABAN
  final String? campoCnab;

  /// Índice do título relacionado (null se não aplicável)
  final int? indiceTitulo;

  /// Número do lote relacionado
  final int? numeroLote;

  /// Tipo de segmento (P, Q, R)
  final String? tipoSegmento;

  /// Sugestão de correção
  final String? sugestaoCorrecao;

  /// Referência FEBRABAN (ex: "FEBRABAN v10.7 - Posição 1-3")
  final String? referenciaFebraban;

  const ErroValidacao({
    required this.codigo,
    required this.descricao,
    this.detalhe,
    required this.severidade,
    required this.categoria,
    this.linha,
    this.posicaoInicio,
    this.posicaoFim,
    this.campoCnab,
    this.indiceTitulo,
    this.numeroLote,
    this.tipoSegmento,
    this.sugestaoCorrecao,
    this.referenciaFebraban,
  });

  /// Etiqueta de severidade para UI
  String get labelSeveridade {
    switch (severidade) {
      case SeveridadeValidacao.fatal:
        return 'FATAL';
      case SeveridadeValidacao.erro:
        return 'ERRO';
      case SeveridadeValidacao.aviso:
        return 'AVISO';
      case SeveridadeValidacao.info:
        return 'INFO';
    }
  }

  /// Etiqueta de categoria para UI
  String get labelCategoria {
    switch (categoria) {
      case CategoriaValidacao.estrutural:
        return 'Estrutural';
      case CategoriaValidacao.headerArquivo:
        return 'Header Arquivo';
      case CategoriaValidacao.headerLote:
        return 'Header Lote';
      case CategoriaValidacao.segmentoP:
        return 'Segmento P';
      case CategoriaValidacao.segmentoQ:
        return 'Segmento Q';
      case CategoriaValidacao.segmentoR:
        return 'Segmento R';
      case CategoriaValidacao.trailerLote:
        return 'Trailer Lote';
      case CategoriaValidacao.trailerArquivo:
        return 'Trailer Arquivo';
      case CategoriaValidacao.negocio:
        return 'Negócio';
      case CategoriaValidacao.algoritmo:
        return 'Algoritmo';
      case CategoriaValidacao.santander:
        return 'Santander';
      case CategoriaValidacao.retorno:
        return 'Retorno';
    }
  }

  /// Mensagem completa formatada
  String get mensagemCompleta {
    final buffer = StringBuffer('[${labelSeveridade}] [$codigo] $descricao');
    if (detalhe != null) buffer.write(' — $detalhe');
    if (linha != null) buffer.write(' (Linha: $linha)');
    if (posicaoInicio != null && posicaoFim != null) {
      buffer.write(' [Pos $posicaoInicio-$posicaoFim]');
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'descricao': descricao,
        'detalhe': detalhe,
        'severidade': severidade.name,
        'categoria': categoria.name,
        'linha': linha,
        'posicaoInicio': posicaoInicio,
        'posicaoFim': posicaoFim,
        'campoCnab': campoCnab,
        'indiceTitulo': indiceTitulo,
        'numeroLote': numeroLote,
        'tipoSegmento': tipoSegmento,
        'sugestaoCorrecao': sugestaoCorrecao,
        'referenciaFebraban': referenciaFebraban,
      };
}
