import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobi/components/navigation/tab_navigation_bar.dart';
import 'package:mobi/screens/activity_card_details.dart';
import 'package:mobi/screens/activity_create_confirmation_screen.dart';
import 'package:mobi/screens/activity_finish.dart';
import 'package:mobi/screens/alert_card_details.dart';
import 'package:mobi/screens/alert_create_confirmation_screen.dart';
import 'package:mobi/screens/alert_details_screen.dart';
import 'package:mobi/screens/auth_screen.dart';
import 'package:mobi/screens/chat_screen.dart';
import 'package:mobi/screens/comment_add_screen.dart';
import 'package:mobi/screens/comment_show_screen.dart';
import 'package:mobi/screens/conversations_screen.dart';
import 'package:mobi/screens/followers_screen.dart';
import 'package:mobi/screens/following_screen.dart';
import 'package:mobi/screens/help_card_details.dart';
import 'package:mobi/screens/help_close_confirmation_screen.dart';
import 'package:mobi/screens/help_close_screen.dart';
import 'package:mobi/screens/help_close_search_screen.dart';
import 'package:mobi/screens/help_close_user_confirmation.dart';
import 'package:mobi/screens/help_create_confirmation_screen.dart';
import 'package:mobi/screens/help_create_screen.dart';
import 'package:mobi/screens/likes_screen.dart';
import 'package:mobi/screens/profile_screen.dart';
import 'package:mobi/screens/search_user_screen.dart';
import 'package:mobi/screens/show_map_screen.dart';
import 'package:mobi/screens/splash_screen.dart';
import 'package:mobi/screens/statistics_screen.dart';
import 'package:mobi/theme/style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //Configura localização das datas
    initializeDateFormatting();
    Intl.defaultLocale = 'pt_BR';

    return MaterialApp(
      title: 'Mobi',
      theme: appTheme(),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          print("LOG");
          print(userSnapshot.connectionState);
          print(userSnapshot.data);
          print(FirebaseAuth.instance.currentUser);
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return AuthScreen();
          }
          if (userSnapshot.hasData && FirebaseAuth.instance.currentUser != null) {
            return TabNavigationBar();
          } else {
            return AuthScreen();
          }
        },
      ),
      routes: {
        '/auth': (context) => AuthScreen(),
        '/main_feed': (context) => TabNavigationBar(),
        '/alert_detail': (context) => AlertDetailsScreen(),
        '/activity_finish': (context) => ActivityFinishScreen(),
        '/profile': (context) => ProfileScreen(),
        '/activity_card_details': (context) => ActivityCardDetails(),
        '/alert_card_details': (context) => AlertCardDetails(),
        '/help_create_confirmation': (context) => HelpConfirmationScreen(),
        '/help_create': (context) => CreateHelpScreen(),
        '/help_card_details': (context) => HelpCardDetails(),
        '/help_close': (context) => HelpCloseScreen(),
        '/help_close_search': (context) => HelpCloseSearchScreen(),
        '/help_close_confirmation': (context) => HelpCloseConfirmationScreen(),
        '/help_close_user_confirmation': (context) => HelpUserConfirmation(),
        '/alert_create_confirmation': (context) => AlertConfirmationScreen(),
        '/activity_create_confirmation': (context) => ActivityConfirmationScreen(),
        '/chat': (context) => ChatScreen(),
        '/conversations': (context) => Conversations(),
        '/search_user': (context) => SearchUserScreen(),
        '/likes': (context) => LikesScreen(),
        '/show_comments': (context) => ShowCommentsScreen(),
        '/add_comment': (context) => AddCommentScreen(),
        '/show_map_screen': (context) => ShowMapScreen(),
        '/statistics': (context) => StatisticsScreen(),
        '/followers_screen': (context) => FollowersScreen(),
        '/following_screen': (context) => FollowingScreen(),
      },
    );
  }
}
