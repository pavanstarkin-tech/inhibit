import 'dart:convert';

class SurfaceRule {
  final String id;
  final String kind;
  final String label;
  final bool defaultEnabled;
  final bool locked;
  final List<String> selectors;
  final List<String> patterns;
  final String? redirect;
  final String? css;

  const SurfaceRule({
    required this.id,
    required this.kind,
    required this.label,
    this.defaultEnabled = true,
    this.locked = false,
    this.selectors = const [],
    this.patterns = const [],
    this.redirect,
    this.css,
  });

  factory SurfaceRule.fromJson(String id, Map<String, dynamic> json) {
    return SurfaceRule(
      id: id,
      kind: json['kind'] as String? ?? 'dom-remove',
      label: json['label'] as String? ?? id,
      defaultEnabled: json['defaultEnabled'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      selectors: (json['selectors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      patterns: (json['patterns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      redirect: json['redirect'] as String?,
      css: json['css'] as String?,
    );
  }
}

class ServiceRuleConfig {
  final String serviceId;
  final List<String> match;
  final List<String> authAllowList;
  final Map<String, SurfaceRule> surfaces;

  const ServiceRuleConfig({
    required this.serviceId,
    required this.match,
    required this.authAllowList,
    required this.surfaces,
  });

  factory ServiceRuleConfig.fromJson(String serviceId, Map<String, dynamic> json) {
    final match = (json['match'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final authAllowList =
        (json['authAllowList'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final surfacesJson = json['surfaces'] as Map<String, dynamic>? ?? {};

    final Map<String, SurfaceRule> surfaces = {};
    surfacesJson.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        surfaces[key] = SurfaceRule.fromJson(key, val);
      }
    });

    return ServiceRuleConfig(
      serviceId: serviceId,
      match: match,
      authAllowList: authAllowList,
      surfaces: surfaces,
    );
  }
}

class RuleBundle {
  final int version;
  final int minEngine;
  final Map<String, ServiceRuleConfig> services;
  final String rawJson;

  const RuleBundle({
    required this.version,
    required this.minEngine,
    required this.services,
    required this.rawJson,
  });

  factory RuleBundle.fromRawJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final version = map['version'] as int? ?? 1;
    final minEngine = map['minEngine'] as int? ?? 1;
    final servicesMap = map['services'] as Map<String, dynamic>? ?? {};

    final Map<String, ServiceRuleConfig> services = {};
    servicesMap.forEach((svcId, svcJson) {
      if (svcJson is Map<String, dynamic>) {
        services[svcId] = ServiceRuleConfig.fromJson(svcId, svcJson);
      }
    });

    return RuleBundle(
      version: version,
      minEngine: minEngine,
      services: services,
      rawJson: raw,
    );
  }
}
