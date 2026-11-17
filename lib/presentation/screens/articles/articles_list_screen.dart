import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rajyo_darpan_publisher/core/constants/app_colors.dart';
import 'package:rajyo_darpan_publisher/presentation/providers/article_provider.dart';
import 'package:rajyo_darpan_publisher/presentation/widgets/status_badge.dart';
import 'package:rajyo_darpan_publisher/presentation/screens/editor/create_article_screen.dart';

class ArticlesListScreen extends StatefulWidget {
  const ArticlesListScreen({super.key});

  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
  String _selectedFilter = 'all';
  final _searchController = TextEditingController();

  final List<Map<String, String>> _filters = [
    {'id': 'all', 'label': 'সকল'},
    {'id': 'published', 'label': 'প্রকাশিত'},
    {'id': 'draft', 'label': 'ড্রাফট'},
    {'id': 'scheduled', 'label': 'শিডিউলড'},
    {'id': 'failed', 'label': 'ব্যর্থ'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ArticleProvider>(context, listen: false).fetchArticles();
    });
  }

  void _onFilterChanged(String filterId) {
    setState(() => _selectedFilter = filterId);
    Provider.of<ArticleProvider>(context, listen: false)
        .fetchArticles(status: filterId, search: _searchController.text);
  }

  void _confirmDeleteArticle(BuildContext context, article) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.danger),
            SizedBox(width: 8),
            Text('সংবাদ মুছে ফেলা'),
          ],
        ),
        content: Text(
          'আপনি কি নিশ্চিত যে "${article.title}" সংবাদটি মুছে ফেলতে চান?\n\nএটি প্যানেল থেকে মুছে যাবে এবং ওয়েবসাইট থেকেও স্বয়ংক্রিয়ভাবে ট্র্যাশে (Trash) চলে যাবে।',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final success = await Provider.of<ArticleProvider>(context, listen: false)
                    .deleteArticle(article.uuid);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('সংবাদটি সফলভাবে ট্র্যাশে সরানো হয়েছে')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('মুছতে ব্যর্থ হয়েছে: $e')),
                  );
                }
              }
            },
            child: const Text('মুছে ফেলুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<ArticleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('সংবাদ তালিকা', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateArticleScreen()),
              ).then((_) => articleProvider.fetchArticles(status: _selectedFilter));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'সংবাদ খুঁজুন...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          articleProvider.fetchArticles(status: _selectedFilter);
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (val) {
                articleProvider.fetchArticles(status: _selectedFilter, search: val);
              },
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f['label']!),
                    selected: isSelected,
                    onSelected: (_) => _onFilterChanged(f['id']!),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Articles List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => articleProvider.fetchArticles(
                status: _selectedFilter,
                search: _searchController.text,
              ),
              child: articleProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : articleProvider.articles.isEmpty
                      ? const Center(
                          child: Text(
                            'কোনো সংবাদ পাওয়া যায়নি',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: articleProvider.articles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final article = articleProvider.articles[index];
                            final hasFailed = article.publishingStatus.any((j) => j.status == 'failed');

                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateArticleScreen(existingArticle: article),
                                    ),
                                  ).then((_) => articleProvider.fetchArticles(status: _selectedFilter));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Thumbnail
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: article.featuredMedia != null
                                                ? Image.network(
                                                    article.featuredMedia!.url,
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(
                                                      width: 70,
                                                      height: 70,
                                                      color: AppColors.primaryLight,
                                                      child: const Icon(Icons.broken_image, color: AppColors.primary),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 70,
                                                    height: 70,
                                                    color: AppColors.primaryLight,
                                                    child: const Icon(Icons.newspaper, color: AppColors.primary),
                                                  ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Content Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  article.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    if (article.category != null) ...[
                                                      Text(
                                                        article.category!,
                                                        style: const TextStyle(
                                                          color: AppColors.primary,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    StatusBadge(status: hasFailed ? 'failed' : article.status),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Delete Action Button
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 22),
                                            tooltip: 'মুছে ফেলুন',
                                            onPressed: () => _confirmDeleteArticle(context, article),
                                          ),
                                        ],
                                      ),

                                      // Action row: retry if failed or quick links
                                      if (hasFailed) ...[
                                        const Divider(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'পাবলিশিং ব্যর্থ হয়েছে',
                                              style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(Icons.refresh, size: 16, color: AppColors.danger),
                                              label: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(color: AppColors.danger)),
                                              onPressed: () async {
                                                final failedJob = article.publishingStatus.firstWhere((j) => j.status == 'failed');
                                                if (failedJob.uuid != null) {
                                                  await articleProvider.retryPublish(article.uuid, failedJob.uuid);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
