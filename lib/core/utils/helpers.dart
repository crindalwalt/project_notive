class DateHelper {
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${_getWeekday(date)} ${_formatTime(date)}';
    } else if (difference.inDays < 365) {
      return '${_getMonth(date)} ${date.day}';
    } else {
      return '${_getMonth(date)} ${date.day}, ${date.year}';
    }
  }

  static String formatDateLong(DateTime date) {
    return '${_getMonthLong(date)} ${date.day}, ${date.year} at ${_formatTime(date)}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String _getWeekday(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  static String _getMonth(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  static String _getMonthLong(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[date.month - 1];
  }
}

class TextHelper {
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String extractPlainText(String richText) {
    // Simple extraction for preview - in a real app you'd parse the Delta format
    return richText.replaceAll(RegExp(r'[{}":\[\],]'), ' ').trim();
  }
}

class DeviceHelper {
  static bool isMobile(double width) => width < 600;
  static bool isTablet(double width) => width >= 600 && width < 1024;
  static bool isDesktop(double width) => width >= 1024;
}
