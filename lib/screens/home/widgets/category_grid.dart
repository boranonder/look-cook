import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/recipe_category.dart';
import '../../category/category_recipes_screen.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: RecipeCategory.values.length,
      itemBuilder: (context, index) {
        final category = RecipeCategory.values[index];
        return _CategoryItem(
          category: category,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CategoryRecipesScreen(category: category),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final RecipeCategory category;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CategoryColors.categoryGradients[category] ?? [0xFFE53E3E, 0xFFC53030];
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Color(colors[0]),
              Color(colors[1]),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(colors[0]).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}