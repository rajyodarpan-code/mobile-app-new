import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/status_badge.dart';
import '../editor/create_article_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const HomeDashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = Provider.of<DashboardProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.newspaper_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('রাজ্য দর্পণ ড্যাশবোর্ড', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => dashboard.fetchSummary(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboard.fetchSummary(),
        child: dashboard.isLoading && dashboard.publishedCount == 0
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Create New Article Banner Button
                    Card(
                      color: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateArticleScreen()),
                          ).then((_) => dashboard.fetchSummary());
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.edit_document, color: Colors.white),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'নতুন সংবাদ তৈরি করুন',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'সরাসরি ওয়েবসাইটে প্রকাশ করুন',
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Grid (2x2)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'প্রকাশিত সংবাদ',
                            count: dashboard.publishedCount,
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            bgColor: AppColors.successLight,
                            onTap: () => widget.onNavigateTab(1), // Articles tab
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'ড্রাফট সংবাদ',
                            count: dashboard.draftCount,
                            icon: Icons.drafts_outlined,
                            color: AppColors.secondary,
                            bgColor: const Color(0xFFF1F5F9),
                            onTap: () => widget.onNavigateTab(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'শিডিউলড সংবাদ',
                            count: dashboard.scheduledCount,
                            icon: Icons.schedule_rounded,
                            color: AppColors.info,
                            bgColor: AppColors.infoLight,
                            onTap: () => widget.onNavigateTab(3), // Schedule tab
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'ব্যর্থ পাবলিশিং',
                            count: dashboard.failedCount,
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.danger,
                            bgColor: AppColors.dangerLight,
                            onTap: () => widget.onNavigateTab(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recently Published Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'সম্প্রতি প্রকাশিত',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateTab(1),
                          child: const Text('সব দেখুন'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Recent Published List
                    if (dashboard.recentPublished.isEmpty)
                      _buildEmptyState('কোনো প্রকাশিত সংবাদ পাওয়া যায়নি')
                    else
                      ...dashboard.recentPublished.map((article) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: article.featuredMedia != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        article.featuredMedia!.url,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
                                      ),
                                    )
                                  : Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.newspaper, color: AppColors.primary),
                                    ),
                              title: Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    if (article.category != null) ...[
                                      Text(
                                        article.category!,
                                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    const StatusBadge(status: 'published'),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CreateArticleScreen(existingArticle: article)),
                                );
                              },
                            ),
                          )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
      ),
    );
  }
}
