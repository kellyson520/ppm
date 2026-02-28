import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/sync/sync_bloc.dart';
import '../../l10n/app_localizations.dart';

class WebDavSettingsScreen extends StatelessWidget {
  const WebDavSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.webdavNodes),
      ),
      body: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) {
          if (state.isLoading && state.nodes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.nodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noWebDavNodes),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddNodeDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addNode),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.nodes.length,
            itemBuilder: (context, index) {
              final node = state.nodes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.storage, color: Color(0xFF6C63FF)),
                  title: Text(node.name),
                  subtitle: Text(node.url),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => context
                        .read<SyncBloc>()
                        .add(SyncNodeRemoved(node.name)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNodeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddNodeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF2D2D44), width: 1),
        ),
        title: Text(
          l10n.addWebDavNode,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.nodeName),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: InputDecoration(labelText: l10n.urlHint),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: userController,
                decoration: InputDecoration(labelText: l10n.username),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.password),
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || urlController.text.isEmpty) {
                return;
              }
              final node = WebDavNode(
                name: nameController.text.trim(),
                url: urlController.text.trim(),
                username: userController.text.trim(),
                password: passController.text,
              );
              context.read<SyncBloc>().add(SyncNodeAdded(node));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}
