# Deuda Técnica y Optimizaciones Pendientes (Frontend -> Backend)

Este documento lista los procesos y cálculos que actualmente se realizan en la memoria del dispositivo móvil (Frontend) como solución temporal para la entrega, pero que por buenas prácticas, rendimiento y escalabilidad, deben migrarse al Backend (NestJS) en el futuro.

## 1. Filtrado de Movimientos (Módulo de Reportes)
- **Dónde ocurre hoy:** En `Pipa-Mov/lib/models/filtro_movimientos.dart` y `Pipa-Mov/lib/screens/reportes/reportes_screen.dart`. La app móvil descarga el historial completo de ingresos y gastos y utiliza el método `.where()` de Dart para filtrar la lista según las fechas, rol, empleado y vehículo.
- **Por qué debe migrarse:** A medida que pasen los meses, descargar miles de movimientos consumirá demasiados datos de internet y RAM del celular, haciendo la app lenta.
- **Qué servicio/endpoint ocuparía:** 
  - Un endpoint como `GET /api/movements` o expandir los de `incomes/expenses` para que acepten query parameters: `?fechaInicio=2023-01-01&fechaFin=2023-01-31&vehiculoId=XXX`.
  - El backend usaría el `QueryBuilder` de TypeORM para aplicar las cláusulas `WHERE` directamente en la base de datos PostgreSQL.

## 2. Generación de Archivos PDF y Excel
- **Dónde ocurre hoy:** En `Pipa-Mov/lib/services/reporte_exporter.dart`. La app dibuja tabla por tabla el PDF y estructura las celdas del Excel utilizando los recursos físicos del celular.
- **Por qué debe migrarse:** Generar archivos grandes en celulares de gama baja puede congelar la app o crashearla por falta de memoria. Además, si quieres cambiar el logo o el diseño del reporte, actualmente tendrías que obligar a los usuarios a actualizar la app en la tienda.
- **Qué servicio/endpoint ocuparía:** 
  - Un endpoint como `GET /api/reports/export?format=pdf&fechaInicio=...`
  - En NestJS utilizarías librerías como `pdfmake`, `puppeteer` o `exceljs`. El servidor crearía el archivo en milisegundos y le devolvería a la app un enlace de descarga o los bytes listos para abrir.

## 3. Cálculo de Subtotales de Reportes en Memoria
- **Dónde ocurre hoy:** En `Pipa-Mov/lib/models/filtro_movimientos.dart` (clase `TotalesMovimientos.de(...)`). Recorre los arreglos filtrados en el front y suma centavo a centavo el balance de los reportes en pantalla.
- **Por qué debe migrarse:** Por la misma razón que el filtro; es redundante sumar en el frontend si la base de datos fue diseñada para sumar eficientemente mediante SQL.
- **Qué servicio/endpoint ocuparía:** 
  - El mismo endpoint que devuelve la lista de movimientos filtrados debería devolver un nodo adicional: `{ "data": [...], "totales": { "ingresos": 5000, "gastos": 2000, "balance": 3000 } }`, calculado con un `SUM()` en NestJS.

## 4. Ausencia de Paginación al obtener el historial
- **Dónde ocurre hoy:** En `Pipa-Mov/lib/data/api/api_movimiento_repository.dart` (`obtenerTodos`). Hace un GET abierto a incomes y expenses, lo cual trae toda la tabla.
- **Por qué debe migrarse:** Cargará muy rápido para 100 registros, pero cuando haya 10,000 registros, el inicio de la app tardará varios segundos y consumirá megas de red en cada recarga.
- **Qué servicio/endpoint ocuparía:** 
  - Los endpoints actuales `/api/incomes` y `/api/expenses` deberían recibir soporte de paginación (`?page=1&limit=50`).
  - La app solo pediría de 50 en 50 cuando el usuario haga scroll hacia abajo ("Lazy loading").
