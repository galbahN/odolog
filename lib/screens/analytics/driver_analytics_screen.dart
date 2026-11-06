import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverAnalyticsScreen extends StatefulWidget {
  const DriverAnalyticsScreen({super.key});

  @override
  State<DriverAnalyticsScreen> createState() => _DriverAnalyticsScreenState();
}

class _DriverAnalyticsScreenState extends State<DriverAnalyticsScreen> {
  String _period = 'weekly'; // weekly or monthly
  bool _isLoading = true;
  String? _error;

  // Data points: date string → value
  Map<String, double> _earningsData = {};
  Map<String, double> _expensesData = {};
  Map<String, int> _tripData = {};
  Map<String, double> _distanceData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _fetchData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final daysBack = _period == 'weekly' ? 7 : 30;
    final startDate = now.subtract(Duration(days: daysBack));
    final startStr = DateFormat('yyyy-MM-dd').format(startDate);

    // Load trips
    final tripsSnap = await FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: startStr)
        .get();

    // Load expenses
    final expensesSnap = await FirebaseFirestore.instance
        .collection('expenses')
        .where('driverId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: startStr)
        .get();

    // Build earnings + trip maps
    final Map<String, double> earnings = {};
    final Map<String, int> trips = {};
    final Map<String, double> distance = {};

    for (var doc in tripsSnap.docs) {
      final data = doc.data();
      final date = data['date'] as String;
      earnings[date] =
          (earnings[date] ?? 0) + (data['earnings'] ?? 0).toDouble();
      trips[date] = (trips[date] ?? 0) + 1;
      distance[date] =
          (distance[date] ?? 0) + (data['distance'] ?? 0).toDouble();
    }

    // Build expenses map
    final Map<String, double> expenses = {};
    for (var doc in expensesSnap.docs) {
      final data = doc.data();
      final date = data['date'] as String;
      expenses[date] = (expenses[date] ?? 0) + (data['amount'] ?? 0).toDouble();
    }

    setState(() {
      _earningsData = earnings;
      _expensesData = expenses;
      _tripData = trips;
      _distanceData = distance;
      _isLoading = false;
    });
  }

  List<DateTime> get _dateRange {
    final now = DateTime.now();
    final daysBack = _period == 'weekly' ? 7 : 30;
    return List.generate(
      daysBack,
      (i) => now.subtract(Duration(days: daysBack - 1 - i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _PeriodSelector(
                    selected: _period,
                    onChanged: (p) {
                      setState(() => _period = p);
                      _loadData();
                    },
                  ),

                  const SizedBox(height: 24),

                  // Summary stats
                  _SummaryRow(
                    earningsData: _earningsData,
                    expensesData: _expensesData,
                    tripData: _tripData,
                  ),

                  const SizedBox(height: 28),

                  // Earnings vs Expenses chart
                  const Text(
                    'Earnings vs Expenses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LineChartCard(
                    dateRange: _dateRange,
                    series: [
                      _ChartSeries(
                        label: 'Earnings',
                        color: const Color(0xFF66BB6A),
                        getData: (date) =>
                            _earningsData[DateFormat(
                              'yyyy-MM-dd',
                            ).format(date)] ??
                            0,
                      ),
                      _ChartSeries(
                        label: 'Expenses',
                        color: const Color(0xFFFFAB91),
                        getData: (date) =>
                            _expensesData[DateFormat(
                              'yyyy-MM-dd',
                            ).format(date)] ??
                            0,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Trip count chart
                  const Text(
                    'Trips Per Day',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LineChartCard(
                    dateRange: _dateRange,
                    series: [
                      _ChartSeries(
                        label: 'Trips',
                        color: const Color(0xFF4FC3F7),
                        getData: (date) =>
                            (_tripData[DateFormat('yyyy-MM-dd').format(date)] ??
                                    0)
                                .toDouble(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Distance chart
                  const Text(
                    'Distance Per Day (km)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LineChartCard(
                    dateRange: _dateRange,
                    series: [
                      _ChartSeries(
                        label: 'Distance',
                        color: const Color(0xFFCE93D8),
                        getData: (date) =>
                            _distanceData[DateFormat(
                              'yyyy-MM-dd',
                            ).format(date)] ??
                            0,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ─── Period Selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['weekly', 'monthly'].map((period) {
        final isSelected = selected == period;
        return GestureDetector(
          onTap: () => onChanged(period),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4FC3F7).withValues(alpha: 0.15)
                  : const Color(0xFF1A2E42),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4FC3F7)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              period == 'weekly' ? 'Last 7 Days' : 'Last 30 Days',
              style: TextStyle(
                color: isSelected ? const Color(0xFF4FC3F7) : Colors.white54,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Summary Row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final Map<String, double> earningsData;
  final Map<String, double> expensesData;
  final Map<String, int> tripData;

  const _SummaryRow({
    required this.earningsData,
    required this.expensesData,
    required this.tripData,
  });

  @override
  Widget build(BuildContext context) {
    final totalEarnings = earningsData.values.fold(0.0, (a, b) => a + b);
    final totalExpenses = expensesData.values.fold(0.0, (a, b) => a + b);
    final totalTrips = tripData.values.fold(0, (a, b) => a + b);
    final netProfit = totalEarnings - totalExpenses;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Earnings',
            value: 'GHS ${totalEarnings.toStringAsFixed(2)}',
            color: const Color(0xFF66BB6A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Net Profit',
            value: 'GHS ${netProfit.toStringAsFixed(2)}',
            color: const Color(0xFF4FC3F7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Trips',
            value: '$totalTrips',
            color: const Color(0xFFCE93D8),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Line Chart Card ──────────────────────────────────────────────────────────

class _ChartSeries {
  final String label;
  final Color color;
  final double Function(DateTime) getData;

  const _ChartSeries({
    required this.label,
    required this.color,
    required this.getData,
  });
}

class _LineChartCard extends StatelessWidget {
  final List<DateTime> dateRange;
  final List<_ChartSeries> series;

  const _LineChartCard({required this.dateRange, required this.series});

  @override
  Widget build(BuildContext context) {
    final lineBarsData = series.map((s) {
      final spots = dateRange.asMap().entries.map((e) {
        final value = s.getData(e.value);
        return FlSpot(e.key.toDouble(), value);
      }).toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: s.color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: s.color.withValues(alpha: 0.08),
        ),
      );
    }).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: dateRange.length > 7 ? 6 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dateRange.length) {
                    return const SizedBox();
                  }
                  return Text(
                    DateFormat('d/M').format(dateRange[index]),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBarsData,
        ),
      ),
    );
  }
}
