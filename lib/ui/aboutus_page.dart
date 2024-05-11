import 'package:flutter/material.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  AboutUsPageState createState() => AboutUsPageState();
}

class AboutUsPageState extends State<AboutUsPage> {
  @override
  Widget build(BuildContext context) {

    var isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 10),
            const Text('About Us'),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),

      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/_logo.png', width: 160),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.info_outline,
                      size: 45,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mission',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color:  Colors.purple),
              ),
              Card(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Our mission is to revolutionize the betting industry by providing a transparent, reliable, and technologically advanced platform for betting on stock values, assets, cryptocurrencies, and other financial instruments. We aim to empower our users with the tools and insights they need to make informed decisions in a fast-paced financial environment.',
                    style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vision',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
              Card(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Our vision is to become a global leader in the financial betting industry, recognized for our integrity, innovation, and user-focused services. We strive to expand the boundaries of traditional betting by integrating cutting-edge technologies and ethical practices that benefit our users and the wider community.',
                    style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Company Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
              Card(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    '- Name: Bets Trading Ltd\n- Tax ID: BX993802C\n- Billing Address: Ferrocarril Av. 34, 33430 Candás - Carreño, Spain\n\nLegal Disclaimer: All activities are conducted in strict compliance with local and international laws. Ensure you are aware of your local laws before engaging in any betting activities. Tax implications may vary based on your jurisdiction.',
                    style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Contact Us',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color:  Colors.purple),
              ),
              Card(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      SelectableText(
                        'Email: betsontrading@gmail.com\nPhone: +34 630609337',
                        style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
