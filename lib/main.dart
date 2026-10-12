import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:light/light.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

void main() => runApp(const MaterialApp(home: SensoresPage()));

class SensoresPage extends StatefulWidget {
  const SensoresPage({super.key});
  @override
  State<SensoresPage> createState() => _SensoresPageState();
}

class _SensoresPageState extends State<SensoresPage> {
  final _battery = Battery();

  int _nivel = 0;
  BatteryState _estado = BatteryState.unknown;
  double _lux = 0;
  bool _luzDisponible = false;
  bool _cerca = false;
  int? _raw; // valor crudo del sensor de proximidad (diagnóstico)

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    // Batería
    _nivel = await _battery.batteryLevel;
    _subs.add(_battery.onBatteryStateChanged.listen((e) async {
      final n = await _battery.batteryLevel;
      if (!mounted) return;
      setState(() {
        _estado = e;
        _nivel = n;
      });
    }));

    // Luz (solo Android)
    try {
      _subs.add(Light().lightSensorStream.listen(
        (v) {
          if (!mounted) return;
          setState(() {
            _luzDisponible = true;
            _lux = v.toDouble();
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _luzDisponible = false);
        },
      ));
    } catch (_) {
      _luzDisponible = false;
    }

    // Proximidad
    _subs.add(ProximitySensor.events.listen((e) {
      if (!mounted) return;
      setState(() {
        _raw = e;
        _cerca = e > 0;
      });
    }));

    if (mounted) setState(() {});
  }

  String _textoEstado(BatteryState e) {
    switch (e) {
      case BatteryState.charging:
        return 'Cargando';
      case BatteryState.discharging:
        return 'Desconectado';
      case BatteryState.full:
        return 'Completa';
      case BatteryState.connectedNotCharging:
        return 'Conectado (sin cargar)';
      default:
        return 'Desconocido';
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel(); // evita fugas de memoria y consumo de batería
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = _luzDisponible && _lux < 20;
    return Scaffold(
      backgroundColor: oscuro ? Colors.black87 : Colors.white,
      appBar: AppBar(title: const Text('Sensores')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tarjeta(
            icono: Icons.battery_full,
            titulo: 'Batería',
            valor: '$_nivel% · ${_textoEstado(_estado)}',
          ),
          _Tarjeta(
            icono: Icons.light_mode,
            titulo: 'Luz',
            valor: _luzDisponible
                ? '${_lux.toStringAsFixed(0)} lux'
                : 'Sensor no disponible',
          ),
          _Tarjeta(
            icono: Icons.sensors,
            titulo: 'Proximidad',
            valor: _cerca
                ? 'Objeto CERCA (valor: $_raw)'
                : 'Despejado (valor: $_raw)',
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.icono,
    required this.titulo,
    required this.valor,
  });
  final IconData icono;
  final String titulo, valor;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icono, size: 32),
          title: Text(titulo),
          subtitle: Text(valor),
        ),
      );
}