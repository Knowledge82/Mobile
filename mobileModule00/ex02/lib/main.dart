import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MyApp());
}

// root widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ex02',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const CalculatorPage(), // home = primera pantalla
    );
  }
}

// una clase normal y corriente, no un widget
// descripcion de un boton: nombre y "anchura" (flex en fila)
class _CalcKey {
  const _CalcKey(this.label, {this.flex = 1});

  final String label;
  final int flex;
}

// el teclado entero. la suma de todos flex en cada fila es igual a 5
const List<List<_CalcKey>> _keyRows = [
  [_CalcKey('7'), _CalcKey('8'), _CalcKey('9'), _CalcKey('C'), _CalcKey('AC')],
  [_CalcKey('4'), _CalcKey('5'), _CalcKey('6'), _CalcKey('+'), _CalcKey('-')],
  [_CalcKey('1'), _CalcKey('2'), _CalcKey('3'), _CalcKey('*'), _CalcKey('/')],
  [_CalcKey('0', flex: 2), _CalcKey('.'), _CalcKey('=', flex: 2)],
];

// boton de color acentuado (acciones y operadores)
const Set<String> _accentLabels = {'C', 'AC', '+', '-', '*', '/', '='};

// createState su unico proposito
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const double _maxContentWidth = 600;

  final TextEditingController _expressionController =
      TextEditingController(text: '0');
  final TextEditingController _resultController =
      TextEditingController(text: '0');

  //liberacion de los recursos
  @override
  void dispose() {
    _expressionController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  //build se llama a menudo, asi que dentro nada pesado o cosas tipo TextEditingController()
  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'), // const = se crea 1 vez en la compilacion
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column( // pila vertical de los hijos
              crossAxisAlignment: CrossAxisAlignment.stretch, //stretch = toda la anchura para cada hijo
              children: [
                Expanded(
                  flex: isLandscape ? 1 : 2,
                  child: _Display(
                    expressionController: _expressionController,
                    resultController: _resultController,
                  ),
                ),
                Expanded(
                  flex: isLandscape ? 2 : 3,
                  child: const _Keypad(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Display extends StatelessWidget {
  const _Display({
    required this.expressionController,
    required this.resultController,
  });

  final TextEditingController expressionController;
  final TextEditingController resultController;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _DisplayField(
              controller: expressionController,
              style: textTheme.headlineMedium,
            ),
          ),
          Expanded(
            child: _DisplayField(
              controller: resultController,
              style: textTheme.headlineSmall
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplayField extends StatelessWidget {
  const _DisplayField({required this.controller, required this.style});

  final TextEditingController controller;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      showCursor: false,
      expands: true,
      maxLines: null, // obligatorio con expands: null
      textAlign: TextAlign.end, // respetando RTL
      textAlignVertical: TextAlignVertical.center,
      style: style,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,// menos standard vertical paddings
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final List<_CalcKey> row in _keyRows)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final _CalcKey key in row)
                  Expanded(
                    flex: key.flex,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _CalcButton(label: key.label),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    void handlePressed() {} // layer 4

    final ButtonStyle style = FilledButton.styleFrom(padding: EdgeInsets.zero);
    final Widget text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: Theme.of(context).textTheme.titleLarge),
    );

    return _accentLabels.contains(label)
        ? FilledButton(onPressed: handlePressed, style: style, child: text)
        : FilledButton.tonal(
          onPressed: handlePressed,
          style: style,
          child: text,
          );
  }
}
