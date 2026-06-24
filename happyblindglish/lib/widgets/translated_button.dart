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

  // Cancela cualquier reproducción de voz antes de iniciar una nueva
  Future<void> _stopSpeech() async {
    anotherEvent = true;
    await _flutterTts.stop();
    _flutterTts.setCompletionHandler(() {});
    await Future.delayed(const Duration(milliseconds: 100));
    anotherEvent = false;
  }

  Future<void> _speakSlowly() async {
    await _stopSpeech();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.2); // Velocidad lenta
    await _flutterTts.speak(widget.text);
  }

  Future<void> _speakNormal() async {
    await _stopSpeech();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.6); // Velocidad normal
    await _flutterTts.speak(widget.text);
  }

  Future<void> _spellOut() async {
    if (block) return;
    
    await _stopSpeech();
    
    setState(() => block = true);
    anotherEvent = false;

    await _flutterTts.setLanguage("es-MX"); // si es de col colocar es-CO, sino dejar es-MX
    await _flutterTts.setSpeechRate(0.6);

    List<String> letters = widget.text.toUpperCase().split('');

    for (String letter in letters) {
      if (anotherEvent || !mounted) break;

      // Usamos un Completer para esperar a que TTS termine cada letra
      final completer = Completer<void>();

      _flutterTts.setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });

      await _flutterTts.speak(letter);
      
      // Espera a que termine de pronunciar la letra
      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {}, // si tarda más de 2s pasa a la siguiente
      );

      // Pausa entre letras
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (mounted) setState(() => block = false);
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
        label: "${widget.text}. Toca para escuchar.",
        onTap: () {
          _speakNormal();
        },
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Seleccionar como respuesta'): () {
            widget.onPressed?.call();
          },
          const CustomSemanticsAction(label: 'Escuchar pronunciación lenta'): () {
              _speakSlowly();
          },
          const CustomSemanticsAction(label: 'Escuchar letra por letra'): () {
              _spellOut();
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 16,
            ),
            color: Colors.indigo,
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
            )
          ),
        ),
      ),
    );
  }
}
