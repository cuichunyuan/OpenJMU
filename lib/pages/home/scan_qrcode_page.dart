import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qr_reader/qrcode_reader_view.dart';

import 'package:openjmu/constants/constants.dart';

@FFRoute(name: 'openjmu://scan-qrcode', routeName: '扫描二维码')
class ScanQrCodePage extends StatefulWidget {
  @override
  _ScanQrCodePageState createState() => _ScanQrCodePageState();
}

class _ScanQrCodePageState extends State<ScanQrCodePage> {
  final GlobalKey<QrcodeReaderViewState> _key = GlobalKey<QrcodeReaderViewState>();

  Future<void> onScan(BuildContext context, String data) async {
    if (data == null) {
      showCenterErrorToast('没有识别到二维码~换一张试试');
      return;
    }
    if (API.urlReg.stringMatch(data) != null) {
      Navigator.of(context).pop();
      unawaited(API.launchWeb(url: '$data'));
    } else if (API.schemeUserPage.stringMatch(data) != null) {
      unawaited(Navigator.of(context).pushReplacementNamed(
        Routes.OPENJMU_USER,
        arguments: <String, dynamic>{
          'uid': int.parse(data.substring(API.schemeUserPage.pattern.length - 2))
        },
      ));
    } else {
      final bool needCopy = await ConfirmationDialog.show(
        context,
        title: '扫码结果',
        content: '$data',
        showConfirm: true,
        confirmLabel: '复制',
        cancelLabel: '返回',
      );
      if (needCopy) {
        unawaited(Clipboard.setData(ClipboardData(text: '$data')));
      }
      _key.currentState.startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FixedAppBarWrapper(
      appBar: FixedAppBar(title: Text('扫描二维码')),
      body: QrcodeReaderView(
        key: _key,
        onScan: (String data) => onScan(context, data),
      ),
    );
  }
}
