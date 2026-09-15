import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/address_model.dart';

class AddressService {
static const String key = "saved_addresses";

static Future<List<AddressModel>> getAddresses() async {
final prefs = await SharedPreferences.getInstance();

final data = prefs.getString(key);

if (data == null) {
  return [];
}

final decoded = jsonDecode(data);

return (decoded as List)
    .map(
      (e) => AddressModel(
        name: e["name"],
        phone: e["phone"],
        address: e["address"],
        city: e["city"],
        pincode: e["pincode"],
      ),
    )
    .toList();


}

static Future<void> saveAddresses(
List<AddressModel> addresses,
) async {
final prefs = await SharedPreferences.getInstance();


final data = addresses
    .map(
      (e) => {
        "name": e.name,
        "phone": e.phone,
        "address": e.address,
        "city": e.city,
        "pincode": e.pincode,
      },
    )
    .toList();

await prefs.setString(
  key,
  jsonEncode(data),
);


}
}
