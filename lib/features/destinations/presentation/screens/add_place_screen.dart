import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/place.dart';
import '../../data/services/firestore_place_service.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key, this.placeService, this.firebaseAuth});

  final FirestorePlaceService? placeService;
  final FirebaseAuth? firebaseAuth;

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late final FirestorePlaceService _placeService;
  late final FirebaseAuth _firebaseAuth;

  String _selectedCategory = 'Camping';

  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  static const List<String> _categories = [
    'Camping',
    'Parking',
    'Wild camping',
    'Camper service',
    'Fishing',
    'Hiking',
    'Boat rental',
    'Viewpoint',
    'Water point',
    'Photo spot',
    'Drone spot',
    'Wildlife',
  ];

  @override
  void initState() {
    super.initState();

    _placeService = widget.placeService ?? FirestorePlaceService();
    _firebaseAuth = widget.firebaseAuth ?? FirebaseAuth.instance;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _validateLatitude(String? value) {
    final normalizedValue = value?.trim().replaceAll(',', '.') ?? '';
    final latitude = double.tryParse(normalizedValue);

    if (normalizedValue.isEmpty) {
      return 'Enter latitude.';
    }

    if (latitude == null) {
      return 'Enter a valid latitude.';
    }

    if (latitude < -90 || latitude > 90) {
      return 'Latitude must be between -90 and 90.';
    }

    return null;
  }

  String? _validateLongitude(String? value) {
    final normalizedValue = value?.trim().replaceAll(',', '.') ?? '';
    final longitude = double.tryParse(normalizedValue);

    if (normalizedValue.isEmpty) {
      return 'Enter longitude.';
    }

    if (longitude == null) {
      return 'Enter a valid longitude.';
    }

    if (longitude < -180 || longitude > 180) {
      return 'Longitude must be between -180 and 180.';
    }

    return null;
  }

  double _parseCoordinate(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation || _isSubmitting) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await _determinePosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });

      _showMessage('Current location added.');
    } on _LocationException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Location could not be detected. Try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const _LocationException(
        'Turn on location services and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const _LocationException('Location permission is required.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const _LocationException(
        'Allow location access in your device settings.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();

      if (lastKnownPosition != null) {
        return lastKnownPosition;
      }

      throw const _LocationException('Location could not be detected.');
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isGettingLocation) {
      return;
    }

    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final user = _firebaseAuth.currentUser;

    if (user == null) {
      _showMessage('Your session has expired. Sign in again.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final displayName = (user.displayName ?? '').trim();
      final email = (user.email ?? '').trim();

      final draft = PlaceDraft(
        name: _nameController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        locationName: _locationNameController.text,
        latitude: _parseCoordinate(_latitudeController.text),
        longitude: _parseCoordinate(_longitudeController.text),
        createdByUserId: user.uid,
        createdByDisplayName: displayName.isEmpty ? 'Traveler' : displayName,
        createdByEmail: email,
      );

      final placeId = await _placeService.createPlace(draft);

      if (!mounted) {
        return;
      }

      await _showSuccessDialog(placeId);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on PlaceServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('The place could not be submitted. Check your connection.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog(String placeId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 44,
          ),
          title: const Text('Place submitted'),
          content: Text(
            'Your place was saved with reference $placeId. '
            'It will become visible after moderation.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSubmitting || _isGettingLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add a place'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AddPlaceHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    _FormLabel(
                      label: 'Place name',
                      child: TextFormField(
                        controller: _nameController,
                        enabled: !isBusy,
                        validator: _validateRequired,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Example: Fjordside camper stop',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FormLabel(
                      label: 'Category',
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: isBusy
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FormLabel(
                      label: 'Location name',
                      child: TextFormField(
                        controller: _locationNameController,
                        enabled: !isBusy,
                        validator: _validateRequired,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Town, region or nearby landmark',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CoordinatesSection(
                      latitudeController: _latitudeController,
                      longitudeController: _longitudeController,
                      latitudeValidator: _validateLatitude,
                      longitudeValidator: _validateLongitude,
                      enabled: !isBusy,
                      isGettingLocation: _isGettingLocation,
                      onUseCurrentLocation: _useCurrentLocation,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FormLabel(
                      label: 'Description',
                      child: TextFormField(
                        controller: _descriptionController,
                        enabled: !isBusy,
                        validator: _validateRequired,
                        minLines: 5,
                        maxLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText:
                              'Describe access, facilities, rules, terrain '
                              'and important safety information.',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _ModerationNotice(),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isBusy ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _isSubmitting ? 'Submitting...' : 'Submit place',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoordinatesSection extends StatelessWidget {
  const _CoordinatesSection({
    required this.latitudeController,
    required this.longitudeController,
    required this.latitudeValidator,
    required this.longitudeValidator,
    required this.enabled,
    required this.isGettingLocation,
    required this.onUseCurrentLocation,
  });

  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final FormFieldValidator<String> latitudeValidator;
  final FormFieldValidator<String> longitudeValidator;
  final bool enabled;
  final bool isGettingLocation;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 21,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Coordinates',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: latitudeController,
                  enabled: enabled,
                  validator: latitudeValidator,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '68.7983',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  controller: longitudeController,
                  enabled: enabled,
                  validator: longitudeValidator,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '16.5417',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: enabled ? onUseCurrentLocation : null,
              icon: isGettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                isGettingLocation
                    ? 'Detecting location...'
                    : 'Use my current location',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPlaceHeader extends StatelessWidget {
  const _AddPlaceHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.add_location_alt_outlined,
            color: AppColors.primary,
            size: 32,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share an outdoor place',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Add accurate information so other travelers can visit '
                  'responsibly and safely.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationNotice extends StatelessWidget {
  const _ModerationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 21,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'New places are reviewed before publication. Do not submit '
              'private property, unsafe locations or misleading information.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _LocationException implements Exception {
  const _LocationException(this.message);

  final String message;
}
