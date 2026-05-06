import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_bloc.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _subTaskController = TextEditingController();

  String _selectedCategory = 'Work';
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<String> _subTasks = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Work', 'icon': Icons.work_outline},
    {'name': 'Personal', 'icon': Icons.person_outline},
    {'name': 'Fitness', 'icon': Icons.fitness_center_outlined},
    {'name': 'Reading', 'icon': Icons.menu_book_outlined},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  void _submitTask() {
    if (_titleController.text.isEmpty) return;

    final timeStr =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

    context.read<TaskBloc>().add(
      AddTaskEvent(
        title: _titleController.text,
        description: _descController.text,
        category: _selectedCategory,
        priority: _selectedPriority,
        dueDate: _selectedDate,
        time: timeStr,
        subTasks: _subTasks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task synchronized successfully')),
          );
        } else if (state is TaskError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildLabel('Task Identity'),
                      const SizedBox(height: 12),
                      _buildTitleInput(),
                      const SizedBox(height: 32),
                      _buildLabel('Description'),
                      const SizedBox(height: 12),
                      _buildDescriptionInput(),
                      const SizedBox(height: 32),

                      _buildCategorySection(),
                      const SizedBox(height: 24),

                      _buildPrioritySection(),
                      const SizedBox(height: 24),
                      _buildScheduleSection(),

                      const SizedBox(height: 24),
                      _buildSubTasksSection(),

                      const SizedBox(height: 32),
                      _buildHeroAsset(),

                      const SizedBox(height: 32),
                      _buildFooterAction(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'NEW TASK',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        color: AppTheme.kPrimaryColor.withValues(alpha: 0.8),
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTitleInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _titleController,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Enter task name...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _descController,
        maxLines: 4,
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Add more details about this task...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131313).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmallLabel(Icons.category, 'Category'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['name']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.kPrimaryColor.withValues(alpha: 0.1)
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.kPrimaryColor.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'],
                        size: 16,
                        color: isSelected
                            ? AppTheme.kPrimaryColor
                            : Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat['name'],
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? AppTheme.kPrimaryColor
                              : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131313).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmallLabel(Icons.priority_high, 'Priority'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                _buildPriorityButton('LOW', TaskPriority.low),
                _buildPriorityButton('MED', TaskPriority.medium),
                _buildPriorityButton('HIGH', TaskPriority.high),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityButton(String label, TaskPriority priority) {
    final isSelected = _selectedPriority == priority;
    Color textColor = Colors.white54;
    if (isSelected) {
      textColor = Colors.white;
    } else if (priority == TaskPriority.high) {
      textColor = Colors.redAccent.withValues(alpha: 0.5);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF262626) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131313).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSmallLabel(Icons.alarm, 'Configuration'),
                  const SizedBox(height: 4),
                  Text(
                    'Time & Reminders',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Switch(
                value: true,
                onChanged: (_) {},
                activeThumbColor: AppTheme.kPrimaryColor,
                activeTrackColor: AppTheme.kPrimaryColor.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildScheduleTile(
                  Icons.calendar_today,
                  'Date',
                  DateFormat('EEEE, MMM d').format(_selectedDate),
                  () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScheduleTile(
                  Icons.schedule,
                  'Time',
                  _selectedTime.format(context),
                  () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) setState(() => _selectedTime = time);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.kPrimaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more,
              color: Colors.white.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTasksSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131313).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmallLabel(Icons.checklist, 'Sub-tasks'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add a sub-task...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addSubTask(),
                  ),
                ),
                IconButton(
                  onPressed: _addSubTask,
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppTheme.kPrimaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._subTasks
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          task,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  void _addSubTask() {
    if (_subTaskController.text.isNotEmpty) {
      setState(() {
        _subTasks.add(_subTaskController.text);
        _subTaskController.clear();
      });
    }
  }

  Widget _buildSmallLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.kPrimaryColor.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: GoogleFonts.inter(
            color: AppTheme.kPrimaryColor.withValues(alpha: 0.8),
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroAsset() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?q=80&w=1000&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.kPrimaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppTheme.kPrimaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Focus Mode Active',
                style: GoogleFonts.inter(
                  color: AppTheme.kPrimaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final isLoading = state is TaskLoading;

        return Column(
          children: [
            GestureDetector(
              onTap: isLoading ? null : _submitTask,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.kPrimaryColor, Color(0xFF1CB853)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kPrimaryColor.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.sync_alt,
                              color: Colors.black,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'SYNCHRONIZE TASK',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This task will be curated into your global sonic workflow.',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
