import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:irem_deneme/models/siparisdetay_model.dart';
import 'package:irem_deneme/models/stokdetay_model.dart';
import 'package:mysql1/mysql1.dart' show MySqlConnection, ConnectionSettings;
import 'package:url_launcher/url_launcher.dart';

import 'login_package/login.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> stokList = [];
  List<String> orderList = [];
  List<String> wareHousesList = [];
  List<StokDetayModel> stokDetayList = [];
  List<StokDetayModel> viewStokDetayList = [];
  List<StokDetayModel> searchStokDetayList = [];
  List<SiparisDetayModel> orderDetailList = [];
  List<SiparisDetayModel> viewOrderDetailList = [];
  List<SiparisDetayModel> searchOrderDetailList = [];
  var listOfColumns;
  var orderDetailSql;
  bool sort;
  bool colorBool;
  int sortColumn;
  bool _value1 = false;
  bool _value2 = false;
  bool _value3 = false;
  bool _value4 = false;
  String appBarText;
  int viewPage;
  String selectedWareHouse;
  int selectedWareHouseIndex;
  String stokadi;
  int kindOfOrder;
  int _currentMax = 0;
  ScrollController _scrollController = ScrollController();
  ScrollController _scrollControllerOrders = ScrollController();
  double heightOfScr;
  double widthOfScr;
  final formKey = GlobalKey<FormState>();
  final sipFormKey = GlobalKey<FormState>();
  StokDetayModel searchedValue;
  bool stokSearch;
  bool siparisSearch;
  DateTime backButtonOnPressedTime;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    mySqlAction();

    sort = false;
    siparisSearch = false;
    stokSearch = false;
    sortColumn = 1;
    colorBool = true;
    appBarText = nameSure;
    viewPage = 0;
    _scrollControllerOrders.addListener(() {
      if (_scrollControllerOrders.position.pixels ==
          _scrollControllerOrders.position.maxScrollExtent) {
        _getMoreData(2);
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreData(1);
      }
    });
    //mySqlGetDetay();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollControllerOrders.dispose();
    _scrollController.dispose();
    //FocusScope.of(context).requestFocus(new FocusNode());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    heightOfScr = MediaQuery.of(context).size.height;
    widthOfScr = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(appBarText),
      ),
      drawer: DrawerMenu(),
      body: WillPopScope(onWillPop: doubleClickExit, child: BodyPage()),
    );
  }

  void _value1Changed(bool value) => setState(() => _value1 = value);

  void _value2Changed(bool value) => setState(() => _value2 = value);

  void _value3Changed(bool value) => setState(() => _value3 = value);

  void _value4Changed(bool value) => setState(() => _value4 = value);

  Future<bool> doubleClickExit() async {
    DateTime currentTime = DateTime.now();

    bool backButton = backButtonOnPressedTime == null ||
        currentTime.difference(backButtonOnPressedTime) > Duration(seconds: 2);

    if (backButton) {
      backButtonOnPressedTime = currentTime;
      Fluttertoast.showToast(msg: "Çıkmak için iki defa basınız");
      return false;
    }
    SystemNavigator.pop(); //uygulamayi kapatir
    //return true;
  }

  _getMoreData(int a) {
    if (a == 1 && !stokSearch) {

      for (int i = _currentMax; i < _currentMax + 10; i++) {
        viewStokDetayList.add(stokDetayList[i]);
        print(stokDetayList[i].toString() + "   " + i.toString());
      }
    } else if (a == 2 && !siparisSearch) {
      for (int i = _currentMax; i < _currentMax + 10; i++) {
        viewOrderDetailList.add(orderDetailList[i]);
        print(viewOrderDetailList[i].toString() + "   " + i.toString());
      }
    }

    _currentMax = _currentMax + 10;
    setState(() {});
  }

  onSortColumns(int columnIndex, bool ascending) {
    if (columnIndex == 1) {
      if (ascending) {
        stokDetayList.sort((a, b) => a.stokAdi.compareTo(b.stokAdi));
      } else {
        stokDetayList.sort((a, b) => b.stokAdi.compareTo(a.stokAdi));
      }
    }
    if (columnIndex == 0) {
      if (ascending) {
        stokDetayList.sort((a, b) => a.stokKodu.compareTo(b.stokKodu));
      } else {
        stokDetayList.sort((a, b) => b.stokKodu.compareTo(a.stokKodu));
      }
    }
  }

  bool changeColor() {
    colorBool = !colorBool;
    return colorBool;
  }

  DataTable getOrderTable() {
    return DataTable(
      columnSpacing: 30,
      columns: [
        DataColumn(label: Text('Müşteri Adı')),
        DataColumn(label: Text('Müşteri Kodu')),
        DataColumn(label: Text('Sipariş Miktarı')),
        DataColumn(label: Text('Tamamlanan')),
        DataColumn(label: Text('Kalan')),
      ],
      //DataTable MaterialStateProperty olduğundan dolayı Materialapp colorlarını kullanamıyor
      rows: (!siparisSearch ? viewOrderDetailList : searchOrderDetailList)
          .map((e) => DataRow(
                  color: changeColor()
                      ? MaterialStateColor.resolveWith((states) => Colors.white)
                      : MaterialStateColor.resolveWith(
                          (states) => Colors.indigo[50]),
                  cells: <DataCell>[
                    DataCell(Text(e.MusteriAdi)),
                    DataCell(Text(
                      e.MusteriKodu,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                    DataCell(Text(e.SiparisMiktari.toString())),
                    DataCell(Text(e.Tamamlanan.toString())),
                    DataCell(Text(e.Kalan.toString())),
                  ]))
          .toList(),
    );
  }

  void customLounch(urlString) async {
    //telefon etme ekranına yönlendirir
    if (await canLaunch(urlString)) {
      await launch(urlString);
    } else {
      Fluttertoast.showToast(msg: "Uygulama bulanamadı");
    }
  }

  Widget BodyPage() {
    if (viewPage == 0)
      return Container(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                margin: EdgeInsets.only(top: 4),
                width: widthOfScr,
                child: Image(image: AssetImage("images/iremlogo2.png"))),
            SizedBox(
              height: 20,
            ),
            Container(
              width: widthOfScr,
              alignment: Alignment.center,
              child: Text(
                "Siz Hayal Edin",
                style: TextStyle(
                    fontSize: widthOfScr * 0.08,
                    fontWeight: FontWeight.w100,
                    fontStyle: FontStyle.italic),
              ),
            ),
            Container(
              width: widthOfScr,
              alignment: Alignment.center,
              child: Text(
                "Biz Tasarlayalım",
                style: TextStyle(
                    fontSize: widthOfScr * 0.1,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ListTile(
              onTap: () {
                setState(() {
                  customLounch('tel:(0342) 231 49 59');
                });
              },
              leading: Icon(Icons.phone),
              title: Text("İletişim için tıklayınız: "),
              subtitle: Text("(0342) 231 49 59"),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text("Adres: "),
              subtitle: Text(
                  "Mücahitler Mah. 52052, Nolu Cd No:9/B, 27000 Şehitkamil"),
            ),
          ],
        ),
      );
    else if (viewPage == 1) {
      {
        return ListView(
          controller: _scrollController,
          children: <Widget>[
            ExpansionTile(
              title: Text("Görünen Sütunlar"),
              children: <Widget>[
                CheckboxListTile(
                    title: Text("Stok Kodu"),
                    value: _value1,
                    onChanged: _value1Changed),
                CheckboxListTile(
                    title: Text("Mevcut Adet"),
                    value: _value2,
                    onChanged: _value2Changed),
                CheckboxListTile(
                    title: Text("Mevcut Miktar"),
                    value: _value3,
                    onChanged: _value3Changed),
                CheckboxListTile(
                    title: Text("Mevcut Brüt"),
                    value: _value4,
                    onChanged: _value4Changed),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Form(
                  key: formKey,
                  child: Container(
                    width: widthOfScr * 0.6,
                    margin: EdgeInsets.only(left: widthOfScr * 0.05),
                    child: TextFormField(
                      onSaved: (searchValue) {
                        if (searchValue.trim().length != 0) {
                          searchStokDetayList.clear();
                          stokDetayList.forEach((element) {
                            print(element.stokAdi);
                            if (element.stokAdi.contains(searchValue)) {
                              print(element.stokAdi);
                              searchedValue = element;
                              setState(() {
                                searchStokDetayList.add(element);
                              });
                            } else {
                              //searchStokDetayList.clear();
                              //Fluttertoast.showToast(msg: "Böyle bir ürün bulunmamaktadır");
                            }
                          });
                          if (searchStokDetayList.length != 0) {
                            stokSearch = true;
                          } else {
                            !stokSearch
                                ? Fluttertoast.showToast(
                                    msg: "Böyle Bir Stok Adı Bulunamadı",
                                    textColor: Colors.red,
                                    backgroundColor: Colors.white)
                                : null;
                          }
                        } else {
                          stokSearch = false;
                        }
                      },
                      decoration: InputDecoration(
                          hintText: "Stok Adı Giriniz..",
                          suffixIcon: Icon(Icons.find_in_page_outlined)),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: widthOfScr * 0.05),
                  width: widthOfScr * 0.3,
                  child: RaisedButton(
                    child: Text("Ara"),
                    onPressed: () {
                      if (formKey.currentState.validate()) {
                        formKey.currentState.save();
                        FocusScope.of(context).requestFocus(new FocusNode());
                      }
                    },
                  ),
                )
              ],
            ),
            Container(
                child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                //datatablenin  sağa sola kaymasını sağladık
                child: DataTable(
                  columnSpacing: 30,
                  sortAscending: sort,
                  sortColumnIndex: sortColumn,
                  columns: [
                    DataColumn(
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            sort = !sort;
                            sortColumn = 0;
                          });
                          onSortColumns(columnIndex, ascending);
                        },
                        label: Visibility(
                          visible: _value1,
                          child: Text('Stok Kodu'),
                        )),
                    DataColumn(
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            sort = !sort;
                            sortColumn = 1;
                          });
                          onSortColumns(columnIndex, ascending);
                        },
                        label: Text('Stok Adı')),
                    DataColumn(
                        label: Visibility(
                      visible: _value2,
                      child: Text('Mevcut Adet'),
                    )),
                    DataColumn(
                        label: Visibility(
                      visible: _value3,
                      child: Text('Mevcut Miktar'),
                    )),
                    DataColumn(
                        label: Visibility(
                      visible: _value4,
                      child: Text('Mevcut Brut'),
                    )),
                  ],
                  //DataTable MaterialStata olduğundan dolayı Materialapp colorlarını kullanamıyor
                  rows: (!stokSearch ? viewStokDetayList : searchStokDetayList)
                      .map((e) => DataRow(
                              color: changeColor()
                                  ? MaterialStateColor.resolveWith(
                                      (states) => Colors.white)
                                  : MaterialStateColor.resolveWith(
                                      (states) => Colors.indigo[50]),
                              cells: <DataCell>[
                                DataCell(Visibility(
                                  visible: _value1,
                                  child: Text(e.stokKodu),
                                )),
                                DataCell(Container(
                                    width: 150,
                                    child: Text(
                                      e.stokAdi,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ))),
                                DataCell(Visibility(
                                  visible: _value2,
                                  child: Text(e.mevcutAdet.toString()),
                                )),
                                DataCell(Visibility(
                                  visible: _value3,
                                  child: Text(e.mevcutMiktar.toString()),
                                )),
                                DataCell(Visibility(
                                  visible: _value4,
                                  child: Text(e.mevcutBrut.toString()),
                                )),
                              ]))
                      .toList(),
                ),
              ),
            ))
          ],
        );
      }
    } else if (viewPage == 2) {
      return ListView(
        controller: _scrollControllerOrders,
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                DropdownButton<String>(
                  hint: Text("Ambar Seçiniz"),
                  value: selectedWareHouse,
                  onChanged: (String Value) {
                    setState(() {
                      EasyLoading.show(status: "Lütfen bekleyiniz");
                      viewOrderDetailList.clear();
                      orderDetailList.clear();
                      _currentMax = 0;
                      selectedWareHouse = Value;
                      mySqlOrderDetail(Value).whenComplete(() {
                        EasyLoading.dismiss();
                      });
                    });
                  },
                  items: wareHousesList.map((String user) {
                    return DropdownMenuItem<String>(
                      value: user,
                      child: Row(
                        children: <Widget>[
                          Text(
                            user,
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Form(
                key: sipFormKey,
                child: Container(
                  width: widthOfScr * 0.6,
                  margin: EdgeInsets.only(left: widthOfScr * 0.05),
                  child: TextFormField(
                    onSaved: (searchValue) {
                      if (searchValue.trim().length != 0) {
                        searchOrderDetailList.clear();
                        orderDetailList.forEach((element) {
                          //print(element.MusteriAdi);
                          if (element.MusteriAdi.contains(searchValue)) {
                            print(element.MusteriAdi);

                            setState(() {
                              searchOrderDetailList.add(element);
                            });
                          }
                        });
                        if (searchOrderDetailList.length != 0) {
                          siparisSearch = true;
                        } else {
                          !siparisSearch
                              ? Fluttertoast.showToast(
                                  msg: "Böyle Bir Stok Adı Bulunamadı",
                                  textColor: Colors.red,
                                  backgroundColor: Colors.white)
                              : null;
                        }
                      } else {
                        siparisSearch = false;
                      }
                    },
                    decoration: InputDecoration(
                        hintText: "Müşteri Adı Giriniz..",
                        suffixIcon: Icon(Icons.find_in_page_outlined)),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: widthOfScr * 0.05),
                width: widthOfScr * 0.3,
                child: RaisedButton(
                  child: Text("Ara"),
                  onPressed: () {
                    if (sipFormKey.currentState.validate() &&
                        selectedWareHouse != null) {
                      sipFormKey.currentState.save();
                      FocusScope.of(context).requestFocus(new FocusNode());
                    } else {
                      Fluttertoast.showToast(msg: "Lütfen Ambar Seçiniz");
                    }
                  },
                ),
              )
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: getOrderTable(),
          )
        ],
      );
    }
  }

  Drawer DrawerMenu() {
    return Drawer(
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(""),
            decoration: BoxDecoration(
                color: Colors.blue,
                image: DecorationImage(
                    alignment: Alignment.centerLeft,
                    image: AssetImage("images/iremlogo2.png"))),
            accountEmail: null,
          ),
          Expanded(
            child: Container(
              child: ListView(
                children: <Widget>[
                  ExpansionTile(
                    children: <Widget>[
                      for (var item in stokList)
                        ListTile(
                          title: Text(item),
                          onTap: () {
                            EasyLoading.show(status: 'Yükleniyor...');

                            setState(() {
                              Navigator.pop(context);
                              stokadi = item;
                              stokDetayList.clear();
                              viewStokDetayList.clear();
                              _currentMax = 0;
                              viewPage = 1;
                            });
                            mySqlGetDetay(item)
                                .whenComplete(() => EasyLoading.dismiss());
                          },
                        )
                    ],
                    trailing: Icon(
                      Icons.arrow_right,
                      size: 36,
                    ),
                    title: Text("Stoklar"),
                  ),
                  ExpansionTile(
                    title: Text("Siparişler"),
                    children: <Widget>[
                      for (var item in orderList)
                        ListTile(
                          title: Text(item),
                          onTap: () {
                            setState(() {
                              if ('Alınan Siparişler' == item) {
                                kindOfOrder = 1;
                                orderDetailList.clear();
                                viewOrderDetailList.clear();
                                _currentMax = 0;
                              } else if (item == "Verilen Siparişler") {
                                kindOfOrder = 2;
                                orderDetailList.clear();
                                viewOrderDetailList.clear();
                                _currentMax = 0;
                              }
                              appBarText = item;
                              viewPage = 2;
                            });
                            Navigator.pop(context);
                          },
                        )
                    ],
                    trailing: Icon(
                      Icons.arrow_right,
                      size: 36,
                    ),
                  ),
                  Divider(
                    height: 64,
                    thickness: 0.5,
                    color: Colors.blue.withOpacity(0.3),
                    indent: 32,
                    endIndent: 32,
                  ),
                  ListTile(
                    leading: Icon(Icons.contact_phone_outlined),
                    title: Text("İletişim"),
                    onTap: () {
                      setState(() {
                        viewPage = 0;
                        Navigator.pop(context);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text("Çıkış Yap"),
                    onTap: () {
                      Navigator.of(context)
                          .popUntil(ModalRoute.withName('/loginpage'));
                    },
                  ),
                  Divider(
                    height: 30,
                    thickness: 0.7,
                    color: Colors.blue.withOpacity(0.5),
                    indent: 10,
                    endIndent: 10,
                  ),
                  ListTile(
                    title: Text(
                      "Server Ip: " + serverIP,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    subtitle: Text(
                      "Veri Tabanı Adı: " + dbName,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future mySqlAction() async {
    print(userName.toString() +
        password.toString() +
        serverIP.toString() +
        portId.toString() +
        dbName.toString());
    try {
      final conn = await MySqlConnection.connect(ConnectionSettings(
          host: serverIP,
          port: portId,
          user: dbUser,
          password: dbPassword,
          db: dbName));
      var _result = await conn.query("select * from stoktip");
      var _orderResult = await conn.query("select * from siparistip");
      var _wareHouses = await conn.query("select * from ambardesc");
      if (_wareHouses.isNotEmpty) {
        for (var row in _wareHouses) {
          setState(() {
            wareHousesList.add(row['description']);
          });
        }
      }
      if (_orderResult.isNotEmpty) {
        for (var row in _orderResult) {
          setState(() {
            orderList.add(row['SiparisAdi']);
          });
        }
      }
      if (_result.isNotEmpty) {
        print("result giriş yapıldıHome Page ");
        for (var row in _result) {
          setState(() {
            stokList.add(row['StokAdi']);
          });
        }
      } else {
        Fluttertoast.showToast(msg: "Böyle bir kullanıcı yok");
      }
    } catch (E) {}
  }

  Future mySqlOrderDetail(String ambardescription) async {
    final conn = await MySqlConnection.connect(ConnectionSettings(
        host: serverIP,
        port: portId,
        user: dbUser,
        password: dbPassword,
        db: dbName));
    var wareHouseIndexSql = await conn.query(
        "select ref from ambardesc where description='$ambardescription'");
    if (wareHouseIndexSql.isNotEmpty) {
      setState(() {
        for (var index in wareHouseIndexSql)
          selectedWareHouseIndex = index['ref'];
      });
    }
    orderDetailSql = await conn.query(
        "select  ol.ref,ol.fisref,o.date,o.fisno,c.name as MusteriAdi,c.custno as MusteriKodu, "
        "ol.cmiktar as SiparisMiktari, "
        "ol.complete as Tamamlanan, ol.cmiktar-ol.complete as Kalan,b.BirimAdi,yn.ne,tw.twistvalues,yt.tipdesc, "
        "r.description as renkadi "
        "from ororderlns ol "
        "inner join ororders o on o.ref=ol.fisref "
        "left join customer c on c.ref=o.cariref "
        "left join yarnne yn on yn.ref=ol.neref "
        "left join twistval tw on tw.ref=ol.katref "
        "left join yarntip yt on yt.ref=ol.tipref "
        "left join renks r on r.ref=ol.renkref "
        "left join BirimList b on b.ref=ol.BirimRef "
        "where ol.cmiktar>ol.complete and o.tip=$kindOfOrder and o.bolum=$selectedWareHouseIndex "
        "Order By c.Name,o.Date ");
    if (orderDetailSql.isNotEmpty) {
      setState(() {
        for (var row in orderDetailSql) {
          orderDetailList.add(SiparisDetayModel(
              row['MusteriAdi'],
              row['MusteriKodu'],
              row['SiparisMiktari'],
              row['Tamamlanan'],
              row['Kalan']));
        }
        _getMoreData(2);
      });
    } else {
      Fluttertoast.showToast(
          msg: "Ambarda Ürün Bulunamadı!!",
          textColor: Colors.red,
          backgroundColor: Colors.white);
    }
  }

  Future mySqlGetDetay(String stokAdi) async {
    stokDetayList.clear();
    final conn = await MySqlConnection.connect(ConnectionSettings(
        host: serverIP,
        port: portId,
        user: dbUser,
        password: dbPassword,
        db: dbName));

    listOfColumns = await conn.query(
        "select s.code as StokKodu,s.description as StokAdi,st.currentadet as MevcutAdet,st.current as MevcutMiktar,st.currentbrut as MevcutBrut from stocks s inner join stocktot st on st.stokref=s.ref and st.ambarref=0 where s.tip=(select StokTipi from stoktip where StokAdi='$stokAdi')");
    if (listOfColumns.isNotEmpty) {
      print("Detay giriş yapıldı");
      for (var row in listOfColumns) {
        setState(() {
          stokDetayList.add(StokDetayModel(
              row['StokKodu'],
              row['StokAdi'],
              row['MevcutAdet'].toString(),
              row['MevcutMiktar'].toString(),
              row['MevcutBrut'].toString()));
        });
      }
      _getMoreData(1);
    } else {
      Fluttertoast.showToast(msg: "Böyle bir kullanıcı yok");
    }
  }
}
