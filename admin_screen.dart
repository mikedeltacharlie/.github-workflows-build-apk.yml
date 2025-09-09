import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitspot/models/fitness_location.dart';
import 'package:fitspot/models/review.dart';
import 'package:fitspot/data/sample_data.dart';
import 'package:fitspot/screens/location_detail_screen.dart';
import 'package:fitspot/firestore/firebase_provider.dart';
import 'package:fitspot/firestore/data_migration.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<FitnessLocation> _pendingLocations = [];
  List<Review> _pendingReviews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPendingData() async {
    try {
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      
      // Carica location suggestions (luoghi non validati)
      firebaseProvider.firestoreService.getLocationSuggestions(status: 'pending').listen((locationSuggestions) {
        setState(() {
          _pendingLocations = locationSuggestions.map((suggestion) => FitnessLocation(
            id: suggestion.id,
            name: suggestion.name,
            description: suggestion.description,
            address: suggestion.address,
            latitude: suggestion.latitude,
            longitude: suggestion.longitude,
            equipmentTypes: suggestion.equipment,
            images: suggestion.imageUrls,
            status: LocationStatus.values.firstWhere(
              (e) => e.name == suggestion.equipmentStatus,
              orElse: () => LocationStatus.pending,
            ),
            isValidated: false,
            validatedBy: null,
            validatedAt: null,
            reviews: [],
            rating: 0.0,
            createdAt: suggestion.createdAt,
            updatedAt: suggestion.updatedAt,
            createdBy: suggestion.submittedBy,
          )).toList();
        });
      });
      
      // Carica recensioni non moderate
      firebaseProvider.firestoreService.getUnmoderatedReviews().listen((reviewDocs) {
        setState(() {
          _pendingReviews = reviewDocs.map((reviewDoc) => Review(
            id: reviewDoc.id,
            locationId: reviewDoc.locationId,
            userId: reviewDoc.userId,
            userName: reviewDoc.userName,
            rating: reviewDoc.rating,
            comment: reviewDoc.comment,
            equipmentReviewed: reviewDoc.equipmentReviews.keys.toList(),
            overallCondition: EquipmentCondition.good,
            locationCondition: _parseLocationCondition(reviewDoc.locationStatus),
            createdAt: reviewDoc.createdAt,
            isModerated: reviewDoc.isModerated,
            imageUrls: reviewDoc.imageUrls,
          )).toList();
        });
      });
    } catch (e) {
      // Fallback ai dati di esempio
      setState(() {
        _pendingLocations = SampleData.sampleLocations
            .where((location) => !location.isValidated)
            .toList();
        _pendingReviews = SampleData.sampleReviews
            .where((review) => !review.isModerated)
            .toList();
      });
    }
  }

  LocationCondition _parseLocationCondition(String? status) {
    if (status == null) return LocationCondition.good;
    switch (status) {
      case 'excellent':
        return LocationCondition.excellent;
      case 'good':
        return LocationCondition.good;
      case 'needsMaintenance':
        return LocationCondition.needsMaintenance;
      case 'poor':
        return LocationCondition.poor;
      case 'closed':
        return LocationCondition.closed;
      default:
        return LocationCondition.good;
    }
  }

  Future<void> _migrateSampleData() async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Migrazione dati in corso...')),
      );
      
      final dataMigration = DataMigration();
      await dataMigration.migrateSampleData();
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Migrazione dati completata!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore migrazione: $e')),
      );
    }
  }

  Future<void> _approveLocation(FitnessLocation location) async {
    try {
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      await firebaseProvider.firestoreService.approveLocationSuggestion(location.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${location.name} approvato con successo'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore approvazione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectLocation(FitnessLocation location) async {
    final String? reason = await _showRejectDialog('Perché vuoi rifiutare questo luogo?');
    if (reason == null || reason.isEmpty) return;

    try {
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      await firebaseProvider.firestoreService.rejectLocationSuggestion(location.id, reason);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${location.name} rifiutato'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore rifiuto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveReview(Review review) async {
    try {
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      await firebaseProvider.firestoreService.moderateReview(review.id, true, null);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recensione approvata'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore approvazione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectReview(Review review) async {
    final String? reason = await _showRejectDialog('Perché vuoi rifiutare questa recensione?');
    if (reason == null || reason.isEmpty) return;

    try {
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      await firebaseProvider.firestoreService.moderateReview(review.id, false, reason);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recensione rifiutata'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore rifiuto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showRejectDialog(String title) async {
    final TextEditingController controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Inserisci il motivo del rifiuto...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pannello Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Luoghi',
              icon: Badge(
                label: Text(_pendingLocations.length.toString()),
                child: const Icon(Icons.place),
              ),
            ),
            Tab(
              text: 'Recensioni',
              icon: Badge(
                label: Text(_pendingReviews.length.toString()),
                child: const Icon(Icons.rate_review),
              ),
            ),
            const Tab(
              text: 'Statistiche',
              icon: Icon(Icons.analytics),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLocationManagement(),
          _buildReviewModeration(),
          _buildStatistics(),
        ],
      ),
      floatingActionButton: Consumer<FirebaseProvider>(
        builder: (context, firebaseProvider, child) {
          if (!firebaseProvider.isAdmin) return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: _migrateSampleData,
            label: const Text('Migra Dati'),
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Migra dati di esempio in Firebase',
          );
        },
      ),
    );
  }

  Widget _buildLocationManagement() {
    if (_pendingLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun luogo in attesa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tutti i luoghi sono stati validati',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingLocations.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final location = _pendingLocations[index];
        return _PendingLocationCard(
          location: location,
          onApprove: () => _approveLocation(location),
          onReject: () => _rejectLocation(location),
          onView: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationDetailScreen(location: location),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewModeration() {
    if (_pendingReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna recensione in attesa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tutte le recensioni sono state moderate',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingReviews.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final review = _pendingReviews[index];
        return _PendingReviewCard(
          review: review,
          onApprove: () => _approveReview(review),
          onReject: () => _rejectReview(review),
        );
      },
    );
  }

  Widget _buildStatistics() {
    final allLocations = SampleData.sampleLocations;
    final validatedLocations = allLocations.where((l) => l.isValidated).length;
    final totalReviews = SampleData.sampleReviews.length;
    final averageRating = SampleData.sampleLocations
        .where((l) => l.averageRating > 0)
        .fold<double>(0, (sum, l) => sum + l.averageRating) / 
        SampleData.sampleLocations.where((l) => l.averageRating > 0).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(
          title: 'Panoramica Luoghi',
          children: [
            _StatItem(label: 'Luoghi totali', value: allLocations.length.toString()),
            _StatItem(label: 'Luoghi validati', value: validatedLocations.toString()),
            _StatItem(label: 'In attesa di validazione', value: _pendingLocations.length.toString()),
            _StatItem(label: 'Rating medio', value: averageRating.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'Attività Recensioni',
          children: [
            _StatItem(label: 'Recensioni totali', value: totalReviews.toString()),
            _StatItem(label: 'In attesa di moderazione', value: _pendingReviews.length.toString()),
          ],
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'Stato Luoghi',
          children: LocationStatus.values.map((status) {
            final count = allLocations.where((l) => l.status == status).length;
            return _StatItem(
              label: status.displayName,
              value: count.toString(),
            );
          }).toList(),
        ),
      ],
    );
  }


}

class _PendingLocationCard extends StatelessWidget {
  final FitnessLocation location;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onView;

  const _PendingLocationCard({
    required this.location,
    required this.onApprove,
    required this.onReject,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'In attesa',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              location.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              'Aggiunto da: ${location.addedBy}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onView,
                    child: const Text('Visualizza'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                    child: const Text('Rifiuta'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Approva'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingReviewCard({
    required this.review,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    review.userName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Da moderare',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                    child: const Text('Rifiuta'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Approva'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _StatCard({
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