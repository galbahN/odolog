import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _DriverData {
  final String name;
  final Map<String, double> earningsByDate;
  _DriverData(this.name, this.earningsByDate);
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  String _period = 'weekly';
  bool _isLoading = true;
  String? _error;

  List<_DriverData> _drivers = [];
  Map<String, double> _maintenanceByDate = {};

  static const _palette = [
    Color(0xFF4FC3F7),
    Color(0xFF66BB6A),
    Color(0xFFFFB74D),
    Color(0xFFCE93D8),
    Color(0xFFFFAB91),
    Color(0xFF80DEEA),
  ];

  int get _days => _period == 'weekly' ? 7 : 30;

  List<DateTime> get _dateRange {
    final now = DateTime.now();
    return List.generate(
      _days,
      (i) => now.subtract(Duration(days: _days - 1 - i)),
    );
  }

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
      final ownerUid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;
      final startStr = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(Duration(days: _days - 1)));

      // Drivers in this owner's fleet
      final driversSnap =
          await db.collection('users').where('ownerId', isEqualTo: ownerUid).get();

      final drivers = <_DriverData>[];
      for (final d in driversSnap.docs) {
        final tripsSnap = await db
            .collection('trips')
            .where('driverId', isEqualTo: d.id)
            .where('date', isGreaterThanOrEqualTo: startStr)
            .get();

        final byDate = <String, double>{};
        for (final t in tripsSnap.docs) {
          final data = t.data();
          final date = data['date'] as String;
          byDate[date] =
              (byDate[date] ?? 0) + (data['earnings'] ?? 0).toDouble();
        }
        drivers.add(_DriverData((d.data()['name'] ?? 'Driver') as String, byDate));
      }

      // Maintenance costs across the owner's vehicles
      final vehiclesSnap =
          await db.collection('vehicles').where('ownerId', isEqualTo: ownerUid).get();
      // whereIn supports up to 30 values; fine for now
      final vehicleIds = vehiclesSnap.docs.map((d) => d.id).take(30).toList();

      final cost = <String, double>{};
      if (vehicleIds.isNotEmpty) {
        final mSnap = await db
            .collection('maintenance')
            .where('vehicleId', whereIn: vehicleIds)
            .get();
        for (final m in mSnap.docs) {
          final data = m.data();
          final date = data['serviceDate'] as String?;
          // Filtered here instead of in the query to avoid needing another index
          if (date == null || date.compareTo(startStr) < 0) continue;
          cost[date] = (cost[date] ?? 0) + (data['cost'] ?? 0).toDouble();
        }
      }

      if (!mounted) return;
      setState(() {
        _drivers = drivers;
        _maintenanceByDate = cost;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double _earningsOn(_DriverData d, DateTime date) =>
      d.earningsByDate[DateFormat('yyyy-MM-dd').format(date)] ?? 0;

  // Weekly view: one point per day. Monthly view: one point per 6 days.
  List<double> get _maintenanceBuckets {
    final bucketSize = _period == 'weekly' ? 1 : 6;
    final range = _dateRange;
    final bucketCount = (range.length / bucketSize).ceil();
    final buckets = List<double>.filled(bucketCount, 0);
    for (var i = 0; i < range.length; i++) {
      final key = DateFormat('yyyy-MM-dd').format(range[i]);
      buckets[i ~/ bucketSize] += _maintenanceByDate[key] ?? 0;
    }
    return buckets;
  }

  List<String> get _maintenanceLabels {
    final bucketSize = _period == 'weekly' ? 1 : 6;
    final range = _dateRange;
    final count = (range.length / bucketSize).ceil();
    return List.generate(
      count,
      (i) => DateFormat('d/M').format(range[i * bucketSize]),
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
          'Fleet Analytics',
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
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final totalEarnings = _drivers.fold<double>(
      0,
      (total, d) => total + d.earningsByDate.values.fold(0.0, (a, b) => a + b),
    );
    final totalMaintenance =
        _maintenanceByDate.values.fold<double>(0, (a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['weekly', 'monthly'].map((p) {
              final selected = _period == p;
              return GestureDetector(
                onTap: () {
                  setState(() => _period = p);
                  _loadData();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF4FC3F7).withValues(alpha: 0.15)
                        : const Color(0xFF1A2E42),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF4FC3F7)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    p == 'weekly' ? 'Last 7 Days' : 'Last 30 Days',
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF4FC3F7)
                          : Colors.white54,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Fleet Earnings',
                  value: 'GHS ${totalEarnings.toStringAsFixed(2)}',
                  color: const Color(0xFF66BB6A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'Maintenance',
                  value: 'GHS ${totalMaintenance.toStringAsFixed(2)}',
                  color: const Color(0xFFFFB74D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'Drivers',
                  value: '${_drivers.length}',
                  color: const Color(0xFF4FC3F7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          const Text(
            'Driver Earnings Comparison',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          if (_drivers.isEmpty)
            const _EmptyCard('Add drivers to your fleet to compare them')
          else
            _LineChartCard(
              labels: _dateRange.map((d) => DateFormat('d/M').format(d)).toList(),
              series: [
                for (var i = 0; i < _drivers.length; i++)
                  _Series(
                    name: _drivers[i].name,
                    color: _palette[i % _palette.length],
                    values: _dateRange.map((d) => _earningsOn(_drivers[i], d)).toList(),
                  ),
              ],
            ),

          const SizedBox(height: 28),
          const Text(
            'Maintenance Costs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          if (totalMaintenance == 0)
            const _EmptyCard('No maintenance costs in this period')
          else
            _LineChartCard(
              labels: _maintenanceLabels,
              series: [
                _Series(
                  name: 'Cost (GHS)',
                  color: const Color(0xFFFFB74D),
                  values: _maintenanceBuckets,
                ),
              ],
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Series {
  final String name;
  final Color color;
  final List<double> values;
  const _Series({required this.name, required this.color, required this.values});
}

class _LineChartCard extends StatelessWidget {
  final List<String> labels;
  final List<_Series> series;

  const _LineChartCard({required this.labels, required this.series});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.white10, strokeWidth: 1),
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
                      interval: labels.length > 7 ? 6 : 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        return Text(
                          labels[i],
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: series.map((s) {
                  return LineChartBarData(
                    spots: [
                      for (var i = 0; i < s.values.length; i++)
                        FlSpot(i.toDouble(), s.values[i]),
                    ],
                    isCurved: true,
                    color: s.color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  );
                }).toList(),
              ),
            ),
          ),
          if (series.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: series.map((s) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.name,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
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

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.white38)),
      ),
    );
  }
}