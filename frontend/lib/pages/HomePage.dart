import 'package:flutter/material.dart';

class HomePage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NextGen Fitness App")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context,'/login') , child: Text("Login"),
        ),
        ElevatedButton(onPressed: () =>  Navigator.pushNamed(context,'/signup'), child: Text("Sign Up"),
        )
          ],
        ),
      ),
    );
  }
}