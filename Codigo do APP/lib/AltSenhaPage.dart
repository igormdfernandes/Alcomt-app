import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alcomt_puro/minhaconta_page.dart';

class AltSenhaPage extends StatefulWidget {
  final FirebaseAuth auth;
  const AltSenhaPage({Key? key, required this.auth}) : super(key: key);

  @override
  _AltSenhaPageState createState() => _AltSenhaPageState();
}

class _AltSenhaPageState extends State<AltSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  String _senhaAntiga = '';
  String _novaSenha = '';

  Future<void> updatePassword(String newPassword) async {
    final user = widget.auth.currentUser;
    final credential = EmailAuthProvider.credential(
      email: user!.email!,
      password: _senhaAntiga,
    );
    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      final userRef =
          FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
      await userRef.update({'senha': newPassword});
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Senha incorreta. Tente novamente.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar senha. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.auth.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('Alterar senha')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Senha antiga'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Insira sua senha antiga:';
                  }
                  // Adicione a validação da senha antiga aqui, se necessário.
                  return null;
                },
                onSaved: (value) {
                  _senhaAntiga = value ?? '';
                },
              ),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Nova senha'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Insira sua nova senha:';
                  }
                  // Adicione a validação da nova senha aqui, se necessário.
                  return null;
                },
                onSaved: (value) {
                  _novaSenha = value ?? '';
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() == true) {
                    _formKey.currentState?.save();
                    await updatePassword(_novaSenha);
                  }
                },
                child: Text('Salvar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
