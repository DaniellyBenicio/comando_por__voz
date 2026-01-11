import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassificadorAudio {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  final List<String> labels = [
    'Background Noise',
    'Baixo',
    'Cima',
    'Desligado',
    'Direito',
    'Esquerdo',
    'Ligado',
  ];

  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/comandos.tflite');

      final inputTensor = _interpreter!.getInputTensors()[0];
      final outputTensor = _interpreter!.getOutputTensors()[0];

      print("Modelo carregado!");
      print("Input shape: ${inputTensor.shape}");
      print("Input type: ${inputTensor.type}");
      print("Output shape: ${outputTensor.shape}");
      print("Tamanho esperado de áudio: ${inputTensor.shape.last} samples");

      _isModelLoaded = true;
    } catch (e) {
      print("Erro ao carregar o modelo: $e");
    }
  }

  Future<Map<String, dynamic>> classificarAudio(String audioPath) async {
    await loadModel();
    if (_interpreter == null) {
      return {'classe': 'Erro', 'confiança': 0.0};
    }

    final file = File(audioPath);
    if (!file.existsSync()) {
      return {'classe': 'Arquivo não encontrado', 'confiança': 0.0};
    }

    final pcmBytes = await file.readAsBytes();
    if (pcmBytes.isEmpty) {
      return {'classe': 'Áudio vazio', 'confiança': 0.0};
    }

    final byteData = ByteData.sublistView(pcmBytes);
    final numSamples = pcmBytes.length ~/ 2;

    final Float32List floatBuffer = Float32List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      floatBuffer[i] = sample / 32768.0;
    }

    const int tamanhoEsperado = 44032;

    Float32List inputBuffer;

    if (numSamples >= tamanhoEsperado) {
      final inicio = (numSamples - tamanhoEsperado) ~/ 2;
      inputBuffer = floatBuffer.sublist(inicio, inicio + tamanhoEsperado);
    } else {
      inputBuffer = Float32List(tamanhoEsperado);
      final offset = (tamanhoEsperado - numSamples) ~/ 2;
      inputBuffer.setRange(offset, offset + numSamples, floatBuffer);
    }

    final input = inputBuffer.reshape([1, tamanhoEsperado]);
    final output = List.filled(labels.length, 0.0).reshape([1, labels.length]);

    try {
      _interpreter!.run(input, output);
    } catch (e) {
      print("Erro na inferência: $e");
      return {'classe': 'Erro na inferência', 'confiança': 0.0};
    }

    final List<double> probabilities = output[0];

    // Verificando se tem algum NaN atrapalhando minnha vida
    if (probabilities.any((p) => p.isNaN)) {
      print("Áudio incompatível ou silêncio)");
      return {'classe': 'Background Noise', 'confianca': 0.0};
    }

    //Buscando o maior índice e maior probabilidade do comando
    int maxIndex = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    String classeDetectada = labels[maxIndex];
    int porcentagem = (maxProb * 100).round();

    print("Probabilidade: $probabilities");
    print("Comando mais provável: $classeDetectada ($porcentagem%)");
    
    if (classeDetectada == 'Background Noise') {
      print("Background Noise detectado");
    } else {
      print("Comando reconhecido com $porcentagem% de confiança!");
    }

    return {
      'classe': classeDetectada,
      'confiança': maxProb,
    };
  }
}