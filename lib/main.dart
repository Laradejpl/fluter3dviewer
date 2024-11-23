import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'dart:async';
import 'dart:math' as math;

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

class Particle {
  Offset position;
  double size;
  double opacity;
  
  Particle(this.position, this.size)
      : opacity = 1.0;

  void update() {
    opacity -= 0.05;
    size *= 0.95;
  }

  bool get isDead => opacity <= 0;
}

class ModelViewerPage extends StatefulWidget {
  const ModelViewerPage({super.key});

  @override
  State<ModelViewerPage> createState() => _ModelViewerPageState();
}

class _ModelViewerPageState extends State<ModelViewerPage> {
  bool _autoRotate = true;
  bool _isAnimating = false;
  Timer? _animationTimer;
  Timer? _particleTimer;
  Offset _currentPosition = Offset.zero;
  double _velocityY = 0;
  double _velocityX = 10;
  bool _isZigZagPhase = true;
  final List<Particle> _particles = [];
  final _random = math.Random();
  
  @override
  void dispose() {
    _animationTimer?.cancel();
    _particleTimer?.cancel();
    super.dispose();
  }

  void _addParticles() {
    // Ajout de plus de particules
    for (int i = 0; i < 8; i++) {
      final randomOffset = Offset(
        _random.nextDouble() * 30 - 15, // Réduit la dispersion horizontale
        _random.nextDouble() * 30 - 15, // Réduit la dispersion verticale
      );
      
      // Crée une particule avec une taille plus grande
      _particles.add(Particle(
        _currentPosition + randomOffset,
        _random.nextDouble() * 8 + 4, // Taille augmentée
      ));
    }
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.update();
    }
    _particles.removeWhere((particle) => particle.isDead);
  }

  void _startZigZagAnimation() {
    if (_isAnimating) return;
    _particles.clear();
    setState(() {
      _isAnimating = true;
      _autoRotate = false;
      _currentPosition = const Offset(-400, 0);
      _velocityY = 0;
      _velocityX = 10;
      _isZigZagPhase = true;
    });

    // Timer plus rapide pour les particules
    _particleTimer = Timer.periodic(const Duration(milliseconds: 8), (timer) {
      if (mounted && _isAnimating) {
        setState(() {
          _addParticles();
          _updateParticles();
        });
      } else {
        timer.cancel();
      }
    });

    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_isZigZagPhase) {
          _currentPosition += Offset(_velocityX, 3);
          
          if (_currentPosition.dx <= -400 || _currentPosition.dx >= 400) {
            _velocityX = -_velocityX;
          }

          if (timer.tick > 940) {
            _isZigZagPhase = false;
            _velocityY = 0;
          }
        } else {
          _velocityY += 0.4;
          _currentPosition += Offset(_velocityX * 0.95, _velocityY);

          final size = MediaQuery.of(context).size;
          if (_currentPosition.dy > size.height - 250) {
            timer.cancel();
            _particleTimer?.cancel();
            setState(() {
              _isAnimating = false;
              _currentPosition = Offset(_currentPosition.dx, size.height - 250);
              _autoRotate = true;
              _particles.clear();
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualiseur 3D avec ZigZag'),
      ),
      body: Stack(
        children: [
          // Particules
          ..._particles.map((particle) => Positioned(
            left: MediaQuery.of(context).size.width / 2 + particle.position.dx,
            top: particle.position.dy,
            child: Container(
              width: particle.size,
              height: particle.size,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.shade300.withOpacity(particle.opacity),
                    Colors.blue.shade200.withOpacity(particle.opacity * 0.5),
                    Colors.blue.shade100.withOpacity(particle.opacity * 0.2),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(particle.opacity * 0.5),
                    blurRadius: particle.size * 0.5,
                    spreadRadius: particle.size * 0.2,
                  ),
                ],
              ),
            ),
          )),
          
          // Modèle 3D
          AnimatedPositioned(
            duration: const Duration(milliseconds: 16),
            left: MediaQuery.of(context).size.width / 2 + _currentPosition.dx,
            top: _currentPosition.dy,
            child: SizedBox(
              width: 200,
              height: 200,
              child: ModelViewer(
                src: 'assets/models/jetski.glb',
                alt: 'Modèle 3D',
                loading: Loading.eager,
                cameraControls: !_isAnimating,
                autoRotate: _autoRotate && !_isAnimating,
                rotationPerSecond: "30deg",
                autoPlay: true,
                fieldOfView: "30deg",
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAnimating ? null : _startZigZagAnimation,
        label: Text(_isAnimating ? 'Animation...' : 'Démarrer'),
        icon: Icon(_isAnimating ? Icons.hourglass_empty : Icons.play_arrow),
      ),
    );
  }
}