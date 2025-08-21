import 'package:flutter/material.dart';

final Map<Color, Map<String, dynamic>> themeTextStyles = {
  // white 테마 (primaryColor: Colors.white10)
  Colors.white: {
    'backgroundColor': Colors.white,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.white,
    )
  },
  // dark 테마 (primaryColor: Colors.black)
  Colors.black: {
    'backgroundColor': Colors.grey[900]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.white,
      backgroundColor: Colors.grey[900]!,
    )
  },
  // light 테마 (primaryColor: Colors.yellow)
  Colors.yellow: {
    'backgroundColor': Colors.yellow[50]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.yellow[50]!,
    )
  },
  // spring 테마 (primaryColor: Colors.pink)
  Colors.pink: {
    'backgroundColor': Colors.pink[50]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.pink[50]!,
    )
  },
  // summer 테마 (primaryColor: Colors.blue)
  Colors.blue: {
    'backgroundColor': Colors.lightBlue[50]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.lightBlue[50]!,
    )
  },
  // autumn 테마 (primaryColor: Colors.orange)
  Colors.orange: {
    'backgroundColor': Colors.orange[50]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.orange[50]!,
    )
  },
  // winter 테마 (primaryColor: Colors.blueGrey)
  Colors.blueGrey: {
    'backgroundColor': Colors.blueGrey[50]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.blueGrey[50]!,
    )
  },
  // nature 테마 (primaryColor: Colors.green)
  Colors.green: {
    'backgroundColor': Colors.green[50]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.green[50]!,
    )
  },
  // sea 테마 (primaryColor: Colors.teal)
  Colors.teal: {
    'backgroundColor': Colors.teal[50]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.teal[50]!,
    )
  },
  // tree 테마 (primaryColor: Colors.brown)
  Colors.brown: {
    'backgroundColor': Colors.brown[50]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.brown[50]!,
    )
  },
  // universe 테마 (primaryColor: Colors.deepPurple)
  Colors.deepPurple: {
    'backgroundColor': Colors.deepPurple[50]!,
    'style': TextStyle(
      fontSize: 14,
      color: Colors.black,
      backgroundColor: Colors.deepPurple[50]!,
    )
  },
};

TextStyle textStyle(Color color) => themeTextStyles[color]?['style'];
