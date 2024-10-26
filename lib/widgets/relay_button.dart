import 'package:flutter/material.dart';

class RelayButton extends StatelessWidget {
  final Function onPressed;
  final String buttonText;

  RelayButton({required this.onPressed, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(),
      child: Text(buttonText),
    );
  }
}
