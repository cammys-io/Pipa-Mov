import 'dart:typed_data';
import 'vehiculo.dart';

enum ServicioOperacion {
  pipa('Pipa de agua', 'agua', TipoUnidad.pipa),
  retro('Retroexcavadora', 'maquinaria', TipoUnidad.retro),
  volteo('Volteo', 'volteo', TipoUnidad.volteo),
  garrafones('Garrafones / botellones', 'agua', TipoUnidad.carroGarrafon);

  final String label;
  final String dbValue;
  final TipoUnidad tipoUnidad;
  const ServicioOperacion(this.label, this.dbValue, this.tipoUnidad);
}

enum CategoriaGasto {
  combustible('Combustible', 'combustible'),
  mantenimiento('Mantenimiento', 'mtto'),
  insumos('Insumos', 'insumos'),
  sueldos('Sueldos', 'sueldos');

  final String label;
  final String dbValue;
  const CategoriaGasto(this.label, this.dbValue);
}

/// Archivo seleccionado en esta sesión. Su URL se asignará al subirlo al backend.
class Evidencia {
  final String nombre;
  final Uint8List bytes;
  const Evidencia({required this.nombre, required this.bytes});
  bool get esPdf => nombre.toLowerCase().endsWith('.pdf');
}

sealed class Movimiento {
  final String id;
  final DateTime fecha;
  final String? vehiculoId;
  final String empleadoId;
  final double monto;
  final Evidencia? evidencia;
  final String? archivoUrl;
  const Movimiento({
    required this.id,
    required this.fecha,
    required this.empleadoId,
    required this.monto,
    this.vehiculoId,
    this.evidencia,
    this.archivoUrl,
  });
  bool get esGasto => this is Gasto;
  String get concepto;
  String get detalle;
  Map<String, dynamic> toJson();
}

class Ingreso extends Movimiento {
  final ServicioOperacion servicio;
  final double? cantidadHoras;
  final int? cantidadViajes;
  final int? cantidadGarrafones;
  final String? capacidadPipa;
  final String? tipoMaterial;
  const Ingreso({
    required super.id,
    required super.fecha,
    required super.empleadoId,
    required super.monto,
    super.vehiculoId,
    super.evidencia,
    super.archivoUrl,
    required this.servicio,
    this.cantidadHoras,
    this.cantidadViajes,
    this.cantidadGarrafones,
    this.capacidadPipa,
    this.tipoMaterial,
  });
  @override
  String get concepto => servicio.label;
  @override
  String get detalle => [
    if (cantidadViajes != null) '$cantidadViajes viajes',
    if (cantidadHoras != null) '$cantidadHoras horas',
    if (cantidadGarrafones != null) '$cantidadGarrafones garrafones',
    if (capacidadPipa != null) capacidadPipa!,
    if (tipoMaterial != null) tipoMaterial!,
  ].join(' · ');
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': fecha.toIso8601String(),
    'tipo_servicio': servicio.dbValue,
    'vehiculo_id': vehiculoId,
    'empleado_id': empleadoId,
    'cantidad_horas': cantidadHoras,
    'cantidad_viajes': cantidadViajes,
    'cantidad_garrafones': cantidadGarrafones,
    'capacidad_pipa': capacidadPipa,
    'tipo_material': tipoMaterial,
    'monto_total': monto,
    'nota_url': archivoUrl,
  };
  factory Ingreso.fromJson(Map<String, dynamic> json) {
    final servicio = switch (json['tipo_servicio']) {
      'maquinaria' => ServicioOperacion.retro,
      'volteo' => ServicioOperacion.volteo,
      'agua' =>
        (json['cantidad_garrafones'] as num? ?? 0) > 0
            ? ServicioOperacion.garrafones
            : ServicioOperacion.pipa,
      _ => throw FormatException(
        'Tipo de servicio desconocido: ${json['tipo_servicio']}',
      ),
    };
    return Ingreso(
      id: json['id'].toString(),
      fecha: DateTime.parse(json['fecha']).toLocal(),
      empleadoId: json['empleado_id'].toString(),
      vehiculoId: json['vehiculo_id']?.toString(),
      monto: (json['monto_total'] as num).toDouble(),
      servicio: servicio,
      cantidadHoras: (json['cantidad_horas'] as num?)?.toDouble(),
      cantidadViajes: (json['cantidad_viajes'] as num?)?.toInt(),
      cantidadGarrafones: (json['cantidad_garrafones'] as num?)?.toInt(),
      capacidadPipa: json['capacidad_pipa'] as String?,
      tipoMaterial: json['tipo_material'] as String?,
      archivoUrl: json['nota_url'] as String?,
    );
  }
}

class Gasto extends Movimiento {
  final CategoriaGasto categoria;
  final String descripcion;
  const Gasto({
    required super.id,
    required super.fecha,
    required super.empleadoId,
    required super.monto,
    super.vehiculoId,
    super.evidencia,
    super.archivoUrl,
    required this.categoria,
    required this.descripcion,
  });
  @override
  String get concepto => categoria.label;
  @override
  String get detalle => descripcion;
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': fecha.toIso8601String(),
    'categoria': categoria.dbValue,
    'monto': monto,
    'descripcion': descripcion,
    'vehiculo_id': vehiculoId,
    'empleado_id': empleadoId,
    'comprobante_url': archivoUrl,
  };
  factory Gasto.fromJson(Map<String, dynamic> json) => Gasto(
    id: json['id'].toString(),
    fecha: DateTime.parse(json['fecha']).toLocal(),
    empleadoId: json['empleado_id'].toString(),
    vehiculoId: json['vehiculo_id']?.toString(),
    monto: (json['monto'] as num).toDouble(),
    descripcion: json['descripcion'] as String,
    categoria: CategoriaGasto.values.firstWhere(
      (c) => c.dbValue == json['categoria'],
    ),
    archivoUrl: json['comprobante_url'] as String?,
  );
}

double calcularImporte(double cantidad, double precio) {
  if (!cantidad.isFinite || !precio.isFinite || cantidad <= 0 || precio <= 0) {
    throw ArgumentError('Cantidad y precio deben ser mayores que cero.');
  }
  final total = cantidad * precio;
  if (!total.isFinite || total > 999999999999.99) {
    throw ArgumentError('Importe fuera de rango.');
  }
  return (total * 100).round() / 100;
}
