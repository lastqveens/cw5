import 'package:flutter/material.dart';
import 'dart:math'; // For random movement
import 'database_helper.dart'; // Import the helper class for saving settings

void main() {
  runApp(const AquariumApp());
}

class AquariumApp extends StatelessWidget {
  const AquariumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fish Aquarium',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  const AquariumScreen({super.key});

  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Fish> fishList = [];
  double selectedSpeed = 2.0;
  Color selectedColor = Colors.red; // Default color from availableColors
  final Random random = Random();
  late Size aquariumSize;
  final List<Color> availableColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 50), // Small interval for smoother updates
      vsync: this,
    )..addListener(() {
        setState(() {
          for (var fish in fishList) {
            fish.move(aquariumSize);
          }
        });
      });

    _controller.repeat(); // Start the continuous animation

    // Load settings from the database (e.g., fish count, speed, and color)
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedSettings = await DatabaseHelper.instance.getSettings();
    setState(() {
      selectedSpeed = savedSettings['speed'] ?? 2.0;
      int savedColorValue = savedSettings['color'] ?? Colors.red.value;
      selectedColor = availableColors.firstWhere(
        (color) => color.value == savedColorValue,
        orElse: () => Colors.red, // Default if no match is found
      );
      int fishCount = savedSettings['fishCount'] ?? 5;
      for (int i = 0; i < fishCount; i++) {
        _addFish();
      }
    });
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        // Fish start at random positions with random directions
        fishList.add(Fish(
          color: selectedColor,
          speed: selectedSpeed,
          position: Offset(random.nextDouble() * aquariumSize.width,
              random.nextDouble() * aquariumSize.height),
          direction: Offset(
              random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1),
        ));
      });
    }
  }

  void _saveSettings() async {
    await DatabaseHelper.instance.saveSettings({
      'speed': selectedSpeed,
      'color': selectedColor.value,
      'fishCount': fishList.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fish Aquarium')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          aquariumSize = constraints.biggest;

          return Stack(
            children: [
              Container(
                width: aquariumSize.width,
                height: aquariumSize.height,
                color: Colors.lightBlue[100],
                child: Stack(
                  children: fishList
                      .map((fish) => Positioned(
                            left: fish.position.dx,
                            top: fish.position.dy,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: fish.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Speed Slider
                      Slider(
                        value: selectedSpeed,
                        min: 0.5,
                        max: 5.0,
                        onChanged: (value) {
                          setState(() {
                            selectedSpeed = value;
                            for (var fish in fishList) {
                              fish.speed = selectedSpeed;
                            }
                          });
                        },
                        label: "Speed: ${selectedSpeed.toStringAsFixed(2)}",
                      ),
                      
                      // Color Dropdown
                      DropdownButton<Color>(
                        value: selectedColor,
                        onChanged: (Color? newColor) {
                          setState(() {
                            selectedColor = newColor!;
                          });
                        },
                        items: availableColors.map((Color color) {
                          return DropdownMenuItem<Color>(
                            value: color,
                            child: Container(
                              width: 24,
                              height: 24,
                              color: color,
                            ),
                          );
                        }).toList(),
                      ),
                      
                      // Add Fish Button
                      ElevatedButton(
                        onPressed: _addFish,
                        child: const Text('Add Fish'),
                      ),
                      
                      // Save Settings Button
                      ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text('Save Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Fish {
  Color color;
  double speed;
  Offset position;
  Offset direction;

  Fish({
    required this.color,
    required this.speed,
    required this.position,
    required this.direction,
  });

  void move(Size aquariumSize) {
    position += direction * speed;

    if (position.dx <= 0 || position.dx >= aquariumSize.width) {
      direction = Offset(-direction.dx, direction.dy); // Reverse x-direction
    }
    if (position.dy <= 0 || position.dy >= aquariumSize.height) {
      direction = Offset(direction.dx, -direction.dy); // Reverse y-direction
    }
  }
}
