// lib/features/map/presentation/screens/route_map_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/services/open_route_service.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({
    super.key,
    required this.destinationTitle,
    required this.location,
    required this.distance,
    required this.duration,
  });

  final String destinationTitle;
  final String location;
  final String distance;
  final String duration;

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen>
    with TickerProviderStateMixin {
  static const String _osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String _userAgentPackageName = 'com.projectnorth.app';

  final MapController _mapController = MapController();
  final OpenRouteService _routeService = OpenRouteService();

  late final AnimationController _routeAnimationController;
  late final AnimationController _navigationController;

  late final Animation<double> _routeAnimation;
  late final Animation<double> _summaryAnimation;

  StreamSubscription<Position>? _positionSubscription;

  Position? _currentPosition;
  RouteResult? _routeResult;

  String? _locationError;
  String? _routeError;

  bool _isLoadingLocation = false;
  bool _isLoadingRoute = false;
  bool _isNavigating = false;
  bool _isFollowingUser = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();

    _routeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _navigationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _routeAnimation = CurvedAnimation(
      parent: _routeAnimationController,
      curve: const Interval(0, 0.78, curve: Curves.easeInOutCubic),
    );

    _summaryAnimation = CurvedAnimation(
      parent: _routeAnimationController,
      curve: const Interval(0.58, 1, curve: Curves.easeOutCubic),
    );

    _navigationController.addStatusListener(_handleNavigationStatus);
    _routeAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocationAndRoute();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _navigationController.removeStatusListener(_handleNavigationStatus);
    _routeAnimationController.dispose();
    _navigationController.dispose();
    _routeService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handleNavigationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    setState(() {
      _isNavigating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You have arrived at ${widget.destinationTitle}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _initializeLocationAndRoute() async {
    await _initializeLocation();

    if (!mounted) {
      return;
    }

    await _loadRealRoute();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _determinePosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      await _startLocationUpdates();
    } on _LocationException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationError = error.message;
        _isLoadingLocation = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationError = 'Unable to get your current location.';
        _isLoadingLocation = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const _LocationException(
        'Location services are disabled. Turn on GPS and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const _LocationException('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const _LocationException(
        'Location permission is permanently denied. Open settings to enable it.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<void> _startLocationUpdates() async {
    await _positionSubscription?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (position) {
            if (!mounted) {
              return;
            }

            setState(() {
              _currentPosition = position;
              _locationError = null;
            });

            if (_isFollowingUser && _isMapReady) {
              _mapController.move(
                LatLng(position.latitude, position.longitude),
                16,
              );
            }
          },
          onError: (_) {
            if (!mounted) {
              return;
            }

            setState(() {
              _locationError = 'Live location updates are unavailable.';
            });
          },
        );
  }

  Future<void> _loadRealRoute() async {
    if (_isLoadingRoute) {
      return;
    }

    final destination = _DestinationRouteData.forDestination(
      widget.destinationTitle,
    );

    final currentPosition = _currentPosition;

    if (destination.usesCurrentLocation && currentPosition == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _routeError = 'Current location is required for this driving route.';
      });

      return;
    }

    final routeStart = destination.usesCurrentLocation
        ? LatLng(currentPosition!.latitude, currentPosition.longitude)
        : destination.start;

    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
    });

    try {
      final result = await _routeService.buildRoute(
        start: routeStart,
        destination: destination.destination,
        profile: destination.profile,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _routeResult = result;
        _isLoadingRoute = false;
        _isFollowingUser = false;
      });

      _routeAnimationController
        ..reset()
        ..forward();

      _fitRoute(result.points);
    } on OpenRouteServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _routeError = error.message;
        _isLoadingRoute = false;
      });

      _fitCurrentRoute();
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      setState(() {
        _routeError = 'Routing request timed out. Check your connection.';
        _isLoadingRoute = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _routeError = 'Unable to build the real route.';
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _retryEverything() async {
    if (_currentPosition == null) {
      await _initializeLocation();
    }

    if (!mounted) {
      return;
    }

    await _loadRealRoute();
  }

  Future<void> _moveToCurrentLocation() async {
    if (_currentPosition == null) {
      await _initializeLocation();
    }

    final position = _currentPosition;

    if (position == null || !mounted || !_isMapReady) {
      return;
    }

    setState(() {
      _isFollowingUser = true;
    });

    _mapController.move(LatLng(position.latitude, position.longitude), 16);
  }

  Future<void> _openLocationSettings() async {
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    await Geolocator.openLocationSettings();
  }

  void _restartRouteAnimation() {
    if (_isNavigating) {
      return;
    }

    setState(() {
      _isFollowingUser = false;
    });

    _fitCurrentRoute();

    _routeAnimationController
      ..reset()
      ..forward();
  }

  void _fitCurrentRoute() {
    final points = _activeRoutePoints;

    if (points.length >= 2) {
      _fitRoute(points);
    }
  }

  void _fitRoute(List<LatLng> points) {
    if (!_isMapReady || points.length < 2) {
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(48, 130, 48, 330),
      ),
    );
  }

  void _startNavigation() {
    final points = _activeRoutePoints;

    if (points.length < 2) {
      return;
    }

    setState(() {
      _isNavigating = true;
      _isFollowingUser = false;
    });

    _fitRoute(points);
    _routeAnimationController.value = 1;

    _navigationController
      ..reset()
      ..forward();
  }

  void _stopNavigation() {
    _navigationController.stop();

    setState(() {
      _isNavigating = false;
    });
  }

  void _pauseOrResumeNavigation() {
    if (_navigationController.isAnimating) {
      _navigationController.stop();
    } else {
      _navigationController.forward();
    }

    setState(() {});
  }

  _DestinationRouteData get _destinationData {
    return _DestinationRouteData.forDestination(widget.destinationTitle);
  }

  List<LatLng> get _activeRoutePoints {
    final realPoints = _routeResult?.points;

    if (realPoints != null && realPoints.length >= 2) {
      return realPoints;
    }

    return _destinationData.fallbackPoints;
  }

  double get _displayDistanceKm {
    return _routeResult?.distanceKilometers ??
        _destinationData.fallbackDistanceKm;
  }

  Duration get _displayDuration {
    return _routeResult?.duration ??
        Duration(minutes: _destinationData.fallbackDurationMinutes);
  }

  _NavigationInstructionView _instructionForProgress(double progress) {
    final liveStep = _routeResult?.stepForProgress(progress);

    if (liveStep != null) {
      return _NavigationInstructionView(
        distance: liveStep.formattedDistance,
        title: liveStep.instruction,
        subtitle: liveStep.streetName.isNotEmpty
            ? liveStep.streetName
            : _formatStepDuration(liveStep.duration),
        icon: _iconForInstructionType(liveStep.type),
        isLive: true,
      );
    }

    final fallback = _destinationData.instructionForProgress(progress);

    return _NavigationInstructionView(
      distance: fallback.distance,
      title: fallback.title,
      subtitle: fallback.subtitle,
      icon: fallback.icon,
      isLive: false,
    );
  }

  IconData _iconForInstructionType(int type) {
    switch (type) {
      case RouteInstructionType.turnLeft:
        return Icons.turn_left_rounded;

      case RouteInstructionType.turnRight:
        return Icons.turn_right_rounded;

      case RouteInstructionType.turnSharpLeft:
        return Icons.turn_sharp_left_rounded;

      case RouteInstructionType.turnSharpRight:
        return Icons.turn_sharp_right_rounded;

      case RouteInstructionType.turnSlightLeft:
        return Icons.turn_slight_left_rounded;

      case RouteInstructionType.turnSlightRight:
        return Icons.turn_slight_right_rounded;

      case RouteInstructionType.enterRoundabout:
      case RouteInstructionType.exitRoundabout:
        return Icons.roundabout_left_rounded;

      case RouteInstructionType.uTurn:
        return Icons.u_turn_left_rounded;

      case RouteInstructionType.destinationReached:
        return Icons.flag_rounded;

      case RouteInstructionType.depart:
        return Icons.navigation_rounded;

      case RouteInstructionType.keepLeft:
        return Icons.fork_left_rounded;

      case RouteInstructionType.keepRight:
        return Icons.fork_right_rounded;

      case RouteInstructionType.continueStraight:
      default:
        return Icons.straight_rounded;
    }
  }

  List<LatLng> _visibleRoutePoints(List<LatLng> points, double progress) {
    if (points.length < 2) {
      return points;
    }

    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final exactIndex = clampedProgress * (points.length - 1);
    final completedIndex = exactIndex.floor();
    final segmentProgress = exactIndex - completedIndex;

    final result = <LatLng>[...points.take(completedIndex + 1)];

    if (completedIndex < points.length - 1) {
      final start = points[completedIndex];
      final end = points[completedIndex + 1];

      result.add(
        LatLng(
          start.latitude + ((end.latitude - start.latitude) * segmentProgress),
          start.longitude +
              ((end.longitude - start.longitude) * segmentProgress),
        ),
      );
    }

    return result;
  }

  LatLng _positionOnRoute(List<LatLng> points, double progress) {
    if (points.isEmpty) {
      return const LatLng(0, 0);
    }

    if (points.length == 1) {
      return points.first;
    }

    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final exactIndex = clampedProgress * (points.length - 1);
    final startIndex = exactIndex.floor().clamp(0, points.length - 2);
    final localProgress = exactIndex - startIndex;

    final start = points[startIndex];
    final end = points[startIndex + 1];

    return LatLng(
      start.latitude + ((end.latitude - start.latitude) * localProgress),
      start.longitude + ((end.longitude - start.longitude) * localProgress),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '$minutes min';
    }

    if (minutes == 0) {
      return '$hours h';
    }

    return '$hours h $minutes min';
  }

  String _formatStepDuration(Duration duration) {
    if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} min';
    }

    return '${math.max(1, duration.inSeconds)} sec';
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destinationData;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _routeAnimationController,
          _navigationController,
        ]),
        builder: (context, _) {
          final routePoints = _activeRoutePoints;

          final routeProgress = _isNavigating ? 1.0 : _routeAnimation.value;

          final visibleRoute = _visibleRoutePoints(routePoints, routeProgress);

          final navigationProgress = _navigationController.value;

          final simulatedPosition = _isNavigating
              ? _positionOnRoute(routePoints, navigationProgress)
              : null;

          final navigationInstruction = _instructionForProgress(
            navigationProgress,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: destination.center,
                    initialZoom: destination.initialZoom,
                    minZoom: 3,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady: () {
                      _isMapReady = true;
                      _fitCurrentRoute();
                    },
                    onPositionChanged: (_, hasGesture) {
                      if (hasGesture && _isFollowingUser) {
                        setState(() {
                          _isFollowingUser = false;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _osmTileUrl,
                      userAgentPackageName: _userAgentPackageName,
                      maxNativeZoom: 19,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 11,
                          color: const Color(0x336D4AFF),
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                        if (visibleRoute.length >= 2)
                          Polyline(
                            points: visibleRoute,
                            strokeWidth: 6,
                            color: const Color(0xFF6D4AFF),
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: routePoints.first,
                          width: 42,
                          height: 42,
                          child: const _RouteMarker(
                            icon: Icons.trip_origin_rounded,
                            isDestination: false,
                          ),
                        ),
                        Marker(
                          point: routePoints.last,
                          width: 48,
                          height: 48,
                          child: const _RouteMarker(
                            icon: Icons.flag_rounded,
                            isDestination: true,
                          ),
                        ),
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            width: 54,
                            height: 54,
                            child: const _CurrentLocationMarker(),
                          ),
                        if (simulatedPosition != null)
                          Marker(
                            point: simulatedPosition,
                            width: 54,
                            height: 54,
                            child: const _NavigationMarker(),
                          ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: const [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: _isNavigating
                            ? _NavigationInstructionCard(
                                key: ValueKey(
                                  '${navigationInstruction.title}-'
                                  '${navigationInstruction.distance}',
                                ),
                                instruction: navigationInstruction,
                              )
                            : _MapTopBar(
                                key: const ValueKey('map-top-bar'),
                                destinationTitle: widget.destinationTitle,
                                isRealRoute: _routeResult != null,
                                isLoadingRoute: _isLoadingRoute,
                                onBackPressed: () {
                                  Navigator.of(context).maybePop();
                                },
                                onReplayPressed: _restartRouteAnimation,
                              ),
                      ),
                      if (_locationError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _ErrorCard(
                          message: _locationError!,
                          icon: Icons.location_off_outlined,
                          onRetryPressed: _retryEverything,
                          onSettingsPressed: _openLocationSettings,
                        ),
                      ],
                      if (_routeError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _ErrorCard(
                          message:
                              'Real route unavailable. Demo route is shown.\n'
                              '$_routeError',
                          icon: Icons.route_outlined,
                          onRetryPressed: _loadRealRoute,
                        ),
                      ],
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          children: [
                            _FloatingMapButton(
                              icon: _isFollowingUser
                                  ? Icons.my_location_rounded
                                  : Icons.location_searching_rounded,
                              isLoading: _isLoadingLocation,
                              tooltip: 'My location',
                              onPressed: _isLoadingLocation
                                  ? null
                                  : _moveToCurrentLocation,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _FloatingMapButton(
                              icon: Icons.route_rounded,
                              tooltip: 'Show route',
                              onPressed: _fitCurrentRoute,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _FloatingMapButton(
                              icon: Icons.refresh_rounded,
                              isLoading: _isLoadingRoute,
                              tooltip: 'Reload route',
                              onPressed: _isLoadingRoute
                                  ? null
                                  : _loadRealRoute,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isNavigating
                            ? _NavigationPanel(
                                key: const ValueKey('navigation-panel'),
                                progress: navigationProgress,
                                distanceKm: _displayDistanceKm,
                                duration: _displayDuration,
                                speed: destination.speedForProgress(
                                  navigationProgress,
                                ),
                                isPaused:
                                    !_navigationController.isAnimating &&
                                    navigationProgress < 1,
                                onPauseResumePressed: _pauseOrResumeNavigation,
                                onStopPressed: _stopNavigation,
                              )
                            : FadeTransition(
                                key: const ValueKey('route-summary'),
                                opacity: _summaryAnimation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.12),
                                    end: Offset.zero,
                                  ).animate(_summaryAnimation),
                                  child: _RouteSummaryCard(
                                    destinationTitle: widget.destinationTitle,
                                    location: widget.location,
                                    distance:
                                        '${_displayDistanceKm.toStringAsFixed(1)} km',
                                    duration: _formatDuration(_displayDuration),
                                    routeLabel: destination.routeLabel,
                                    icon: destination.icon,
                                    isRealRoute: _routeResult != null,
                                    realStepCount:
                                        _routeResult?.steps.length ?? 0,
                                    isLoading: _isLoadingRoute,
                                    onBeginNavigationPressed: _startNavigation,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({
    super.key,
    required this.destinationTitle,
    required this.isRealRoute,
    required this.isLoadingRoute,
    required this.onBackPressed,
    required this.onReplayPressed,
  });

  final String destinationTitle;
  final bool isRealRoute;
  final bool isLoadingRoute;
  final VoidCallback onBackPressed;
  final VoidCallback onReplayPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MapIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: onBackPressed,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: _floatingDecoration(radius: 17),
            child: Row(
              children: [
                if (isLoadingRoute)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF6D4AFF),
                    ),
                  )
                else
                  Icon(
                    isRealRoute
                        ? Icons.cloud_done_outlined
                        : Icons.route_rounded,
                    size: 19,
                    color: const Color(0xFF6D4AFF),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    destinationTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _MapIconButton(icon: Icons.replay_rounded, onPressed: onReplayPressed),
      ],
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          width: 48,
          height: 48,
          decoration: _floatingDecoration(radius: 17),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final IconData? icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: Ink(
            width: 48,
            height: 48,
            decoration: _floatingDecoration(radius: 17),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Color(0xFF6D4AFF),
                      ),
                    )
                  : Icon(icon, size: 22, color: const Color(0xFF6D4AFF)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.icon,
    required this.onRetryPressed,
    this.onSettingsPressed,
  });

  final String message;
  final IconData icon;
  final VoidCallback onRetryPressed;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD7D9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE5484D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          TextButton(onPressed: onRetryPressed, child: const Text('Retry')),
          if (onSettingsPressed != null)
            IconButton(
              onPressed: onSettingsPressed,
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined, size: 20),
            ),
        ],
      ),
    );
  }
}

class _NavigationInstructionCard extends StatelessWidget {
  const _NavigationInstructionCard({super.key, required this.instruction});

  final _NavigationInstructionView instruction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40111727),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(instruction.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        instruction.distance,
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (instruction.isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  instruction.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  instruction.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12,
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

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.destinationTitle,
    required this.location,
    required this.distance,
    required this.duration,
    required this.routeLabel,
    required this.icon,
    required this.isRealRoute,
    required this.realStepCount,
    required this.isLoading,
    required this.onBeginNavigationPressed,
  });

  final String destinationTitle;
  final String location;
  final String distance;
  final String duration;
  final String routeLabel;
  final IconData icon;
  final bool isRealRoute;
  final int realStepCount;
  final bool isLoading;
  final VoidCallback onBeginNavigationPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _floatingDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEFF),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFDED7FF)),
                ),
                child: Icon(icon, color: const Color(0xFF6D4AFF), size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destinationTitle,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isRealRoute
                      ? const Color(0xFFECFDF3)
                      : const Color(0xFFFFF7E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isRealRoute
                      ? realStepCount > 0
                            ? '$realStepCount steps'
                            : 'Live route'
                      : 'Demo route',
                  style: TextStyle(
                    color: isRealRoute
                        ? const Color(0xFF027A48)
                        : const Color(0xFFB54708),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _RouteMetric(
                  label: 'Distance',
                  value: distance,
                  icon: Icons.route_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RouteMetric(
                  label: 'Duration',
                  value: duration,
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RouteMetric(
                  label: 'Route',
                  value: routeLabel,
                  icon: Icons.alt_route_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onBeginNavigationPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: const Color(0xFF98A2B3),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.navigation_rounded, size: 21),
              label: Text(
                isLoading ? 'Building route...' : 'Begin navigation',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    super.key,
    required this.progress,
    required this.distanceKm,
    required this.duration,
    required this.speed,
    required this.isPaused,
    required this.onPauseResumePressed,
    required this.onStopPressed,
  });

  final double progress;
  final double distanceKm;
  final Duration duration;
  final int speed;
  final bool isPaused;
  final VoidCallback onPauseResumePressed;
  final VoidCallback onStopPressed;

  @override
  Widget build(BuildContext context) {
    final remainingDistance = distanceKm * (1 - progress);

    final remainingMinutes = math.max(
      1,
      (duration.inMinutes * (1 - progress)).ceil(),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _floatingDecoration(radius: 26),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NavigationMetric(
                  label: 'Remaining',
                  value: '${remainingDistance.toStringAsFixed(1)} km',
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _NavigationMetric(
                  label: 'Arrival',
                  value: '$remainingMinutes min',
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _NavigationMetric(label: 'Speed', value: '$speed km/h'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFEEEAFD),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6D4AFF),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: onPauseResumePressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: Color(0xFFE1E6ED)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    ),
                    label: Text(
                      isPaused ? 'Resume' : 'Pause',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onStopPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF1F2),
                      foregroundColor: const Color(0xFFE5484D),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text(
                      'End route',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFFE8ECF1));
  }
}

class _NavigationMetric extends StatelessWidget {
  const _NavigationMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF0F4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6D4AFF)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({required this.icon, required this.isDestination});

  final IconData icon;
  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6D4AFF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x556D4AFF),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, size: isDestination ? 21 : 17, color: Colors.white),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x332563EB),
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(color: Color(0x552563EB), blurRadius: 12),
          ],
        ),
      ),
    );
  }
}

class _NavigationMarker extends StatelessWidget {
  const _NavigationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x406D4AFF),
      ),
      padding: const EdgeInsets.all(9),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6D4AFF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: const Icon(
          Icons.navigation_rounded,
          color: Colors.white,
          size: 19,
        ),
      ),
    );
  }
}

class _DestinationRouteData {
  const _DestinationRouteData({
    required this.routeLabel,
    required this.icon,
    required this.center,
    required this.initialZoom,
    required this.start,
    required this.destination,
    required this.profile,
    required this.fallbackPoints,
    required this.fallbackDistanceKm,
    required this.fallbackDurationMinutes,
    required this.instructions,
    required this.isDriving,
    required this.usesCurrentLocation,
  });

  final String routeLabel;
  final IconData icon;
  final LatLng center;
  final double initialZoom;
  final LatLng start;
  final LatLng destination;
  final RouteProfile profile;
  final List<LatLng> fallbackPoints;
  final double fallbackDistanceKm;
  final int fallbackDurationMinutes;
  final List<_FallbackNavigationInstruction> instructions;
  final bool isDriving;
  final bool usesCurrentLocation;

  factory _DestinationRouteData.forDestination(String title) {
    final normalized = title.toLowerCase();

    if (normalized.contains('trolltunga')) {
      return const _DestinationRouteData(
        routeLabel: 'Mountain',
        icon: Icons.hiking_rounded,
        center: LatLng(60.1278, 6.6825),
        initialZoom: 12.5,
        start: LatLng(60.1324, 6.6258),
        destination: LatLng(60.1249, 6.7404),
        profile: RouteProfile.footHiking,
        fallbackDistanceKm: 18,
        fallbackDurationMinutes: 540,
        isDriving: false,
        usesCurrentLocation: false,
        fallbackPoints: [
          LatLng(60.1324, 6.6258),
          LatLng(60.1287, 6.6460),
          LatLng(60.1228, 6.6684),
          LatLng(60.1186, 6.6902),
          LatLng(60.1212, 6.7135),
          LatLng(60.1249, 6.7404),
        ],
        instructions: [
          _FallbackNavigationInstruction(
            progress: 0,
            distance: '300 m',
            title: 'Continue on the main trail',
            subtitle: 'Skjeggedal trailhead',
            icon: Icons.straight_rounded,
          ),
          _FallbackNavigationInstruction(
            progress: 0.25,
            distance: '1.8 km',
            title: 'Keep left at the trail junction',
            subtitle: 'Mountain plateau',
            icon: Icons.turn_slight_left_rounded,
          ),
          _FallbackNavigationInstruction(
            progress: 0.55,
            distance: '2.4 km',
            title: 'Continue across the plateau',
            subtitle: 'Follow the trail markers',
            icon: Icons.straight_rounded,
          ),
          _FallbackNavigationInstruction(
            progress: 0.82,
            distance: '700 m',
            title: 'Approach Trolltunga viewpoint',
            subtitle: 'Final rocky section',
            icon: Icons.turn_slight_right_rounded,
          ),
        ],
      );
    }

    if (normalized.contains('senja')) {
      return const _DestinationRouteData(
        routeLabel: 'Scenic',
        icon: Icons.directions_car_rounded,
        center: LatLng(69.4465, 17.4930),
        initialZoom: 9.5,
        start: LatLng(69.4510, 17.1890),
        destination: LatLng(69.4620, 17.8010),
        profile: RouteProfile.drivingCar,
        fallbackDistanceKm: 11,
        fallbackDurationMinutes: 75,
        isDriving: true,
        usesCurrentLocation: true,
        fallbackPoints: [
          LatLng(69.4510, 17.1890),
          LatLng(69.4400, 17.2980),
          LatLng(69.4580, 17.4210),
          LatLng(69.4480, 17.5480),
          LatLng(69.4710, 17.6740),
          LatLng(69.4620, 17.8010),
        ],
        instructions: [
          _FallbackNavigationInstruction(
            progress: 0,
            distance: '500 m',
            title: 'Continue along the coastal road',
            subtitle: 'National Scenic Route Senja',
            icon: Icons.straight_rounded,
          ),
          _FallbackNavigationInstruction(
            progress: 0.30,
            distance: '2.1 km',
            title: 'Turn right toward the viewpoint',
            subtitle: 'Bergsbotn platform',
            icon: Icons.turn_right_rounded,
          ),
          _FallbackNavigationInstruction(
            progress: 0.60,
            distance: '3.4 km',
            title: 'Follow the road along the fjord',
            subtitle: 'Coastal section',
            icon: Icons.straight_rounded,
          ),
          _FallbackNavigationInstruction(
            progress: 0.85,
            distance: '600 m',
            title: 'Turn left into the parking area',
            subtitle: 'Scenic viewpoint',
            icon: Icons.turn_left_rounded,
          ),
        ],
      );
    }

    return const _DestinationRouteData(
      routeLabel: 'Summit',
      icon: Icons.landscape_rounded,
      center: LatLng(67.9281, 13.0850),
      initialZoom: 14,
      start: LatLng(67.9256, 13.0885),
      destination: LatLng(67.9305, 13.0815),
      profile: RouteProfile.footHiking,
      fallbackDistanceKm: 4.8,
      fallbackDurationMinutes: 210,
      isDriving: false,
      usesCurrentLocation: false,
      fallbackPoints: [
        LatLng(67.9256, 13.0885),
        LatLng(67.9264, 13.0869),
        LatLng(67.9274, 13.0856),
        LatLng(67.9284, 13.0844),
        LatLng(67.9294, 13.0829),
        LatLng(67.9305, 13.0815),
      ],
      instructions: [
        _FallbackNavigationInstruction(
          progress: 0,
          distance: '200 m',
          title: 'Follow the trail from Reine',
          subtitle: 'Reinebringen trailhead',
          icon: Icons.straight_rounded,
        ),
        _FallbackNavigationInstruction(
          progress: 0.28,
          distance: '450 m',
          title: 'Continue up the stone steps',
          subtitle: 'Steep ascent',
          icon: Icons.trending_up_rounded,
        ),
        _FallbackNavigationInstruction(
          progress: 0.60,
          distance: '300 m',
          title: 'Keep right at the resting area',
          subtitle: 'Upper mountain section',
          icon: Icons.turn_slight_right_rounded,
        ),
        _FallbackNavigationInstruction(
          progress: 0.85,
          distance: '120 m',
          title: 'Continue to the summit viewpoint',
          subtitle: 'Final ascent',
          icon: Icons.flag_rounded,
        ),
      ],
    );
  }

  _FallbackNavigationInstruction instructionForProgress(double progress) {
    var current = instructions.first;

    for (final instruction in instructions) {
      if (progress >= instruction.progress) {
        current = instruction;
      }
    }

    return current;
  }

  int speedForProgress(double progress) {
    if (isDriving) {
      return 42 + (math.sin(progress * math.pi * 4).abs() * 18).round();
    }

    return 3 + (math.sin(progress * math.pi * 5).abs() * 2).round();
  }
}

class _NavigationInstructionView {
  const _NavigationInstructionView({
    required this.distance,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLive,
  });

  final String distance;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLive;
}

class _FallbackNavigationInstruction {
  const _FallbackNavigationInstruction({
    required this.progress,
    required this.distance,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final double progress;
  final String distance;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _LocationException implements Exception {
  const _LocationException(this.message);

  final String message;
}

BoxDecoration _floatingDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.97),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE4E8EF)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A0F172A),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
  );
}
