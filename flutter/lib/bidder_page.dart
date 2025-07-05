import 'package:flutter/material.dart';
import 'metamask_service.dart';

class BidderPage extends StatefulWidget {
  const BidderPage({super.key});

  @override
  State<BidderPage> createState() => _BidderPageState();
}

class _BidderPageState extends State<BidderPage> {
  final MetaMaskService _metaMaskService = MetaMaskService();
  String? artName;
  String? artDescription;
  bool artExists = false;
  String _status = '';
  String _connectionStatus = 'Not connected';
  String _address = '';
  String _tokenBalance = '0';
  String _ownershipPercentage = '0%';
  final TextEditingController _bidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchArtPiece();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    if (_metaMaskService.isConnected) {
      setState(() {
        _connectionStatus = 'Connected';
        _address = _metaMaskService.connectedAddress ?? '';
      });
      await _fetchTokenBalance();
    }
  }

  Future<void> _connectMetaMask() async {
    setState(() => _connectionStatus = 'Connecting...');

    final success = await _metaMaskService.connect();
    if (success) {
      setState(() {
        _connectionStatus = 'Connected';
        _address = _metaMaskService.connectedAddress ?? '';
      });
      await _fetchTokenBalance();
    } else {
      setState(() => _connectionStatus = 'Connection failed');
    }
  }

  Future<void> _fetchTokenBalance() async {
    if (!_metaMaskService.isConnected) return;

    try {
      final result = await _metaMaskService.getContractData('tokens',
          params: [_metaMaskService.connectedAddress]);

      // Parse the result to get token balance
      if (result != null && result.toString().contains('"result"')) {
        // Extract the hex value and convert to decimal
        final hexValue = result.toString().split('"result":"')[1].split('"')[0];
        if (hexValue != '0x') {
          final tokenBalance = BigInt.parse(hexValue, radix: 16);
          final percentage =
              (tokenBalance * BigInt.from(100)) / BigInt.from(1e18);

          setState(() {
            _tokenBalance = tokenBalance.toString();
            _ownershipPercentage = '${percentage.toString()}%';
          });
        }
      }
    } catch (e) {
      setState(() {
        _tokenBalance = '0';
        _ownershipPercentage = '0%';
      });
    }
  }

  Future<void> _fetchArtPiece() async {
    try {
      final result = await _metaMaskService.getContractData('getArtPiece');
      if (result != null && result.toString().contains('Mona Lisa')) {
        setState(() {
          artName = 'Mona Lisa';
          artDescription =
              'The famous portrait by Leonardo da Vinci, one of the most valuable paintings in the world.';
          artExists = true;
        });
      } else {
        setState(() {
          artExists = false;
        });
      }
    } catch (e) {
      setState(() {
        artExists = false;
      });
    }
  }

  Future<void> _placeBid() async {
    if (!_metaMaskService.isConnected) {
      setState(() => _status = 'Please connect MetaMask first');
      return;
    }

    if (_bidController.text.isEmpty) {
      setState(() => _status = 'Please enter a bid amount');
      return;
    }
    setState(() => _status = 'Placing bid...');
    try {
      final amount = double.parse(_bidController.text);
      final weiAmount = (amount * 1e18).toInt().toRadixString(16);
      await _metaMaskService
          .callContract('bidWithTracking', params: ['0x$weiAmount']);
      setState(() => _status = 'Bid placed successfully!');
      _bidController.clear();
      // Refresh token balance after successful bid
      await _fetchTokenBalance();
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple[900]!,
              Colors.deepPurple[700]!,
              Colors.purple[600]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'BIDDER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    if (!_metaMaskService.isConnected)
                      ElevatedButton(
                        onPressed: _connectMetaMask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Connect MetaMask'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.5)),
                        ),
                        child: Text(
                          '${_address.substring(0, 6)}...${_address.substring(_address.length - 4)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Icon(Icons.gavel, color: Colors.amber[300], size: 32),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Center(
                  child: artExists
                      ? Container(
                          margin: const EdgeInsets.all(24),
                          child: Card(
                            elevation: 20,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey[50]!,
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Art Piece Display
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.deepPurple[200]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: 64,
                                            color: Colors.deepPurple[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            artName ?? '',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            artDescription ?? '',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 24),

                                          // Token Balance and Ownership
                                          if (_metaMaskService.isConnected)
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.amber[50],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.amber[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      const Text(
                                                        'Your Tokens:',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                      Text(
                                                        _tokenBalance,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      const Text(
                                                        'Ownership:',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                      Text(
                                                        _ownershipPercentage,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // Bidding Interface
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.amber[200]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Place Your Bid',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: _bidController,
                                            decoration: InputDecoration(
                                              labelText: 'Bid Amount (ETH)',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              prefixIcon: Icon(
                                                  Icons.currency_bitcoin,
                                                  color: Colors.amber[600]),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: _placeBid,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.amber[600],
                                                foregroundColor: Colors.white,
                                                elevation: 8,
                                                shadowColor: Colors.amber[600]!
                                                    .withOpacity(0.5),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text(
                                                'PLACE BID',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (_status.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.green[200]!),
                                        ),
                                        child: Text(
                                          _status,
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.all(24),
                          child: Card(
                            elevation: 20,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey[50]!,
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(48),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'No Art Piece Available',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Please wait for the auction creator to add an art piece.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
