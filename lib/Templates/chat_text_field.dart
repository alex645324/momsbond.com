import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

/// Isolated TextField widget that maintains focus independently of message state changes
class ChatTextField extends StatefulWidget {
  final Function(String) onSendMessage;
  final double scaleFactor;

  const ChatTextField({
    Key? key,
    required this.onSendMessage,
    required this.scaleFactor,
  }) : super(key: key);

  @override
  _ChatTextFieldState createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listen for focus changes for debugging
    _focusNode.addListener(() {
      _log('FOCUS CHANGE  -> hasFocus=${_focusNode.hasFocus}');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    _log('_sendMessage called with text="$text"');
    if (text.isNotEmpty) {
      // Send message via callback
      widget.onSendMessage(text);
      // Clear text content
      _log('Clearing text and requesting focus');
      _controller.clear();
      // Immediately request focus to maintain keyboard
      _focusNode.requestFocus();
    }
  }

  void _handleSwipeDown() {
    // Only unfocus on user's intentional swipe down gesture
    _focusNode.unfocus();
  }

  // --------------------------------------------------
  // Helper utilities (private)
  // --------------------------------------------------

  void _log(String msg) => debugPrint('[ChatTextField] $msg');

  TextStyle _txt(Color color) => GoogleFonts.poppins(
        fontSize: 11 * widget.scaleFactor,
        color: color,
      );

  BoxDecoration get _outerDecoration => BoxDecoration(
        color: const Color(0xFFE6E3E0),
        borderRadius: BorderRadius.circular(29 * widget.scaleFactor),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
      );

  void _maybeHandleSwipe(DragUpdateDetails d) {
    if (d.delta.dy > 0 && d.delta.dy > d.delta.dx.abs() && d.delta.dy > 5) {
      _handleSwipeDown();
    }
  }

  Widget _buildSendIcon() => GestureDetector(
        onTap: () {
          _log('suffixIcon tapped');
          _sendMessage();
        },
        child: Container(
          margin: EdgeInsets.only(right: 8 * widget.scaleFactor),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Icon(
            Icons.send,
            color: const Color(0xFF494949),
            size: 20 * widget.scaleFactor,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    _log('build()');
    return GestureDetector(
      onPanUpdate: _maybeHandleSwipe,
      child: Container(
        constraints: BoxConstraints(
          minHeight: 44 * widget.scaleFactor,
          maxHeight: 120 * widget.scaleFactor,
        ),
        decoration: _outerDecoration,
        child: TextField(
          onTap: () => _log('TextField tapped'),
          controller: _controller,
          focusNode: _focusNode,
          onSubmitted: (_) {
            _log('onSubmitted triggered');
            _sendMessage();
          },
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: null, // allow unlimited lines
          minLines: 1,
          style: _txt(const Color(0xFF494949)),
          decoration: InputDecoration(
            hintText: 'say how you feel...',
            hintStyle: _txt(const Color(0xFF878787)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20 * widget.scaleFactor,
              vertical: 14 * widget.scaleFactor,
            ),
            border: InputBorder.none,
            isDense: true,
            suffixIcon: _buildSendIcon(),
          ),
        ),
      ),
    );
  }
} 