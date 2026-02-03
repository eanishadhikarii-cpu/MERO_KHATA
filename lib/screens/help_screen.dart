import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool isNepali = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isNepali ? 'सहायता' : 'Help'),
        actions: [
          Switch(
            value: isNepali,
            onChanged: (value) => setState(() => isNepali = value),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              isNepali ? 'मुख्य सुविधाहरू' : 'Main Features',
              isNepali ? [
                '• बिक्री र खरिद व्यवस्थापन',
                '• ग्राहक खाता (उधारो) ट्र्याकिङ',
                '• स्टक व्यवस्थापन',
                '• दैनिक रिपोर्ट',
                '• बारकोड स्क्यान',
              ] : [
                '• Sales and purchase management',
                '• Customer account (credit) tracking',
                '• Stock management',
                '• Daily reports',
                '• Barcode scanning',
              ],
            ),
            
            _buildSection(
              isNepali ? 'बिक्री कसरी गर्ने' : 'How to Make a Sale',
              isNepali ? [
                '१. होम स्क्रिनमा "बिक्री" बटन थिच्नुहोस्',
                '२. उत्पादन खोज्नुहोस् वा बारकोड स्क्यान गर्नुहोस्',
                '३. मात्रा सेट गर्नुहोस्',
                '४. "बिक्री पूरा गर्नुहोस्" थिच्नुहोस्',
                '५. भुक्तानी विधि छान्नुहोस्',
              ] : [
                '1. Tap "Sale" button on home screen',
                '2. Search product or scan barcode',
                '3. Set quantity',
                '4. Tap "Complete Sale"',
                '5. Choose payment method',
              ],
            ),
            
            _buildSection(
              isNepali ? 'उधारो बिक्री' : 'Credit Sales',
              isNepali ? [
                '• बिक्री पूरा गर्दा "उधारो" छान्नुहोस्',
                '• ग्राहकको नाम र फोन नम्बर राख्नुहोस्',
                '• ग्राहक खाता स्वचालित रूपमा अपडेट हुन्छ',
                '• "ग्राहक खाता" बाट बकाया हेर्न सकिन्छ',
              ] : [
                '• Select "Credit" when completing sale',
                '• Enter customer name and phone',
                '• Customer account updates automatically',
                '• View outstanding from "Customer Account"',
              ],
            ),
            
            _buildSection(
              isNepali ? 'उत्पादन थप्ने' : 'Adding Products',
              isNepali ? [
                '• एडमिन प्यानलमा जानुहोस्',
                '• "इन्भेन्टरी" मा क्लिक गर्नुहोस्',
                '• "नयाँ उत्पादन" बटन थिच्नुहोस्',
                '• विवरणहरू भर्नुहोस्',
                '• सेभ गर्नुहोस्',
              ] : [
                '• Go to Admin Panel',
                '• Click "Inventory"',
                '• Tap "New Product" button',
                '• Fill in details',
                '• Save',
              ],
            ),
            
            _buildSection(
              isNepali ? 'रिपोर्ट हेर्ने' : 'Viewing Reports',
              isNepali ? [
                '• एडमिन प्यानलमा "रिपोर्ट" मा जानुहोस्',
                '• दैनिक, साप्ताहिक, मासिक रिपोर्ट हेर्नुहोस्',
                '• बिक्री, नाफा, स्टक रिपोर्ट उपलब्ध',
                '• रिपोर्ट शेयर गर्न सकिन्छ',
              ] : [
                '• Go to "Reports" in Admin Panel',
                '• View daily, weekly, monthly reports',
                '• Sales, profit, stock reports available',
                '• Reports can be shared',
              ],
            ),
            
            _buildSection(
              isNepali ? 'सुरक्षा' : 'Security',
              isNepali ? [
                '• एडमिन प्यानल PIN द्वारा सुरक्षित',
                '• बायोमेट्रिक लक समर्थन',
                '• डाटा स्थानीय रूपमा भण्डारण',
                '• नियमित ब्याकअप लिनुहोस्',
              ] : [
                '• Admin Panel secured by PIN',
                '• Biometric lock support',
                '• Data stored locally',
                '• Take regular backups',
              ],
            ),
            
            _buildSection(
              isNepali ? 'समस्या समाधान' : 'Troubleshooting',
              isNepali ? [
                '• एप बन्द भएर खुल्दैन भने फोन रिस्टार्ट गर्नुहोस्',
                '• डाटा हराएको छ भने ब्याकअप रिस्टोर गर्नुहोस्',
                '• बारकोड स्क्यान काम नगरे क्यामेरा अनुमति दिनुहोस्',
                '• ढिलो चलिरहेको छ भने स्टोरेज सफा गर्नुहोस्',
              ] : [
                '• If app crashes, restart phone',
                '• If data lost, restore from backup',
                '• If barcode not working, allow camera permission',
                '• If running slow, clear storage',
              ],
            ),
            
            SizedBox(height: 32),
            
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 32),
                    SizedBox(height: 8),
                    Text(
                      isNepali ? 'थप सहायताको लागि' : 'For More Help',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      isNepali 
                        ? 'यो एप नेपाली पसलेहरूको लागि बनाइएको हो। सबै सुविधाहरू अफलाइनमा काम गर्छ।'
                        : 'This app is made for Nepali shopkeepers. All features work offline.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text(item, style: TextStyle(fontSize: 14)),
              )).toList(),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}