import 'package:flutter/material.dart';

class CircularProgress extends StatelessWidget {
  const CircularProgress({
    this.width = 50.0,
    this.height = 50.0,
  }) : super();

  final double width, height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: width,
        height: height,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreen),
          backgroundColor: Colors.black12,
        ));
  }
}

class DefaultLoading extends StatelessWidget {
  const DefaultLoading({
    this.text1 = "",
    this.text2 = "",
    this.fontSize = 16,
  }) : super();

  final String text1, text2;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CircularProgress(),
          Container(
            padding: EdgeInsets.fromLTRB(0, 20, 0, 10),
            child: Text(text1, style: TextStyle(fontSize: fontSize)),
          ),
          Container(
            // padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Text(text2, style: TextStyle(fontSize: fontSize)),
          ),
        ],
      ),
    );
  }
}
