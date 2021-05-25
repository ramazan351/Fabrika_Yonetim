import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:irem_deneme/home_page.dart';
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';

import 'package:mysql1/mysql1.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

String serverIP = "";
int portId;

String dbName = "";
String dbUser = "";
String dbPassword = "";
String userName = "";
String password = "";
String nameSure = "";

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final alertFormKey = GlobalKey<FormState>();
  int _start = 2;
  Timer timer;
  bool isThere = false;
  TextEditingController _controllerServIp,
      _controllerPortId,
      _controllerDbName,
      _controllerDbUserName,
      _controllerDbUserPass;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSharedInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        actions: <Widget>[
          FlatButton(
              onPressed: () => serverAlert(),
              child: Icon(Icons.connect_without_contact_outlined))
        ],
        title: Text("Kullanıcı Girişi"),
      ),
      body: Container(
        margin: EdgeInsets.all(10),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                onSaved: (dName) {
                  setState(() {
                    userName = dName;
                  });
                },
                validator: (String s) {
                  if (s == "") {
                    return "Kullanıcı adı boş geçilemez";
                  } else
                    return null;
                },
                decoration: InputDecoration(
                    labelText: "Kullanıcı Adı", hintText: "Kullanıcı Adı"),
              ),
              TextFormField(
                onSaved: (dName) {
                  setState(() {
                    password = dName;
                  });
                },
                validator: (String s) {
                  if (s == "") {
                    return "Şifre boş geçilemez";
                  } else
                    return null;
                },
                decoration:
                    InputDecoration(labelText: "Şifre", hintText: "Şifre"),
              ),
              RaisedButton(
                onPressed: () => login(),
                child: Text("Giriş"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future sharedRegister() async {
    SharedPreferences _userName = await SharedPreferences.getInstance();
    SharedPreferences _userpass = await SharedPreferences.getInstance();
    SharedPreferences _serverIP = await SharedPreferences.getInstance();
    SharedPreferences _portId = await SharedPreferences.getInstance();
    SharedPreferences _dbName = await SharedPreferences.getInstance();
    SharedPreferences _dbUser = await SharedPreferences.getInstance();
    SharedPreferences _dbPass = await SharedPreferences.getInstance();
    _userName.setString("username", userName);
    _userpass.setString("password", password);
    _serverIP.setString("ip", serverIP);
    _portId.setInt("portId", portId);
    _dbName.setString("dbName", dbName);
    _dbUser.setString("dbUser", dbUser);
    _dbPass.setString("dbPass", dbPassword);
  }

  Future getSharedInfo() async {
    SharedPreferences _userName = await SharedPreferences.getInstance();
    SharedPreferences _userpass = await SharedPreferences.getInstance();
    SharedPreferences _serverIP = await SharedPreferences.getInstance();
    SharedPreferences _portId = await SharedPreferences.getInstance();
    SharedPreferences _dbName = await SharedPreferences.getInstance();
    SharedPreferences _dbUser = await SharedPreferences.getInstance();
    SharedPreferences _dbPass = await SharedPreferences.getInstance();
    userName = _userName.getString("username");
    password = _userpass.getString("password");
    serverIP = _serverIP.getString("ip");
    portId = _portId.getInt("portId");
    dbName = _dbName.getString("dbName");
    dbUser = _dbUser.getString("dbUser");
    dbPassword = _dbPass.getString("dbPass");
    _controllerServIp = new TextEditingController(text: serverIP);
    _controllerPortId = TextEditingController(text: portId.toString());
    _controllerDbName = TextEditingController(text: dbName);
    _controllerDbUserName = TextEditingController(text: dbUser);
    _controllerDbUserPass = TextEditingController(text: dbPassword);
    if (userName != "" && serverIP != null) {
      LmySqlAction().whenComplete(() => isThere=true);

    } else
      startTimer();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    timer = new Timer.periodic(
        oneSec,
        (Timer timer) => setState(() {
              if (_start < 1) {
                timer.cancel();
                //FONKSİYONUNU YAZ
                serverAlert();
              } else {
                _start = _start - 1;
              }
            }));
  }

  Future LmySqlAction() async {
    print(userName.toString() +
        password.toString() +
        serverIP.toString() +
        portId.toString() +
        dbName.toString() +
        "  MySqlAction");
    try {
      final conn = await MySqlConnection.connect(ConnectionSettings(
          host: serverIP,
          port: portId,
          user: dbUser,
          password: dbPassword,
          db: dbName));

      var _login = await conn.query(
          "select * from user where username like '$userName' and password like '$password'");
      if (_login.isNotEmpty) {
        Fluttertoast.showToast(msg: "Giriş yapıldı");
        Navigator.pushNamed(context, "/homepage");

        print("mysql giriş yapıldı");

        for (var row in _login) {
          setState(() {
            nameSure = row['adsoyad'];
          });
        }
      } else {
        Fluttertoast.showToast(msg: "Böyle bir kullanıcı yok");
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: " Giriş Yapılamadı, Server bilgilerini kontrol ediniz..",
          backgroundColor: Colors.red);
      startTimer();
    }
  }

  login() {
    if (formKey.currentState.validate()) {
      formKey.currentState.save();
      sharedRegister();
      LmySqlAction();
    }
  }

  serverAlert() {
    showDialog(
        barrierDismissible: false, //sayfanın herhangi bir yerine tıklandığında diyalogun kapanmasını engeller
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Form(
              key: alertFormKey,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _controllerServIp,
                      onSaved: (sIp) {
                        setState(() {
                          serverIP = sIp;
                        });
                      },
                      validator: (String s) {
                        if (s == "") {
                          return "server ip boş geçilemez";
                        } else
                          return null;
                      },
                      decoration: InputDecoration(
                          labelText: "Server Ip", hintText: "Server Ip"),
                    ),
                    TextFormField(
                      controller: _controllerPortId,
                      keyboardType: TextInputType.number,
                      onSaved: (pId) {
                        setState(() {
                          portId = int.parse(pId.toString());
                        });
                      },
                      validator: (String s) {
                        if (s == "") {
                          return "port id boş geçilemez";
                        } else
                          return null;
                      },
                      decoration: InputDecoration(
                          labelText: "Port Id", hintText: "Port Id"),
                    ),
                    TextFormField(
                      controller: _controllerDbName,
                      onSaved: (dName) {
                        setState(() {
                          dbName = dName;
                        });
                      },
                      validator: (String s) {
                        if (s == "") {
                          return "veritabanı adı boş geçilemez";
                        } else
                          return null;
                      },
                      decoration: InputDecoration(
                          labelText: "Veritabanı Adı",
                          hintText: "Veritabanı Adı"),
                    ),
                    TextFormField(
                      controller: _controllerDbUserName,
                      onSaved: (user) {
                        setState(() {
                          dbUser = user;
                        });
                      },
                      validator: (String s) {
                        if (s == "") {
                          return "Bu alan boş geçilemez";
                        } else
                          return null;
                      },
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          hintText: "Kullanıcı Adı",
                          labelText: "Kullanıcı Adı",
                          labelStyle: TextStyle(color: Colors.blue)),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      controller: _controllerDbUserPass,
                      obscureText: true,
                      onSaved: (pass) {
                        setState(() {
                          dbPassword = pass;
                        });
                      },
                      validator: (String s) {
                        if (s == "") {
                          return "Bu alan boş geçilemez";
                        } else
                          return null;
                      },
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock),
                          hintText: "Şifre",
                          labelText: "Şifre",
                          labelStyle: TextStyle(color: Colors.blue)),
                    ),
                    RaisedButton(
                        child: Text("Kaydet"), onPressed: () => serverSave())
                  ],
                ),
              ),
            ),
          );
        });
  }

  serverSave() {
    if (alertFormKey.currentState.validate()) {
      alertFormKey.currentState.save();
      Navigator.pop(context);
      Fluttertoast.showToast(msg: serverIP);
    }
  }
}
