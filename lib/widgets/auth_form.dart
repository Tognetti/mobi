import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobi/exceptions/exceptions.dart';
import 'package:mobi/widgets/user_image_picker.dart';

class AuthForm extends StatefulWidget {
  AuthForm(this.submitFn, this.isLoading);

  final bool isLoading;
  final void Function(
      String email, String password, String username, String cidade, String estado, bool isLogin, File image, BuildContext ctx) submitFn;

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  String _userEmail = '';
  String _userName = '';
  String _userPassword = '';
  String _cidade = '';
  String _estado = '';
  var _userImageFile;

  void _trySubmit() {
    final isValid = _formKey.currentState.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState.save();
      widget.submitFn(_userEmail.trim(), _userPassword, _userName, _cidade, _estado, _isLogin, _userImageFile, context);
    }
  }

  void _pickedImage(File image) {
    _userImageFile = image;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 7,
      margin: EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                if (!_isLogin) UserImagePicker(_pickedImage, null),
                TextFormField(
                  key: ValueKey('email'),
                  decoration: InputDecoration(labelText: 'E-mail'),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Insira um e-mail';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _userEmail = value;
                  },
                ),
                if (!_isLogin)
                  TextFormField(
                    key: ValueKey('nome'),
                    decoration: InputDecoration(labelText: 'Nome'),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Insira um nome';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _userName = value;
                    },
                  ),
                if (!_isLogin)
                  TextFormField(
                    key: ValueKey('cidade'),
                    decoration: InputDecoration(labelText: 'Cidade'),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Insira sua cidade';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _cidade = value;
                    },
                  ),
                if (!_isLogin)
                  TextFormField(
                    key: ValueKey('estado'),
                    decoration: InputDecoration(labelText: 'Estado'),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Insira seu estado';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _estado = value;
                    },
                  ),
                TextFormField(
                  obscureText: true,
                  key: ValueKey('senha'),
                  decoration: InputDecoration(labelText: 'Senha'),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Insira uma senha';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _userPassword = value;
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                if (widget.isLoading) CircularProgressIndicator(),
                if (!widget.isLoading)
                  RaisedButton(
                    color: Colors.green,
                    child: _isLogin
                        ? Text(
                            "Entrar",
                            style: TextStyle(color: Colors.white),
                          )
                        : Text(
                            "Cadastrar",
                            style: TextStyle(color: Colors.white),
                          ),
                    onPressed: _trySubmit,
                  ),
                if (!widget.isLoading)
                  FlatButton(
                    textColor: Theme.of(context).primaryColor,
                    child: _isLogin ? Text("Criar nova conta") : Text("Já tenho uma conta"),
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
