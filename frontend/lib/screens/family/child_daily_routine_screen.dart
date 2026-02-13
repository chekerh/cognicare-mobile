import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/task_reminder.dart';
import '../../services/reminders_service.dart';
import '../../providers/auth_provider.dart';

const Color _primaryBlue = Color(0xFF6BA4D7);
const Color _lightBlue = Color(0xFFBFE3F5);

class ChildDailyRoutineScreen extends StatefulWidget {
  final String childId;
  final String? routineType; // 'morning', 'afternoon', 'evening', or null for all day

  const ChildDailyRoutineScreen({
    super.key,
    required this.childId,
    this.routineType,
  });

  @override
  State<ChildDailyRoutineScreen> createState() => _ChildDailyRoutineScreenState();
}

class _ChildDailyRoutineScreenState extends State<ChildDailyRoutineScreen> {
  bool _isLoading = true;
  bool _isPiConnected = false;
  List<TaskReminder> _reminders = [];
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    // If no childId provided, show empty state
    if (widget.childId.isEmpty) {
      if (mounted) {
        setState(() {
          _reminders = [];
          _completedCount = 0;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final remindersService = RemindersService(
        getToken: () async => authProvider.accessToken,
      );

      final reminders = await remindersService.getTodayReminders(widget.childId);
      
      // Filter by routine type if specified
      List<TaskReminder> filtered = reminders;
      if (widget.routineType != null) {
        filtered = _filterByRoutineType(reminders, widget.routineType!);
      }

      // Count completed tasks
      final completed = filtered.where((r) => r.completedToday == true).length;

      if (mounted) {
        setState(() {
          _reminders = filtered;
          _completedCount = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reminders: $e');
      if (mounted) {
        setState(() {
          _reminders = [];
          _completedCount = 0;
          _isLoading = false;
        });
        // Show error only if it's not a "no reminders" case
        if (!e.toString().contains('404')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  List<TaskReminder> _filterByRoutineType(List<TaskReminder> reminders, String type) {
    // Filter based on time of day
    return reminders.where((r) {
      if (r.time == null) return false;
      final hour = int.tryParse(r.time!.split(':')[0]) ?? 0;
      
      switch (type) {
        case 'morning':
          return hour >= 6 && hour < 12;
        case 'afternoon':
          return hour >= 12 && hour < 18;
        case 'evening':
          return hour >= 18 || hour < 6;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _toggleTaskCompletion(TaskReminder reminder) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final remindersService = RemindersService(
        getToken: () async => authProvider.accessToken,
      );

      final newStatus = !(reminder.completedToday ?? false);
      
      await remindersService.completeTask(
        reminderId: reminder.id,
        completed: newStatus,
        date: DateTime.now(),
      );

      // Update local state
      if (mounted) {
        setState(() {
          final index = _reminders.indexWhere((r) => r.id == reminder.id);
          if (index != -1) {
            _reminders[index] = reminder.copyWith(
              completedToday: newStatus,
              completedAt: newStatus ? DateTime.now() : null,
            );
            
            if (newStatus) {
              _completedCount++;
            } else {
              _completedCount--;
            }
          }
        });

        // Show encouragement message
        if (newStatus) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getEncouragementMessage(reminder.type)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  String _getEncouragementMessage(ReminderType type) {
    switch (type) {
      case ReminderType.water:
        return 'Great job staying hydrated! 💧';
      case ReminderType.meal:
        return 'Well done! You had a healthy meal! 🍎';
      case ReminderType.medication:
        return 'Perfect! You took your medicine! 💊';
      case ReminderType.hygiene:
        return 'Awesome! You\'re so clean! ✨';
      case ReminderType.homework:
        return 'Amazing work! You completed your task! 📚';
      default:
        return 'Well done! Keep it up! ⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = _reminders.length;
    final progress = totalTasks > 0 ? _completedCount / totalTasks : 0.0;

    return Scaffold(
      backgroundColor: _lightBlue,
      appBar: AppBar(
        backgroundColor: _lightBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Child Daily Visual Routine',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.code, color: Colors.black54),
            onPressed: () {
              // Show code/settings dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 64,
                            color: _primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Aucune tâche pour aujourd\'hui',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Commencez par créer des rappels pour votre enfant dans la section nutrition et routines.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Retour au tableau de bord'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
              child: Column(
                children: [
                  // Header Card
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  
                  // Task List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _reminders.length,
                      itemBuilder: (context, index) {
                        return _buildTaskCard(_reminders[index]);
                      },
                    ),
                  ),
                  
                  // Progress Footer
                  _buildProgressFooter(progress, totalTasks),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getRoutineTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getRoutineDate(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (_isPiConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.router, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'RASPBERRY PI CONNECTÉ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  String _getRoutineTitle() {
    switch (widget.routineType) {
      case 'morning':
        return 'Morning Routine';
      case 'afternoon':
        return 'Afternoon Routine';
      case 'evening':
        return 'Evening Routine';
      default:
        return 'Daily Routine';
    }
  }

  String _getRoutineDate() {
    final now = DateTime.now();
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];
    final month = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][now.month - 1];
    return '$weekday, $month ${now.day}';
  }

  Widget _buildTaskCard(TaskReminder reminder) {
    final isCompleted = reminder.completedToday ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _getTaskColor(reminder.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _getTaskIcon(reminder),
            ),
          ),
          const SizedBox(width: 16),
          
          // Task Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                if (reminder.description != null || reminder.time != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.description ?? '${reminder.time}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (reminder.piSyncEnabled) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.sync, size: 14, color: Colors.blue.shade300),
                      const SizedBox(width: 4),
                      Text(
                        'PI SYNC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade300,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Checkbox
          GestureDetector(
            onTap: () => _toggleTaskCompletion(reminder),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? _primaryBlue : Colors.grey.shade300,
                  width: 2,
                ),
                color: isCompleted ? _primaryBlue : Colors.transparent,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTaskIcon(TaskReminder reminder) {
    final icon = _getIconData(reminder.type);
    final color = _getTaskColor(reminder.type);
    
    if (reminder.icon != null && reminder.icon!.isNotEmpty) {
      // If it's an emoji
      return Text(
        reminder.icon!,
        style: const TextStyle(fontSize: 32),
      );
    }
    
    return Icon(icon, color: color, size: 32);
  }

  IconData _getIconData(ReminderType type) {
    switch (type) {
      case ReminderType.water:
        return Icons.water_drop;
      case ReminderType.meal:
        return Icons.restaurant;
      case ReminderType.medication:
        return Icons.medication;
      case ReminderType.hygiene:
        return Icons.face;
      case ReminderType.homework:
        return Icons.school;
      case ReminderType.activity:
        return Icons.sports_soccer;
      default:
        return Icons.task_alt;
    }
  }

  Color _getTaskColor(ReminderType type) {
    switch (type) {
      case ReminderType.water:
        return const Color(0xFF60A5FA);
      case ReminderType.meal:
        return const Color(0xFFFB923C);
      case ReminderType.medication:
        return const Color(0xFFEC4899);
      case ReminderType.hygiene:
        return const Color(0xFF8B5CF6);
      case ReminderType.homework:
        return const Color(0xFF10B981);
      case ReminderType.activity:
        return const Color(0xFFF59E0B);
      default:
        return _primaryBlue;
    }
  }

  Widget _buildProgressFooter(double progress, int total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keep going!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(_primaryBlue),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '$_completedCount / $total',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
