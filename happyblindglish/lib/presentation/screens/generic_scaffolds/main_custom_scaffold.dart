import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:happyblindglish/presentation/blocs/tutorial_preference.dart';
import 'package:happyblindglish/utils/app_utils.dart';
import 'package:happyblindglish/utils/constants.dart';
import 'package:happyblindglish/widgets/custom_button_1.dart';
import 'package:happyblindglish/widgets/custom_button_2.dart';

class MainCustomScaffold extends StatefulWidget {
  final String title;
  final String? buttonText1;
  final bool? forceTutorial;
  final Widget? view;
  final String tutorialText;
  final String? buttonText2;
  final String? buttonText3;
  final bool returnBottomButtonActivated;
  final void Function()? onPressed1;
  final void Function()? onPressed2;
  final void Function()? onPressed3;

  const MainCustomScaffold({
    super.key,
    required this.title,
    this.onPressed1,
    this.onPressed2,
    this.onPressed3,
    this.buttonText1,
    this.buttonText2,
    this.buttonText3,
    this.returnBottomButtonActivated = false,
    this.view,
    required this.tutorialText,
    this.forceTutorial,
  });

  @override
  State<MainCustomScaffold> createState() => _MainCustomScaffoldState();
}

class _MainCustomScaffoldState extends State<MainCustomScaffold> {
  @override
  void initState() {
    super.initState();
    SemanticsService.announce("Entraste a ${widget.title}", TextDirection.ltr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Semantics(
              excludeSemantics: true,
              label: "Botón de ayuda",
              button: false,
              child: IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Diálogo de ayuda"),
                            content: Text(widget.tutorialText),
                            actions: [
                              GestureDetector(
                                child: const Text("Cerrar cuadro de ayuda"),
                                onTap: () => Navigator.of(context).pop(),
                              )
                            ],
                          );
                        });
                  },
                  icon: const Icon(Icons.help))),
        ],
        title: Center(
          child: Text(
            softWrap: true,
            widget.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppUtils.titleFontSize,
            ),
          ),
        ),
        backgroundColor: AppUtils.generalBackground,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: AppUtils.generalBackground,
      body: BlocBuilder<TutorialPreferenceCubit, bool>(
        builder: (context, state) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppUtils.generalPadding,
                vertical: AppUtils.generalPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: state ||
                      widget.forceTutorial != null && widget.forceTutorial!,
                  child: Text(
                    widget.tutorialText,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppUtils.guideTextSize),
                    textAlign: TextAlign.justify,
                  ),
                ),
                widget.view ?? const SizedBox.shrink(),
                _buildButton(widget.buttonText1, widget.onPressed1),
                _buildButton(widget.buttonText2, widget.onPressed2),
                _buildButton(widget.buttonText3, widget.onPressed3),
                if (widget.returnBottomButtonActivated)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: AppUtils.buttonPadding,
                        left: AppUtils.buttonPadding),
                    child: CustomButton2(
                      onPressed: () => {
                        //TODO: reproducir sonido o indicar que se regresó
                        Navigator.pop(context)
                      },
                      text: Strings.screenBack.toUpperCase(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String? text, void Function()? onPressed) {
    return text != null && text.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: AppUtils.buttonPadding),
            child: Semantics(
              button: false,
              child: CustomButton1(
                onPressed: onPressed,
                text: text,
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
