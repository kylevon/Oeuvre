import 'package:flutter/material.dart';
import 'metamask_service.dart';

class BidderPage extends StatefulWidget {
  const BidderPage({super.key});

  @override
  State<BidderPage> createState() => _BidderPageState();
}

class _BidderPageState extends State<BidderPage> {
  final MetaMaskService _metaMaskService = MetaMaskService();
  String _status = '';
  String _connectionStatus = 'Not connected';
  String _address = '';
  bool _isConnected = false;
  final TextEditingController _bidController = TextEditingController();

  List<Map<String, dynamic>> _ownedArtPieces = [];
  List<Map<String, dynamic>> _activeAuctions = [];

  @override
  void initState() {
    super.initState();
    // Don't auto-connect, wait for user to click the button
  }

  Future<void> _forceConnectMetaMask() async {
    setState(() => _connectionStatus = 'Connecting...');

    final success = await _metaMaskService.connect();
    if (success) {
      setState(() {
        _connectionStatus = 'Connected';
        _address = _metaMaskService.connectedAddress ?? '';
        _isConnected = true;
      });
      await _fetchOwnedArtPieces();
      await _fetchActiveAuctions();
    } else {
      setState(() =>
          _connectionStatus = 'Connection failed - Please connect MetaMask');
    }
  }

  Future<void> _fetchOwnedArtPieces() async {
    if (!_metaMaskService.isConnected) return;
    try {
      final pieces = await _metaMaskService
          .getUserArtPieces(_metaMaskService.connectedAddress!);
      setState(() {
        _ownedArtPieces = pieces;
      });
    } catch (e) {
      setState(() {
        _ownedArtPieces = [];
      });
    }
  }

  Future<void> _fetchActiveAuctions() async {
    if (!_metaMaskService.isConnected) return;
    try {
      print('[BidderPage] Fetching active auctions...');
      final auctions = await _metaMaskService.getActiveAuctions();
      print('[BidderPage] Found ${auctions.length} active auctions: $auctions');
      setState(() {
        _activeAuctions = auctions;
      });
    } catch (e) {
      print('[BidderPage] Error fetching active auctions: $e');
      setState(() {
        _activeAuctions = [];
      });
    }
  }

  Future<void> _showBidDialog(Map<String, dynamic> auction) async {
    final TextEditingController bidAmountController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Place Bid on ${auction['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current highest bid: ${auction['collectiveBid']} ETH'),
              const SizedBox(height: 16),
              TextField(
                controller: bidAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your bid amount (ETH)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _placeBid(auction['id'], bidAmountController.text);
              },
              child: const Text('Place Bid'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _placeBid(int artPieceId, String amountText) async {
    if (!_metaMaskService.isConnected) {
      setState(() => _status = 'Please connect MetaMask first');
      return;
    }

    if (amountText.isEmpty) {
      setState(() => _status = 'Please enter a bid amount');
      return;
    }

    try {
      final amount = double.parse(amountText);
      if (amount <= 0) {
        setState(() => _status = 'Bid amount must be greater than 0');
        return;
      }

      setState(() => _status = 'Placing bid...');

      // Convert ETH to Wei
      final weiAmount = (amount * 1e18).toInt();
      final weiHex = '0x${weiAmount.toRadixString(16)}';

      print(
          '[BidderPage] Placing bid: $amount ETH ($weiHex wei) on art piece $artPieceId');

      await _metaMaskService.bid(artPieceId, weiHex);

      setState(() => _status = 'Bid placed successfully!');

      // Refresh the auctions to show updated bid
      await _fetchActiveAuctions();
    } catch (e) {
      print('[BidderPage] Error placing bid: $e');
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
                        onPressed: _forceConnectMetaMask,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.5)),
                            ),
                            child: Text(
                              '${_address.substring(0, 6)}...${_address.substring(_address.length - 4)}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (value) {
                              if (value == 'switch') {
                                _metaMaskService
                                    .switchAccount()
                                    .then((success) {
                                  if (success) {
                                    final addr =
                                        _metaMaskService.connectedAddress ?? '';
                                    setState(() {
                                      _address = addr;
                                      _isConnected = true;
                                    });
                                    _fetchOwnedArtPieces();
                                    _fetchActiveAuctions();
                                  }
                                });
                              } else if (value == 'disconnect') {
                                _metaMaskService.disconnect();
                                setState(() {
                                  _isConnected = false;
                                  _address = '';
                                  _ownedArtPieces = [];
                                  _activeAuctions = [];
                                });
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'switch',
                                child: Row(
                                  children: [
                                    Icon(Icons.swap_horiz, size: 20),
                                    SizedBox(width: 8),
                                    Text('Switch Account'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'disconnect',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, size: 20),
                                    SizedBox(width: 8),
                                    Text('Disconnect'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(width: 12),
                    Icon(Icons.gavel, color: Colors.amber[300], size: 32),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: !_isConnected
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: _forceConnectMetaMask,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Connect MetaMask',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Please connect MetaMask to view and participate in auctions.',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    // Your Art Pieces Section
                                    Card(
                                      elevation: 20,
                                      shadowColor:
                                          Colors.black.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(24),
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
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.art_track,
                                                      color: Colors.amber[600],
                                                      size: 32),
                                                  const SizedBox(width: 16),
                                                  const Text(
                                                    'Your Art Collection',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.deepPurple,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                              if (_ownedArtPieces.isEmpty)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                        color:
                                                            Colors.grey[300]!),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        Icons.art_track,
                                                        size: 48,
                                                        color: Colors.grey[400],
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      const Text(
                                                        'No Art Pieces Owned Yet',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Participate in auctions to own art pieces!',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                Column(
                                                  children: _ownedArtPieces
                                                      .map((artPiece) {
                                                    return Card(
                                                      margin: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 12),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(20),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              artPiece[
                                                                      'name'] ??
                                                                  'Art Piece',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .deepPurple,
                                                              ),
                                                            ),
                                                            if (artPiece[
                                                                    'description'] !=
                                                                null)
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top:
                                                                            8.0),
                                                                child: Text(
                                                                  artPiece[
                                                                      'description'],
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      color: Colors
                                                                          .black87),
                                                                ),
                                                              ),
                                                            const SizedBox(
                                                                height: 12),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                    'Total Tokens: ${artPiece['ownership']}',
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w600,
                                                                        color: Colors
                                                                            .amber)),
                                                                Text(
                                                                    'Ownership: ${artPiece['percentage']}%',
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w600,
                                                                        color: Colors
                                                                            .amber)),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Active Auctions Section
                                    Card(
                                      elevation: 20,
                                      shadowColor:
                                          Colors.black.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(24),
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
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.groups,
                                                      color: Colors.blue,
                                                      size: 32),
                                                  const SizedBox(width: 16),
                                                  const Text(
                                                    'Collective Auctions',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.deepPurple,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                'Join collective bids to compete with wealthy art collectors!',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                              if (_activeAuctions.isEmpty)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                        color:
                                                            Colors.grey[300]!),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        Icons.hourglass_empty,
                                                        size: 48,
                                                        color: Colors.grey[400],
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      const Text(
                                                        'No Active Collective Auctions',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Check back later for new collective auctions!',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                Column(
                                                  children: _activeAuctions
                                                      .map((auction) {
                                                    return Card(
                                                      margin: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 8),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(20),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    auction['name'] ??
                                                                        'Art Piece',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .deepPurple,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          6),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .green
                                                                        .withOpacity(
                                                                            0.2),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12),
                                                                    border: Border.all(
                                                                        color: Colors
                                                                            .green),
                                                                  ),
                                                                  child:
                                                                      const Text(
                                                                    'ACTIVE',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .green,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 16),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      'Current Bid',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .grey[600],
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      '${auction['collectiveBid']} ETH',
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: Colors
                                                                            .amber,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 16),
                                                            ElevatedButton(
                                                              onPressed: () =>
                                                                  _showBidDialog(
                                                                      auction),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .deepPurple,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                  'Place Bid'),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    // Status bar
                    if (_status.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: _status.contains('Error')
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _status.contains('Error')
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
