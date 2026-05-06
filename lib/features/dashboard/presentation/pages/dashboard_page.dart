import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/features/dashboard/presentation/widgets/bottom_cards.dart';
import 'package:super_app/features/dashboard/presentation/widgets/status_card.dart';
import 'package:super_app/features/dashboard/presentation/widgets/task_card.dart';
import 'package:super_app/features/schedule/presentation/pages/schedule_page.dart';
import 'package:super_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:super_app/features/tasks/presentation/pages/add_task_page.dart';

import '../../../../injection_container.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardInitial) {
              context.read<DashboardBloc>().add(LoadDashboardDataEvent());
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF72FE8F)),
              );
            }
            if (state is DashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF72FE8F)),
              );
            }
            if (state is DashboardError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            if (state is DashboardLoaded) {
              final data = state.dashboardData;
              return CustomScrollView(
                slivers: [
                  _buildDailyStatus(data.dailyStatus, context),
                  _buildActiveTasks(data.activeTasks, context),
                  _buildInsights(data.trend, data.insightMessage),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildDailyStatus(List<dynamic> status, BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Status',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF72FE8F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF72FE8F).withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'OPTIMAL',
                    style: TextStyle(
                      color: Color(0xFF72FE8F),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: status.length,
              itemBuilder: (context, index) {
                final item = status[index];
                return DashboardStatusCard(
                  title: item.title,
                  value: item.value,
                  type: item.type,
                  progress: item.progress,
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActiveTasks(List<dynamic> tasks, BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Tasks',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 20),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SchedulePage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF72FE8F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Color(0xFF72FE8F),
                          size: 8,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selengkapnya',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFF72FE8F),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tasks.map(
              (task) => DashboardTaskCard(
                title: task.title,
                priority: task.priority,
                estimatedTime: task.estimatedTime,
                isCompleted: task.isCompleted,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights(dynamic trend, String message) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 180,
                child: TrendCard(
                  growth: trend.growth,
                  dataPoints: trend.dataPoints,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 180,
                child: InsightCard(message: message),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => sl<TaskBloc>(),
              child: const AddTaskPage(),
            ),
          ),
        );
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF72FE8F), Color(0xFF1CB853)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF72FE8F).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }
}
