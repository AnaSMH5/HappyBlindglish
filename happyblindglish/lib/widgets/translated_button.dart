import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TranslatedButton extends StatefulWidget {
  final void Function()? onPressed;
  final String text;

  const TranslatedButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  State<TranslatedButton> createState() => _TranslatedButtonState();
}

class _TranslatedButtonState extends State<TranslatedButton> {
  bool block = false;
  bool anotherEvent = false;
  final FlutterTts _flutterTts = FlutterTts();
  final FocusNode _focusNode = FocusNode(); 

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _speakNormal(); // Pronuncia automáticamente al recibir foco
      }
    });
  }

  /// Cancela cualquier reproducción de voz antes de iniciar una nueva
  Future<void> _stopSpeech() async {
    await _flutterTts.stop();
  }

  Future<void> _speakSlowly() async {
    await _stopSpeech();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.2); // Velocidad lenta
    await _flutterTts.speak(
      widget.text,
    );
  }

  Future<void> _speakNormal() async {
    await _stopSpeech();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.7); // Velocidad lenta
    await _flutterTts.speak(
      widget.text,
    );
  }

  Future<void> _spellOut() async {
    await _stopSpeech();
    block = true;
    await _flutterTts.setLanguage("es-MX");
    await _flutterTts.setSpeechRate(0.5); // Velocidad moderada
    bool firstTime = true;
    List<String> letters = widget.text.toUpperCase().split('');
    await Future.forEach(letters, (letter) async {
      if (anotherEvent) {
        return;
      } else {
        if (firstTime) {
          await Future.delayed(
              const Duration(milliseconds: 1000)); // Pausa entre letras
          firstTime = false;
        }
        await _flutterTts.speak(letter); // Pronuncia la letra
        await Future.delayed(
            const Duration(milliseconds: 500)); // Pausa entre letras
      }
    });
    block = false;
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
        label: "${widget.text}. Toca para escuchar. Acciones adicionales disponibles.",
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Seleccionar como respuesta'): () {
            widget.onPressed?.call();
          },
          const CustomSemanticsAction(label: 'Escuchar letra por letra'): () {
            if (!block) {
              if (anotherEvent) {
                anotherEvent = false;
              }
              _spellOut();
            }
          },
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: () {
            _speakNormal();
          },
          onDoubleTap: () {
            widget.onPressed!();
          },
          onLongPress: () async {
            if (!block) {
              if (anotherEvent) {
                anotherEvent = false;
              }
              _spellOut();
            }
          },
          child: Container(
            color: Colors.indigo,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: Semantics(
                      excludeSemantics: true,
                      child: Text(
                        widget.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
