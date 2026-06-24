import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:happyblindglish/models/reto.dart';
import 'package:happyblindglish/presentation/blocs/reto_cubit.dart';
import 'package:happyblindglish/presentation/screens/generic_scaffolds/main_custom_scaffold.dart';
import 'package:happyblindglish/utils/app_utils.dart';

class RetosDelDiaScreen extends StatefulWidget {
  const RetosDelDiaScreen({super.key});

  @override
  State<RetosDelDiaScreen> createState() => _RetosDelDiaScreenState();
}

class _RetosDelDiaScreenState extends State<RetosDelDiaScreen> {
  List<Reto> retosDelDia = [];
  int numInicialDeRetos = 0;
  int numeroRetosCompletados = 0;
  @override
  void initState() {
    super.initState();
    _obtenerRetosDelDia().then((value) {
      setState(() {
        retosDelDia = value;
        numInicialDeRetos = retosDelDia.length;
      });
    });
  }

  Future<List<Reto>> _obtenerRetosDelDia() async {
    return [
      Reto(
          tema: "animales",
          estatusCompletado: false,
          datosReto: DatosReto(
            puntosReto: 20,
            palabrasPorAprender: 5,
          ),
          tipo: TipoDeReto.acertarLasPalabras.name),
      Reto(
          tema: "colores",
          estatusCompletado: false,
          datosReto: DatosReto(
            puntosReto: 40,
            palabrasPorAprender: 5,
          ),
          tipo: TipoDeReto.acertarLasPalabras.name),
      Reto(
          tema: "verbos",
          estatusCompletado: false,
          datosReto: DatosReto(
            puntosReto: 40,
            palabrasPorAprender: 5,
          ),
          tipo: TipoDeReto.acertarLasPalabras.name),
      Reto(
          tema: "saludos",
          estatusCompletado: false,
          datosReto: DatosReto(
            puntosReto: 100,
            palabrasPorAprender: 3,
          ),
          tipo: TipoDeReto.acertarLasPalabras.name),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MainCustomScaffold(
        returnBottomButtonActivated: true,
        view: retosDelDia.isNotEmpty
            ? Column(
                children: [
                  Semantics(
                    label:
                        "$numeroRetosCompletados de $numInicialDeRetos retos completados",
                    child: Text(
                        "$numeroRetosCompletados de $numInicialDeRetos retos completados"),
                  ),
                  Container(
                    color: AppUtils.generalBackground,
                    height: MediaQuery.of(context).size.height / 1.5,
                    child: ListView.builder(
                        itemCount: retosDelDia.length,
                        itemBuilder: (context, index) {
                          return ChallengeCard(
                            reto: retosDelDia[index],
                            onPressed: () {
                              context
                                  .read<RetoCubit>()
                                  .setChallengeSelection(retosDelDia[index]);
                              Navigator.pushNamed(
                                context,
                                "reto_actividad_screen",
                              );
                              setState(() {
                                numeroRetosCompletados += 1;
                                retosDelDia.remove(retosDelDia[index]);
                              });
                            },
                          );
                        }),
                  ),
                ],
              )
            : Center(
                child: Column(
                  children: [
                    Semantics(
                      label:
                          "$numeroRetosCompletados de $numInicialDeRetos retos completados",
                      child: Text(
                          "$numeroRetosCompletados de $numInicialDeRetos retos completados"),
                    ),
                    Semantics(
                      label: 'No hay más retos hoy',
                      child: const Text("No hay más retos hoy"),
                    ),
                  ],
                ),
              ),
        title: "Retos del día",
        tutorialText:
            "En esta pantalla podrás encontrar los retos que tienes que cumplir hoy, entrando en cada reto irás a la lección que te permitirá avanzár en él");
  }
}

class ChallengeCard extends StatelessWidget {
  final void Function()? onPressed;
  final Reto reto;
  const ChallengeCard({
    super.key,
    required this.reto,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppUtils.textButtonPadding),
      child: GestureDetector(
        onTap: onPressed,
        child: Card(
          surfaceTintColor: const Color(0xffffffff),
          child: Semantics(
            button: true,
            label:
                "Reto de ${reto.tema}, acierta ${reto.datosReto.palabrasPorAprender} palabras en inglés",
            child: ListTile(
              title: Text(
                  "Acierta ${reto.datosReto.palabrasPorAprender} ${reto.tema} en inglés"),
            ),
          ),
        ),
      ),
    );
  }
}

enum TipoDeReto { acertarLasPalabras }
