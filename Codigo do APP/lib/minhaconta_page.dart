import 'package:flutter/material.dart';
import 'package:alcomt_puro/editar_areas_page.dart';
import 'package:alcomt_puro/MenuPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alcomt_puro/AltSenhaPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MinhaContaPage extends StatefulWidget {
  final FirebaseAuth auth;
  const MinhaContaPage({Key? key, required this.auth}) : super(key: key);

  @override
  _MinhaContaPageState createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  String nome = '';
  String email = '';
  String telefone = '';
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    //obtem os dados do Firestore e atualiza o estado do widget com os valores obtidos
    final userId = widget.auth.currentUser!.uid;
    final userRef = firestore.collection('usuarios').doc(userId); 

    userRef.get().then((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          nome = documentSnapshot.data()!['nome'];
          email = documentSnapshot.data()!['email'];
          telefone = documentSnapshot.data()!['telefone'];
        });
      } else {
        print('Dados não encontrados');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Minha Conta',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black, // define o background preto do appBar
        leading: IconButton(
          //icone <-
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white, // define a cor do ícone como branca
          ),
          onPressed: () {
            Navigator.push(
              //Navega para a página
              context,
              MaterialPageRoute(
                  builder: (context) => MenuPage(auth: widget.auth)),
            );
          },
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.0),
            Text(
              'Nome',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              nome,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'E-mail',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              email,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Telefone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              telefone,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                // Ação do botão "Editar áreas de interesse"
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditBairroPage(auth: FirebaseAuth.instance)),
                ); // código para salvar o cadastro
              },
              child: Text(
                'Editar áreas de interesse',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Ação do botão "Alterar senha"
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AltSenhaPage(auth: FirebaseAuth.instance)),
                );
              },
              child: Text(
                'Alterar senha',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
