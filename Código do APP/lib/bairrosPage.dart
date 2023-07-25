import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:alcomt_puro/MenuPage.dart';
import 'package:alcomt_puro/LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBairroPage extends StatefulWidget {
  const AddBairroPage({Key? key, required this.auth}) : super(key: key);
  final FirebaseAuth auth;

  @override
  _AddBairroPageState createState() => _AddBairroPageState();
}

class Bairro {
  final String nome;
  final String idUsuario;

  Bairro({
    required this.nome,
    required this.idUsuario,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'idUsuario': idUsuario,
    };
  }
}

class _AddBairroPageState extends State<AddBairroPage> {
  List<String>? _bairros; // Lista de bairros
  Map<String, int>? _bairroIndices; // índices dos bairros
  List<bool> _selectedBairros = []; // bairros selecionados
  List<String>? _filteredBairros; // bairros filtrados

  final TextEditingController _searchController =
      TextEditingController(); // Controlador de texto para pesquisa de bairros

  // Salva os bairros selecionados no banco
  late String _uidFire; // ID do usuário logado
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    loadBairros(); // Carrega os bairros a partir do arquivo CSV
    _uidFire = widget.auth.currentUser!.uid; // Obtém o ID do usuário logado
  }

  //importa os bairros do Recife
  Future<void> loadBairros() async {
    final String bairrosString =
        await rootBundle.loadString('assets/bairrosRecife.csv');
    _bairros = convertCsvToListOfString(bairrosString);
    _bairroIndices = createBairroIndices(_bairros!);
    _selectedBairros = List.generate(_bairros!.length, (index) => false);
    setState(() {});
  }

  // Converte uma string CSV em uma lista de strings
  List<String> convertCsvToListOfString(String csvString) {
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(csvString);
    return rowsAsListOfValues.map((e) => e.first.toString()).toList();
  }

  // Cria um mapa de índices para cada bairro da lista de bairros
  Map<String, int> createBairroIndices(List<String> bairros) {
    Map<String, int> indices = {};
    if (_bairros != null) {
      for (int i = 0; i < _bairros!.length; i++) {
        indices[_bairros![i]] = i;
      }
    }
    return indices;
  }

  // Filtra a lista de bairros
  void searchBairros(String searchTerm) {
    setState(() {
      _filteredBairros = _bairros
          ?.where((bairro) =>
              bairro.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    });
  }

  void salvarBairrosSelecionados() async {
    List<Bairro> bairrosSelecionados = _selectedBairros
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => Bairro(nome: _bairros![entry.key], idUsuario: _uidFire))
        .toList();

    try {
      CollectionReference bairrosRef = firestore.collection('bairrosUsuarios');
      DocumentReference userBairrosRef = bairrosRef.doc(_uidFire);

      Map<String, dynamic> userBairrosData = {};
      for (var bairro in bairrosSelecionados) {
        userBairrosData[bairro.nome] = true;
      }

      await userBairrosRef.set(userBairrosData, SetOptions(merge: true));
    } catch (e) {
      print('Erro ao adicionar bairros selecionados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Adicionar Bairros de Interesse",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white, // define a cor do ícone como branca
            ),
            onPressed: () async {
              await widget.auth.signOut(); // Desautentica o usuário
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LoginPage(auth: widget.auth)),
              );
            }),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Image.asset(
              'assets/logo_alcomt.png',
              width: 200,
              height: 200,
            ),
            //exibe os bairros selecionados
            Wrap(
              children: _selectedBairros
                  .asMap()
                  .entries
                  .where((entry) => entry.value)
                  .map((entry) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _bairros![entry.key],
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => searchBairros(value),
                decoration: InputDecoration(
                  hintText: "Pesquisar bairro...",
                  hintStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height *
                  0.25, // Defina a altura desejada
              child: _bairros != null && _bairros!.isNotEmpty
                  ? ListView.builder(
                      itemCount: 94,
                      itemBuilder: (context, index) {
                        if (index >=
                            (_filteredBairros?.length ?? _bairros!.length)) {
                          return SizedBox();
                        }
                        final String bairro =
                            _filteredBairros?[index] ?? _bairros![index];
                        return CheckboxListTile(
                          value: _selectedBairros[_bairros!.indexOf(bairro)],
                          title: Text(
                            bairro,
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedBairros[_bairros!.indexOf(bairro)] =
                                  value ?? false;
                            });
                          },
                        );
                      },
                    )
                  : SizedBox(height: 40),
            ),
            // botão de cadastrar
            ElevatedButton(
              onPressed: () {
                salvarBairrosSelecionados();
                Navigator.push(
                  //Navega para a página
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MenuPage(auth: FirebaseAuth.instance)),
                ); // código para salvar o cadastro
              },
              child: Text(
                'Avançar',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(vertical: 20),
                ),
                textStyle: MaterialStateProperty.all(
                  TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
