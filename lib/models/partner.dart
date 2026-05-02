class AccountabilityPartner {
  String id;
  String firstName;
  String email;
  bool isVerified; // Tracks general consent

  AccountabilityPartner({
    required this.id,
    required this.firstName,
    required this.email,
    this.isVerified = false,
  });
}

// MOCK DATA
List<AccountabilityPartner> myNetwork = [
  AccountabilityPartner(id: 'p1', firstName: 'Mark', email: 'mark@example.com', isVerified: true),
  AccountabilityPartner(id: 'p2', firstName: 'Sarah', email: 'sarah@example.com', isVerified: false),
];