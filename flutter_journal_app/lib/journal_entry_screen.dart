import 'package:flutter/material.dart';
import 'package:flutter_journal_app/database_helper.dart'; // Import DatabaseHelper
import 'package:intl/intl.dart'; // For date formatting

class JournalEntryScreen extends StatefulWidget {
  final DateTime selectedDate;

  JournalEntryScreen({required this.selectedDate});

  @override
  _JournalEntryScreenState createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _entryController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  JournalEntry? _existingEntry;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _loadEntry() async {
    String formattedDate = _formatDate(widget.selectedDate);
    JournalEntry? entry = await _dbHelper.getEntry(formattedDate);
    if (entry != null) {
      setState(() {
        _entryController.text = entry.content;
        _existingEntry = entry;
      });
    }
  }

  Future<void> _saveEntry() async {
    String formattedDate = _formatDate(widget.selectedDate);
    String content = _entryController.text;

    if (content.isEmpty) {
      // Optionally, show a message if the content is empty
      // If an entry exists and content is now empty, consider deleting it
      if (_existingEntry != null) {
        await _dbHelper.deleteEntry(formattedDate);
        print("Deleted entry for $formattedDate");
      }
      Navigator.pop(context);
      return;
    }

    if (_existingEntry != null) {
      // Update existing entry
      _existingEntry!.content = content;
      await _dbHelper.updateEntry(_existingEntry!);
      print("Updated entry for $formattedDate");
    } else {
      // Insert new entry
      JournalEntry newEntry = JournalEntry(date: formattedDate, content: content);
      await _dbHelper.insertEntry(newEntry);
      print("Saved new entry for $formattedDate");
    }
    Navigator.pop(context); // Go back to the calendar screen
  }

  @override
  Widget build(BuildContext context) {
    String displayDate = DateFormat('MMM d, yyyy').format(widget.selectedDate.toLocal());
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Entry - $displayDate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              'Entry for $displayDate:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _entryController,
                maxLines: null, // Allows for multi-line input
                expands: true,
                decoration: InputDecoration(
                  hintText: 'Write your thoughts...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveEntry,
              child: Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
