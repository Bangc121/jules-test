import 'package:flutter/material.dart';
import 'package:flutter_journal_app/database_helper.dart'; // Import DatabaseHelper
import 'package:flutter_journal_app/journal_entry_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For date formatting

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<JournalEntry>> _entriesByDate = {}; // To store entries by date string
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllEntriesForMarkers(); // Load entries for event markers
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Method to load entries and populate _entriesByDate
  // In a real app, you might fetch entries for the visible month range
  // For simplicity, we'll try to get an indication for any date that has an entry
  // This is not super efficient for large datasets but works for this scope.
  // A more robust solution would involve querying entries by month or visible range.
  Future<void> _loadAllEntriesForMarkers() async {
    // This is a placeholder. Ideally, DatabaseHelper would have a method
    // to get all dates with entries, or entries within a range.
    // For now, we can't easily query *all* entries without a proper method in DatabaseHelper.
    // So, this part will be more conceptual for the eventLoader.
    // Let's assume we have a way to get dates with entries.
    // For example, if dbHelper.getAllEntries() existed:
    // final allEntries = await _dbHelper.getAllEntries();
    // final Map<String, List<JournalEntry>> entriesMap = {};
    // for (var entry in allEntries) {
    //   if (entriesMap.containsKey(entry.date)) {
    //     entriesMap[entry.date]!.add(entry);
    //   } else {
    //     entriesMap[entry.date] = [entry];
    //   }
    // }
    // if (mounted) {
    //   setState(() {
    //     _entriesByDate = entriesMap;
    //   });
    // }
    // Since we don't have getAllEntries, we'll simulate this.
    // When an entry is saved/deleted, we could update a list of dates with entries.
    // For now, the eventLoader will just check if the date is `_selectedDay` as a simple example.
    // This will be updated when navigating back from JournalEntryScreen.
    print("Placeholder for _loadAllEntriesForMarkers. Actual implementation needs DB support for all entry dates.");
  }

  List<JournalEntry> _getEventsForDay(DateTime day) {
    String formattedDate = _formatDate(day);
    return _entriesByDate[formattedDate] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JournalEntryScreen(selectedDate: selectedDay),
        ),
      ).then((_) {
        // Refresh markers when returning from JournalEntryScreen
        // This is a simple way to update markers.
        // A more robust way involves checking if an entry was actually saved/deleted.
        _updateMarkerForDate(selectedDay);
      });
    }
  }

  // Method to update marker for a specific date, typically after saving/deleting an entry
  Future<void> _updateMarkerForDate(DateTime date) async {
    String formattedDate = _formatDate(date);
    JournalEntry? entry = await _dbHelper.getEntry(formattedDate);
    setState(() {
      if (entry != null) {
        _entriesByDate[formattedDate] = [entry]; // Add/update marker
      } else {
        _entriesByDate.remove(formattedDate); // Remove marker
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Calendar'),
      ),
      body: TableCalendar<JournalEntry>( // Specify type for TableCalendar
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: _onDaySelected,
        eventLoader: _getEventsForDay, // Use eventLoader to show markers
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                right: 1,
                bottom: 1,
                child: _buildEventsMarker(date, events),
              );
            }
            return null;
          },
        ),
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          // When page changes, you might want to reload entries for the new visible month
          // For simplicity, this is not implemented here.
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  // Custom marker widget (a simple dot)
  Widget _buildEventsMarker(DateTime date, List<JournalEntry> events) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[400],
      ),
      width: 7.0,
      height: 7.0,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
    );
  }
}
