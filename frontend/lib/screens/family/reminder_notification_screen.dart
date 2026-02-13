import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Couleurs alignées avec le dashboard famille
const Color _primary = Color(0xFFA3D9E5);
const Color _primaryDark = Color(0xFF7BBCCB);
const Color _backgroundColor = Color(0xFFF8FAFC);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate600 = Color(0xFF475569);

class ReminderNotificationScreen extends StatefulWidget {
  final String taskTitle;
  final String? taskDescription;
  final String icon;
  final String? time;
  final String reminderId;

  const ReminderNotificationScreen({
    super.key,
    required this.taskTitle,
    this.taskDescription,
    required this.icon,
    this.time,
    required this.reminderId,
  });

  @override
  State<ReminderNotificationScreen> createState() => _ReminderNotificationScreenState();
}

class _ReminderNotificationScreenState extends State<ReminderNotificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and badge
            _buildHeader(),
            
            // Main content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Icon with Smiley Face
                      _buildAnimatedIcon(),
                      
                      const SizedBox(height: 60),
                      
                      // Message Card
                      _buildMessageCard(),
                      
                      const SizedBox(height: 40),
                      
                      // Animated Time Circle
                      if (widget.time != null) _buildTimeCircle(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom padding
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.pop(),
            ),
          ),
          
          const Spacer(),
          
          // Raspberry Pi Connected Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.router, size: 14, color: _primaryDark),
                const SizedBox(width: 6),
                Text(
                  'RASPBERRY PI CONNECTÉ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.icon,
                      style: const TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 8),
                    // Smiley face
                    const Text(
                      '😊',
                      style: TextStyle(fontSize: 40),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon in card
          Container(
            width: 56,
            height: 56,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                widget.icon,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Title
          Text(
            widget.taskTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Description if available
          if (widget.taskDescription != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.taskDescription!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeCircle() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Rotating border
              Transform.rotate(
                angle: _animationController.value * 2 * 3.14159,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _primary,
                      width: 4,
                    ),
                    gradient: SweepGradient(
                      colors: [
                        _primary,
                        _primary.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Time text
              Center(
                child: Text(
                  widget.time!,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _primaryDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
