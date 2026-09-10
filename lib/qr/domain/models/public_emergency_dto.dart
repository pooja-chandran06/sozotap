class PublicEmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool canCall;

  const PublicEmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    required this.canCall,
  });

  factory PublicEmergencyContact.fromMap(Map<String, dynamic> map) {
    return PublicEmergencyContact(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Emergency Contact',
      relationship: map['relationship'] as String? ?? 'Contact',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      canCall: map['canCall'] as bool? ?? true,
    );
  }
}

class PublicEmergencyDto {
  final String displayEmergencyId;
  final String fullName;
  final String? photoUrl;
  final String bloodGroup;
  final String allergies;
  final String medicalConditions;
  final String currentMedications;
  final String implants;
  final String emergencyNotes;
  final String? primaryDoctor;
  final String? preferredHospital;
  final String? hospitalAddress;
  final List<PublicEmergencyContact> emergencyContacts;
  final String? lastUpdated;

  const PublicEmergencyDto({
    required this.displayEmergencyId,
    required this.fullName,
    this.photoUrl,
    required this.bloodGroup,
    required this.allergies,
    required this.medicalConditions,
    required this.currentMedications,
    required this.implants,
    required this.emergencyNotes,
    this.primaryDoctor,
    this.preferredHospital,
    this.hospitalAddress,
    required this.emergencyContacts,
    this.lastUpdated,
  });

  factory PublicEmergencyDto.fromMap(Map<String, dynamic> map) {
    final contactsList = map['emergencyContacts'] as List? ?? [];
    return PublicEmergencyDto(
      displayEmergencyId: map['displayEmergencyId'] as String? ?? 'ST-0000-0000',
      fullName: map['fullName'] as String? ?? 'Emergency Patient',
      photoUrl: map['photoUrl'] as String?,
      bloodGroup: map['bloodGroup'] as String? ?? 'Not Specified',
      allergies: map['allergies'] as String? ?? 'None reported',
      medicalConditions: map['medicalConditions'] as String? ?? 'None reported',
      currentMedications: map['currentMedications'] as String? ?? 'None reported',
      implants: map['implants'] as String? ?? 'None reported',
      emergencyNotes: map['emergencyNotes'] as String? ?? '',
      primaryDoctor: map['primaryDoctor'] as String?,
      preferredHospital: map['preferredHospital'] as String?,
      hospitalAddress: map['hospitalAddress'] as String?,
      emergencyContacts: contactsList
          .map((c) => PublicEmergencyContact.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
      lastUpdated: map['lastUpdated'] as String?,
    );
  }
}
