import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rajyo_darpan_publisher/core/constants/app_colors.dart';
import 'package:rajyo_darpan_publisher/core/network/api_client.dart';
import 'package:rajyo_darpan_publisher/core/constants/api_constants.dart';
import 'package:rajyo_darpan_publisher/presentation/widgets/status_badge.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingSchedules();
  }

  Future<void> _fetchUpcomingSchedules() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(ApiConstants.upcomingSchedules);
      if (res != null && res['data'] is List) {
        setState(() {
          _schedules = res['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSchedule(dynamic scheduleId) async {
    try {
      await _apiClient.delete(ApiConstants.scheduleDetail(scheduleId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শিডিউল সফলভাবে বাতিল করা হয়েছে')),
      );
      _fetchUpcomingSchedules();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('বাতিল করতে সমস্যা হয়েছে: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('শিডিউল সংবাদ', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUpcomingSchedules,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUpcomingSchedules,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _schedules.isEmpty
                ? const Center(
                    child: Text(
                      'বর্তমানে কোনো শিডিউল করা সংবাদ নেই',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _schedules[index];
                      final job = item['publishing_job'] ?? {};
                      final article = job['article'] ?? {};
                      final scheduledAt = item['scheduled_at'] != null
                          ? DateTime.tryParse(item['scheduled_at'])
                          : null;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.infoLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.schedule, color: AppColors.info),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          article['title'] ?? 'শিরোনাম নেই',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          scheduledAt != null
                                              ? 'প্রকাশের সময়: ${DateFormat('dd MMM yyyy, hh:mm a').format(scheduledAt)}'
                                              : '',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const StatusBadge(status: 'scheduled'),
                                  TextButton.icon(
                                    icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
                                    label: const Text('শিডিউল বাতিল', style: TextStyle(color: AppColors.danger)),
                                    onPressed: () => _cancelSchedule(item['id']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
