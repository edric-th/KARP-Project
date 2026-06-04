// Small, forgiving JSON coercion helpers. The backend sends camelCase JSON and
// some fields may be absent (older docs) — these never throw on missing/typed data.

double asDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int asInt(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String asString(dynamic v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

bool asBool(dynamic v, [bool fallback = false]) =>
    v is bool ? v : fallback;

List<String> asStringList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const <String>[];

/// Parses an ISO-8601 string (e.g. expectedCallAt / createdAt) into a DateTime.
DateTime? asDate(dynamic v) {
  if (v is String) return DateTime.tryParse(v);
  return null;
}

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
