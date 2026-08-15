import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vipinde_todo/core/app_theme.dart';
import 'package:vipinde_todo/providers/user_search_provider.dart';
import 'package:vipinde_todo/screens/search_screen.dart';
import 'package:vipinde_todo/services/github_api_service.dart';
import 'package:vipinde_todo/services/recent_searches_service.dart';

void main() {
  runApp(const VipindeTodoApp());
}

class VipindeTodoApp extends StatelessWidget {
  const VipindeTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services are plain dependencies, injected so they can be faked in tests.
        Provider<GithubApiService>(create: (_) => GithubApiService()),
        Provider<RecentSearchesService>(create: (_) => RecentSearchesService()),
        ChangeNotifierProvider<UserSearchProvider>(
          create: (context) => UserSearchProvider(
            api: context.read<GithubApiService>(),
            recentSearches: context.read<RecentSearchesService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'vipinde_ToDo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const SearchScreen(),
      ),
    );
  }
}
