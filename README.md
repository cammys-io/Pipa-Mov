# Pipa Móv

Frontend Flutter para administrar flotilla, personal, servicios, ingresos y gastos.

## Ejecutar

Requiere Dart 3.11 o posterior y un Flutter compatible (verificado con Flutter 3.44.9).

```sh
flutter pub get
flutter run -d chrome
```

Después de agregar dependencias, detener la ejecución anterior y volver a ejecutar la app; hot reload no registra plugins nuevos.

## Módulos

- Inicio: ingresos, gastos y balance del mes; estado de flotilla y últimos movimientos.
- Operaciones: alta, edición y eliminación. Pipas (viajes y capacidad), retroexcavadoras (horas), volteos (viajes/horas y material), garrafones (cantidad).
- Gastos: combustible, mantenimiento (`mtto`), insumos y sueldos; empleado obligatorio, vehículo opcional y comprobante.
- Catálogos: personal y vehículos/maquinaria. Se impide borrar registros con movimientos o asignaciones para conservar referencias.
- Reportes: filtros inclusivos por fecha, tipo, categoría/servicio y vehículo; PDF y Excel `.xlsx` con los mismos registros filtrados, totales e importes numéricos.

Los formularios permiten adjuntar JPG, PNG o PDF de hasta 10 MB. Las imágenes se previsualizan y el PDF adjunto puede guardarse. Los reportes se descargan en navegador; en escritorio se guardan en Descargas y en móvil en el directorio que proporciona `file_saver`.

## Estado de la conexión

Por solicitud, **no se conecta al backend ni se incluyen datos de ejemplo**. Los repositorios `MemoryUsuarioRepository`, `MemoryVehiculoRepository` y `MemoryMovimientoRepository` inician vacíos. Los registros y los bytes de adjuntos se guardan únicamente durante la sesión y se pierden al reiniciar.

Para integrar NestJS, inyectar implementaciones de `UsuarioRepository`, `VehiculoRepository` y `MovimientoRepository` en los providers de `lib/main.dart`. El contrato combinado de movimientos puede consultar los endpoints separados de ingresos y gastos. Debe garantizar IDs únicos entre ambos recursos o adaptar la identidad compuesta antes de usar IDs enteros repetidos entre tablas.

Los modelos `Ingreso` y `Gasto` incluyen `toJson/fromJson` con los campos del diagrama. Antes de enviar al API, adaptar IDs `String` a enteros si el contrato lo requiere y omitir el ID local en las altas. `cantidad_garrafones` distingue botellones de pipas cuando `tipo_servicio = agua`. Confirmar ese criterio, los valores de capacidad (`5mil`, `10mil`) y el catálogo de materiales con el backend.

La subida real de adjuntos está pendiente de los endpoints de archivos: enviar `Evidencia.bytes` y asignar la URL resultante a `nota_url` / `comprobante_url`. No se generan URLs ficticias. La autenticación y los permisos deben integrarse con el backend antes de uso real; el campo rol es parte del catálogo, no un sistema de acceso implementado.

## Regla provisional de cobro

Se calcula cantidad × precio unitario (por viaje, hora o garrafón) con redondeo a centavos. En volteos se elige hora o viaje. También hay monto manual. Al editar, se conserva el monto manual porque la BD no incluye tarifa ni unidad de cobro. No se inventan tarifas, impuestos o descuentos.

## Diseño y verificación

La paleta está centralizada en `lib/core/theme/app_theme.dart`: azul pizarra, blanco, gris y colores suaves para estados. Menú lateral en escritorio, navegación inferior en móvil y tablas con desplazamiento horizontal.

```sh
flutter analyze
flutter test
flutter build web
```

Las pruebas cubren formularios, navegación en móvil/escritorio, cálculo, filtros, CRUD temporal, serialización y generación de PDF/Excel. La selección y descarga nativa de archivos requieren comprobación manual en cada plataforma.
