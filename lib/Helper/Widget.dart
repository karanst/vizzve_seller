import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';


showToast(msg){
  Fluttertoast.showToast(
      msg: "$msg",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Color(0xff9ECB3D),
      textColor: Colors.white,
      fontSize: 12.0
  );
}