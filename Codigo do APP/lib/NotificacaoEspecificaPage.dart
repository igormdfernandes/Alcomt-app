import 'package:alcomt_puro/minhaconta_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alcomt_puro/LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alcomt_puro/adicNotifPage.dart';
import 'package:intl/intl.dart';
import 'package:alcomt_puro/MenuPage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class NotificacaoEspecificaPage extends StatelessWidget {
  final FirebaseAuth auth;
  final QueryDocumentSnapshot<Object?> notificacao;
  const NotificacaoEspecificaPage({
    Key? key,
    required this.notificacao,
    required this.auth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data =
        notificacao.data() as Map<String, dynamic>;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Detalhes da Notificação',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black, // define o background preto do appBar
        leading: IconButton(
          //icone <-
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            // define a cor do ícone como branca
          ),
          onPressed: () {
            Navigator.push(
              //Navega para a página
              context,
              MaterialPageRoute(
                builder: (context) => MenuPage(
                  auth: FirebaseAuth.instance,
                ),
              ),
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 100.0),
            Text(
              'Bairro: ' + data['bairro'],
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Data: ' + DateFormat('dd/MM/yyyy').format(data['data'].toDate()),
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height:8.0),
            Text(
              'Usuário: ${data['usuario']}',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Descrição: ${data['descricao']}',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.0),
            if (data.containsKey('imagem'))
              Image.network(
                data['imagem'],
                width: 300,
                height: 300,
              ),
            SizedBox(height: 16.0),
            Text(
              'Tipo: ${data['tipo']}',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
