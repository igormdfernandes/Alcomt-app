import 'package:alcomt_puro/minhaconta_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alcomt_puro/LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alcomt_puro/adicNotifPage.dart';
import 'package:alcomt_puro/NotificacaoEspecificaPage.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MenuPage extends StatefulWidget {
  final FirebaseAuth auth;
  const MenuPage({Key? key, required this.auth}) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.auth.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    //final user = FirebaseAuth.instance.currentUser;
    //final uid = user?.uid;

    Future<Map<String, dynamic>> _getUsuarioBairros() async {
      final document = await FirebaseFirestore.instance
          .collection('bairrosUsuarios')
          .doc(_currentUser.uid)
          .get();
      return document.data() ?? {};
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Menu',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () async {
            await widget.auth.signOut(); // Desautentica o usuário
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LoginPage(auth: widget.auth)),
            );
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                  minHeight: 40), // altura mínima definida para o container
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Spacer(),
                  Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/person-icon.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      //botão minha conta
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      MinhaContaPage(auth: widget.auth)),
                            );
                          },
                          child: SizedBox(
                            width: 80,
                            height: 40,
                          ),
                        ),
                      )),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 0),
              child: Image.asset(
                'assets/logo_alcomt.png',
                width: 200,
                height: 200,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 0, bottom: 10.0),
              child: Text(
                'Últimas atualizações:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _getUsuarioBairros(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final usuarioBairros = snapshot.data!;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notificacoes')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    // Ordena as notificações por data.
                    final notificacoesOrdenadas = snapshot.data!.docs;
                    notificacoesOrdenadas
                        .sort((a, b) => b['data'].compareTo(a['data']));

                    final notificacoesFiltradas =
                        notificacoesOrdenadas.where((notificacao) {
                      final notificacaoBairro =
                          notificacao['bairro'] as String?;
                      return notificacaoBairro != null &&
                          usuarioBairros[notificacaoBairro] == true;
                    }).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: notificacoesFiltradas.length,
                      itemBuilder: (context, index) {
                        final notificacao = notificacoesFiltradas[index];
                        final data = notificacao['data']
                            .toDate(); // convertendo Timestamp para DateTime
                        final dataFormatada = DateFormat('dd/MM/yyyy')
                            .format(data); // formatando a data

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificacaoEspecificaPage(
                                    notificacao: notificacao,
                                    auth: widget.auth),
                              ),
                            );
                          },
                          child: Card(
                            child: ListTile(
                              title: Text(
                                notificacao['bairro'],
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notificacao['descricao'],
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Enviado em ${DateFormat('dd/MM/yyyy HH:mm').format(notificacao['data'].toDate())}',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.only(bottom: 16.0),
        child: SizedBox(
          width: 60.0,
          height: 60.0,
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => adicNotifPage(
                    auth: widget.auth,
                    location: null, // passar para a outra página
                    address: null,
                  ),
                ),
              );
            },
            child: Icon(
              Icons.add,
              size: 70.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
