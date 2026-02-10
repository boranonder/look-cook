import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'components/web_layout.dart';

class ContactPage extends StatefulWidget {
  final Function(String)? onNavigate;

  const ContactPage({super.key, this.onNavigate});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate sending
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mesajınız gönderildi. En kısa sürede dönüş yapacağız.'),
          backgroundColor: Colors.green[700],
        ),
      );
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return WebLayoutScrollable(
      onNavigate: widget.onNavigate,
      children: [
        // Hero Section
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryRed, AppTheme.darkRed],
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64 : 24,
            vertical: 80,
          ),
          child: Center(
            child: Column(
              children: [
                Text(
                  'İletişim',
                  style: TextStyle(
                    fontSize: isDesktop ? 48 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sorularınız mı var? Bize ulaşın',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Contact Section
        Container(
          width: double.infinity,
          color: Colors.white,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: Responsive.contentMaxWidth(context),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: 80,
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildContactForm()),
                        const SizedBox(width: 60),
                        Expanded(child: _buildContactInfo()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildContactInfo(),
                        const SizedBox(height: 48),
                        _buildContactForm(),
                      ],
                    ),
            ),
          ),
        ),

        // FAQ Section
        Container(
          width: double.infinity,
          color: Colors.grey[50],
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: Responsive.contentMaxWidth(context),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: 80,
              ),
              child: Column(
                children: [
                  Text(
                    'Sıkça Sorulan Sorular',
                    style: TextStyle(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _FAQItem(
                    question: 'Uygulama ücretsiz mi?',
                    answer: 'Evet, Look & Cook tamamen ücretsizdir. Tüm özelliklere ücretsiz erişebilirsiniz.',
                  ),
                  _FAQItem(
                    question: 'Nasıl tarif paylaşabilirim?',
                    answer: 'Hesap oluşturduktan sonra "Tarif Ekle" butonuna tıklayarak kolayca tarif paylaşabilirsiniz.',
                  ),
                  _FAQItem(
                    question: 'Tariflerimi silebilir miyim?',
                    answer: 'Evet, kendi tariflerinizi istediğiniz zaman düzenleyebilir veya silebilirsiniz.',
                  ),
                  _FAQItem(
                    question: 'Hesabımı nasıl silebilirim?',
                    answer: 'Profil > Ayarlar > Hesap Ayarları bölümünden hesabınızı silebilirsiniz.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bize Yazın',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Formu doldurun, size en kısa sürede dönelim.',
            style: TextStyle(color: AppTheme.textLight),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Adınız',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen adınızı girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen e-posta adresinizi girin';
              }
              if (!value.contains('@')) {
                return 'Geçerli bir e-posta girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Konu',
              prefixIcon: Icon(Icons.subject),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen konu girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Mesajınız',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen mesajınızı yazın';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Gönder',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İletişim Bilgileri',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 32),
        _ContactInfoItem(
          icon: Icons.email,
          title: 'E-posta',
          value: 'destek@lookcookapp.com',
          onTap: () => _launchUrl('mailto:destek@lookcookapp.com'),
        ),
        const SizedBox(height: 24),
        _ContactInfoItem(
          icon: Icons.language,
          title: 'Website',
          value: 'www.lookcookapp.com',
          onTap: () => _launchUrl('https://lookcookapp.com'),
        ),
        const SizedBox(height: 24),
        _ContactInfoItem(
          icon: Icons.access_time,
          title: 'Çalışma Saatleri',
          value: 'Pazartesi - Cuma\n09:00 - 18:00',
        ),
        const SizedBox(height: 40),
        const Text(
          'Sosyal Medya',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _SocialButton(icon: Icons.facebook, onTap: () {}),
            const SizedBox(width: 12),
            _SocialButton(icon: Icons.camera_alt, onTap: () {}),
            const SizedBox(width: 12),
            _SocialButton(icon: Icons.alternate_email, onTap: () {}),
          ],
        ),
      ],
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ContactInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _ContactInfoItem({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryRed),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: onTap != null ? AppTheme.primaryRed : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.remove : Icons.add,
                    color: AppTheme.primaryRed,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.answer,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
