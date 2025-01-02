import 'package:flutter/material.dart';

class CategoryButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      // ignore: sort_child_properties_last
      child: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? Colors.green
              : const Color.fromARGB(255, 143, 143, 143), // Text color
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSelected
              ? Colors.green
              : const Color.fromARGB(255, 238, 238, 238), // Border color
          width: 1,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18), // Rounded corners
        ),
      ),
    );
  }
}
