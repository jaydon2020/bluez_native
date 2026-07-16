// example/set_discoverable.dart — set adapter discoverable state.

import 'package:bluez_native/bluez_native.dart';

Future<void> main(List<String> args) async {
  bool targetState = false;
  if (args.isNotEmpty) {
    if (args[0].toLowerCase() == 'true') {
      targetState = true;
    } else if (args[0].toLowerCase() == 'false') {
      targetState = false;
    } else {
      print('Usage: dart run example/set_discoverable.dart [true|false]');
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

  print('Current discoverable: ${adapter.discoverable}');

  print('Setting discoverable to $targetState...');
  try {
    await adapter.setDiscoverable(targetState);
    print('Successfully set discoverable to $targetState.');
  } catch (e) {
    print('Failed to set discoverable: $e');
  }

  print('New discoverable state: ${adapter.discoverable}');

  await client.close();
  print('Done.');
}
