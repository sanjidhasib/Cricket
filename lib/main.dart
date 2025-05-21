import 'package:flutter/material.dart';
import 'match_page.dart';
import 'splash_screen.dart';
import 'SummaryPage.dart';
import 'player_performance.dart';
import 'match_setup_page.dart';

void main() {
  runApp(CricketScorerApp());
}

class CricketScorerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket Scorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
      routes: {
        '/setup': (context) => MatchSetupPage(),
      },
    );
  }
}

class Team {
  final String name;
  final List<String> players;

  Team({required this.name, required this.players});
}

class TeamDatabase {
  static final TeamDatabase _instance = TeamDatabase._internal();
  factory TeamDatabase() => _instance;

  TeamDatabase._internal();

  List<Team> teams = [];

  void addTeam(Team team) {
    teams.add(team);
  }

  List<Team> getAllTeams() {
    return teams;
  }

  Team? getTeamByName(String name) {
    try {
      return teams.firstWhere((team) => team.name == name);
    } catch (e) {
      return null;
    }
  }

  void clearTeams() {
    teams.clear();
  }
}
