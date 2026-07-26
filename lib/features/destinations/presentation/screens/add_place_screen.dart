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
  static const List<String> _placeTypes = [
    'Camping',
    'Picnic area',
    'Free motorhome area',
    'Paying motorhome area',
    'Private car park for campers',
    'Parking day/night',
  ];

  static const List<_SelectableOption> _services = [
    _SelectableOption(
      value: 'Electricity',
      icon: Icons.electrical_services_rounded,
    ),
    _SelectableOption(value: 'Drinking water', icon: Icons.water_drop_rounded),
    _SelectableOption(value: 'Toilets', icon: Icons.wc_rounded),
    _SelectableOption(value: 'Showers', icon: Icons.shower_rounded),
    _SelectableOption(
      value: 'Laundry',
      icon: Icons.local_laundry_service_rounded,
    ),
    _SelectableOption(
      value: 'Washing for motorhomes',
      icon: Icons.local_car_wash_rounded,
    ),
    _SelectableOption(value: 'Boat rental', icon: Icons.sailing_rounded),
    _SelectableOption(
      value: 'Camper rental',
      icon: Icons.airport_shuttle_rounded,
    ),
  ];

  static const List<_SelectableOption> _activities = [
    _SelectableOption(value: 'Swimming', icon: Icons.pool_rounded),
    _SelectableOption(value: 'Wildlife', icon: Icons.pets_rounded),
    _SelectableOption(value: 'Fishing', icon: Icons.phishing_rounded),
    _SelectableOption(
      value: 'Viewpoint',
      label: 'View spots',
      icon: Icons.landscape_rounded,
    ),
    _SelectableOption(
      value: 'Canoe/kayak',
      label: 'Canoe / kayak',
      icon: Icons.kayaking_rounded,
    ),
    _SelectableOption(
      value: 'Mountain bike tracks',
      icon: Icons.pedal_bike_rounded,
    ),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late final FirestorePlaceService _placeService;
  late final FirebaseAuth _firebaseAuth;

  String _selectedPlaceType = _placeTypes.first;

  final Set<String> _selectedServices = <String>{};
  final Set<String> _selectedActivities = <String>{};

  bool _isSubmitting = false;
  bool _isGettingLocation = false;

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

  void _toggleService(String service) {
    if (_isSubmitting || _isGettingLocation) {
      return;
    }

    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  void _toggleActivity(String activity) {
    if (_isSubmitting || _isGettingLocation) {
      return;
    }

    setState(() {
      if (_selectedActivities.contains(activity)) {
        _selectedActivities.remove(activity);
      } else {
        _selectedActivities.add(activity);
      }
    });
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
    } catch (error) {
      debugPrint('Location error: $error');
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
    } catch (error) {
      debugPrint('Current position error: $error');

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
      final firebaseDisplayName = (user.displayName ?? '').trim();
      final email = (user.email ?? '').trim();

      final draft = PlaceDraft(
        name: _nameController.text,
        description: _descriptionController.text,
        locationName: _locationNameController.text,
        latitude: _parseCoordinate(_latitudeController.text),
        longitude: _parseCoordinate(_longitudeController.text),
        createdByUserId: user.uid,
        createdByDisplayName: firebaseDisplayName.isEmpty
            ? 'Traveler'
            : firebaseDisplayName,
        createdByEmail: email,

        // Старое поле сохраняется для совместимости.
        category: _selectedPlaceType,

        // Новая структура Firestore.
        placeType: _selectedPlaceType,
        services: _selectedServices.toList(growable: false),
        activities: _selectedActivities.toList(growable: false),
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
    } catch (error, stackTrace) {
      debugPrint('Place submission error: $error');
      debugPrintStack(stackTrace: stackTrace);

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
                      label: 'Place type',
                      helperText:
                          'Choose the main type that best describes this place.',
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPlaceType,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _placeTypes
                            .map((placeType) {
                              return DropdownMenuItem<String>(
                                value: placeType,
                                child: Text(placeType),
                              );
                            })
                            .toList(growable: false),
                        onChanged: isBusy
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _selectedPlaceType = value;
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

                    const SizedBox(height: AppSpacing.xl),

                    _SelectionSection(
                      title: 'Services',
                      description:
                          'Select every service that is available at this place.',
                      selectedCount: _selectedServices.length,
                      options: _services,
                      selectedValues: _selectedServices,
                      enabled: !isBusy,
                      onOptionPressed: _toggleService,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _SelectionSection(
                      title: 'Activities',
                      description:
                          'Select the activities available at or near this place.',
                      selectedCount: _selectedActivities.length,
                      options: _activities,
                      selectedValues: _selectedActivities,
                      enabled: !isBusy,
                      onOptionPressed: _toggleActivity,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _FormLabel(
                      label: 'Description',
                      helperText:
                          'Include access, restrictions, terrain and safety information.',
                      child: TextFormField(
                        controller: _descriptionController,
                        enabled: !isBusy,
                        validator: _validateRequired,
                        minLines: 5,
                        maxLines: 9,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText:
                              'Describe the place, road access, facilities, '
                              'rules and anything travelers should know.',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const _SubmissionSummary(),

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

class _SelectionSection extends StatelessWidget {
  const _SelectionSection({
    required this.title,
    required this.description,
    required this.selectedCount,
    required this.options,
    required this.selectedValues,
    required this.enabled,
    required this.onOptionPressed,
  });

  final String title;
  final String description;
  final int selectedCount;
  final List<_SelectableOption> options;
  final Set<String> selectedValues;
  final bool enabled;
  final ValueChanged<String> onOptionPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: selectedCount == 0
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(selectedCount),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$selectedCount selected',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: options
                .map((option) {
                  final selected = selectedValues.contains(option.value);

                  return _SelectableChip(
                    option: option,
                    selected: selected,
                    enabled: enabled,
                    onTap: () {
                      onOptionPressed(option.value);
                    },
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final _SelectableOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : enabled
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 7),
              Text(
                option.label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : enabled
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 7),
                const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ],
            ],
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
          const SizedBox(height: 5),
          const Text(
            'Use your current position or enter exact coordinates manually.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
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
                  'Choose the main place type, available services and '
                  'activities so travelers can find it through map filters.',
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

class _SubmissionSummary extends StatelessWidget {
  const _SubmissionSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 21),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Services and activities are optional. Only select options '
              'that are genuinely available at this location.',
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
  const _FormLabel({required this.label, required this.child, this.helperText});

  final String label;
  final String? helperText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final description = helperText;

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
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _SelectableOption {
  const _SelectableOption({
    required this.value,
    required this.icon,
    String? label,
  }) : label = label ?? value;

  final String value;
  final String label;
  final IconData icon;
}

class _LocationException implements Exception {
  const _LocationException(this.message);

  final String message;
}
