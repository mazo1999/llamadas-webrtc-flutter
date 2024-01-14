import 'package:flutter/material.dart';
import 'package:flutter_meet/presentation/screens/screens.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _idCallController = TextEditingController();
  @override
  void dispose() {
    _idCallController.dispose();
    super.dispose();
  }

  void _createMeet() async {
    Uuid uuid = const Uuid();
    String meetId = uuid.v1();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext _) => MeetsScreen(
          meetId: meetId,
        ),
      ),
    );
  }

  void _joinMeet() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext _) => MeetsScreen(
          callerId: _idCallController.text,
        ),
      ),
    );
  }

  void _openFullscreenDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateb) => Dialog.fullscreen(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Ingrese a una reunión'),
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  TextButton(
                    child: const Text('Cerrar'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextField(
                      onChanged: (value) {
                        setStateb(() {});
                      },
                      controller: _idCallController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.link_sharp),
                        suffixIcon: _idCallController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _idCallController.clear();
                                },
                              )
                            : null,
                        labelText: 'Código de la reunión',
                        hintText: 'Ej: k8ub-uf4d-3f4d-3f4d',
                        filled: true,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    FilledButton(
                      onPressed: _joinMeet,
                      child: const Text('Ingresar'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuniones Flutter'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.info),
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Reuniones Flutter',
                  applicationVersion: '1.0.0',
                  applicationIcon: const FlutterLogo(),
                  children: [
                    const Text(
                        'Aplicación de reuniones en Flutter desarollado por: Rogelio Josue Carata Inca.'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: _createMeet,
              child: const IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Crear nueva reunión'),
                    VerticalDivider(
                      endIndent: 5,
                      indent: 5,
                    ),
                    Icon(
                      Icons.video_call_rounded,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            OutlinedButton(
              onPressed: () {
                _openFullscreenDialog(context);
              },
              child: const IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ingresar a una reunión'),
                    VerticalDivider(
                      endIndent: 2,
                      indent: 2,
                    ),
                    Icon(Icons.group),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
