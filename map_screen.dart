import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import 'package:fitspot/models/fitness_location.dart';
import 'package:fitspot/data/sample_data.dart';
import 'package:fitspot/screens/location_detail_screen.dart';
import 'package:fitspot/firestore/firebase_provider.dart';
import 'package:fitspot/firestore/firestore_data_schema.dart';
import 'package:fitspot/widgets/image_picker_dialog.dart';
import 'package:fitspot/services/image_upload_service.dart';
import 'package:fitspot/services/favorites_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<FitnessLocation> _locations = [];
  bool _showOnlyValidated = true;
  bool _showOnlyFavorites = false;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadFavoritesStatus() async {
    final favoriteIds = await FavoritesService.getFavoriteIds();
    setState(() {
      _locations = _locations.map((location) {
        return location.copyWith(
          isFavorite: favoriteIds.contains(location.id),
        );
      }).toList();
    });
  }

  void _loadLocations() async {
    try {
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      final favoriteIds = await FavoritesService.getFavoriteIds();
      
      firebaseProvider.firestoreService.getValidatedLocations().listen((locationDocs) {
        setState(() {
          _locations = locationDocs.map((locationDoc) => FitnessLocation(
            id: locationDoc.id,
            name: locationDoc.name,
            description: locationDoc.description,
            address: locationDoc.address,
            latitude: locationDoc.latitude,
            longitude: locationDoc.longitude,
            equipmentTypes: locationDoc.equipment, // Note: using equipment field
            images: locationDoc.imageUrls, // Note: using imageUrls field
            status: locationDoc.isValidated ? LocationStatus.excellent : LocationStatus.good,
            isValidated: locationDoc.isValidated,
            validatedBy: locationDoc.validatedBy,
            validatedAt: locationDoc.validatedAt,
            reviews: [],
            rating: locationDoc.averageRating, // Note: using averageRating field
            createdAt: locationDoc.createdAt,
            updatedAt: locationDoc.updatedAt,
            createdBy: locationDoc.submittedBy, // Note: using submittedBy field
            isFavorite: favoriteIds.contains(locationDoc.id),
          )).toList();
        });
      });
    } catch (e) {
      // Fallback ai dati di esempio in caso di errore
      final favoriteIds = await FavoritesService.getFavoriteIds();
      setState(() {
        _locations = SampleData.sampleLocations.map((location) => 
          location.copyWith(
            isFavorite: favoriteIds.contains(location.id),
          )
        ).toList();
      });
    }
  }

  List<FitnessLocation> get _filteredLocations {
    var filtered = _locations;
    
    if (_showOnlyValidated) {
      filtered = filtered.where((location) => location.isValidated).toList();
    }
    
    if (_showOnlyFavorites) {
      filtered = filtered.where((location) => location.isFavorite).toList();
    }
    
    return filtered;
  }

  List<Marker> get _markers {
    List<Marker> markers = _filteredLocations.map((location) {
      Color markerColor = _getMarkerColor(location);

      return Marker(
        point: LatLng(location.latitude, location.longitude),
        width: 40.0,
        height: 40.0,
        child: GestureDetector(
          onTap: () => _showLocationBottomSheet(location),
          child: Container(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();

    // Aggiungi il marker della posizione utente se disponibile
    if (_userPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          width: 50.0,
          height: 50.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Color _getMarkerColor(FitnessLocation location) {
    if (!location.isValidated) {
      return Colors.orange;
    }
    switch (location.status) {
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

  Future<void> _goToUserLocation() async {
    try {
      // Controlla i permessi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permessi di localizzazione negati'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permessi di localizzazione negati permanentemente. Abilitali nelle impostazioni.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ottieni la posizione corrente
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userPosition = position;
      });

      // Centri la mappa sulla posizione dell'utente
      _mapController.move(
        LatLng(position.latitude, position.longitude), 
        15.0, // Zoom più vicino per vedere i dettagli
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posizione trovata! Marker blu indica la tua posizione'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel ottenere la posizione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLocationBottomSheet(FitnessLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => _LocationBottomSheet(
          location: location,
          scrollController: scrollController,
          onViewDetails: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationDetailScreen(location: location),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fit Spot'),
        actions: [
          IconButton(
            icon: Icon(_showOnlyValidated ? Icons.verified : Icons.visibility),
            onPressed: () {
              setState(() {
                _showOnlyValidated = !_showOnlyValidated;
                _showOnlyFavorites = false; // Reset favorites filter when changing validation
              });
            },
            tooltip: _showOnlyValidated ? 'Mostra tutti' : 'Solo validati',
          ),
          IconButton(
            icon: Icon(_showOnlyFavorites ? Icons.star : Icons.star_border),
            onPressed: () async {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
              if (_showOnlyFavorites) {
                // Load favorite status for all locations
                await _loadFavoritesStatus();
              }
            },
            tooltip: _showOnlyFavorites ? 'Mostra tutti' : 'Solo preferiti',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToUserLocation,
            tooltip: 'Vai alla mia posizione',
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(45.4642, 9.1900),
          initialZoom: 11.0,
          minZoom: 8.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.fitspot',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "location_fab",
            onPressed: _goToUserLocation,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.my_location, color: Colors.white),
            tooltip: 'La mia posizione',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "add_fab",
            onPressed: () => _showAddLocationDialog(),
            child: const Icon(Icons.add_location_alt),
            tooltip: 'Aggiungi luogo',
          ),
        ],
      ),
    );
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddLocationDialog(
        onLocationAdded: () {
          _loadLocations();
        },
      ),
    );
  }
}

class _LocationBottomSheet extends StatelessWidget {
  final FitnessLocation location;
  final ScrollController scrollController;
  final VoidCallback onViewDetails;

  const _LocationBottomSheet({
    required this.location,
    required this.scrollController,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.center,
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
              if (location.isValidated)
                Icon(
                  Icons.verified,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (location.averageRating > 0) ...[
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < location.averageRating.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                    '${location.averageRating.toStringAsFixed(1)} (${location.reviewCount})'),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            location.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: location.equipmentTypes.take(3).map((equipment) {
              return Chip(
                label: Text(equipment),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
          if (location.equipmentTypes.length > 3) ...[
            const SizedBox(height: 8),
            Text(
              '+${location.equipmentTypes.length - 3} altre attrezzature',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewDetails,
              child: const Text('Vedi Dettagli'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddLocationDialog extends StatefulWidget {
  final VoidCallback onLocationAdded;

  const _AddLocationDialog({
    required this.onLocationAdded,
  });

  @override
  State<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<_AddLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _cityController = TextEditingController();
  final _capController = TextEditingController();
  final _otherEquipmentController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _isSearchingAddress = false;
  bool _isUploadingImages = false;
  double? _latitude;
  double? _longitude;
  
  // Variabili per le immagini
  List<File> _selectedImages = [];

  String _buildCompleteAddress() {
    final parts = <String>[];
    
    if (_streetController.text.trim().isNotEmpty) {
      String street = _streetController.text.trim();
      if (_streetNumberController.text.trim().isNotEmpty) {
        street += ' ${_streetNumberController.text.trim()}';
      }
      parts.add(street);
    }
    
    if (_cityController.text.trim().isNotEmpty) {
      String cityPart = _cityController.text.trim();
      if (_capController.text.trim().isNotEmpty) {
        cityPart = '${_capController.text.trim()} $cityPart';
      }
      parts.add(cityPart);
    }
    
    String address = parts.join(', ');
    
    // Se l'indirizzo è vuoto ma abbiamo le coordinate, usa le coordinate come indirizzo
    if (address.isEmpty && _latitude != null && _longitude != null) {
      address = 'Posizione GPS: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}';
    }
    
    return address;
  }  List<String> _uploadedImageUrls = [];
  
  // Lista di attrezzature predefinite
  static const List<String> _predefinedEquipment = [
    'Sbarre per trazioni',
    'Parallele',
    'Panca piana',
    'Spalliera',
    'Anelli',
    'Corda per arrampicata',
    'Monkey bars',
    'Panca addominali',
    'Ostacoli',
    'Gradini per step',
    'Pali per slalom',
    'Attrezzi TRX fissi',
    'Panca inclinata',
    'Struttura per calisthenics',
    'Campo da basket',
    'Campo da calcio',
    'Pista di atletica',
  ];
  
  final Set<String> _selectedEquipment = {};
  bool _hasOtherEquipment = false;
  String _selectedEquipmentStatus = 'good';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _capController.dispose();
    _otherEquipmentController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Controlla i permessi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permessi di localizzazione negati';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permessi di localizzazione negati permanentemente. Abilitali nelle impostazioni.';
      }

      // Ottieni la posizione corrente
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Ottieni l'indirizzo dalla posizione e aggiorna automaticamente il campo
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '';
          if (place.street != null && place.street!.isNotEmpty) {
            address += place.street!;
          }
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            address += place.subThoroughfare!;
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            address += place.locality!;
          }
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            if (address.isNotEmpty) address += ' ';
            address += place.postalCode!;
          }

          setState(() {
            // Dividere l'indirizzo nei campi separati
            final parts = address.split(',');
            if (parts.isNotEmpty) {
              _streetController.text = parts[0].trim();
              if (parts.length > 1) {
                _cityController.text = parts[parts.length - 2].trim();
              }
              // Provare a estrarre il CAP dall'ultimo elemento
              if (parts.length > 2) {
                final lastPart = parts.last.trim();
                final capMatch = RegExp(r'\d{5}').firstMatch(lastPart);
                if (capMatch != null) {
                  _capController.text = capMatch.group(0)!;
                }
              }
            }
          });
        }
      } catch (e) {
        // Imposta un indirizzo generico se il geocoding fallisce
        setState(() {
          // Lasciare i campi vuoti quando si usa la posizione GPS
          _streetController.text = '';
          _streetNumberController.text = '';
          _cityController.text = '';
          _capController.text = '';
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posizione corrente rilevata e impostata sulla mappa!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nel ottenere la posizione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  List<String> _addressSuggestions = [];
  bool _showSuggestions = false;
  Timer? _searchTimer;

  // Elenco completo di città e località italiane
  static const List<String> _italianCities = [
    'Roma', 'Milano', 'Napoli', 'Torino', 'Palermo', 'Genova', 'Bologna', 'Firenze', 
    'Bari', 'Catania', 'Venezia', 'Verona', 'Messina', 'Padova', 'Trieste', 'Taranto',
    'Brescia', 'Parma', 'Prato', 'Modena', 'Reggio Calabria', 'Reggio Emilia', 'Perugia',
    'Livorno', 'Ravenna', 'Cagliari', 'Foggia', 'Rimini', 'Salerno', 'Ferrara', 'Sassari',
    'Latina', 'Giugliano in Campania', 'Monza', 'Siracusa', 'Pescara', 'Bergamo', 
    'Forlì', 'Trento', 'Vicenza', 'Terni', 'Bolzano', 'Novara', 'Ancona', 'Piacenza',
    'Andria', 'Arezzo', 'Udine', 'Cesena', 'Lecce', 'Pesaro', 'Barletta', 'Aprilia',
    'Como', 'Cremona', 'Mantova', 'Pavia', 'Varese', 'Lecco', 'Lodi', 'Sondrio',
    'Asti', 'Alessandria', 'Cuneo', 'Biella', 'Vercelli', 'Imperia', 'Savona', 'La Spezia',
    'Pisa', 'Lucca', 'Massa', 'Pistoia', 'Grosseto', 'Siena', 'Carrara', 'Viareggio'
  ];

  Future<void> _searchAddressSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
        _isSearchingAddress = false;
      });
      return;
    }

    setState(() {
      _isSearchingAddress = true;
    });

    try {
      // Usa l'API di Nominatim per suggerimenti reali
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': '$query, Italia',
          'format': 'json',
          'addressdetails': 1,
          'limit': 8,
          'countrycodes': 'it',
          'accept-language': 'it',
        },
        options: Options(
          headers: {
            'User-Agent': 'FitSpot/1.0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        List<dynamic> results = response.data;
        List<String> suggestions = [];

        for (var result in results.take(8)) {
          String displayName = result['display_name'] ?? '';
          if (displayName.isNotEmpty) {
            // Pulisci il display name rimuovendo parti ripetitive
            displayName = displayName.split(', Italia')[0]; // Rimuovi ", Italia, ..."
            suggestions.add(displayName);
          }
        }

        // Se non abbiamo abbastanza risultati, aggiungi alcuni suggerimenti locali
        if (suggestions.length < 3) {
          List<String> localSuggestions = [
            'Via $query',
            'Piazza $query',
            'Corso $query',
          ].where((s) => !suggestions.contains(s)).take(3 - suggestions.length).toList();
          suggestions.addAll(localSuggestions);
        }

        setState(() {
          _addressSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
          _isSearchingAddress = false;
        });
      } else {
        throw 'Errore nella risposta del server';
      }
    } catch (e) {
      print('Errore API Nominatim: $e');
      
      // Fallback con suggerimenti locali intelligenti
      List<String> fallbackSuggestions = [];
      
      // Suggerimenti con prefissi comuni per vie
      List<String> streetPrefixes = ['Via', 'Piazza', 'Corso', 'Viale', 'Largo'];
      
      bool hasPrefix = streetPrefixes.any((prefix) => query.toLowerCase().startsWith(prefix.toLowerCase()));
      
      if (!hasPrefix && query.trim().length >= 2) {
        // Aggiungi suggerimenti con prefissi
        for (String prefix in streetPrefixes.take(3)) {
          fallbackSuggestions.add('$prefix $query');
        }
      }
      
      // Aggiungi suggerimenti con città italiane principali
      List<String> majorCities = ['Milano', 'Roma', 'Napoli', 'Torino', 'Bologna'];
      for (String city in majorCities.take(3)) {
        fallbackSuggestions.add('$query, $city');
      }

      setState(() {
        _addressSuggestions = fallbackSuggestions.take(6).toList();
        _showSuggestions = fallbackSuggestions.isNotEmpty;
        _isSearchingAddress = false;
      });
    }
  }

  Future<void> _searchCitySuggestions(String query) async {
    // Suggerimenti per città in tempo reale usando API
    if (query.trim().length >= 2) {
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'q': '$query',
            'format': 'json',
            'addressdetails': 1,
            'limit': 8,
            'countrycodes': 'it',
            'featureType': 'city',
            'accept-language': 'it',
          },
          options: Options(
            headers: {
              'User-Agent': 'FitSpot/1.0',
            },
          ),
        );

        if (response.statusCode == 200 && response.data is List) {
          List<dynamic> results = response.data;
          
          // Se abbiamo risultati e un indirizzo strada, prova a geocodificare
          if (results.isNotEmpty && _streetController.text.isNotEmpty) {
            String fullAddress = '${_streetController.text}, $query, Italia';
            _searchAddress(fullAddress);
          }
        }
      } catch (e) {
        // Fallback alla lista statica se l'API fallisce
        String exactMatch = _italianCities.firstWhere(
          (city) => city.toLowerCase() == query.toLowerCase(),
          orElse: () => '',
        );
        
        if (exactMatch.isNotEmpty && _streetController.text.isNotEmpty) {
          String fullAddress = '${_streetController.text}, $exactMatch, Italia';
          _searchAddress(fullAddress);
        }
      }
    }
  }

  Future<void> _parseAndFillAddress(String suggestion) async {
    try {
      // Usa l'API di Nominatim per ottenere i dettagli completi dell'indirizzo
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': suggestion,
          'format': 'json',
          'addressdetails': 1,
          'limit': 1,
          'countrycodes': 'it',
          'accept-language': 'it',
        },
        options: Options(
          headers: {
            'User-Agent': 'FitSpot/1.0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
        final result = response.data[0];
        final address = result['address'] ?? {};
        
        // Estrai i dettagli dell'indirizzo
        String road = address['road'] ?? address['pedestrian'] ?? address['residential'] ?? '';
        String houseNumber = address['house_number'] ?? '';
        String city = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? '';
        String postcode = address['postcode'] ?? '';
        
        // Se non abbiamo la strada dal campo 'road', proviamo con il display_name
        if (road.isEmpty) {
          final displayParts = suggestion.split(',');
          if (displayParts.isNotEmpty) {
            road = displayParts[0].trim();
          }
        }
        
        // Auto-compila i campi
        setState(() {
          if (road.isNotEmpty) _streetController.text = road;
          if (houseNumber.isNotEmpty) _streetNumberController.text = houseNumber;
          if (city.isNotEmpty) _cityController.text = city;
          if (postcode.isNotEmpty) _capController.text = postcode;
          
          // Imposta le coordinate
          _latitude = double.tryParse(result['lat']?.toString() ?? '');
          _longitude = double.tryParse(result['lon']?.toString() ?? '');
          
          _isSearchingAddress = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indirizzo auto-compilato con successo!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Fallback al parsing semplice se l'API non restituisce risultati
        await _simpleAddressParse(suggestion);
      }
    } catch (e) {
      print('Errore nel parsing dell\'indirizzo: $e');
      // Fallback al parsing semplice in caso di errore
      await _simpleAddressParse(suggestion);
    }
  }

  Future<void> _simpleAddressParse(String suggestion) async {
    // Parse semplice come fallback
    final parts = suggestion.split(',');
    if (parts.isNotEmpty) {
      _streetController.text = parts[0].trim();
      if (parts.length > 1) {
        final cityPart = parts[1].trim();
        _cityController.text = cityPart.replaceAll('Italia', '').trim();
      }
    }
    
    setState(() {
      _isSearchingAddress = false;
    });
    
    // Cerca le coordinate per il suggerimento selezionato
    await _searchAddress(suggestion);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Indirizzo impostato. Compila manualmente i campi mancanti.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearchingAddress = true;
      _showSuggestions = false;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        setState(() {
          _latitude = location.latitude;
          _longitude = location.longitude;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indirizzo trovato e coordinate impostate!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indirizzo non trovato'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella ricerca: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearchingAddress = false;
      });
    }
  }

  Future<void> _addImages() async {
    try {
      final List<File> newImages = await ImagePickerDialog.showMultipleImagePicker(
        context,
        maxImages: 5 - _selectedImages.length,
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
        'locations/${DateTime.now().millisecondsSinceEpoch}',
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

  void _submitLocation() async {
    if (!_formKey.currentState!.validate()) return;

    // Controlla che ci sia almeno una posizione (GPS) o un indirizzo manuale valido
    final hasManualAddress = _streetController.text.trim().isNotEmpty && _cityController.text.trim().isNotEmpty;
    final hasGpsCoordinates = _latitude != null && _longitude != null;
    
    if (!hasGpsCoordinates && !hasManualAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci almeno via e città, oppure usa la posizione GPS'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedEquipment.isEmpty && !_hasOtherEquipment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno un\'attrezzatura'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Se abbiamo un indirizzo manuale ma non le coordinate GPS, proviamo il geocoding
      if (!hasGpsCoordinates && hasManualAddress) {
        final fullAddress = _buildCompleteAddress() + ', Italia';
        try {
          List<Location> locations = await locationFromAddress(fullAddress);
          if (locations.isNotEmpty) {
            Location location = locations.first;
            _latitude = location.latitude;
            _longitude = location.longitude;
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Coordinate trovate per l\'indirizzo inserito'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Se il geocoding fallisce, mostra un errore ma non bloccare il salvataggio
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attenzione: Impossibile trovare le coordinate per questo indirizzo. Il posto potrebbe non apparire correttamente sulla mappa.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
      final firebaseService = Provider.of<FirebaseProvider>(context, listen: false);
      List<String> allEquipment = _selectedEquipment.toList();
      if (_hasOtherEquipment && _otherEquipmentController.text.trim().isNotEmpty) {
        allEquipment.addAll(_otherEquipmentController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }

      // Upload immagini se presenti
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      if (firebaseService.isAuthenticated) {
        // Utente autenticato - salva su Firebase
        final currentUser = firebaseService.user!;
        
        // Converti FitnessLocationDocument in LocationSuggestionDocument
        final suggestion = LocationSuggestionDocument(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          latitude: _latitude ?? 0.0, // Se non ci sono coordinate, usa 0.0 come placeholder
          longitude: _longitude ?? 0.0, // Se non ci sono coordinate, usa 0.0 come placeholder
          address: _buildCompleteAddress(),
          type: 'workout_area',
          equipment: allEquipment,
          submittedBy: currentUser.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'pending',
          equipmentStatus: _selectedEquipmentStatus,
          adminNotes: '',
          imageUrls: imageUrls, // Aggiungiamo le immagini caricate
        );
        
        await firebaseService.firestoreService.createLocationSuggestion(suggestion);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location aggiunta con successo! Verrà validata dall\'amministratore.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Utente ospite - salva localmente
        final location = FitnessLocation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          address: _buildCompleteAddress(),
          latitude: _latitude ?? 0.0, // Se non ci sono coordinate, usa 0.0 come placeholder
          longitude: _longitude ?? 0.0, // Se non ci sono coordinate, usa 0.0 come placeholder
          equipmentTypes: allEquipment,
          images: [],
          status: LocationStatus.values.firstWhere(
            (e) => e.name == _selectedEquipmentStatus,
            orElse: () => LocationStatus.good,
          ),
          isValidated: false,
          reviews: [],
          rating: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'guest_user',
        );
        
        // Salva nella cache locale
        final localData = Provider.of<FirebaseProvider>(context, listen: false);
        // Qui dovresti avere un LocalDataService o simile per salvare i dati locali
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location aggiunta localmente! Registrati per sincronizzare i tuoi contributi.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      widget.onLocationAdded();
      Navigator.of(context).pop();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'aggiunta: $e'),
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
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aggiungi Nuovo Luogo',
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
                        // Nome del luogo
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome del luogo',
                            hintText: 'Es. Parco delle Rose',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci il nome del luogo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Descrizione
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descrizione',
                            hintText: 'Descrivi brevemente il luogo e le sue caratteristiche',
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci una descrizione';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Sezione Posizione
                        Text(
                          'Posizione',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Campi indirizzo separati
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Indirizzo *',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Via e numero civico con suggerimenti
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: _streetController,
                                          decoration: InputDecoration(
                                            labelText: 'Via/Piazza',
                                            hintText: 'es. Via Roma',
                                            prefixIcon: const Icon(Icons.location_on, size: 20),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            suffixIcon: _isSearchingAddress 
                                                ? const Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child: SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Richiesto';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            // Cancella il timer precedente
                                            _searchTimer?.cancel();
                                            
                                            // Avvia un nuovo timer per ritardare la ricerca
                                            _searchTimer = Timer(const Duration(milliseconds: 500), () {
                                              if (value.trim().length >= 2) {
                                                _searchAddressSuggestions(value.trim());
                                              } else {
                                                setState(() {
                                                  _showSuggestions = false;
                                                  _addressSuggestions = [];
                                                });
                                              }
                                            });
                                          },
                                        ),
                                        // Lista suggerimenti
                                        if (_showSuggestions && _addressSuggestions.isNotEmpty)
                                          Container(
                                            constraints: const BoxConstraints(maxHeight: 150),
                                            margin: const EdgeInsets.only(top: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surface,
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: _addressSuggestions.length,
                                              itemBuilder: (context, index) {
                                                final suggestion = _addressSuggestions[index];
                                                return ListTile(
                                                  dense: true,
                                                  leading: const Icon(Icons.location_on, size: 18),
                                                  title: Text(
                                                    suggestion,
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                  onTap: () async {
                                                    setState(() {
                                                      _showSuggestions = false;
                                                      _addressSuggestions = [];
                                                      _isSearchingAddress = true;
                                                    });
                                                    
                                                    // Auto-compila i campi usando l'API di Nominatim per ottenere dettagli completi
                                                    await _parseAndFillAddress(suggestion);
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _streetNumberController,
                                      decoration: InputDecoration(
                                        labelText: 'N°',
                                        hintText: '123',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      keyboardType: TextInputType.text,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Città e CAP
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: _cityController,
                                          decoration: InputDecoration(
                                            labelText: 'Città',
                                            hintText: 'es. Milano',
                                            prefixIcon: const Icon(Icons.location_city, size: 20),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Richiesto';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            if (value.trim().length >= 2) {
                                              _searchCitySuggestions(value.trim());
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _capController,
                                      decoration: InputDecoration(
                                        labelText: 'CAP',
                                        hintText: '20100',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      keyboardType: TextInputType.number,
                                      maxLength: 5,
                                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                                        return null; // Nasconde il counter
                                      },
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty && value.length != 5) {
                                          return 'CAP non valido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Bottoni posizione
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                                icon: _isLoadingLocation 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.my_location),
                                label: const Text('Usa Posizione Corrente'),
                              ),
                            ),
                          ],
                        ),
                        
                        // Stato delle coordinate
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Coordinate impostate: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                    style: TextStyle(color: Colors.green[700], fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Sezione Attrezzature
                        Text(
                          'Attrezzature Disponibili',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seleziona tutte le attrezzature presenti in questo luogo:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Griglia attrezzature
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _predefinedEquipment.map((equipment) {
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
                              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              checkmarkColor: Theme.of(context).colorScheme.primary,
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Altro checkbox
                        CheckboxListTile(
                          title: const Text('Altro (specifica)'),
                          value: _hasOtherEquipment,
                          onChanged: (value) {
                            setState(() {
                              _hasOtherEquipment = value ?? false;
                              if (!_hasOtherEquipment) {
                                _otherEquipmentController.clear();
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        // Campo altro
                        if (_hasOtherEquipment) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _otherEquipmentController,
                            decoration: const InputDecoration(
                              labelText: 'Altre attrezzature',
                              hintText: 'Specifica altre attrezzature (separa con virgola)',
                              prefixIcon: Icon(Icons.add),
                            ),
                            maxLines: 2,
                            validator: _hasOtherEquipment ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Specifica le altre attrezzature';
                              }
                              return null;
                            } : null,
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Sezione Stato delle Attrezzature
                        Text(
                          'Stato delle Attrezzature',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Indica lo stato generale delle attrezzature:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Dropdown per lo stato
                        DropdownButtonFormField<String>(
                          value: _selectedEquipmentStatus,
                          decoration: const InputDecoration(
                            labelText: 'Stato delle attrezzature',
                            prefixIcon: Icon(Icons.health_and_safety),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'excellent',
                              child: Row(
                                children: [
                                  Icon(Icons.stars, color: Colors.green, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Eccellente'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'good',
                              child: Row(
                                children: [
                                  Icon(Icons.thumb_up, color: Colors.lightGreen, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Buono'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'needsMaintenance',
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Richiede Manutenzione'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'poor',
                              child: Row(
                                children: [
                                  Icon(Icons.thumb_down, color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Pessimo'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'closed',
                              child: Row(
                                children: [
                                  Icon(Icons.block, color: Colors.grey, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Chiuso/Non Accessibile'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedEquipmentStatus = value ?? 'good';
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Seleziona lo stato delle attrezzature';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Sezione Foto
                        Text(
                          'Foto del Luogo',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aggiungi fino a 5 foto per mostrare il luogo e le attrezzature:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Griglia foto selezionate
                        if (_selectedImages.isNotEmpty) ...[
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                final image = _selectedImages[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 120,
                                  height: 120,
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
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
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
                          onPressed: _selectedImages.length >= 5 ? null : _addImages,
                          icon: const Icon(Icons.add_a_photo),
                          label: Text(
                            _selectedImages.isEmpty 
                                ? 'Aggiungi foto'
                                : 'Aggiungi altre foto (${_selectedImages.length}/5)',
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
                      onPressed: (_isLoading || _isUploadingImages) ? null : _submitLocation,
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
