import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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

class ReminderTemplate {
  final String title;
  final String description;
  final String icon;
  final ReminderType type;
  final ReminderFrequency frequency;
  final String? time;
  final int? intervalMinutes;
  final Color color;

  const ReminderTemplate({
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.frequency,
    this.time,
    this.intervalMinutes,
    required this.color,
  });
}

class CreateReminderScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const CreateReminderScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Templates de rappels pré-configurés
  final List<ReminderTemplate> _templates = const [
    ReminderTemplate(
      title: 'Brush Teeth',
      description: '2 minutes',
      icon: '🪥',
      type: ReminderType.hygiene,
      frequency: ReminderFrequency.daily,
      time: '08:00',
      color: Color(0xFF8B5CF6),
    ),
    ReminderTemplate(
      title: 'Take Medicine',
      description: '',
      icon: '💊',
      type: ReminderType.medication,
      frequency: ReminderFrequency.daily,
      time: '09:00',
      color: Color(0xFFEC4899),
    ),
    ReminderTemplate(
      title: 'Wash Face',
      description: 'Fresh and clean!',
      icon: '😊',
      type: ReminderType.hygiene,
      frequency: ReminderFrequency.daily,
      time: '08:30',
      color: Color(0xFF60A5FA),
    ),
    ReminderTemplate(
      title: 'Get Dressed',
      description: 'Choose your favorite shirt',
      icon: '👕',
      type: ReminderType.activity,
      frequency: ReminderFrequency.daily,
      time: '08:45',
      color: Color(0xFFFB923C),
    ),
    ReminderTemplate(
      title: 'Eat Breakfast',
      description: 'Yummy time!',
      icon: '🍴',
      type: ReminderType.meal,
      frequency: ReminderFrequency.daily,
      time: '09:00',
      color: Color(0xFFFB923C),
    ),
    ReminderTemplate(
      title: 'Drink Water',
      description: '',
      icon: '💧',
      type: ReminderType.water,
      frequency: ReminderFrequency.interval,
      intervalMinutes: 120,
      color: Color(0xFF60A5FA),
    ),
    ReminderTemplate(
      title: 'Pack Bag',
      description: 'Ready for school!',
      icon: '🎒',
      type: ReminderType.activity,
      frequency: ReminderFrequency.daily,
      time: '10:00',
      color: Color(0xFF8B5CF6),
    ),
    ReminderTemplate(
      title: 'Do Homework',
      description: 'Study time',
      icon: '📚',
      type: ReminderType.homework,
      frequency: ReminderFrequency.daily,
      time: '16:00',
      color: Color(0xFF10B981),
    ),
  ];

  Future<void> _createReminderFromTemplate(ReminderTemplate template) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final remindersService = RemindersService(
        getToken: () async => authProvider.accessToken,
      );

      final reminderData = {
        'childId': widget.childId,
        'type': template.type.name,
        'title': template.title,
        'description': template.description.isNotEmpty ? template.description : null,
        'icon': template.icon,
        'color': '#${template.color.value.toRadixString(16).substring(2).toUpperCase()}',
        'frequency': template.frequency.name,
        if (template.time != null) 'time': template.time,
        if (template.intervalMinutes != null) 'intervalMinutes': template.intervalMinutes,
        'soundEnabled': true,
        'vibrationEnabled': true,
        'piSyncEnabled': template.type == ReminderType.water || template.type == ReminderType.medication,
        'daysOfWeek': [],
      };

      await remindersService.createReminder(reminderData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${template.title}" ajouté avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Retour avec succès
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primaryDark),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: _primaryDark,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Sélectionnez une tâche pour ${widget.childName}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Title
                          const Text(
                            'Tâches Quotidiennes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Templates grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _templates.length,
                            itemBuilder: (context, index) {
                              return _buildTemplateCard(_templates[index]);
                            },
                          ),
                          
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter une Tâche',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Routine quotidienne',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ReminderTemplate template) {
    return GestureDetector(
      onTap: () => _createReminderFromTemplate(template),
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: template.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  template.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                template.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Description
            if (template.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Frequency badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: template.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    template.frequency == ReminderFrequency.interval
                        ? Icons.repeat
                        : Icons.access_time,
                    size: 12,
                    color: template.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    template.time ?? '${template.intervalMinutes}min',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: template.color,
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
}
