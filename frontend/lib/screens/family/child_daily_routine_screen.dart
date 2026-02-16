import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/task_reminder.dart';
import '../../services/reminders_service.dart';
import '../../providers/auth_provider.dart';

// Couleurs alignées avec le dashboard famille
const Color _primary = Color(0xFFA3D9E5);
const Color _primaryDark = Color(0xFF7BBCCB);
const Color _backgroundColor = Color(0xFFF8FAFC);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate600 = Color(0xFF475569);
const Color _slate500 = Color(0xFF64748B);
const Color _slate400 = Color(0xFF94A3B8);
const Color _slate300 = Color(0xFFCBD5E1);

class ChildDailyRoutineScreen extends StatefulWidget {
  final String childId;

  const ChildDailyRoutineScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ChildDailyRoutineScreen> createState() => _ChildDailyRoutineScreenState();
}

class _ChildDailyRoutineScreenState extends State<ChildDailyRoutineScreen> {
  bool _isLoading = true;
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

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final remindersService = RemindersService(
        getToken: () async => authProvider.accessToken,
      );

      final reminders = await remindersService.getTodayReminders(widget.childId);
      final completed = reminders.where((r) => r.completedToday == true).length;

      if (mounted) {
        setState(() {
          _reminders = reminders;
          _completedCount = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading reminders: $e');
      if (mounted) {
        setState(() {
          _reminders = [];
          _completedCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTaskCompletion(TaskReminder reminder) async {
    final newStatus = !(reminder.completedToday ?? false);
    
    // Si c'est un médicament et qu'on veut le marquer comme complété, ouvrir l'écran de vérification
    if (reminder.type == ReminderType.medication && newStatus) {
      final result = await context.push(
        '/family/medicine-verification',
        extra: {
          'reminderId': reminder.id,
          'taskTitle': reminder.title,
          'taskDescription': reminder.description,
        },
      );
      
      // Si la vérification a réussi, recharger les reminders
      if (result == true && mounted) {
        _loadReminders();
      }
      return;
    }
    
    // Pour les autres tâches, complétion normale
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final remindersService = RemindersService(
        getToken: () async => authProvider.accessToken,
      );
      
      await remindersService.completeTask(
        reminderId: reminder.id,
        completed: newStatus,
        date: DateTime.now(),
      );

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

        if (newStatus) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getEncouragementMessage(reminder.type)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getEncouragementMessage(ReminderType type) {
    switch (type) {
      case ReminderType.water:
        return 'Great job staying hydrated!';
      case ReminderType.meal:
        return 'Well done! You had a healthy meal!';
      case ReminderType.medication:
        return 'Perfect! You took your medicine!';
      case ReminderType.hygiene:
        return 'Awesome! You\'re so clean!';
      case ReminderType.homework:
        return 'Amazing work! You completed your task!';
      default:
        return 'Well done! Keep it up!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = _reminders.length;
    final progress = totalTasks > 0 ? _completedCount / totalTasks : 0.0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primaryDark))
            : Column(
                children: [
                  // Custom Header
                  _buildHeader(),
                  const SizedBox(height: 20),
                  
                  // Task List or Empty State
                  Expanded(
                    child: _reminders.isEmpty
                        ? _buildEmptyState()
                        : _buildTaskList(),
                  ),
                  
                  // Progress Footer
                  if (_reminders.isNotEmpty) ...[
                    _buildProgressFooter(progress, totalTasks),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push(
            '/family/create-reminder',
            extra: {
              'childId': widget.childId,
              'childName': 'Enfant',
            },
          );
          
          // Si un rappel a été ajouté, recharger la liste
          if (result == true && mounted) {
            _loadReminders();
          }
        },
        backgroundColor: _primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ajouter une tâche',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 4,
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
          const SizedBox(width: 16),
          
          // Title
          const Expanded(
            child: Text(
              'Child Daily Visual Routine',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Settings Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.black87),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Parametres bientot disponibles')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '📅',
                  style: const TextStyle(fontSize: 60),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Aucune tâche pour aujourd\'hui',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Commencez par créer des rappels pour votre enfant. Cliquez sur le bouton ci-dessous pour ajouter des tâches quotidiennes.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final result = await context.push(
                  '/family/create-reminder',
                  extra: {
                    'childId': widget.childId,
                    'childName': 'Enfant',
                  },
                );
                
                if (result == true && mounted) {
                  _loadReminders();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ajouter des tâches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(_reminders[index]);
      },
    );
  }

  Widget _buildTaskCard(TaskReminder reminder) {
    final isCompleted = reminder.completedToday ?? false;
    
    return GestureDetector(
      onTap: () {
        // Navigate to notification screen
        context.push(
          '/family/reminder-notification',
          extra: {
            'taskTitle': reminder.title,
            'taskDescription': reminder.description,
            'icon': _getEmojiForType(reminder.type),
            'time': reminder.time,
            'reminderId': reminder.id,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getTaskColor(reminder.type).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _getEmojiForType(reminder.type),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            
            // Task Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (reminder.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      reminder.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (reminder.piSyncEnabled) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.router, size: 11, color: _primaryDark),
                        const SizedBox(width: 4),
                        Text(
                          'PI SYNC',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _primaryDark,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? _primaryDark : Colors.grey.shade300,
                    width: 2.5,
                  ),
                  color: isCompleted ? _primaryDark : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressFooter(double progress, int total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep going!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                  ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: _slate300,
                    valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$_completedCount / $total',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmojiForType(ReminderType type) {
    switch (type) {
      case ReminderType.water:
        return '💧';
      case ReminderType.meal:
        return '🍴';
      case ReminderType.medication:
        return '💊';
      case ReminderType.homework:
        return '🎓';
      case ReminderType.hygiene:
        return '😊';
      case ReminderType.activity:
        return '⚽';
      default:
        return '✅';
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
        return _primaryDark;
    }
  }
}
