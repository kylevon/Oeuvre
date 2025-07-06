import 'package:flutter/material.dart';
import 'metamask_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final MetaMaskService _metaMaskService = MetaMaskService();
  final TextEditingController _artNameController = TextEditingController();
  final TextEditingController _auctionDurationController =
      TextEditingController();
  String _connectionStatus = 'Not connected';
  String _address = '';
  bool _isConnected = false;
  bool _isAdmin = false;
  String _status = '';
  List<Map<String, dynamic>> _activeAuctions = [];
  List<Map<String, dynamic>> _acquiredArtPieces = [];
  bool _isLoading = false;

  // Replace with your actual admin address
  static const String adminAddress =
      '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

  @override
  void initState() {
    super.initState();
    _auctionDurationController.text = '3600'; // Default 1 hour
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isConnected && _isAdmin) {
      setState(() => _isLoading = true);
      try {
        await _loadActiveAuctions();
        await _loadAcquiredArtPieces();
      } catch (e) {
        setState(() => _status = 'Error loading data: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadActiveAuctions() async {
    try {
      print('Loading active auctions...');
      final auctions = await _metaMaskService.getActiveAuctions();
      print('Found ${auctions.length} active auctions: $auctions');
      setState(() {
        _activeAuctions = auctions;
      });
    } catch (e) {
      print('Error loading active auctions: $e');
      setState(() {
        _activeAuctions = [];
      });
    }
  }

  Future<void> _loadAcquiredArtPieces() async {
    try {
      // For now, we'll use a simplified approach
      // In a full implementation, you'd call getAcquiredArtPieces() method
      setState(() {
        _acquiredArtPieces = []; // Placeholder - implement proper decoding
      });
    } catch (e) {
      print('Error loading acquired art pieces: $e');
      setState(() {
        _acquiredArtPieces = [];
      });
    }
  }

  Future<void> _forceConnectMetaMask() async {
    setState(() => _connectionStatus = 'Connecting...');
    final success = await _metaMaskService.connect();
    if (success) {
      final addr = _metaMaskService.connectedAddress ?? '';
      setState(() {
        _connectionStatus = 'Connected';
        _address = addr;
        _isConnected = true;
        _isAdmin = addr.toLowerCase() == adminAddress.toLowerCase();
      });
      if (_isAdmin) {
        await _loadData();
      }
    } else {
      setState(() =>
          _connectionStatus = 'Connection failed - Please connect MetaMask');
    }
  }

  Future<void> _createArtPiece() async {
    if (!_isAdmin) return;
    final name = _artNameController.text.trim();
    final duration = int.tryParse(_auctionDurationController.text) ?? 3600;

    if (name.isEmpty) {
      setState(() => _status = 'Please enter an auction name.');
      return;
    }

    setState(() => _status = 'Creating auction...');
    try {
      await _metaMaskService.createArtPiece(name, auctionDuration: duration);
      setState(() => _status = 'Auction created successfully!');
      _artNameController.clear();
      await _loadData();
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _confirmAuction(int artPieceId) async {
    setState(() => _status = 'Confirming auction...');
    try {
      await _metaMaskService.confirmAuction(artPieceId);
      setState(() => _status = 'Auction confirmed successfully!');
      await _loadData();
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _cancelAuction(int artPieceId) async {
    setState(() => _status = 'Canceling auction...');
    try {
      await _metaMaskService.cancelAuction(artPieceId);
      setState(() => _status = 'Auction canceled successfully!');
      await _loadData();
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _endAuctionEarly(int artPieceId) async {
    setState(() => _status = 'Ending auction early...');
    try {
      await _metaMaskService.endAuctionEarly(artPieceId);
      setState(() => _status = 'Auction ended early!');
      await _loadData();
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
              if (_isConnected)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'ADMIN DASHBOARD',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
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
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'switch') {
                            _metaMaskService.switchAccount().then((success) {
                              if (success) {
                                final addr =
                                    _metaMaskService.connectedAddress ?? '';
                                setState(() {
                                  _address = addr;
                                  _isAdmin = addr.toLowerCase() ==
                                      adminAddress.toLowerCase();
                                });
                                if (_isAdmin) _loadData();
                              }
                            });
                          } else if (value == 'disconnect') {
                            _metaMaskService.disconnect();
                            setState(() {
                              _isConnected = false;
                              _isAdmin = false;
                              _address = '';
                              _activeAuctions = [];
                              _acquiredArtPieces = [];
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
                ),
              Expanded(
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
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Please connect MetaMask to access admin features.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : !_isAdmin
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline,
                                  color: Colors.white70, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'Access Denied',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'This address is not authorized as admin.',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status
                                if (_status.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.amber.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      _status,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                // Create Auction Section
                                _buildSection(
                                  'Create New Auction',
                                  Icons.add_circle,
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: _artNameController,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          decoration: const InputDecoration(
                                            labelText: 'Auction Name',
                                            labelStyle: TextStyle(
                                                color: Colors.white70),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white30),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller:
                                              _auctionDurationController,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Auction Duration (seconds)',
                                            labelStyle: TextStyle(
                                                color: Colors.white70),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white30),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _createArtPiece,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Create Auction'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Active Auctions Section
                                _buildSection(
                                  'Current Auctions',
                                  Icons.gavel,
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.white))
                                      : _activeAuctions.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No active auctions',
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            )
                                          : Column(
                                              children: _activeAuctions
                                                  .map((auction) =>
                                                      _buildAuctionCard(
                                                          auction))
                                                  .toList(),
                                            ),
                                ),
                                const SizedBox(height: 24),
                                // Acquired Art Pieces Section
                                _buildSection(
                                  'Acquired Art Pieces',
                                  Icons.art_track,
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.white))
                                      : _acquiredArtPieces.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No acquired art pieces',
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            )
                                          : Column(
                                              children: _acquiredArtPieces
                                                  .map((piece) =>
                                                      _buildArtPieceCard(piece))
                                                  .toList(),
                                            ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildAuctionCard(Map<String, dynamic> auction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            auction['name'] ?? 'Unknown Art Piece',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Collective Bid: ${auction['collectiveBid']} ETH',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmAuction(auction['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Win'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _cancelAuction(auction['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _endAuctionEarly(auction['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('End Early'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEther(dynamic wei) {
    if (wei == null) return '0';
    try {
      final weiBigInt = BigInt.parse(wei.toString());
      final eth = weiBigInt / BigInt.from(10).pow(18);
      final remainder = weiBigInt % BigInt.from(10).pow(18);
      final remainderStr = remainder.toString().padLeft(18, '0');
      final ethStr = eth.toString();
      final decimalStr = remainderStr.substring(0, 4);
      return '$ethStr.$decimalStr';
    } catch (e) {
      return '0';
    }
  }

  Widget _buildArtPieceCard(Map<String, dynamic> piece) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            piece['name'] ?? 'Unknown Art Piece',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Owner: ${piece['owner'] ?? 'Unknown'}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'Purchase Price: ${piece['price'] ?? '0'} ETH',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
