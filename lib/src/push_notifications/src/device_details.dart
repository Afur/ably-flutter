import 'package:ably_flutter/ably_flutter.dart';
import 'package:meta/meta.dart';

/// BEGIN LEGACY DOCSTRING
/// Details of a registered device.
///
/// https://docs.ably.com/client-lib-development-guide/features/#PCD1
/// END LEGACY DOCSTRING

/// BEGIN CANONICAL DOCSTRING
/// Contains the properties of a device registered for push notifications.
/// END CANONICAL DOCSTRING
@immutable
class DeviceDetails {
  /// BEGIN LEGACY DOCSTRING
  /// The id of the device registration.
  ///
  /// Generated locally if not available
  ///
  /// https://docs.ably.com/client-lib-development-guide/features/#PCD2
  /// END LEGACY DOCSTRING
  final String? id;

  /// BEGIN LEGACY DOCSTRING
  /// populated for device registrations associated with a clientId (optional)
  ///
  /// https://docs.ably.com/client-lib-development-guide/features/#PCD3
  /// END LEGACY DOCSTRING
  final String? clientId;

  /// BEGIN LEGACY DOCSTRING
  /// The device platform.
  ///
  /// https://docs.ably.com/client-lib-development-guide/features/#PCD6
  /// END LEGACY DOCSTRING
  final DevicePlatform platform;

  /// BEGIN LEGACY DOCSTRING
  /// the device form factor.
  ///
  /// https://docs.ably.com/client-lib-development-guide/features/#PCD4
  /// END LEGACY DOCSTRING
  final FormFactor formFactor;

  /// BEGIN LEGACY DOCSTRING
  /// a map of string key/value pairs containing any other registered
  /// metadata associated with the device registration
  ///
  /// https://docs.ably.com/client-lib-development-guide/features/#PCD5
  /// END LEGACY DOCSTRING
  final Map<String, String> metadata;

  /// BEGIN LEGACY DOCSTRING
  /// Details of the push registration for this device.
  ///
  /// https://docs.ably.com/client-lib-development-guide/features/#PCD7
  /// END LEGACY DOCSTRING
  final DevicePushDetails push;

  /// BEGIN LEGACY DOCSTRING
  /// Initializes an instance without any defaults
  /// END LEGACY DOCSTRING
  const DeviceDetails({
    required this.formFactor,
    required this.metadata,
    required this.platform,
    required this.push,
    this.clientId,
    this.id,
  });
}
