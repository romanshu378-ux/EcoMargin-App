import 'package:flutter/material.dart';

enum ConnectorStatus {
  available,
  preparing,
  charging,
  suspendedEv,
  suspendedEvse,
  finishing,
  reserved,
  unavailable,
  faulted,
  unknown,
}

class ConnectorStatusInfo {
  final ConnectorStatus status;
  final String rawStatus;
  final String label;
  final String description;
  final Color color;
  final IconData icon;
  final bool isStartable;

  const ConnectorStatusInfo({
    required this.status,
    required this.rawStatus,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    required this.isStartable,
  });

  static ConnectorStatusInfo fromRaw(String? raw) {
    final statusStr = (raw ?? '').trim().toUpperCase();

    switch (statusStr) {
      case 'AVAILABLE':
        return const ConnectorStatusInfo(
          status: ConnectorStatus.available,
          rawStatus: 'AVAILABLE',
          label: 'Available',
          description: 'Connector Available',
          color: Color(0xFF16A34A), // Green
          icon: Icons.check_circle_rounded,
          isStartable: true,
        );
      case 'PREPARING':
        return const ConnectorStatusInfo(
          status: ConnectorStatus.preparing,
          rawStatus: 'PREPARING',
          label: 'Preparing',
          description: 'Please connect charging connector',
          color: Color(0xFFD97706), // Amber
          icon: Icons.electrical_services_rounded,
          isStartable: true, // Eligible if plug is confirmed
        );
      case 'CHARGING':
      case 'ACTIVE':
        return const ConnectorStatusInfo(
          status: ConnectorStatus.charging,
          rawStatus: 'CHARGING',
          label: 'In Use',
          description: 'Charging session already active',
          color: Color(0xFF2563EB), // Blue
          icon: Icons.bolt_rounded,
          isStartable: false,
        );
      case 'SUSPENDED_EV':
        return const ConnectorStatusInfo(
          status: ConnectorStatus.suspendedEv,
          rawStatus: 'SUSPENDED_EV',
          label: 'Charging Suspended',
          description: 'Paused by vehicle battery management',
          color: Color(0xFFEA580C), // Orange
          icon: Icons.pause_circle_filled_rounded,
          isStartable: false,
        );
      case 'SUSPENDED_EVSE':
        return const ConnectorStatusInfo(
          status: ConnectorStatus.suspendedEvse,
          rawStatus: 'SUSPENDED_EVSE',
          label: 'Charging Suspended',
          description: 'Temporarily paused by charger',
          color: Color(0xFFEA580C), // Orange
          icon: Icons.pause_circle_filled_rounded,
          isStartable: false,
        );
      case 'FINISHING':
      case 'STOPPING':
        return const ConnectorStatusInfo(
          status: ConnectorStatus.finishing,
          rawStatus: 'FINISHING',
          label: 'Finishing',
          description: 'Finishing charging session',
          color: Color(0xFFD97706), // Amber
          icon: Icons.timelapse_rounded,
          isStartable: false,
        );
      case 'RESERVED':
        return const ConnectorStatusInfo(
          status: ConnectorStatus.reserved,
          rawStatus: 'RESERVED',
          label: 'Reserved',
          description: 'Connector reserved for another user',
          color: Color(0xFF9333EA), // Purple
          icon: Icons.bookmark_rounded,
          isStartable: false,
        );
      case 'UNAVAILABLE':
      case 'OFFLINE':
        return const ConnectorStatusInfo(
          status: ConnectorStatus.unavailable,
          rawStatus: 'UNAVAILABLE',
          label: 'Currently Unavailable',
          description: 'Please select another connector',
          color: Color(0xFF64748B), // Slate/Grey
          icon: Icons.block_rounded,
          isStartable: false,
        );
      case 'FAULTED':
      case 'FAULT':
        return const ConnectorStatusInfo(
          status: ConnectorStatus.faulted,
          rawStatus: 'FAULTED',
          label: 'Charger Fault',
          description: 'This charger is currently unavailable',
          color: Color(0xFFDC2626), // Red
          icon: Icons.error_rounded,
          isStartable: false,
        );
      default:
        return ConnectorStatusInfo(
          status: ConnectorStatus.unknown,
          rawStatus: statusStr,
          label: statusStr.isNotEmpty ? statusStr : 'Unknown',
          description: 'Status unknown',
          color: const Color(0xFF64748B),
          icon: Icons.help_outline_rounded,
          isStartable: false,
        );
    }
  }
}
