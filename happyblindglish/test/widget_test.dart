// This tests should be separated
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happyblindglish/main.dart';
import 'package:happyblindglish/models/palabra.dart';
import 'package:happyblindglish/models/leccion.dart';
import 'package:happyblindglish/models/reto.dart';
import 'package:happyblindglish/presentation/blocs/leccion_cubit.dart';
import 'package:happyblindglish/presentation/blocs/reto_cubit.dart';
import 'package:happyblindglish/presentation/blocs/tutorial_preference.dart';
import 'package:happyblindglish/presentation/screens/main_screen.dart';
import 'package:happyblindglish/presentation/screens/onboarding_screen.dart';

// Widget helper para proveer los BLoCs necesarios en los tests
Widget _withBlocs(Widget child) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => TutorialPreferenceCubit()),
      BlocProvider(create: (_) => RetoCubit()),
      BlocProvider(create: (_) => LeccionCubit()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  // ── Modelo Palabra ────────────────────────────────────────
  group('Modelo Palabra', () {
    test('toMap y fromMap son consistentes', () {
      final palabra = Palabra(
        palabraEspanol: 'perro',
        palabraIngles: 'dog',
        tipo: 'animales',
        nivel: 1,
        aprendido: false,
      );

      final map = palabra.toMap();
      final palabraReconstruida = Palabra.fromMap(map);

      expect(palabraReconstruida.palabraEspanol, equals('perro'));
      expect(palabraReconstruida.palabraIngles, equals('dog'));
      expect(palabraReconstruida.tipo, equals('animales'));
      expect(palabraReconstruida.nivel, equals(1));
      expect(palabraReconstruida.aprendido, equals(false));
    });

    test('aprendido se convierte correctamente a int en toMap', () {
      final palabraAprendida = Palabra(
        palabraEspanol: 'gato',
        palabraIngles: 'cat',
        tipo: 'animales',
        nivel: 1,
        aprendido: true,
      );

      final map = palabraAprendida.toMap();
      expect(map['aprendido'], equals(1));
    });

    test('aprendido se convierte correctamente desde int en fromMap', () {
      final map = {
        'palabraEspanol': 'gato',
        'palabraIngles': 'cat',
        'tipo': 'animales',
        'nivel': 1,
        'aprendido': 1,
      };

      final palabra = Palabra.fromMap(map);
      expect(palabra.aprendido, isTrue);
    });

    test('aprendido es false por defecto', () {
      final palabra = Palabra(
        palabraEspanol: 'casa',
        palabraIngles: 'house',
        tipo: 'partes_casa',
        nivel: 1,
      );
      expect(palabra.aprendido, isFalse);
    });
  });

  // ── Modelo Leccion ────────────────────────────────────────
  group('Modelo Leccion', () {
    test('toMap y fromMap son consistentes', () {
      final leccion = Leccion(
        nombre: 'Los animales',
        tema: 'animales',
        dificultad: 1,
      );

      final map = leccion.toMap();
      final leccionReconstruida = Leccion.fromMap(map);

      expect(leccionReconstruida.nombre, equals('Los animales'));
      expect(leccionReconstruida.tema, equals('animales'));
      expect(leccionReconstruida.dificultad, equals(1));
    });
  });

  // ── Modelo Reto ───────────────────────────────────────────
  group('Modelo Reto', () {
    test('toMap y fromMap son consistentes', () {
      final reto = Reto(
        tema: 'animales',
        tipo: 'acertarLasPalabras',
        estatusCompletado: false,
        datosReto: DatosReto(
          puntosReto: 20,
          palabrasPorAprender: 5,
        ),
      );

      final map = reto.toMap();
      final retoReconstruido = Reto.fromMap(map);

      expect(retoReconstruido.tema, equals('animales'));
      expect(retoReconstruido.estatusCompletado, isFalse);
      expect(retoReconstruido.datosReto.puntosReto, equals(20));
      expect(retoReconstruido.datosReto.palabrasPorAprender, equals(5));
    });

    test('estatusCompletado se convierte correctamente a int', () {
      final reto = Reto(
        tipo: 'acertarLasPalabras',
        estatusCompletado: true,
        datosReto: DatosReto(puntosReto: 10, palabrasPorAprender: 3),
      );

      final map = reto.toMap();
      expect(map['estatusCompletado'], equals(1));
    });
  });

  // ── BLoCs ─────────────────────────────────────────────────
  group('LeccionCubit', () {
    test('estado inicial es null', () {
      final cubit = LeccionCubit();
      expect(cubit.state, isNull);
    });

    test('setLessonSelection actualiza el estado', () {
      final cubit = LeccionCubit();
      final leccion = Leccion(
        nombre: 'Los colores',
        tema: 'colores',
        dificultad: 1,
      );

      cubit.setLessonSelection(leccion);
      expect(cubit.state?.tema, equals('colores'));
    });
  });

  group('RetoCubit', () {
    test('estado inicial es null', () {
      final cubit = RetoCubit();
      expect(cubit.state, isNull);
    });

    test('setChallengeSelection actualiza el estado', () {
      final cubit = RetoCubit();
      final reto = Reto(
        tema: 'verbos',
        tipo: 'acertarLasPalabras',
        estatusCompletado: false,
        datosReto: DatosReto(puntosReto: 40, palabrasPorAprender: 5),
      );

      cubit.setChallengeSelection(reto);
      expect(cubit.state?.tema, equals('verbos'));
      expect(cubit.state?.datosReto.puntosReto, equals(40));
    });
  });

  // ── Widgets ───────────────────────────────────────────────
  group('OnboardingScreen', () {
    testWidgets('muestra el título de bienvenida', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pump();

      expect(
        find.text('Bienvenido a HappyBlindglish'),
        findsOneWidget,
      );
    });

    testWidgets('muestra botón Siguiente en la primera página', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pump();

      expect(find.text('SIGUIENTE'), findsOneWidget);
    });

    testWidgets('no muestra botón Anterior en la primera página',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pump();

      expect(find.text('ANTERIOR'), findsNothing);
    });
  });

  group('MainScreen', () {
    testWidgets('muestra los tres botones principales', (tester) async {
      await tester.pumpWidget(
        _withBlocs(
          const MainScreen(text: 'texto de prueba'),
        ),
      );
      await tester.pump();

      expect(find.text('RETOS DEL DÍA'), findsOneWidget);
      expect(find.text('VER MI PROGRESO'), findsOneWidget);
      expect(find.text('LECCIONES Y VOCABULARIO'), findsOneWidget);
    });
  });

  // ── MyApp ─────────────────────────────────────────────────
  group('MyApp', () {
    testWidgets('arranca sin errores con isFirstLaunch true', (tester) async {
      await tester.pumpWidget(
        _withBlocs(const MyApp(isFirstLaunch: true)),
      );
      await tester.pump();
      expect(find.byType(MyApp), findsOneWidget);
    });

    testWidgets('arranca sin errores con isFirstLaunch false', (tester) async {
      await tester.pumpWidget(
        _withBlocs(const MyApp(isFirstLaunch: false)),
      );
      await tester.pump();
      expect(find.byType(MyApp), findsOneWidget);
    });
  });
}