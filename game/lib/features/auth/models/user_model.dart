import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// User data model matching Login API response
class UserModel {
  final int id;
  final int srNo;
  final String branchCode;
  final String userName;
  final String password;
  final String roleType;
  final String entryDate;
  final String? lastLoginDate;
  final bool isActive;
  final String name;
  final String sponsoringId;
  final String customerCode;
  final String? userUniqueKey;
  final String emailAddress;
  final String? tokenNo;
  final String accId;
  final String? designation;
  final String? profilePic;
  final String customerName;
  final int isShopify;
  final String activeStatus;
  final int isFounder;
  final String emailAddress1;
  final String? companyId;
  final String country;

  const UserModel({
    required this.id,
    required this.srNo,
    required this.branchCode,
    required this.userName,
    required this.password,
    required this.roleType,
    required this.entryDate,
    this.lastLoginDate,
    required this.isActive,
    required this.name,
    required this.sponsoringId,
    required this.customerCode,
    this.userUniqueKey,
    required this.emailAddress,
    this.tokenNo,
    required this.accId,
    this.designation,
    this.profilePic,
    required this.customerName,
    required this.isShopify,
    required this.activeStatus,
    required this.isFounder,
    required this.emailAddress1,
    this.companyId,
    required this.country,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      srNo: json['SrNo'] ?? 0,
      branchCode: (json['BranchCode'] ?? '').toString(),
      userName: (json['UserName'] ?? '').toString(),
      password: (json['Password'] ?? '').toString(),
      roleType: (json['RoleType'] ?? '').toString(),
      entryDate: (json['EntryDate'] ?? '').toString(),
      lastLoginDate: json['LastLoginDate']?.toString(),
      isActive: json['IsActive'] ?? false,
      name: (json['Name'] ?? '').toString(),
      sponsoringId: (json['Sponsoring_id'] ?? '').toString(),
      customerCode: (json['CustomerCode'] ?? '').toString(),
      userUniqueKey: json['UserUniqueKey']?.toString(),
      emailAddress: (json['EmailAddress'] ?? '').toString(),
      tokenNo: json['TokenNO']?.toString(),
      accId: (json['AccId'] ?? '').toString(),
      designation: json['Designation']?.toString(),
      profilePic: json['ProfilePic']?.toString(),
      customerName: (json['CustomerName'] ?? '').toString(),
      isShopify: json['IsShopify'] ?? 0,
      activeStatus: (json['ActiveStatus'] ?? '').toString(),
      isFounder: json['isFounder'] ?? 0,
      emailAddress1: (json['EmailAddress1'] ?? '').toString(),
      companyId: json['companyid']?.toString(),
      country: (json['country'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'SrNo': srNo,
        'BranchCode': branchCode,
        'UserName': userName,
        'Password': password,
        'RoleType': roleType,
        'EntryDate': entryDate,
        'LastLoginDate': lastLoginDate,
        'IsActive': isActive,
        'Name': name,
        'Sponsoring_id': sponsoringId,
        'CustomerCode': customerCode,
        'UserUniqueKey': userUniqueKey,
        'EmailAddress': emailAddress,
        'TokenNO': tokenNo,
        'AccId': accId,
        'Designation': designation,
        'ProfilePic': profilePic,
        'CustomerName': customerName,
        'IsShopify': isShopify,
        'ActiveStatus': activeStatus,
        'isFounder': isFounder,
        'EmailAddress1': emailAddress1,
        'companyid': companyId,
        'country': country,
      };

  UserModel copyWith({
    int? id,
    int? srNo,
    String? branchCode,
    String? userName,
    String? password,
    String? roleType,
    String? entryDate,
    String? lastLoginDate,
    bool? isActive,
    String? name,
    String? sponsoringId,
    String? customerCode,
    String? userUniqueKey,
    String? emailAddress,
    String? tokenNo,
    String? accId,
    String? designation,
    String? profilePic,
    String? customerName,
    int? isShopify,
    String? activeStatus,
    int? isFounder,
    String? emailAddress1,
    String? companyId,
    String? country,
  }) {
    return UserModel(
      id: id ?? this.id,
      srNo: srNo ?? this.srNo,
      branchCode: branchCode ?? this.branchCode,
      userName: userName ?? this.userName,
      password: password ?? this.password,
      roleType: roleType ?? this.roleType,
      entryDate: entryDate ?? this.entryDate,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      isActive: isActive ?? this.isActive,
      name: name ?? this.name,
      sponsoringId: sponsoringId ?? this.sponsoringId,
      customerCode: customerCode ?? this.customerCode,
      userUniqueKey: userUniqueKey ?? this.userUniqueKey,
      emailAddress: emailAddress ?? this.emailAddress,
      tokenNo: tokenNo ?? this.tokenNo,
      accId: accId ?? this.accId,
      designation: designation ?? this.designation,
      profilePic: profilePic ?? this.profilePic,
      customerName: customerName ?? this.customerName,
      isShopify: isShopify ?? this.isShopify,
      activeStatus: activeStatus ?? this.activeStatus,
      isFounder: isFounder ?? this.isFounder,
      emailAddress1: emailAddress1 ?? this.emailAddress1,
      companyId: companyId ?? this.companyId,
      country: country ?? this.country,
    );
  }
}

/// User preferences service for local storage
class UserPrefsService {
  static const _keyUserRecord = 'user_record_json';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRecord, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserRecord);
    if (raw == null || raw.isEmpty) return null;
    final Map<String, dynamic> json = jsonDecode(raw);
    return UserModel.fromJson(json);
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserRecord);
  }

  static Future<bool> isLoggedIn() async {
    final user = await loadUser();
    return user != null;
  }
}
