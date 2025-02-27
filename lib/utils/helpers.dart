import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  // Format a date string
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'Unknown';
    }
    
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMMd().format(date);
    } catch (e) {
      return dateStr;
    }
  }
  
  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
  
  // Show a custom snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Check if the device is in dark mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  // Get screen dimensions
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
} 