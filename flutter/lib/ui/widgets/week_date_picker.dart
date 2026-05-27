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
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280, minWidth: 260),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 15, 5, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Week',
                style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Week: ${_fmt(weekStart)} – ${_fmt(weekEnd)}, ${weekStart.year}',
                style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
              _MonthCalendar(
                selected: _selected,
                firstDate: DateTime(2020),
                lastDate: now,
                onChanged: (date) => setState(() => _selected = date),
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

class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final DateTime selected;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  late DateTime _month;

  static const _weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selected.year, widget.selected.month);
  }

  bool get _canPrev => _month.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
  bool get _canNext => _month.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(widget.selected.year, widget.selected.month, widget.selected.day);

    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    // DateTime.weekday: 1=Mon..7=Sun → offset for Sun-first grid: Sun=0..Sat=6
    final startOffset = firstDay.weekday % 7;
    final rowCount = ((startOffset + daysInMonth) / 7).ceil();

    final dayRows = List.generate(rowCount, (row) {
      return Row(
        children: List.generate(7, (col) {
          final day = row * 7 + col - startOffset + 1;
          if (day < 1 || day > daysInMonth) return const Expanded(child: SizedBox());
          final date = DateTime(_month.year, _month.month, day);
          return Expanded(
            child: _DayCell(
              day: day,
              isSelected: date == selected,
              isToday: date == today,
              isDisabled: date.isAfter(widget.lastDate) || date.isBefore(widget.firstDate),
              onTap: () => widget.onChanged(date),
            ),
          );
        }),
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month/year header — same 7-column structure as the grid so arrows align
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDialog<DateTime>(
                      context: context,
                      builder: (ctx) => Dialog(
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: YearPicker(
                            firstDate: widget.firstDate,
                            lastDate: widget.lastDate,
                            selectedDate: _month,
                            onChanged: (date) => Navigator.pop(ctx, date),
                          ),
                        ),
                      ),
                    );
                    if (picked != null) {
                      setState(() => _month = DateTime(picked.year, _month.month));
                    }
                  },
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Text(
                        '${_monthNames[_month.month]} ${_month.year}',
                        style: textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _canPrev
                      ? () => setState(() => _month = DateTime(_month.year, _month.month - 1))
                      : null,
                    child: Icon(Icons.chevron_left,
                      color: _canPrev ? Colors.black : Colors.black26),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _canNext
                      ? () => setState(() => _month = DateTime(_month.year, _month.month + 1))
                      : null,
                    child: Icon(Icons.chevron_right,
                      color: _canNext ? Colors.black : Colors.black26),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Weekday letters — no transform
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            children: _weekdayLetters.map((d) => Expanded(
              child: Center(
                child: Text(d,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),

        // Day grid — fixed height for 6 rows so buttons don't shift between months
        Padding(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 6 * 32,
            child: Column(children: dayRows),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = isSelected
      ? const BoxDecoration(shape: BoxShape.circle, color: Const.neutralPointsValueBgColor)
      : isToday
        ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Const.neutralPointsValueBgColor, width: 1.5),
          )
        : null;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: SizedBox(
        height: 32,
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: decoration,
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isDisabled ? Colors.black26 : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
