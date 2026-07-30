class SoftwareCapabilities {
  final List<String> actions;
  final List<String> fileFormats;
  final Map<String, String>? constraints;

  const SoftwareCapabilities({
    required this.actions,
    required this.fileFormats,
    this.constraints,
  });

  Map<String, dynamic> toJson() => {
    'actions': actions,
    'fileFormats': fileFormats,
    if (constraints != null) 'constraints': constraints,
  };
}

class SoftwareState {
  final String activeDocument;
  final List<String> selectedNodes;
  final List<String> layers;
  final Map<String, dynamic>? extra;

  const SoftwareState({
    this.activeDocument = '',
    this.selectedNodes = const [],
    this.layers = const [],
    this.extra,
  });

  Map<String, dynamic> toJson() => {
    'activeDocument': activeDocument,
    'selectedNodes': selectedNodes,
    'layers': layers,
    if (extra != null) 'extra': extra,
  };
}
