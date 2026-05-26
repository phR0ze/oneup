import 'package:flutter/material.dart';
import '../../const.dart';

class WeekPickerDialog extends StatefulWidget {
  const WeekPickerDialog({super.key, required this.initialDate});
  final DateTime initialDate;

  @override
  State<WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<WeekPickerDialog> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  (DateTime, DateTime) _weekRange(DateTime date) {
    final mon = date.subtract(Duration(days: date.weekday - 1));
    final start = DateTime(mon.year, mon.month, mon.day);
    final end = start.add(const Duration(days: 6));
    return (start, end);
  }

  String _fmt(DateTime d) => '${_monthAbbr(d.month)} ${d.day}';

  String _monthAbbr(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final (weekStart, weekEnd) = _weekRange(_selected);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: Const.dialogWidth,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Week',
                style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Week: ${_fmt(weekStart)} – ${_fmt(weekEnd)}, ${weekStart.year}',
                style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    onSurface: Colors.black,
                    primary: Const.neutralPointsValueBgColor,
                    onPrimary: Colors.black,
                  ),
                  textTheme: textTheme.copyWith(
                    titleSmall: textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  datePickerTheme: DatePickerThemeData(
                    weekdayStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _selected,
                  firstDate: DateTime(2020),
                  lastDate: now,
                  onDateChanged: (date) => setState(() => _selected = date),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 5),
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.green),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context, _selected),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
