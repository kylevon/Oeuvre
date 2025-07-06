import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:http/http.dart' as http;

class MetaMaskService {
  static const String _rpcUrl = 'http://127.0.0.1:8545';
  static const String _contractAddress =
      '0x9a676e781a523b5d0c0e43731313a708cb607508';

  static const Map<String, String> _functionSelectors = {
    'createArtPiece': '0x48bf823b',
    'bid': '0x454a2ab3',
    'withdraw': '0x2e1a7d4d',
    'confirmAuction': '0xa61c8077',
    'cancelAuction': '0x96b5a755',
    'getArtPiece': '0x2e03e468',
    'getArtPieceCount': '0xa0857969',
    'getOwnership': '0x6bcfe592',
    'getUserArtPieces': '0xdb454930',
    'getActiveAuctions': '0xcf44b5d5',
    'getAcquiredArtPieces': '0x5406636f',
    'getAuctionBidders': '0xdf276469',
    'endAuctionEarly': '0xb0a9a2cd',
  };

  String? _connectedAddress;
  bool _isConnected = false;

  String? get connectedAddress => _connectedAddress;
  bool get isConnected => _isConnected;

  Future<bool> connect() async {
    try {
      // Check if MetaMask is available
      final ethereum = js.context['ethereum'];
      if (ethereum == null) {
        throw Exception(
            'MetaMask not found. Please install MetaMask extension.');
      }

      // Always force account selection - this will trigger MetaMask popup
      return await _forceRequestAccounts();
    } catch (e) {
      print('MetaMask connection error: $e');
      return false;
    }
  }

  void disconnect() {
    _connectedAddress = null;
    _isConnected = false;
    print('Disconnected from MetaMask');
  }

  Future<bool> switchAccount() async {
    disconnect();
    // Force a fresh connection that will show the popup
    return await _forceRequestAccounts();
  }

  Future<bool> _forceRequestAccounts() async {
    try {
      final completer = Completer<bool>();

      // More aggressive approach to force MetaMask popup
      js.context.callMethod('eval', [
        '''
        if (window.ethereum) {
          // Clear any cached state
          if (window.ethereum.removeAllListeners) {
            window.ethereum.removeAllListeners();
          }
          
          // Force disconnect and reconnect
          window.ethereum.request({
            method: 'wallet_requestPermissions',
            params: [{
              eth_accounts: {}
            }]
          }).then(function(permissions) {
            // After getting permissions, request accounts
            return window.ethereum.request({
              method: 'eth_requestAccounts'
            });
          }).then(function(accounts) {
            if (accounts && accounts.length > 0) {
              window.metamaskForceAccounts = accounts;
            } else {
              window.metamaskForceError = 'No accounts selected';
            }
          }).catch(function(error) {
            // If wallet_requestPermissions fails, try direct eth_requestAccounts
            window.ethereum.request({
              method: 'eth_requestAccounts'
            }).then(function(accounts) {
              if (accounts && accounts.length > 0) {
                window.metamaskForceAccounts = accounts;
              } else {
                window.metamaskForceError = 'No accounts selected';
              }
            }).catch(function(innerError) {
              window.metamaskForceError = innerError.message || innerError;
            });
          });
        } else {
          window.metamaskForceError = 'MetaMask not found';
        }
      '''
      ]);

      // Poll for result
      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        final accounts = js.context['metamaskForceAccounts'];
        final error = js.context['metamaskForceError'];

        if (accounts != null) {
          js.context['metamaskForceAccounts'] = null;
          timer.cancel();
          _connectedAddress = accounts[0];
          _isConnected = true;
          print('Connected to MetaMask: $_connectedAddress');
          completer.complete(true);
        } else if (error != null) {
          js.context['metamaskForceError'] = null;
          timer.cancel();
          completer.completeError(error);
        }
      });

      // Timeout after 30 seconds
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.completeError('Connection timeout');
        }
      });

      return completer.future;
    } catch (e) {
      print('Force account selection error: $e');
      return false;
    }
  }

  Future<List<String>> _requestAccounts() async {
    final completer = Completer<List<String>>();

    try {
      // Use eth_requestAccounts to force MetaMask popup
      js.context.callMethod('eval', [
        '''
        if (window.ethereum) {
          window.ethereum.request({
            method: 'eth_requestAccounts'
          }).then(function(accounts) {
            window.metamaskAccounts = accounts;
          }).catch(function(error) {
            window.metamaskError = error;
          });
        } else {
          window.metamaskError = 'MetaMask not found';
        }
      '''
      ]);

      // Poll for result
      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        final accounts = js.context['metamaskAccounts'];
        final error = js.context['metamaskError'];

        if (accounts != null) {
          js.context['metamaskAccounts'] = null;
          timer.cancel();
          completer.complete(List<String>.from(accounts));
        } else if (error != null) {
          js.context['metamaskError'] = null;
          timer.cancel();
          completer.completeError(error);
        }
      });

      // Timeout after 30 seconds
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.completeError('Connection timeout');
        }
      });
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  Future<String> callContract(String functionName,
      {List<dynamic>? params, String? value}) async {
    if (!_isConnected) throw Exception('Not connected to MetaMask');

    final selector = _functionSelectors[functionName];
    if (selector == null) throw Exception('Unknown function: $functionName');

    String data = selector;
    if (params != null) {
      for (var param in params) {
        if (param is String) {
          // Encode string parameters
          final encoded = _encodeString(param);
          data += encoded;
        } else if (param is int) {
          // Encode uint256 parameters
          final encoded = _encodeUint256(param);
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

    if (value != null && value.isNotEmpty) {
      tx['value'] = value;
    }

    final hash = await _sendTransaction(tx);
    return hash;
  }

  Future<String> _sendTransaction(Map<String, dynamic> transaction) async {
    final completer = Completer<String>();

    try {
      js.context.callMethod('eval', [
        '''
        if (window.ethereum) {
          window.ethereum.request({
            method: 'eth_sendTransaction',
            params: [${_mapToJson(transaction)}]
          }).then(function(hash) {
            window.txHash = hash;
          }).catch(function(error) {
            window.txError = error;
          });
        } else {
          window.txError = 'MetaMask not found';
        }
      '''
      ]);

      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        final hash = js.context['txHash'];
        final error = js.context['txError'];

        if (hash != null) {
          js.context['txHash'] = null;
          timer.cancel();
          completer.complete(hash);
        } else if (error != null) {
          js.context['txError'] = null;
          timer.cancel();
          completer.completeError(error);
        }
      });

      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.completeError('Transaction timeout');
        }
      });
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  String _mapToJson(Map<String, dynamic> map) {
    final entries =
        map.entries.map((e) => '"${e.key}": "${e.value}"').join(', ');
    return '{ $entries }';
  }

  String _encodeString(String str) {
    // Proper ABI encoding for dynamic strings
    final bytes = str.codeUnits;
    final length = bytes.length;

    // First, encode the offset to the string data (32 bytes from the start of the data)
    final offset =
        '0000000000000000000000000000000000000000000000000000000000000040';

    // Then encode the string length
    final lengthHex = length.toRadixString(16).padLeft(64, '0');

    // Then encode the string data (padded to 32-byte boundary)
    final dataHex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final paddedData = dataHex.padRight(64, '0');

    return offset + lengthHex + paddedData;
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

  // Function selectors
  static const String _createArtPieceSelector = '0x8f283970';
  static const String _getArtPieceSelector = '0x8da5cb5b';
  static const String _getArtPieceCountSelector = '0x8f283970';
  static const String _bidSelector = '0x454a2ab3';
  static const String _withdrawSelector = '0x3ccfd60b';
  static const String _finalizeSelector = '0x439766ce';
  static const String _claimOwnershipAndPaySelector = '0x8f283970';
  static const String _getOwnershipSelector = '0x8da5cb5b';
  static const String _getUserArtPiecesSelector = '0x8f283970';
  static const String _changeArtPresentationSelector = '0x8f283970';
  static const String _voteSelector = '0x0121b93f';
  static const String _endAuctionEarlySelector = '0x8f283970';
  static const String _payoutOnResaleSelector = '0x8f283970';

  Future<String> createArtPiece(String name,
      {int auctionDuration = 3600}) async {
    // Custom encoding for createArtPiece function
    final selector = _functionSelectors['createArtPiece']!;

    // Encode parameters manually for proper ABI encoding
    final nameBytes = name.codeUnits;
    final nameLength = nameBytes.length;

    // Offset to string data (32 bytes from start of data)
    final offset =
        '0000000000000000000000000000000000000000000000000000000000000040';

    // Auction duration (uint256)
    final durationHex = auctionDuration.toRadixString(16).padLeft(64, '0');

    // String length (uint256)
    final lengthHex = nameLength.toRadixString(16).padLeft(64, '0');

    // String data (padded to 32-byte boundary)
    final dataHex =
        nameBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final paddedData = dataHex.padRight(64, '0');

    final data = selector + offset + durationHex + lengthHex + paddedData;

    final tx = {
      'from': _connectedAddress,
      'to': _contractAddress,
      'data': data,
      'gas': '0x1e8480',
    };

    final hash = await _sendTransaction(tx);
    return hash;
  }

  Future<Map<String, dynamic>> getArtPiece(int artPieceId) async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data = _getArtPieceSelector + _encodeUint256(artPieceId);

    final result = await _callContract(data);
    if (result == null) return {};

    // Decode the result (name, description, exists, createdAt, totalTokens)
    final decoded = _decodeArtPiece(result);
    return {
      'name': decoded['name'],
      'description': decoded['description'],
      'exists': decoded['exists'],
      'createdAt': decoded['createdAt'],
      'totalTokens': decoded['totalTokens'],
    };
  }

  Future<int> getArtPieceCount() async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data = _getArtPieceCountSelector;

    final result = await _callContract(data);
    if (result == null) return 0;

    return _decodeUint256(result);
  }

  Future<String> bid(int artPieceId, String amount) async {
    return await callContract('bid', params: [artPieceId], value: amount);
  }

  Future<String> withdraw(int artPieceId) async {
    return await callContract('withdraw', params: [artPieceId]);
  }

  Future<String> confirmAuction(int artPieceId) async {
    return await callContract('confirmAuction', params: [artPieceId]);
  }

  Future<String> cancelAuction(int artPieceId) async {
    return await callContract('cancelAuction', params: [artPieceId]);
  }

  Future<String> endAuctionEarly(int artPieceId) async {
    return await callContract('endAuctionEarly', params: [artPieceId]);
  }

  Future<void> finalize(String artOwner) async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data = _finalizeSelector + _encodeAddress(artOwner);

    final tx = {
      'to': _contractAddress,
      'data': data,
      'gas': '300000',
    };

    final hash = await _sendTransaction(tx);
    print('Finalize transaction hash: $hash');
  }

  Future<void> claimOwnershipAndPay(int artPieceId, int amount) async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data = _claimOwnershipAndPaySelector + _encodeUint256(artPieceId);

    final tx = {
      'to': _contractAddress,
      'data': data,
      'value': '0x${amount.toRadixString(16)}',
      'gas': '200000',
    };

    final hash = await _sendTransaction(tx);
    print('Claim ownership transaction hash: $hash');
  }

  Future<Map<String, dynamic>> getOwnership(int artPieceId, String user) async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data = _getOwnershipSelector +
        _encodeUint256(artPieceId) +
        _encodeAddress(user);

    final result = await _callContract(data);
    if (result == null) return {'ownership': 0, 'percentage': 0};

    // Decode the result (ownership, percentage)
    final decoded = _decodeOwnership(result);
    return {
      'ownership': decoded['ownership'],
      'percentage': decoded['percentage'],
    };
  }

  Future<List<Map<String, dynamic>>> getUserArtPieces(String user) async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data = _getUserArtPiecesSelector + _encodeAddress(user);

    final result = await _callContract(data);
    if (result == null) return [];

    // Decode the result (artPieceIds[], ownerships[], percentages[])
    final decoded = _decodeUserArtPieces(result);
    final List<Map<String, dynamic>> artPieces = [];

    for (int i = 0; i < decoded['artPieceIds'].length; i++) {
      artPieces.add({
        'artPieceId': decoded['artPieceIds'][i],
        'ownership': decoded['ownerships'][i],
        'percentage': decoded['percentages'][i],
      });
    }

    return artPieces;
  }

  Future<List<Map<String, dynamic>>> getActiveAuctions() async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data = _functionSelectors['getActiveAuctions']!;
    print('[MetaMaskService] getActiveAuctions selector: $data');

    final result = await _callContract(data);
    print('[MetaMaskService] getActiveAuctions raw result: $result');

    if (result == null || result == '0x') {
      print('[MetaMaskService] No active auctions found');
      return [];
    }

    // Decode the result (artPieceIds[])
    final decoded = _decodeActiveAuctions(result);
    print(
        '[MetaMaskService] getActiveAuctions decoded IDs: ${decoded['artPieceIds']}');
    final List<Map<String, dynamic>> auctions = [];

    for (int i = 0; i < decoded['artPieceIds'].length; i++) {
      final artPieceId = decoded['artPieceIds'][i];

      // Get art piece details
      final artPieceData =
          _functionSelectors['getArtPiece']! + _encodeUint256(artPieceId);
      final artPieceResult = await _callContract(artPieceData);
      print('[MetaMaskService] getArtPiece($artPieceId) raw: $artPieceResult');

      if (artPieceResult != null) {
        final artPiece = _decodeArtPiece(artPieceResult);
        print('[MetaMaskService] getArtPiece($artPieceId) decoded: $artPiece');

        // Convert Wei to ETH for display
        final highestBidStr = artPiece['highestBid']?.toString() ?? '0';
        final highestBidWei = BigInt.parse(highestBidStr);
        final highestBidEth = highestBidWei / BigInt.from(10).pow(18);
        final remainder = highestBidWei % BigInt.from(10).pow(18);
        final highestBidEthDouble = highestBidEth.toDouble() +
            (remainder.toDouble() / BigInt.from(10).pow(18).toDouble());

        auctions.add({
          'id': artPieceId,
          'name': artPiece['name'],
          'collectiveBid': highestBidEthDouble.toStringAsFixed(4),
          'auctionEndTime': artPiece['auctionEndTime'] ?? 0,
        });
      }
    }

    print('[MetaMaskService] Returning ${auctions.length} auctions');
    return auctions;
  }

  Future<void> changeArtPresentation(String newPresentation) async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data =
        _changeArtPresentationSelector + _encodeString(newPresentation);

    final tx = {
      'to': _contractAddress,
      'data': data,
      'gas': '100000',
    };

    final hash = await _sendTransaction(tx);
    print('Change art presentation transaction hash: $hash');
  }

  Future<void> vote() async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data = _voteSelector;

    final tx = {
      'to': _contractAddress,
      'data': data,
      'gas': '100000',
    };

    final hash = await _sendTransaction(tx);
    print('Vote transaction hash: $hash');
  }

  Future<void> payoutOnResale(int amount) async {
    if (!isConnected) throw Exception('MetaMask not connected');

    final data = _payoutOnResaleSelector + _encodeUint256(amount);

    final tx = {
      'to': _contractAddress,
      'data': data,
      'gas': '200000',
    };

    final hash = await _sendTransaction(tx);
    print('Payout on resale transaction hash: $hash');
  }

  Map<String, dynamic> _decodeArtPiece(String result) {
    // Remove 0x prefix and decode the result
    final data = result.substring(2);
    // Solidity tuple: (string name, bool exists, uint256 createdAt, uint256 totalTokens, bool isAuctionActive, bool auctionFinalized, uint256 highestBid, address highestBidder, uint256 auctionEndTime)
    // string offset: 0-64, bool: 64-128, uint256: 128-192, ...
    // We'll decode only the most important fields for display
    if (data.length < 576) return {};
    // Name string offset (should be 0x20)
    final nameOffset = int.parse(data.substring(0, 64), radix: 16);
    // Exists (bool)
    final exists = int.parse(data.substring(64, 128), radix: 16) != 0;
    // createdAt
    final createdAt = int.parse(data.substring(128, 192), radix: 16);
    // totalTokens
    final totalTokens = int.parse(data.substring(192, 256), radix: 16);
    // isAuctionActive (bool)
    final isAuctionActive = int.parse(data.substring(256, 320), radix: 16) != 0;
    // auctionFinalized (bool)
    final auctionFinalized =
        int.parse(data.substring(320, 384), radix: 16) != 0;
    // highestBid
    final highestBid =
        BigInt.parse(data.substring(384, 448), radix: 16).toString();
    // highestBidder
    final highestBidder = '0x' + data.substring(410, 448);
    // auctionEndTime
    final auctionEndTime = int.parse(data.substring(448, 512), radix: 16);
    // Now decode the string (name)
    final nameLen = int.parse(data.substring(576, 640), radix: 16);
    final nameHex = data.substring(640, 640 + nameLen * 2);
    final name = String.fromCharCodes([
      for (int i = 0; i < nameHex.length; i += 2)
        int.parse(nameHex.substring(i, i + 2), radix: 16)
    ]);
    return {
      'name': name,
      'exists': exists,
      'createdAt': createdAt,
      'totalTokens': totalTokens,
      'isAuctionActive': isAuctionActive,
      'auctionFinalized': auctionFinalized,
      'highestBid': highestBid,
      'highestBidder': highestBidder,
      'auctionEndTime': auctionEndTime,
    };
  }

  Map<String, dynamic> _decodeOwnership(String result) {
    // Remove 0x prefix and decode the result
    final data = result.substring(2);

    // This is a simplified decoder
    return {
      'ownership': 0,
      'percentage': 0,
    };
  }

  Map<String, dynamic> _decodeUserArtPieces(String result) {
    // Remove 0x prefix and decode the result
    final data = result.substring(2);

    // This is a simplified decoder
    return {
      'artPieceIds': <int>[],
      'ownerships': <int>[],
      'percentages': <int>[],
    };
  }

  Map<String, dynamic> _decodeActiveAuctions(String result) {
    // Remove 0x prefix and decode the result
    final data = result.substring(2);
    print('[MetaMaskService] _decodeActiveAuctions data: $data');
    if (data.isEmpty) return {'artPieceIds': <int>[]};

    try {
      // Dynamic array of uint256: first 32 bytes is offset, next 32 is length, then values
      if (data.length < 128) {
        print('[MetaMaskService] Data too short for array decoding');
        return {'artPieceIds': <int>[]};
      }

      final length = int.parse(data.substring(64, 128), radix: 16);
      print('[MetaMaskService] Array length: $length');

      if (length == 0) {
        print('[MetaMaskService] Empty array');
        return {'artPieceIds': <int>[]};
      }

      final ids = <int>[];
      for (int i = 0; i < length; i++) {
        final start = 128 + i * 64;
        final end = start + 64;
        if (data.length < end) {
          print('[MetaMaskService] Data too short for element $i');
          break;
        }
        final hex = data.substring(start, end);
        final id = int.parse(hex, radix: 16);
        ids.add(id);
        print('[MetaMaskService] Decoded ID $i: $id');
      }
      print('[MetaMaskService] _decodeActiveAuctions ids: $ids');
      return {'artPieceIds': ids};
    } catch (e) {
      print('[MetaMaskService] Error decoding active auctions: $e');
      return {'artPieceIds': <int>[]};
    }
  }

  Map<String, dynamic> _decodeAuctionBidders(String result) {
    // Remove 0x prefix and decode the result
    final data = result.substring(2);
    print('[MetaMaskService] _decodeAuctionBidders data: $data');
    if (data.isEmpty) return {'bidders': [], 'amounts': []};

    try {
      // Check if this is an empty array result
      if (data.length < 128) {
        print('[MetaMaskService] Data too short, assuming empty array');
        return {'bidders': [], 'amounts': []};
      }

      // Dynamic array of tuples: (address bidder, uint256 amount)
      // First 32 bytes is offset, next 32 is length, then values
      final length = int.parse(data.substring(64, 128), radix: 16);
      print('[MetaMaskService] _decodeAuctionBidders length: $length');

      // If length is 0, return empty arrays
      if (length == 0) {
        print('[MetaMaskService] Array length is 0, returning empty arrays');
        return {'bidders': [], 'amounts': []};
      }

      final bidders = <String>[];
      final amounts = <String>[];

      for (int i = 0; i < length; i++) {
        final start = 128 + i * 128; // Each tuple is 128 bytes
        final end = start + 128;
        if (data.length < end) {
          print('[MetaMaskService] Data too short for element $i, stopping');
          break; // Safety check
        }
        final bidderHex = data.substring(start, start + 64);
        final amountHex = data.substring(start + 64, end);
        bidders.add('0x' + bidderHex);
        amounts.add('0x' + amountHex);
      }
      print('[MetaMaskService] _decodeAuctionBidders bidders: $bidders');
      print('[MetaMaskService] _decodeAuctionBidders amounts: $amounts');
      return {'bidders': bidders, 'amounts': amounts};
    } catch (e) {
      print('[MetaMaskService] _decodeAuctionBidders error: $e');
      return {'bidders': [], 'amounts': []};
    }
  }

  String _encodeUint256(int value) {
    return value.toRadixString(16).padLeft(64, '0');
  }

  String _encodeAddress(String address) {
    return address.substring(2).padLeft(64, '0');
  }

  int _decodeUint256(String hex) {
    return int.parse(hex, radix: 16);
  }

  Future<String?> _callContract(String data) async {
    try {
      // Ensure data has 0x prefix
      final dataWithPrefix = data.startsWith('0x') ? data : '0x$data';

      print('[MetaMaskService] Calling contract with data: $dataWithPrefix');

      final response = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'jsonrpc': '2.0',
          'method': 'eth_call',
          'params': [
            {
              'to': _contractAddress,
              'data': dataWithPrefix,
            },
            'latest'
          ],
          'id': 1,
        }),
      );

      final result = response.body;
      final jsonResult = json.decode(result);

      if (jsonResult['error'] != null) {
        print('Contract call error: ${jsonResult['error']}');
        return null;
      }

      print('[MetaMaskService] Contract call result: ${jsonResult['result']}');
      return jsonResult['result'] as String?;
    } catch (e) {
      print('Error calling contract: $e');
      return null;
    }
  }
}
