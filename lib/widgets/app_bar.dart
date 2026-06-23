import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    /// provider call
    final homeProvider = Provider.of<HomeProvider>(context);
    final TextEditingController searchController = TextEditingController();

    /// dark light theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    /// user pop up
    if (homeProvider.selectedCategory.isNotEmpty) {
      searchController.text = homeProvider.selectedCategory;
      searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: searchController.text.length),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: textColor, fontSize: 14),
              textInputAction: TextInputAction.search,

              /// keyboard search icon
              decoration: InputDecoration(
                hintText: 'Find Hospitals, Police, Schools...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.purpleAccent,
                  size: 20,
                ),

                /// magic clear button
                suffixIcon: homeProvider.selectedCategory.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () {
                          searchController.clear();

                          /// clear button
                          homeProvider.filterByCategory('');
                        },
                      )
                    : null,

                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.purpleAccent,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (value) {
                final query = value.trim();
                if (query.isNotEmpty) {
                  /// custom search method
                  homeProvider.searchCustomQuery(query);
                } else {
                  /// clear search field
                  homeProvider.filterByCategory('');
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.purpleAccent.withOpacity(0.15),
          child: const Icon(
            Icons.location_on,
            color: Colors.purpleAccent,
            size: 20,
          ),
        ),
      ],
    );
  }
}
