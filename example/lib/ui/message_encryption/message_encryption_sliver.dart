import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MessageEncryptionSliver extends StatelessWidget {
  ably.Realtime? _realtime;
  ably.RealtimeChannel? _channel;

  MessageEncryptionSliver(this._realtime, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Message Encryption'),
        Text('Realtime client is ${_realtime}'),
        TextButton(
          child: Text('Connect and listen to channel'),
          onPressed: () async {
            final params = await ably.Crypto.getParams();
            final channelOptions =
                ably.RealtimeChannelOptions(cipher: params);
            final channel = _realtime!.channels.get("encrypted");
            channel.setOptions(channelOptions);
            channel.on().listen((event) {
              print("on().listen: ${event}");
            });
            channel.subscribe().listen((event) {
              print("subscribe().listen: ${event}");
            });
            channel.attach();
          },
        ),
        TextButton(
          child: Text('Publish encrypted message'),
          onPressed: () async {
            _channel!.publish(
                message: ably.Message(
                    name: "Hello",
                    data: {"payload": "this should be encrypted"}));
          },
        )
      ],
    );
  }
}
