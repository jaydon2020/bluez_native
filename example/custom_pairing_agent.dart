// example/custom_pairing_agent.dart — custom pairing agent example.

import 'dart:io';

import 'package:bluez_native/bluez_native.dart';

import 'example_utils.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Usage: dart run example/custom_pairing_agent.dart <device_address> '
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

  print('Registering custom pairing agent...');
  client.registerAgent();

  // Listen for agent requests
  final sub = client.agentRequest.listen((req) {
    print('\n[Agent Request] Type: ${req.requestType.name}');
    
    if (req.requestType == AgentRequestType.requestConfirmation) {
      print('Please confirm passkey: ${req.passkey.toString().padLeft(6, '0')}');
      stdout.write('Type "yes" to accept or "no" to reject: ');
      final response = stdin.readLineSync()?.trim().toLowerCase();
      final accepted = response == 'y' || response == 'yes';
      client.agentRespond(req.requestId, accepted: accepted);
    } else if (req.requestType == AgentRequestType.requestPinCode || 
               req.requestType == AgentRequestType.requestPasskey) {
      stdout.write('Enter PIN/Passkey: ');
      final response = stdin.readLineSync()?.trim();
      client.agentRespond(req.requestId, accepted: true, response: response);
    } else if (req.requestType == AgentRequestType.displayPasskey) {
      print('Display Passkey: ${req.passkey.toString().padLeft(6, '0')} (Entered: ${req.entered})');
    } else if (req.requestType == AgentRequestType.displayPinCode) {
      print('Display PIN Code: ${req.pinCode}');
    } else if (req.requestType == AgentRequestType.requestAuthorization || 
               req.requestType == AgentRequestType.authorizeService) {
      stdout.write('Authorize? (y/n): ');
      final response = stdin.readLineSync()?.trim().toLowerCase();
      final accepted = response == 'y' || response == 'yes';
      client.agentRespond(req.requestId, accepted: accepted);
    } else if (req.requestType == AgentRequestType.cancel) {
      print('Request cancelled.');
    } else if (req.requestType == AgentRequestType.release) {
      print('Agent released.');
    }
  });

  final target = await findDevice(client, adapter, args[0], timeout: timeout);
  if (target == null) {
    await sub.cancel();
    client.unregisterAgent();
    await client.close();
    return;
  }

  print('Found: ${target.name.isNotEmpty ? target.name : target.address}');
  print('Paired: ${target.paired}');

  if (target.paired) {
    print('Already paired.');
  } else {
    print('Pairing...');
    try {
      await target.pair();
      print('Paired: ${target.paired}');
    } on BlueZOperationException catch (e) {
      print('Pairing failed: $e');
    }
  }

  await sub.cancel();
  print('Unregistering agent...');
  client.unregisterAgent();
  
  await client.close();
  print('Done.');
}
