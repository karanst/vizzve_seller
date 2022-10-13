import 'dart:convert';
/// message : "Category retrieved successfully"
/// error : false
/// data : [{"id":"1","name":"Chinese Food","parent_id":"0","slug":"chinese-food","image":"uploads/media/2022/images_(29).jpg","banner":null,"row_order":"0","status":"1","clicks":"205"},{"id":"4","name":"south indian food","parent_id":"0","slug":"south-indian-food","image":"uploads/media/2022/download_-_2022-01-29T124643_587.jpg","banner":null,"row_order":"0","status":"1","clicks":"296"},{"id":"7","name":"Idli","parent_id":"0","slug":"idli","image":"uploads/media/2022/download_-_2022-01-29T124643_5871.jpg","banner":"","row_order":"0","status":"1","clicks":"0"},{"id":"9","name":"Italian","parent_id":"0","slug":"italian","image":"uploads/media/2022/download_(94).jpg","banner":null,"row_order":"0","status":"1","clicks":"50"},{"id":"11","name":"Full Meal","parent_id":"0","slug":"full-meal","image":"uploads/media/2022/download_(98)1.jpg","banner":null,"row_order":"0","status":"1","clicks":"196"},{"id":"15","name":"Dessert","parent_id":"0","slug":"dessert","image":"uploads/media/2022/download_-_2022-02-04T150516_547.jpg","banner":"","row_order":"0","status":"1","clicks":"30"},{"id":"23","name":"Nonveg","parent_id":"0","slug":"nonveg","image":"uploads/media/2022/261.jpg","banner":null,"row_order":"0","status":"1","clicks":"7"},{"id":"25","name":"ds","parent_id":"0","slug":"ds","image":"uploads/media/2022/261.jpg","banner":null,"row_order":"0","status":"1","clicks":"0"},{"id":"27","name":"Indian French Fries","parent_id":"0","slug":"indian-french-fries","image":"uploads/media/2022/dewr45.jpg","banner":"uploads/media/2022/dewr45.jpg","row_order":"0","status":"1","clicks":"28"},{"id":"30","name":"DEMO Category","parent_id":"0","slug":"demo-category","image":"uploads/media/2022/vizzve_food_logo1.png","banner":null,"row_order":"0","status":"1","clicks":"0"}]

CategoryModel categoryModelFromJson(String str) => CategoryModel.fromJson(json.decode(str));
String categoryModelToJson(CategoryModel data) => json.encode(data.toJson());
class CategoryModel {
  CategoryModel({
      String? message, 
      bool? error, 
      List<Data>? data,}){
    _message = message;
    _error = error;
    _data = data;
}

  CategoryModel.fromJson(dynamic json) {
    _message = json['message'];
    _error = json['error'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(Data.fromJson(v));
      });
    }
  }
  String? _message;
  bool? _error;
  List<Data>? _data;

  String? get message => _message;
  bool? get error => _error;
  List<Data>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = _message;
    map['error'] = _error;
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// id : "1"
/// name : "Chinese Food"
/// parent_id : "0"
/// slug : "chinese-food"
/// image : "uploads/media/2022/images_(29).jpg"
/// banner : null
/// row_order : "0"
/// status : "1"
/// clicks : "205"

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      String? id, 
      String? name, 
      String? parentId, 
      String? slug, 
      String? image, 
      dynamic banner, 
      String? rowOrder, 
      String? status, 
      String? clicks,}){
    _id = id;
    _name = name;
    _parentId = parentId;
    _slug = slug;
    _image = image;
    _banner = banner;
    _rowOrder = rowOrder;
    _status = status;
    _clicks = clicks;
}

  Data.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _parentId = json['parent_id'];
    _slug = json['slug'];
    _image = json['image'];
    _banner = json['banner'];
    _rowOrder = json['row_order'];
    _status = json['status'];
    _clicks = json['clicks'];
  }
  String? _id;
  String? _name;
  String? _parentId;
  String? _slug;
  String? _image;
  dynamic _banner;
  String? _rowOrder;
  String? _status;
  String? _clicks;

  String? get id => _id;
  String? get name => _name;
  String? get parentId => _parentId;
  String? get slug => _slug;
  String? get image => _image;
  dynamic get banner => _banner;
  String? get rowOrder => _rowOrder;
  String? get status => _status;
  String? get clicks => _clicks;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['parent_id'] = _parentId;
    map['slug'] = _slug;
    map['image'] = _image;
    map['banner'] = _banner;
    map['row_order'] = _rowOrder;
    map['status'] = _status;
    map['clicks'] = _clicks;
    return map;
  }

}