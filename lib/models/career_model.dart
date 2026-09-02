import 'mission_model.dart';
import 'skill_node_model.dart';

/// Represents Sector Progression, Achievements, and Tech Tree.
class CareerModel {
  final int sectorLevel;
  final String sectorName;
  final int prestigeCount;
  final List<MissionModel> missions;
  final List<SkillNodeModel> skills;

  const CareerModel({
    required this.sectorLevel,
    required this.sectorName,
    required this.prestigeCount,
    required this.missions,
    required this.skills,
  });

  /// Sector name generator based on rank
  static String getSectorTitle(int sector) {
    const sectorNames = [
      'Orion Nebula',
      'Andromeda Expanse',
      'Kepler Void',
      'Cygnus Rift',
      'Vela Supercluster',
      'Centauri Apex',
      'Sagittarius Core',
      'Hyperion Gate',
      'Tiamat Abyss',
      'Cosmic Singularity',
    ];
    final index = (sector - 1) % sectorNames.length;
    return '${sectorNames[index]} (Sector $sector)';
  }

  factory CareerModel.initial() {
    return CareerModel(
      sectorLevel: 1,
      sectorName: getSectorTitle(1),
      prestigeCount: 0,
      missions: MissionModel.getInitialMissions(),
      skills: SkillNodeModel.getInitialSkills(),
    );
  }

  CareerModel copyWith({
    int? sectorLevel,
    String? sectorName,
    int? prestigeCount,
    List<MissionModel>? missions,
    List<SkillNodeModel>? skills,
  }) {
    return CareerModel(
      sectorLevel: sectorLevel ?? this.sectorLevel,
      sectorName: sectorName ?? this.sectorName,
      prestigeCount: prestigeCount ?? this.prestigeCount,
      missions: missions ?? this.missions,
      skills: skills ?? this.skills,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectorLevel': sectorLevel,
      'sectorName': sectorName,
      'prestigeCount': prestigeCount,
      'missions': missions.map((m) => m.toJson()).toList(),
      'skills': skills.map((s) => s.toJson()).toList(),
    };
  }

  factory CareerModel.fromJson(Map<String, dynamic> json) {
    return CareerModel(
      sectorLevel: json['sectorLevel'] as int? ?? 1,
      sectorName: json['sectorName'] as String? ?? getSectorTitle(1),
      prestigeCount: json['prestigeCount'] as int? ?? 0,
      missions: json['missions'] != null
          ? (json['missions'] as List)
              .map((m) => MissionModel.fromJson(m as Map<String, dynamic>))
              .toList()
          : MissionModel.getInitialMissions(),
      skills: json['skills'] != null
          ? (json['skills'] as List)
              .map((s) => SkillNodeModel.fromJson(s as Map<String, dynamic>))
              .toList()
          : SkillNodeModel.getInitialSkills(),
    );
  }
}
