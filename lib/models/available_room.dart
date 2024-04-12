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

  factory AvailableRoom.fromJson(Map<String, dynamic> json) {
    int numParticipants = 0;
    if (json['num_participants'] != null) {
      numParticipants = json['num_participants'] as int;
    }
    return AvailableRoom(
      sid: json['sid'],
      name: json['name'],
      numParticipants: numParticipants,
    );
  }
}
