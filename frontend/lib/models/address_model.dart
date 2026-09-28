class AddressModel {
  final String? id;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String pincode;

  AddressModel({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.pincode,
  });
}
