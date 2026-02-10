import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'components/web_layout.dart';

class PrivacyPage extends StatelessWidget {
  final Function(String)? onNavigate;

  const PrivacyPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return WebLayoutScrollable(
      onNavigate: onNavigate,
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
            vertical: 60,
          ),
          child: Center(
            child: Column(
              children: [
                Text(
                  'Gizlilik Politikası',
                  style: TextStyle(
                    fontSize: isDesktop ? 42 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Son güncelleme: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        Container(
          width: double.infinity,
          color: Colors.white,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: 60,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Giriş',
                    'Look & Cook olarak gizliliğinize önem veriyoruz. Bu gizlilik politikası, '
                    'uygulamamızı kullandığınızda kişisel verilerinizin nasıl toplandığını, '
                    'kullanıldığını ve korunduğunu açıklamaktadır.',
                  ),
                  _buildSection(
                    'Toplanan Bilgiler',
                    'Uygulamamızı kullanırken aşağıdaki bilgileri toplayabiliriz:\n\n'
                    '• Hesap bilgileri (ad, e-posta adresi)\n'
                    '• Profil bilgileri (profil fotoğrafı, biyografi)\n'
                    '• Paylaştığınız tarifler ve içerikler\n'
                    '• Uygulama kullanım verileri\n'
                    '• Cihaz bilgileri (model, işletim sistemi)',
                  ),
                  _buildSection(
                    'Bilgilerin Kullanımı',
                    'Topladığımız bilgileri şu amaçlarla kullanıyoruz:\n\n'
                    '• Hesabınızı oluşturmak ve yönetmek\n'
                    '• Uygulama özelliklerini sağlamak\n'
                    '• Deneyiminizi kişiselleştirmek\n'
                    '• Uygulamayı geliştirmek ve iyileştirmek\n'
                    '• Güvenliği sağlamak',
                  ),
                  _buildSection(
                    'Bilgi Paylaşımı',
                    'Kişisel bilgilerinizi üçüncü taraflarla satmıyoruz. Bilgilerinizi yalnızca:\n\n'
                    '• Yasal zorunluluklar durumunda\n'
                    '• Sizin açık onayınızla\n'
                    '• Hizmet sağlayıcılarımızla (barındırma, analitik)\n\n'
                    'paylaşabiliriz.',
                  ),
                  _buildSection(
                    'Veri Güvenliği',
                    'Verilerinizi korumak için endüstri standardı güvenlik önlemleri kullanıyoruz. '
                    'Bu önlemler şunları içerir:\n\n'
                    '• SSL/TLS şifreleme\n'
                    '• Güvenli veri depolama\n'
                    '• Düzenli güvenlik denetimleri',
                  ),
                  _buildSection(
                    'Haklarınız',
                    'KVKK kapsamında aşağıdaki haklara sahipsiniz:\n\n'
                    '• Verilerinize erişim hakkı\n'
                    '• Verilerinizin düzeltilmesini isteme hakkı\n'
                    '• Verilerinizin silinmesini isteme hakkı\n'
                    '• Veri işlemeye itiraz hakkı\n\n'
                    'Bu haklarınızı kullanmak için destek@lookcookapp.com adresinden bize ulaşabilirsiniz.',
                  ),
                  _buildSection(
                    'Çerezler',
                    'Web sitemizde deneyiminizi iyileştirmek için çerezler kullanıyoruz. '
                    'Çerezler, tarayıcınızda saklanan küçük metin dosyalarıdır. '
                    'Tarayıcı ayarlarınızdan çerezleri devre dışı bırakabilirsiniz.',
                  ),
                  _buildSection(
                    'Çocukların Gizliliği',
                    'Uygulamamız 13 yaşın altındaki çocuklara yönelik değildir. '
                    'Bilerek 13 yaşın altındaki kişilerden kişisel bilgi toplamıyoruz.',
                  ),
                  _buildSection(
                    'Değişiklikler',
                    'Bu gizlilik politikasını zaman zaman güncelleyebiliriz. '
                    'Önemli değişiklikler olduğunda size e-posta veya uygulama içi bildirim yoluyla haber vereceğiz.',
                  ),
                  _buildSection(
                    'İletişim',
                    'Gizlilik politikamızla ilgili sorularınız için:\n\n'
                    'E-posta: destek@lookcookapp.com\n'
                    'Web: www.lookcookapp.com/contact',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textLight,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
