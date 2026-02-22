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

  // État pour la tâche en cours de configuration
  String _customTitle = '';
  String _customIcon = '📝';
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

  Future<void> _showConfigDialog(ReminderTemplate template,
      {bool isCustom = false}) async {
    _customTitle = isCustom ? '' : template.title;
    _customIcon = isCustom ? '📝' : template.icon;
    _selectedTimes = template.time != null
        ? [
            TimeOfDay(
                hour: int.parse(template.time!.split(':')[0]),
                minute: int.parse(template.time!.split(':')[1]))
          ]
        : [TimeOfDay.now()];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 32,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isCustom ? 'Nouvelle Tâche' : 'Configurer ${template.title}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                if (isCustom) ...[
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Nom de la tâche',
                      prefixIcon: const Icon(Icons.edit_note),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onChanged: (val) => _customTitle = val,
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Horaires de notification',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ..._selectedTimes.asMap().entries.map((entry) => Chip(
                          label: Text(entry.value.format(context)),
                          onDeleted: () {
                            setModalState(() {
                              _selectedTimes.removeAt(entry.key);
                            });
                          },
                          deleteIcon: const Icon(Icons.close, size: 16),
                          backgroundColor: _primary.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter'),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setModalState(() {
                            _selectedTimes.add(time);
                          });
                        }
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedTimes.isEmpty
                        ? null
                        : () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Confirmer et Créer',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      _saveReminder(template, isCustom);
    }
  }

  Future<void> _saveReminder(ReminderTemplate template, bool isCustom) async {
    if (isCustom && _customTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez donner un nom à la tâche')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final remindersService = RemindersService(
        getToken: () async => authProvider.accessToken,
      );

      final List<String> timesStr = _selectedTimes.map((t) {
        final hour = t.hour.toString().padLeft(2, '0');
        final minute = t.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }).toList();

      final reminderData = {
        'childId': widget.childId,
        'type': isCustom ? 'custom' : template.type.name,
        'title': isCustom ? _customTitle : template.title,
        'description': isCustom
            ? null
            : (template.description.isNotEmpty ? template.description : null),
        'icon': isCustom ? _customIcon : template.icon,
        'color':
            '#${template.color.value.toRadixString(16).substring(2).toUpperCase()}',
        'frequency': template.frequency.name,
        'times': timesStr,
        'soundEnabled': true,
        'vibrationEnabled': true,
        'daysOfWeek': [],
      };

      await remindersService.createReminder(reminderData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ "${isCustom ? _customTitle : template.title}" ajouté !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
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
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                            children: [
                              // Bouton Tâche Personnalisée
                              _buildCustomTaskCard(),
                              ..._templates.map((t) => _buildTemplateCard(t)),
                            ],
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

  Widget _buildCustomTaskCard() {
    return _buildTemplateCard(
      const ReminderTemplate(
        title: 'Tâche Personnalisée',
        description: 'Libre choix',
        icon: '📝',
        type: ReminderType.custom,
        frequency: ReminderFrequency.daily,
        color: _primaryDark,
      ),
      isCustom: true,
    );
  }

  Widget _buildTemplateCard(ReminderTemplate template,
      {bool isCustom = false}) {
    return GestureDetector(
      onTap: () => _showConfigDialog(template, isCustom: isCustom),
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
