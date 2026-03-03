import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilterApplied;

  FilterBottomSheet({required this.onFilterApplied});

  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  double _minRating = 3.0;
  double _maxDistance = 200.0;
  bool _onlyFree = false;
  bool _onlyIndoor = false;
  bool _onlyOutdoor = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0A1F44),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _minRating = 3.0;
                          _maxDistance = 200.0;
                          _onlyFree = false;
                          _onlyIndoor = false;
                          _onlyOutdoor = false;
                        });
                      },
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: Color(0xFF00DFD8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Rating Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimum Rating',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _minRating,
                            min: 1.0,
                            max: 5.0,
                            divisions: 8,
                            label: _minRating.toStringAsFixed(1),
                            activeColor: Color(0xFF00DFD8),
                            inactiveColor: Colors.white.withOpacity(0.2),
                            onChanged: (value) {
                              setState(() {
                                _minRating = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_minRating.toStringAsFixed(1)}+',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Distance Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maximum Distance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _maxDistance,
                            min: 0.0,
                            max: 500.0,
                            divisions: 10,
                            label: '${_maxDistance.toInt()} km',
                            activeColor: Color(0xFF00DFD8),
                            inactiveColor: Colors.white.withOpacity(0.2),
                            onChanged: (value) {
                              setState(() {
                                _maxDistance = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_maxDistance.toInt()} km',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Quick Filters
                Text(
                  'Quick Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFilterChip('Free Entry', _onlyFree, (value) {
                      setState(() {
                        _onlyFree = value;
                        if (value) {
                          _onlyOutdoor = false;
                          _onlyIndoor = false;
                        }
                      });
                    }),
                    _buildFilterChip('Indoor Only', _onlyIndoor, (value) {
                      setState(() {
                        _onlyIndoor = value;
                        if (value) {
                          _onlyOutdoor = false;
                          _onlyFree = false;
                        }
                      });
                    }),
                    _buildFilterChip('Outdoor Only', _onlyOutdoor, (value) {
                      setState(() {
                        _onlyOutdoor = value;
                        if (value) {
                          _onlyIndoor = false;
                          _onlyFree = false;
                        }
                      });
                    }),
                  ],
                ),

                SizedBox(height: 32),

                // Apply Button
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF007CF0).withOpacity(0.4),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: () {
                        final filters = {
                          'minRating': _minRating,
                          'maxDistance': _maxDistance,
                          'onlyFree': _onlyFree,
                          'onlyIndoor': _onlyIndoor,
                          'onlyOutdoor': _onlyOutdoor,
                        };
                        widget.onFilterApplied(filters);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Center(
                        child: Text(
                          'APPLY FILTERS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    Function(bool) onChanged,
  ) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: Colors.white)),
      selected: isSelected,
      onSelected: onChanged,
      backgroundColor: Colors.white.withOpacity(0.1),
      selectedColor: Color(0xFF00DFD8),
      labelPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
