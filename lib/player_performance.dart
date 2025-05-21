class PlayerPerformance {
  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
  final String outBy;
  final double overs;
  final int wickets;
  final int runsConceded;
  final int maidens;
  final int catches;
  final int runOuts;
  final int stumping;

  PlayerPerformance({
    required this.name,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.outBy = '',
    this.overs = 0,
    this.wickets = 0,
    this.runsConceded = 0,
    this.maidens = 0,
    this.catches = 0,
    this.runOuts = 0,
    this.stumping = 0,
  });

  double get strikeRate => balls > 0 ? (runs / balls) * 100 : 0;

  double get economy => overs > 0 ? runsConceded / overs : 0;

  PlayerPerformance copyWith({
    String? name,
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    bool? isOut,
    String? outBy,
    double? overs,
    int? wickets,
    int? runsConceded,
    int? maidens,
    int? catches,
    int? runOuts,
    int? stumping,
  }) {
    return PlayerPerformance(
      name: name ?? this.name,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isOut: isOut ?? this.isOut,
      outBy: outBy ?? this.outBy,
      overs: overs ?? this.overs,
      wickets: wickets ?? this.wickets,
      runsConceded: runsConceded ?? this.runsConceded,
      maidens: maidens ?? this.maidens,
      catches: catches ?? this.catches,
      runOuts: runOuts ?? this.runOuts,
      stumping: stumping ?? this.stumping,
    );
  }
}
