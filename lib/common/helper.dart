import 'dart:io';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:hex/hex.dart';
import 'package:pointycastle/export.dart';
import 'package:provider/provider.dart';
import 'package:xdag/common/color.dart';
import 'package:xdag/model/config_modal.dart';
import 'package:xdag/widget/button.dart';
import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:fast_base58/fast_base58.dart';
import 'package:xdag/widget/desktop.dart';

class Helper {
  static bool isDesktop = Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  static bool checkName(String name) {
    RegExp regExp2 = RegExp(r",");
    return !regExp2.hasMatch(name);
  }

  static String removeTrailingZeros(String str) {
    double num = double.parse(str);
    String result;
    if (num == num.toInt()) {
      result = "${num.toInt()}.00";
    } else {
      result = num.toString();
      result = result.replaceAll(RegExp(r"(\.\d*?[1-9]+?)0+?$"), r"$1");
      result = result.replaceAll(RegExp(r"\.?$"), "");
    }
    return result;
  }

  static String formatDate(String time) {
    DateTime date = DateTime.parse(time);
    return "${date.year}-${date.month < 10 ? "0${date.month}" : date.month}";
  }

  static String formatString(String content) {
    if (content.length > 16) {
      return "${content.substring(0, 8)}...${content.substring(content.length - 8)}";
    }
    return content;
  }

  static String formatTime(String time) {
    DateTime date = DateTime.parse(time);
    // MM-dd HH:mm
    return "${date.month < 10 ? "0${date.month}" : date.month}-${date.day < 10 ? "0${date.day}" : date.day} ${date.hour < 10 ? "0${date.hour}" : date.hour}:${date.minute < 10 ? "0${date.minute}" : date.minute}";
  }

  static String formatFullTime(String time) {
    DateTime date = DateTime.parse(time);
    // YYYY-MM-dd HH:mm
    return "${date.year}-${date.month < 10 ? "0${date.month}" : date.month}-${date.day < 10 ? "0${date.day}" : date.day} ${date.hour < 10 ? "0${date.hour}" : date.hour}:${date.minute < 10 ? "0${date.minute}" : date.minute}";
  }

  static String formatDouble(String num) {
    String result;
    double number = double.parse(num);
    if (number == number.toInt()) {
      result = "${number.toInt()}.00";
    } else {
      // 向下保留两位小数
      result = number.toStringAsFixed(2);
    }
    return result;
  }

  static TextStyle fitChineseFont(BuildContext context, TextStyle textStyle, {listen = true}) {
    ConfigModal configModal = Provider.of<ConfigModal>(context, listen: listen);
    if (configModal.local.languageCode == const Locale("ja").languageCode || configModal.local.languageCode == const Locale("zh").languageCode) {
      return textStyle.useSystemChineseFont();
    }
    return textStyle;
  }

  // show toast
  static void showToast(BuildContext context, String msg, {Color color = DarkColors.mainColor}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      content: Text(
        msg,
        style: Helper.fitChineseFont(
          context,
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
          listen: false,
        ),
      ),
    ));
  }

  static void showDialog(BuildContext context, String title, Widget content, String btnText, VoidCallback onPressed) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: DarkColors.bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          titlePadding: const EdgeInsets.fromLTRB(12.0, 15.0, 12, 0),
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(15.0, 25.0, 15.0, 0.0),
          actionsPadding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
          title: Row(
            children: <Widget>[
              MyCupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DarkColors.blockColor,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      title,
                      style: Helper.fitChineseFont(context, const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.w700)),
                    ),
                  )),
              const SizedBox(width: 40)
            ],
          ),
          content: content,
          actions: <Widget>[
            Button(
              text: btnText,
              width: ScreenHelper.screenWidth - 60,
              bgColor: DarkColors.mainColor54,
              disable: true,
              onPressed: onPressed,
            ),
          ],
        );
      },
    );
  }

  // show bottom sheet
  static Future<dynamic> showBottomSheet(BuildContext context, Widget child) async {
    return await showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      backgroundColor: DarkColors.bgColor,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext buildContext) => child,
    );
  }

  static Uint8List sha256ripemd160(Uint8List data) {
    Digest sha256 = Digest("SHA-256");
    RIPEMD160Digest ripemd160 = RIPEMD160Digest();
    Uint8List ripemd160Result = ripemd160.process(sha256.process(data));
    Uint8List checksum = sha256.process(sha256.process(ripemd160Result));
    Uint8List res = Uint8List.fromList(ripemd160Result + checksum.sublist(0, 4));
    return res;
  }

  static String base58Encode(List<int> bytes) {
    var alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    var base58 = StringBuffer();
    var value = BigInt.parse(bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
    while (value > BigInt.zero) {
      var mod = value.remainder(BigInt.from(58));
      base58.write(alphabet[mod.toInt()]);
      value = value ~/ BigInt.from(58);
    }
    for (var i = 0; i < bytes.length && bytes[i] == 0; i++) {
      base58.write(alphabet[0]);
    }
    return base58.toString().split('').reversed.join();
  }

  static List<int> base58Decode(String input) {
    var decodedRaw = Base58Decode(input);
    return decodedRaw.reversed.toList();
  }

  static String getAddressByWallet(bip32.BIP32 hdWallet) {
    Uint8List pubKey = hdWallet.publicKey;
    Uint8List hashedPubKey = sha256ripemd160(pubKey);
    return base58Encode(hashedPubKey);
  }

  static void changeAndroidStatusBarAndNavBar(bool isMask) async {
    if (Platform.isAndroid) {
      await FlutterStatusbarcolor.setStatusBarColor(isMask ? DarkColors.bgColorMask : DarkColors.bgColor);
      FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
      await FlutterStatusbarcolor.setNavigationBarColor(isMask ? DarkColors.bgColorMask : DarkColors.bgColor);
    }
  }

  static void changeAndroidStatusBar(bool isMask) async {
    if (Platform.isAndroid) {
      await FlutterStatusbarcolor.setStatusBarColor(isMask ? DarkColors.bgColorMask2 : DarkColors.bgColor);
      FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
      await FlutterStatusbarcolor.setNavigationBarColor(DarkColors.bgColor);
    }
  }

  static bip32.BIP32 createWallet({bool isPrivate = false, String content = ''}) {
    if (isPrivate) {
      var decodedKey = Base58Decode(content);
      var privateKey = Uint8List.fromList(decodedKey.sublist(1, 33));
      return bip32.BIP32.fromPrivateKey(privateKey, Uint8List(32));
    } else {
      return getWalletByMnemonic(content);
    }
  }

  static bip32.BIP32 getWalletByMnemonic(String mnemonic) {
    String seed = bip39.mnemonicToSeedHex(mnemonic.trim());
    bip32.BIP32 hdWallet = bip32.BIP32.fromSeed(HEX.decode(seed) as Uint8List);
    bip32.BIP32 child = hdWallet.derivePath("m/44'/586'/0'/0/0");
    return child;
  }
}

class ScreenHelper {
  static bool init = false;
  static double screenWidth = 0;
  static double screenHeight = 0;
  static double bottomPadding = 0;
  static double topPadding = 0;

  static void initScreen(BuildContext context) {
    if (init) {
      return;
    }
    init = true;
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    screenWidth = mediaQueryData.size.width;
    screenHeight = mediaQueryData.size.height;
    bottomPadding = mediaQueryData.padding.bottom;
    topPadding = mediaQueryData.padding.top;
  }
}
