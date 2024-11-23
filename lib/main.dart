import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PhotoShooterPage(),
  ));
}

class Particle {
  Offset position;
  double size;
  double opacity;
  Color color;
  double velocityY;

  Particle(this.position, this.size)
      : opacity = 1.0,
        velocityY = -2.0 - math.Random().nextDouble() * 2,
        color = Colors.orange;

  void update() {
    opacity -= 0.035;
    size *= 0.95;
    position = position.translate(0, velocityY);
    velocityY += 0.1;
  }

  bool get isDead => opacity <= 0;
}

class ProjectileAnimation {
  Offset start;
  Offset target;
  double progress = 0.0;
  final List<Particle> particles = [];

  ProjectileAnimation(this.start, this.target);

  Offset getCurrentPosition() {
    return Offset.lerp(start, target, progress) ?? start;
  }
}

class PhotoShooterPage extends StatefulWidget {
  const PhotoShooterPage({super.key});

  @override
  State<PhotoShooterPage> createState() => _PhotoShooterPageState();
}

class _PhotoShooterPageState extends State<PhotoShooterPage>
    with TickerProviderStateMixin {
  final List<String> photos = ['jane.png', 'rico.png', 'pablo.png'];
  Timer? _animationTimer;
  ProjectileAnimation? _currentProjectile;
  String? _projectileModel;
  final _random = math.Random();
  bool _isProjectileVisible = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundLoaded = false;
  final List<int> scores = [0, 0, 0]; // Scores individuels pour chaque photo

  // Controllers pour les animations
  final List<AnimationController> _shakeControllers = [];
  final List<AnimationController> _shrinkControllers = [];
  final List<Animation<double>> _shrinkAnimations = [];

  @override
  void initState() {
    super.initState();
    _initSound();
    _initAnimations();
  }

  void _initAnimations() {
    for (int i = 0; i < photos.length; i++) {
      // Shake controller
      final shakeController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );

      // Shrink controller
      final shrinkController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      // Shrink animation
      final shrinkAnimation = Tween<double>(
        begin: 1.0,
        end: 0.8,
      ).animate(CurvedAnimation(
        parent: shrinkController,
        curve: Curves.easeInOut,
      ));

      _shakeControllers.add(shakeController);
      _shrinkControllers.add(shrinkController);
      _shrinkAnimations.add(shrinkAnimation);
    }
  }

  Future<void> _initSound() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/bombsound.wav'));
      _isSoundLoaded = true;
    } catch (e) {
      debugPrint('Erreur de chargement du son: $e');
    }
  }

  void _playImpactAnimation(int photoIndex) {
    _shakeControllers[photoIndex].forward().then((_) {
      _shakeControllers[photoIndex].reverse();
    });

    _shrinkControllers[photoIndex].forward().then((_) {
      _shrinkControllers[photoIndex].reverse();
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _audioPlayer.dispose();
    for (var controller in _shakeControllers) {
      controller.dispose();
    }
    for (var controller in _shrinkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _playImpactSound() async {
    final player = AudioPlayer();
    try {
      await player.play(AssetSource('sounds/bombsound.wav'), volume: 1.0);
      Future.delayed(const Duration(milliseconds: 1000), () {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Erreur de lecture du son: $e');
      player.dispose();
    }
  }

  void _showProjectileSelection(int photoIndex) {
    if (_isProjectileVisible) return;

    final photoPosition = Offset(
      MediaQuery.of(context).size.width * (photoIndex + 1) / 4,
      150,
    );

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Choisissez votre projectile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _launchProjectile('bomb.glb', photoPosition, photoIndex);
                    },
                    child: Column(
                      children: [
                        Image.asset('assets/images/bomb.png',
                            width: 60, height: 60),
                        const Text('Bombe')
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _launchProjectile('starship.glb', photoPosition, photoIndex);
                    },
                    child: Column(
                      children: [
                        Image.asset('assets/images/starship.png',
                            width: 60, height: 60),
                        const Text('Vaisseau')
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _launchProjectile('burger.glb', photoPosition, photoIndex);
                    },
                    child: Column(
                      children: [
                        Image.asset('assets/images/burger.png',
                            width: 60, height: 60),
                        const Text('Burger')
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _addParticles() {
    if (_currentProjectile == null) return;

    final position = Offset(_currentProjectile!.getCurrentPosition().dx + 50,
        _currentProjectile!.getCurrentPosition().dy + 50);

    for (int i = 0; i < 8; i++) {
      final randomOffset = Offset(
        _random.nextDouble() * 15 - 7.5,
        _random.nextDouble() * 10,
      );
      _currentProjectile!.particles.add(
          Particle(position + randomOffset, _random.nextDouble() * 12 + 6));
    }
  }

  void _updateParticles() {
    if (_currentProjectile == null) return;

    for (var particle in _currentProjectile!.particles) {
      particle.update();
    }
    _currentProjectile!.particles.removeWhere((particle) => particle.isDead);
  }

  void _launchProjectile(String modelFile, Offset targetPosition, int photoIndex) {
    final screenSize = MediaQuery.of(context).size;
    final startPosition = Offset(screenSize.width / 2, screenSize.height - 150);
    final adjustedTarget = Offset(targetPosition.dx - 50, targetPosition.dy - 50);
    
    final distance = (adjustedTarget - startPosition).distance;
    final animationDuration = (distance / 500 * 1000).clamp(500.0, 1500.0);
    final soundDelay = animationDuration * 0.8;
    
    setState(() {
      // Mettre à jour le score de la photo ciblée
      if (modelFile == 'burger.glb') {
        scores[photoIndex] += 1;
      } else if (modelFile == 'bomb.glb') {
        scores[photoIndex] = math.max(0, scores[photoIndex] - 1);
      }
      
      _projectileModel = modelFile;
      _currentProjectile = ProjectileAnimation(startPosition, adjustedTarget);
      _isProjectileVisible = true;
    });

    Future.delayed(Duration(milliseconds: soundDelay.toInt()), () {
      if (mounted) {
        _playImpactSound();
        _playImpactAnimation(photoIndex);
      }
    });

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_currentProjectile!.progress >= 1.0) {
          timer.cancel();
          _isProjectileVisible = false;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _currentProjectile = null;
                _projectileModel = null;
              });
            }
          });
          return;
        }

        _currentProjectile!.progress += 16 / animationDuration;
        _addParticles();
        _updateParticles();
      });
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Photo Shooter'),
    ),
    body: Stack(
      children: [
        // Photos avec animations et scores individuels
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return Stack(
                children: [
                  // Photo avec animations
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _shakeControllers[index],
                      _shrinkControllers[index],
                    ]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeControllers[index].value * 10 - 5, 0),
                        child: Transform.scale(
                          scale: _shrinkAnimations[index].value,
                          child: GestureDetector(
                            onTap: () => _showProjectileSelection(index),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: Colors.blue, width: 2),
                                image: DecorationImage(
                                  image: AssetImage('assets/images/${photos[index]}'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Pastille de score
                  Positioned(
                    left: -5,
                    bottom: -5,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        scores[index].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),

        // Particles avec effet de flammes
        if (_currentProjectile != null)
          ..._currentProjectile!.particles.map((particle) => Positioned(
                left: particle.position.dx,
                top: particle.position.dy,
                child: Container(
                  width: particle.size,
                  height: particle.size * 1.2,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.5),
                      radius: 0.8,
                      colors: [
                        Colors.yellow.withOpacity(particle.opacity),
                        Colors.orange.withOpacity(particle.opacity * 0.8),
                        Colors.red.withOpacity(particle.opacity * 0.5),
                        Colors.red.shade900.withOpacity(particle.opacity * 0.3),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(particle.opacity * 0.5),
                        blurRadius: particle.size * 0.5,
                        spreadRadius: particle.size * 0.2,
                      ),
                    ],
                  ),
                ),
              )),

        // Projectile 3D
        if (_isProjectileVisible &&
            _currentProjectile != null &&
            _projectileModel != null)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 16),
            curve: Curves.linear,
            left: _currentProjectile!.getCurrentPosition().dx,
            top: _currentProjectile!.getCurrentPosition().dy,
            width: 100,
            height: 100,
            child: ModelViewer(
              src: 'assets/models/$_projectileModel',
              alt: 'Projectile 3D',
              autoRotate: true,
              cameraControls: false,
              autoPlay: true,
              backgroundColor: Colors.transparent,
              scale: "0.5 0.5 0.5",
              fieldOfView: "45deg",
              cameraOrbit: "0deg 75deg 150%",
              minCameraOrbit: "auto auto 150%",
              maxCameraOrbit: "auto auto 150%",
              exposure: 1.0,
            ),
          ),
      ],
    ),
  );
}
}