import 'package:flutter/material.dart';
import 'main.dart';
import 'match_page.dart';
import 'player_performance.dart';
import 'SummaryPage.dart';

// Define theme colors
const Color kOffWhite = Color(0xFFF5F5F0);
const Color kGolden = Color(0xFFD4AF37);
const Color kBlack = Colors.black;

class MatchSetupPage extends StatefulWidget {
  @override
  _MatchSetupPageState createState() => _MatchSetupPageState();
}

class _MatchSetupPageState extends State<MatchSetupPage> {
  final TeamDatabase db = TeamDatabase();
  final TextEditingController hostController = TextEditingController();
  final TextEditingController visitorController = TextEditingController();
  final TextEditingController oversController =
      TextEditingController(text: "20");
  final TextEditingController venueController = TextEditingController();
  final TextEditingController matchDateController = TextEditingController();
  String? tossWinner;
  String? tossDecision;

  Team? selectedHostTeam;
  Team? selectedVisitorTeam;

  @override
  void initState() {
    super.initState();
    _initializeDefaultTeams();
    matchDateController.text = DateTime.now().toString().split(' ')[0];
  }

  void _initializeDefaultTeams() {
    if (db.getAllTeams().isEmpty) {
      db.addTeam(
        Team(
          name: "India",
          players: [
            "Rohit Sharma",
            "Virat Kohli",
            "KL Rahul",
            "Rishabh Pant",
            "Ravindra Jadeja",
            "Hardik Pandya",
            "R Ashwin",
            "Jasprit Bumrah",
            "Mohammed Shami",
            "Mohammed Siraj",
            "Shubman Gill"
          ],
        ),
      );
      db.addTeam(
        Team(
          name: "Australia",
          players: [
            "David Warner",
            "Steve Smith",
            "Marnus Labuschagne",
            "Glenn Maxwell",
            "Mitchell Marsh",
            "Alex Carey",
            "Pat Cummins",
            "Mitchell Starc",
            "Josh Hazlewood",
            "Nathan Lyon",
            "Travis Head"
          ],
        ),
      );
      db.addTeam(
        Team(
          name: "England",
          players: [
            "Joe Root",
            "Ben Stokes",
            "Jos Buttler",
            "Jonny Bairstow",
            "Moeen Ali",
            "Chris Woakes",
            "Jofra Archer",
            "Stuart Broad",
            "Jimmy Anderson",
            "Ollie Pope",
            "Zak Crawley"
          ],
        ),
      );
    }
  }

  void startMatch() {
    if (_validateSetup()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchPage(
            hostTeam: hostController.text,
            visitorTeam: visitorController.text,
            overs: int.parse(oversController.text),
            tossWinner: tossWinner!,
            tossDecision: tossDecision!,
            hostPlayers: selectedHostTeam!.players,
            visitorPlayers: selectedVisitorTeam!.players,
            matchDate: matchDateController.text,
            venue: venueController.text.isNotEmpty
                ? venueController.text
                : "Home Ground",
            onMatchEnd: (
              String winner,
              int hostScore,
              int visitorScore,
              int hostWickets,
              int visitorWickets,
              double hostOvers,
              double visitorOvers,
              List<PlayerPerformance> hostPlayerPerformances,
              List<PlayerPerformance> visitorPlayerPerformances,
            ) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SummaryPage(
                    winner: winner,
                    hostTeam: hostController.text,
                    visitorTeam: visitorController.text,
                    hostScore: hostScore,
                    visitorScore: visitorScore,
                    hostWickets: hostWickets,
                    visitorWickets: visitorWickets,
                    hostOvers: hostOvers,
                    visitorOvers: visitorOvers,
                    venue: venueController.text.isNotEmpty
                        ? venueController.text
                        : "Home Ground",
                    matchDate: matchDateController.text,
                    hostPlayers: hostPlayerPerformances,
                    visitorPlayers: visitorPlayerPerformances,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  bool _validateSetup() {
    if (hostController.text.isEmpty || visitorController.text.isEmpty) {
      _showErrorSnackBar('Please select both teams');
      return false;
    }

    if (oversController.text.isEmpty) {
      _showErrorSnackBar('Please enter the number of overs');
      return false;
    }

    try {
      int overs = int.parse(oversController.text);
      if (overs <= 0 || overs > 50) {
        _showErrorSnackBar('Overs should be between 1 and 50');
        return false;
      }
    } catch (e) {
      _showErrorSnackBar('Please enter a valid number of overs');
      return false;
    }

    if (tossWinner == null) {
      _showErrorSnackBar('Please select the toss winner');
      return false;
    }

    if (tossDecision == null) {
      _showErrorSnackBar('Please select the toss decision');
      return false;
    }

    if (selectedHostTeam == null || selectedVisitorTeam == null) {
      _showErrorSnackBar('Please select both teams');
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: kOffWhite)),
        backgroundColor: kBlack,
      ),
    );
  }

  void _showAddTeamDialog() {
    final teamNameController = TextEditingController();
    final List<TextEditingController> playerControllers =
        List.generate(11, (index) => TextEditingController());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kOffWhite,
          title: Text("Add New Team",
              style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: teamNameController,
                  decoration: InputDecoration(
                    labelText: "Team Name",
                    labelStyle: TextStyle(color: kBlack),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: kGolden),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kGolden, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kGolden),
                    ),
                  ),
                  style: TextStyle(color: kBlack),
                ),
                SizedBox(height: 20),
                Text("Enter 11 Players:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: kBlack)),
                SizedBox(height: 10),
                ...List.generate(
                  11,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: playerControllers[index],
                      decoration: InputDecoration(
                        labelText: "Player ${index + 1}",
                        labelStyle: TextStyle(color: kBlack),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: kGolden),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: kGolden, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: kGolden),
                        ),
                      ),
                      style: TextStyle(color: kBlack),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: kGolden)),
            ),
            TextButton(
              onPressed: () {
                if (teamNameController.text.isEmpty) {
                  _showErrorSnackBar("Please enter a team name");
                  return;
                }

                bool allPlayersEntered = playerControllers
                    .every((controller) => controller.text.isNotEmpty);

                if (!allPlayersEntered) {
                  _showErrorSnackBar("Please enter all 11 player names");
                  return;
                }

                final team = Team(
                  name: teamNameController.text,
                  players: playerControllers.map((c) => c.text).toList(),
                );

                db.addTeam(team);
                setState(() {});
                Navigator.pop(context);
                _showErrorSnackBar("Team added successfully");
              },
              child: Text("Add Team",
                  style:
                      TextStyle(color: kGolden, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showTeamSelectionDialog(bool isHost) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kOffWhite,
          title: Text("Select ${isHost ? 'Host' : 'Visitor'} Team",
              style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: db.getAllTeams().length,
              itemBuilder: (context, index) {
                final team = db.getAllTeams()[index];
                return ListTile(
                  title: Text(team.name, style: TextStyle(color: kBlack)),
                  subtitle: Text("${team.players.length} players",
                      style: TextStyle(color: kBlack.withOpacity(0.7))),
                  tileColor:
                      index % 2 == 0 ? kOffWhite : kOffWhite.withOpacity(0.8),
                  onTap: () {
                    setState(() {
                      if (isHost) {
                        selectedHostTeam = team;
                        hostController.text = team.name;
                      } else {
                        selectedVisitorTeam = team;
                        visitorController.text = team.name;
                      }
                    });
                    Navigator.pop(context);
                    _showTeamPlayersDialog(team);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: kGolden)),
            ),
          ],
        );
      },
    );
  }

  void _showTeamPlayersDialog(Team team) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kOffWhite,
          title: Text("${team.name} Players",
              style: TextStyle(color: kBlack, fontWeight: FontWeight.bold)),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: team.players.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child:
                        Text("${index + 1}", style: TextStyle(color: kBlack)),
                    backgroundColor: kGolden,
                  ),
                  title: Text(team.players[index],
                      style: TextStyle(color: kBlack)),
                  tileColor:
                      index % 2 == 0 ? kOffWhite : kOffWhite.withOpacity(0.8),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK",
                  style:
                      TextStyle(color: kGolden, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        title: Text("Cricket Scorer",
            style: TextStyle(color: kOffWhite, fontWeight: FontWeight.bold)),
        backgroundColor: kBlack,
        iconTheme: IconThemeData(color: kGolden),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: kGolden),
            onPressed: _showAddTeamDialog,
            tooltip: "Add New Team",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                color: kOffWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: kGolden, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Teams",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kBlack)),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _showTeamSelectionDialog(true),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: hostController,
                            style: TextStyle(color: kBlack),
                            decoration: InputDecoration(
                              labelText: "Host Team",
                              labelStyle: TextStyle(color: kBlack),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: kGolden),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: kGolden, width: 2),
                              ),
                              suffixIcon:
                                  Icon(Icons.arrow_drop_down, color: kGolden),
                            ),
                          ),
                        ),
                      ),
                      if (selectedHostTeam != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                          child: Text(
                            "Selected ${selectedHostTeam!.players.length} players",
                            style: TextStyle(color: kBlack.withOpacity(0.7)),
                          ),
                        ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _showTeamSelectionDialog(false),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: visitorController,
                            style: TextStyle(color: kBlack),
                            decoration: InputDecoration(
                              labelText: "Visitor Team",
                              labelStyle: TextStyle(color: kBlack),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: kGolden),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: kGolden, width: 2),
                              ),
                              suffixIcon:
                                  Icon(Icons.arrow_drop_down, color: kGolden),
                            ),
                          ),
                        ),
                      ),
                      if (selectedVisitorTeam != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                          child: Text(
                            "Selected ${selectedVisitorTeam!.players.length} players",
                            style: TextStyle(color: kBlack.withOpacity(0.7)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                color: kOffWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: kGolden, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Match Details",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kBlack)),
                      SizedBox(height: 16),
                      TextField(
                        controller: oversController,
                        style: TextStyle(color: kBlack),
                        decoration: InputDecoration(
                          labelText: "Overs",
                          labelStyle: TextStyle(color: kBlack),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kGolden),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kGolden, width: 2),
                          ),
                          helperText: "Enter a number between 1 and 50",
                          helperStyle:
                              TextStyle(color: kBlack.withOpacity(0.7)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: venueController,
                        style: TextStyle(color: kBlack),
                        decoration: InputDecoration(
                          labelText: "Venue",
                          labelStyle: TextStyle(color: kBlack),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kGolden),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kGolden, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: matchDateController,
                        style: TextStyle(color: kBlack),
                        decoration: InputDecoration(
                          labelText: "Match Date",
                          labelStyle: TextStyle(color: kBlack),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kGolden),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kGolden, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today, color: kGolden),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: kBlack,
                                        onPrimary: kOffWhite,
                                        onSurface: kBlack,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: kGolden,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                matchDateController.text =
                                    date.toString().split(' ')[0];
                              }
                            },
                          ),
                        ),
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                color: kOffWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: kGolden, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Toss Details",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kBlack)),
                      SizedBox(height: 8),
                      Text("Toss won by:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: kBlack)),
                      Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: kGolden.withOpacity(0.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile(
                                title: Text("Host",
                                    style: TextStyle(color: kBlack)),
                                value: "host",
                                groupValue: tossWinner,
                                activeColor: kGolden,
                                onChanged: (value) {
                                  setState(() {
                                    tossWinner = value as String?;
                                    tossDecision = null;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile(
                                title: Text("Visitor",
                                    style: TextStyle(color: kBlack)),
                                value: "visitor",
                                groupValue: tossWinner,
                                activeColor: kGolden,
                                onChanged: (value) {
                                  setState(() {
                                    tossWinner = value as String?;
                                    tossDecision = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (tossWinner != null) ...[
                        SizedBox(height: 8),
                        Text("Decision:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: kBlack)),
                        Theme(
                          data: Theme.of(context).copyWith(
                            unselectedWidgetColor: kGolden.withOpacity(0.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: RadioListTile(
                                  title: Text("Bat",
                                      style: TextStyle(color: kBlack)),
                                  value: "bat",
                                  groupValue: tossDecision,
                                  activeColor: kGolden,
                                  onChanged: (value) {
                                    setState(() {
                                      tossDecision = value as String?;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile(
                                  title: Text("Field",
                                      style: TextStyle(color: kBlack)),
                                  value: "field",
                                  groupValue: tossDecision,
                                  activeColor: kGolden,
                                  onChanged: (value) {
                                    setState(() {
                                      tossDecision = value as String?;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.sports_cricket, color: kOffWhite),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlack,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: kGolden, width: 2),
                    ),
                  ),
                  onPressed: startMatch,
                  label: Text("Start Match",
                      style: TextStyle(
                          color: kOffWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
