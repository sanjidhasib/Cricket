import 'package:flutter/material.dart';

abstract class VoiceAnnouncer {
  Future<void> speak(String text);
  Future<void> stop();
  bool get isEnabled;
  set isEnabled(bool value);
}

class SnackBarAnnouncer implements VoiceAnnouncer {
  final BuildContext context;
  bool _isEnabled = true;

  SnackBarAnnouncer(this.context);

  @override
  Future<void> speak(String text) async {
    if (_isEnabled) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return Future.value();
  }

  @override
  Future<void> stop() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    return Future.value();
  }

  @override
  bool get isEnabled => _isEnabled;

  @override
  set isEnabled(bool value) {
    _isEnabled = value;
  }
}

class MatchPage extends StatefulWidget {
  final String hostTeam;
  final String visitorTeam;
  final int overs;
  final String tossWinner;
  final Function(String winner, int hostScore, int visitorScore) onMatchEnd;

  const MatchPage({
    super.key,
    required this.hostTeam,
    required this.visitorTeam,
    required this.overs,
    required this.tossWinner,
    required this.onMatchEnd,
  });

  @override
  MatchPageState createState() => MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  int runs = 0, balls = 0, wickets = 0, oversCompleted = 0, bowlerBalls = 0;
  double crr = 0.0;
  String batsman1 = ""; // Empty initially
  String batsman2 = ""; // Empty initially
  String bowler = ""; // Empty initially
  int batsman1Runs = 0, batsman2Runs = 0, batsman1Balls = 0, batsman2Balls = 0;
  int bowlerRuns = 0, bowlerWickets = 0;
  bool wide = false, noBall = false, wicket = false;
  List<int> runOptions = [0, 1, 2, 3, 4, 6];
  bool isFirstInnings = true;
  int targetRuns = 0;
  int secondInningsScore = 0;
  String battingTeam = "";
  String bowlingTeam = "";
  late VoiceAnnouncer announcer;
  bool get isSpeechEnabled => announcer.isEnabled;
  set isSpeechEnabled(bool value) => announcer.isEnabled = value;

  // Add flags to track if we're waiting for player entries
  bool isWaitingForNewBatsman =
      true; // Start with true to require initial entry
  bool isWaitingForNewBowler = true; // Start with true to require initial entry
  bool isMatchStarted = false; // Flag to track if match setup is complete

  @override
  void initState() {
    super.initState();
    // Determine who bats first based on toss
    if (widget.tossWinner == "host") {
      battingTeam = widget.hostTeam;
      bowlingTeam = widget.visitorTeam;
    } else {
      battingTeam = widget.visitorTeam;
      bowlingTeam = widget.hostTeam;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize announcer
    announcer = SnackBarAnnouncer(context);

    // Announce match setup and prompt for initial players
    Future.delayed(Duration(milliseconds: 500), () {
      _speak(
          "Match between ${widget.hostTeam} and ${widget.visitorTeam} is ready to begin. $battingTeam won the toss and will bat first.");

      // Show dialog to enter initial players
      _showInitialPlayersSetupDialog();
    });
  }

  void _showInitialPlayersSetupDialog() {
    // First show dialog for initial batsmen
    _showInitialBatsmenDialog();
  }

  @override
  void dispose() {
    announcer.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await announcer.speak(text);
  }

  void updateCRR() {
    setState(() {
      if (balls > 0) {
        crr = (runs * 6) / balls;
      }
    });
  }

  void nextBall(int run) {
    // If waiting for new player entries, don't allow the game to continue
    if (isWaitingForNewBatsman || isWaitingForNewBowler) {
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

        // Announce wide or no ball
        if (wide) {
          _speak("Wide ball. ${run > 0 ? '$run runs' : 'One run'} added.");
        } else if (noBall) {
          _speak("No ball. ${run > 0 ? '$run runs' : 'One run'} added.");
        }
      } else {
        runs += run;
        balls++;
        bowlerBalls++;

        if (wicket) {
          wickets++;
          bowlerWickets++;
          wicket = false;

          // Announce wicket
          String currentBatsman = batsman1.endsWith("*")
              ? batsman1.substring(0, batsman1.length - 1)
              : batsman2.substring(0, batsman2.length - 1);
          _speak(
              "Wicket! $currentBatsman is out. Bowled by $bowler. $battingTeam is $runs for $wickets.");

          if (wickets >= 10) {
            _speak("All out! $battingTeam is all out for $runs.");
            if (isFirstInnings) {
              completeFirstInnings();
            } else {
              endMatch();
            }
            return;
          }

          // Set waiting flag and show dialog
          isWaitingForNewBatsman = true;
          _showBatsmanDialog();
          return; // Early return to prevent further processing
        } else {
          // Update batsman stats
          if (batsman1.endsWith("*")) {
            batsman1Runs += run;
            batsman1Balls++;
            // Announce significant runs for the batsman
            if (run == 4) {
              _speak(
                  "Four runs! ${batsman1.substring(0, batsman1.length - 1)} hits a boundary.");
            } else if (run == 6) {
              _speak(
                  "Six runs! ${batsman1.substring(0, batsman1.length - 1)} hits it out of the park.");
            } else if (run > 0) {
              _speak("$run runs scored.");
            }
          } else {
            batsman2Runs += run;
            batsman2Balls++;
            // Announce significant runs for the batsman
            if (run == 4) {
              _speak("Four runs! $batsman2 hits a boundary.");
            } else if (run == 6) {
              _speak("Six runs! $batsman2 hits it out of the park.");
            } else if (run > 0) {
              _speak("$run runs scored.");
            }
          }

          // Announce batsman milestones
          _checkAndAnnounceBatsmanMilestones();
        }

        if (run % 2 != 0) {
          // Swap batsmen
          setState(() {
            if (batsman1.endsWith("*")) {
              batsman1 = batsman1.substring(0, batsman1.length - 1);
              batsman2 = "${batsman2}*";
            } else {
              batsman2 = batsman2.substring(0, batsman2.length - 1);
              batsman1 = "${batsman1}*";
            }
          });
        }

        if (bowlerBalls >= 6) {
          bowlerBalls = 0;
          oversCompleted++;

          // Announce over completion
          _speak(
              "End of the over. $oversCompleted overs completed. $battingTeam is $runs for $wickets.");

          // Swap batsmen at the end of over
          setState(() {
            if (batsman1.endsWith("*")) {
              batsman1 = batsman1.substring(0, batsman1.length - 1);
              batsman2 = "${batsman2}*";
            } else {
              batsman2 = batsman2.substring(0, batsman2.length - 1);
              batsman1 = "${batsman1}*";
            }
          });

          if (oversCompleted < widget.overs) {
            // Set waiting flag and show dialog
            isWaitingForNewBowler = true;
            _showBowlerDialog();
            return; // Early return to prevent further processing
          } else if (isFirstInnings) {
            completeFirstInnings();
          } else {
            endMatch();
          }
        }
      }
      wide = noBall = false;

      // Check if second innings is over
      if (!isFirstInnings && runs > targetRuns) {
        _speak("$battingTeam has reached the target!");
        endMatch();
      }
    });
    updateCRR();
  }

  void _showInputRequiredDialog() {
    String message = isWaitingForNewBatsman
        ? "Please enter the new batsman's name before continuing."
        : "Please enter the new bowler's name before continuing.";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Input Required"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Show the appropriate dialog again
              if (isWaitingForNewBatsman) {
                _showBatsmanDialog();
              } else {
                _showBowlerDialog();
              }
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _checkAndAnnounceBatsmanMilestones() {
    // Check for batsman1 milestones
    if (batsman1Runs == 50) {
      _speak(
          "${batsman1.endsWith("*") ? batsman1.substring(0, batsman1.length - 1) : batsman1} has scored a half century!");
    } else if (batsman1Runs == 100) {
      _speak(
          "${batsman1.endsWith("*") ? batsman1.substring(0, batsman1.length - 1) : batsman1} has scored a century!");
    }

    // Check for batsman2 milestones
    if (batsman2Runs == 50) {
      _speak(
          "${batsman2.endsWith("*") ? batsman2.substring(0, batsman2.length - 1) : batsman2} has scored a half century!");
    } else if (batsman2Runs == 100) {
      _speak(
          "${batsman2.endsWith("*") ? batsman2.substring(0, batsman2.length - 1) : batsman2} has scored a century!");
    }
  }

  void completeFirstInnings() {
    _speak(
        "First innings complete. $battingTeam scored $runs runs for $wickets wickets in $oversCompleted.${bowlerBalls} overs.");

    setState(() {
      targetRuns = runs + 1;
      isFirstInnings = false;
      runs = 0;
      balls = 0;
      wickets = 0;
      oversCompleted = 0;
      bowlerBalls = 0;
      batsman1 = ""; // Clear batsmen
      batsman2 = "";
      bowler = ""; // Clear bowler
      batsman1Runs = 0;
      batsman2Runs = 0;
      batsman1Balls = 0;
      batsman2Balls = 0;
      bowlerRuns = 0;
      bowlerWickets = 0;
      crr = 0.0;

      // Swap teams
      String temp = battingTeam;
      battingTeam = bowlingTeam;
      bowlingTeam = temp;

      // Set waiting flags for second innings
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
              // Start second innings setup
              _showInitialBatsmenDialog();
              // Announce second innings
              _speak(
                  "Second innings starting. $battingTeam needs to score $targetRuns runs to win.");
            },
            child: Text("Start Second Innings"),
          ),
        ],
      ),
    );
  }

  void _showInitialBatsmenDialog() {
    TextEditingController batsman1Controller = TextEditingController();
    TextEditingController batsman2Controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Opening Batsmen for $battingTeam"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: batsman1Controller,
                decoration:
                    const InputDecoration(hintText: "Enter first batsman name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: batsman2Controller,
                decoration: const InputDecoration(
                    hintText: "Enter second batsman name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (batsman1Controller.text.isEmpty ||
                    batsman2Controller.text.isEmpty) {
                  // Show error if fields are empty
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please enter both batsmen names")));
                } else {
                  setState(() {
                    batsman1 = "${batsman1Controller.text}*";
                    batsman2 = batsman2Controller.text;
                    isWaitingForNewBatsman = false;

                    // Announce new batsmen
                    _speak(
                        "${batsman1Controller.text} and ${batsman2Controller.text} are opening the batting for $battingTeam.");
                  });
                  Navigator.pop(context);

                  // Now get the opening bowler
                  _showInitialBowlerDialog();
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showInitialBowlerDialog() {
    TextEditingController bowlerController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Opening Bowler for $bowlingTeam"),
          content: TextField(
            controller: bowlerController,
            decoration: const InputDecoration(hintText: "Enter bowler name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (bowlerController.text.isEmpty) {
                  // Show error if field is empty
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please enter a bowler name")));
                } else {
                  setState(() {
                    bowler = bowlerController.text;
                    isWaitingForNewBowler = false;

                    // Announce opening bowler
                    _speak(
                        "${bowlerController.text} will open the bowling for $bowlingTeam.");

                    // Mark match as started
                    if (!isMatchStarted) {
                      isMatchStarted = true;
                      // Announce match start
                      Future.delayed(Duration(milliseconds: 500), () {
                        _speak("Match has begun!");
                      });
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showBatsmanDialog() {
    TextEditingController batsmanController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
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
                if (batsmanController.text.isEmpty) {
                  // Show error if field is empty
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please enter a batsman name")));
                } else {
                  setState(() {
                    if (batsman1.endsWith("*")) {
                      batsman1 = "${batsmanController.text}*";
                      batsman1Runs = 0;
                      batsman1Balls = 0;
                    } else {
                      batsman2 = "${batsmanController.text}*";
                      batsman2Runs = 0;
                      batsman2Balls = 0;
                    }
                    // Reset the waiting flag
                    isWaitingForNewBatsman = false;
                    // Announce new batsman
                    _speak(
                        "New batsman ${batsmanController.text} is at the crease.");
                  });
                  Navigator.pop(context);
                }
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
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
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
                if (bowlerController.text.isEmpty) {
                  // Show error if field is empty
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please enter a bowler name")));
                } else {
                  setState(() {
                    bowler = bowlerController.text;
                    bowlerRuns = 0;
                    bowlerWickets = 0;
                    // Reset the waiting flag
                    isWaitingForNewBowler = false;
                    // Announce new bowler
                    _speak("${bowlerController.text} is the new bowler.");
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text("$battingTeam: $runs/$wickets"),
            subtitle: Text(
                "Overs: $oversCompleted.$bowlerBalls  |  CRR: ${crr.toStringAsFixed(2)}"),
          ),
          if (!isFirstInnings)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  "Target: $targetRuns runs (${targetRuns - runs} more needed)"),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Widget> stats) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(title),
            tileColor: Colors.blueAccent,
            textColor: Colors.white,
          ),
          ...stats,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildExtrasSelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: isWaitingForNewBatsman || isWaitingForNewBowler
                  ? null // Disable button if waiting for player input
                  : () {
                      setState(() {
                        wide = true;
                        nextBall(0); // Wide ball adds 1 run
                      });
                    },
              child: const Text("Wide"),
            ),
            ElevatedButton(
              onPressed: isWaitingForNewBatsman || isWaitingForNewBowler
                  ? null // Disable button if waiting for player input
                  : () {
                      setState(() {
                        noBall = true;
                        nextBall(0); // No ball adds 1 run
                      });
                    },
              child: const Text("No Ball"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: isWaitingForNewBatsman || isWaitingForNewBowler
              ? null // Disable button if waiting for player input
              : () {
                  setState(() {
                    wicket = true;
                    nextBall(0); // Wicket taken on this ball
                  });
                },
          child: const Text("Wicket"),
        ),
      ],
    );
  }

  Widget _buildRunButtons() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: runOptions.map((run) {
        return ElevatedButton(
          onPressed: isWaitingForNewBatsman || isWaitingForNewBowler
              ? null // Disable button if waiting for player input
              : () {
                  nextBall(run); // Run value selected on this button click
                },
          child: Text(run.toString()),
        );
      }).toList(),
    );
  }

  void endMatch() {
    String winner;
    int hostFinalScore, visitorFinalScore;

    if (isFirstInnings) {
      // If match ends during first innings (e.g., all out)
      if (battingTeam == widget.hostTeam) {
        winner = widget.visitorTeam;
        hostFinalScore = runs;
        visitorFinalScore = 0;
      } else {
        winner = widget.hostTeam;
        hostFinalScore = 0;
        visitorFinalScore = runs;
      }
    } else {
      // Second innings
      if (runs >= targetRuns) {
        winner = battingTeam;
      } else {
        winner = bowlingTeam;
      }

      if (battingTeam == widget.hostTeam) {
        hostFinalScore = runs;
        visitorFinalScore = targetRuns - 1;
      } else {
        hostFinalScore = targetRuns - 1;
        visitorFinalScore = runs;
      }
    }

    // Announce match result
    int winningMargin;
    if (isFirstInnings) {
      _speak("Match ended. $winner wins the match.");
    } else if (winner == battingTeam) {
      winningMargin = 10 - wickets;
      _speak("$winner wins by $winningMargin wickets!");
    } else {
      winningMargin = targetRuns - runs - 1;
      _speak("$winner wins by $winningMargin runs!");
    }

    widget.onMatchEnd(winner, hostFinalScore, visitorFinalScore);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.hostTeam} vs ${widget.visitorTeam}"),
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          // Voice toggle button
          IconButton(
            icon: Icon(isSpeechEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                isSpeechEnabled = !isSpeechEnabled;
                if (isSpeechEnabled) {
                  _speak("Commentary enabled");
                }
              });
            },
            tooltip:
                isSpeechEnabled ? "Disable Commentary" : "Enable Commentary",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildScoreCard(),
              const SizedBox(height: 10),
              _buildStatsCard("Batsman Stats", [
                _buildStatRow(batsman1.isEmpty ? "Batsman 1" : batsman1,
                    batsman1.isEmpty ? "-" : "$batsman1Runs ($batsman1Balls)"),
                _buildStatRow(batsman2.isEmpty ? "Batsman 2" : batsman2,
                    batsman2.isEmpty ? "-" : "$batsman2Runs ($batsman2Balls)"),
              ]),
              _buildStatsCard("Bowler Stats", [
                _buildStatRow("Bowler", bowler.isEmpty ? "-" : bowler),
                _buildStatRow(
                    "Runs Given", bowler.isEmpty ? "-" : "$bowlerRuns"),
                _buildStatRow(
                    "Wickets", bowler.isEmpty ? "-" : "$bowlerWickets"),
              ]),
              const SizedBox(height: 10),
              if (isWaitingForNewBatsman || isWaitingForNewBowler)
                Card(
                  color: Colors.amber.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      !isMatchStarted
                          ? "Please enter player names to start the match"
                          : isWaitingForNewBatsman
                              ? "Please enter the new batsman's name"
                              : "Please enter the new bowler's name",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              _buildExtrasSelection(),
              const SizedBox(height: 10),
              _buildRunButtons(),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: isWaitingForNewBatsman || isWaitingForNewBowler
                    ? null // Disable button if waiting for player input
                    : endMatch,
                child: const Text("End Match",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
