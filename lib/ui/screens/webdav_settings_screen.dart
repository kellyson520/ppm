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
      backgroundColor: const Color(0xFF101018),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.webdavNodes,
            style: const TextStyle(fontWeight: FontWeight.w700)),
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
                  Icon(Icons.cloud_off_rounded,
                      size: 80, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 24),
                  Text(l10n.noWebDavNodes,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showAddNodeBottomSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addNode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: state.nodes.length,
            itemBuilder: (context, index) {
              final node = state.nodes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dns_rounded,
                        color: Color(0xFF6C63FF), size: 24),
                  ),
                  title: Text(node.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  subtitle: Text(
                    node.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.withValues(alpha: 0.6)),
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
        onPressed: () => _showAddNodeBottomSheet(context),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddNodeBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF161622),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.addWebDavNode,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                  nameController, l10n.nodeName, Icons.label_outline_rounded,
                  next: true),
              const SizedBox(height: 16),
              _buildTextField(urlController, l10n.urlHint, Icons.link_rounded,
                  next: true, type: TextInputType.url),
              const SizedBox(height: 16),
              _buildTextField(
                  userController, l10n.username, Icons.person_outline_rounded,
                  next: true),
              const SizedBox(height: 16),
              _buildTextField(
                  passController, l10n.password, Icons.lock_outline_rounded,
                  obscure: true),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty ||
                      urlController.text.isEmpty) {
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
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(l10n.add,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool next = false,
    bool obscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      textInputAction: next ? TextInputAction.next : TextInputAction.done,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon,
            size: 20, color: const Color(0xFF6C63FF).withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1),
        ),
      ),
    );
  }
}
