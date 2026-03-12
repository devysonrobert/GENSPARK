// core/validation/rules/business_rules.dart
// Regras de negócio CNAB 240
// Validações cruzadas entre segmentos e regras de cobrança Santander

import '../models/validation_error.dart';
import '../models/validation_result.dart';

class RegraNegocios {
  /// BR001 — Todo Segmento P deve ter um Segmento Q correspondente no mesmo lote
  static ResultadoRegra bR001SegmentoPQPareados(
      List<String> linhas, List<int> linhasP, List<int> linhasQ) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];

    if (linhasP.length != linhasQ.length) {
      erros.add(ErroValidacao(
        codigo: 'BR001',
        descricao:
            'Quantidade de Segmentos P e Q desbalanceada — cada título deve ter P e Q',
        detalhe:
            'Segmentos P: ${linhasP.length} | Segmentos Q: ${linhasQ.length}',
        severidade: SeveridadeValidacao.fatal,
        categoria: CategoriaValidacao.negocio,
        sugestaoCorrecao:
            'Cada Segmento P deve ser seguido de um Segmento Q. Verifique a geração do arquivo',
        referenciaFebraban:
            'FEBRABAN CNAB 240 v10.7 — Seção 2.3: P e Q são obrigatórios por título',
      ));
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('BR001', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('BR001', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// BR002 — Segmento R deve aparecer apenas após P e Q do mesmo título
  static ResultadoRegra bR002SegmentoRPosicao(List<String> linhas) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];

    for (int i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      if (linha.length < 14) continue;

      if (linha.substring(7, 8) == '3' && linha.substring(13, 14) == 'R') {
        // O R deve vir logo após Q
        if (i < 2) {
          erros.add(ErroValidacao(
            codigo: 'BR002',
            descricao: 'Segmento R encontrado em posição inválida no arquivo',
            detalhe: 'Linha ${i + 1}: Segmento R antes de P e Q',
            severidade: SeveridadeValidacao.erro,
            categoria: CategoriaValidacao.negocio,
            linha: i + 1,
          ));
          continue;
        }

        final prev = linhas[i - 1];
        if (prev.length >= 14 && prev.substring(13, 14) != 'Q') {
          erros.add(ErroValidacao(
            codigo: 'BR002',
            descricao:
                'Segmento R não precedido por Segmento Q na linha ${i + 1}',
            detalhe:
                'Linha anterior (${i}): segmento = "${prev.length >= 14 ? prev.substring(13, 14) : "?"}"',
            severidade: SeveridadeValidacao.aviso,
            categoria: CategoriaValidacao.negocio,
            linha: i + 1,
            sugestaoCorrecao:
                'Segmentos devem seguir a ordem P → Q → R (opcional)',
          ));
        }
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('BR002', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('BR002', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// BR003 — Nosso número deve ser único dentro do lote/arquivo
  static ResultadoRegra bR003NossoNumeroUnico(
      List<String> segmentosP, List<int> linhasP) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];
    final nossoNumeros = <String, int>{};

    for (int i = 0; i < segmentosP.length; i++) {
      final seg = segmentosP[i];
      if (seg.length < 52) continue;

      // Nosso número: posição 33-52 (índice 32-51)
      final nossoNum = seg.substring(32, 52).trim();
      if (nossoNum.isEmpty || RegExp(r'^0+$').hasMatch(nossoNum)) continue;

      if (nossoNumeros.containsKey(nossoNum)) {
        final linhaOriginal = nossoNumeros[nossoNum]!;
        erros.add(ErroValidacao(
          codigo: 'BR003',
          descricao: 'Nosso Número duplicado no arquivo',
          detalhe:
              'Nosso Número "$nossoNum" aparece nas linhas $linhaOriginal e ${i < linhasP.length ? linhasP[i] : i + 1}',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.negocio,
          linha: i < linhasP.length ? linhasP[i] : i + 1,
          posicaoInicio: 33,
          posicaoFim: 52,
          campoCnab: 'Identificação do Título no Banco',
          indiceTitulo: i,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Cada título deve ter um Nosso Número único. Renumere os títulos',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Nosso Número: identificação única do título',
        ));
      } else {
        nossoNumeros[nossoNum] = i < linhasP.length ? linhasP[i] : i + 1;
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('BR003', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('BR003', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// BR004 — Número do documento deve ser único no lote
  static ResultadoRegra bR004NumeroDocumentoUnico(
      List<String> segmentosP, List<int> linhasP) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];
    final documentos = <String, int>{};

    for (int i = 0; i < segmentosP.length; i++) {
      final seg = segmentosP[i];
      if (seg.length < 72) continue;

      // Número do documento: posição 63-72 (índice 62-71)
      final numDoc = seg.substring(62, 72).trim();
      if (numDoc.isEmpty) continue;

      if (documentos.containsKey(numDoc)) {
        erros.add(ErroValidacao(
          codigo: 'BR004',
          descricao: 'Número de documento duplicado no arquivo',
          detalhe:
              'Documento "$numDoc" duplicado. Primeira ocorrência na linha ${documentos[numDoc]}',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.negocio,
          linha: i < linhasP.length ? linhasP[i] : i + 1,
          posicaoInicio: 63,
          posicaoFim: 72,
          campoCnab: 'Número do Documento (Seu Número)',
          indiceTitulo: i,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'Verifique se há duplicidade de títulos no arquivo',
        ));
      } else {
        documentos[numDoc] = i < linhasP.length ? linhasP[i] : i + 1;
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('BR004', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('BR004', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// BR005 — Data de vencimento não pode ser anterior à data de emissão
  static ResultadoRegra bR005VencimentoAposEmissao(
      List<String> segmentosP, List<int> linhasP) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];

    DateTime? parseData(String s) {
      if (!RegExp(r'^\d{8}$').hasMatch(s) || s == '00000000') return null;
      try {
        return DateTime(
          int.parse(s.substring(4, 8)),
          int.parse(s.substring(2, 4)),
          int.parse(s.substring(0, 2)),
        );
      } catch (_) {
        return null;
      }
    }

    for (int i = 0; i < segmentosP.length; i++) {
      final seg = segmentosP[i];
      if (seg.length < 114) continue;

      final dataVencStr = seg.substring(72, 80);
      final dataEmissStr = seg.substring(106, 114);

      final dataVenc = parseData(dataVencStr);
      final dataEmiss = parseData(dataEmissStr);

      if (dataVenc != null && dataEmiss != null && dataVenc.isBefore(dataEmiss)) {
        erros.add(ErroValidacao(
          codigo: 'BR005',
          descricao:
              'Data de vencimento anterior à data de emissão no Segmento P',
          detalhe:
              'Emissão: $dataEmissStr | Vencimento: $dataVencStr',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.negocio,
          linha: i < linhasP.length ? linhasP[i] : i + 1,
          posicaoInicio: 73,
          posicaoFim: 80,
          campoCnab: 'Data de Vencimento',
          indiceTitulo: i,
          tipoSegmento: 'P',
          sugestaoCorrecao:
              'A data de vencimento deve ser igual ou posterior à data de emissão',
        ));
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('BR005', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('BR005', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// BR006 — Valor total no Trailer de Lote deve conferir com soma dos títulos
  static ResultadoRegra bR006ValorTotalTrailerLote(
      List<String> segmentosP, String trailerLote, int numLinhaTrailer) {
    final sw = Stopwatch()..start();

    if (trailerLote.length < 46) {
      return ResultadoRegra.sucesso('BR006', tempoMs: sw.elapsedMilliseconds);
    }

    // Somar valores dos segmentos P
    int somaCalculada = 0;
    for (final seg in segmentosP) {
      if (seg.length < 95) continue;
      final valorStr = seg.substring(80, 95);
      somaCalculada += int.tryParse(valorStr) ?? 0;
    }

    // Ler valor declarado no trailer (posição 30-46, índice 29-45) = 17 chars
    final valorDeclaradoStr = trailerLote.substring(29, 46);
    final valorDeclarado = int.tryParse(valorDeclaradoStr) ?? -1;

    if (valorDeclarado != somaCalculada) {
      return ResultadoRegra.falha('BR006', [
        ErroValidacao(
          codigo: 'BR006',
          descricao:
              'Valor total no Trailer de Lote não confere com a soma dos títulos',
          detalhe:
              'Declarado: R\$ ${(valorDeclarado / 100.0).toStringAsFixed(2)} | '
              'Calculado: R\$ ${(somaCalculada / 100.0).toStringAsFixed(2)}',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.negocio,
          linha: numLinhaTrailer,
          posicaoInicio: 30,
          posicaoFim: 46,
          campoCnab: 'Valor Total dos Títulos em Carteira',
          sugestaoCorrecao:
              'Atualize o valor total no Trailer de Lote com a soma correta',
          referenciaFebraban:
              'FEBRABAN CNAB 240 v10.7 — Posição 30-46: Valor Total Cobrança',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('BR006', tempoMs: sw.elapsedMilliseconds);
  }

  /// BR007 — Limite: arquivo não pode ter mais de 9999 lotes
  static ResultadoRegra bR007LimiteLotes(int qtdLotes) {
    final sw = Stopwatch()..start();

    if (qtdLotes > 9999) {
      return ResultadoRegra.falha('BR007', [
        ErroValidacao(
          codigo: 'BR007',
          descricao: 'Número de lotes excede o limite máximo',
          detalhe: 'Lotes: $qtdLotes | Limite: 9999',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.negocio,
          sugestaoCorrecao:
              'Divida o arquivo em múltiplos arquivos com no máximo 9999 lotes cada',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('BR007', tempoMs: sw.elapsedMilliseconds);
  }

  /// BR008 — Limite: arquivo não pode ter mais de 99999 títulos
  static ResultadoRegra bR008LimiteTitulos(int qtdTitulos) {
    final sw = Stopwatch()..start();

    if (qtdTitulos > 99999) {
      return ResultadoRegra.falha('BR008', [
        ErroValidacao(
          codigo: 'BR008',
          descricao: 'Número de títulos excede o limite do arquivo CNAB 240',
          detalhe: 'Títulos: $qtdTitulos | Limite prático: 99999',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.negocio,
          sugestaoCorrecao: 'Divida em múltiplos arquivos remessa',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }
    return ResultadoRegra.sucesso('BR008', tempoMs: sw.elapsedMilliseconds);
  }

  /// BR009 — Carteira no Segmento P deve ser consistente no arquivo inteiro
  static ResultadoRegra bR009CarteiraCodigo(List<String> segmentosP) {
    final sw = Stopwatch()..start();
    final carteiras = <String>{};

    for (final seg in segmentosP) {
      if (seg.length < 35) continue;
      final cart = seg.substring(32, 35);
      if (RegExp(r'^\d{3}$').hasMatch(cart)) {
        carteiras.add(cart);
      }
    }

    const carteirasValidas = {'101', '102', '104', '201'};
    final invalidas = carteiras.difference(carteirasValidas);

    if (invalidas.isNotEmpty) {
      return ResultadoRegra.falha('BR009', [
        ErroValidacao(
          codigo: 'BR009',
          descricao:
              'Carteiras inválidas encontradas no arquivo: ${invalidas.join(', ')}',
          detalhe: 'Carteiras válidas para Santander: 101, 102, 104, 201',
          severidade: SeveridadeValidacao.erro,
          categoria: CategoriaValidacao.negocio,
          sugestaoCorrecao:
              'Corrija o código de carteira nos títulos afetados',
          referenciaFebraban:
              'Santander: 101=Simples, 102=Vinculada, 104=Caucionada, 201=Descontada',
        ),
      ], tempoMs: sw.elapsedMilliseconds);
    }

    return ResultadoRegra.sucesso('BR009', tempoMs: sw.elapsedMilliseconds);
  }

  /// BR010 — Agência e conta nos segmentos P devem ser iguais ao header do arquivo
  static ResultadoRegra bR010AgenciaContaConsistente(
      String headerArquivo, List<String> segmentosP, List<int> linhasP) {
    final sw = Stopwatch()..start();
    final erros = <ErroValidacao>[];

    if (headerArquivo.length < 66) {
      return ResultadoRegra.sucesso('BR010', tempoMs: sw.elapsedMilliseconds);
    }

    final agenciaHeader = headerArquivo.substring(52, 56); // pos 53-56
    final contaHeader = headerArquivo.substring(57, 65);    // pos 58-65

    for (int i = 0; i < segmentosP.length; i++) {
      final seg = segmentosP[i];
      if (seg.length < 30) continue;

      final agenciaSeg = seg.substring(17, 21); // pos 18-21
      final contaSeg = seg.substring(22, 30);    // pos 23-30

      if (agenciaSeg != agenciaHeader) {
        erros.add(ErroValidacao(
          codigo: 'BR010',
          descricao: 'Agência no Segmento P diverge do Header de Arquivo',
          detalhe:
              'Header: $agenciaHeader | Segmento P (título ${i + 1}): $agenciaSeg',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.negocio,
          linha: i < linhasP.length ? linhasP[i] : null,
          posicaoInicio: 18,
          posicaoFim: 21,
          campoCnab: 'Agência Mantenedora',
          indiceTitulo: i,
          tipoSegmento: 'P',
        ));
      }

      if (contaSeg != contaHeader) {
        erros.add(ErroValidacao(
          codigo: 'BR010',
          descricao: 'Conta no Segmento P diverge do Header de Arquivo',
          detalhe:
              'Header: $contaHeader | Segmento P (título ${i + 1}): $contaSeg',
          severidade: SeveridadeValidacao.aviso,
          categoria: CategoriaValidacao.negocio,
          linha: i < linhasP.length ? linhasP[i] : null,
          posicaoInicio: 23,
          posicaoFim: 30,
          campoCnab: 'Número da Conta Corrente',
          indiceTitulo: i,
          tipoSegmento: 'P',
        ));
      }
    }

    return erros.isEmpty
        ? ResultadoRegra.sucesso('BR010', tempoMs: sw.elapsedMilliseconds)
        : ResultadoRegra.falha('BR010', erros, tempoMs: sw.elapsedMilliseconds);
  }

  /// Executa todas as regras de negócio
  static List<ResultadoRegra> validarTodo({
    required List<String> linhas,
    required List<String> segmentosP,
    required List<String> segmentosQ,
    required List<int> linhasP,
    required List<int> linhasQ,
    required String? trailerLote,
    required int numLinhaTrailerLote,
    required String? headerArquivo,
    required int qtdLotes,
    required int qtdTitulos,
  }) {
    final resultados = <ResultadoRegra>[
      bR001SegmentoPQPareados(linhas, linhasP, linhasQ),
      bR002SegmentoRPosicao(linhas),
      bR003NossoNumeroUnico(segmentosP, linhasP),
      bR004NumeroDocumentoUnico(segmentosP, linhasP),
      bR005VencimentoAposEmissao(segmentosP, linhasP),
      bR007LimiteLotes(qtdLotes),
      bR008LimiteTitulos(qtdTitulos),
      bR009CarteiraCodigo(segmentosP),
    ];

    if (trailerLote != null) {
      resultados.add(bR006ValorTotalTrailerLote(segmentosP, trailerLote, numLinhaTrailerLote));
    }

    if (headerArquivo != null) {
      resultados.add(bR010AgenciaContaConsistente(headerArquivo, segmentosP, linhasP));
    }

    return resultados;
  }
}
