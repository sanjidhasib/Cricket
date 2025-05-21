import 'package:flutter/material.dart';
import 'SummaryPage.dart';
import 'player_performance.dart';

class MatchPage extends StatefulWidget {
  final String hostTeam;
  final String visitorTeam;
  final int overs;
  final String tossWinner;
  final String tossDecision;
  final Function(
    String winner,
    int hostScore,
    int visitorScore,
    int hostWickets,
    int visitorWickets,
    double hostOvers,
    double visitorOvers,
    List<PlayerPerformance> hostPlayers,
    List<PlayerPerformance> visitorPlayers,
  ) onMatchEnd;
  final List<String> hostPlayers;
  final List<String> visitorPlayers;
  final String matchDate;
  final String venue;

  const MatchPage({
    super.key,
    required this.hostTeam,
    required this.visitorTeam,
    required this.overs,
    required this.tossWinner,
    required this.tossDecision,
    required this.onMatchEnd,
    required this.hostPlayers,
    required this.visitorPlayers,
    this.matchDate = 'Today',
    this.venue = 'Home Ground',
  });

  @override
  MatchPageState createState() => MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  int runs = 0, balls = 0, wickets = 0, oversCompleted = 0, bowlerBalls = 0;
  double crr = 0.0;
  String batsman1 = "";
  String batsman2 = "";
  String bowler = "";
  int batsman1Runs = 0, batsman2Runs = 0, batsman1Balls = 0, batsman2Balls = 0;
  int batsman1Fours = 0,
      batsman1Sixes = 0,
      batsman2Fours = 0,
      batsman2Sixes = 0;
  int bowlerRuns = 0, bowlerWickets = 0, bowlerMaidens = 0;
  bool wide = false, noBall = false, wicket = false;
  List<int> runOptions = [0, 1, 2, 3, 4, 6];
  bool isFirstInnings = true;
  int targetRuns = 0;
  String battingTeam = "";
  String bowlingTeam = "";
  bool potentialMaiden = true;
  late List<String> battingPlayers;
  late List<String> bowlingPlayers;
  List<String> outBatsmen = [];
  Map<String, int> bowlerOvers = {};
  Set<String> bowlersUsed = {};
  Map<String, PlayerPerformance> hostPlayerStats = {};
  Map<String, PlayerPerformance> visitorPlayerStats = {};
  String dismissalType = "Bowled";
  String dismissedBy = "";
  bool isWaitingForNewBatsman = false;
  bool isWaitingForNewBowler = false;
  bool isMatchStarted = false;
  bool isShowingDismissalDialog = false;

  @override
  void initState() {
    super.initState();
    // Determine who bats first based on toss
    if (widget.tossWinner == "host") {
      battingTeam = widget.hostTeam;
      bowlingTeam = widget.visitorTeam;
      battingPlayers = List.from(widget.hostPlayers);
      bowlingPlayers = List.from(widget.visitorPlayers);
    } else {
      battingTeam = widget.visitorTeam;
      bowlingTeam = widget.hostTeam;
      battingPlayers = List.from(widget.visitorPlayers);
      bowlingPlayers = List.from(widget.hostPlayers);
    }

    // If toss decision was to field, swap teams
    if (widget.tossDecision == "field") {
      String temp = battingTeam;
      battingTeam = bowlingTeam;
      bowlingTeam = temp;

      List<String> tempPlayers = battingPlayers;
      battingPlayers = bowlingPlayers;
      bowlingPlayers = tempPlayers;
    }

    _initializePlayerStats();
  }

  void _initializePlayerStats() {
    for (String player in widget.hostPlayers) {
      hostPlayerStats[player] = PlayerPerformance(name: player);
    }
    for (String player in widget.visitorPlayers) {
      visitorPlayerStats[player] = PlayerPerformance(name: player);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(Duration(milliseconds: 500), () {
      _showMessage(
          "Match between ${widget.hostTeam} and ${widget.visitorTeam} is ready to begin. "
          "${widget.tossWinner == "host" ? widget.hostTeam : widget.visitorTeam} won the toss and chose to ${widget.tossDecision}.");
      _showInitialPlayersSetupDialog();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInitialPlayersSetupDialog() {
    isWaitingForNewBatsman = true;
    _showBatsmenSelectionDialog();
  }

  void updateCRR() {
    setState(() {
      if (balls > 0) {
        crr = (runs * 6) / balls;
      }
    });
  }

  void nextBall(int run) {
    if (isWaitingForNewBatsman ||
        isWaitingForNewBowler ||
        isShowingDismissalDialog) {
      _showInputRequiredDialog();
      return;
    }

    if (isFirstInnings && oversCompleted >= widget.overs ||
        !isFirstInnings &&
            (oversCompleted >= widget.overs || runs > targetRuns)) {
      if (isFirstInnings) {
        completeFirstInnings();
      } else {
        endMatch();
      }
      return;
    }

    setState(() {
      if (wide || noBall) {
        runs += run + 1;
        bowlerRuns += run + 1;
        _updateBowlerStats(bowler, run + 1, 0, 0);
        potentialMaiden = false;

        if (wide) {
          _showMessage(
              "Wide ball. ${run > 0 ? '$run runs' : 'One run'} added.");
        } else if (noBall) {
          _showMessage("No ball. ${run > 0 ? '$run runs' : 'One run'} added.");
        }
      } else {
        runs += run;
        balls++;
        bowlerBalls++;

        if (run > 0) {
          potentialMaiden = false;
        }

        if (wicket) {
          wickets++;
          bowlerWickets++;
          isShowingDismissalDialog = true;
          _showDismissalDialog();
          return;
        } else {
          if (batsman1.endsWith("*")) {
            batsman1Runs += run;
            batsman1Balls++;
            if (run == 4) batsman1Fours++;
            if (run == 6) batsman1Sixes++;

            String playerName = batsman1.substring(0, batsman1.length - 1);
            _updateBatsmanStats(
                playerName, run, 1, run == 4 ? 1 : 0, run == 6 ? 1 : 0);

            if (run == 4) {
              _showMessage("Four runs! ${playerName} hits a boundary.");
            } else if (run == 6) {
              _showMessage("Six runs! ${playerName} hits it out of the park.");
            } else if (run > 0) {
              _showMessage("$run runs scored.");
            }
          } else {
            batsman2Runs += run;
            batsman2Balls++;
            if (run == 4) batsman2Fours++;
            if (run == 6) batsman2Sixes++;
            _updateBatsmanStats(
                batsman2, run, 1, run == 4 ? 1 : 0, run == 6 ? 1 : 0);

            if (run == 4) {
              _showMessage("Four runs! $batsman2 hits a boundary.");
            } else if (run == 6) {
              _showMessage("Six runs! $batsman2 hits it out of the park.");
            } else if (run > 0) {
              _showMessage("$run runs scored.");
            }
          }

          _updateBowlerStats(bowler, run, 0, 0);
          _checkAndShowBatsmanMilestones();
        }

        if (run % 2 != 0) {
          if (batsman1.endsWith("*")) {
            batsman1 = batsman1.substring(0, batsman1.length - 1);
            batsman2 = "${batsman2}*";
          } else {
            batsman2 = batsman2.substring(0, batsman2.length - 1);
            batsman1 = "${batsman1}*";
          }
        }

        if (bowlerBalls >= 6) {
          if (potentialMaiden) {
            bowlerMaidens++;
            _updateBowlerStats(bowler, 0, 0, 1);
            _showMessage("Maiden over by $bowler!");
          }

          bowlerBalls = 0;
          oversCompleted++;
          potentialMaiden = true;
          bowlerOvers[bowler] = (bowlerOvers[bowler] ?? 0) + 1;

          _showMessage(
              "End of the over. $oversCompleted overs completed. $battingTeam is $runs for $wickets.");

          if (batsman1.endsWith("*")) {
            batsman1 = batsman1.substring(0, batsman1.length - 1);
            batsman2 = "${batsman2}*";
          } else {
            batsman2 = batsman2.substring(0, batsman2.length - 1);
            batsman1 = "${batsman1}*";
          }

          if (oversCompleted < widget.overs) {
            isWaitingForNewBowler = true;
            _showBowlerSelectionDialog();
            return;
          } else if (isFirstInnings) {
            completeFirstInnings();
          } else {
            endMatch();
          }
        }
      }
      wide = noBall = wicket = false;

      if (!isFirstInnings && runs > targetRuns) {
        _showMessage("$battingTeam has reached the target!");
        endMatch();
      }
    });
    updateCRR();
  }

  void _updateBatsmanStats(String playerName, int runsScored, int ballsFaced,
      int foursHit, int sixesHit) {
    Map<String, PlayerPerformance> teamStats =
        battingTeam == widget.hostTeam ? hostPlayerStats : visitorPlayerStats;

    if (teamStats.containsKey(playerName)) {
      PlayerPerformance current = teamStats[playerName]!;
      teamStats[playerName] = PlayerPerformance(
        name: playerName,
        runs: current.runs + runsScored,
        balls: current.balls + ballsFaced,
        fours: current.fours + foursHit,
        sixes: current.sixes + sixesHit,
        isOut: current.isOut,
        outBy: current.outBy,
        overs: current.overs,
        wickets: current.wickets,
        runsConceded: current.runsConceded,
        maidens: current.maidens,
        catches: current.catches,
        runOuts: current.runOuts,
        stumping: current.stumping,
      );
    }
  }

  void _updateBowlerStats(
      String playerName, int runsGiven, int wicketsTaken, int maidenOver) {
    Map<String, PlayerPerformance> teamStats =
        bowlingTeam == widget.hostTeam ? hostPlayerStats : visitorPlayerStats;

    if (teamStats.containsKey(playerName)) {
      PlayerPerformance current = teamStats[playerName]!;
      double newOvers = current.overs;
      if (bowlerBalls % 6 == 0 && bowlerBalls > 0) {
        newOvers = current.overs + 1.0;
      } else if (bowlerBalls > 0) {
        int completedOvers = current.overs.floor();
        newOvers = completedOvers + (bowlerBalls / 10);
      }

      teamStats[playerName] = PlayerPerformance(
        name: playerName,
        runs: current.runs,
        balls: current.balls,
        fours: current.fours,
        sixes: current.sixes,
        isOut: current.isOut,
        outBy: current.outBy,
        overs: double.parse(newOvers.toStringAsFixed(1)),
        wickets: current.wickets + wicketsTaken,
        runsConceded: current.runsConceded + runsGiven,
        maidens: current.maidens + maidenOver,
        catches: current.catches,
        runOuts: current.runOuts,
        stumping: current.stumping,
      );
    }
  }

  void _updateFieldingStats(
      String playerName, int catchesTaken, int runOutsMade, int stumpingsMade) {
    Map<String, PlayerPerformance> teamStats =
        bowlingTeam == widget.hostTeam ? hostPlayerStats : visitorPlayerStats;

    if (teamStats.containsKey(playerName)) {
      PlayerPerformance current = teamStats[playerName]!;
      teamStats[playerName] = PlayerPerformance(
        name: playerName,
        runs: current.runs,
        balls: current.balls,
        fours: current.fours,
        sixes: current.sixes,
        isOut: current.isOut,
        outBy: current.outBy,
        overs: current.overs,
        wickets: current.wickets,
        runsConceded: current.runsConceded,
        maidens: current.maidens,
        catches: current.catches + catchesTaken,
        runOuts: current.runOuts + runOutsMade,
        stumping: current.stumping + stumpingsMade,
      );
    }
  }

  void _markBatsmanOut(
      String playerName, String dismissalMethod, String fielderName) {
    Map<String, PlayerPerformance> teamStats =
        battingTeam == widget.hostTeam ? hostPlayerStats : visitorPlayerStats;

    if (teamStats.containsKey(playerName)) {
      PlayerPerformance current = teamStats[playerName]!;
      teamStats[playerName] = PlayerPerformance(
        name: playerName,
        runs: current.runs,
        balls: current.balls,
        fours: current.fours,
        sixes: current.sixes,
        isOut: true,
        outBy: dismissalMethod == "Bowled" || dismissalMethod == "LBW"
            ? bowler
            : "$dismissalMethod by $fielderName, bowled by $bowler",
        overs: current.overs,
        wickets: current.wickets,
        runsConceded: current.runsConceded,
        maidens: current.maidens,
        catches: current.catches,
        runOuts: current.runOuts,
        stumping: current.stumping,
      );
    }
  }

  void _showDismissalDialog() {
    String currentBatsman = batsman1.endsWith("*")
        ? batsman1.substring(0, batsman1.length - 1)
        : batsman2.substring(0, batsman2.length - 1);

    List<String> dismissalTypes = [
      "Bowled",
      "Caught",
      "LBW",
      "Run Out",
      "Stumped"
    ];
    dismissalType = dismissalTypes[0];
    dismissedBy = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Wicket Details"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("$currentBatsman is out!"),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Dismissal Type"),
                  value: dismissalType,
                  items: dismissalTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      dismissalType = value!;
                    });
                  },
                ),
                SizedBox(height: 10),
                if (dismissalType == "Caught" ||
                    dismissalType == "Run Out" ||
                    dismissalType == "Stumped")
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "By Player"),
                    value:
                        dismissedBy.isEmpty ? bowlingPlayers[0] : dismissedBy,
                    items: bowlingPlayers.map((player) {
                      return DropdownMenuItem(
                        value: player,
                        child: Text(player),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        dismissedBy = value!;
                      });
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _processDismissalAndContinue(currentBatsman);
                  Navigator.pop(context);
                },
                child: Text("Confirm"),
              ),
            ],
          );
        });
      },
    );
  }

  void _processDismissalAndContinue(String dismissedBatsman) {
    _updateBowlerStats(bowler, 0, 1, 0);

    if (dismissalType == "Caught") {
      _updateFieldingStats(dismissedBy, 1, 0, 0);
      _showMessage(
          "$dismissedBatsman is out! Caught by $dismissedBy, bowled by $bowler.");
    } else if (dismissalType == "Run Out") {
      _updateFieldingStats(dismissedBy, 0, 1, 0);
      _showMessage("$dismissedBatsman is out! Run out by $dismissedBy.");
    } else if (dismissalType == "Stumped") {
      _updateFieldingStats(dismissedBy, 0, 0, 1);
      _showMessage(
          "$dismissedBatsman is out! Stumped by $dismissedBy, bowled by $bowler.");
    } else {
      _showMessage("$dismissedBatsman is out! $dismissalType by $bowler.");
    }

    _markBatsmanOut(dismissedBatsman, dismissalType, dismissedBy);
    outBatsmen.add(dismissedBatsman);

    if (wickets >= 10) {
      _showMessage("All out! $battingTeam is all out for $runs.");
      if (isFirstInnings) {
        completeFirstInnings();
      } else {
        endMatch();
      }
      return;
    }

    setState(() {
      wicket = false;
      isShowingDismissalDialog = false;
      isWaitingForNewBatsman = true;

      if (batsman1.startsWith(dismissedBatsman)) {
        batsman1 = "";
      } else {
        batsman2 = "";
      }
    });

    // Show batsman selection dialog after state has been updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBatsmenSelectionDialog();
    });
  }

  void _showInputRequiredDialog() {
    String message = isWaitingForNewBatsman
        ? "Please select the next batsman before continuing."
        : isWaitingForNewBowler
            ? "Please select the next bowler before continuing."
            : "Please complete the current action before continuing.";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Selection Required"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isWaitingForNewBatsman) {
                _showBatsmenSelectionDialog();
              } else if (isWaitingForNewBowler) {
                _showBowlerSelectionDialog();
              }
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _checkAndShowBatsmanMilestones() {
    if (batsman1Runs == 50) {
      _showMessage(
          "${batsman1.endsWith("*") ? batsman1.substring(0, batsman1.length - 1) : batsman1} has scored a half century!");
    } else if (batsman1Runs == 100) {
      _showMessage(
          "${batsman1.endsWith("*") ? batsman1.substring(0, batsman1.length - 1) : batsman1} has scored a century!");
    }

    if (batsman2Runs == 50) {
      _showMessage(
          "${batsman2.endsWith("*") ? batsman2.substring(0, batsman2.length - 1) : batsman2} has scored a half century!");
    } else if (batsman2Runs == 100) {
      _showMessage(
          "${batsman2.endsWith("*") ? batsman2.substring(0, batsman2.length - 1) : batsman2} has scored a century!");
    }
  }

  void completeFirstInnings() {
    _showMessage(
        "First innings complete. $battingTeam scored $runs runs for $wickets wickets in $oversCompleted.${bowlerBalls} overs.");

    setState(() {
      targetRuns = runs + 1;
      isFirstInnings = false;
      runs = 0;
      balls = 0;
      wickets = 0;
      oversCompleted = 0;
      bowlerBalls = 0;
      batsman1 = "";
      batsman2 = "";
      bowler = "";
      batsman1Runs = 0;
      batsman2Runs = 0;
      batsman1Balls = 0;
      batsman2Balls = 0;
      batsman1Fours = 0;
      batsman1Sixes = 0;
      batsman2Fours = 0;
      batsman2Sixes = 0;
      bowlerRuns = 0;
      bowlerWickets = 0;
      bowlerMaidens = 0;
      crr = 0.0;
      potentialMaiden = true;

      String temp = battingTeam;
      battingTeam = bowlingTeam;
      bowlingTeam = temp;

      List<String> tempPlayers = battingPlayers;
      battingPlayers = bowlingPlayers;
      bowlingPlayers = tempPlayers;

      outBatsmen.clear();
      bowlerOvers.clear();
      bowlersUsed.clear();

      isWaitingForNewBatsman = true;
      isWaitingForNewBowler = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("First Innings Complete"),
        content: Text("$bowlingTeam needs $targetRuns runs to win."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBatsmenSelectionDialog();
              _showMessage(
                  "Second innings starting. $battingTeam needs to score $targetRuns runs to win.");
            },
            child: Text("Start Second Innings"),
          ),
        ],
      ),
    );
  }

  void _showBatsmenSelectionDialog() {
    List<String> availableBatsmen = battingPlayers.where((player) {
      bool isCurrentBatsman1 = batsman1.isNotEmpty &&
          batsman1.substring(
                  0,
                  batsman1.endsWith("*")
                      ? batsman1.length - 1
                      : batsman1.length) ==
              player;
      bool isCurrentBatsman2 = batsman2.isNotEmpty &&
          batsman2.substring(
                  0,
                  batsman2.endsWith("*")
                      ? batsman2.length - 1
                      : batsman2.length) ==
              player;
      return !outBatsmen.contains(player) &&
          !isCurrentBatsman1 &&
          !isCurrentBatsman2;
    }).toList();

    if (availableBatsmen.isEmpty) {
      setState(() {
        isWaitingForNewBatsman = false;
      });
      _showMessage("No more batsmen available. All out!");
      if (isFirstInnings) {
        completeFirstInnings();
      } else {
        endMatch();
      }
      return;
    }

    String? selectedBatsman;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Select Batsman for $battingTeam"),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Available Batsmen:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableBatsmen.length,
                      itemBuilder: (context, index) {
                        return RadioListTile<String>(
                          title: Text(availableBatsmen[index]),
                          value: availableBatsmen[index],
                          groupValue: selectedBatsman,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedBatsman = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (selectedBatsman == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a batsman")),
                    );
                    return;
                  }

                  setState(() {
                    if (batsman1.isEmpty) {
                      batsman1 = "$selectedBatsman*";
                      batsman1Runs = 0;
                      batsman1Balls = 0;
                      batsman1Fours = 0;
                      batsman1Sixes = 0;
                    } else if (batsman2.isEmpty) {
                      batsman2 = "$selectedBatsman";
                      batsman2Runs = 0;
                      batsman2Balls = 0;
                      batsman2Fours = 0;
                      batsman2Sixes = 0;
                    }
                    isWaitingForNewBatsman = false;
                    _showMessage("$selectedBatsman comes to the crease.");
                  });

                  Navigator.pop(context);

                  // If we still need another batsman (after a wicket), show the dialog again
                  if ((batsman1.isEmpty || batsman2.isEmpty) && wickets < 10) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showBatsmenSelectionDialog();
                    });
                  } else if (bowler.isEmpty) {
                    isWaitingForNewBowler = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showBowlerSelectionDialog();
                    });
                  }
                },
                child: Text("Confirm"),
              ),
            ],
          );
        });
      },
    );
  }

  void _showBowlerSelectionDialog() {
    if (bowlersUsed.length >= 5) {
      _showBowlerSelectionWithRestrictions(bowlersUsed.toList());
    } else {
      _showBowlerSelectionWithRestrictions(bowlingPlayers);
    }
  }

  void _showBowlerSelectionWithRestrictions(List<String> eligibleBowlers) {
    String? selectedBowler;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Select Bowler for $bowlingTeam"),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Eligible Bowlers:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: eligibleBowlers.length,
                      itemBuilder: (context, index) {
                        String bowlerName = eligibleBowlers[index];
                        int oversBowled = bowlerOvers[bowlerName] ?? 0;
                        return RadioListTile<String>(
                          title: Text("$bowlerName (${oversBowled} overs)"),
                          value: bowlerName,
                          groupValue: selectedBowler,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedBowler = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (selectedBowler == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a bowler")),
                    );
                    return;
                  }

                  setState(() {
                    bowler = selectedBowler!;
                    bowlerRuns = 0;
                    bowlerWickets = 0;
                    bowlerMaidens = 0;
                    bowlersUsed.add(bowler);
                    isWaitingForNewBowler = false;
                    potentialMaiden = true;

                    if (!isMatchStarted) {
                      isMatchStarted = true;
                      _showMessage(
                          "Match has begun! $bowler will bowl to ${batsman1.endsWith('*') ? batsman1.substring(0, batsman1.length - 1) : batsman2}");
                    } else {
                      _showMessage("$bowler starts a new over.");
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text("Confirm"),
              ),
            ],
          );
        });
      },
    );
  }

  void endMatch() {
    String winner;
    int hostScore, visitorScore, hostWickets, visitorWickets;
    double hostOvers, visitorOvers;

    if (isFirstInnings) {
      if (battingTeam == widget.hostTeam) {
        winner = widget.visitorTeam;
        hostScore = runs;
        visitorScore = 0;
        hostWickets = wickets;
        visitorWickets = 0;
        hostOvers = oversCompleted + (bowlerBalls / 10);
        visitorOvers = 0.0;
      } else {
        winner = widget.hostTeam;
        hostScore = 0;
        visitorScore = runs;
        hostWickets = 0;
        visitorWickets = wickets;
        hostOvers = 0.0;
        visitorOvers = oversCompleted + (bowlerBalls / 10);
      }
    } else {
      if (battingTeam == widget.hostTeam) {
        hostScore = runs;
        visitorScore = targetRuns - 1;
        hostWickets = wickets;
        visitorWickets = 10;
        hostOvers = oversCompleted + (bowlerBalls / 10);
        visitorOvers = widget.overs.toDouble();
        winner = runs >= targetRuns ? widget.hostTeam : widget.visitorTeam;
      } else {
        hostScore = targetRuns - 1;
        visitorScore = runs;
        hostWickets = 10;
        visitorWickets = wickets;
        hostOvers = widget.overs.toDouble();
        visitorOvers = oversCompleted + (bowlerBalls / 10);
        winner = runs >= targetRuns ? widget.visitorTeam : widget.hostTeam;
      }
    }

    List<PlayerPerformance> hostPlayerPerformances = [];
    List<PlayerPerformance> visitorPlayerPerformances = [];

    hostPlayerStats.forEach((name, stats) {
      hostPlayerPerformances.add(stats);
    });

    visitorPlayerStats.forEach((name, stats) {
      visitorPlayerPerformances.add(stats);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Match Complete"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$winner has won the match!"),
            SizedBox(height: 10),
            Text(
                "${widget.hostTeam}: $hostScore/${hostWickets < 10 ? hostWickets : 'all out'} (${hostOvers.toStringAsFixed(1)} overs)"),
            Text(
                "${widget.visitorTeam}: $visitorScore/${visitorWickets < 10 ? visitorWickets : 'all out'} (${visitorOvers.toStringAsFixed(1)} overs)"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onMatchEnd(
                  winner,
                  hostScore,
                  visitorScore,
                  hostWickets,
                  visitorWickets,
                  hostOvers,
                  visitorOvers,
                  hostPlayerPerformances,
                  visitorPlayerPerformances);
            },
            child: Text("View Match Summary"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int runsNeeded = isFirstInnings ? 0 : targetRuns - runs;
    int ballsRemaining =
        (widget.overs * 6) - (oversCompleted * 6 + bowlerBalls);
    double rr = runs > 0 && balls > 0 ? (runs / balls) * 6 : 0.0;
    double rrr = runsNeeded > 0 && ballsRemaining > 0
        ? (runsNeeded / ballsRemaining) * 6
        : 0.0;

    String formattedOvers =
        oversCompleted.toString() + "." + bowlerBalls.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.hostTeam} vs ${widget.visitorTeam}"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        isFirstInnings ? "First Innings" : "Second Innings",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "$battingTeam: $runs/$wickets",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Overs: $formattedOvers / ${widget.overs}",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text("CRR: ${crr.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 16)),
                      if (!isFirstInnings) ...[
                        Text(
                          "Target: $targetRuns runs (${rrr.toStringAsFixed(2)} RRR)",
                          style: TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                        Text(
                          "Need $runsNeeded runs from $ballsRemaining balls",
                          style: TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Batsmen",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                        },
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        children: [
                          TableRow(
                            decoration:
                                BoxDecoration(color: Colors.grey.shade200),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Batsman",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("R",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("B",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("4s",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("6s",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman1.isEmpty ? "-" : batsman1),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman1.isEmpty
                                    ? "-"
                                    : batsman1Runs.toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman1.isEmpty
                                    ? "-"
                                    : batsman1Balls.toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman1.isEmpty
                                    ? "-"
                                    : batsman1Fours.toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman1.isEmpty
                                    ? "-"
                                    : batsman1Sixes.toString()),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman2.isEmpty ? "-" : batsman2),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman2.isEmpty
                                    ? "-"
                                    : batsman2Runs.toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman2.isEmpty
                                    ? "-"
                                    : batsman2Balls.toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman2.isEmpty
                                    ? "-"
                                    : batsman2Fours.toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(batsman2.isEmpty
                                    ? "-"
                                    : batsman2Sixes.toString()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bowler",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(bowler.isEmpty ? "No bowler selected" : bowler),
                          Text(bowler.isEmpty
                              ? ""
                              : "$bowlerWickets/$bowlerRuns (${(bowlerOvers[bowler] ?? 0)}.${bowlerBalls} overs)")
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (int run in runOptions)
                    ElevatedButton(
                      onPressed: isShowingDismissalDialog ||
                              isWaitingForNewBatsman ||
                              isWaitingForNewBowler
                          ? null
                          : () => nextBall(run),
                      child: Text("$run", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: isShowingDismissalDialog ||
                            isWaitingForNewBatsman ||
                            isWaitingForNewBowler
                        ? null
                        : () {
                            setState(() {
                              wide = true;
                            });
                          },
                    child: Text("Wide"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: wide ? Colors.blue : Colors.grey),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: isShowingDismissalDialog ||
                            isWaitingForNewBatsman ||
                            isWaitingForNewBowler
                        ? null
                        : () {
                            setState(() {
                              noBall = true;
                            });
                          },
                    child: Text("No Ball"),
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: noBall ? Colors.blue : Colors.grey),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: isShowingDismissalDialog ||
                            isWaitingForNewBatsman ||
                            isWaitingForNewBowler
                        ? null
                        : () {
                            setState(() {
                              wicket = true;
                            });
                          },
                    child: Text("Wicket"),
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: wicket ? Colors.blue : Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
