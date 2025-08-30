import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/folder_provider.dart';
import '../../widgets/common/state_widgets.dart' as custom_widgets;
import 'note_list_item.dart';

class NotesList extends StatelessWidget {
  const NotesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NoteProvider, FolderProvider>(
      builder: (context, noteProvider, folderProvider, child) {
        if (noteProvider.isLoading) {
          return const custom_widgets.LoadingWidget(
            message: 'Loading notes...',
          );
        }

        if (noteProvider.error != null) {
          return custom_widgets.ErrorWidget(
            message: noteProvider.error!,
            onRetry: () => noteProvider.loadNotes(),
          );
        }

        final notes = noteProvider.notes;

        if (notes.isEmpty) {
          return custom_widgets.EmptyWidget(
            title: 'No notes yet',
            subtitle: 'Create your first note to get started',
            icon: Icons.note_add,
            action: ElevatedButton.icon(
              onPressed: () => _createNewNote(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Note'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isSelected = noteProvider.selectedNote?.id == note.id;

            return NoteListItem(
              note: note,
              isSelected: isSelected,
              onTap: () => noteProvider.selectNote(note),
              onPin: () => noteProvider.togglePinNote(note.id),
              onDelete: () => _showDeleteDialog(context, note.id, note.title),
            );
          },
        );
      },
    );
  }

  void _createNewNote(BuildContext context) {
    final folderProvider = context.read<FolderProvider>();
    final noteProvider = context.read<NoteProvider>();

    if (folderProvider.selectedFolder != null) {
      noteProvider.createNote(
        title: 'New Note',
        content: '',
        folderId: folderProvider.selectedFolder!.id,
      );
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    String noteId,
    String noteTitle,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "$noteTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<NoteProvider>().deleteNote(noteId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
