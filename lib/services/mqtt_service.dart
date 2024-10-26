import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  MqttServerClient client;

  Function(String) onMessageReceived;
  Function(String) onStatusChanged;

  MQTTService(this.onMessageReceived, this.onStatusChanged)
      : client = MqttServerClient('119.2.119.202', 'flutter_client') {
    client.port = 1883;
    client.logging(on: true);
    // client.keepAlivePeriod = 10;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.pongCallback = pong;
  }

  Future<void> connect() async {
    final connMessage = MqttConnectMessage()
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      onStatusChanged('Error: ${e.toString()}');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT client connected');
      onStatusChanged('Connected');
    } else {
      print('Connection failed - disconnecting');
      onStatusChanged('Connection failed');
      client.disconnect();
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      onMessageReceived(payload);
    });
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void onConnected() {
    print('Connected to the broker');
    onStatusChanged('Connected');
  }

  void onDisconnected() {
    print('Disconnected from the broker');
    onStatusChanged('Disconnected');
  }

  void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
    onStatusChanged('Subscribed to $topic');
  }

  void pong() {
    print('Ping response client callback invoked');
 n }
}
