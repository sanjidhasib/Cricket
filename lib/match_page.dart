import 'package:flutter/material.dart';

class MatchPage extends StatefulWidget {
  final String hostTeam;
  final String visitorTeam;
  final int overs;

  const MatchPage(
      {super.key,
      required this.hostTeam,
      required this.visitorTeam,
      required this.overs});

  @override
  MatchPageState createState() => MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  int runs = 0, balls = 0, wickets = 0, oversCompleted = 0, bowlerBalls = 0;
  double crr = 0.0;
  String batsman1 = "A*";
  String batsman2 = "B";
  String bowler = "C";
  int batsman1Runs = 0, batsman2Runs = 0, batsman1Balls = 0, batsman2Balls = 0;
  int bowlerRuns = 0, bowlerWickets = 0;
  bool wide = false, noBall = false, wicket = false;
  List<int> runOptions = [0, 1, 2, 3, 4, 6];

  void updateCRR() {
    if (balls > 0) {
      setState(() {
        crr = runs / (balls / 6);
      });
    }
  }

  void nextBall(int run) {
    setState(() {
      if (wide || noBall) {
        runs += run + 1;
        bowlerRuns += 1;
      } else {
        runs += run;
        balls++;
        bowlerBalls++;

        if (wicket) {
          wickets++;
          bowlerWickets++;
          wicket = false;
          _showBatsmanDialog();
        } else {
          if (batsman1.endsWith("*")) {
            batsman1Runs += run;
            batsman1Balls++;
          } else {
            batsman2Runs += run;
            batsman2Balls++;
          }
        }

        if (run % 2 != 0) {
          String temp = batsman1;
          batsman1 = batsman2;
          batsman2 = temp;
        }

        if (bowlerBalls >= 6) {
          bowlerBalls = 0;
          oversCompleted++;
          _showBowlerDialog();
        }
      }
      wide = noBall = false;
    });
    updateCRR();
  }

  void _showBatsmanDialog() {
    TextEditingController batsmanController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Batsman"),
          content: TextField(
            controller: batsmanController,
            decoration:
                const InputDecoration(hintText: "Enter new batsman name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (batsmanController.text.isNotEmpty) {
                  setState(() {
                    if (batsman1.endsWith("*")) {
                      batsman1 = "${batsmanController.text}*";
                      batsman1Runs = 0;
                      batsman1Balls = 0;
                    } else {
                      batsman2 = batsmanController.text;
                      batsman2Runs = 0;
                      batsman2Balls = 0;
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showBowlerDialog() {
    TextEditingController bowlerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Bowler"),
          content: TextField(
            controller: bowlerController,
            decoration:
                const InputDecoration(hintText: "Enter new bowler name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (bowlerController.text.isNotEmpty) {
                  setState(() {
                    bowler = bowlerController.text;
                    bowlerRuns = 0;
                    bowlerWickets = 0;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.hostTeam} vs ${widget.visitorTeam}"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildScoreCard(),
              const SizedBox(height: 10),
              _buildStatsCard("Batsman Stats", [
                _buildStatRow(batsman1, "$batsman1Runs ($batsman1Balls)"),
                _buildStatRow(batsman2, "$batsman2Runs ($batsman2Balls)"),
              ]),
              _buildStatsCard("Bowler Stats", [
                _buildStatRow("Bowler", bowler),
                _buildStatRow("Runs Given", "$bowlerRuns"),
                _buildStatRow("Wickets", "$bowlerWickets"),
              ]),
              _buildExtrasSelection(),
              _buildRunButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Card(
      child: ListTile(
        title: Text("Score: $runs/$wickets"),
        subtitle: Text(
            "Overs: $oversCompleted.$bowlerBalls  |  CRR: ${crr.toStringAsFixed(2)}"),
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Widget> rows) {
    return Card(
      child: Column(children: [ListTile(title: Text(title)), ...rows]),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(value),
    );
  }

  Widget _buildExtrasSelection() {
    return Wrap(
      children: [
        _buildCheckbox("Wide", wide, (val) => setState(() => wide = val!)),
        _buildCheckbox(
            "No Ball", noBall, (val) => setState(() => noBall = val!)),
        _buildCheckbox(
            "Wicket", wicket, (val) => setState(() => wicket = val!)),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
        children: [Checkbox(value: value, onChanged: onChanged), Text(label)]);
  }

  Widget _buildRunButtons() {
    return Wrap(
      children: runOptions
          .map((run) => ElevatedButton(
              onPressed: () => nextBall(run), child: Text("$run")))
          .toList(),
    );
  }
}
