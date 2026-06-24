import 'package:audioplayers/audioplayers.dart';
// import 'package:dart_levenshtein/dart_levenshtein.dart'; // usar para mejorar the similarity check
import 'package:flutter/material.dart';
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

void _playSound(AssetSource sound) async {
  try {
    await _audioPlayer.play(sound);
  } catch (e) {
    logger.i("Error al reproducir sonido: $e");
  }
}

bool listenedOnce = false;
final AudioPlayer _audioPlayer = AudioPlayer();

class _LeccionButtonState extends State<LeccionButton> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final db = DatabaseProvider();
  final FlutterTts _flutterTts = FlutterTts();  
  final FocusNode _focusNode = FocusNode(); 

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _pronunciarPalabra();
      }
    });
  }

  Future<void> _pronunciarPalabra() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.speak(widget.palabra.palabraIngles);
  }

  void _startListening() async {
    final targetWord = widget.palabra.palabraIngles.toLowerCase().trim();
    const double similarityThreshold = 0.3; // Ajusta el umbral según tolerancia

    if (await _speechToText.initialize()) {
      logger.i("SpeechToText inicializado correctamente.");

      _speechToText.listen(
        onResult: (result) async {
          logger.i(result.alternates);
          if (!result.finalResult) return; // Esperar a que termine de hablar

          String recognizedPhrase = result.recognizedWords.toLowerCase().trim();
          logger.i("Frase reconocida: $recognizedPhrase");

          List<String> wordsInPhrase =
              recognizedPhrase.split(" "); // Separar en palabras
          logger.i("Palabras separadas: $wordsInPhrase");

          bool esCorrecto = false;

          for (var word in wordsInPhrase) {
            double similarity = jaccardSimilarity(word, targetWord);
            logger.i(
                "Comparando '$word' con '$targetWord' - Similaridad: $similarity");

            if (similarity >= similarityThreshold) {
              esCorrecto = true;
              break;
            }
          }

          if (esCorrecto) {
            _playSound(AssetSource("sonidos/assert.mp3"));
            logger.i("Palabra reconocida correctamente. Marcando como aprendida.");
            Palabra nuevaPalabra = Palabra(
              palabraEspanol: widget.palabra.palabraEspanol,
              palabraIngles: widget.palabra.palabraIngles,
              tipo: widget.palabra.tipo,
              nivel: widget.palabra.nivel,
              aprendido: true, // ✅ Cambiando el valor correctamente
            );
            await db.updatePalabra(
                nuevaPalabra.palabraEspanol, nuevaPalabra.toMap());
            logger.i(widget.palabra);
            widget.onCorrectPronunciation!(nuevaPalabra);
          } else {
            logger.i("Palabra incorrecta.");
            _playSound(AssetSource("sonidos/wrong.mp3"));
          }
          _speechToText.stop();
        },
        listenFor: const Duration(seconds: 5),
        localeId: "en-US",
      );
    } else {
      logger.i("Error al inicializar SpeechToText.");
    }
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
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: Semantics(
        button: true,
        label:
            "${widget.palabra.palabraEspanol} Toca para escuchar y mantén presionado para practicar pronunciación",
        onTap: () {
          _pronunciarPalabra();
        },
        onLongPress: () {
          _startListening();
        },
        child: GestureDetector(
          onTap: _pronunciarPalabra,
          onLongPress: _startListening,
          child: Center(
            child: Card(
              elevation: 8,
              color: Colors.indigo,
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: 16,
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
    );
  }
}
