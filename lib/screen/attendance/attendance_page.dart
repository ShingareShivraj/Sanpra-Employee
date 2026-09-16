import 'package:flutter/material.dart';

import '../../model/attendance_calendar_model.dart';
import 'attendance_viewmodel.dart';

const _primary = Color(0xFF1B5FE0);
const _primaryDark = Color(0xFF123FA0);
const _accent = Color(0xFF4E8CFF);
const _present = Color(0xFF16A66A);
const _absent = Color(0xFFE5484D);
const _halfDay = Color(0xFFF59E0B);
const _leave = Color(0xFF4E78E8);
const _holiday = Color(0xFF8792A5);

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late final AttendanceViewModel _viewModel;
  int _financialYearStart = DateTime.now().month >= 4
      ? DateTime.now().year
      : DateTime.now().year - 1;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _viewModel = AttendanceViewModel();
    _selectedMonth = DateTime.now();
    _viewModel.addListener(_onViewModelChanged);
    _loadAttendance();
    _viewModel.loadShiftInfo();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  String get _financialYear =>
      '$_financialYearStart-${(_financialYearStart + 1).toString().substring(2)}';
  DateTime get _financialYearStartDate => DateTime(_financialYearStart, 4);
  DateTime get _financialYearEndDate => DateTime(_financialYearStart + 1, 3, 31);

  Future<void> _loadAttendance() => _viewModel.loadAttendance(
    fromDate: _formatDate(_financialYearStartDate),
    toDate: _formatDate(_financialYearEndDate),
  );

  Future<void> _changeFinancialYear(int difference) async {
    setState(() {
      _financialYearStart += difference;
      _selectedMonth = DateTime(_financialYearStart, 4);
    });
    await _loadAttendance();
  }

  void _changeMonth(int difference) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + difference);
    if (_isInsideFinancialYear(next)) setState(() => _selectedMonth = next);
  }

  bool _isInsideFinancialYear(DateTime date) {
    final month = DateTime(date.year, date.month);
    return !month.isBefore(DateTime(_financialYearStart, 4)) &&
        !month.isAfter(DateTime(_financialYearStart + 1, 3));
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _monthName(int month) => _months[month - 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            Text('Your yearly attendance record', style: TextStyle(fontSize: 11.5, color: Color(0xFFDCE8FF), fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh attendance',
            onPressed: _viewModel.isLoading ? null : _loadAttendance,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _loadAttendance,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && !_viewModel.hasData) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_viewModel.errorMessage != null && !_viewModel.hasData) return _buildErrorState();
    if (!_viewModel.hasData) return _buildEmptyState();
    return _buildAttendanceContent();
  }

  Widget _buildAttendanceContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 14),
          _buildSummary(),
          const SizedBox(height: 16),
          _buildShiftCard(),
          const SizedBox(height: 18),
          _sectionTitle('Monthly calendar', 'Tap any date for details'),
          const SizedBox(height: 10),
          _buildCalendarCard(),
          const SizedBox(height: 12),
          _buildLegend(),
          if (_viewModel.isLoading) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(color: _primary, backgroundColor: Color(0xFFDDE8FA)),
          ],
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryDark, _primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: .22), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance overview', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Financial year record', style: TextStyle(color: Color(0xFFDCE8FF), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                _heroArrow(Icons.chevron_left_rounded, 'Previous financial year', _viewModel.isLoading ? null : () => _changeFinancialYear(-1)),
                Expanded(
                  child: Column(
                    children: [
                      const Text('FINANCIAL YEAR', style: TextStyle(color: Color(0xFFCFE0FF), fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(_financialYear, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                _heroArrow(Icons.chevron_right_rounded, 'Next financial year', _viewModel.isLoading ? null : () => _changeFinancialYear(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroArrow(IconData icon, String tooltip, VoidCallback? onPressed) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .13), foregroundColor: Colors.white),
      icon: Icon(icon),
    );
  }

  Widget _buildSummary() {
    return Column(
      children: [
        _sectionTitle('Yearly summary', 'Attendance at a glance'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _summaryTile('Present', _viewModel.presentCount, _present, Icons.check_circle_rounded)),
            const SizedBox(width: 9),
            Expanded(child: _summaryTile('Absent', _viewModel.absentCount, _absent, Icons.cancel_rounded)),
            const SizedBox(width: 9),
            Expanded(child: _summaryTile('Half Day', _viewModel.halfDayCount, _halfDay, Icons.timelapse_rounded)),
            const SizedBox(width: 9),
            Expanded(child: _summaryTile('Leave', _viewModel.onLeaveCount, _leave, Icons.beach_access_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String caption) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF17233D)))),
        Text(caption, style: const TextStyle(fontSize: 10.5, color: Color(0xFF77839A))),
      ],
    );
  }

  Widget _summaryTile(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .16)),
        boxShadow: const [BoxShadow(color: Color(0x0A17233D), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 7),
          Text('$value', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF17233D))),
          const SizedBox(height: 1),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF77839A))),
        ],
      ),
    );
  }

  Widget _buildShiftCard() {
    if (_viewModel.isShiftLoading && !_viewModel.hasShiftData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE4EAF3),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primary,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading shift information...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF77839A),
              ),
            ),
          ],
        ),
      );
    }

    if (!_viewModel.hasShiftData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE4EAF3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: _primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No default shift is assigned to you.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5F6C83),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final shift = _viewModel.shiftData!.shift!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF2FF),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD9E6FA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17233D),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: _primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Shift',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF77839A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shift.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17233D),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Shift details',
                onPressed: _showShiftDetails,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primary,
                ),
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                ),
              ),
            ],
          ),
          // const SizedBox(height: 14),
          // Container(
          //   padding: const EdgeInsets.symmetric(
          //     horizontal: 13,
          //     vertical: 11,
          //   ),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withValues(alpha: .8),
          //     borderRadius: BorderRadius.circular(14),
          //   ),
          //   child: Row(
          //     children: [
          //       const Icon(
          //         Icons.access_time_rounded,
          //         size: 18,
          //         color: _primary,
          //       ),
          //       const SizedBox(width: 8),
          //       Expanded(
          //         child: Text(
          //           '${_formatShiftTime(shift.startTime)}'
          //               '  —  '
          //               '${_formatShiftTime(shift.endTime)}',
          //           style: const TextStyle(
          //             fontSize: 14,
          //             fontWeight: FontWeight.w700,
          //             color: Color(0xFF27344D),
          //           ),
          //         ),
          //       ),
          //       TextButton(
          //         onPressed: _showShiftDetails,
          //         child: const Text('View details'),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  void _showShiftDetails() {
    final shift = _viewModel.shiftData?.shift;

    if (shift == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .82,
            ),
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DEEA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: _primary,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Shift',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF77839A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shift.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17233D),
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F5F9),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _shiftTimeCard(shift),

                  const SizedBox(height: 12),

                  _shiftDetailRow(
                    Icons.event_available_rounded,
                    'Holiday List',
                    shift.holidayList ?? 'Not assigned',
                  ),

                  const SizedBox(height: 10),

                  _shiftDetailRow(
                    Icons.timelapse_rounded,
                    'Half Day Threshold',
                    '${shift.halfDayThreshold} hours',
                  ),

                  const SizedBox(height: 10),

                  _shiftDetailRow(
                    Icons.person_off_rounded,
                    'Absent Threshold',
                    '${shift.absentThreshold} hours',
                  ),

                  const SizedBox(height: 16),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Attendance Settings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17233D),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _shiftSettingRow(
                    Icons.login_rounded,
                    'Check-in before shift',
                    _formatSettingValue(
                      shift.beginCheckInBeforeShiftStartTime,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _shiftSettingRow(
                    Icons.logout_rounded,
                    'Check-out after shift',
                    _formatSettingValue(
                      shift.allowCheckOutAfterShiftEndTime,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _shiftSettingRow(
                    Icons.auto_awesome_rounded,
                    'Auto Attendance',
                    shift.enableAutoAttendance
                        ? 'Enabled'
                        : 'Disabled',
                  ),

                  const SizedBox(height: 8),

                  _shiftSettingRow(
                    Icons.sync_alt_rounded,
                    'Auto Check-in / Check-out',
                    shift.determineCheckInAndCheckOut
                        ? 'Enabled'
                        : 'Disabled',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _shiftTimeCard(ShiftInfo shift) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE3E9F2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'START TIME',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                    color: Color(0xFF8A95A8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatShiftTime(shift.startTime),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17233D),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: const Color(0xFFDDE3EC),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'END TIME',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                      color: Color(0xFF8A95A8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatShiftTime(shift.endTime),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17233D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shiftDetailRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE7ECF4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color: _primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF77839A),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF27344D),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _shiftSettingRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5F6C83),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF27344D),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSettingValue(dynamic value) {
    if (value == null) {
      return 'Not configured';
    }

    if (value is bool) {
      return value ? 'Enabled' : 'Disabled';
    }

    if (value is num) {
      return value == 1 ? 'Enabled' : 'Disabled';
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == '0') {
      return 'Disabled';
    }

    return text;
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [BoxShadow(color: Color(0x0B17233D), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          _buildMonthHeader(),
          const Divider(height: 1, color: Color(0xFFEDF1F7)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 15),
            child: _buildCalendar(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final canGoBack = _isInsideFinancialYear(DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    final canGoForward = _isInsideFinancialYear(DateTime(_selectedMonth.year, _selectedMonth.month + 1));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          _monthArrow(Icons.chevron_left_rounded, canGoBack ? () => _changeMonth(-1) : null),
          Expanded(
            child: Column(
              children: [
                Text(_monthName(_selectedMonth.month), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF17233D))),
                Text('${_selectedMonth.year}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF77839A), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _monthArrow(Icons.chevron_right_rounded, canGoForward ? () => _changeMonth(1) : null),
        ],
      ),
    );
  }

  Widget _monthArrow(IconData icon, VoidCallback? onPressed) => IconButton(
    onPressed: onPressed,
    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F5FF), foregroundColor: _primary, disabledForegroundColor: const Color(0xFFB9C2D1)),
    icon: Icon(icon),
  );

  Widget _buildCalendar() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final leading = DateTime(year, month).weekday - 1;
    final days = DateTime(year, month + 1, 0).day;
    final cells = ((leading + days) / 7).ceil() * 7;
    return Column(
      children: [
        _buildWeekdayHeader(),
        const SizedBox(height: 9),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
            childAspectRatio: .78,
          ),
          itemBuilder: (_, index) {
            final day = index - leading + 1;
            if (day < 1 || day > days) return const SizedBox();
            return _buildCalendarDay(DateTime(year, month, day));
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Row(
      children: List.generate(7, (index) => Expanded(
        child: Center(child: Text(weekdays[index], style: TextStyle(fontSize: 9, letterSpacing: .35, fontWeight: FontWeight.w800, color: index >= 5 ? _absent.withValues(alpha: .75) : const Color(0xFF8A95A8)))),
      )),
    );
  }

  Widget _buildCalendarDay(DateTime date) {
    final dateString = _formatDate(date);
    final status = _viewModel.getStatusForDate(dateString);
    final holiday = _viewModel.getHolidayNameForDate(dateString);
    final color = _getStatusColor(status);
    final today = _isToday(date);
    final hasStatus = status != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDayDetails(date: date, status: status, holidayName: holiday),
        child: Container(
          decoration: BoxDecoration(
            color: today ? _primary : hasStatus ? color.withValues(alpha: .075) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: today ? _primary : hasStatus ? color.withValues(alpha: .15) : Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}', style: TextStyle(fontSize: 13.5, fontWeight: today ? FontWeight.w800 : FontWeight.w600, color: today ? Colors.white : const Color(0xFF27344D))),
              const SizedBox(height: 5),
              Container(
                width: hasStatus ? 15 : 4,
                height: 4,
                decoration: BoxDecoration(color: today ? Colors.white : hasStatus ? color : const Color(0xFFDDE3EC), borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'P': return _present;
      case 'A': return _absent;
      case 'H': return _halfDay;
      case 'L': return _leave;
      case 'HOLIDAY': return _holiday;
      default: return const Color(0xFFCBD3DF);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE4EAF3))),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 13,
        runSpacing: 8,
        children: [
          _legendItem(_present, 'Present'),
          _legendItem(_absent, 'Absent'),
          _legendItem(_halfDay, 'Half Day'),
          _legendItem(_leave, 'Leave'),
          _legendItem(_holiday, 'Holiday'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF5F6C83))),
    ],
  );

  void _showDayDetails({
    required DateTime date,
    required String? status,
    required String? holidayName,
  }) {
    final dateString = _formatDate(date);
    final attendanceStatus =
    _viewModel.getAttendanceStatusForDate(dateString);
    final attendanceDetail =
    _viewModel.getAttendanceDetailForDate(dateString);
    final color = _getStatusColor(status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD7DEEA), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(17)),
                    child: Icon(_statusIcon(status), color: color, size: 27),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusLabel(status), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF17233D))),
                        const SizedBox(height: 3),
                        Text(_formatDisplayDate(date), style: const TextStyle(fontSize: 12, color: Color(0xFF77839A))),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close_rounded), style: IconButton.styleFrom(backgroundColor: const Color(0xFFF2F5F9))),
                ],
              ),
              const SizedBox(height: 18),
              _detailRow(
                status == 'HOLIDAY'
                    ? Icons.celebration_rounded
                    : status == null
                    ? Icons.info_outline_rounded
                    : Icons.fact_check_rounded,
                status == 'HOLIDAY'
                    ? 'Holiday'
                    : 'Attendance status',
                status == 'HOLIDAY'
                    ? (holidayName ?? 'Holiday')
                    : attendanceStatus != null
                    ? _statusLabel(attendanceStatus)
                    : 'No record available',
                color,
              ),

              if (status != 'HOLIDAY' &&
                  attendanceDetail != null) ...[
                const SizedBox(height: 10),
                _detailRow(
                  Icons.work_history_rounded,
                  'Shift Type',
                  attendanceDetail.shiftType ?? '--',
                  color,
                ),
                const SizedBox(height: 10),

                _detailRow(
                  Icons.login_rounded,
                  'Check In',
                  _formatTime(attendanceDetail.checkIn),
                  color,
                ),

                const SizedBox(height: 10),

                _detailRow(
                  Icons.logout_rounded,
                  'Check Out',
                  _formatTime(attendanceDetail.checkOut),
                  color,
                ),

                const SizedBox(height: 10),

                _detailRow(
                  Icons.schedule_rounded,
                  'Working Hours',
                  _formatWorkingHours(
                    attendanceDetail.workingHours,
                  ),
                  color,
                ),

                if (attendanceDetail.lateEntry) ...[
                  const SizedBox(height: 10),
                  _detailRow(
                    Icons.warning_amber_rounded,
                    'Late Mark',
                    'Late',
                    _absent,
                  ),
                ],
              ],
              if (status == null) ...[
                const SizedBox(height: 10),
                const Text('No attendance or holiday record is available for this date.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF77839A))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatShiftTime(String? time) {
    if (time == null || time.isEmpty) {
      return '--';
    }

    final parts = time.split(':');

    if (parts.length < 2) {
      return time;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return time;
    }

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '${displayHour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) {
      return '--';
    }

    final dateTime = DateTime.tryParse(time);

    if (dateTime != null) {
      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;

      return '${displayHour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')} $period';
    }

    final parts = time.split(':');

    if (parts.length < 2) {
      return time;
    }

    final hour = int.tryParse(parts[0].split(' ').last);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return time;
    }

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '${displayHour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatWorkingHours(double hours) {
    final totalMinutes = (hours * 60).round();
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;

    return '${hour}h ${minute}m';
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'P': return Icons.check_circle_rounded;
      case 'A': return Icons.cancel_rounded;
      case 'H': return Icons.timelapse_rounded;
      case 'L': return Icons.beach_access_rounded;
      case 'HOLIDAY': return Icons.celebration_rounded;
      default: return Icons.event_note_rounded;
    }
  }

  Widget _detailRow(IconData icon, String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF6F8FC), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE7ECF4))),
      child: Row(
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(width: 11),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF77839A)))),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF27344D)))),
        ],
      ),
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'P': return 'Present';
      case 'A': return 'Absent';
      case 'H': return 'Half Day';
      case 'L': return 'On Leave';
      case 'HOLIDAY': return 'Holiday';
      default: return 'Unmarked';
    }
  }

  String _formatDisplayDate(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${_monthName(date.month)} ${date.year}';
  }

  Widget _buildErrorState() => _stateList(
    icon: Icons.cloud_off_rounded,
    color: _absent,
    title: 'Unable to load attendance',
    message: _viewModel.errorMessage ?? 'Something went wrong. Please try again.',
    action: FilledButton.icon(onPressed: _loadAttendance, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
  );

  Widget _buildEmptyState() => _stateList(
    icon: Icons.calendar_month_outlined,
    color: _primary,
    title: 'No attendance data',
    message: 'No attendance records are available for financial year $_financialYear.',
  );

  Widget _stateList({required IconData icon, required Color color, required String title, required String message, Widget? action}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 76, height: 76, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(24)), child: Icon(icon, color: color, size: 36)),
              const SizedBox(height: 18),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF17233D))),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF77839A))),
              if (action != null) ...[const SizedBox(height: 20), action],
            ],
          ),
        ),
      ],
    );
  }
}
