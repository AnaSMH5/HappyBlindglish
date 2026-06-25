import 'package:audioplayers/audioplayers.dart';
// import 'package:dart_levenshtein/dart_levenshtein.dart'; // usar para mejorar the similarity check
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:happyblindglish/models/palabra.dart';
import 'package:happyblindglish/providers/db_provider.dart';
import 'package:logger/logger.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

final logger = Logger();

class LeccionButton extends StatefulWidget {
  final void Function()? onPressed;
  final void Function(Palabra learnedWord)? onCorrectPronunciation;
  final Palabra palabra;

  const LeccionButton({
    super.key,
    required this.onCorrectPronunciation,
    required this.onPressed,
    required this.palabra,
  });

  @override
  State<LeccionButton> createState() => _LeccionButtonState();
}

class _LeccionButtonState extends State<LeccionButton> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();  
  final FocusNode _focusNode = FocusNode(); 
  final FocusNode _focusNodeMic = FocusNode();
  final db = DatabaseProvider();

  bool _listening = false;
  bool _listened = false;

  Future<void> _pronunciarPalabra() async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.speak(widget.palabra.palabraIngles);

    // Marcar la palabra como escuchada para habilitar el micrófono
    if (!_listened) {
      setState(() =>_listened = true);
    }
  }

  Future<void> _playSound(AssetSource sound) async {
    try {
      await _audioPlayer.play(sound);
    } catch (e) {
      logger.e("Error al reproducir sonido: $e");
    }
  }

  Future<void> _startListening() async {
    if (!_listened) {
      logger.w("El usuario debe escuchar la palabra antes de practicar la pronunciación.");
      await _flutterTts.setLanguage("es-MX");
      await _flutterTts.speak("Debes escuchar primero la palabra antes de practicar la pronunciación.");
      return;
    }

    if (_listening) return;

    // Detener TTS antes de escuchar
    await _flutterTts.stop();

    final targetWord = widget.palabra.palabraIngles.toLowerCase().trim();
    const double similarityThreshold = 0.3;

    final initialized = await _speechToText.initialize(
      onError: (error) => logger.e("STT error: $error"),
    );

    if (!initialized) {
      logger.e("Error al inicializar SpeechToText.");
      return;
    }

    setState(() => _listening = true);

    // Anunciar que el micrófono está activo
    await _flutterTts.setLanguage("es-CO");
    await _flutterTts.speak("Escuchando");
    await Future.delayed(const Duration(milliseconds: 800));

    _speechToText.listen(
      onResult: (result) async {
        if (!result.finalResult) return;

        setState(() => _listening = false);

        String recognizedPhrase = result.recognizedWords.toLowerCase().trim();
        logger.i("Frase reconocida: $recognizedPhrase");

        List<String> wordsInPhrase = recognizedPhrase.split(" ");
        bool esCorrecto = false;

        for (var word in wordsInPhrase) {
          double similarity = jaccardSimilarity(word, targetWord);
          logger.i("Comparando '$word' con '$targetWord' - Similitud: $similarity");

          if (similarity >= similarityThreshold) {
            esCorrecto = true;
            break;
          }
        }

        if (esCorrecto) {
          await _playSound(AssetSource("sonidos/assert.mp3"));
          logger.i("Correcto. Marcando como aprendida.");

          Palabra nuevaPalabra = Palabra(
            palabraEspanol: widget.palabra.palabraEspanol,
            palabraIngles: widget.palabra.palabraIngles,
            tipo: widget.palabra.tipo,
            nivel: widget.palabra.nivel,
            aprendido: true,
          );

          await db.updatePalabra(
            nuevaPalabra.palabraEspanol,
            nuevaPalabra.toMap(),
          );

          widget.onCorrectPronunciation?.call(nuevaPalabra);
        } else {
          logger.i("Incorrecto.");
          await _playSound(AssetSource("sonidos/wrong.mp3"));
        }

        _speechToText.stop();
      },
      listenFor: const Duration(seconds: 5),
      localeId: "en-US",
      onSoundLevelChange: (level) => logger.i("Nivel de sonido: $level"),
    );
  }

  double jaccardSimilarity(String a, String b) {
    Set<String> setA = a.split('').toSet();
    Set<String> setB = b.split('').toSet();

    int intersection = setA.intersection(setB).length;
    int union = setA.union(setB).length;

    return union == 0 ? 0.0 : intersection / union;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusNodeMic.dispose();
    _flutterTts.stop();
    _audioPlayer.dispose();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          focusNode: _focusNode,
          child: Semantics(
            button: true,
            label: "${widget.palabra.palabraEspanol} Toca dos veces para escuchar la palabra en inglés.",
            onTap: _pronunciarPalabra,
            child: GestureDetector(
              excludeFromSemantics: true,
              onTap: _pronunciarPalabra,
              child: ExcludeSemantics(
                child: Center(
                  child: Card(
                    elevation: 8,
                    color: Colors.indigo,
                    margin: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.08,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.palabra.palabraIngles,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                          Text(
                            widget.palabra.palabraEspanol,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.08,
                              fontWeight: FontWeight.w500,
                              color: Colors.yellow,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Botón de micrófono para practicar pronunciación
        Focus(
          focusNode: _focusNodeMic,
          child: Semantics(
            button: true,
            label: _listening ? "Escuchando, habla ahora"
              : _listened ? "Pronunciar con tu voz. Doble tap para activar el micrófono"
              : "Escucha la palabra primero antes de pronunciar",
            onTap: _startListening,
            child: GestureDetector(
              excludeFromSemantics: true,
              onTap: _startListening,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: 4
                  ),
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.04,
                ),
                decoration: BoxDecoration(
                  color: _listening ? Colors.green.shade800 : Colors.indigo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _listening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(_listening ? "Escuchando..."
                      : _listened ? "Pronunciar con tu voz"
                      : "Escucha la palabra primero",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
