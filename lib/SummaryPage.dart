import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'main.dart';
import 'match_setup_page.dart';
import 'player_performance.dart';

class SummaryPage extends StatefulWidget {
  final String winner;
  final String hostTeam;
  final String visitorTeam;
  final int hostScore;
  final int visitorScore;
  final int hostWickets;
  final int visitorWickets;
  final double hostOvers;
  final double visitorOvers;
  final List<PlayerPerformance> hostPlayers;
  final List<PlayerPerformance> visitorPlayers;
  final String matchDate;
  final String venue;

  const SummaryPage({
    required this.winner,
    required this.hostTeam,
    required this.visitorTeam,
    required this.hostScore,
    required this.visitorScore,
    this.hostWickets = 0,
    this.visitorWickets = 0,
    this.hostOvers = 0.0,
    this.visitorOvers = 0.0,
    this.hostPlayers = const [],
    this.visitorPlayers = const [],
    this.matchDate = 'Today',
    this.venue = 'Home Ground',
  });

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late PlayerPerformance playerOfMatch;

  @override
  void initState() {
    super.initState();
    _determinePlayerOfTheMatch();
  }

  void _determinePlayerOfTheMatch() {
    int highestImpact = 0;
    PlayerPerformance? bestPlayer;

    for (var player in widget.hostPlayers) {
      int impact = player.runs + (player.wickets * 20);
      if (impact > highestImpact) {
        highestImpact = impact;
        bestPlayer = player;
      }
    }

    for (var player in widget.visitorPlayers) {
      int impact = player.runs + (player.wickets * 20);
      if (impact > highestImpact) {
        highestImpact = impact;
        bestPlayer = player;
      }
    }

    playerOfMatch =
        bestPlayer ?? PlayerPerformance(name: "No outstanding performer");
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    // Add first page with match overview
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(),
              pw.SizedBox(height: 20),
              _buildPdfMatchResult(),
              pw.SizedBox(height: 20),
              _buildPdfScorecard(),
              pw.SizedBox(height: 20),
              _buildPdfPlayerOfMatch(),
            ],
          );
        },
      ),
    );

    // Add host team stats page
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(showFullHeader: false),
              pw.SizedBox(height: 20),
              _buildPdfTeamStats(widget.hostTeam, widget.hostPlayers),
            ],
          );
        },
      ),
    );

    // Add visitor team stats page
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(showFullHeader: false),
              pw.SizedBox(height: 20),
              _buildPdfTeamStats(widget.visitorTeam, widget.visitorPlayers),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  pw.Widget _buildPdfHeader({bool showFullHeader = true}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          "${widget.hostTeam} vs ${widget.visitorTeam}",
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        if (showFullHeader) ...[
          pw.Text(widget.matchDate),
          pw.Text(widget.venue),
        ],
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildPdfMatchResult() {
    String winningMargin = _calculateWinningMargin();
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            "${widget.winner} won by $winningMargin",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfScorecard() {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            _buildPdfHeaderCell('Team'),
            _buildPdfHeaderCell('Score'),
          ],
        ),
        pw.TableRow(
          children: [
            _buildPdfCell(widget.hostTeam),
            _buildPdfCell(
                "${widget.hostScore}/${widget.hostWickets} (${widget.hostOvers.toStringAsFixed(1)} ov)"),
          ],
        ),
        pw.TableRow(
          children: [
            _buildPdfCell(widget.visitorTeam),
            _buildPdfCell(
                "${widget.visitorScore}/${widget.visitorWickets} (${widget.visitorOvers.toStringAsFixed(1)} ov)"),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfPlayerOfMatch() {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8.0),
      child: pw.Column(
        children: [
          pw.Text(
            "PLAYER OF THE MATCH",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(playerOfMatch.name, style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 4),
          if (playerOfMatch.runs > 0)
            pw.Text(
                "${playerOfMatch.runs} runs (${playerOfMatch.balls} balls)"),
          if (playerOfMatch.wickets > 0)
            pw.Text("${playerOfMatch.wickets} wickets"),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTeamStats(
      String teamName, List<PlayerPerformance> players) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          teamName,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text("BATTING", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        _buildPdfBattingTable(players),
        pw.SizedBox(height: 8),
        pw.Text("BOWLING", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        _buildPdfBowlingTable(players),
        pw.SizedBox(height: 8),
        pw.Text("FIELDING",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        _buildPdfFieldingTable(players),
      ],
    );
  }

  pw.Widget _buildPdfBattingTable(List<PlayerPerformance> players) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            _buildPdfHeaderCell('Batsman'),
            _buildPdfHeaderCell('R'),
            _buildPdfHeaderCell('B'),
            _buildPdfHeaderCell('4s'),
            _buildPdfHeaderCell('6s'),
            _buildPdfHeaderCell('SR'),
          ],
        ),
        ...players
            .where((player) => player.balls > 0)
            .map((player) => pw.TableRow(
                  children: [
                    _buildPdfCell(player.name),
                    _buildPdfCell(player.runs.toString()),
                    _buildPdfCell(player.balls.toString()),
                    _buildPdfCell(player.fours.toString()),
                    _buildPdfCell(player.sixes.toString()),
                    _buildPdfCell(player.strikeRate.toStringAsFixed(1)),
                  ],
                ))
            .toList(),
      ],
    );
  }

  pw.Widget _buildPdfBowlingTable(List<PlayerPerformance> players) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            _buildPdfHeaderCell('Bowler'),
            _buildPdfHeaderCell('O'),
            _buildPdfHeaderCell('M'),
            _buildPdfHeaderCell('R'),
            _buildPdfHeaderCell('W'),
            _buildPdfHeaderCell('Econ'),
          ],
        ),
        ...players
            .where((player) => player.overs > 0)
            .map((player) => pw.TableRow(
                  children: [
                    _buildPdfCell(player.name),
                    _buildPdfCell(player.overs.toStringAsFixed(1)),
                    _buildPdfCell(player.maidens.toString()),
                    _buildPdfCell(player.runsConceded.toString()),
                    _buildPdfCell(player.wickets.toString()),
                    _buildPdfCell(player.economy.toStringAsFixed(1)),
                  ],
                ))
            .toList(),
      ],
    );
  }

  pw.Widget _buildPdfFieldingTable(List<PlayerPerformance> players) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            _buildPdfHeaderCell('Player'),
            _buildPdfHeaderCell('Catches'),
            _buildPdfHeaderCell('Run Outs'),
            _buildPdfHeaderCell('Stumping'),
          ],
        ),
        ...players
            .where((player) =>
                player.catches > 0 || player.runOuts > 0 || player.stumping > 0)
            .map((player) => pw.TableRow(
                  children: [
                    _buildPdfCell(player.name),
                    _buildPdfCell(player.catches.toString()),
                    _buildPdfCell(player.runOuts.toString()),
                    _buildPdfCell(player.stumping.toString()),
                  ],
                ))
            .toList(),
      ],
    );
  }

  pw.Widget _buildPdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4.0),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _buildPdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4.0),
      child: pw.Text(text),
    );
  }

  String _calculateWinningMargin() {
    if (widget.winner == widget.hostTeam) {
      if (widget.hostScore > widget.visitorScore) {
        return '${widget.hostScore - widget.visitorScore} runs';
      } else {
        return '${10 - widget.hostWickets} wickets';
      }
    } else {
      if (widget.visitorScore > widget.hostScore) {
        return '${widget.visitorScore - widget.hostScore} runs';
      } else {
        return '${10 - widget.visitorWickets} wickets';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Match Summary"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: "Export to PDF",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMatchHeader(),
              SizedBox(height: 16),
              _buildMatchResultCard(),
              SizedBox(height: 16),
              _buildScorecardCard(),
              SizedBox(height: 16),
              _buildPlayerOfMatchCard(),
              SizedBox(height: 16),
              _buildTeamStatsSection(widget.hostTeam, widget.hostPlayers),
              SizedBox(height: 16),
              _buildTeamStatsSection(widget.visitorTeam, widget.visitorPlayers),
              SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchHeader() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 8,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              "${widget.hostTeam} vs ${widget.visitorTeam}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              widget.matchDate,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              widget.venue,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchResultCard() {
    String winningMargin = _calculateWinningMargin();
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.green.shade200, width: 2),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "${widget.winner} won by $winningMargin",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "SCOREBOARD",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Divider(),
            _buildTeamScoreRow(
              widget.hostTeam,
              widget.hostScore,
              widget.hostWickets,
              widget.hostOvers,
            ),
            SizedBox(height: 8),
            _buildTeamScoreRow(
              widget.visitorTeam,
              widget.visitorScore,
              widget.visitorWickets,
              widget.visitorOvers,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScoreRow(
      String teamName, int score, int wickets, double overs) {
    final bool isWinner = teamName == widget.winner;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              if (isWinner)
                Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  teamName,
                  style: TextStyle(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    color: isWinner ? Colors.green.shade800 : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: Text(
            "$score/${wickets < 10 ? wickets : 'all out'} (${overs.toStringAsFixed(1)} ov)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerOfMatchCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.amber.shade200, width: 2),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "PLAYER OF THE MATCH",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                playerOfMatch.name.isNotEmpty
                    ? playerOfMatch.name.substring(0, 1)
                    : "?",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Text(
              playerOfMatch.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (playerOfMatch.runs > 0)
                  _buildStatChip(
                      "${playerOfMatch.runs} runs (${playerOfMatch.balls} balls)"),
                if (playerOfMatch.wickets > 0)
                  _buildStatChip("${playerOfMatch.wickets} wickets"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.amber.shade100,
    );
  }

  Widget _buildTeamStatsSection(
      String teamName, List<PlayerPerformance> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            teamName.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        _buildBattingStats(players),
        SizedBox(height: 16),
        _buildBowlingStats(players),
        SizedBox(height: 16),
        _buildFieldingStats(players),
      ],
    );
  }

  Widget _buildBattingStats(List<PlayerPerformance> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("BATTING"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 12,
            columns: [
              DataColumn(label: Text('BATSMAN')),
              DataColumn(label: Text('R')),
              DataColumn(label: Text('B')),
              DataColumn(label: Text('4s')),
              DataColumn(label: Text('6s')),
              DataColumn(label: Text('SR')),
            ],
            rows: players.isNotEmpty
                ? players
                    .where((player) => player.balls > 0)
                    .map((player) => DataRow(
                          cells: [
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(player.name),
                                  if (player.isOut && player.outBy.isNotEmpty)
                                    Text(
                                      player.outBy,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text('${player.runs}')),
                            DataCell(Text('${player.balls}')),
                            DataCell(Text('${player.fours}')),
                            DataCell(Text('${player.sixes}')),
                            DataCell(
                                Text(player.strikeRate.toStringAsFixed(1))),
                          ],
                        ))
                    .toList()
                : [
                    DataRow(
                      cells: [
                        DataCell(Text('No data available')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                      ],
                    )
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildBowlingStats(List<PlayerPerformance> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("BOWLING"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 12,
            columns: [
              DataColumn(label: Text('BOWLER')),
              DataColumn(label: Text('O')),
              DataColumn(label: Text('M')),
              DataColumn(label: Text('R')),
              DataColumn(label: Text('W')),
              DataColumn(label: Text('ECON')),
            ],
            rows: players.isNotEmpty
                ? players
                    .where((player) => player.overs > 0)
                    .map((player) => DataRow(
                          cells: [
                            DataCell(Text(player.name)),
                            DataCell(Text(player.overs.toStringAsFixed(1))),
                            DataCell(Text('${player.maidens}')),
                            DataCell(Text('${player.runsConceded}')),
                            DataCell(Text('${player.wickets}')),
                            DataCell(Text(player.economy.toStringAsFixed(1))),
                          ],
                        ))
                    .toList()
                : [
                    DataRow(
                      cells: [
                        DataCell(Text('No data available')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                      ],
                    )
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldingStats(List<PlayerPerformance> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("FIELDING"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            columns: [
              DataColumn(label: Text('PLAYER')),
              DataColumn(label: Text('CATCHES')),
              DataColumn(label: Text('RUN OUTS')),
              DataColumn(label: Text('STUMPING')),
            ],
            rows: players.isNotEmpty
                ? players
                    .where((player) =>
                        player.catches > 0 ||
                        player.runOuts > 0 ||
                        player.stumping > 0)
                    .map((player) => DataRow(
                          cells: [
                            DataCell(Text(player.name)),
                            DataCell(Text('${player.catches}')),
                            DataCell(Text('${player.runOuts}')),
                            DataCell(Text('${player.stumping}')),
                          ],
                        ))
                    .toList()
                : [
                    DataRow(
                      cells: [
                        DataCell(Text('No data available')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                        DataCell(Text('')),
                      ],
                    )
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.picture_as_pdf),
          label: Text("Export PDF"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _exportToPdf,
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.sports_cricket),
          label: Text("New Match"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MatchSetupPage()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}
