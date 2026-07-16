// example/set_pairable.dart — set adapter pairable state.

import 'package:bluez_native/bluez_native.dart';

Future<void> main(List<String> args) async {
  bool targetState = false;
  if (args.isNotEmpty) {
    if (args[0].toLowerCase() == 'true') {
      targetState = true;
    } else if (args[0].toLowerCase() == 'false') {
      targetState = false;
    } else {
      print('Usage: dart run example/set_pairable.dart [true|false]');
      return;
    }
  }

  final client = BlueZClient();
  await client.connect();

  if (client.adapters.isEmpty) {
    print('No adapters found');
    await client.close();
    return;
  }

  final adapter = client.adapters.first;

  if (!adapter.powered) {
    print('Powering on adapter...');
    await adapter.setPowered(true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  print('Current pairable: ${adapter.pairable}');

  print('Setting pairable to $targetState...');
  try {
    await adapter.setPairable(targetState);
    print('Successfully set pairable to $targetState.');
  } catch (e) {
    print('Failed to set pairable: $e');
  }

  print('New pairable state: ${adapter.pairable}');

  await client.close();
  print('Done.');
}
