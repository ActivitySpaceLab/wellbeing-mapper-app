import 'package:flutter/material.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingHelper {
  static const String _onboardingKey = 'has_seen_onboarding';
  
  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingKey) ?? false);
  }
  
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
  
  /// Localization helper (English default, Italian, Spanish).
  static String _t3(BuildContext context, String en, String it, String es) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'it':
        return it;
      case 'es':
        return es;
      default:
        return en;
    }
  }

  static void showQuickTour(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.waving_hand, color: SouthAfricanTheme.accentYellow),
            SizedBox(width: 8),
            Text(_t3(context, 'Welcome!', 'Benvenuto/a!', '¡Bienvenido/a!')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t3(context, 'Let\'s quickly show you around:',
                    'Facciamo un rapido giro dell\'app:',
                    'Hagamos un recorrido rápido:'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              _buildTourItem(
                  Icons.toggle_on,
                  _t3(context, 'Yellow switch = location tracking ON',
                      'Interruttore giallo = tracciamento della posizione ATTIVO',
                      'Interruptor amarillo = seguimiento de ubicación ACTIVADO')),
              _buildTourItem(
                  Icons.gps_fixed,
                  _t3(context, 'GPS button = get current location',
                      'Pulsante GPS = ottieni la posizione attuale',
                      'Botón GPS = obtener la ubicación actual')),
              _buildTourItem(
                  Icons.add_circle,
                  _t3(context, 'Blue "Survey" button = take wellbeing survey',
                      'Pulsante blu "Questionario" = compila il questionario sul benessere',
                      'Botón azul "Encuesta" = responder la encuesta de bienestar')),
              _buildTourItem(
                  Icons.menu,
                  _t3(context, 'Menu = access all app features',
                      'Menu = accedi a tutte le funzionalità dell\'app',
                      'Menú = acceder a todas las funciones de la aplicación')),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SouthAfricanTheme.softYellow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _t3(context,
                      'Tip: Open the menu and tap "Help & Guide" for detailed instructions!',
                      'Suggerimento: apri il menu e tocca "Aiuto e guida" per istruzioni dettagliate!',
                      'Consejo: abra el menú y toque "Ayuda y guía" para instrucciones detalladas.'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              markOnboardingComplete();
            },
            child: Text(_t3(context, 'Got it!', 'Ho capito!', '¡Entendido!')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              markOnboardingComplete();
              Navigator.of(context).pushNamed('/help');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SouthAfricanTheme.primaryBlue,
              foregroundColor: SouthAfricanTheme.pureWhite,
            ),
            child: Text(_t3(context, 'Show Full Guide', 'Mostra la guida completa',
                'Mostrar la guía completa')),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildTourItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SouthAfricanTheme.primaryBlue),
          SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
