import 'package:flutter/material.dart';
import 'web_navbar.dart';
import 'web_footer.dart';

class WebLayout extends StatelessWidget {
  final Widget child;
  final bool showNavbar;
  final bool showFooter;
  final Function(String)? onNavigate;

  const WebLayout({
    super.key,
    required this.child,
    this.showNavbar = true,
    this.showFooter = true,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (showNavbar)
            WebNavbar(onNavigate: onNavigate),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  child,
                  if (showFooter)
                    WebFooter(onNavigate: onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Scrollable web layout with navbar fixed at top
class WebLayoutScrollable extends StatelessWidget {
  final List<Widget> children;
  final bool showNavbar;
  final bool showFooter;
  final Function(String)? onNavigate;

  const WebLayoutScrollable({
    super.key,
    required this.children,
    this.showNavbar = true,
    this.showFooter = true,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (showNavbar)
            WebNavbar(onNavigate: onNavigate),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...children,
                  if (showFooter)
                    WebFooter(onNavigate: onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
