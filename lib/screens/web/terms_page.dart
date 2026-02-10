import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'components/web_layout.dart';

class TermsPage extends StatelessWidget {
  final Function(String)? onNavigate;

  const TermsPage({super.key, this.onNavigate});

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
                  'Kullanım Koşulları',
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
                    'Kabul',
                    'Look & Cook uygulamasını kullanarak bu kullanım koşullarını kabul etmiş sayılırsınız. '
                    'Bu koşulları kabul etmiyorsanız, lütfen uygulamayı kullanmayın.',
                  ),
                  _buildSection(
                    'Hesap Oluşturma',
                    'Uygulamamızı kullanmak için bir hesap oluşturmanız gerekebilir. Hesap oluştururken:\n\n'
                    '• Doğru ve güncel bilgiler vermeyi kabul edersiniz\n'
                    '• Hesap bilgilerinizi gizli tutmayı kabul edersiniz\n'
                    '• Hesabınızda gerçekleşen tüm aktivitelerden sorumlusunuz\n'
                    '• 13 yaşından büyük olduğunuzu beyan edersiniz',
                  ),
                  _buildSection(
                    'Kullanıcı İçeriği',
                    'Uygulamamızda paylaştığınız tarifler, fotoğraflar ve yorumlar için:\n\n'
                    '• İçeriğin size ait olduğunu veya paylaşma hakkınız olduğunu beyan edersiniz\n'
                    '• İçeriğin telif hakkı ihlali içermediğini kabul edersiniz\n'
                    '• Zararlı, yanıltıcı veya uygunsuz içerik paylaşmamayı kabul edersiniz\n'
                    '• Look & Cook\'a içeriğinizi platform üzerinde kullanma hakkı verirsiniz',
                  ),
                  _buildSection(
                    'Yasaklı Davranışlar',
                    'Aşağıdaki davranışlar kesinlikle yasaktır:\n\n'
                    '• Spam veya istenmeyen içerik paylaşmak\n'
                    '• Diğer kullanıcıları taciz etmek\n'
                    '• Yanıltıcı veya sahte bilgi paylaşmak\n'
                    '• Uygulamanın güvenliğini tehlikeye atmak\n'
                    '• Başkalarının fikri mülkiyet haklarını ihlal etmek\n'
                    '• Yasa dışı içerik paylaşmak',
                  ),
                  _buildSection(
                    'Fikri Mülkiyet',
                    'Look & Cook uygulaması, tasarımı, logoları ve içeriği telif hakkı ile korunmaktadır. '
                    'Yazılı izin olmadan uygulamamızın herhangi bir kısmını kopyalayamaz, '
                    'değiştiremez veya dağıtamazsınız.',
                  ),
                  _buildSection(
                    'Sorumluluk Reddi',
                    'Uygulamamız "olduğu gibi" sunulmaktadır. Şunları garanti etmiyoruz:\n\n'
                    '• Hizmetin kesintisiz veya hatasız olacağını\n'
                    '• Tariflerin doğruluğu veya güvenliğini\n'
                    '• Kullanıcı tarafından oluşturulan içeriğin kalitesini\n\n'
                    'Tarifleri uygularken kendi sorumluluğunuzda dikkatli olmanızı öneririz.',
                  ),
                  _buildSection(
                    'Hesap Sonlandırma',
                    'Aşağıdaki durumlarda hesabınızı sonlandırma hakkımızı saklı tutarız:\n\n'
                    '• Kullanım koşullarının ihlali\n'
                    '• Uzun süreli hesap inaktivitesi\n'
                    '• Yasadışı aktiviteler\n\n'
                    'Siz de istediğiniz zaman hesabınızı silebilirsiniz.',
                  ),
                  _buildSection(
                    'Değişiklikler',
                    'Bu kullanım koşullarını önceden haber vermeksizin değiştirme hakkını saklı tutarız. '
                    'Önemli değişiklikler e-posta veya uygulama içi bildirim yoluyla duyurulacaktır. '
                    'Değişikliklerden sonra uygulamayı kullanmaya devam etmeniz, '
                    'yeni koşulları kabul ettiğiniz anlamına gelir.',
                  ),
                  _buildSection(
                    'Uyuşmazlık Çözümü',
                    'Bu koşullardan doğan uyuşmazlıklar Türkiye Cumhuriyeti kanunlarına tabi olacaktır. '
                    'Uyuşmazlıklar için İstanbul mahkemeleri yetkilidir.',
                  ),
                  _buildSection(
                    'İletişim',
                    'Kullanım koşullarıyla ilgili sorularınız için:\n\n'
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
