/// Modelo para CREAR/ENVIAR solicitudes de fertilizantes
class SolicitudFertilizante {
  final String tipoFertilizante;
  final double cantidad;
  final String fechaRequerida;
  final String motivo;
  final String notas;
  final String prioridad;
  final String? finca;      
  final String? ubicacion;  

  SolicitudFertilizante({
    required this.tipoFertilizante,
    required this.cantidad,
    required this.fechaRequerida,
    required this.motivo,
    required this.notas,
    required this.prioridad,
    this.finca,      
    this.ubicacion, 
  });

  Map<String, dynamic> toJson() => {
        "tipoFertilizante": tipoFertilizante,
        "cantidad": cantidad,
        "fechaRequerida": fechaRequerida,
        "motivo": motivo,
        "notas": notas,
        "prioridad": prioridad,
        "finca": finca ?? '',        
        "ubicacion": ubicacion ?? '', 
      };
}