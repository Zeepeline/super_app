import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/tasks/domain/entities/task_entity.dart';
import 'package:super_app/features/tasks/presentation/bloc/task_bloc.dart';

import '../../../../injection_container.dart';
import 'add_task_page.dart';

class TaskDetailPage extends StatelessWidget {
  final TaskEntity task;

  const TaskDetailPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TaskBloc>(),
      child: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task status updated!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(
              context,
              true,
            ); // Return true to indicate refresh needed
          } else if (state is TaskDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task deleted!'),
                backgroundColor: Colors.redAccent,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0E0E0E),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildSectionLabel('Description'),
                      const SizedBox(height: 12),
                      _buildDescription(),
                      const SizedBox(height: 32),
                      _buildMetaGrid(),
                      const SizedBox(height: 32),
                      if (task.subTasks.isNotEmpty) ...[
                        _buildSectionLabel('Sub-tasks'),
                        const SizedBox(height: 16),
                        _buildSubTaskList(),
                      ],
                      const SizedBox(height: 40),
                      _buildActionButtons(context),
                      const SizedBox(height: 40),
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
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0E0E0E),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1516280440614-37939bbacd81?q=80&w=1000&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0E0E0E).withOpacity(0.8),
                    const Color(0xFF0E0E0E),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTaskPage(task: task)),
            );
            if (result == true && context.mounted) {
              Navigator.pop(context, true);
            }
          },
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getPriorityColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getPriorityColor().withOpacity(0.3)),
          ),
          child: Text(
            task.priority.toString().split('.').last.toUpperCase(),
            style: GoogleFonts.inter(
              color: _getPriorityColor(),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          task.title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        color: AppTheme.kPrimaryColor.withOpacity(0.8),
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      task.description.isEmpty ? 'No description provided.' : task.description,
      style: GoogleFonts.inter(
        color: Colors.white.withOpacity(0.7),
        fontSize: 15,
        height: 1.6,
      ),
    );
  }

  Widget _buildMetaGrid() {
    String timeDisplay = task.time;
    if (task.endTime != null) {
      timeDisplay = "${task.time} - ${task.endTime}";
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildMetaItem(Icons.category_outlined, 'Category', task.category),
        _buildMetaItem(
          Icons.calendar_today_outlined,
          'Due Date',
          DateFormat('MMM dd, yyyy').format(task.dueDate),
        ),
        _buildMetaItem(Icons.access_time_outlined, 'Schedule', timeDisplay),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Container(
      width: (SizedBox.fromSize()
          .width), // This is a placeholder, Wrap handles width
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.kPrimaryColor, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTaskList() {
    return Column(
      children: task.subTasks.map((subTask) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.radio_button_unchecked,
                color: AppTheme.kPrimaryColor.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  subTask,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final isLoading = state is TaskLoading;

        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isLoading || task.isCompleted
                    ? null
                    : () {
                        context.read<TaskBloc>().add(
                          UpdateTaskStatusEvent(task: task, isCompleted: true),
                        );
                      },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? Colors.green.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: task.isCompleted
                          ? Colors.green.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            task.isCompleted ? 'COMPLETED' : 'MARK COMPLETED',
                            style: GoogleFonts.plusJakartaSans(
                              color: task.isCompleted
                                  ? Colors.green
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppTheme.kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.black,
                size: 32,
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return const Color(0xFFFF5722);
      case TaskPriority.medium:
        return const Color(0xFF72FE8F);
      case TaskPriority.low:
        return const Color(0xFFADAAAA);
    }
  }
}
