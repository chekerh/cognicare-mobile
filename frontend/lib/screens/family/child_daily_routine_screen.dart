import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/task_reminder.dart';
import '../../services/reminders_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';

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
        // Filtrage intelligent des doublons "hérités"
        // Si on a deux tâches avec le même nom, et que l'une a des horaires mais pas l'autre,
        // on privilégie celle avec les horaires.
        final filteredReminders = <TaskReminder>[];
        final Map<String, TaskReminder> nameMap = {};

        for (final r in reminders) {
          final key = r.title.trim().toLowerCase();
          if (!nameMap.containsKey(key)) {
            nameMap[key] = r;
            filteredReminders.add(r);
          } else {
            // Si on a déjà vu ce nom, on remplace si le nouveau a des horaires et l'ancien non
            final existing = nameMap[key]!;
            if (r.times.isNotEmpty && existing.times.isEmpty) {
              final idx = filteredReminders.indexOf(existing);
              filteredReminders[idx] = r;
              nameMap[key] = r;
            }
            // Sinon on ignore le doublon
          }
        }

        setState(() {
          _reminders = filteredReminders;
          _completedCount = filteredReminders.where((r) => r.completedToday == true).length;
          _isLoading = false;
        });
        
        // Synchroniser les notifications locales
        NotificationService().syncNotifications(filteredReminders);
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
              // On réinitialise le statut de vérification si on dé-complète
              verificationStatus: newStatus ? reminder.verificationStatus : null,
              verificationMetadata: newStatus ? reminder.verificationMetadata : null,
            );
            
            if (newStatus) {
              _completedCount++;
            } else {
              if (_completedCount > 0) _completedCount--;
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

  Future<void> _deleteReminder(TaskReminder reminder) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final remindersService = RemindersService(
        getToken: () async => authProvider.accessToken,
      );
      
      await remindersService.deleteReminder(reminder.id);
      
      if (mounted) {
        setState(() {
          _reminders.removeWhere((r) => r.id == reminder.id);
          _completedCount = _reminders.where((r) => r.completedToday == true).length;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${reminder.title}" supprimé'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression : $e'),
            backgroundColor: Colors.red,
          ),
        );
        _loadReminders();
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
          
          // Add Task Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _primaryDark.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: _primaryDark, size: 28),
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
        final reminder = _reminders[index];
        return Dismissible(
          key: ValueKey('reminder_${reminder.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Confirmer la suppression"),
                  content: Text("Voulez-vous vraiment supprimer le rappel \"${reminder.title}\" ?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("ANNULER"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            _deleteReminder(reminder);
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
          ),
          child: _buildTaskCard(reminder),
        );
      },
    );
  }

  Widget _buildTaskCard(TaskReminder reminder) {
    final isCompleted = reminder.completedToday ?? false;
    
    return GestureDetector(
      onTap: () {
        // Suppression de la navigation vers l'écran de notification inutile
        // On peut éventuellement ajouter ici une boîte de dialogue de détails
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
                  Row(
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (reminder.type == ReminderType.medication && isCompleted && reminder.verificationStatus != 'VALID')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Vérification...',
                            style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  if (reminder.description != null && reminder.description!.isNotEmpty) ...[
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
                  const SizedBox(height: 6),
                  if (reminder.times.isNotEmpty) 
                    Wrap(
                      spacing: 4,
                      children: reminder.times.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _primaryDark),
                        ),
                      )).toList(),
                    )
                  else
                    const Text(
                      'Horaire non spécifié',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.orange),
                    ),
                ],
              ),
            ),
            
            // Checkbox logic: Medication must be VALID to show tick
            GestureDetector(
              onTap: () => _toggleTaskCompletion(reminder),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (reminder.type == ReminderType.medication)
                        ? (reminder.verificationStatus == 'VALID' ? _primaryDark : Colors.grey.shade200)
                        : (isCompleted ? _primaryDark : Colors.grey.shade200),
                    width: 2.5,
                  ),
                  color: (reminder.type == ReminderType.medication)
                      ? (reminder.verificationStatus == 'VALID' ? _primaryDark : Colors.transparent)
                      : (isCompleted ? _primaryDark : Colors.transparent),
                ),
                child: ((reminder.type == ReminderType.medication && reminder.verificationStatus == 'VALID') || 
                       (reminder.type != ReminderType.medication && isCompleted))
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : (reminder.type == ReminderType.medication && isCompleted && reminder.verificationStatus != 'VALID')
                        ? const Icon(Icons.hourglass_bottom, color: Colors.orange, size: 18) // Waiting for AI
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
