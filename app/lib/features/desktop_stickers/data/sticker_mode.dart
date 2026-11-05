enum StickerMode {
  mini,
  standard,
  expanded;

  bool get showsDetails => this == expanded;

  static StickerMode read(Object? value) => values.firstWhere(
    (StickerMode mode) => mode.name == value,
    orElse: () => mini,
  );
}
