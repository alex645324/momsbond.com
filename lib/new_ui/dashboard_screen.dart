import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            final scaleFactor = screenWidth / 393.0;
            
            return Stack(
              children: [
                // Header section (fixed at top)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 128 * scaleFactor,
                  child: Column(
                    children: [
                      Text(
                        'this is your homebase',
                        style: GoogleFonts.poppins(
                          fontSize: 20 * scaleFactor,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF494949),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8 * scaleFactor),
                      Text(
                        'where you maintain and create new connections.',
                        style: GoogleFonts.poppins(
                          fontSize: 11 * scaleFactor,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF777673),
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Scrollable content area
                Positioned.fill(
                  top: 200 * scaleFactor,
                  bottom: 130 * scaleFactor, // Leave space for bottom button
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor),
                      child: Stack(
                        children: [
                          // Connection Circles with Names
                          // Pink circle - alieel
                          Positioned(
                            left: 20 * scaleFactor,
                            top: 49 * scaleFactor,
                            child: Column(
                              children: [
                                Container(
                                  width: 85 * scaleFactor,
                                  height: 79 * scaleFactor,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFD4E2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(height: 4 * scaleFactor),
                                Text(
                                  'alieel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scaleFactor,
                                    color: const Color(0xFF494949),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Light gray circle - ana
                          Positioned(
                            left: 220 * scaleFactor,
                            top: 17 * scaleFactor,
                            child: Column(
                              children: [
                                Container(
                                  width: 68 * scaleFactor,
                                  height: 63 * scaleFactor,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD9D9D9),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(height: 4 * scaleFactor),
                                Text(
                                  'ana',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scaleFactor,
                                    color: const Color(0xFF494949),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Sage circle - jakie
                          Positioned(
                            left: 190 * scaleFactor,
                            top: 147 * scaleFactor,
                            child: Column(
                              children: [
                                Container(
                                  width: 100 * scaleFactor,
                                  height: 98 * scaleFactor,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD8DAC5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(height: 4 * scaleFactor),
                                Text(
                                  'jakie',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scaleFactor,
                                    color: const Color(0xFF494949),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Cream circle - sashia
                          Positioned(
                            left: 71 * scaleFactor,
                            top: 260 * scaleFactor,
                            child: Column(
                              children: [
                                Container(
                                  width: 96 * scaleFactor,
                                  height: 95 * scaleFactor,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEDE4C6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(height: 4 * scaleFactor),
                                Text(
                                  'sashia',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scaleFactor,
                                    color: const Color(0xFF494949),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Light gray circle - azul
                          Positioned(
                            left: 238 * scaleFactor,
                            top: 329 * scaleFactor,
                            child: Column(
                              children: [
                                Container(
                                  width: 104.19 * scaleFactor,
                                  height: 102.82 * scaleFactor,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDFE0E2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(height: 4 * scaleFactor),
                                Text(
                                  'azul',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scaleFactor,
                                    color: const Color(0xFF494949),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Light gray circle - zack
                          Positioned(
                            left: 30 * scaleFactor,
                            top: 447 * scaleFactor,
                            child: Column(
                              children: [
                                Container(
                                  width: 72 * scaleFactor,
                                  height: 71 * scaleFactor,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD9D9D9),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(height: 4 * scaleFactor),
                                Text(
                                  'zack',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12 * scaleFactor,
                                    color: const Color(0xFF494949),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Add extra space at bottom to ensure scrollability
                          SizedBox(height: 600 * scaleFactor),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom button (fixed)
                Positioned(
                  left: 86 * scaleFactor,
                  bottom: 65 * scaleFactor,
                  child: Container(
                    width: 245 * scaleFactor,
                    height: 44 * scaleFactor,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(29 * scaleFactor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'make another connection :)',
                        style: GoogleFonts.poppins(
                          fontSize: 12 * scaleFactor,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF494949),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 