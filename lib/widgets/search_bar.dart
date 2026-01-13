import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final String? initialValue;

  const SearchBarWidget({
    Key? key,
    required this.onSearchChanged,
    this.initialValue,
  }) : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _hasSearchText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(width: 16),
          Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search destinations...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {
                  _hasSearchText = value.isNotEmpty;
                });
                widget.onSearchChanged(value);
              },
            ),
          ),
          if (_hasSearchText)
            IconButton(
              onPressed: () {
                _controller.clear();
                setState(() {
                  _hasSearchText = false;
                });
                widget.onSearchChanged('');
              },
              icon: Icon(Icons.close, color: Colors.white.withOpacity(0.7)),
            ),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}
