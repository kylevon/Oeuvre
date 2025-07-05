import 'dart:async';
import 'dart:js' as js;
import 'package:http/http.dart' as http;

class MetaMaskService {
  static const String _rpcUrl = 'http://127.0.0.1:8545';
  static const String _contractAddress =
      '0xa51c1fc2f0d1a1b8494ed1fe312d7c3a78ed91c0';

  static const Map<String, String> _functionSelectors = {
    'bidWithTracking': '0x26986ad5',
    'finalize': '0x4ef39b75',
    'endAuctionEarly': '0x40b9edbf',
    'vote': '0x632a9a52',
    'changeArtPresentation': '0x72853d34',
    'tokens': '0xe4860339',
    'totalBid': '0x8a9e8671',
    'createArtPiece': '0x8f4eb604',
    'getArtPiece': '0x8da5cb5b',
  };

  String? _connectedAddress;
  bool _isConnected = false;

  String? get connectedAddress => _connectedAddress;
  bool get isConnected => _isConnected;

  Future<bool> connect() async {
    try {
      final ethereum = js.context['ethereum'];
      if (ethereum == null) {
        throw Exception('MetaMask not found');
      }

      final accounts = await _callMetaMask('requestAccounts');
      if (accounts.isNotEmpty) {
        _connectedAddress = accounts[0];
        _isConnected = true;
        return true;
      }
      return false;
    } catch (e) {
      print('MetaMask connection error: $e');
      return false;
    }
  }

  Future<List<String>> _callMetaMask(String method,
      [List<dynamic>? params]) async {
    final completer = Completer<List<String>>();

    js.context.callMethod('eval', [
      '''
      window.ethereum.request({
        method: '$method',
        params: ${params ?? []}
      }).then(function(result) {
        window.flutterResult = result;
      }).catch(function(error) {
        window.flutterError = error;
      });
    '''
    ]);

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final result = js.context['flutterResult'];
      final error = js.context['flutterError'];

      if (result != null) {
        js.context['flutterResult'] = null;
        timer.cancel();
        completer.complete(List<String>.from(result));
      } else if (error != null) {
        js.context['flutterError'] = null;
        timer.cancel();
        completer.completeError(error);
      }
    });

    return completer.future;
  }

  Future<String> callContract(String functionName,
      {List<dynamic>? params}) async {
    if (!_isConnected) throw Exception('Not connected to MetaMask');

    final selector = _functionSelectors[functionName];
    if (selector == null) throw Exception('Unknown function: $functionName');

    String data = selector;
    if (params != null) {
      for (var param in params) {
        if (param is String && functionName == 'createArtPiece') {
          // Encode string parameters for createArtPiece
          final encoded = _encodeString(param);
          data += encoded;
        } else {
          data += param.toString().padLeft(64, '0');
        }
      }
    }

    final tx = {
      'from': _connectedAddress,
      'to': _contractAddress,
      'data': data,
      'gas': '0x1e8480',
    };

    if (functionName == 'bidWithTracking') {
      tx['value'] = params?[0] ?? '0x0';
    }

    final hash = await _callMetaMask('eth_sendTransaction', [tx]);
    return hash.first;
  }

  String _encodeString(String str) {
    // Simple string encoding - in production you'd use proper ABI encoding
    final bytes = str.codeUnits;
    final length = bytes.length;
    final lengthHex = length.toRadixString(16).padLeft(64, '0');
    final dataHex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return lengthHex + dataHex.padRight(64, '0');
  }

  Future<String> getContractData(String functionName,
      {List<dynamic>? params}) async {
    final selector = _functionSelectors[functionName];
    if (selector == null) throw Exception('Unknown function: $functionName');

    String data = selector;
    if (params != null) {
      data += params.map((p) => p.toString().padLeft(64, '0')).join();
    }

    final response = await http.post(
      Uri.parse(_rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: {
        'jsonrpc': '2.0',
        'method': 'eth_call',
        'params': [
          {
            'to': _contractAddress,
            'data': data,
          },
          'latest'
        ],
        'id': 1,
      },
    );

    final result = response.body;
    return result;
  }

  Future<String> getBalance(String address) async {
    final response = await http.post(
      Uri.parse(_rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: {
        'jsonrpc': '2.0',
        'method': 'eth_getBalance',
        'params': [address, 'latest'],
        'id': 1,
      },
    );

    final result = response.body;
    return result;
  }
}
