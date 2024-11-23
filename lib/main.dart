import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const ModelViewerPage(),
    );
  }
}

class ModelViewerPage extends StatefulWidget {
  const ModelViewerPage({super.key});

  @override
  State<ModelViewerPage> createState() => _ModelViewerPageState();
}

class _ModelViewerPageState extends State<ModelViewerPage> {
  bool _autoRotate = true;
  double _rotationSpeed = 30;
  String _backgroundColor = '#EEEEEE';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualiseur 3D '),
        actions: [
          // Bouton pour la rotation automatique
          IconButton(
            icon: Icon(_autoRotate ? Icons.rotate_right : Icons.rotate_right_outlined),
            onPressed: () {
              setState(() {
                _autoRotate = !_autoRotate;
              });
            },
            tooltip: 'Rotation automatique',
          ),
          // Bouton pour changer la couleur de fond
          PopupMenuButton<String>(
            icon: const Icon(Icons.color_lens),
            onSelected: (String color) {
              setState(() {
                _backgroundColor = color;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: '#FFFFFF',
                child: Text('Blanc'),
              ),
              const PopupMenuItem<String>(
                value: '#000000',
                child: Text('Noir'),
              ),
              const PopupMenuItem<String>(
                value: '#EEEEEE',
                child: Text('Gris clair'),
              ),
              const PopupMenuItem<String>(
                value: '#E3F2FD',
                child: Text('Bleu clair'),
              ),
            ],
          ),
        ],
      ),
      body: ModelViewer(
        src: 'assets/models/jetski.glb',
        alt: 'Modèle 3D',
        backgroundColor: Color(int.parse('0xFF${_backgroundColor.substring(1)}')),
        loading: Loading.eager,
        cameraControls: true,
        touchAction: TouchAction.panY,
        autoRotate: _autoRotate,
        rotationPerSecond: "${_rotationSpeed}deg",
        autoPlay: true,
        // Paramètres de caméra optimisés
        interpolationDecay: 200,
        fieldOfView: "30deg",
        minFieldOfView: "25deg",
        maxFieldOfView: "45deg",
        interactionPrompt: InteractionPrompt.auto,
      ),
      bottomNavigationBar: _buildControlPanel(),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_autoRotate) ...[
            Row(
              children: [
                const Text('Vitesse: '),
                Expanded(
                  child: Slider(
                    value: _rotationSpeed,
                    min: 5,
                    max: 90,
                    divisions: 17,
                    label: "${_rotationSpeed.round()}°/s",
                    onChanged: (value) {
                      setState(() {
                        _rotationSpeed = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {}); // Recharge le modèle
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réinitialiser'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _autoRotate = !_autoRotate;
                  });
                },
                icon: Icon(_autoRotate ? Icons.pause : Icons.play_arrow),
                label: Text(_autoRotate ? 'Pause' : 'Rotation'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}