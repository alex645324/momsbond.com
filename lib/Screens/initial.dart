import 'package:flutter/material.dart';


void main(){
  runApp( 
    MaterialApp(
      debugShowCheckedModeBanner: false, // this removes the banner
      home: MvpCode(),
    ),
  );
}

class MvpCode extends StatelessWidget{
  @override 
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor:  const Color(0xFFF2EDE7),
      body: Center(
        child: Container(
          width: 393, 
          height: 852, 
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "a gentle space.", 
                  style: const TextStyle(
                    fontFamily: "Nunito", 
                    fontSize: 20, 
                    fontWeight: FontWeight.normal, 
                    color: Color(0xFF574F4E),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight, 
                  child: Text(
                    "just for you", 
                    style: const TextStyle(
                      fontFamily: "Nunito", 
                      fontSize: 20, 
                      fontWeight: FontWeight.normal, 
                      color: Color(0xFF574F4E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}