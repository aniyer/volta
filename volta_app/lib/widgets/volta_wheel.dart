import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/cyber_vibrant_theme.dart';

/// Mission data model for the wheel
class WheelMission {
  final String id;
  final String title;
  final String icon;
  final String description;
  final int points;
  final Color color;
  
  WheelMission({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.points,
    required this.color,
  });
}

/// The signature VOLTA Wheel - an interactive spinning chore selector
class VoltaWheel extends StatefulWidget {
  final List<WheelMission> missions;
  final Function(WheelMission) onMissionSelected;
  
  const VoltaWheel({
    super.key,
    required this.missions,
    required this.onMissionSelected,
  });

  static const List<Color> segmentColors = [
    CyberVibrantTheme.neonViolet, // Purple
    CyberVibrantTheme.electricTeal, // Teal
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFFF5722), // Deep Orange (Distinct from Amber/Orange)
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan (Distinct from Teal)
    Color(0xFF8D6E63), // Brown
    Color(0xFF6366F1), // Indigo
    Color(0xFF84CC16), // Lime
  ];

  @override
  State<VoltaWheel> createState() => _VoltaWheelState();
}

class _VoltaWheelState extends State<VoltaWheel>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  
  double _currentRotation = 0;
  bool _isSpinning = false;
  int? _selectedIndex;
  
  final Random _random = Random();
  


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _spin() {
    if (_isSpinning || widget.missions.isEmpty) return;
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isSpinning = true;
      _selectedIndex = null;
    });
    
    // Calculate target rotation to land on the selected index
    // The pointer is at the top (-pi/2).
    // Segment i center is at: -pi/2 + i*angle + angle/2
    // We want the wheel to rotate R such that: Position(i) + R = -pi/2 (mod 2pi)
    // -pi/2 + i*angle + angle/2 + R = -pi/2
    // R = -(i*angle + angle/2)
    
    final targetIndex = _random.nextInt(widget.missions.length);
    final segmentAngle = (2 * pi) / widget.missions.length;
    final missionTitle = widget.missions[targetIndex].title;
    
    // Calculate current position in modulus (positive 0..2pi)
    double currentMod = _currentRotation % (2 * pi);
    if (currentMod < 0) currentMod += 2 * pi;
    
    // Target modulation
    final targetModRaw = -(targetIndex * segmentAngle + segmentAngle / 2);
    // Normalize targetMod to 0..2pi for easier delta calc
    double targetMod = targetModRaw % (2 * pi);
    if (targetMod < 0) targetMod += 2 * pi;
    
    // Calculate forward distance to target (Clockwise)
    // We want to go from currentMod -> targetMod
    // If target > current: delta = target - current
    // If target < current: delta = (2pi - current) + target
    
    double delta = targetMod - currentMod;
    while (delta < 0) {
      delta += 2 * pi;
    }
    
    print('SPIN DEBUG: Target Index: $targetIndex ($missionTitle)');
    print('Current Rotation: $_currentRotation (Mod: $currentMod)');
    print('Target Mod: $targetMod');
    print('Delta: $delta');
    
    // Add extra spins
    final extraRotations = 5 + _random.nextInt(3);
    final totalRotation = delta + (extraRotations * 2 * pi);
    
    print('Total Rotation: $totalRotation');

    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: _currentRotation + totalRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _rotationAnimation.addListener(() {
      setState(() {
        _currentRotation = _rotationAnimation.value;
      });
    });
    
    _selectedIndex = targetIndex;
    _controller.forward(from: 0);
  }
  
  void _onSpinComplete() {
    HapticFeedback.heavyImpact();
    
    setState(() {
      _isSpinning = false;
    });
    
    if (_selectedIndex != null) {
      widget.onMissionSelected(widget.missions[_selectedIndex!]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Increased size to fit text
    // Increased size to fit text
    const double wheelSize = 400; 
    const double painterSize = 380;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Wheel
        SizedBox(
          width: wheelSize,
          height: wheelSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: wheelSize - 10,
                height: wheelSize - 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              
              // Wheel segments
              Transform.rotate(
                angle: _currentRotation,
                child: CustomPaint(
                  size: const Size(painterSize, painterSize),
                  painter: WheelPainter(
                    missions: widget.missions,
                    colors: VoltaWheel.segmentColors,
                  ),
                ),
              ),
              
              // Center hub
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CyberVibrantTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.8),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Pointer/indicator at top
              Positioned(
                top: 0,
                child: Container(
                  width: 30,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CyberVibrantTheme.magmaOrange,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.magmaOrange, 0.8),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // SPIN Button
        GestureDetector(
          onTap: _isSpinning ? null : _spin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 160,
            height: 60,
            decoration: BoxDecoration(
              gradient: _isSpinning 
                  ? LinearGradient(
                      colors: [
                        CyberVibrantTheme.textMuted,
                        CyberVibrantTheme.withAlpha(CyberVibrantTheme.textMuted, 0.8),
                      ],
                    )
                  : CyberVibrantTheme.spinButtonGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: _isSpinning ? [] : [
                BoxShadow(
                  color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.magmaOrange, 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: _isSpinning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'SPIN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ).animate(
          target: _isSpinning ? 0 : 1,
        ).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 200.ms,
        ),
      ],
    );
  }
}

/// Custom painter for wheel segments
class WheelPainter extends CustomPainter {
  final List<WheelMission> missions;
  final List<Color> colors;
  
  WheelPainter({
    required this.missions,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (missions.isEmpty) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / missions.length;
    
    for (int i = 0; i < missions.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;
      final color = colors[i % colors.length];
      
      // Draw segment
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );
      
      // Draw segment border
      final borderPaint = Paint()
        ..color = CyberVibrantTheme.darkBase
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );
      
      // Draw text label
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + segmentAngle / 2);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: missions[i].title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: radius * 0.5);
      
      canvas.translate(radius * 0.55, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) {
    return missions != oldDelegate.missions;
  }
}
