import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'classificador_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Classificador de Áudios',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 202, 132, 25),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Comandos por Voz'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderReady = false;
  bool _isRecording = false;

  String comandoDetectado = "Toque para falar...";
  IconData iconeAtual = Icons.mic_none;
  Color corIcone = Colors.grey;

  final ClassificadorAudio _classificadorAudio = ClassificadorAudio();

  @override
  void initState() {
    super.initState();
    initRecorder();
    _classificadorAudio.loadModel();
  }

  Future<void> initRecorder() async {
    await _recorder.openRecorder();
    setState(() {
      _isRecorderReady = true;
    });
  }

  Future<void> startRecording() async {
    if (!_isRecorderReady) return;

    await _recorder.startRecorder(
      toFile: 'audio_temp.pcm',
      codec: Codec.pcm16,
      sampleRate: 44100,
      numChannels: 1,
    );

    setState(() {
      _isRecording = true;
      comandoDetectado = "Diga o comando...";
      iconeAtual = Icons.settings_voice;
      corIcone = Colors.red;
    });
  }

  Future<void> stopRecording() async {
    if (!_isRecorderReady || !_isRecording) return;

    final path = await _recorder.stopRecorder();

    setState(() {
      _isRecording = false;
    });

    if (path != null) {
      final resultado = await _classificadorAudio.classificarAudio(path);

      String classe = resultado['classe'];

      setState(() {
        comandoDetectado = classe.toUpperCase();

        switch (classe) {
          case 'Cima':
            iconeAtual = Icons.arrow_upward;
            corIcone = Colors.blue;
            break;
          case 'Baixo':
            iconeAtual = Icons.arrow_downward;
            corIcone = Colors.blue;
            break;
          case 'Esquerdo':
            iconeAtual = Icons.arrow_back;
            corIcone = Colors.blue;
            break;
          case 'Direito':
            iconeAtual = Icons.arrow_forward;
            corIcone = Colors.blue;
            break;
          case 'Ligado':
            iconeAtual = Icons.lightbulb;
            corIcone = Colors.green;
            break;
          case 'Desligado':
            iconeAtual = Icons.lightbulb_outline;
            corIcone = Colors.red;
            break;
          case 'Background Noise':
          default:
            iconeAtual = Icons.volume_off;
            corIcone = Colors.grey;
            comandoDetectado = "Nenhum comando identificado";
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(iconeAtual, size: 100, color: corIcone),
              ),
              const SizedBox(height: 32),

              Text(
                comandoDetectado,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton.icon(
                  onPressed: _isRecorderReady
                      ? (_isRecording ? stopRecording : startRecording)
                      : null,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 20),
                  label: Text(
                    _isRecording ? "Parar Gravação" : "Iniciar Gravação",
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }
}
