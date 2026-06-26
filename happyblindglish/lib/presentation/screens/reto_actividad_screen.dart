import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:happyblindglish/global/banco_palabras.dart';
import 'package:happyblindglish/models/palabra.dart';
import 'package:happyblindglish/models/pregunta_respuestas.dart';
import 'package:happyblindglish/models/reto.dart';
import 'package:happyblindglish/presentation/blocs/reto_cubit.dart';
import 'package:logger/logger.dart';
import 'package:happyblindglish/utils/constants.dart';
import 'package:happyblindglish/widgets/custom_button_2.dart';
import 'package:happyblindglish/widgets/translated_button.dart';

final logger = Logger();

class RetoActividadScreen extends StatefulWidget {
  const RetoActividadScreen({super.key});

  @override
  State<RetoActividadScreen> createState() => _RetoActividadScreenState();
}

class _RetoActividadScreenState extends State<RetoActividadScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late List<PreguntaRespuestas> preguntas;
  int _indicePregunta = 0; // Índice de la pregunta actual
  int puntosGanados = 0;
  late Reto selectedReto;
  bool firstTime = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    selectedReto = context.read<RetoCubit>().state!;
    preguntas = generarPreguntas(
      BancoPalabras.bancoTraducciones,
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  RegExp regex = RegExp(r'¿Cómo se dice:\s*(.*)');

  List<PreguntaRespuestas> generarPreguntas(
    List<Palabra> banco,
  ) {
    List<PreguntaRespuestas> preguntas = [];
    Random random = Random();
    final bancoLocal =
        banco.where((palabra) => palabra.tipo == selectedReto.tema).toList();

    for (int i = 0; i < selectedReto.datosReto.palabrasPorAprender; i++) {
      var palabra = bancoLocal[random.nextInt(bancoLocal.length)];
      String preguntaTexto =
          "¿Cómo se dice: ${palabra.palabraEspanol} en inglés?";
      String respuestaCorrecta = palabra.palabraIngles;
      String tipoPalabra = palabra.tipo;

      List<String> opcionesIncorrectas = bancoLocal
          .where((p) =>
              p.tipo == tipoPalabra && p.palabraIngles != respuestaCorrecta)
          .map((p) => p.palabraIngles)
          .toList();

      while (opcionesIncorrectas.length < 3) {
        var palabraExtra = bancoLocal[random.nextInt(bancoLocal.length)];
        if (!opcionesIncorrectas.contains(palabraExtra.palabraIngles) &&
            palabraExtra.palabraIngles != respuestaCorrecta) {
          opcionesIncorrectas.add(palabraExtra.palabraIngles);
        }
      }

      opcionesIncorrectas.shuffle();
      List<String> respuestasIncorrectas = opcionesIncorrectas.take(3).toList();

      List<Respuesta> respuestas = [
        Respuesta(respuesta: respuestaCorrecta, correcta: true),
        ...respuestasIncorrectas
            .map((r) => Respuesta(respuesta: r, correcta: false)),
      ];

      respuestas.shuffle();

      preguntas.add(PreguntaRespuestas(
        pregunta: preguntaTexto,
        respuestas: respuestas,
        tipoPalabra: tipoPalabra,
      ));
    }

    return preguntas;
  }

  Future<void> _playSound(AssetSource sound) async {
    try {
      await _audioPlayer.play(sound);
    } catch (e) {
      logger.i("Error al reproducir sonido: $e");
    }
  }

  Future<void> _answer(bool esCorrecta, Reto state) async {
    if (_loading) return; // Evita múltiples respuestas rápidas
    setState(() => _loading = true);
    
    if (esCorrecta) {
      puntosGanados +=
          state.datosReto.puntosReto ~/ state.datosReto.palabrasPorAprender;
      await _playSound(AssetSource('sonidos/assert.mp3'));
      await Future.delayed(const Duration(seconds: 2));
    } else {
      await _playSound(AssetSource('sonidos/wrong.mp3'));
      await Future.delayed(const Duration(seconds: 2));
    }
    _siguientePregunta();
  }

  void _siguientePregunta() {
    if (_indicePregunta < selectedReto.datosReto.palabrasPorAprender - 1) {
      SemanticsService.announce(
          "Pregunta ${_indicePregunta + 2} de ${selectedReto.datosReto.palabrasPorAprender}${preguntas[_indicePregunta + 1].pregunta}",
          TextDirection.ltr);
      setState(() {
        _indicePregunta++;
        _loading = false; // libera el bloqueo para la siguiente pregunta
      });
    } else {
      SemanticsService.announce(
          "$puntosGanados puntos ganados, actividad finalizada, Te encuentras en: Retos del día",
          TextDirection.ltr);
      Navigator.pop(context);
    }
  }

  Widget _buildInstructions() {
    final bool lectorActivo = WidgetsBinding.instance.accessibilityFeatures.accessibleNavigation;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        padding: const EdgeInsets.all(12),
        child: lectorActivo ? const Column( // Con lector de pantalla
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instrucciones', 
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, 
                color: Colors.black
              )
            ),
            SizedBox(height: 4),
            Text(
              "• La palabra se pronuncia automáticamente al llegar a ella."
              " Toca dos veces para seleccionar como respuesta.\n"
              "• Escucha lo que dice tu sistema y sigue las intrucciones para ver más acciones:"
              " 'Seleccionar como respuesta', 'Escuchar pronunciación lenta' o 'Escuchar letra por letra'.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
                height: 1.6,
              ),
            )
          ],
        ) : 
        // Sin lector de pantalla
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instrucciones', 
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, 
                color: Colors.black
              )
            ),
            SizedBox(height: 4),
            Text(
              "• Toca una vez para escuchar.\n"
              "• Toca dos veces para seleccionar como respuesta.\n"
              "• Mantén presionado para escuchar letra por letra.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
                height: 1.6,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Puntaje: $puntosGanados acumulados"),
        backgroundColor: Colors.amber,
        actions: [
          Semantics(
            label: "Botón de ayuda",
            button: true,
            child: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("¿Cómo responder?"),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "El reto son cinco preguntas, cada pregunta cuenta con cuatro (4) opciones de respuesta disponibles."
                            "Debes elegir la respuesta correcta entre esas opciones."
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Sin lector de pantalla:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text("• Toca una vez para escuchar la palabra"),
                          Text("• Toca dos veces para seleccionar como respuesta"),
                          Text("• Mantén presionado para escuchar letra por letra"),
                          SizedBox(height: 12),
                          Text(
                            "Con lector de pantalla:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text("• La palabra se pronuncia automáticamente al llegar a ella"),
                          Text("• Escucha lo que dice tu sistema y sigue las intrucciones para ver más acciones"),
                          Text("• Puedes elegir entre: 'Seleccionar como respuesta', 'Escuchar pronunciación lenta' o 'Escuchar letra por letra'"),
                        ],
                      ),
                      actions: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text("Cerrar"),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.help),
            ),
          ),
        ],
      ),
      body: BlocBuilder<RetoCubit, Reto?>(
        builder: (context, state) {
          if (firstTime) {
            firstTime = false;
            SemanticsService.announce(
                "Entraste a: acierta ${selectedReto.datosReto.palabrasPorAprender} ${selectedReto.tema} en inglés",
                TextDirection.ltr);
          }
          return SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Instrucciones siempre visibles
                _buildInstructions(),
                // Contador de preguntas
                Semantics(
                  child: Text(
                    "Pregunta ${_indicePregunta + 1} de ${selectedReto.datosReto.palabrasPorAprender}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Pregunta
                ExcludeSemantics(
                  excluding: _loading, // Excluye la semántica mientras se está cargando
                  child: AbsorbPointer(
                    absorbing: _loading, // Evita interacciones mientras se está cargando
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              // Permite que el texto use el espacio disponible y haga multilínea
                              child: Semantics(
                                child: Align(
                                  child: Text(
                                    preguntas[_indicePregunta].pregunta,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 20),
                                    softWrap: true, // Permite el salto de línea
                                    overflow: TextOverflow.visible, // Evita que el texto se corte
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                         ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: preguntas[_indicePregunta].respuestas.length,
                          semanticChildCount: preguntas[_indicePregunta]
                              .respuestas
                              .length, // Importante
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TranslatedButton(
                                onPressed: () async {
                                  await _answer(
                                    preguntas[_indicePregunta]
                                        .respuestas[index]
                                        .correcta,
                                    state!
                                  );
                                },
                                text: preguntas[_indicePregunta]
                                    .respuestas[index]
                                    .respuesta,
                                index: index
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón terminar actividad
                CustomButton2(
                  onPressed: () {
                    // Mostrar el diálogo de confirmación
                    SemanticsService.announce(
                        '¿Seguro de que deseas terminar la actividad?',
                        TextDirection.ltr);
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: const Text(
                              'Perderás los puntos acumulados y no podrás volver a hacer este reto'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(), // Cerrar el diálogo
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pop(context); // Salir de la pantalla
                                SemanticsService.announce(
                                    'Regresaste a retos del día',
                                    TextDirection.ltr);
                              },
                              child: const Text('Sí, terminar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  text: Strings.terminarActividad,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
