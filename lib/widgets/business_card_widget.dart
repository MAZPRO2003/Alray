import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BusinessCardWidget extends StatefulWidget {
  const BusinessCardWidget({super.key});

  @override
  State<BusinessCardWidget> createState() => _BusinessCardWidgetState();
}

class _BusinessCardWidgetState extends State<BusinessCardWidget> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCard() async {
    setState(() => _isSharing = true);
    try {
      // 1. Capture the widget as an image
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 2. Save image to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/business_card.png').create();
      await file.writeAsBytes(pngBytes);

      // 3. Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Al Ray Associates - Business Card');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing card: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The Business Card wrapped in RepaintBoundary for capture
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RepaintBoundary(
              key: _cardKey,
              child: Container(
                width: 600, // Fixed high-res base width
                height: 340, // Fixed high-res base height
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- HEADER ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // House Logo Area
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFDD2C33,
                            ), // Brighter red from image
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(2),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.home,
                                color: Colors.white,
                                size: 32, // Larger home icon
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A R A',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24), // Increased spacing
                        // Company Name
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              'Al Ray Associates',
                              style: GoogleFonts.dancingScript(
                                color: const Color(0xFFDD2C33), // Brighter red
                                fontSize: 64, // Much larger font
                                fontWeight: FontWeight.w700,
                                height: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- BODY ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Name & Title
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'H.ABDUL KADER',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Managing Director',
                                style: GoogleFonts.inter(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right Column: Contact Details (Aligned visually as per image)
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildContactText(
                                '1/1245, 1st Floor, West Main Road,',
                              ),
                              const SizedBox(height: 4),
                              _buildContactText(
                                'Kumudham Nagar, Mugalivakkam,',
                              ),
                              const SizedBox(height: 4),
                              _buildContactText('Chennai - 600 125.'),
                              const SizedBox(height: 12),
                              _buildContactRow(
                                'Mobile',
                                '8667011700 / 9841324123',
                              ),
                              const SizedBox(height: 12),
                              _buildContactRow(
                                'E-mail',
                                'alrayassociates@gmail.com',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // --- FOOTER ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Center(
                        child: Text(
                          'Plan / Estimate / Construction / Real Estate',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ), // End of FittedBox
          // --- UI ACTIONS ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                FilledButton.icon(
                  onPressed: _isSharing ? null : _shareCard,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share, size: 18),
                  label: Text(_isSharing ? 'Preparing...' : 'Share Image'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildContactRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
