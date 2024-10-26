import 'package:flutter/material.dart';

class MqttProvider extends ChangeNotifier {
  String receivedMessage;

  MqttProvider({
    this.receivedMessage = " ",
  });
}
