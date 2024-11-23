import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MaterialApp(
    home: BurgerClickerGame(),
    debugShowCheckedModeBanner: false,
  ));
}

class BurgerClickerGame extends StatefulWidget {
  const BurgerClickerGame({super.key});

  @override
  State<BurgerClickerGame> createState() => _BurgerClickerGameState();
}

class _BurgerClickerGameState extends State<BurgerClickerGame> {
  int score = 0;
  bool isBurgerVisible = false;
  Timer? _disappearTimer;
  final random = Random();
  double burgerX = 0;
  double burgerY = 0;

  @override
  void initState() {
    super.initState();
    // Démarrer le jeu après le build initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showNextBurger();
    });
  }

  void showNextBurger() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    setState(() {
      burgerX = random.nextDouble() * (size.width - 200);
      burgerY = 100 + random.nextDouble() * (size.height - 300);
      isBurgerVisible = true;
    });

    // Programmer la disparition du burger après 3 secondes
    _disappearTimer?.cancel();
    _disappearTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isBurgerVisible = false;
        });
        // Programmer l'apparition du prochain burger après 1 seconde
        Future.delayed(const Duration(seconds: 1), showNextBurger);
      }
    });
  }

  void _incrementScore() {
    if (!isBurgerVisible) return;
    
    setState(() {
      score += 10;
      isBurgerVisible = false;
    });
    
    _disappearTimer?.cancel();
    // Montrer le prochain burger après un court délai
    Future.delayed(const Duration(milliseconds: 500), showNextBurger);
  }

  @override
  void dispose() {
    _disappearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Score en haut
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Score: $score',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Burger avec effet lumineux violet
          if (isBurgerVisible)
            Positioned(
              left: burgerX,
              top: burgerY,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ElevatedButton(
                  onPressed: _incrementScore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: Stack(
                    children: [
                      // Effet de lueur violette
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // gradient: RadialGradient(
                          //   colors: [
                          //     Colors.purple.withOpacity(0.3),
                          //     Colors.transparent,
                          //   ],
                          //   stops: const [0.2, 1.0],
                          // ),
                        ),
                      ),
                      
                      // ModelViewer
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: ModelViewer(
                          src: 'assets/models/burger.glb',
                          alt: 'Burger 3D',
                          autoRotate: true,
                          cameraControls: false,
                          autoPlay: true,
                          backgroundColor: Colors.transparent,
                          scale: "1.0 1.0 1.0",
                          fieldOfView: "30deg",
                          exposure: 1.2,
                          shadowIntensity: 0,
                          disableZoom: true,
                          cameraOrbit: "0deg 90deg 100%",
                        ),
                      ),
                      
                      // Overlay effet violet
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          // gradient: LinearGradient(
                          //   begin: Alignment.topLeft,
                          //   end: Alignment.bottomRight,
                          //   colors: [
                          //     Colors.purple.withOpacity(0.2),
                          //     Colors.transparent,
                          //     Colors.transparent,
                          //     Colors.purple.withOpacity(0.2),
                          //   ],
                          //   stops: const [0.0, 0.3, 0.7, 1.0],
                          // ),
                        ),
                      ),
                      
                      // Effet de brillance
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            // gradient: LinearGradient(
                            //   begin: Alignment.topCenter,
                            //   end: Alignment.bottomCenter,
                            //   colors: [
                            //     Colors.purple.withOpacity(0.3),
                            //     Colors.transparent,
                            //   ],
                            // ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}