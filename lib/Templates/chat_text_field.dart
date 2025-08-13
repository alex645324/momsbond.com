import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../config/locale_helper.dart';

/// Isolated TextField widget that maintains focus independently of message state changes
class ChatTextField extends StatefulWidget {
  final Function(String) onSendMessage;
  final double scaleFactor;
  final ValueChanged<String>? onTextChanged;
  final bool hasMessages; // New parameter to track if conversation has started
  final VoidCallback? onUserStartedTyping;
  final VoidCallback? onUserStoppedTyping;

  const ChatTextField({
    Key? key,
    required this.onSendMessage,
    required this.scaleFactor,
    this.onTextChanged,
    this.hasMessages = false, // Default to false for first message
    this.onUserStartedTyping,
    this.onUserStoppedTyping,
  }) : super(key: key);

  @override
  _ChatTextFieldState createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _starterText = '';
  int _starterTextLength = 0;
  bool _isInitialized = false;
  bool _wasTyping = false;

  @override
  void initState() {
    super.initState();
    
    // Listen for focus changes for debugging
    _focusNode.addListener(() {
      _log('FOCUS CHANGE  -> hasFocus=${_focusNode.hasFocus}');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize only once when dependencies are available
    if (!_isInitialized) {
      // Only use starter text if no messages exist yet
      if (!widget.hasMessages) {
        // Get starter text from configuration
        _starterText = L.chat(context).inputStarterText;
        _starterTextLength = _starterText.length;
        
        // Initialize controller with starter text
        _controller.text = _starterText;
        
        // Position cursor at end of starter text
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _starterTextLength),
        );
        
        // Listen for text changes to protect starter text
        _controller.addListener(_handleTextChange);
      } else {
        // No starter text - conversation already started
        _starterText = '';
        _starterTextLength = 0;
        _controller.text = '';
      }
      
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(ChatTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If hasMessages changed from false to true, remove starter text
    if (oldWidget.hasMessages != widget.hasMessages && widget.hasMessages) {
      _log('Messages detected - removing starter text');
      
      // Remove listener if it was active
      if (_starterTextLength > 0) {
        _controller.removeListener(_handleTextChange);
      }
      
      // Clear starter text
      _starterText = '';
      _starterTextLength = 0;
      _controller.text = '';
      
      // Position cursor at beginning
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: 0),
      );
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.removeListener(_handleTextChange);
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final currentText = _controller.text;
    final currentSelection = _controller.selection;
    
    // If no starter text (conversation already started), pass through normally
    if (_starterTextLength == 0) {
      widget.onTextChanged?.call(currentText);
      return;
    }
    
    // If starter text was modified or deleted, restore it
    if (!currentText.startsWith(_starterText)) {
      _log('Starter text was modified, restoring...');
      
      // Extract user input if any
      String userInput = '';
      if (currentText.length > _starterTextLength) {
        userInput = currentText.substring(_starterTextLength);
      }
      
      // Restore starter text with user input
      final restoredText = _starterText + userInput;
      _controller.value = TextEditingValue(
        text: restoredText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: restoredText.length),
        ),
      );
      
      // Call onTextChanged with user input only
      widget.onTextChanged?.call(userInput);
      return;
    }
    
    // Prevent cursor from being placed before starter text
    if (currentSelection.baseOffset < _starterTextLength) {
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _starterTextLength),
      );
    }
    
    // Call onTextChanged with user input only (text after starter)
    final userInput = currentText.length > _starterTextLength 
        ? currentText.substring(_starterTextLength) 
        : '';
    widget.onTextChanged?.call(userInput);
    
    // Handle typing indicators
    final isTyping = userInput.isNotEmpty;
    if (isTyping && !_wasTyping) {
      widget.onUserStartedTyping?.call();
      _wasTyping = true;
    } else if (!isTyping && _wasTyping) {
      widget.onUserStoppedTyping?.call();
      _wasTyping = false;
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    _log('_sendMessage called with text="$text"');
    
    // Handle sending based on whether starter text is active
    if (_starterTextLength == 0) {
      // No starter text - normal mode
      if (text.isNotEmpty) {
        widget.onSendMessage(text);
        _controller.clear();
        widget.onUserStoppedTyping?.call();
        _wasTyping = false;
        _focusNode.requestFocus();
      }
    } else {
      // Starter text mode - only send if user has added content after starter text
      if (text.length > _starterTextLength) {
        // Send complete message including starter text
        widget.onSendMessage(text);
        widget.onUserStoppedTyping?.call();
        _wasTyping = false;
        // Reset to starter text only
        _log('Resetting to starter text and requesting focus');
        _controller.text = _starterText;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _starterTextLength),
        );
        // Immediately request focus to maintain keyboard
        _focusNode.requestFocus();
      }
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
        fontSize: 14 * widget.scaleFactor,
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
            size: 24 * widget.scaleFactor,
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
          minHeight: 56 * widget.scaleFactor,
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
            hintText: _starterTextLength == 0 ? L.chat(context).inputHint : null,
            hintStyle: _starterTextLength == 0 ? _txt(const Color(0xFF878787)) : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 24 * widget.scaleFactor,
              vertical: 18 * widget.scaleFactor,
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