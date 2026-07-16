// example/set_trust.dart — set a device as trusted.

import 'package:bluez_native/bluez_native.dart';

import 'example_utils.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Usage: dart run example/set_trust.dart <device_address> '
      '[--timeout <seconds>]',
    );
    return;
  }

  final timeout = parseScanTimeout(args);
  final client = BlueZClient();
  await client.connect();

  final adapter = client.adapters.first;

  if (!adapter.powered) {
    print('Powering on adapter...');
    await adapter.setPowered(true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  final target = await findDevice(client, adapter, args[0], timeout: timeout);
  if (target == null) {
    await client.close();
    return;
  }

  print('Found: ${target.name.isNotEmpty ? target.name : target.address}');
  print('Trusted: ${target.trusted}');

  if (target.trusted) {
    print('Already trusted.');
    await client.close();
    return;
  }

  print('Setting trust to true...');
  try {
    await target.setTrust(true);
    print('Trusted: ${target.trusted}');
  } on BlueZOperationException catch (e) {
    print('Set trust failed: $e');
  }

  await client.close();
  print('Done.');
}
