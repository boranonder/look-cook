import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  Future<void> _sendPasswordResetEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.currentUser?.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('E-posta adresi bulunamadı'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    try {
      await authProvider.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.email, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Şifre sıfırlama linki $email adresine gönderildi'),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Ayarları'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Email Info
          Card(
            child: ListTile(
              leading: const Icon(Icons.email, color: AppTheme.primaryRed),
              title: const Text('E-posta Adresi'),
              subtitle: Text(currentUser?.email ?? 'Bilinmiyor'),
            ),
          ),

          const SizedBox(height: 24),

          // Security Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Güvenlik',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Change Password
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock, color: AppTheme.primaryRed),
              title: const Text('Şifre Değiştir'),
              subtitle: const Text('Hesabınızın şifresini güncelleyin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePasswordDialog(context),
            ),
          ),

          const SizedBox(height: 24),

          // Danger Zone
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Tehlikeli Bölge',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Delete Account
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Hesabı Sil',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Bu işlem geri alınamaz'),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? currentPasswordError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Şifre Değiştir'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current Password
                  TextFormField(
                    controller: currentPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Mevcut Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                      ),
                      errorText: currentPasswordError,
                    ),
                    obscureText: obscureCurrent,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mevcut şifre gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // New Password
                  TextFormField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    obscureText: obscureNew,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Yeni şifre gerekli';
                      }
                      if (value.length < 8) {
                        return 'Şifre en az 8 karakter olmalı';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Büyük harf gerekli';
                      }
                      if (!RegExp(r'[a-z]').hasMatch(value)) {
                        return 'Küçük harf gerekli';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Rakam gerekli';
                      }
                      if (value == currentPasswordController.text) {
                        return 'Yeni şifre mevcut şifreden farklı olmalı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre Tekrar',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    obscureText: obscureConfirm,
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Şifre: 8+ karakter, büyük harf, küçük harf, rakam',
                      style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              Navigator.pop(context);
                              _sendPasswordResetEmail();
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Şifremi unuttum',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Clear previous error
                      setDialogState(() => currentPasswordError = null);

                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isLoading = true);

                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);

                        // Verify current password first
                        final isValid = await authProvider.verifyPassword(currentPasswordController.text);
                        if (!isValid) {
                          setDialogState(() {
                            isLoading = false;
                            currentPasswordError = 'Mevcut şifre yanlış';
                          });
                          return;
                        }

                        // Update password
                        await authProvider.updatePassword(newPasswordController.text);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Şifreniz güncellendi'),
                                ],
                              ),
                              backgroundColor: Colors.green[700],
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: Colors.red[700],
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Hesabı Sil'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu işlem geri alınamaz!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text('Hesabınızı sildiğinizde:'),
            SizedBox(height: 8),
            Text('• Tüm tarifleriniz silinecek'),
            Text('• Tüm yorumlarınız silinecek'),
            Text('• Takipçi ve takip listeniz silinecek'),
            Text('• Favori listeleriniz silinecek'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Second confirmation
              final confirmed = await showDialog<bool>(
                context: this.context,
                builder: (context) => AlertDialog(
                  title: const Text('Emin misiniz?'),
                  content: const Text(
                    'Hesabınızı kalıcı olarak silmek istediğinizden emin misiniz?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hayır'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Evet, Sil'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && this.context.mounted) {
                try {
                  final authProvider = Provider.of<AuthProvider>(this.context, listen: false);
                  await authProvider.deleteAccount();
                  await authProvider.signOut();
                } catch (e) {
                  if (this.context.mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Hesap silinemedi: $e'),
                        backgroundColor: Colors.red[700],
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }
}
