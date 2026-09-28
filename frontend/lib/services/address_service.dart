import 'api_service.dart';
import '../models/address_model.dart';

class AddressService {
  static List<AddressModel> _cachedAddresses = [];

  static Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await ApiService.get('/addresses');
      if (response is List) {
        _cachedAddresses = response.map((e) => AddressModel(
          id: e["_id"]?.toString(),
          name: e["fullName"] ?? e["name"] ?? '',
          phone: e["phone"] ?? '',
          address: e["addressLine1"] ?? e["address"] ?? '',
          city: e["city"] ?? '',
          pincode: e["pincode"] ?? '',
        )).toList();
      }
    } catch (e) {
      print('Fetch addresses error: $e');
    }
    return _cachedAddresses;
  }

  static Future<void> saveAddress(AddressModel addr) async {
    try {
      await ApiService.post('/addresses', {
        "fullName": addr.name,
        "phone": addr.phone,
        "addressLine1": addr.address,
        "city": addr.city,
        "pincode": addr.pincode,
        "state": "Tamil Nadu", // Defaulting as per previous context
        "isDefault": _cachedAddresses.isEmpty,
      });
      await getAddresses(); // Refresh cache
    } catch (e) {
      print('Save address error: $e');
      throw e;
    }
  }

  static Future<void> deleteAddress(String id) async {
    try {
      await ApiService.delete('/addresses/$id');
      await getAddresses(); // Refresh cache
    } catch (e) {
      print('Delete address error: $e');
    }
  }

  // Legacy support for multiple saves (rarely used now with single add)
  static Future<void> saveAddresses(List<AddressModel> addresses) async {
      // Just saving the last one for now to sync with backend logic
      if (addresses.isNotEmpty) {
          await saveAddress(addresses.last);
      }
  }
}
