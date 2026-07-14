import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:happyblindglish/models/leccion.dart';
import 'package:happyblindglish/presentation/blocs/leccion_cubit.dart';
import 'package:happyblindglish/presentation/screens/generic_scaffolds/main_custom_scaffold.dart';
import 'package:happyblindglish/utils/app_utils.dart';

class LeccionesScreen extends StatefulWidget {
  const LeccionesScreen({super.key});

  @override
  State<LeccionesScreen> createState() => _LeccionesScreenState();
}

class _LeccionesScreenState extends State<LeccionesScreen> {
  List<Leccion> lecciones = [];
  @override
  void initState() {
    super.initState();
    _obtenerLeccionesDelDia().then((value) {
      setState(() {
        lecciones = value;
      });
    });
  }

  Future<List<Leccion>> _obtenerLeccionesDelDia() async {

    List<Leccion> todasLasLecciones = [
      Leccion(tema: "animales", nombre: 'Los animales', dificultad: 1),
      Leccion(tema: "colores", nombre: 'Los colores', dificultad: 1),
      Leccion(tema: "verbos", nombre: 'Aprende verbos', dificultad: 1),
      Leccion(tema: "saludos", nombre: "Frases cotidianas", dificultad: 1),
      Leccion(tema: "letras", nombre: "El abecedario o alfabeto", dificultad: 1),
      Leccion(tema: "numeros", nombre: "Los números", dificultad: 1),
      Leccion(tema: "dias_meses", nombre: "Los meses y días de la semana", dificultad: 1),
    ];

    return todasLasLecciones;
  }

  @override
  Widget build(BuildContext context) {
    return MainCustomScaffold(
        returnBottomButtonActivated: true,
        view: Column(
          children: [
            Container(
              color: AppUtils.generalBackground,
              height: MediaQuery.of(context).size.height / 1.5,
              child: ListView.builder(
                  itemCount: lecciones.length,
                  itemBuilder: (context, index) {
                    return LeccionCard(
                      leccion: lecciones[index],
                      onPressed: () {
                        context
                            .read<LeccionCubit>()
                            .setLessonSelection(lecciones[index]);
                        Navigator.pushNamed(
                          context,
                          "leccion_actividad_screen",
                        );
                      },
                    );
                  }),
            ),
          ],
        ),
        title: "Lecciones y vocabulario",
        tutorialText:
            '''En esta pantalla podrás encontrar las lecciones con las que puedes aprender continuamente. El progreso que hagas en cada lección y las palabras aprendidas se quedarán guardadas aunque salgas de la lección o de la aplicación''');
  }
}

class LeccionCard extends StatelessWidget {
  final void Function()? onPressed;
  final Leccion leccion;
  const LeccionCard({
    super.key,
    required this.leccion,
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
            child: ListTile(
              title: Text(leccion.nombre),
            ),
          ),
        ),
      ),
    );
  }
}
