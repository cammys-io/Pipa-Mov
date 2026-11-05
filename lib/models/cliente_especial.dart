/// Opciones comunes del catálogo SAT CFDI 4.0 para Uso del CFDI.
enum SatUsoCfdi {
  g03('G03', 'G03 - Gastos en general'),
  g01('G01', 'G01 - Adquisición de mercancías'),
  g02('G02', 'G02 - Devoluciones, descuentos o bonificaciones'),
  i01('I01', 'I01 - Construcciones'),
  i02('I02', 'I02 - Mobiliario y equipo de oficina'),
  i03('I03', 'I03 - Equipo de transporte'),
  i04('I04', 'I04 - Equipo de cómputo'),
  i08('I08', 'I08 - Otra maquinaria y equipo'),
  d01('D01', 'D01 - Honorarios médicos y gastos hospitalarios'),
  d02('D02', 'D02 - Gastos médicos por discapacidad'),
  d03('D03', 'D03 - Gastos funerales'),
  d04('D04', 'D04 - Donativos'),
  d07('D07', 'D07 - Primas por seguros de gastos médicos'),
  d10('D10', 'D10 - Pagos por servicios educativos'),
  s01('S01', 'S01 - Sin efectos fiscales'),
  cp01('CP01', 'CP01 - Pagos'),
  cn01('CN01', 'CN01 - Nómina');

  final String clave;
  final String label;
  const SatUsoCfdi(this.clave, this.label);

  static SatUsoCfdi? fromClave(String? clave) {
    if (clave == null) return null;
    for (final v in values) {
      if (v.clave.toUpperCase() == clave.toUpperCase()) return v;
    }
    return null;
  }
}

/// Opciones del catálogo SAT CFDI 4.0 para Régimen Fiscal.
enum SatRegimenFiscal {
  r601('601', '601 - General de Ley Personas Morales'),
  r603('603', '603 - Personas Morales con Fines no Lucrativos'),
  r605('605', '605 - Sueldos y Salarios'),
  r606('606', '606 - Arrendamiento'),
  r607('607', '607 - Enajenación o Adquisición de Bienes'),
  r608('608', '608 - Demás ingresos'),
  r610('610', '610 - Residentes en el Extranjero'),
  r611('611', '611 - Ingresos por Dividendos'),
  r612('612', '612 - Personas Físicas con Actividades Empresariales'),
  r614('614', '614 - Intereses'),
  r615('615', '615 - Obtención de premios'),
  r616('616', '616 - Sin obligaciones fiscales'),
  r620('620', '620 - Sociedades Cooperativas'),
  r621('621', '621 - Incorporación Fiscal (RIF)'),
  r622('622', '622 - Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras'),
  r623('623', '623 - Opcional para Grupos de Sociedades'),
  r624('624', '624 - Coordinados'),
  r625('625', '625 - Plataformas Tecnológicas'),
  r626('626', '626 - Régimen Simplificado de Confianza (RESICO)');

  final String clave;
  final String label;
  const SatRegimenFiscal(this.clave, this.label);

  static SatRegimenFiscal? fromClave(String? clave) {
    if (clave == null) return null;
    for (final v in values) {
      if (v.clave == clave) return v;
    }
    return null;
  }
}

/// Método de Pago SAT.
enum SatMetodoPago {
  pue('PUE', 'PUE - Pago en una sola exhibición'),
  ppd('PPD', 'PPD - Pago en parcialidades o diferido');

  final String clave;
  final String label;
  const SatMetodoPago(this.clave, this.label);

  static SatMetodoPago? fromClave(String? clave) {
    if (clave == null) return null;
    for (final v in values) {
      if (v.clave.toUpperCase() == clave.toUpperCase()) return v;
    }
    return null;
  }
}

/// Formas de Pago SAT.
enum SatFormaPago {
  efectivo('01', '01 - Efectivo'),
  cheque('02', '02 - Cheque nominativo'),
  transferencia('03', '03 - Transferencia electrónica'),
  tarjetaCredito('04', '04 - Tarjeta de crédito'),
  monederoElectronico('05', '05 - Monedero electrónico'),
  dineroElectronico('06', '06 - Dinero electrónico'),
  valesDespensa('08', '08 - Vales de despensa'),
  dacionPago('12', '12 - Dación en pago'),
  compensacion('17', '17 - Compensación'),
  tarjetaDebito('28', '28 - Tarjeta de débito'),
  tarjetaServicios('29', '29 - Tarjeta de servicios'),
  intermediario('31', '31 - Intermediario de pagos'),
  porDefinir('99', '99 - Por definir');

  final String clave;
  final String label;
  const SatFormaPago(this.clave, this.label);

  static SatFormaPago? fromClave(String? clave) {
    if (clave == null) return null;
    for (final v in values) {
      if (v.clave == clave) return v;
    }
    return null;
  }
}

/// Modelo de datos para Clientes Especiales (facturación e ingresos).
class ClienteEspecial {
  final String id;
  final String nombreEmpresa;
  final String? direccion;
  final bool requiereFactura;
  final bool activo;

  // Campos de facturación
  final String? rfc;
  final String? razonSocial;
  final String? regimenFiscal;
  final String? usoCfdi;
  final String? metodoPago;
  final String? formaPago;
  final String? calle;
  final String? numeroExterior;
  final String? numeroInterior;
  final String? colonia;
  final String? municipio;
  final String? ciudad;
  final String? estado;
  final String? pais;
  final String? codigoPostal;
  final String? telefono;
  final String? email;
  final String? referencia;
  final DateTime? createdAt;

  const ClienteEspecial({
    required this.id,
    required this.nombreEmpresa,
    this.direccion,
    this.requiereFactura = false,
    this.activo = true,
    this.rfc,
    this.razonSocial,
    this.regimenFiscal,
    this.usoCfdi,
    this.metodoPago,
    this.formaPago,
    this.calle,
    this.numeroExterior,
    this.numeroInterior,
    this.colonia,
    this.municipio,
    this.ciudad,
    this.estado,
    this.pais = 'México',
    this.codigoPostal,
    this.telefono,
    this.email,
    this.referencia,
    this.createdAt,
  });

  /// Etiqueta compacta para selects y listas (ej. "Constructora Roble · ROB901010ABC").
  String get etiqueta {
    if (rfc != null && rfc!.trim().isNotEmpty) {
      return '$nombreEmpresa · $rfc';
    }
    return nombreEmpresa;
  }

  factory ClienteEspecial.fromJson(Map<String, dynamic> json) {
    return ClienteEspecial(
      id: json['id']?.toString() ?? '',
      nombreEmpresa: json['nombreEmpresa']?.toString() ?? '',
      direccion: json['direccion']?.toString(),
      requiereFactura: json['requiereFactura'] == true,
      activo: json['activo'] ?? true,
      rfc: json['rfc']?.toString(),
      razonSocial: json['razonSocial']?.toString(),
      regimenFiscal: json['regimenFiscal']?.toString(),
      usoCfdi: json['usoCfdi']?.toString(),
      metodoPago: json['metodoPago']?.toString(),
      formaPago: json['formaPago']?.toString(),
      calle: json['calle']?.toString(),
      numeroExterior: json['numeroExterior']?.toString(),
      numeroInterior: json['numeroInterior']?.toString(),
      colonia: json['colonia']?.toString(),
      municipio: json['municipio']?.toString(),
      ciudad: json['ciudad']?.toString(),
      estado: json['estado']?.toString(),
      pais: json['pais']?.toString() ?? 'México',
      codigoPostal: json['codigoPostal']?.toString(),
      telefono: json['telefono']?.toString(),
      email: json['email']?.toString(),
      referencia: json['referencia']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nombreEmpresa': nombreEmpresa,
      'requiereFactura': requiereFactura,
      'activo': activo,
    };

    void putIfValid(String key, String? val) {
      if (val != null && val.trim().isNotEmpty) {
        map[key] = val.trim();
      }
    }

    putIfValid('direccion', direccion);
    putIfValid('telefono', telefono);
    putIfValid('email', email);
    putIfValid('referencia', referencia);

    if (requiereFactura) {
      putIfValid('rfc', rfc);
      putIfValid('razonSocial', razonSocial);
      putIfValid('regimenFiscal', regimenFiscal);
      putIfValid('usoCfdi', usoCfdi);
      putIfValid('metodoPago', metodoPago);
      putIfValid('formaPago', formaPago);
      putIfValid('calle', calle);
      putIfValid('numeroExterior', numeroExterior);
      putIfValid('numeroInterior', numeroInterior);
      putIfValid('colonia', colonia);
      putIfValid('municipio', municipio);
      putIfValid('ciudad', ciudad);
      putIfValid('estado', estado);
      putIfValid('pais', pais);
      putIfValid('codigoPostal', codigoPostal);
    }

    return map;
  }

  ClienteEspecial copyWith({
    String? id,
    String? nombreEmpresa,
    String? direccion,
    bool? requiereFactura,
    bool? activo,
    String? rfc,
    String? razonSocial,
    String? regimenFiscal,
    String? usoCfdi,
    String? metodoPago,
    String? formaPago,
    String? calle,
    String? numeroExterior,
    String? numeroInterior,
    String? colonia,
    String? municipio,
    String? ciudad,
    String? estado,
    String? pais,
    String? codigoPostal,
    String? telefono,
    String? email,
    String? referencia,
    DateTime? createdAt,
  }) {
    return ClienteEspecial(
      id: id ?? this.id,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      direccion: direccion ?? this.direccion,
      requiereFactura: requiereFactura ?? this.requiereFactura,
      activo: activo ?? this.activo,
      rfc: rfc ?? this.rfc,
      razonSocial: razonSocial ?? this.razonSocial,
      regimenFiscal: regimenFiscal ?? this.regimenFiscal,
      usoCfdi: usoCfdi ?? this.usoCfdi,
      metodoPago: metodoPago ?? this.metodoPago,
      formaPago: formaPago ?? this.formaPago,
      calle: calle ?? this.calle,
      numeroExterior: numeroExterior ?? this.numeroExterior,
      numeroInterior: numeroInterior ?? this.numeroInterior,
      colonia: colonia ?? this.colonia,
      municipio: municipio ?? this.municipio,
      ciudad: ciudad ?? this.ciudad,
      estado: estado ?? this.estado,
      pais: pais ?? this.pais,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      referencia: referencia ?? this.referencia,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
