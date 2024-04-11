import 'package:flutter/material.dart' show immutable;

@immutable
class AvailableRoom {
  final String sid;
  final String name;
  final int numParticipants;

  const AvailableRoom({
    required this.sid,
    required this.name,
    required this.numParticipants,
  });

  factory AvailableRoom.fromJson(Map<String, dynamic> json) => AvailableRoom(
        sid: json['sid'],
        name: json['name'],
        numParticipants: json['numParticipants'] as int,
      );
}
