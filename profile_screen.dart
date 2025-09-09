import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitspot/models/app_user.dart';
import 'package:fitspot/data/sample_data.dart';
import 'package:fitspot/screens/admin_screen.dart';
import 'package:fitspot/firestore/firebase_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
    
    // Se l'utente è autenticato, usa i dati Firebase
    if (firebaseProvider.isAuthenticated && firebaseProvider.userDocument != null) {
      try {
        final userDoc = firebaseProvider.userDocument!;
        final appUser = AppUser(
          id: userDoc.id,
          name: userDoc.name,
          email: userDoc.email,
          profileImageUrl: userDoc.profileImageUrl,
          joinedAt: userDoc.createdAt,
          role: userDoc.isAdmin ? UserRole.admin : UserRole.user,
          stats: UserStats(
            totalWorkouts: 0,
            totalWorkoutTime: Duration.zero,
          ),
        );
        setState(() {
          _currentUser = appUser;
        });
        return;
      } catch (e) {
        // In caso di errore, continua con profilo ospite
      }
    }
    
    // Se non autenticato, crea profilo ospite
    setState(() {
      _currentUser = AppUser(
        id: 'guest',
        name: 'Ospite',
        email: 'ospite@fitspot.com',
        profileImageUrl: null,
        joinedAt: DateTime.now(),
        role: UserRole.user,
        stats: UserStats(
          totalWorkouts: 0,
          totalWorkoutTime: Duration.zero,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseProvider>(
      builder: (context, firebaseProvider, child) {
        // Aggiorna automaticamente il profilo quando cambia lo stato di autenticazione
        AppUser currentUser;
        
        if (firebaseProvider.isAuthenticated && firebaseProvider.userDocument != null) {
          // Se autenticato, usa i dati Firebase
          final userDoc = firebaseProvider.userDocument!;
          final isAdmin = (userDoc.email == 'admin@fitspot.com' || userDoc.isAdmin);
          print('User email: ${userDoc.email}');
          print('Is admin in document: ${userDoc.isAdmin}');
          print('Is admin calculated: $isAdmin');
          
          currentUser = AppUser(
            id: userDoc.id,
            name: userDoc.name,
            email: userDoc.email,
            profileImageUrl: userDoc.profileImageUrl,
            joinedAt: userDoc.createdAt,
            role: isAdmin ? UserRole.admin : UserRole.user,
            stats: UserStats(
              totalWorkouts: 0,
              totalWorkoutTime: Duration.zero,
            ),
          );
        } else {
          // Se non autenticato, crea profilo ospite
          currentUser = AppUser(
            id: 'guest',
            name: 'Ospite',
            email: 'ospite@fitspot.com',
            profileImageUrl: null,
            joinedAt: DateTime.now(),
            role: UserRole.user,
            stats: UserStats(
              totalWorkouts: 0,
              totalWorkoutTime: Duration.zero,
            ),
          );
        }
        
        _currentUser = currentUser;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profilo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showSettings,
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(currentUser),
                _buildStats(currentUser),
                _buildMenuItems(currentUser),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(AppUser currentUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: currentUser.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      currentUser.profileImageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    currentUser.name.substring(0, 2).toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            currentUser.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentUser.email,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: currentUser.role == UserRole.admin
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  currentUser.role.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: currentUser.role == UserRole.admin
                        ? Theme.of(context).colorScheme.onTertiary
                        : Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (currentUser.name == 'Ospite')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_off,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ospite',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Membro dal ${currentUser.joinedAt.day}/${currentUser.joinedAt.month}/${currentUser.joinedAt.year}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AppUser currentUser) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le Tue Statistiche',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.fitness_center,
                      title: 'Allenamenti',
                      value: currentUser.stats.totalWorkouts.toString(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.schedule,
                      title: 'Ore totali',
                      value: '${currentUser.stats.totalWorkoutTime.inHours}h',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.place,
                      title: 'Luoghi visitati',
                      value: currentUser.stats.locationsVisited.toString(),
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.rate_review,
                      title: 'Recensioni',
                      value: currentUser.stats.reviewsWritten.toString(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItems(AppUser currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Guest user registration prompt
          if (currentUser.name == 'Ospite') ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea il tuo account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Registrati per salvare i tuoi allenamenti e recensioni',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed('/auth'),
                    child: const Text('Registrati ora'),
                  ),
                ],
              ),
            ),
          ],
          
          if (currentUser.role == UserRole.admin) ...[
            _MenuItem(
              icon: Icons.admin_panel_settings,
              title: 'Pannello Admin',
              subtitle: 'Gestisci luoghi e recensioni',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminScreen()),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _MenuItem(
            icon: Icons.edit,
            title: 'Modifica Profilo',
            subtitle: 'Aggiorna le tue informazioni',
            onTap: _editProfile,
          ),
          const SizedBox(height: 8),
          _MenuItem(
            icon: Icons.notifications,
            title: 'Notifiche',
            subtitle: 'Gestisci le notifiche',
            onTap: _manageNotifications,
          ),
          const SizedBox(height: 8),
          _MenuItem(
            icon: Icons.privacy_tip,
            title: 'Privacy e Sicurezza',
            subtitle: 'Impostazioni privacy',
            onTap: _privacySettings,
          ),
          const SizedBox(height: 8),
          _MenuItem(
            icon: Icons.help,
            title: 'Aiuto e Supporto',
            subtitle: 'FAQ e contatti',
            onTap: _showHelp,
          ),
          const SizedBox(height: 8),
          _MenuItem(
            icon: Icons.info,
            title: 'Info App',
            subtitle: 'Versione e informazioni',
            onTap: _showAppInfo,
          ),
          // Mostra il pulsante Esci solo se non è un utente ospite
          if (currentUser.name != 'Ospite') ...[
            const SizedBox(height: 8),
            _MenuItem(
              icon: Icons.logout,
              title: 'Esci',
              subtitle: 'Disconnettiti dall\'app',
              onTap: _logout,
              isDestructive: true,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impostazioni'),
        content: const Text('Le impostazioni saranno disponibili nella versione completa dell\'app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    if (_currentUser == null) return;
    
    showDialog(
      context: context,
      builder: (context) => _EditProfileDialog(
        currentUser: _currentUser!,
        onProfileUpdated: () {
          _loadUserProfile();
        },
      ),
    );
  }

  void _manageNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifiche'),
        content: const Text('La gestione delle notifiche sarà disponibile nella versione completa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _privacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy'),
        content: const Text('Le impostazioni privacy saranno disponibili nella versione completa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aiuto'),
        content: const Text('Per supporto, contatta: support@girolibero.it'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showAboutDialog(
      context: context,
      applicationName: 'FitSpot',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 FitSpot. Tutti i diritti riservati.',
      children: [
        const Text('App per il fitness all\'aperto e la condivisione di luoghi di allenamento.'),
      ],
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Logout'),
        content: const Text('Sei sicuro di voler uscire dall\'app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Effettua il logout usando FirebaseProvider
              final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
              await firebaseProvider.signOut();
              
              // Ricarica il profilo per mostrare lo stato ospite
              _loadUserProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final AppUser currentUser;
  final VoidCallback onProfileUpdated;

  const _EditProfileDialog({
    required this.currentUser,
    required this.onProfileUpdated,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentUser.name;
    _emailController.text = widget.currentUser.email;
    // AppUser non ha un campo bio, quindi lasciamo vuoto
    _bioController.text = '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      
      if (!firebaseProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devi essere autenticato per modificare il profilo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Aggiorna il profilo Firebase Auth
      await firebaseProvider.updateProfile({
        'displayName': _nameController.text.trim(),
      });
      
      widget.onProfileUpdated();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilo aggiornato con successo!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'aggiornamento: $e'),
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
                  'Modifica Profilo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            hintText: 'Il tuo nome completo',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci il tuo nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'La tua email',
                          ),
                          readOnly: true, // L'email non può essere cambiata facilmente in Firebase Auth
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci la tua email';
                            }
                            if (!value.contains('@')) {
                              return 'Inserisci una email valida';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio (opzionale)',
                            hintText: 'Racconta qualcosa di te...',
                          ),
                          maxLines: 3,
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
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salva'),
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Theme.of(context).colorScheme.error : null;

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onTap: onTap,
      ),
    );
  }
}