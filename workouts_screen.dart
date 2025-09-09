import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fitspot/models/workout.dart';
import 'package:fitspot/data/sample_data.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Workout> _workouts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWorkouts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadWorkouts() {
    setState(() {
      _workouts = [];
    });
  }

  List<Workout> get _completedWorkouts => _workouts.where((w) => w.endTime != null).toList();
  List<Workout> get _activeWorkouts => _workouts.where((w) => w.endTime == null).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allenamenti'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cronologia'),
            Tab(text: 'Statistiche'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWorkoutDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkoutHistory(),
          _buildWorkoutStats(),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistory() {
    if (_workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun allenamento in cronologia',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Inizia il tuo primo allenamento!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_activeWorkouts.isNotEmpty) ...[
          Text(
            'Allenamenti Attivi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._activeWorkouts.map((workout) => _ActiveWorkoutCard(
                workout: workout,
                onStop: () => _stopWorkout(workout),
              )),
          const SizedBox(height: 24),
        ],
        Text(
          'Cronologia',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._completedWorkouts.map((workout) => _WorkoutCard(workout: workout)),
      ],
    );
  }

  Widget _buildWorkoutStats() {
    if (_completedWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna statistica disponibile',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Completa alcuni allenamenti per vedere le tue statistiche',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final totalWorkouts = _completedWorkouts.length;
    final totalTime = _completedWorkouts.fold<Duration>(
      Duration.zero,
      (sum, workout) => sum + workout.duration,
    );
    final totalCalories = _completedWorkouts.fold<int>(
      0,
      (sum, workout) => sum + workout.caloriesBurned,
    );
    final averageDuration = totalTime.inMinutes ~/ totalWorkouts;
    
    final workoutsByType = <WorkoutType, int>{};
    for (final workout in _completedWorkouts) {
      workoutsByType[workout.type] = (workoutsByType[workout.type] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsCard(
          title: 'Panoramica',
          children: [
            _StatItem(label: 'Allenamenti totali', value: totalWorkouts.toString()),
            _StatItem(label: 'Tempo totale', value: '${totalTime.inHours}h ${totalTime.inMinutes % 60}m'),
            _StatItem(label: 'Calorie bruciate', value: '$totalCalories kcal'),
            _StatItem(label: 'Durata media', value: '${averageDuration}m'),
          ],
        ),
        const SizedBox(height: 16),
        _StatsCard(
          title: 'Per Tipologia',
          children: workoutsByType.entries.map((entry) {
            return _StatItem(
              label: entry.key.displayName,
              value: entry.value.toString(),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAddWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuovo Allenamento'),
        content: const Text('Vuoi iniziare un nuovo allenamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewWorkout();
            },
            child: const Text('Inizia'),
          ),
        ],
      ),
    );
  }

  void _startNewWorkout() {
    final newWorkout = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'user123',
      title: 'Nuovo Allenamento',
      description: 'Allenamento in corso...',
      type: WorkoutType.general,
      duration: Duration.zero,
      startTime: DateTime.now(),
    );

    setState(() {
      _workouts.add(newWorkout);
    });
  }

  void _stopWorkout(Workout workout) {
    final duration = DateTime.now().difference(workout.startTime);
    final updatedWorkout = Workout(
      id: workout.id,
      userId: workout.userId,
      locationId: workout.locationId,
      locationName: workout.locationName,
      title: workout.title,
      description: 'Allenamento completato',
      type: workout.type,
      duration: duration,
      startTime: workout.startTime,
      endTime: DateTime.now(),
      exercises: const ['Allenamento libero'],
      notes: 'Allenamento completato con successo',
      caloriesBurned: (duration.inMinutes * 5), // Stima approssimativa
      distanceKm: workout.distanceKm,
    );

    setState(() {
      final index = _workouts.indexWhere((w) => w.id == workout.id);
      if (index != -1) {
        _workouts[index] = updatedWorkout;
      }
    });
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;

  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getWorkoutIcon(workout.type),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workout.startTime.day}/${workout.startTime.month}/${workout.startTime.year}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(workout.type.displayName),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (workout.locationName != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workout.locationName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                _WorkoutStat(
                  icon: Icons.timer,
                  label: 'Durata',
                  value: '${workout.duration.inMinutes}min',
                ),
                const SizedBox(width: 16),
                _WorkoutStat(
                  icon: Icons.local_fire_department,
                  label: 'Calorie',
                  value: '${workout.caloriesBurned}',
                ),
                if (workout.distanceKm != null) ...[
                  const SizedBox(width: 16),
                  _WorkoutStat(
                    icon: Icons.straighten,
                    label: 'Distanza',
                    value: '${workout.distanceKm!.toStringAsFixed(1)}km',
                  ),
                ],
              ],
            ),
            if (workout.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                workout.notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getWorkoutIcon(WorkoutType type) {
    switch (type) {
      case WorkoutType.cardio:
        return Icons.favorite;
      case WorkoutType.strength:
        return Icons.fitness_center;
      case WorkoutType.flexibility:
        return Icons.self_improvement;
      case WorkoutType.sports:
        return Icons.sports_soccer;
      case WorkoutType.calisthenics:
        return Icons.accessibility_new;
      case WorkoutType.running:
        return Icons.directions_run;
      case WorkoutType.cycling:
        return Icons.directions_bike;
      case WorkoutType.general:
        return Icons.sports_gymnastics;
    }
  }
}

class _ActiveWorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onStop;

  const _ActiveWorkoutCard({
    required this.workout,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ALLENAMENTO IN CORSO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              workout.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (i) => DateTime.now()),
              builder: (context, snapshot) {
                final elapsed = DateTime.now().difference(workout.startTime);
                final hours = elapsed.inHours;
                final minutes = elapsed.inMinutes % 60;
                final seconds = elapsed.inSeconds % 60;
                
                return Text(
                  '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WorkoutStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _StatsCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}