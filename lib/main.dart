import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
 
import 'firebase_options.dart'; // gerado pelo comando: flutterfire configure
 
final navigatorKey = GlobalKey<NavigatorState>();
 
// ---------- Dados do app (fixos no código) ----------
class Match {
  final String id;
  final String home;
  final String away;
  final String date;
  final String stadium;
  final String description;
  const Match(this.id, this.home, this.away, this.date, this.stadium, this.description);
}
 
const matches = <Match>[
  Match('1', 'Flamengo', 'Vasco', 'Sáb, 16:00', 'Maracanã',
      'Clássico dos Milhões válido pela rodada. Expectativa de casa cheia e jogo muito disputado.'),
  Match('2', 'Palmeiras', 'Corinthians', 'Dom, 18:30', 'Allianz Parque',
      'Derby paulista com times em momentos parecidos na tabela.'),
  Match('3', 'Grêmio', 'Internacional', 'Dom, 16:00', 'Arena do Grêmio',
      'Grenal da rodada, sempre imprevisível.'),
  Match('4', 'Remo', 'Paysandu', 'Seg, 20:00', 'Mangueirão',
      'Re-Pa, o grande clássico paraense.'),
];
 
// ---------- Handler de mensagens com app em segundo plano/encerrado ----------
// Precisa ser função de nível superior (fora de classes).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Mensagem em background: ${message.messageId}');
}
 
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const RodadaApp());
}
 
class RodadaApp extends StatelessWidget {
  const RodadaApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rodada FC',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
 
// ---------- Tela inicial ----------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
 
  @override
  State<HomePage> createState() => _HomePageState();
}
 
class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _setupFcm();
  }
 
  Future<void> _setupFcm() async {
    final fcm = FirebaseMessaging.instance;
 
    // Permissão (necessária no Android 13+)
    await fcm.requestPermission();
 
    // Token do aparelho: use no Firebase Console para enviar um teste direto
    final token = await fcm.getToken();
    debugPrint('FCM TOKEN: $token');
 
    // Opcional: inscrição em tópico, permite enviar para todos pelo Console
    await fcm.subscribeToTopic('torcedores');
 
    // App ENCERRADO e aberto pelo toque na notificação
    final initial = await fcm.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openFromMessage(initial));
    }
 
    // App em SEGUNDO PLANO e aberto pelo toque na notificação
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
 
    // App ABERTO (primeiro plano): o Android não mostra notificação sozinho,
    // então exibimos um aviso dentro do app.
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${n.title ?? ''}\n${n.body ?? ''}'),
          action: SnackBarAction(
            label: 'VER',
            onPressed: () => _openFromMessage(message),
          ),
        ),
      );
    });
  }
 
  // Lê o dado "matchId" e abre a tela do jogo correspondente
  void _openFromMessage(RemoteMessage message) {
    final id = message.data['matchId'];
    if (id == null) return;
    final match = matches.where((m) => m.id == id).firstOrNull;
    if (match == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => DetailPage(match: match)),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚽ Rodada FC')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: matches.length,
        itemBuilder: (context, i) {
          final m = matches[i];
          return Card(
            child: ListTile(
              title: Text('${m.home} x ${m.away}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${m.date} • ${m.stadium}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailPage(match: m)),
              ),
            ),
          );
        },
      ),
    );
  }
}
 
// ---------- Tela de detalhes ----------
class DetailPage extends StatelessWidget {
  final Match match;
  const DetailPage({super.key, required this.match});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do jogo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${match.home} x ${match.away}',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.schedule),
              const SizedBox(width: 8),
              Text(match.date),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.stadium),
              const SizedBox(width: 8),
              Text(match.stadium),
            ]),
            const SizedBox(height: 24),
            Text(match.description, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
