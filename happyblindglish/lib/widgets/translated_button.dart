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
    await _flutterTts.setSpeechRate(0.5); // Velocidad normal
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
        const Duration(seconds: 4),
        onTimeout: () {}, // si tarda más de 4s pasa a la siguiente
      );

      // Pausa entre letras
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (mounted) setState(() => block = false);
  }

  // Diálogo de confirmación antes de registrar la respuesta
  Future<void> _confirmSelection(BuildContext context) async {
    await _stopSpeech(); // Detiene cualquier pronunciación antes de mostrar el diálogo

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          semanticLabel: "Confirmación de respuesta.", 
          title: const Text("¿Confirmar respuesta?"),
          content: Localizations.override(
            context: context,
            locale: const Locale('en', 'US'),
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: <Widget>[
            // Cancelar — vuelve a las opciones sin perder el foco
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Devolver el foco al botón después de cancelar
                _focusNode.requestFocus();
                // Volver a pronunciar la palabra para reorientar al usuario
                _speakNormal();
              },
              child: const Text(
                "Cancelar",
                style: TextStyle(fontSize: 18),
              ),
            ),
            // Confirmar — registra la respuesta
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onPressed?.call();
              },
              child: const Text(
                "Confirmar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
        label: "${widget.text}. Toca dos veces para seleccionar como respuesta.",
        onTap: () => _confirmSelection(context),
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Seleccionar como respuesta'): () {
            _confirmSelection(context);
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
          onTap: () => _speakNormal(),
          onDoubleTap: () => _confirmSelection(context),
          onLongPress: () async {
            if (!block) {
              if (anotherEvent) {
                anotherEvent = false;
              }
              _spellOut();
            }
          },
          child: ExcludeSemantics(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 16,
              ),
              color: Colors.indigo,
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
      ),
    );
  }
}
