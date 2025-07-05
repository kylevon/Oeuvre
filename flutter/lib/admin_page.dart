import 'package:flutter/material.dart';
import 'metamask_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final MetaMaskService _metaMaskService = MetaMaskService();
  String _status = 'Not connected';
  String _address = '';
  bool _isAdmin = false;
  final TextEditingController _artNameController = TextEditingController();
  final TextEditingController _artDescriptionController =
      TextEditingController();
  bool _artPieceCreated = false;

  // Admin address from Hardhat
  static const String adminAddress =
      '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _artNameController.text = 'Mona Lisa';
    _artDescriptionController.text =
        'The famous portrait by Leonardo da Vinci, one of the most valuable paintings in the world.';
  }

  Future<void> _checkConnection() async {
    if (_metaMaskService.isConnected) {
      setState(() {
        _status = 'Connected';
        _address = _metaMaskService.connectedAddress ?? '';
        _isAdmin = _address.toLowerCase() == adminAddress.toLowerCase();
      });
    }
  }

  Future<void> _connectMetaMask() async {
    setState(() => _status = 'Connecting...');

    final success = await _metaMaskService.connect();
    if (success) {
      setState(() {
        _status = 'Connected';
        _address = _metaMaskService.connectedAddress ?? '';
        _isAdmin = _address.toLowerCase() == adminAddress.toLowerCase();
      });
    } else {
      setState(() => _status = 'Connection failed');
    }
  }

  Future<void> _createArtPiece() async {
    if (_artNameController.text.isEmpty ||
        _artDescriptionController.text.isEmpty) {
      setState(() => _status = 'Please fill in all fields');
      return;
    }

    setState(() => _status = 'Creating art piece...');
    try {
      await _metaMaskService.callContract('createArtPiece',
          params: [_artNameController.text, _artDescriptionController.text]);
      setState(() => _status = 'Art piece created successfully!');
      setState(() => _artPieceCreated = true);
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _getArtPiece() async {
    setState(() => _status = 'Fetching art piece...');
    try {
      final result = await _metaMaskService.getContractData('getArtPiece');
      setState(() => _status = 'Art piece data: $result');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _startAuction() async {
    setState(() => _status = 'Starting auction...');
    try {
      await _metaMaskService.callContract('endAuctionEarly');
      setState(() => _status = 'Auction started!');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _finalizeAuction() async {
    setState(() => _status = 'Finalizing auction...');
    try {
      await _metaMaskService.callContract('finalize',
          params: ['0x90f79bf6eb2c4f870365e785982e1f101e93b906']);
      setState(() => _status = 'Auction finalized!');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _updatePresentation() async {
    setState(() => _status = 'Updating presentation...');
    try {
      await _metaMaskService.callContract('changeArtPresentation',
          params: ['Private Collection - Exclusive Display']);
      setState(() => _status =
          'Presentation updated to: Private Collection - Exclusive Display');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Creator - Admin Panel'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.orange[50],
      body: Center(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.admin_panel_settings,
                    size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('Create Art Piece',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _artNameController,
                  decoration: const InputDecoration(
                    labelText: 'Art Piece Name',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _artDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: false,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _metaMaskService.isConnected && !_artPieceCreated
                        ? _createArtPiece
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('Create Mona Lisa Auction',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                ),
                if (_artPieceCreated)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Card(
                      color: Colors.orange[100],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.image, size: 48, color: Colors.orange),
                            SizedBox(height: 8),
                            Text('Mona Lisa',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                                'The famous portrait by Leonardo da Vinci, one of the most valuable paintings in the world.',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 12),
                            Text(
                                'Auction created! Bidders can now see and bid on this art piece.',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_status.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_status,
                        style: const TextStyle(color: Colors.green)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
