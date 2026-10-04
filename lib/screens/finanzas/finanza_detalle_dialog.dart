import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const _panelAlt = Color(0xFFF1F4F7);

/// Una fila etiqueta/valor del detalle. Si [valor] es null o vacío se muestra
/// el mensaje [faltante] (ej. "Sin horas registradas") en gris e itálica.
class DetalleFila {
  final String etiqueta;
  final String? valor;
  final String faltante;

  const DetalleFila(this.etiqueta, this.valor, {required this.faltante});

  bool get tieneValor => valor != null && valor!.trim().isNotEmpty;
}

/// Contenido del detalle ya listo para pintarse.
///
/// [empleado] y [vehiculo] son null cuando el registro no los tiene asignados;
/// en ese caso el diálogo muestra [sinEmpleado] / [sinVehiculo].
class DetalleFinanza {
  final List<DetalleFila> generales;
  final List<DetalleFila>? empleado;
  final List<DetalleFila>? vehiculo;
  final String comprobanteTitulo;
  final String? comprobanteUrl;

  const DetalleFinanza({
    required this.generales,
    required this.empleado,
    required this.vehiculo,
    this.comprobanteTitulo = 'Comprobante',
    required this.comprobanteUrl,
  });
}

/// Diálogo de detalle compartido por Ingresos y Gastos.
///
/// Recibe un [Future] (la llamada al endpoint findOne) y se encarga de mostrar
/// el estado de carga y de error dentro del mismo diálogo, por lo que no
/// requiere abrir/cerrar un diálogo de carga aparte.
class FinanzaDetalleDialog extends StatelessWidget {
  final String titulo;
  final Future<DetalleFinanza> detalle;

  const FinanzaDetalleDialog({
    super.key,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: SizedBox(
        width: 440,
        child: FutureBuilder<DetalleFinanza>(
          future: detalle,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 100,
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              final msg = snapshot.error?.toString().replaceFirst('Exception: ', '');
              return _Aviso(
                icono: Icons.error_outline,
                texto: 'No se pudo cargar el detalle${msg == null ? '' : ': $msg'}',
              );
            }
            return _Contenido(data: snapshot.data!);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  final DetalleFinanza data;

  const _Contenido({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Seccion(titulo: 'Datos generales', filas: data.generales),
          _Seccion(
            titulo: 'Empleado',
            filas: data.empleado,
            sinDatos: 'Sin empleado asignado',
          ),
          _Seccion(
            titulo: 'Vehículo',
            filas: data.vehiculo,
            sinDatos: 'Sin vehículo asignado',
          ),
          _titulo(data.comprobanteTitulo),
          const SizedBox(height: 8),
          _Comprobante(url: data.comprobanteUrl),
        ],
      ),
    );
  }
}

Widget _titulo(String texto) => Text(
      texto,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );

class _Seccion extends StatelessWidget {
  final String titulo;
  final List<DetalleFila>? filas;
  final String? sinDatos;

  const _Seccion({required this.titulo, required this.filas, this.sinDatos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo(titulo),
          const SizedBox(height: 8),
          if (filas == null)
            _Aviso(icono: Icons.info_outline, texto: sinDatos ?? 'Sin datos')
          else
            ...filas!.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: f.tieneValor
                      ? Text.rich(TextSpan(children: [
                          TextSpan(
                              text: '${f.etiqueta}: ',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: f.valor),
                        ]), style: const TextStyle(fontSize: 14))
                      : Text('${f.etiqueta}: ${f.faltante}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic)),
                )),
        ],
      ),
    );
  }
}

class _Comprobante extends StatelessWidget {
  final String? url;

  const _Comprobante({required this.url});

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    if (u == null || u.isEmpty) {
      return const _Aviso(icono: Icons.image_not_supported_outlined, texto: 'Sin comprobante');
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        u,
        height: 240,
        width: double.infinity,
        fit: BoxFit.contain,
        // Si el servidor de la imagen no permite CORS en web, se usa
        // un elemento <img> nativo como alternativa.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const SizedBox(
                height: 120,
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              ),
        errorBuilder: (context, error, stack) => const _Aviso(
          icono: Icons.broken_image_outlined,
          texto: 'No se pudo cargar la imagen del comprobante',
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Aviso({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panelAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}
