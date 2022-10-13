import 'dart:async';
import 'dart:math';
import 'package:eshopmultivendor/Helper/ApiBaseHelper.dart';
import 'package:eshopmultivendor/Helper/AppBtn.dart';
import 'package:eshopmultivendor/Helper/Color.dart';
import 'package:eshopmultivendor/Helper/Constant.dart';
import 'package:eshopmultivendor/Helper/PushNotificationService.dart';
import 'package:eshopmultivendor/Helper/Session.dart';
import 'package:eshopmultivendor/Helper/String.dart';
import 'package:eshopmultivendor/Localization/Language_Constant.dart';
import 'package:eshopmultivendor/Model/CategoryModel/CategoryModel.dart';
import 'package:eshopmultivendor/Model/OrdersModel/OrderModel.dart';
import 'package:eshopmultivendor/Model/ZipCodesModel/ZipCodeModel.dart';
import 'package:eshopmultivendor/Screen/Add_Product.dart';
import 'package:eshopmultivendor/Screen/Authentication/Login.dart';
import 'package:eshopmultivendor/Screen/OrderDetail.dart';
import 'package:eshopmultivendor/Screen/TermFeed/Contact_Us.dart';
import 'package:eshopmultivendor/Screen/Customers.dart';
import 'package:eshopmultivendor/Screen/OrderList.dart';
import 'package:eshopmultivendor/Screen/TermFeed/Privacy_Policy.dart';
import 'package:eshopmultivendor/Screen/ProductList.dart';
import 'package:eshopmultivendor/Screen/WalletHistory.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helper/Indicator.dart';
import '../main.dart';
import 'Profile.dart';
import 'TermFeed/Terms_Conditions.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

int? total, offset;
List<Order_Model> orderList = [];
bool _isLoading = true;
bool isLoadingmore = true;
// List<PersonModel> delBoyList = [];
List<ZipCodeModel> zipCodeList = [];
List<CategoryModel> catagoryList = [];
String? delPermission;
ApiBaseHelper apiBaseHelper = ApiBaseHelper();

class _HomeState extends State<Home> with TickerProviderStateMixin {
//==============================================================================
//============================= Variables Declaration ==========================
  int curDrwSel = 0;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<String?> languageList = [];
  List<Order_Model> tempList = [];
  String? all,
      received,
      processed,
      shipped,
      delivered,
      cancelled,
      returned,
      awaiting;
  String _searchText = "";
  String? totalorderCount,
      totalproductCount,
      totalcustCount,
      totaldelBoyCount,
      totalsoldOutCount,
      totallowStockCount;
  bool scrollLoadmore = true, scrollGettingData = false, scrollNodata = false;
  int scrollOffset = 0;
  String? start, end;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  ScrollController? controller; // = new ScrollController();
  int? selectLan;
  bool _isNetworkAvail = true;
  String? activeStatus;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  List<String> statusList = [
    ALL,
    PLACED,
    PROCESSED,
    SHIPED,
    DELIVERD,
    CANCLED,
    RETURNED,
    awaitingPayment
  ];

//==============================================================================
//===================================== For Chart ==============================

  int curChart = 0;
  Map<int, LineChartData>? chartList;
  List? days = [], dayEarning = [];
  List? months = [], monthEarning = [];
  List? weeks = [], weekEarning = [];
  List? catCountList = [], catList = [];
  List colorList = [];
  int? touchedIndex;

//==============================================================================
//============================= For Language Selection =========================

  List<String> langCode = [
    ENGLISH,
    HINDI,
    CHINESE,
    SPANISH,
    ARABIC,
    RUSSIAN,
    JAPANESE,
    DEUTSCH
  ];

  var sellerOnOff = false;


//==============================================================================
//============================= initState Method ===============================

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));
    final pushNotificationService = PushNotificationService(context: context,onResult: (result){
      print("terabhai"+result);
      if(result=="yes"){
        scrollLoadmore = true;
        scrollOffset = 0;
        orderList.clear();
        getOrder();
      }

    });
    pushNotificationService.initialise();
    offset = 0;
    total = 0;
    chartList = {0: dayData(), 1: weekData(), 2: monthData()};
    scrollController = ScrollController(keepScrollOffset: true);
    scrollController!.addListener(_transactionscrollListener);
    orderList.clear();
    getSaveDetail();
    getStatics();
    getSallerDetail();
    //  getDeliveryBoy();
    getZipCodes();
    getCategories();
     getOrder();

    buttonController = new AnimationController(
      duration: new Duration(milliseconds: 2000),
      vsync: this,
    );

    buttonSqueezeanimation = new Tween(
      begin: width * 0.7,
      end: 50.0,
    ).animate(
      new CurvedAnimation(
        parent: buttonController!,
        curve: new Interval(
          0.0,
          0.150,
        ),
      ),
    );
    controller = ScrollController(keepScrollOffset: true);
    // controller!.addListener(_scrollListener);
    new Future.delayed(
      Duration.zero,
      () {
        languageList = [
          getTranslated(context, 'English'),
          getTranslated(context, 'Hindi'),
          // getTranslated(context, 'Chinese'),
          // getTranslated(context, 'Spanish'),
          // getTranslated(context, 'Arabic'),
          // getTranslated(context, 'Russian'),
          // getTranslated(context, 'Japanese'),
          // getTranslated(context, 'Deutch'),
        ];
      },
    );
    super.initState();

  }
  _transactionscrollListener() {
    if (scrollController!.offset >=
        scrollController!.position.maxScrollExtent &&
        !scrollController!.position.outOfRange) {
      if (mounted)
        setState(
              () {
            scrollLoadmore = true;
            getOrder();
          },
        );
    }
  }
//==============================================================================
//============================= For Animation ==================================

  getSaveDetail() async {
    print("we are here");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String getlng = await getPrefrence(LAGUAGE_CODE) ?? '';

    selectLan = langCode.indexOf(getlng == '' ? "en" : getlng);
  }

//==============================================================================
//============================= For Animation ==================================

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

//==============================================================================
//============================= Build Method ===================================

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setSystemUIOverlayStyle(
    //   SystemUiOverlayStyle(
    //     statusBarColor: white, // status bar color
    //     systemNavigationBarColor: black,
    //   ),
    // );
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return
      // ScaffoldMessenger(
      // key: scaffoldMessengerKey,
     // child:
    Scaffold(
        key: _scaffoldKey,
        backgroundColor: lightWhite,
        appBar: getAppBar(context),
        drawer: getDrawer(context),
        body: getBodyPart(),
        floatingActionButton: floatingBtn(),
      );
   // );
  }

//==============================================================================
//=============================== floating Button ==============================
  bool statusOn = false;
  floatingBtn() {
    return FloatingActionButton(
      backgroundColor: white,
      child: Icon(
        Icons.add,
        size: 32,
        color: fontColor,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddProduct(),
          ),
        );
      },
    );
  }

//==============================================================================
//=============================== chart coding  ================================

  getChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        height: 250,
        child: Card(
          elevation: 0,
          margin: EdgeInsets.only(top: 10, left: 5, right: 15),
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8),
                  child: Text(
                    getTranslated(context, "ProductSales")!,
                    style: Theme.of(context)
                        .textTheme
                        .headline6!
                        .copyWith(color: primary),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: curChart == 0
                        ? TextButton.styleFrom(
                            primary: Colors.white,
                            backgroundColor: primary,
                            onSurface: Colors.grey,
                          )
                        : null,
                    onPressed: () {
                      setState(
                        () {
                          curChart = 0;
                        },
                      );
                    },
                    child: Text(
                      getTranslated(context, "Day")!,
                    ),
                  ),
                  TextButton(
                    style: curChart == 1
                        ? TextButton.styleFrom(
                            primary: Colors.white,
                            backgroundColor: primary,
                            onSurface: Colors.grey,
                          )
                        : null,
                    onPressed: () {
                      setState(
                        () {
                          curChart = 1;
                        },
                      );
                    },
                    child: Text(
                      getTranslated(context, "Week")!,
                    ),
                  ),
                  TextButton(
                    style: curChart == 2
                        ? TextButton.styleFrom(
                            primary: Colors.white,
                            backgroundColor: primary,
                            onSurface: Colors.grey,
                          )
                        : null,
                    onPressed: () {
                      setState(
                        () {
                          curChart = 2;
                        },
                      );
                    },
                    child: Text(
                      getTranslated(context, "Month")!,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: LineChart(
                  chartList![curChart]!,
                  swapAnimationDuration: const Duration(milliseconds: 250),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

//1. LineChartData

  LineChartData dayData() {
    if (dayEarning!.length == 0) {
      dayEarning!.add(0);
      days!.add(0);
    }
    List<FlSpot> spots = dayEarning!.asMap().entries.map((e) {
      return FlSpot(double.parse(days![e.key].toString()),
          double.parse(e.value.toString()));
    }).toList();

    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          colors: [
            grad2Color,
          ],
          belowBarData: BarAreaData(
            show: true,
            colors: [primary.withOpacity(0.5)],
          ),
          aboveBarData: BarAreaData(
            show: true,
            colors: [fontColor.withOpacity(0.2)],
          ),
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      minY: 0,
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
            showTitles: true,
            reservedSize: 3,
            getTextStyles: (context, value) => const TextStyle(
                  color: black,
                  fontSize: 9,
                ),
            margin: 10,
            getTitles: (value) {
              return value.toInt().toString();
            }),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (context, value) => const TextStyle(
            color: black,
            fontSize: 9,
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: fontColor.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  //2. catChart

  LineChartData weekData() {
    if (weekEarning!.length == 0) {
      weekEarning!.add(0);
      weeks!.add(0);
    }
    List<FlSpot> spots = weekEarning!.asMap().entries.map((e) {
      return FlSpot(
          double.parse(e.key.toString()), double.parse(e.value.toString()));
    }).toList();

    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          colors: [
            grad2Color,
          ],
          belowBarData: BarAreaData(
            show: true,
            colors: [
              primary.withOpacity(0.5),
            ],
          ),
          aboveBarData: BarAreaData(
            show: true,
            colors: [fontColor.withOpacity(0.2)],
          ),
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      minY: 0,
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
            showTitles: true,
            reservedSize: 4,
            getTextStyles: (context, value) => const TextStyle(
                  color: black,
                  fontSize: 9,
                ),
            margin: 10,
            getTitles: (value) {
              return weeks![value.toInt()].toString();
            }),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (context, value) => const TextStyle(
            color: black,
            fontSize: 9,
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: fontColor.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  //2. monthData

  LineChartData monthData() {
    if (monthEarning!.length == 0) {
      monthEarning!.add(0);
      months!.add(0);
    }

    List<FlSpot> spots = monthEarning!.asMap().entries.map((e) {
      return FlSpot(
          double.parse(e.key.toString()), double.parse(e.value.toString()));
    }).toList();

    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          colors: [
            grad2Color,
          ],
          belowBarData: BarAreaData(
            show: true,
            colors: [primary.withOpacity(0.5)],
          ),
          aboveBarData: BarAreaData(
            show: true,
            colors: [fontColor.withOpacity(0.2)],
          ),
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      minY: 0,
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (context, value) => const TextStyle(
            color: black,
            fontSize: 9,
          ),
        ),
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 3,
          getTextStyles: (context, value) => const TextStyle(
            color: black,
            fontSize: 9,
          ),
          margin: 10,
          getTitles: (value) {
            return months![value.toInt()];
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: fontColor.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  Color generateRandomColor() {
    Random random = Random();
    // Pick a random number in the range [0.0, 1.0)
    double randomDouble = random.nextDouble();

    return Color((randomDouble * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

//==============================================================================
//========================= getZipcodesApi API =================================

  Future<void> getCategories() async {
    CUR_USERID = await getPrefrence(Id);
    var parameter = {
      SellerId: CUR_USERID,
    };
    apiBaseHelper.postAPICall(getCategoriesApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          catagoryList.clear();
          var data = getdata["data"];
          print(data);
          catagoryList = (data as List)
              .map((data) => new CategoryModel.fromJson(data))
              .toList();
        } else {
          setSnackbar(msg!);
        }
      },
      onError: (error) {
        setSnackbar(error.toString());
      },
    );
  }

  Future<void> getZipCodes() async {
    var parameter = {};
    apiBaseHelper.postAPICall(getZipcodesApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          zipCodeList.clear();
          var data = getdata["data"];
          zipCodeList = (data as List)
              .map((data) => new ZipCodeModel.fromJson(data))
              .toList();
        } else {
          setSnackbar(msg!);
        }
      },
      onError: (error) {
        setSnackbar(error.toString());
      },
    );
  }
//==============================================================================
//========================= getDeliveryBoy API =================================

  // Future<void> getDeliveryBoy() async {
  //   CUR_USERID = await getPrefrence(Id);
  //   var parameter = {
  //     SellerId: CUR_USERID,
  //   };
  //   apiBaseHelper.postAPICall(getDeliveryBoysApi, parameter).then(
  //     (getdata) async {
  //       bool error = getdata["error"];
  //       String? msg = getdata["message"];

  //       if (!error) {
  //         delBoyList.clear();
  //         var data = getdata["data"];
  //         delBoyList = (data as List)
  //             .map((data) => new PersonModel.fromJson(data))
  //             .toList();
  //       } else {
  //         setSnackbar(msg!);
  //       }
  //     },
  //     onError: (error) {
  //       setSnackbar(error.toString());
  //     },
  //   );
  // }

//==============================================================================
//========================= getStatics API =====================================

  Future<Null> getStatics() async {
    CUR_USERID = await getPrefrence(Id);
    CUR_USERNAME = await getPrefrence(Username);
    var parameter = {SellerId: CUR_USERID};

    apiBaseHelper.postAPICall(getStatisticsApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          CUR_CURRENCY = getdata["currency_symbol"];
          var count = getdata['counts'][0];
          totalorderCount = count["order_counter"];
          totalproductCount = count["product_counter"];
          totalsoldOutCount = count['count_products_sold_out_status'];
          totallowStockCount = count["count_products_low_status"];
          totalcustCount = count["user_counter"];
          delPermission = count["permissions"]['assign_delivery_boy'];
          weekEarning = getdata['earnings'][0]["weekly_earnings"]['total_sale'];
          days = getdata['earnings'][0]["daily_earnings"]['day'];
          dayEarning = getdata['earnings'][0]["daily_earnings"]['total_sale'];
          months = getdata['earnings'][0]["monthly_earnings"]['month_name'];
          monthEarning =
              getdata['earnings'][0]["monthly_earnings"]['total_sale'];

          weeks = getdata['earnings'][0]["weekly_earnings"]['week'];
          //  if (chartList != null) chartList!.clear();
          chartList = {0: dayData(), 1: weekData(), 2: monthData()};

          catCountList = getdata['category_wise_product_count']['counter'];
          catList = getdata['category_wise_product_count']['cat_name'];
          colorList.clear();
          for (int i = 0; i < catList!.length; i++)
            colorList.add(generateRandomColor());
        } else {
          setSnackbar(msg!);
        }

        setState(() {
          _isLoading = false;
        });
      },
      onError: (error) {
        setSnackbar(error.toString());
      },
    );
    return null;
  }

  Future<Null> getSallerDetail() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      CUR_USERID = await getPrefrence(Id);

      var parameter = {Id: CUR_USERID};
      apiBaseHelper.postAPICall(getSellerDetails, parameter).then(
        (getdata) async {
          bool error = getdata["error"];
          String? msg = getdata["message"];
            print(getdata);
          if (!error) {
            var data = getdata["data"][0];
            print(data["open_close_status"]+"??????????????????????????????////");
            CUR_BALANCE = double.parse(data[BALANCE]).toStringAsFixed(2);
            LOGO = data["logo"].toString();
            RATTING = data[Rating] ?? "";
            NO_OFF_RATTING = data[NoOfRatings] ?? "";
            NO_OFF_RATTING = data[NoOfRatings] ?? "";
            var id = data[Id];
            var username = data[Username];
            var email = data[Email];
            var mobile = data[Mobile];
            var address = data[Address];
            CUR_USERID = id!;
            CUR_USERNAME = username!;
            var srorename = data[Storename];
            var storeurl = data[Storeurl]??"";
            var storeDesc = data[storeDescription];
            var accNo = data[accountNumber];
            var accname = data[accountName];
            var bankCode = data[BankCOde];
            var bankName = data[bankNAme]??'';
            var latitutute = data[Latitude];
            var longitude = data[Longitude];
            var taxname = data[taxName];
            var tax_number = data[taxNumber];
            var pan_number = data[panNumber];
            var status = data[STATUS];
            var storeLogo = data[StoreLogo];
          var   openClose = data["open_close_status"];
            sellerOnOff = openClose=="1"?true:false;

            print("bank name : $bankName");
            saveUserDetail(
              id!,
              username!,
              email!,
              mobile!,
              address!,
              srorename!,
              storeurl!,
              storeDesc!,
              accNo!,
              accname!,
              bankCode ?? "",
              bankName ?? "",
              latitutute ?? "",
              longitude ?? "",
              taxname ?? "",
              tax_number!,
              pan_number!,
              status!,
              storeLogo!,
            );
          }
          setState(() {
            _isLoading = false;
          });
        },
        onError: (error) {
          setSnackbar(error.toString());
        },
      );
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
          _isLoading = false;
        });
    }

    return null;
  }

  getAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        appName,
        style: TextStyle(
          color: grad2Color,
        ),
      ),
      actions: [
        CupertinoSwitch(value: sellerOnOff, onChanged: (val){
          setState(() {
            sellerOnOff = val;
            if(sellerOnOff){
              setOpenClose("1");
            }else{
              setOpenClose("0");
            }
          });
        }),
      ],
      backgroundColor: white,
      iconTheme: IconThemeData(color: grad2Color),
    );
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      duration: Duration(seconds: 1),
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: black),
      ),
      backgroundColor: white,
      elevation: 1.0,
    ));
  }

  getDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          color: white,
          child: ListView(
            padding: EdgeInsets.all(0),
            shrinkWrap: true,
            physics: BouncingScrollPhysics(),
            children: <Widget>[
              _getHeader(),
              Divider(),
              _getDrawerItem(
                  0, getTranslated(context, "HOME")!, Icons.home_outlined),
              // _getDrawerItem(0, getTranslated(context, "PRODUCTS")!,
              //     Icons.shopping_basket_outlined),
              // Divider(),
              // _getDrawerItem(
              //     2, getTranslated(context, "CUSTOMERS")!, Icons.person),
              _getDrawerItem(3, getTranslated(context, "WALLETHISTORY")!,
                  Icons.account_balance_wallet_outlined),
              Divider(),
              _getDrawerItem(4, getTranslated(context, "PRODUCTS")!,
                  Icons.production_quantity_limits_outlined),
              // _getDrawerItem(10, "Add Product", Icons.add),
              // Divider(),
              // _getDrawerItem(5, getTranslated(context, "ChangeLanguage")!,
              //     Icons.translate),
              _getDrawerItem(6, getTranslated(context, "T_AND_C")!,
                  Icons.speaker_notes_outlined),
              Divider(),
              _getDrawerItem(7, getTranslated(context, "PRIVACYPOLICY")!,
                  Icons.lock_outline),
              _getDrawerItem(
                  9, getTranslated(context, "CONTACTUS")!, Icons.contact_page),
              Divider(),
              _getDrawerItem(
                  8, getTranslated(context, "LOGOUT")!, Icons.home_outlined),
            ],
          ),
        ),
      ),
    );
  }

  _getHeader() {
    return InkWell(
      child: Container(
        decoration: back(),
        padding: EdgeInsets.only(left: 10.0, bottom: 10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 10),
              child: Container(
                width: MediaQuery.of(context).size.width*0.4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CUR_USERNAME!,
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1!
                          .copyWith(color: white, fontWeight: FontWeight.bold),
                    ),
                    // Text(
                    //   getTranslated(context, "WALLET_BAL")! +
                    //       ": " +
                    //       CUR_CURRENCY +
                    //       "" +
                    //       CUR_BALANCE,
                    //   style: Theme.of(context)
                    //       .textTheme
                    //       .caption!
                    //       .copyWith(color: white),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTranslated(context, "EDIT_PROFILE_LBL")!,
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .copyWith(color: white),
                          ),
                          Icon(
                            Icons.arrow_right_outlined,
                            color: white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            Container(
              margin: EdgeInsets.only(top: 20, right: 20),
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1.0,
                  color: white,
                ),
              ),
              child: LOGO != ''
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(100.0),
                      child: sallerLogo(62),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(100.0),
                      child: imagePlaceHolder(62),
                    ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Profile(),
          ),
        ).then((value) {
          print("back frome profile screen");
          getStatics();
          getSallerDetail();
          //  getDeliveryBoy();
          getZipCodes();
          getCategories();
          setState(() {});
          Navigator.pop(context);
        });
        setState(() {});
      },
    );
  }

  sallerLogo(double size) {
    return CircleAvatar(
      backgroundImage: NetworkImage(LOGO),
      radius: 25,
    );
  }

  imagePlaceHolder(double size) {
    return new Container(
      height: size,
      width: size,
      child: Icon(
        Icons.account_circle,
        color: Colors.white,
        size: size,
      ),
    );
  }

  _getDrawerItem(int index, String title, IconData icn) {
    return Container(
      margin: EdgeInsets.only(
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: curDrwSel == index
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [secondary.withOpacity(0.2), primary.withOpacity(0.2)],
                stops: [0, 1],
              )
            : null,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icn,
          color: curDrwSel == index ? primary : lightBlack2,
        ),
        title: Text(
          title,
          style: TextStyle(
              color: curDrwSel == index ? primary : lightBlack2, fontSize: 15),
        ),
        onTap: () {
          if (title == getTranslated(context, "HOME")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
          } else if (title == getTranslated(context, "ORDERS")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderList(),
              ),
            );
          } else if (title == getTranslated(context, "CUSTOMERS")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Customers(),
              ),
            );
          } else if (title == getTranslated(context, "WALLETHISTORY")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WalletHistory(),
              ),
            );
          } else if (title == getTranslated(context, "PRODUCTS")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductList(
                  flag: '',
                ),
              ),
            );
          } else if (title == getTranslated(context, "ChangeLanguage")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            languageDialog();
          } else if (title == getTranslated(context, "T_AND_C")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Terms_And_Condition(),
              ),
            );
          } else if (title == getTranslated(context, "CONTACTUS")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContactUs(),
              ),
            ).then((value) {
              setState(() {});
            });
          } else if (title == getTranslated(context, "PRIVACYPOLICY")!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrivacyPolicy(),
              ),
            );
          } else if (title == getTranslated(context, "LOGOUT")!) {
            Navigator.pop(context);
            logOutDailog();
          } else if (title == "Add Product") {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProduct(),
              ),
            );
          }
        },
      ),
    );
  }

  languageDialog() async {
    await dialogAnimate(
      context,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setStater) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(0.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                  child: Text(
                    getTranslated(context, 'CHOOSE_LANGUAGE_LBL')!,
                    style: Theme.of(this.context).textTheme.subtitle1!.copyWith(
                          color: fontColor,
                        ),
                  ),
                ),
                Divider(color: lightBlack),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: getLngList(context)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> getLngList(BuildContext ctx) {
    return languageList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted)
                  setState(
                    () {
                      selectLan = index;
                      _changeLan(langCode[index], ctx);
                    },
                  );
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 25.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectLan == index ? grad2Color : white,
                            border: Border.all(color: grad2Color),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: selectLan == index
                                ? Icon(
                                    Icons.check,
                                    size: 17.0,
                                    color: white,
                                  )
                                : Icon(
                                    Icons.check_box_outline_blank,
                                    size: 15.0,
                                    color: white,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: 15.0,
                          ),
                          child: Text(
                            languageList[index]!,
                            style: Theme.of(this.context)
                                .textTheme
                                .subtitle1!
                                .copyWith(color: lightBlack),
                          ),
                        )
                      ],
                    ),
                    index == languageList.length - 1
                        ? Container(
                            margin: EdgeInsetsDirectional.only(
                              bottom: 10,
                            ),
                          )
                        : Divider(
                            color: lightBlack,
                          ),
                  ],
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  void _changeLan(String language, BuildContext ctx) async {
    Locale _locale = await setLocale(language);

    MyApp.setLocale(ctx, _locale);
  }

  logOutDailog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Text(
                getTranslated(context, "LOGOUTTXT")!,
                style: Theme.of(this.context)
                    .textTheme
                    .subtitle1!
                    .copyWith(color: fontColor),
              ),
              actions: <Widget>[
                new TextButton(
                    child: Text(
                      getTranslated(context, "LOGOUTNO")!,
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2!
                          .copyWith(
                              color: lightBlack, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    }),
                new TextButton(
                  child: Text(
                    getTranslated(context, "LOGOUTYES")!,
                    style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                        color: fontColor, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    clearUserSession();
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => Login()),
                        (Route<dynamic> route) => false);
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  getBodyPart() {
    return _isNetworkAvail
        ? _isLoading
            ? shimmer()
            : RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refresh,
        child: _showContent(),
    )
            // : RefreshIndicator(
            //     key: _refreshIndicatorKey,
            //     onRefresh: _refresh,
            //     child: SingleChildScrollView(
            //       child: Padding(
            //         padding: const EdgeInsets.only(
            //           top: 10,
            //           left: 8,
            //           right: 8,
            //         ),
            //         child: Column(
            //           children: [
            //             firstHeader(),
            //             secondHeader(),
            //             thirdHeader(),
            //             SizedBox(
            //               height: 5,
            //             ),
            //             // getChart(),
            //             // catChart(),
            //             SizedBox(height: 15),
            //           ],
            //         ),
            //       ),
            //     ),
            //   )
        : noInternet(context);
  }
  ScrollController? scrollController;
  _showContent() {
    return NotificationListener<ScrollNotification>(
      // onNotification:
      //     (scrollNotification) {} as bool Function(ScrollNotification)?,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: <Widget>[
                  _detailHeader(),
                  _detailHeader2(),
                  _filterRow(),
                  scrollNodata
                      ?getNoItem(context)
                      : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsetsDirectional.only(
                          bottom: 5, start: 10, end: 10),
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: orderList.length,
                      itemBuilder: (context, index) {
                        Order_Model? item;
                        try {
                          item =
                          orderList.isEmpty ? null : orderList[index];
                          if (scrollLoadmore &&
                              index == (orderList.length - 1) &&
                              scrollController!.position.pixels <= 0) {
                            getOrder();
                          }
                        } on Exception catch (_) {}

                        return item == null
                            ? Container()
                            : orderItem(index);
                      }),
                ],
              ),
            ),
          ),
          scrollGettingData
              ? Padding(
            padding: EdgeInsetsDirectional.only(top: 5, bottom: 5),
            child: CircularProgressIndicator(),
          )
              : Container(),
        ],
      ),
    );
  }
  _filterRow() {
    return Row(
      children: [
        Container(
            margin: EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width * .375,
            height: 45,
            child: ElevatedButton(
              onPressed: () => _startDate(context),
              child: Text(
                start == null ? 'Start Date' : start!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                side: BorderSide(color: primary),
                primary: primary,
                onPrimary: Colors.white,
                onSurface: fontColor,
              ),
            )),
        Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            width: MediaQuery.of(context).size.width * .375,
            height: 45,
            child: ElevatedButton(
              onPressed: () => _endDate(context),
              child: Text(end == null ? 'End Date' : end!),
              style: ElevatedButton.styleFrom(
                primary: primary,
                onPrimary: Colors.white,
                onSurface: Colors.grey,
              ),
            )),
        Expanded(
          child: Container(
            margin: EdgeInsets.all(10),
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  start = null;
                  end = null;
                  startDate = DateTime.now();
                  endDate = DateTime.now();
                  scrollLoadmore = true;
                  scrollOffset = 0;
                });
                getOrder();
              },
              child: Center(
                child: Icon(Icons.close),
              ),
              style: ElevatedButton.styleFrom(
                primary: primary,
                onPrimary: Colors.white,
                onSurface: Colors.grey,
                padding: EdgeInsets.all(0),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Future<void> _startDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: startDate,
        firstDate: DateTime(2020, 1),
        lastDate: DateTime.now());
    if (picked != null)
      setState(
            () {
          startDate = picked;
          start = DateFormat('dd-MM-yyyy').format(startDate);

          if (start != null && end != null) {
            scrollLoadmore = true;
            scrollOffset = 0;
            getOrder();
          }
        },
      );
  }

  Future<void> _endDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: startDate,
        firstDate: startDate,
        lastDate: DateTime.now());
    if (picked != null)
      setState(
            () {
          endDate = picked;
          end = DateFormat('dd-MM-yyyy').format(endDate);
          if (start != null && end != null) {
            scrollLoadmore = true;
            scrollOffset = 0;
            getOrder();
          }
        },
      );
  }
  _detailHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Card(
              elevation: 0,
              child: InkWell(
                onTap: () {
                  setState(() {
                    activeStatus = null;
                    scrollLoadmore = true;
                    scrollOffset = 0;
                  });

                  getOrder();
                },
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: primary,
                      ),
                      Text(
                        getTranslated(context, "ORDER")!,
                        style: Theme.of(context).textTheme.caption!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        all ?? "",
                        style: TextStyle(
                          color: black,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Card(
              elevation: 0,
              child: InkWell(
                onTap: () {
                  setState(
                        () {
                      activeStatus = statusList[1];
                      scrollLoadmore = true;
                      scrollOffset = 0;
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.archive,
                        color: primary,
                      ),
                      Text(
                        getTranslated(context, "RECEIVED_LBL")!,
                        style: Theme.of(context).textTheme.caption!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        received ?? '',
                        style: TextStyle(
                            color: black, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Expanded(
          //   flex: 1,
          //   child: Card(
          //     elevation: 0,
          //     child: InkWell(
          //       onTap: () {
          //         setState(() {
          //           activeStatus = statusList[2];
          //           scrollLoadmore = true;
          //           scrollOffset = 0;
          //         });
          //       },
          //       child: Padding(
          //         padding: const EdgeInsets.all(18.0),
          //         child: Column(
          //           children: [
          //             Icon(
          //               Icons.work,
          //               color: primary,
          //             ),
          //             Text(
          //               getTranslated(context, "PROCESSED_LBL")!,
          //               style: Theme.of(context).textTheme.caption!.copyWith(
          //                     fontWeight: FontWeight.bold,
          //                     color: grey,
          //                   ),
          //               maxLines: 1,
          //               overflow: TextOverflow.ellipsis,
          //             ),
          //             Text(
          //               processed ?? "",
          //               style: TextStyle(
          //                   color: black, fontWeight: FontWeight.bold),
          //             )
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          // Expanded(
          //   flex: 1,
          //   child: Card(
          //     elevation: 0,
          //     child: InkWell(
          //       onTap: () {
          //         setState(() {
          //           activeStatus = statusList[3];
          //           scrollLoadmore = true;
          //           scrollOffset = 0;
          //         });
          //       },
          //       child: Padding(
          //         padding: const EdgeInsets.all(18.0),
          //         child: Column(
          //           children: [
          //             Icon(
          //               Icons.airport_shuttle,
          //               color: primary,
          //             ),
          //             Text(
          //               getTranslated(context, "SHIPED_LBL")!,
          //               style: Theme.of(context).textTheme.caption!.copyWith(
          //                     fontWeight: FontWeight.bold,
          //                     color: grey,
          //                   ),
          //               maxLines: 1,
          //               overflow: TextOverflow.ellipsis,
          //             ),
          //             Text(
          //               shipped ?? "",
          //               style: TextStyle(
          //                   color: black, fontWeight: FontWeight.bold),
          //             )
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  _detailHeader2() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Card(
            elevation: 0,
            child: InkWell(
              onTap: () {
                setState(() {
                  activeStatus = statusList[4];
                  scrollLoadmore = true;
                  scrollOffset = 0;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_turned_in,
                      color: primary,
                    ),
                    Text(
                      getTranslated(context, "DELIVERED_LBL")!,
                      style: Theme.of(context).textTheme.caption!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      delivered ?? "",
                      style:
                      TextStyle(color: black, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Card(
            elevation: 0,
            child: InkWell(
              onTap: () {
                setState(
                      () {
                    activeStatus = statusList[5];
                    scrollLoadmore = true;
                    scrollOffset = 0;
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.cancel,
                      color: primary,
                    ),
                    Text(
                      getTranslated(context, "CANCELLED_LBL")!,
                      style: Theme.of(context).textTheme.caption!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cancelled ?? "",
                      style:
                      TextStyle(color: black, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Card(
            elevation: 0,
            child: InkWell(
              onTap: () {
                setState(() {
                  activeStatus = statusList[6];
                  scrollLoadmore = true;
                  scrollOffset = 0;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload,
                      color: primary,
                    ),
                    Text(
                      getTranslated(context, "RETURNED_LBL")!,
                      style: Theme.of(context).textTheme.caption!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      returned ?? "",
                      style:
                      TextStyle(color: black, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  orderItem(int index) {
    Order_Model model = orderList[index];
    Color back;

    if ((model.itemList![0].activeStatus!) == DELIVERD)
      back = Colors.green;
    else if ((model.itemList![0].activeStatus!) == SHIPED)
      back = Colors.orange;
    else if ((model.itemList![0].activeStatus!) == CANCLED ||
        model.itemList![0].activeStatus! == RETURNED)
      back = red;
    else if ((model.itemList![0].activeStatus!) == PROCESSED)
      back = Colors.indigo;
    else if ((model.itemList![0].activeStatus!) == PROCESSED)
      back = Colors.indigo;
    else if (model.itemList![0].activeStatus! == "awaiting")
      back = Colors.black;
    else
      back = Colors.cyan;

    return Card(
      elevation: 0,
      margin: EdgeInsets.all(5.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: [
                        Text(
                          getTranslated(context, "Order_No")! + ".",
                          style: TextStyle(color: grey),
                        ),
                        Text(
                          model.id!,
                          style: TextStyle(color: black),
                        ),
                      ],
                    ),
                    Spacer(),
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: back,
                        borderRadius: new BorderRadius.all(
                          const Radius.circular(
                            4.0,
                          ),
                        ),
                      ),
                      child: Text(
                        capitalize(model.itemList![0].activeStatus!),
                        style: TextStyle(color: white),
                      ),
                    )
                  ],
                ),
              ),
              Divider(),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: secondary,
                          ),
                          Expanded(
                            child: Text(
                              model.name != null && model.name!.length > 0
                                  ? " " + capitalize(model.name!)
                                  : " ",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      child: Row(
                        children: [
                          Icon(
                            Icons.call,
                            size: 14,
                            color: secondary,
                          ),
                          Text(
                            " " + model.mobile!,
                            style: TextStyle(
                                color: black,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                      onTap: () {
                        //  _launchCaller(index);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.money,
                          size: 14,
                          color: secondary,
                        ),
                        Row(
                          children: [
                            Text(
                              " " +
                                  getTranslated(context, "PayableTXT")! +
                                  ": ",
                              style: TextStyle(color: grey),
                            ),
                            Text(
                              " " + CUR_CURRENCY + " " + model.payable!,
                              style: TextStyle(color: black),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 14,
                          color: secondary,
                        ),
                        Text(
                          " " + model.payMethod!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 14,
                      color: secondary,
                    ),
                    Row(
                      children: [
                        Text(
                          " " + getTranslated(context, "ORDER_DATE")! + ": ",
                          style: TextStyle(color: grey),
                        ),
                        Text(
                          model.orderDate!,
                          style: TextStyle(color: black),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        onTap: () async {
          print("${model.id}");
          var result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetail(
                //   model: orderList[index],
                id: model.id,
              ),
            ),
          );
          print("Status Result : " + result.toString());
          if(result == true){
            scrollLoadmore = true;
            scrollOffset = 0;
            getOrder();
          }
          // setState(() {
          //   getOrder();
          //   },
          // );
        },
      ),
    );
  }
  catChart() {
    Size size = MediaQuery.of(context).size;
    double width = size.width > size.height ? size.height : size.width;
    double ratio;
    if (width > 600) {
      ratio = 0.5;
      // Do something for tablets here
    } else {
      ratio = 0.8;
      // Do something for phones
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: AspectRatio(
        aspectRatio: 1.23,
        child: Card(
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  getTranslated(context, "CatWiseCount")!,
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(color: primary),
                ),
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      height: 18,
                    ),
                    Expanded(
                      flex: 2,
                      child: AspectRatio(
                        aspectRatio: .8,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                    touchCallback: (pieTouchResponse) {
                                  // ingnore abc
                                  setState(
                                    () {
                                      final desiredTouch =
                                          pieTouchResponse.touchInput
                                                  is! PointerExitEvent &&
                                              pieTouchResponse.touchInput
                                                  is! PointerUpEvent;
                                      if (desiredTouch &&
                                          pieTouchResponse.touchedSection !=
                                              null) {
                                        touchedIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                      } else {
                                        touchedIndex = -1;
                                      }
                                    },
                                  );
                                }),
                                borderData: FlBorderData(
                                  show: false,
                                ),
                                sectionsSpace: 0,
                                startDegreeOffset: 180,
                                centerSpaceRadius: 40,
                                sections: showingSections(),
                              ),
                            ),

                            // Text("Category wise product's count",style: TextStyle(fontWeight: FontWeight.bold,color: primary),)
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shrinkWrap: true,
                        itemCount: colorList.length,
                        itemBuilder: (context, i) {
                          return Indicators(
                            color: colorList[i],
                            text: catList![i] + " " + catCountList![i],
                            textColor:
                                touchedIndex == i ? Colors.black : Colors.grey,
                            isSquare: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(
      catCountList!.length,
      (i) {
        final isTouched = i == touchedIndex;
        //  final double opacity = isTouched ? 1 : 0.6;

        final double fontSize = isTouched ? 25 : 16;
        final double radius = isTouched ? 60 : 50;

        return PieChartSectionData(
          color: colorList[i],
          value: double.parse(catCountList![i].toString()),
          title: "",
          radius: radius,
          titleStyle:
              TextStyle(fontSize: fontSize, color: const Color(0xffffffff)),
        );
      },
    );
  }

  noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            noIntImage(),
            noIntText(context),
            noIntDec(context),
            AppBtn(
              title: getTranslated(context, "TRY_AGAIN_INT_LBL")!,
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();

                Future.delayed(Duration(seconds: 2)).then(
                  (_) async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      getStatics();
                      getSallerDetail();
                      //      getDeliveryBoy();
                       getOrder(); //API Call
                    } else {
                      await buttonController!.reverse();
                      setState(
                        () {},
                      );
                    }
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Future<Null> _refresh() async {
    Completer<Null> completer = new Completer<Null>();
    await Future.delayed(Duration(seconds: 3)).then(
      (onvalue) {
        completer.complete();
        // offset = 0;
        // total = 0;
        // orderList.clear();
        // orderList.clear();
        getStatics();
        print("referecs state");
        // getSallerDetail();
        // //   getDeliveryBoy();
        // getZipCodes();
        scrollLoadmore = true;
        scrollOffset = 0;
        orderList.clear();
        getOrder();
        print("get Order call");
        setState(() {
            _isLoading = false;
          },
        );
      },
    );
    return completer.future;
  }

  Future<Null> getOrder() async {
    if (readOrder) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (scrollLoadmore) {
          if (mounted)
            setState(() {
              scrollLoadmore = false;
              scrollGettingData = true;
              if (scrollOffset == 0) {
                orderList = [];
              }
            });
          CUR_USERID = await getPrefrence(Id);
          CUR_USERNAME = await getPrefrence(Username);

          var parameter = {
            SellerId: CUR_USERID,
            LIMIT: perPage.toString(),
            OFFSET: scrollOffset.toString(),
            SEARCH: _searchText.trim(),
          };
          if (start != null)
            parameter[START_DATE] = "${startDate.toLocal()}".split(' ')[0];
          if (end != null)
            parameter[END_DATE] = "${endDate.toLocal()}".split(' ')[0];
          if (activeStatus != null) {
            if (activeStatus == awaitingPayment) activeStatus = "awaiting";
            parameter[ActiveStatus] = activeStatus!;
          }

          apiBaseHelper.postAPICall(getOrdersApi, parameter).then(
                (getdata) async {
              bool error = getdata["error"];
              String? msg = getdata["message"];
              scrollGettingData = false;
              if (scrollOffset == 0) scrollNodata = error;

              if (!error) {
                all = getdata["total"];
                received = getdata["received"];
                processed = getdata["processed"];
                shipped = getdata["shipped"];
                delivered = getdata["delivered"];
                cancelled = getdata["cancelled"];
                returned = getdata["returned"];
                awaiting = getdata["awaiting"];
                tempList.clear();
                var data = getdata["data"];
                print("data : $data");
                if (data.length != 0) {
                  tempList = (data as List)
                      .map((data) => new Order_Model.fromJson(data))
                      .toList();

                  setState(() {
                    orderList.addAll(tempList);
                  });

                  scrollLoadmore = true;
                  scrollOffset = scrollOffset + perPage;
                } else {
                  scrollLoadmore = false;
                }
              } else {
                scrollLoadmore = false;
              }
              if (mounted)
                setState(() {
                  scrollLoadmore = false;
                });
            },
            onError: (error) {
              setSnackbar(error.toString());
            },
          );
        }
      } else {
        if (mounted)
          setState(
                () {
              _isNetworkAvail = false;
              scrollLoadmore = false;
            },
          );
      }
      return null;
    } else {
      setSnackbar('You have not authorized permission for read order!!');
    }
  }

  firstHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        getOrderButton(),
        getBalanceButton(),
        getProductsButton(),
      ],
    );
  }

  getOrderButton() {
    return Expanded(
      flex: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderList(),
            ),
          );
        },
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: primary,
                ),
                Text(
                  getTranslated(context, "ORDER")!,
                  style: TextStyle(
                    color: grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  totalorderCount ?? "",
                  style: TextStyle(
                    color: black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  getBalanceButton() {
    return Expanded(
      flex: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WalletHistory(), //  WalletHistory(),
            ),
          );
        },
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: primary,
                ),
                Text(
                  getTranslated(context, "BALANCE_LBL")!,
                  style: TextStyle(
                    color: grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CUR_CURRENCY + " " + CUR_BALANCE,
                  style: TextStyle(
                    color: black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  getProductsButton() {
    return Expanded(
      flex: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductList(
                flag: '',
              ),
            ),
          );
        },
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Icon(
                  Icons.wallet_giftcard,
                  color: primary,
                ),
                Text(
                  getTranslated(context, "PRODUCT_LBL")!,
                  style: TextStyle(
                    color: grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  totalproductCount ?? "",
                  style: TextStyle(
                    color: black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  secondHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        getCustomerButton(),
        getRattingButton(),
      ],
    );
  }

  getRattingButton() {
    return Expanded(
      flex: 1,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Icon(
                Icons.star_rounded,
                color: primary,
              ),
              Text(
                "Rating",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: grey,
                ),
              ),
              Text(
                RATTING + r" / " + NO_OFF_RATTING,
                style: TextStyle(
                  color: black,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
      ),
    );
  }

  getCustomerButton() {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Customers(),
            ),
          );
        },
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Icon(
                  Icons.group,
                  color: primary,
                ),
                Text(
                  getTranslated(context, "CUSTOMER_LBL")!,
                  style: TextStyle(
                    color: grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  totalcustCount ?? "",
                  style: TextStyle(
                    color: black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  thirdHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        getSoldOutProduct(),
        getLowStockProduct(),
      ],
    );
  }

  getSoldOutProduct() {
    return Expanded(
      flex: 2,
      child: Card(
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductList(
                  flag: "sold",
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Icon(
                  Icons.not_interested,
                  color: primary,
                ),
                Text(
                  getTranslated(context, "Sold Out Products")!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    color: grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  totalsoldOutCount ?? "",
                  style: TextStyle(
                    color: black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  getLowStockProduct() {
    return Expanded(
      flex: 2,
      child: Card(
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductList(
                  flag: "low",
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Icon(
                  Icons.offline_bolt,
                  color: primary,
                ),
                Text(
                  getTranslated(context, "Low Stock Products")!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  totallowStockCount ?? "",
                  style: TextStyle(
                    color: black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> setOpenClose(status) async {
    var parameter = {
      "seller_id": CUR_USERID,
      "open_close_status": status ?? "",
    };

    apiBaseHelper.postAPICall(openCloseApi, parameter).then(
          (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        print(parameter);
        if (!error) {
          await buttonController!.reverse();
          setSnackbar(msg!);
          setState(() {

          });
        } else {
          await buttonController!.reverse();
          setSnackbar(msg!);
          setState(() {});
        }
      },
      onError: (error) {
        setSnackbar(error.toString());
      },
    );
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }
}
