import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 30,
          ),
          CircleAvatar(
            radius: 80,
            backgroundImage: AssetImage('assets/user_profile.jpg'),
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
              child: Text(
                'Giulia Tamburini',
                style: TextStyle(fontSize: 22),
              )
          ),
          Text(
            'Your selected Car',
            style: TextStyle(fontSize: 15),
          ),
          Text('Tesla')
        ],
      ),
    );
  }
}