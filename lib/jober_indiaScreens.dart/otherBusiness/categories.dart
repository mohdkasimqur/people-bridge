class OtherBusinessCategory {
  final String name;
  final String key;
  final bool isShopType;

  const OtherBusinessCategory({
    required this.name,
    required this.key,
    this.isShopType = false,
  });
}

String categoryKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

const List<OtherBusinessCategory> defaultOtherBusinessCategories = [
  OtherBusinessCategory(
    name: 'Electronics Shop',
    key: 'electronics_shop',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Mobile Shop',
    key: 'mobile_shop',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Clothing Shop',
    key: 'clothing_shop',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Furniture Shop',
    key: 'furniture_shop',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Hardware Shop',
    key: 'hardware_shop',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Supermarket',
    key: 'supermarket',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Bakery',
    key: 'bakery',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Restaurant',
    key: 'restaurant',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Hotel',
    key: 'hotel',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Office',
    key: 'office',
  ),
  OtherBusinessCategory(
    name: 'Consultancy',
    key: 'consultancy',
  ),
  OtherBusinessCategory(
    name: 'Service Center',
    key: 'service_center',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Trading',
    key: 'trading',
  ),
  OtherBusinessCategory(
    name: 'Wholesale',
    key: 'wholesale',
    isShopType: true,
  ),
  OtherBusinessCategory(
    name: 'Other',
    key: 'other',
  ),
];