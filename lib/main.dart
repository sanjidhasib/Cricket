import 'package:flutter/material.dart';
import 'match_page.dart'; 
import 'splash_screen.dart'; 

void main() {
  runApp(MyApp());
}


  class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), 
    );
  }
}

class CricketScorerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MatchSetupPage(),
    );
  }
}

class MatchSetupPage extends StatefulWidget {
  @override
  _MatchSetupPageState createState() => _MatchSetupPageState();
}

class _MatchSetupPageState extends State<MatchSetupPage> {
  TextEditingController hostController = TextEditingController();
  TextEditingController visitorController = TextEditingController();
  TextEditingController oversController = TextEditingController();
  String? tossWinner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cricket Scorer"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: hostController,
                decoration: InputDecoration(
                    labelText: "Host Team", border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: visitorController,
                decoration: InputDecoration(
                    labelText: "Visitor Team", border: OutlineInputBorder()),
              ),
              SizedBox(height: 20),
              Text("Toss won by?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: Text("Host"),
                      value: "host",
                      groupValue: tossWinner,
                      onChanged: (value) {
                        setState(() {
                          tossWinner = value as String?;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: Text("Visitor"),
                      value: "visitor",
                      groupValue: tossWinner,
                      onChanged: (value) {
                        setState(() {
                          tossWinner = value as String?;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextField(
                controller: oversController,
                decoration: InputDecoration(
                    labelText: "Overs", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () {
                    if (hostController.text.isNotEmpty &&
                        visitorController.text.isNotEmpty &&
                        oversController.text.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchPage(
                            hostTeam: hostController.text,
                            visitorTeam: visitorController.text,
                            overs: int.parse(oversController.text),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text("Start Match",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
