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
        title: Text(l10n.addWebDavNode),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.nodeName),
              ),
              TextField(
                controller: urlController,
                decoration: InputDecoration(labelText: l10n.urlHint),
              ),
              TextField(
                controller: userController,
                decoration: InputDecoration(labelText: l10n.username),
              ),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.password),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final node = WebDavNode(
                name: nameController.text,
                url: urlController.text,
                username: userController.text,
                password: passController.text,
              );
              context.read<SyncBloc>().add(SyncNodeAdded(node));
              Navigator.pop(context);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}
