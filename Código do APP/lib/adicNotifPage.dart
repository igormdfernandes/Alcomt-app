import 'package:flutter/material.dart';
import 'package:alcomt_puro/MenuPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:alcomt_puro/mapPage.dart';

//import 'package:alcomt_puro/mapPage.dart';

class adicNotifPage extends StatefulWidget {
  final FirebaseAuth auth;
  final LatLng? location;
  final String? address;
  const adicNotifPage(
      {Key? key,
      required this.auth,
      required this.location,
      required this.address})
      : super(key: key);

  @override
  _adicNotifPageState createState() => _adicNotifPageState();
}

class _adicNotifPageState extends State<adicNotifPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String username = '';

  List<String> _bairros = []; // Lista de bairros
  List<String> _tiposAlerta = [
    "Acidente com Vítimas",
    "Acidente sem Vítimas",
    "Alagamento",
    "Alto fluxo",
    "Atropelamento de Animal",
    "Baixa iluminação",
    "Batida",
    "Chuva",
    "Queda de Árvore",
    "Rua interditada",
  ];
  String selectedBairro = '';
  String selectedTipoAlerta = '';
  TextEditingController _descricaoController = TextEditingController();
  double lat = 0.0; //mapa
  double long = 0.0; //mapa
  String erro = ''; //mapa
  String endereco = '';
  String _path = '';
  String imageName = '';
  FirebaseStorage storage = FirebaseStorage.instance;
  File? _image;
  final CollectionReference<Map<String, dynamic>> notificacoesRef =
      FirebaseFirestore.instance.collection('notificacoes');

  @override
  void initState() {
    super.initState();
    loadBairros(); // Carrega os bairros a partir do arquivo CSV
    lat = widget.location?.latitude ?? 0.0;
    long = widget.location?.longitude ?? 0.0;
    endereco = widget.address ?? '';
  }

// Upload de imagens
  String generateImageName() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_${_image?.hashCode}.png';
  }

  Future<void> uploadFile(BuildContext context) async {
    try {
      final Reference ref = storage.ref().child(
          'images/${DateTime.now().millisecondsSinceEpoch.toString()}.png');
      final SettableMetadata metadata = SettableMetadata(
          contentType: 'image/*',
          customMetadata: {'order': 'file upload test'});
      final UploadTask uploadTask = ref.putFile(_image!, metadata);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      final String urlDownload = await snapshot.ref.getDownloadURL();
      print('URL de Download: $urlDownload');

      final String uid = widget.auth.currentUser!.uid;
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await firestore.collection('usuarios').doc(uid).get();

      final String nome = docSnapshot.data()!['Nome'];
      username = nome;

      await notificacoesRef.add({
        'tipo_alerta': selectedTipoAlerta,
        'bairro': selectedBairro,
        'imagem_url': urlDownload,
        'descricao': _descricaoController.text,
        'data': DateTime.now(),
        'TTL': "",
        'usuario': nome
      });
    } catch (e) {
      print('Erro ao fazer upload do arquivo: $e');
    }
  }

  Future<Directory> getApplicationDocumentsDirectory() async {
    return await path_provider.getApplicationDocumentsDirectory();
  }

  void _pickImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.getImage(source: source);

    if (pickedFile == null) {
      return;
    }

    final appDir = await path_provider.getApplicationDocumentsDirectory();
    imageName = generateImageName();
    final imagePath = path.join(appDir.path, imageName);

    try {
      await File(pickedFile.path).copy(imagePath);
      setState(() {
        _image = File(imagePath);
      });
    } catch (e) {
      print('Erro ao salvar a imagem: $e');
    }
  }

  //importa os bairros do Recife
  Future<void> loadBairros() async {
    final String bairrosString =
        await rootBundle.loadString('assets/bairrosRecife.csv');
    _bairros.addAll(convertCsvToListOfString(bairrosString));
    setState(() {});
  }

  // Converte uma string CSV em uma lista de strings
  List<String> convertCsvToListOfString(String csvString) {
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(csvString);
    return rowsAsListOfValues.map((e) => e.first.toString()).toList();
  }

  void updateSelectedBairro(String? value) {
    setState(() {
      selectedBairro = value!;
    });
  }

  void updateSelectedTipoAlerta(String? value) {
    setState(() {
      selectedTipoAlerta = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Adicionar Notificação",
            style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/logo_alcomt.png',
              width: 250,
              height: 250,
            ),
            Text("Tipo de alerta", style: TextStyle(color: Colors.white)),
            SizedBox(height: 8.0),
            _buildDropdownButtonAlerta(
                _tiposAlerta), //seleciona o tipo de alerta
            SizedBox(height: 16.0),
            Text("Bairro", style: TextStyle(color: Colors.white)),
            SizedBox(height: 8.0),
            _buildDropdownButtonBairro(_bairros), //seleciona o bairro
            SizedBox(height: 16.0),
            Text("Descrição", style: TextStyle(color: Colors.white)),
            SizedBox(height: 8.0),
            Container(
              height: 200,
              child: TextFormField(
                //campo de descrição
                controller: _descricaoController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Descreva aqui mais detalhes sobre o alerta...",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            //Carregar imagem
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Container(
                        child: Wrap(
                          children: <Widget>[
                            ListTile(
                              leading: Icon(Icons.camera_alt),
                              title: Text('Câmera'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.photo_library),
                              title: Text('Galeria'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text(
                'Adicionar imagem',
                style: TextStyle(
                  color: Colors.black, // define a cor do texto como preto
                ),
              ),
            ),
            SizedBox(height: 16.0),
            //Navegar para a tela do mapa
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => mapPage()),
                );
              },
              child: Text(
                'Marcar Posição',
                style: TextStyle(
                  color: Colors.black, // define a cor do texto como preto
                ),
              ),
            ),
            //enviar dados
            ElevatedButton(
              onPressed: () async {
                final User? user = FirebaseAuth.instance.currentUser;
                final String uid = user!.uid;

                // Buscar o documento de usuário correspondente na coleção "usuarios"
                final DocumentSnapshot userDoc = await FirebaseFirestore
                    .instance
                    .collection('usuarios')
                    .doc(uid)
                    .get();
                final Map<String, dynamic> userData =
                    userDoc.data() as Map<String, dynamic>;
                final String nome = userData['nome'] as String;
                // Extrair o nome do usuário do documento de usuário e salvá-lo na variável "nome"
                if (_image != null) {
                  // Mostrar SnackBar informando que a imagem está sendo enviada
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Enviando imagem...')),
                  );
                  final metadata = SettableMetadata(
                    contentType: 'image/*',
                    customMetadata: {'picked-file-path': _image!.path},
                  );
                  final snapshot = await FirebaseStorage.instance
                      .ref()
                      .child('images')
                      .child(imageName)
                      .putFile(_image!, metadata);
                  final imageUrl = await snapshot.ref.getDownloadURL();
                  notificacoesRef.add({
                    'tipo': selectedTipoAlerta,
                    'bairro': selectedBairro,
                    'endereço': endereco,
                    'descricao': _descricaoController.text,
                    'latitude': lat,
                    'longitude': long,
                    'imagem': imageUrl,
                    'data': DateTime.now(),
                    'TTL': "",
                    'usuario': nome,
                  });
                  // Mostrar SnackBar informando que a imagem foi enviada
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Imagem enviada com sucesso!')));
                } else {
                  notificacoesRef.add({
                    'tipo': selectedTipoAlerta,
                    'bairro': selectedBairro,
                    'endereço': endereco,
                    'descricao': _descricaoController.text,
                    'latitude': lat,
                    'longitude': long,
                    'data': DateTime.now(),
                    'TTL': "",
                    'usuario': nome,
                  });
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MenuPage(auth: widget.auth)),
                );
              },
              child: Text(
                "Enviar",
                style: TextStyle(
                  color: Colors.black, // define a cor do texto como preto
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownButtonBairro(List<String> bairros) {
    String? selectedBairro = bairros.isNotEmpty ? bairros[0] : null;
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        hintText: "Selecione o bairro",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      value: selectedBairro,
      onChanged: (String? value) => updateSelectedBairro(value),
      items: bairros
          .map(
            (bairro) => DropdownMenuItem<String>(
              value: bairro,
              child: Text(bairro),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDropdownButtonAlerta(List<String> tiposAlerta) {
    String? selectedTipoAlerta = tiposAlerta.isNotEmpty ? tiposAlerta[0] : null;
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        hintText: "Selecione o tipo de alerta",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      value: selectedTipoAlerta,
      onChanged: (String? value) => updateSelectedTipoAlerta(value),
      items: tiposAlerta
          .map(
            (tipoAlerta) => DropdownMenuItem<String>(
              value: tipoAlerta,
              child: Text(tipoAlerta),
            ),
          )
          .toList(),
    );
  }
}
