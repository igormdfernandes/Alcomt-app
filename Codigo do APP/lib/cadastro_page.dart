import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alcomt_puro/bairrosPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class CadastroPage extends StatefulWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  // controladores para os campos do formulário
  TextEditingController _nomeController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _telefoneController = TextEditingController();
  TextEditingController _senhaController = TextEditingController();
  TextEditingController _confirmaSenhaController = TextEditingController(); 

  Future<void> _cadastrarUsuario() async {
    try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text, password: _senhaController.text);
        print("Usuário criado com sucesso: ${userCredential.user!.uid}");

        Map<String, dynamic> userData = {
          'nome': _nomeController.text,
          'email': _emailController.text,
          'telefone': _telefoneController.text
        };
        
        //inserir os dados na coleção usuários
        await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).set(userData);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddBairroPage(auth: FirebaseAuth.instance)),
        );
    } on FirebaseAuthException catch (e) {
    if (e.code == 'weak-password') {
      print('A senha fornecida é muito fraca.');
    } else if (e.code == 'email-already-in-use') {
      print('O e-mail já está em uso.');
    }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // define o background preto
      appBar: AppBar(
        title: Text(
          'Cadastro',
          style:
              TextStyle(color: Colors.white), //define a cor do título em branco
        ), // título da página de cadastro
        backgroundColor: Colors.black, // define o background preto do appBar
        leading: IconButton(
          //icone <-
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white, // define a cor do ícone como branca
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/logo_alcomt.png',
              width: 200,
              height: 200,
            ),
            // campo de texto para o nome
            TextFormField(
              controller: _nomeController,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14), // define a fonte e cor do texto
              decoration: InputDecoration(
                labelText: 'Nome',
                hintText: 'Digite seu nome',
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14), // define a fonte e cor do rótulo
                filled: true, // ativa o background
                fillColor: Colors.white.withOpacity(
                    0.2), // define o background da caixa de texto com transparência
              ),
            ),
            SizedBox(height: 12),
            // campo de texto para o e-mail
            TextFormField(
              controller: _emailController,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14), // define a fonte e cor do texto
              decoration: InputDecoration(
                labelText: 'E-mail',
                hintText: 'nome@email.com',
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14), // define a fonte e cor do rótulo
                filled: true,
                fillColor: Colors.white.withOpacity(
                    0.2), // define o background da caixa de texto com transparência
              ),
              validator: (email) {
                if (email == null || email.isEmpty) {
                  return 'Digite seu e-mail';
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            // campo de texto para o telefone
            TextFormField(
              controller: _telefoneController,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14), // define a fonte e cor do texto
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                ],
              decoration: InputDecoration(
                labelText: 'Telefone',
                hintText: '(xx) xxxxx-xxxx',
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14), // define a fonte e cor do rótulo
                filled: true, // ativa o background
                fillColor: Colors.white.withOpacity(
                    0.2), // define o background da caixa de texto com transparência
              ),
            ),
            SizedBox(height: 12),
            // campo de texto para a senha
            TextFormField(
              controller: _senhaController,
              obscureText: true, // mascara a senha com pontos
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14), // define a fonte e cor do texto
              decoration: InputDecoration(
                labelText: 'Senha', // ativa o background
                hintText: 'Digite sua senha',
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14), // define a fonte e cor do rótulo
                filled: true,
                fillColor: Colors.white.withOpacity(
                    0.2), // define o background da caixa de texto com transparência
              ),
            ),
            SizedBox(height: 12),
            // campo de texto para confirmar a senha
            TextFormField(
              controller: _confirmaSenhaController,
              obscureText: true, // mascara a senha com pontos
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14), // define a fonte e cor do texto
              decoration: InputDecoration(
                labelText: 'Confirmar a Senha',
                hintText: 'Digite novamente a senha',
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14), // define a fonte e cor do rótulo
                filled: true, // ativa o background
                fillColor: Colors.white.withOpacity(
                    0.2), // define o background da caixa de texto com transparência
              ),
              validator: (value) {
                if (value != _senhaController.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            // Botão de cadastrar
            ElevatedButton(
              onPressed: () {
                _cadastrarUsuario();
              },
              child: Text(
                'Cadastrar',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(vertical: 15),
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