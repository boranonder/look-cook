import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../models/recipe_category.dart';
import '../../services/recipe_service.dart';
import '../../services/storage_service.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _instructionController = TextEditingController();

  final List<String> _ingredients = [];
  final List<String> _instructions = [];

  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  RecipeCategory _selectedCategory = RecipeCategory.evYemekleri;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          if (_selectedImages.length < 10) {
            _selectedImages.add(image);
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _addIngredient() {
    if (_ingredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text.trim());
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addInstruction() {
    if (_instructionController.text.trim().isNotEmpty) {
      setState(() {
        _instructions.add(_instructionController.text.trim());
        _instructionController.clear();
      });
    }
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
    });
  }

  Future<void> _publishRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir malzeme eklemelisiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir yapılış adımı eklemelisiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarif eklemek için giriş yapmalısınız'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user profile for name
      final userProfile = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();

      final userName = userProfile?['name'] ?? user.email?.split('@')[0] ?? 'Kullanıcı';

      // Upload images if selected
      List<String> imageUrls = [];
      String? imageUrl;
      if (_selectedImages.isNotEmpty) {
        final storageService = StorageService();
        imageUrls = await storageService.uploadRecipeImagesFromXFiles(_selectedImages, user.id);
        imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
      }

      final recipe = Recipe(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        ingredients: List<String>.from(_ingredients),
        instructions: List<String>.from(_instructions),
        authorId: user.id,
        authorName: userName,
        createdAt: DateTime.now(),
        category: _selectedCategory,
        imageUrl: imageUrl,
        imageUrls: imageUrls,
      );

      final recipeService = RecipeService();
      await recipeService.addRecipe(recipe);

      // Clear form
      _nameController.clear();
      _descriptionController.clear();
      _ingredients.clear();
      _instructions.clear();
      setState(() {
        _selectedImages.clear();
        _selectedCategory = RecipeCategory.evYemekleri;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarif başarıyla yayınlandı!'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarif eklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addRecipe),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _publishRecipe,
              child: Text(
                l10n.publish,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Images Section
              SizedBox(
                height: 200,
                child: _selectedImages.isEmpty
                    ? GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.dividerGray,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryRed.withOpacity(0.3),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${l10n.addPhoto} (Birden fazla seçebilirsiniz)',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _selectedImages.length) {
                                  // Add more button
                                  if (_selectedImages.length < 10) {
                                    return GestureDetector(
                                      onTap: _pickImages,
                                      child: Container(
                                        width: 150,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.dividerGray,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: AppTheme.primaryRed.withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, size: 32, color: Colors.grey[600]),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Ekle',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }
                                return Stack(
                                  children: [
                                    Container(
                                      width: 150,
                                      margin: const EdgeInsets.only(right: 8),
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: kIsWeb
                                          ? Image.network(
                                              _selectedImages[index].path,
                                              fit: BoxFit.cover,
                                              height: double.infinity,
                                            )
                                          : Image.file(
                                              File(_selectedImages[index].path),
                                              fit: BoxFit.cover,
                                              height: double.infinity,
                                            ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryRed,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Kapak',
                                            style: TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              if (_selectedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${_selectedImages.length}/10 görsel seçildi',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Category Selection
              DropdownButtonFormField<RecipeCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                ),
                items: RecipeCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(category.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Recipe Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.recipeName,
                  hintText: 'Örn: Köfte, Baklava, Pilav...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tarif adı gerekli';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Recipe Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Kısa Açıklama',
                  hintText: 'Tarif hakkında kısa bir açıklama...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Açıklama gerekli';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Ingredients Section
              _SectionTitle(
                title: l10n.ingredients,
                icon: Icons.shopping_cart,
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ingredientController,
                      decoration: const InputDecoration(
                        hintText: 'Malzeme ekle...',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _addIngredient(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addIngredient,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              if (_ingredients.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dividerGray),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ingredients.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryRed,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(_ingredients[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeIngredient(index),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Instructions Section
              _SectionTitle(
                title: l10n.instructions,
                icon: Icons.list_alt,
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _instructionController,
                      decoration: const InputDecoration(
                        hintText: 'Yapılış adımı ekle...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onFieldSubmitted: (_) => _addInstruction(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addInstruction,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              if (_instructions.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dividerGray),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _instructions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryRed,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(_instructions[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeInstruction(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryRed,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.primaryRed,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}