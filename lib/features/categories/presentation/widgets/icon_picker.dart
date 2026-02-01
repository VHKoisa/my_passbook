import 'package:flutter/material.dart';

class IconPickerWidget extends StatelessWidget {
  final String selectedIcon;
  final Color selectedColor;
  final Function(String) onIconSelected;

  const IconPickerWidget({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
  });

  static const List<MapEntry<String, IconData>> availableIcons = [
    // Food & Drink
    MapEntry('restaurant', Icons.restaurant),
    MapEntry('local_cafe', Icons.local_cafe),
    MapEntry('local_bar', Icons.local_bar),
    MapEntry('local_grocery_store', Icons.local_grocery_store),
    MapEntry('fastfood', Icons.fastfood),
    MapEntry('cake', Icons.cake),

    // Transportation
    MapEntry('directions_car', Icons.directions_car),
    MapEntry('local_gas_station', Icons.local_gas_station),
    MapEntry('directions_bus', Icons.directions_bus),
    MapEntry('flight', Icons.flight),
    MapEntry('train', Icons.train),
    MapEntry('two_wheeler', Icons.two_wheeler),

    // Shopping
    MapEntry('shopping_bag', Icons.shopping_bag),
    MapEntry('shopping_cart', Icons.shopping_cart),
    MapEntry('store', Icons.store),
    MapEntry('checkroom', Icons.checkroom),
    MapEntry('diamond', Icons.diamond),
    MapEntry('watch', Icons.watch),

    // Home & Living
    MapEntry('home', Icons.home),
    MapEntry('electrical_services', Icons.electrical_services),
    MapEntry('water_drop', Icons.water_drop),
    MapEntry('local_laundry_service', Icons.local_laundry_service),
    MapEntry('cleaning_services', Icons.cleaning_services),
    MapEntry('chair', Icons.chair),

    // Health & Fitness
    MapEntry('local_hospital', Icons.local_hospital),
    MapEntry('medical_services', Icons.medical_services),
    MapEntry('local_pharmacy', Icons.local_pharmacy),
    MapEntry('fitness_center', Icons.fitness_center),
    MapEntry('spa', Icons.spa),
    MapEntry('psychology', Icons.psychology),

    // Entertainment
    MapEntry('movie', Icons.movie),
    MapEntry('sports_esports', Icons.sports_esports),
    MapEntry('music_note', Icons.music_note),
    MapEntry('theaters', Icons.theaters),
    MapEntry('sports_soccer', Icons.sports_soccer),
    MapEntry('casino', Icons.casino),

    // Education & Work
    MapEntry('school', Icons.school),
    MapEntry('work', Icons.work),
    MapEntry('laptop', Icons.laptop),
    MapEntry('book', Icons.book),
    MapEntry('science', Icons.science),
    MapEntry('business', Icons.business),

    // Finance
    MapEntry('attach_money', Icons.attach_money),
    MapEntry('account_balance', Icons.account_balance),
    MapEntry('savings', Icons.savings),
    MapEntry('payments', Icons.payments),
    MapEntry('credit_card', Icons.credit_card),
    MapEntry('trending_up', Icons.trending_up),

    // Bills & Utilities
    MapEntry('receipt_long', Icons.receipt_long),
    MapEntry('subscriptions', Icons.subscriptions),
    MapEntry('phone_android', Icons.phone_android),
    MapEntry('wifi', Icons.wifi),
    MapEntry('tv', Icons.tv),
    MapEntry('cloud', Icons.cloud),

    // Family & Personal
    MapEntry('child_care', Icons.child_care),
    MapEntry('pets', Icons.pets),
    MapEntry('family_restroom', Icons.family_restroom),
    MapEntry('card_giftcard', Icons.card_giftcard),
    MapEntry('celebration', Icons.celebration),
    MapEntry('favorite', Icons.favorite),

    // Other
    MapEntry('category', Icons.category),
    MapEntry('more_horiz', Icons.more_horiz),
    MapEntry('question_mark', Icons.question_mark),
    MapEntry('star', Icons.star),
    MapEntry('lightbulb', Icons.lightbulb),
    MapEntry('build', Icons.build),
  ];

  static IconData getIconData(String iconName) {
    final entry = availableIcons.firstWhere(
      (e) => e.key == iconName,
      orElse: () => const MapEntry('category', Icons.category),
    );
    return entry.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: availableIcons.length,
        itemBuilder: (context, index) {
          final icon = availableIcons[index];
          final isSelected = icon.key == selectedIcon;

          return GestureDetector(
            onTap: () => onIconSelected(icon.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? selectedColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                icon.value,
                color: isSelected
                    ? selectedColor
                    : Theme.of(context).textTheme.bodySmall?.color,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
