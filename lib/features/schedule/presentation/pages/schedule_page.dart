import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:super_app/features/tasks/domain/entities/task_entity.dart';
import 'package:super_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:super_app/features/tasks/presentation/pages/add_task_page.dart';
import 'package:super_app/features/tasks/presentation/pages/task_detail_page.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../bloc/schedule_bloc.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/session_timeline_card.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ScheduleBloc>()..add(LoadScheduleEvent(DateTime.now())),
      child: Scaffold(
        backgroundColor: AppTheme.kBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Bagian Kalender & Navigasi Bulan
              // Hanya rebuild jika bulan/tahun berubah atau saat inisialisasi
              BlocBuilder<ScheduleBloc, ScheduleState>(
                buildWhen: (previous, current) {
                  if (previous is ScheduleLoaded && current is ScheduleLoaded) {
                    // Hanya rebuild kalender jika bulan atau tahun berubah
                    return previous.selectedDate.month !=
                            current.selectedDate.month ||
                        previous.selectedDate.year != current.selectedDate.year;
                  }
                  return true;
                },
                builder: (context, state) {
                  final selectedDate = state.selectedDate;
                  final holidays = state.holidays;

                  return SliverMainAxisGroup(
                    slivers: [
                      _buildMonthNav(context, selectedDate),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: CalendarWidget(
                            selectedDate: selectedDate,
                            holidays: holidays,
                            onDateSelected: (date) {
                              context.read<ScheduleBloc>().add(
                                LoadScheduleEvent(date),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Bagian Detail Sesi & Hari Libur
              // Rebuild setiap kali tanggal dipilih
              BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) {
                  final selectedDate = state.selectedDate;
                  final holidayName = state
                      .getHolidayForDate(selectedDate)
                      ?.name;

                  return SliverMainAxisGroup(
                    slivers: [
                      _buildSectionHeader(context, selectedDate, holidayName),
                      if (state is ScheduleLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(
                                color: AppTheme.kPrimaryColor,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      else if (state is ScheduleLoaded)
                        state.sessions.isEmpty
                            ? const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Text(
                                    'No activities planned for this day.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    return SessionTimelineCard(
                                      session: state.sessions[index],
                                      onTap: () {
                                        final session = state.sessions[index];
                                        // Navigasi ke detail jika id-nya bukan id dummy (1, 2, 3)
                                        if (session.id != '1' &&
                                            session.id != '2' &&
                                            session.id != '3') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  TaskDetailPage(
                                                    task: TaskEntity(
                                                      id: session.id,
                                                      title: session.title,
                                                      description:
                                                          session.description,
                                                      category: session.tag,
                                                      priority: TaskPriority
                                                          .medium, // Fallback
                                                      dueDate:
                                                          state.selectedDate,
                                                      time: session.time,
                                                      isCompleted:
                                                          false, // Default
                                                      subTasks: const [],
                                                    ),
                                                  ),
                                            ),
                                          ).then((refresh) {
                                            if (refresh == true &&
                                                context.mounted) {
                                              context.read<ScheduleBloc>().add(
                                                LoadScheduleEvent(
                                                  state.selectedDate,
                                                ),
                                              );
                                            }
                                          });
                                        }
                                      },
                                    );
                                  }, childCount: state.sessions.length),
                                ),
                              )
                      else if (state is ScheduleError)
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                state.message,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => sl<TaskBloc>(),
                    child: const AddTaskPage(),
                  ),
                ),
              ).then((_) {
                if (context.mounted) {
                  final state = context.read<ScheduleBloc>().state;
                  context.read<ScheduleBloc>().add(
                    LoadScheduleEvent(state.selectedDate),
                  );
                }
              });
            },
            backgroundColor: AppTheme.kPrimaryColor,
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNav(BuildContext context, DateTime selectedDate) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SCHEDULE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 32),
                ),
                Row(
                  children: [
                    _buildNavButton(context, Icons.chevron_left, () {
                      final prevMonth = DateTime(
                        selectedDate.year,
                        selectedDate.month - 1,
                        1,
                      );
                      context.read<ScheduleBloc>().add(
                        LoadScheduleEvent(prevMonth),
                      );
                    }),
                    const SizedBox(width: 12),
                    _buildNavButton(context, Icons.chevron_right, () {
                      final nextMonth = DateTime(
                        selectedDate.year,
                        selectedDate.month + 1,
                        1,
                      );
                      context.read<ScheduleBloc>().add(
                        LoadScheduleEvent(nextMonth),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    DateTime selectedDate,
    String? holidayName,
  ) {
    final now = DateTime.now();
    final isToday =
        now.year == selectedDate.year &&
        now.month == selectedDate.month &&
        now.day == selectedDate.day;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (holidayName != null) ...[
              _buildHolidayCard(context, holidayName),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday ? 'Today\'s Sessions' : 'Day\'s Sessions',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat(
                      'EEEE, MMM d',
                    ).format(selectedDate).toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.kOnSurfaceVariantColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayCard(BuildContext context, String holidayName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.redAccent.withOpacity(0.2),
            Colors.redAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HARI LIBUR NASIONAL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  holidayName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerHighColor.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, 'DASHBOARD', false),
          _buildNavItem(Icons.calendar_today, 'CALENDAR', true),
          _buildNavItem(Icons.list_alt_rounded, 'TASKS', false),
          _buildNavItem(Icons.settings_outlined, 'SETTINGS', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive
              ? AppTheme.kPrimaryColor
              : AppTheme.kOnSurfaceVariantColor,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? AppTheme.kPrimaryColor
                : AppTheme.kOnSurfaceVariantColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
