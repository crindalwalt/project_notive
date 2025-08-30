import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/folder_provider.dart';
import '../../providers/theme_provider.dart';

class CreateFolderDialog extends StatefulWidget {
  final String? folderId;
  final String? initialName;
  final String? initialEmoji;
  final Color? initialColor;

  const CreateFolderDialog({
    super.key,
    this.folderId,
    this.initialName,
    this.initialEmoji,
    this.initialColor,
  });

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  String _selectedEmoji = '📁';
  Color _selectedColor = const Color(0xFF007ACC);
  
  final List<String> _popularEmojis = [
    '📁', '📂', '🗂️', '📋', '📊', '📈', '📉', '📝', '✍️', '📄',
    '📑', '📚', '📖', '📕', '📗', '📘', '📙', '🔖', '🏷️', '📎',
    '🔗', '📌', '📍', '🎯', '💡', '⭐', '🔥', '❤️', '💼', '🏠',
    '⚡', '🌟', '🚀', '🎨', '🎭', '🎪', '🎵', '🎤', '🎧', '📺',
    '💻', '⌨️', '🖥️', '📱', '⌚', '🔧', '⚙️', '🛠️', '🔨', '⚔️'
  ];
  
  final List<Color> _popularColors = [
    const Color(0xFF007ACC), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF84CC16), // Lime
    const Color(0xFFF97316), // Orange
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF43F5E), // Rose
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedEmoji = widget.initialEmoji ?? '📁';
    _selectedColor = widget.initialColor ?? const Color(0xFF007ACC);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final isEditing = widget.folderId != null;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF252526) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _selectedEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEditing ? 'Edit Folder' : 'Create New Folder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(isDark),
              const SizedBox(height: 24),
              _buildEmojiSelector(isDark),
              const SizedBox(height: 24),
              _buildColorSelector(isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _createOrUpdateFolder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Folder Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          autofocus: true,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF374151),
          ),
          decoration: InputDecoration(
            hintText: 'Enter folder name...',
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _selectedColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Icon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: _popularEmojis.length,
            itemBuilder: (context, index) {
              final emoji = _popularEmojis[index];
              final isSelected = emoji == _selectedEmoji;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEmoji = emoji;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedColor.withOpacity(0.2) : null,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected 
                        ? Border.all(color: _selectedColor, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Color',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularColors.map((color) {
            final isSelected = color.value == _selectedColor.value;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected 
                      ? Border.all(
                          color: isDark ? Colors.white : Colors.black,
                          width: 3,
                        )
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _createOrUpdateFolder() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final folderProvider = context.read<FolderProvider>();
    
    if (widget.folderId != null) {
      // Update existing folder
      folderProvider.updateFolder(
        widget.folderId!,
        name: name,
        emoji: _selectedEmoji,
        color: _selectedColor,
      );
    } else {
      // Create new folder
      folderProvider.createFolderWithStyle(
        name,
        emoji: _selectedEmoji,
        color: _selectedColor,
      );
    }
    
    Navigator.pop(context);
  }
}
