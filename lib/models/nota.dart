/// Estados posibles de una nota. El valor `api` coincide con el enum
/// `EstadoNota` del backend (en minúsculas).
enum EstadoNota {
  info('info', 'INFO'),
  pendiente('pendiente', 'PENDIENTE'),
  resuelto('resuelto', 'RESUELTO');

  final String api;
  final String label;
  const EstadoNota(this.api, this.label);

  static EstadoNota fromApi(String? value) {
    final v = value?.toLowerCase();
    return EstadoNota.values.firstWhere(
      (e) => e.api == v,
      orElse: () => EstadoNota.info,
    );
  }
}

/// Nota/recordatorio. Corresponde a la entidad `Note` (tabla `notas`).
class Nota {
  final String id;
  final String titulo;
  final String descripcion;
  final EstadoNota estatus;
  final DateTime? createdAt;

  const Nota({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.estatus,
    this.createdAt,
  });

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      id: json['id'].toString(),
      titulo: (json['titulo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      estatus: EstadoNota.fromApi(json['estatus']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
    );
  }

  /// Cuerpo JSON para POST / PATCH (el backend rechaza propiedades extra).
  Map<String, dynamic> toBodyJson() => {
    'titulo': titulo,
    'descripcion': descripcion,
    'estatus': estatus.api,
  };

  Nota copyWith({String? titulo, String? descripcion, EstadoNota? estatus}) {
    return Nota(
      id: id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      estatus: estatus ?? this.estatus,
      createdAt: createdAt,
    );
  }
}
