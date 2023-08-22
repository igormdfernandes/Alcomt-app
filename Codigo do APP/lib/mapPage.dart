import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alcomt_puro/adicNotifPage.dart';
import 'package:firebase_auth/firebase_auth.dart';

//pagina mapa
class mapPage extends StatefulWidget {
  @override
  _mapPageState createState() => _mapPageState();
}

class _mapPageState extends State<mapPage> {
  // Declaração das variáveis que serão utilizadas
  GoogleMapController? _controller;
  LatLng? _currentLocation;
  LatLng? _markedLocation;
  String? _address;

  // Configuração inicial do mapa
  static final CameraPosition initialPosition = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 14.0,
  );

  // Função que marca um ponto no mapa
  void _onMapTapped(LatLng location) async {
    setState(() {
      _markedLocation = location;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _markedLocation!.latitude, _markedLocation!.longitude);
      Placemark placemark = placemarks[0];
      setState(() {
        _address =
            "${placemark.thoroughfare}, ${placemark.subThoroughfare} - ${placemark.subLocality}, ${placemark.locality} - ${placemark.administrativeArea}";
      });
    } on PlatformException catch (e) {
      print('Erro ao buscar endereço: ${e.toString()}');
      setState(() {
        _address = 'Não foi possível obter o endereço';
      });
    }
  }

  // Função que salva a localização marcada e envia para a próxima página
  void _saveLocation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => adicNotifPage(
          auth: FirebaseAuth.instance,
          location: _markedLocation, // passar para a outra página
          address: _address, // passar para a outra página
        ),
      ),
    );
  }

  // Verifica se o serviço de localização está habilitado
  Future<bool> isLocationServiceEnabled() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    return true;
  }

  Future<bool> checkPermission() async {
    var permissionStatus = await Permission.location.status;
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await Permission.location.request();
      if (permissionStatus != PermissionStatus.granted &&
          permissionStatus != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  // Obtém a localização atual do usuário
  Future<void> _getCurrentLocation() async {
    if (await Geolocator.isLocationServiceEnabled()) {
      if (await Permission.location.request().isGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      } else {
        // a permissão foi negada
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Permissão de localização"),
              content: Text(
                  "Para usar o aplicativo, você precisa habilitar a permissão de localização."),
              actions: <Widget>[
                TextButton(
                  child: Text("Cancelar"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Habilitar"),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (await Permission.location.request().isGranted) {
                      // a permissão foi concedida
                      // chama a função novamente para obter a localização atual
                      _getCurrentLocation();
                    }
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      // o serviço de localização não está habilitado
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Serviço de localização desativado'),
          content: Text(
              'O serviço de localização está desativado. Por favor, habilite o serviço de localização nas configurações do dispositivo.'),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<Position?> getCurrentPosition(
      {LocationAccuracy desiredAccuracy = LocationAccuracy.high,
      Duration? timeout}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationServiceDisabledException();
    }

    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      throw PermissionDeniedException('Permissão Negada!!');
    }

    if (status == PermissionStatus.granted) {
      try {
        return await Geolocator.getCurrentPosition(
            desiredAccuracy: desiredAccuracy);
      } on PlatformException catch (e) {
        throw _convertPlatformException(e);
      }
    }

    // Request permission
    status = await requestPermission();
    if (status == PermissionStatus.granted) {
      try {
        return await Geolocator.getCurrentPosition(
            desiredAccuracy: desiredAccuracy);
      } on PlatformException catch (e) {
        throw _convertPlatformException(e);
      }
    }

    throw PermissionDeniedException('Permissão Negada!!');
  }

  Exception _convertPlatformException(PlatformException e) {
    // Converta a exceção do tipo PlatformException para uma exceção personalizada
    return Exception('Ocorreu um erro: ${e.message}');
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        onTap: _onMapTapped,
        initialCameraPosition: _currentLocation != null
            ? CameraPosition(
                target: _currentLocation!,
                zoom: 14.0,
              )
            : initialPosition,
        markers: _markedLocation != null
            ? {
                Marker(
                  markerId: MarkerId("markedLocation"),
                  position: _markedLocation!,
                ),
              }
            : {},
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _markedLocation != null ? _saveLocation : null,
        child: Icon(Icons.save),
      ),
    );
  }
}
