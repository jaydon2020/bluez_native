// example/agent_pair_device.dart — pair with a Bluetooth device using a
// custom BlueZ pairing agent.

import 'dart:async';
import 'dart:io';

import 'package:bluez_native/bluez_native.dart';

import 'example_utils.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Usage: dart run example/agent_pair_device.dart <device_address> '
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

  print('Registering pairing agent...');
  client.registerAgent();

  final agentSub = client.agentRequest.listen((req) {
    _handleAgentRequest(client, req);
  });

  final target = await findDevice(client, adapter, args[0], timeout: timeout);
  if (target == null) {
    await _cleanup(client, agentSub);
    return;
  }

  print('Found: ${target.name.isNotEmpty ? target.name : target.address}');
  print('Paired: ${target.paired}');

  if (target.paired) {
    print('Already paired.');
    await _cleanup(client, agentSub);
    return;
  }

  print('Pairing with custom agent...');
  try {
    await target.pair();
    print('Paired: ${target.paired}');
  } on BlueZOperationException catch (e) {
    print('Pairing failed: $e');
  }

  print('Unregistering pairing agent...');
  await _cleanup(client, agentSub);
  print('Done.');
}

Future<void> _cleanup(
  BlueZClient client,
  StreamSubscription<BlueZAgentRequest> agentSub,
) async {
  await agentSub.cancel();
  client.unregisterAgent();
  await client.close();
}

void _handleAgentRequest(BlueZClient client, BlueZAgentRequest req) {
  final device = _deviceName(req.devicePath);

  print('');
  print('Agent request: ${req.requestType.name}');
  if (device.isNotEmpty) print('Device: $device');

  switch (req.requestType) {
    case AgentRequestType.requestPinCode:
      final pin = _promptRequired('Enter PIN code');
      client.agentRespond(req.requestId, response: pin);

    case AgentRequestType.displayPinCode:
      print('Enter this PIN on the remote device: ${req.pinCode}');

    case AgentRequestType.requestPasskey:
      final passkey = _promptRequired('Enter passkey');
      client.agentRespond(req.requestId, response: passkey);

    case AgentRequestType.displayPasskey:
      final passkey = req.passkey.toString().padLeft(6, '0');
      print('Enter this passkey on the remote device: $passkey');
      if (req.entered > 0) {
        print('Remote device reports ${req.entered} digit(s) entered.');
      }

    case AgentRequestType.requestConfirmation:
      final passkey = req.passkey.toString().padLeft(6, '0');
      final accepted = _confirm('Confirm passkey $passkey?');
      client.agentRespond(req.requestId, accepted: accepted);

    case AgentRequestType.requestAuthorization:
      final accepted = _confirm('Allow this device to pair?');
      client.agentRespond(req.requestId, accepted: accepted);

    case AgentRequestType.authorizeService:
      print('Service UUID: ${req.uuid}');
      final accepted = _confirm('Allow this device to use this service?');
      client.agentRespond(req.requestId, accepted: accepted);

    case AgentRequestType.cancel:
      print('BlueZ canceled the pairing request.');

    case AgentRequestType.release:
      print('BlueZ released the pairing agent.');
  }
}

String _promptRequired(String label) {
  while (true) {
    stdout.write('$label: ');
    final value = stdin.readLineSync()?.trim() ?? '';
    if (value.isNotEmpty) return value;
    print('Value cannot be empty.');
  }
}

bool _confirm(String label) {
  while (true) {
    stdout.write('$label [y/N]: ');
    final value = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (value == 'y' || value == 'yes') return true;
    if (value.isEmpty || value == 'n' || value == 'no') return false;
    print('Please answer y or n.');
  }
}

String _deviceName(String devicePath) {
  if (devicePath.isEmpty) return '';
  final parts = devicePath.split('/');
  return parts.last.replaceAll('dev_', '').replaceAll('_', ':');
}
