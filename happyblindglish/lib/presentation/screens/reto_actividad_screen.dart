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
          "¿Cómo se dice: ${palabra.palabraEspanol}. En inglés?";
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

  void _playSound(AssetSource sound) async {
    try {
      await _audioPlayer.play(sound);
    } catch (e) {
      logger.i("Error al reproducir sonido: $e");
    }
  }

  void _siguientePregunta() {
    if (_indicePregunta < selectedReto.datosReto.palabrasPorAprender - 1) {
      SemanticsService.announce(
          "Pregunta ${_indicePregunta + 2} de ${selectedReto.datosReto.palabrasPorAprender}${preguntas[_indicePregunta + 1].pregunta}",
          TextDirection.ltr);
      setState(() {
        _indicePregunta++;
      });
    } else {
      SemanticsService.announce(
          "$puntosGanados puntos ganados, actividad finalizada, Te encuentras en: Retos del día",
          TextDirection.ltr);
      Navigator.pop(context);
    }
  }

  void _hideUI() {
    setState(() {
      blockUI = true;
    });
  }

  void _showUI() {
    setState(() {
      blockUI = false;
    });
  }

  bool blockUI = false;
  bool firstTime = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Puntaje: $puntosGanados acumulados"),
        backgroundColor: Colors.amber,
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<RetoCubit, Reto?>(
        builder: (context, state) {
          if (firstTime) {
            firstTime = false;
            SemanticsService.announce(
                "Entraste a, acierta ${selectedReto.datosReto.palabrasPorAprender} ${selectedReto.tema} en inglés",
                TextDirection.ltr);
          }
          return Semantics(
            excludeSemantics: blockUI,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    child: Text(
                      "Pregunta ${_indicePregunta + 1} de ${selectedReto.datosReto.palabrasPorAprender}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
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
                              overflow: TextOverflow
                                  .visible, // Evita que el texto se corte
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: preguntas[_indicePregunta].respuestas.length,
                    semanticChildCount: preguntas[_indicePregunta]
                        .respuestas
                        .length, // Importante
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TranslatedButton(
                            onPressed: () async {
                              _hideUI();
                              if (preguntas[_indicePregunta]
                                  .respuestas[index]
                                  .correcta) {
                                puntosGanados += state!.datosReto.puntosReto ~/
                                    state.datosReto.palabrasPorAprender;
                                _playSound(AssetSource('sonidos/assert.mp3'));
                                await Future.delayed(
                                    const Duration(seconds: 2));

                                _siguientePregunta();
                              } else {
                                _playSound(AssetSource('sonidos/wrong.mp3'));

                                await Future.delayed(
                                    const Duration(seconds: 2));

                                _siguientePregunta();
                              }
                              _showUI();
                            },
                            text: preguntas[_indicePregunta]
                                .respuestas[index]
                                .respuesta),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        container: false,
                        label: "Leer pegunta otra vez",
                        excludeSemantics: true,
                        child: IconButton(
                          icon: const Icon(Icons.replay_outlined),
                          onPressed: () {
                            SemanticsService.announce(
                                preguntas[_indicePregunta].pregunta,
                                TextDirection.ltr);
                          },
                        ),
                      ),
                    ],
                  ),
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
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Cerrar el diálogo
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Cerrar el diálogo
                                  Navigator.pop(
                                      context); // Salir de la pantalla
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
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
