import 'package:flutter/material.dart';
import 'package:fitspot/models/fitness_location.dart';
import 'package:fitspot/data/sample_data.dart';
import 'package:fitspot/screens/location_detail_screen.dart';
import 'package:fitspot/firestore/firestore_service.dart';
import 'package:fitspot/services/favorites_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<FitnessLocation> _locations = [];
  List<FitnessLocation> _filteredLocations = [];
  String _searchQuery = '';
  String? _selectedEquipment;
  LocationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ricarica i dati quando si torna alla schermata
    _loadLocations();
  }

  void _loadLocations() async {
    try {
      final firestoreService = FirestoreService();
      final approvedLocationsData = await firestoreService.getApprovedFitnessLocations();
      final favoriteIds = await FavoritesService.getFavoriteIds();
      
      // Convertire i dati in oggetti FitnessLocation aggiornati
      final approvedLocations = approvedLocationsData.map((data) {
        return FitnessLocation(
          id: data['id'],
          name: data['name'],
          description: data['description'],
          address: data['address'],
          latitude: data['latitude'],
          longitude: data['longitude'],
          equipmentTypes: List<String>.from(data['equipmentTypes']),
          images: List<String>.from(data['imageUrls']),
          isValidated: data['isValidated'],
          status: LocationStatus.values.firstWhere(
            (status) => status.toString().split('.').last == data['status'],
            orElse: () => LocationStatus.good,
          ),
          rating: data['averageRating'],
          createdAt: DateTime.now(), // Default value for required field
          updatedAt: DateTime.now(), // Default value for required field
          createdBy: 'user', // Default value for required field
          isFavorite: favoriteIds.contains(data['id']),
        );
      }).toList();
      
      setState(() {
        // Mostrare solo i luoghi approvati dal database
        _locations = approvedLocations;
        _filteredLocations = _locations;
      });
    } catch (e) {
      print('Error loading locations: $e');
      // In caso di errore, non mostrare nessun luogo
      setState(() {
        _locations = [];
        _filteredLocations = _locations;
      });
    }
  }

  void _filterLocations() {
    setState(() {
      _filteredLocations = _locations.where((location) {
        final matchesSearch = location.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            location.address.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesEquipment = _selectedEquipment == null ||
            location.equipmentTypes.contains(_selectedEquipment);
        
        final matchesStatus = _selectedStatus == null ||
            location.status == _selectedStatus;

        return matchesSearch && matchesEquipment && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luoghi Fitness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cerca luoghi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterLocations();
              },
            ),
          ),
          if (_selectedEquipment != null || _selectedStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_selectedEquipment != null) ...[
                    Chip(
                      label: Text(_selectedEquipment!),
                      onDeleted: () {
                        setState(() => _selectedEquipment = null);
                        _filterLocations();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_selectedStatus != null) ...[
                    Chip(
                      label: Text(_selectedStatus!.displayName),
                      onDeleted: () {
                        setState(() => _selectedStatus = null);
                        _filterLocations();
                      },
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: _filteredLocations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nessun luogo trovato',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prova a modificare i filtri di ricerca',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredLocations.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final location = _filteredLocations[index];
                      return _LocationCard(
                        location: location,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationDetailScreen(location: location),
                            ),
                          );
                          // Ricarica i dati quando si torna dalla pagina dettagli
                          _loadLocations();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtri',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Attrezzature',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: SampleData.commonEquipmentTypes.map((equipment) {
                final isSelected = _selectedEquipment == equipment;
                return FilterChip(
                  label: Text(equipment),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedEquipment = selected ? equipment : null;
                    });
                    _filterLocations();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Stato',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: LocationStatus.values.map((status) {
                final isSelected = _selectedStatus == status;
                return FilterChip(
                  label: Text(status.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? status : null;
                    });
                    _filterLocations();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedEquipment = null;
                        _selectedStatus = null;
                      });
                      _filterLocations();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancella Filtri'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Applica'),
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

class _LocationCard extends StatefulWidget {
  final FitnessLocation location;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.onTap,
  });

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.location.isFavorite;
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
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
                          widget.location.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.location.address,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _toggleFavorite,
                            child: Icon(
                              _isFavorite ? Icons.star : Icons.star_border,
                              color: _isFavorite ? Colors.amber : Colors.grey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.location.isValidated)
                            Icon(
                              Icons.verified,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                      if (widget.location.averageRating > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.location.averageRating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.location.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.location.equipmentTypes.take(3).map((equipment) {
                  return Chip(
                    label: Text(
                      equipment,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  );
                }).toList(),
              ),
              if (widget.location.equipmentTypes.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${widget.location.equipmentTypes.length - 3} altre attrezzature',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}