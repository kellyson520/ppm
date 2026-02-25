import 'package:flutter/material.dart';
import '../../services/vault_service.dart';
import '../../core/models/models.dart';
import '../widgets/password_card_item.dart';
import 'add_password_screen.dart';
import 'password_detail_screen.dart';
import 'settings_screen.dart';

class VaultScreen extends StatefulWidget {
  final VaultService vaultService;
  final VoidCallback onLockRequested;

  const VaultScreen({
    super.key,
    required this.vaultService,
    required this.onLockRequested,
  });

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchController = TextEditingController();
  List<PasswordCard> _cards = [];
  List<PasswordCard> _filteredCards = [];
  bool _isLoading = true;
  VaultStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cards = await widget.vaultService.getAllCards();
      final stats = await widget.vaultService.getStats();
      
      setState(() {
        _cards = cards;
        _filteredCards = cards;
        _stats = stats;
        _isLoading = false;
      });
    } on Exception {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load vault data');
    }
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCards = _cards;
      } else {
        // Filter locally for now
        // In production, use blind index search
        _filteredCards = _cards.where((card) {
          return card.cardId.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _navigateToAddPassword() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddPasswordScreen(
          vaultService: widget.vaultService,
        ),
      ),
    );

    if (result == true) {
      _loadData();
      _showSuccess('Password saved successfully');
    }
  }

  Future<void> _navigateToPasswordDetail(PasswordCard card) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PasswordDetailScreen(
          vaultService: widget.vaultService,
          card: card,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          vaultService: widget.vaultService,
          onLockRequested: widget.onLockRequested,
        ),
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vault'),
        leading: IconButton(
          icon: const Icon(Icons.lock_outline),
          onPressed: widget.onLockRequested,
          tooltip: 'Lock Vault',
        ),
        actions: [
          if (_stats != null && _stats!.pendingSyncCount > 0)
            Badge(
              label: Text('${_stats!.pendingSyncCount}'),
              child: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () {
                  // TODO: Trigger sync
                  _showSuccess('Sync started');
                },
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                _showSuccess('Already up to date');
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search passwords...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Stats bar
          if (_stats != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatChip(
                    Icons.password,
                    '${_stats!.cardCount}',
                    'Passwords',
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.history,
                    '${_stats!.eventCount}',
                    'Events',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Password list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCards.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCards.length,
                          itemBuilder: (context, index) {
                            final card = _filteredCards[index];
                            return PasswordCardItem(
                              card: card,
                              onTap: () => _navigateToPasswordDetail(card),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPassword,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No passwords yet'
                : 'No matches found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isEmpty)
            Text(
              'Tap the + button to add your first password',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
        ],
      ),
    );
  }
}
