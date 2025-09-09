import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitspot/models/fitness_location.dart';
import 'package:fitspot/models/review.dart';
import 'package:fitspot/data/sample_data.dart';
import 'package:fitspot/firestore/firebase_provider.dart';
import 'package:fitspot/firestore/firestore_data_schema.dart';
import 'package:fitspot/widgets/image_picker_dialog.dart';
import 'package:fitspot/services/image_upload_service.dart';
import 'package:fitspot/services/favorites_service.dart';

class LocationDetailScreen extends StatefulWidget {
  final FitnessLocation location;

  const LocationDetailScreen({
    super.key,
    required this.location,
  });

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  List<Review> _reviews = [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final isFavorite = await FavoritesService.isFavorite(widget.location.id);
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.toggleFavorite(widget.location.id);
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite 
            ? 'Aggiunto ai preferiti' 
            : 'Rimosso dai preferiti'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _loadReviews() {
    try {
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      firebaseProvider.firestoreService.getReviewsForLocation(widget.location.id).listen((reviewDocs) {
        setState(() {
          _reviews = reviewDocs.map((reviewDoc) => Review(
            id: reviewDoc.id,
            locationId: reviewDoc.locationId,
            userId: reviewDoc.userId,
            userName: reviewDoc.userName,
            rating: reviewDoc.rating,
            comment: reviewDoc.comment,
            equipmentReviewed: reviewDoc.equipmentReviews.keys.toList(),
            overallCondition: EquipmentCondition.good, // Default from getter
            locationCondition: _parseLocationCondition(reviewDoc.locationStatus),
            createdAt: reviewDoc.createdAt,
            isModerated: reviewDoc.isModerated,
            imageUrls: reviewDoc.imageUrls,
          )).toList();
        });
      });
    } catch (e) {
      // Fallback ai dati di esempio in caso di errore
      setState(() {
        _reviews = SampleData.sampleReviews.where((r) => r.locationId == widget.location.id).toList();
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

  Color _getLocationConditionColor(LocationCondition condition) {
    switch (condition) {
      case LocationCondition.excellent:
        return Colors.green;
      case LocationCondition.good:
        return Colors.lightGreen;
      case LocationCondition.needsMaintenance:
        return Colors.orange;
      case LocationCondition.poor:
        return Colors.redAccent;
      case LocationCondition.closed:
        return Colors.red;
    }
  }

  IconData _getLocationConditionIcon(LocationCondition condition) {
    switch (condition) {
      case LocationCondition.excellent:
        return Icons.star;
      case LocationCondition.good:
        return Icons.check_circle;
      case LocationCondition.needsMaintenance:
        return Icons.build;
      case LocationCondition.poor:
        return Icons.warning;
      case LocationCondition.closed:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location.name),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            onPressed: _toggleFavorite,
            color: _isFavorite ? Colors.amber : null,
            tooltip: _isFavorite ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildLocationInfo(),
            _buildEquipmentSection(),
            _buildReviewsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildImageSection() {
    if (widget.location.imageUrls.isEmpty) {
      return Container(
        height: 200,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Nessuna immagine disponibile',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: widget.location.imageUrls.length,
        itemBuilder: (context, index) {
          return Image.network(
            widget.location.imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.error,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.location.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.location.isValidated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verificato',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.location.address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          if (widget.location.reviewCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Stelle per la media delle valutazioni
                ...List.generate(5, (index) {
                  return Icon(
                    index < widget.location.averageRating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${widget.location.averageRating.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Stato medio del posto
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLocationConditionColor(widget.location.averageLocationCondition),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.location.averageLocationCondition.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${widget.location.reviewCount} recensioni)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            widget.location.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attrezzature Disponibili',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Stato generale delle attrezzature
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.location.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getStatusColor(widget.location.status).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(widget.location.status),
                  color: _getStatusColor(widget.location.status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Stato: ${widget.location.status.displayName}',
                  style: TextStyle(
                    color: _getStatusColor(widget.location.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.location.equipmentTypes.map((equipment) {
              return Chip(
                label: Text(equipment),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recensioni (${_reviews.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showAddReviewDialog(),
                child: const Text('Aggiungi'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nessuna recensione ancora',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sii il primo a recensire questo luogo!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._reviews.map((review) => _ReviewCard(review: review)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _startWorkout(),
              icon: const Icon(Icons.fitness_center),
              label: const Text('Inizia Allenamento'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showDirections(),
              icon: const Icon(Icons.directions),
              label: const Text('Indicazioni'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(LocationStatus status) {
    switch (status) {
      case LocationStatus.excellent:
      case LocationStatus.good:
        return Colors.green;
      case LocationStatus.needsMaintenance:
        return Colors.yellow;
      case LocationStatus.poor:
        return Colors.red;
      case LocationStatus.closed:
        return Colors.grey;
      case LocationStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(LocationStatus status) {
    switch (status) {
      case LocationStatus.excellent:
      case LocationStatus.good:
        return Icons.check_circle;
      case LocationStatus.needsMaintenance:
        return Icons.build;
      case LocationStatus.poor:
        return Icons.warning;
      case LocationStatus.closed:
        return Icons.block;
      case LocationStatus.pending:
        return Icons.schedule;
    }
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddReviewDialog(
        location: widget.location,
        onReviewAdded: () {
          _loadReviews();
        },
      ),
    );
  }

  void _startWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inizia Allenamento'),
        content: Text('Vuoi iniziare un allenamento presso ${widget.location.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createAndStartWorkout();
            },
            child: const Text('Inizia'),
          ),
        ],
      ),
    );
  }

  void _createAndStartWorkout() async {
    try {
      final firebaseService = Provider.of<FirebaseProvider>(context, listen: false);
      
      if (!firebaseService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devi essere autenticato per iniziare un allenamento'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final currentUser = firebaseService.user;
      if (currentUser != null) {
        final workout = WorkoutDocument(
          id: '', // Will be set by Firestore
          userId: currentUser.uid,
          locationId: widget.location.id,
          name: 'Allenamento presso ${widget.location.name}',
          type: 'outdoor',
          date: DateTime.now(),
          duration: 0, // Will be updated when workout is completed
          calories: 0, // Will be calculated when workout is completed
          exercises: [],
          notes: 'Allenamento all\'aperto iniziato',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await firebaseService.firestoreService.addWorkout(workout);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allenamento iniziato! Vai alla sezione Allenamenti per monitorarlo.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Naviga alla schermata allenamenti
        Navigator.of(context).pushNamed('/workouts');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'iniziare l\'allenamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDirections() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Indicazioni'),
        content: Text('Apri le indicazioni per ${widget.location.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apri Mappa'),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  Color _getLocationConditionColor(LocationCondition condition) {
    switch (condition) {
      case LocationCondition.excellent:
        return Colors.green;
      case LocationCondition.good:
        return Colors.lightGreen;
      case LocationCondition.needsMaintenance:
        return Colors.orange;
      case LocationCondition.poor:
        return Colors.redAccent;
      case LocationCondition.closed:
        return Colors.red;
    }
  }

  IconData _getLocationConditionIcon(LocationCondition condition) {
    switch (condition) {
      case LocationCondition.excellent:
        return Icons.star;
      case LocationCondition.good:
        return Icons.check_circle;
      case LocationCondition.needsMaintenance:
        return Icons.build;
      case LocationCondition.poor:
        return Icons.warning;
      case LocationCondition.closed:
        return Icons.block;
    }
  }

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
                          const SizedBox(width: 8),
                          Text(
                           '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getLocationConditionColor(review.locationCondition).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getLocationConditionColor(review.locationCondition).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getLocationConditionIcon(review.locationCondition),
                                  size: 14,
                                  color: _getLocationConditionColor(review.locationCondition),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  review.locationCondition.displayName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _getLocationConditionColor(review.locationCondition),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (review.equipmentReviewed.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Attrezzature recensite:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: review.equipmentReviewed.map((equipment) {
                  return Chip(
                    label: Text(equipment),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddReviewDialog extends StatefulWidget {
  final FitnessLocation location;
  final VoidCallback onReviewAdded;

  const _AddReviewDialog({
    required this.location,
    required this.onReviewAdded,
  });

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 5.0;
  List<String> _selectedEquipment = [];
  LocationCondition _locationCondition = LocationCondition.good; // Stato del posto
  bool _isLoading = false;
  bool _isUploadingImages = false;
  
  // Variabili per le immagini
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addImages() async {
    try {
      final List<File> newImages = await ImagePickerDialog.showMultipleImagePicker(
        context,
        maxImages: 3 - _selectedImages.length,
      );
      
      if (newImages.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(newImages);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore selezione immagini: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final List<String> urls = await ImageUploadService.uploadMultipleImages(
        _selectedImages,
        'reviews/${widget.location.id}/${DateTime.now().millisecondsSinceEpoch}',
      );
      return urls;
    } catch (e) {
      print('Error uploading images: $e');
      return [];
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }

  void _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService = Provider.of<FirebaseProvider>(context, listen: false);
      
      if (!firebaseService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devi essere autenticato per aggiungere una recensione'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Upload immagini se presenti
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      final currentUser = firebaseService.user;
      if (currentUser != null) {
        final reviewDoc = ReviewDocument(
          id: '', // Will be set by Firestore
          locationId: widget.location.id,
          userId: currentUser.uid,
          userName: currentUser.displayName ?? 'Utente Anonimo',
          userPhotoUrl: currentUser.photoURL,
          rating: _rating.toInt(),
          comment: _commentController.text.trim(),
          equipmentReviews: _selectedEquipment.isNotEmpty ? {_selectedEquipment.first: 'Buono'} : {},
          imageUrls: imageUrls, // Aggiungiamo le immagini caricate
          locationStatus: _locationCondition.name, // Aggiungiamo lo stato del posto
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await firebaseService.firestoreService.addReview(reviewDoc);
      }
      
      widget.onReviewAdded();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recensione aggiunta con successo!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'aggiunta della recensione: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aggiungi Recensione',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valutazione',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setState(() {
                                _rating = index + 1.0;
                              }),
                              child: Icon(
                                index < _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Commento',
                            hintText: 'Scrivi la tua esperienza...',
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci un commento';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Valutazione stato del posto
                        Text(
                          'Stato del posto',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<LocationCondition>(
                            value: _locationCondition,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: LocationCondition.values.map((condition) {
                              return DropdownMenuItem(
                                value: condition,
                                child: Text(condition.displayName),
                              );
                            }).toList(),
                            onChanged: (LocationCondition? newCondition) {
                              if (newCondition != null) {
                                setState(() {
                                  _locationCondition = newCondition;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (widget.location.equipmentTypes.isNotEmpty) ...[
                          Text(
                            'Attrezzature utilizzate (opzionale)',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.location.equipmentTypes.map((equipment) {
                              final isSelected = _selectedEquipment.contains(equipment);
                              return FilterChip(
                                label: Text(equipment),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedEquipment.add(equipment);
                                    } else {
                                      _selectedEquipment.remove(equipment);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Sezione Foto
                        Text(
                          'Foto (opzionale)',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aggiungi fino a 3 foto per mostrare la tua esperienza:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Griglia foto selezionate
                        if (_selectedImages.isNotEmpty) ...[
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                final image = _selectedImages[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          image,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // Bottone aggiungi foto
                        OutlinedButton.icon(
                          onPressed: _selectedImages.length >= 3 ? null : _addImages,
                          icon: const Icon(Icons.add_a_photo),
                          label: Text(
                            _selectedImages.isEmpty 
                                ? 'Aggiungi foto'
                                : 'Aggiungi altre foto (${_selectedImages.length}/3)',
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annulla'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (_isLoading || _isUploadingImages) ? null : _submitReview,
                      child: (_isLoading || _isUploadingImages)
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(_isUploadingImages ? 'Caricamento foto...' : 'Invio...'),
                              ],
                            )
                          : const Text('Aggiungi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}