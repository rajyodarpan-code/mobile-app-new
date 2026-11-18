import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rajyo_darpan_publisher/core/constants/app_colors.dart';
import 'package:rajyo_darpan_publisher/data/models/article_model.dart';
import 'package:rajyo_darpan_publisher/data/models/category_model.dart';
import 'package:rajyo_darpan_publisher/presentation/providers/article_provider.dart';
import 'package:rajyo_darpan_publisher/presentation/providers/draft_provider.dart';
import 'package:rajyo_darpan_publisher/presentation/widgets/primary_button.dart';

class CreateArticleScreen extends StatefulWidget {
  final ArticleModel? existingArticle;

  const CreateArticleScreen({super.key, this.existingArticle});

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  final _sourceNewsController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _excerptController = TextEditingController();
  final _slugController = TextEditingController();

  final _seoTitleController = TextEditingController();
  final _metaDescriptionController = TextEditingController();
  final _focusKeywordController = TextEditingController();
  final _imageAltController = TextEditingController();
  final _imageCaptionController = TextEditingController();

  // AI Loading states
  bool _isAiGeneratingAll = false;
  bool _isAiGeneratingContent = false;
  bool _isAiGeneratingSeo = false;
  bool _isAiGeneratingImage = false;

  // Categories & Tags
  String? _selectedCategory;
  final List<String> _tags = [];
  final _tagInputController = TextEditingController();

  // Media
  File? _selectedLocalImage;
  int? _featuredMediaId;
  String? _featuredImageUrl;
  bool _isUploadingImage = false;

  // Publishing flags
  bool _isBreakingNews = false;
  bool _isFeaturedNews = false;
  DateTime? _scheduledDateTime;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ArticleProvider>(context, listen: false).fetchPlatformsAndTaxonomies();
    });

    if (widget.existingArticle != null) {
      _populateExistingData(widget.existingArticle!);
    }
  }

  void _populateExistingData(ArticleModel a) {
    _titleController.text = a.title;
    _contentController.text = a.content ?? '';
    _excerptController.text = a.excerpt ?? '';
    _slugController.text = a.slug ?? '';

    _seoTitleController.text = a.seoTitle ?? '';
    _metaDescriptionController.text = a.metaDescription ?? '';
    _focusKeywordController.text = a.focusKeyword ?? '';
    _imageAltController.text = a.imageAlt ?? '';
    _imageCaptionController.text = a.imageCaption ?? '';

    _selectedCategory = a.category;
    _tags.addAll(a.tags);

    if (a.featuredMedia != null) {
      _featuredMediaId = a.featuredMedia!.id;
      _featuredImageUrl = a.featuredMedia!.url;
    }
  }

  // Image Picker
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);

    if (picked != null) {
      setState(() {
        _selectedLocalImage = File(picked.path);
        _isUploadingImage = true;
      });

      try {
        final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
        final media = await articleProvider.uploadImage(
          _selectedLocalImage!,
          altText: _imageAltController.text,
        );

        if (media != null) {
          setState(() {
            _featuredMediaId = media.id;
            _featuredImageUrl = media.url;
            _isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ছবি সফলভাবে আপলোড হয়েছে')),
          );
        }
      } catch (e) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ছবি আপলোডে ব্যর্থ: $e')),
        );
      }
    }
  }

  // Determine primary content to feed AI (Article Body first, fallback to Source News)
  String? _getEffectiveAiContent() {
    final body = _contentController.text.trim();
    if (body.isNotEmpty) return body;
    final source = _sourceNewsController.text.trim();
    if (source.isNotEmpty) return source;
    return null;
  }

  // AI 1: Generate Everything from Source News (updates Article Body + all pages)
  Future<void> _handleAiGenerateEverything() async {
    final source = _sourceNewsController.text.trim();
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে প্রথমে সোর্স খবরের বক্সে লেখা পেস্ট করুন')),
      );
      return;
    }

    setState(() => _isAiGeneratingAll = true);
    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      final output = await articleProvider.generateAIContent(
        type: 'rewrite',
        content: source,
        uuid: widget.existingArticle?.uuid,
      );

      if (output != null) {
        setState(() {
          if (output['title'] != null || output['seo_headline'] != null) {
            _titleController.text = (output['title'] ?? output['seo_headline']).toString();
          }
          if (output['content'] != null || output['article'] != null) {
            _contentController.text = (output['content'] ?? output['article']).toString();
          }
          if (output['excerpt'] != null) {
            _excerptController.text = output['excerpt'].toString();
          }
          if (output['seo_title'] != null) {
            _seoTitleController.text = output['seo_title'].toString();
          }
          if (output['meta_description'] != null) {
            _metaDescriptionController.text = output['meta_description'].toString();
          }
          if (output['focus_keyword'] != null) {
            _focusKeywordController.text = output['focus_keyword'].toString();
          }
          if (output['slug'] != null) {
            _slugController.text = output['slug'].toString();
          }
          if (output['image_alt'] != null) {
            _imageAltController.text = output['image_alt'].toString();
          }
          if (output['image_caption'] != null) {
            _imageCaptionController.text = output['image_caption'].toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✦ AI দিয়ে সমস্ত পেজের তথ্য সফলভাবে তৈরি হয়েছে')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI তৈরিতে সমস্যা হয়েছে: $e')),
      );
    } finally {
      setState(() => _isAiGeneratingAll = false);
    }
  }

  // AI 2: Generate for All based on Article Body (Article Body text stays intact!)
  Future<void> _handleAiGenerateForAllFromArticleBody() async {
    final effectiveContent = _getEffectiveAiContent();
    if (effectiveContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে আর্টিকেলের বডিতে কিছু টেক্সট লিখুন বা সোর্স টেক্সট দিন')),
      );
      return;
    }

    setState(() => _isAiGeneratingAll = true);
    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      final output = await articleProvider.generateAIContent(
        type: 'rewrite',
        content: effectiveContent,
        uuid: widget.existingArticle?.uuid,
      );

      if (output != null) {
        setState(() {
          // Notice: _contentController.text is NOT overwritten! It stays intact.
          if (output['title'] != null || output['seo_headline'] != null) {
            _titleController.text = (output['title'] ?? output['seo_headline']).toString();
          }
          if (output['excerpt'] != null) {
            _excerptController.text = output['excerpt'].toString();
          }
          if (output['seo_title'] != null) {
            _seoTitleController.text = output['seo_title'].toString();
          }
          if (output['meta_description'] != null) {
            _metaDescriptionController.text = output['meta_description'].toString();
          }
          if (output['focus_keyword'] != null) {
            _focusKeywordController.text = output['focus_keyword'].toString();
          }
          if (output['slug'] != null) {
            _slugController.text = output['slug'].toString();
          }
          if (output['image_alt'] != null) {
            _imageAltController.text = output['image_alt'].toString();
          }
          if (output['image_caption'] != null) {
            _imageCaptionController.text = output['image_caption'].toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✦ মূল খবর বজায় রেখে বাকি সব পেজ AI দিয়ে তৈরি হয়েছে')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI তৈরিতে সমস্যা হয়েছে: $e')),
      );
    } finally {
      setState(() => _isAiGeneratingAll = false);
    }
  }

  // AI 3: Generate for Content Page only (Headline + Excerpt only)
  Future<void> _handleAiGenerateContentPageOnly() async {
    final effectiveContent = _getEffectiveAiContent();
    if (effectiveContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে আর্টিকেলের বডিতে খবর লিখুন বা সোর্স টেক্সট দিন')),
      );
      return;
    }

    setState(() => _isAiGeneratingContent = true);
    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      final output = await articleProvider.generateAIContent(
        type: 'rewrite',
        content: effectiveContent,
        uuid: widget.existingArticle?.uuid,
      );

      if (output != null) {
        setState(() {
          if (output['title'] != null || output['seo_headline'] != null) {
            _titleController.text = (output['title'] ?? output['seo_headline']).toString();
          }
          if (output['excerpt'] != null) {
            _excerptController.text = output['excerpt'].toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✦ শিরোনাম ও এক্সার্পট সফলভাবে AI দিয়ে তৈরি হয়েছে')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI তৈরিতে সমস্যা হয়েছে: $e')),
      );
    } finally {
      setState(() => _isAiGeneratingContent = false);
    }
  }

  // AI 4: Generate for SEO Page only (SEO Title, Meta Desc, Focus Keyword, Slug)
  Future<void> _handleAiGenerateSeoPageOnly() async {
    final effectiveContent = _getEffectiveAiContent();
    if (effectiveContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে কনটেন্ট পেজে খবর লিখুন বা সোর্স টেক্সট দিন')),
      );
      return;
    }

    setState(() => _isAiGeneratingSeo = true);
    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      final output = await articleProvider.generateAIContent(
        type: 'seo',
        content: effectiveContent,
        uuid: widget.existingArticle?.uuid,
      );

      if (output != null) {
        setState(() {
          if (output['seo_title'] != null) {
            _seoTitleController.text = output['seo_title'].toString();
          }
          if (output['meta_description'] != null) {
            _metaDescriptionController.text = output['meta_description'].toString();
          }
          if (output['focus_keyword'] != null) {
            _focusKeywordController.text = output['focus_keyword'].toString();
          }
          if (output['slug'] != null) {
            _slugController.text = output['slug'].toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✦ এসইও পেজের সমস্ত তথ্য সফলভাবে AI দিয়ে তৈরি হয়েছে')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SEO তৈরিতে সমস্যা হয়েছে: $e')),
      );
    } finally {
      setState(() => _isAiGeneratingSeo = false);
    }
  }

  // AI 5: Generate for Image Page only (Image Alt Text + Caption using Vision AI if image exists)
  Future<void> _handleAiGenerateImagePageOnly() async {
    final effectiveContent = _getEffectiveAiContent();
    if (effectiveContent == null && _selectedLocalImage == null && _featuredImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে ছবি সিলেক্ট করুন বা কনটেন্ট পেজে খবর লিখুন')),
      );
      return;
    }

    setState(() => _isAiGeneratingImage = true);
    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);

      String? imageBase64;
      String? imageMimeType;
      String? imageUrl;

      if (_selectedLocalImage != null) {
        final bytes = await _selectedLocalImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
        final ext = _selectedLocalImage!.path.split('.').last.toLowerCase();
        imageMimeType = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      } else if (_featuredImageUrl != null && _featuredImageUrl!.startsWith('http')) {
        imageUrl = _featuredImageUrl;
      }

      final output = await articleProvider.generateAIContent(
        type: 'image',
        content: effectiveContent ?? 'এই ছবির জন্য সংবাদপত্রের উপযোগী অল্ট টেক্সট ও ক্যাপশন তৈরি করুন।',
        uuid: widget.existingArticle?.uuid,
        imageBase64: imageBase64,
        imageMimeType: imageMimeType,
        imageUrl: imageUrl,
      );

      if (output != null) {
        setState(() {
          if (output['image_alt'] != null) {
            _imageAltController.text = output['image_alt'].toString();
          }
          if (output['image_caption'] != null) {
            _imageCaptionController.text = output['image_caption'].toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imageBase64 != null || imageUrl != null
                  ? '✦ Vision AI দিয়ে ছবি বিশ্লেষণ করে অল্ট টেক্সট ও ক্যাপশন তৈরি হয়েছে'
                  : '✦ ছবির অল্টারনেটিভ টেক্সট ও ক্যাপশন AI দিয়ে তৈরি হয়েছে',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ছবির বিবরণ তৈরিতে সমস্যা হয়েছে: $e')),
      );
    } finally {
      setState(() => _isAiGeneratingImage = false);
    }
  }

  // Auto-save local draft
  Future<void> _saveLocalDraft() async {
    final draftProvider = Provider.of<DraftProvider>(context, listen: false);
    final draft = LocalDraft(
      serverUuid: widget.existingArticle?.uuid,
      title: _titleController.text,
      content: _contentController.text,
      excerpt: _excerptController.text,
      slug: _slugController.text,
      category: _selectedCategory,
      tags: _tags,
      seoTitle: _seoTitleController.text,
      metaDescription: _metaDescriptionController.text,
      focusKeyword: _focusKeywordController.text,
      imageAlt: _imageAltController.text,
      imageCaption: _imageCaptionController.text,
      localImagePath: _selectedLocalImage?.path,
      featuredMediaId: _featuredMediaId,
      isBreaking: _isBreakingNews,
      isFeatured: _isFeaturedNews,
      lastModified: DateTime.now().toIso8601String(),
    );

    await draftProvider.autoSaveDraft(draft);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ড্রাফট ডিভাইসে সংরক্ষিত হয়েছে')),
    );
  }

  // Final Action: Save Draft or Publish Now
  Future<void> _handlePublishAction({bool isDraftOnly = false}) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('হেডলাইন বা শিরোনাম আবশ্যক')),
      );
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isSubmitting = true);
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);

    try {
      // 1. Save / Update Article in Laravel backend
      final savedArticle = await articleProvider.saveOrUpdateArticle(
        uuid: widget.existingArticle?.uuid,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        excerpt: _excerptController.text.trim(),
        slug: _slugController.text.trim().isNotEmpty ? _slugController.text.trim() : null,
        category: _selectedCategory,
        tags: _tags,
        featuredMediaId: _featuredMediaId,
        seoTitle: _seoTitleController.text.trim(),
        metaDescription: _metaDescriptionController.text.trim(),
        focusKeyword: _focusKeywordController.text.trim(),
        imageAlt: _imageAltController.text.trim(),
        imageCaption: _imageCaptionController.text.trim(),
        isBreaking: _isBreakingNews,
        isFeatured: _isFeaturedNews,
      );

      if (savedArticle == null) {
        throw Exception('আর্টিকেল সংরক্ষণ করা যায়নি');
      }

      // 2. If Publish Now or Schedule
      if (!isDraftOnly) {
        await articleProvider.publishArticle(
          uuid: savedArticle.uuid,
          scheduleAt: _scheduledDateTime,
          status: _scheduledDateTime != null ? 'future' : 'publish',
        );
      }

      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isDraftOnly ? Icons.check_circle : Icons.cloud_done_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(isDraftOnly ? 'ড্রাফট সংরক্ষিত' : (_scheduledDateTime != null ? 'শিডিউল সম্পন্ন' : 'সফলভাবে প্রকাশিত')),
            ],
          ),
          content: Text(
            isDraftOnly
                ? 'আর্টিকেলটি সফলভাবে ড্রাফট হিসেবে জমা হয়েছে।'
                : (_scheduledDateTime != null
                    ? 'আর্টিকেলটি নির্ধারিত সময়ে স্বয়ংক্রিয়ভাবে ওয়ার্ডপ্রেসে প্রকাশিত হবে।'
                    : 'আর্টিকেলটি সফলভাবে ওয়ার্ডপ্রেস ও রাজ্য দর্পণে প্রকাশিত হয়েছে।'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to previous screen
              },
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('সমস্যা দেখা দিয়েছে: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingArticle != null ? 'আর্টিকেল সম্পাদনা' : 'নতুন সংবাদ লিখুন',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.existingArticle != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'সংবাদ মুছে ফেলুন',
              onPressed: () {
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
                    content: const Text(
                      'আপনি কি নিশ্চিত যে এই সংবাদটি মুছে ফেলতে চান?\n\nএটি প্যানেল থেকে মুছে যাবে এবং ওয়েবসাইট থেকেও স্বয়ংক্রিয়ভাবে ট্র্যাশে (Trash) চলে যাবে।',
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
                                .deleteArticle(widget.existingArticle!.uuid);
                            if (success && mounted) {
                              Navigator.pop(context); // Go back to list
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
              },
            ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'লোকাল ড্রাফট সংরক্ষণ',
            onPressed: _saveLocalDraft,
          ),
          TextButton(
            onPressed: _isSubmitting ? null : () => _handlePublishAction(isDraftOnly: true),
            child: const Text('ড্রাফট সেভ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '১. কনটেন্ট'),
            Tab(text: '২. এসইও'),
            Tab(text: '৩. ক্যাটাগরি'),
            Tab(text: '৪. ছবি'),
            Tab(text: '৫. পাবলিশ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContentTab(),
          _buildSeoTab(),
          _buildCategoryTab(),
          _buildMediaTab(),
          _buildPublishTab(),
        ],
      ),
    );
  }

  // STEP 1: Content
  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Source News Box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.feed_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'সোর্স খবর / প্রেস রিলিজ (Source News)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    if (_sourceNewsController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'মুছে ফেলুন',
                        onPressed: () => setState(() => _sourceNewsController.clear()),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sourceNewsController,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'এখানে যে কোনো সোর্স খবর, প্রেস রিলিজ বা রেফারেন্স টেক্সট পেস্ট করুন...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCBD5E1))),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                // Button: Generate Everything
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isAiGeneratingAll ? null : _handleAiGenerateEverything,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED), // vibrant purple for master AI action
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isAiGeneratingAll
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      _isAiGeneratingAll ? 'AI দিয়ে তৈরি হচ্ছে...' : '✦ Generate Everything (সমস্ত পেজ একসাথে লিখুন)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Headline
          TextField(
            controller: _titleController,
            maxLines: 2,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'সংবাদের শিরোনাম / হেডলাইন *',
              hintText: 'এখানে সংবাদের আকর্ষণীয় শিরোনাম লিখুন...',
            ),
          ),
          const SizedBox(height: 16),

          // Excerpt
          TextField(
            controller: _excerptController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'সংক্ষিপ্ত বিবরণ (Excerpt)',
              hintText: 'সংবাদের ছোট সারসংক্ষেপ...',
            ),
          ),
          const SizedBox(height: 16),

          // Body (Rich Text Multi-line Editor)
          const Text(
            'সংবাদের মূল বিষয়বস্তু (Article Body) *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.format_bold, size: 20),
                        onPressed: () => _wrapSelectedText('<strong>', '</strong>'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_italic, size: 20),
                        onPressed: () => _wrapSelectedText('<em>', '</em>'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_list_bulleted, size: 20),
                        onPressed: () => _wrapSelectedText('<ul>\n<li>', '</li>\n</ul>'),
                      ),
                      const Spacer(),
                      Text(
                        'শব্দ: ${_contentController.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: _contentController,
                  maxLines: 15,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'এখানে সংবাদের পূর্ণ বিবরণ লিখুন বা পেস্ট করুন...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Buttons below Article Body:
          // 1. Generate for All (Body unchanged)
          // 2. Generate for This Page Only
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAiGeneratingAll ? null : _handleAiGenerateForAllFromArticleBody,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6D28D9),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isAiGeneratingAll
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_motion_outlined, size: 16),
                  label: const Text(
                    '✦ Generate for All\n(বডি অপরিবর্তিত থাকবে)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAiGeneratingContent ? null : _handleAiGenerateContentPageOnly,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isAiGeneratingContent
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: const Text(
                    '✦ Generate for\nThis Page Only',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            text: 'পরবর্তী ধাপ (এসইও)',
            onPressed: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }

  void _wrapSelectedText(String open, String close) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start < 0 || selection.end < 0) return;

    final selected = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(selection.start, selection.end, '$open$selected$close');
    _contentController.text = newText;
  }

  // STEP 2: SEO
  Widget _buildSeoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AI Button for SEO Page only
          OutlinedButton.icon(
            onPressed: _isAiGeneratingSeo ? null : _handleAiGenerateSeoPageOnly,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isAiGeneratingSeo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 16),
            label: Text(
              _isAiGeneratingSeo ? 'SEO তথ্য তৈরি হচ্ছে...' : '✦ Generate for This Page Only (SEO Title, Meta & Slug)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _seoTitleController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'SEO Title (সার্চ ইঞ্জিনের জন্য শিরোনাম)',
              suffixText: '${_seoTitleController.text.length}/60',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _metaDescriptionController,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Meta Description (মেটা বিবরণী)',
              suffixText: '${_metaDescriptionController.text.length}/160',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _focusKeywordController,
            decoration: const InputDecoration(
              labelText: 'Focus Keyword (প্রধান কী-ওয়ার্ড)',
              hintText: 'যেমন: কলকাতা, নির্বাচন, রাজনীতি',
            ),
          ),
          const SizedBox(height: 16),
          // Slug
          TextField(
            controller: _slugController,
            decoration: const InputDecoration(
              labelText: 'ইউআরএল স্লাগ (URL Slug)',
              hintText: 'ইংরেজি বা বাংলায় স্লাগ (খালি রাখলে স্বয়ংক্রিয় তৈরি হবে)',
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'পরবর্তী ধাপ (ক্যাটাগরি ও ট্যাগ)',
            onPressed: () => _tabController.animateTo(2),
          ),
        ],
      ),
    );
  }

  // STEP 3: Categories & Tags
  Widget _buildCategoryTab() {
    final articleProvider = Provider.of<ArticleProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'সংবাদের ক্যাটাগরি নির্বাচন করুন *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Dropdown for WP categories
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCategory,
                hint: const Text('ক্যাটাগরি সিলেক্ট করুন'),
                items: articleProvider.categories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.name,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'ট্যাগসমূহ (Tags)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagInputController,
                  decoration: const InputDecoration(
                    hintText: 'ট্যাগ লিখুন...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addTag,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(60, 48),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tag chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: AppColors.primaryLight,
                deleteIconColor: AppColors.primary,
                onDeleted: () => setState(() => _tags.remove(tag)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            text: 'পরবর্তী ধাপ (ফিচার্ড ছবি)',
            onPressed: () => _tabController.animateTo(3),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    final t = _tagInputController.text.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() {
        _tags.add(t);
        _tagInputController.clear();
      });
    }
  }

  // STEP 4: Featured Image
  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ফিচার্ড ইমেজ (Featured Image)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Image Preview Container
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: _isUploadingImage
                ? const Center(child: CircularProgressIndicator())
                : _featuredImageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_featuredImageUrl!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _featuredMediaId = null;
                                    _featuredImageUrl = null;
                                    _selectedLocalImage = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 56, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            const Text('এখনো কোনো ছবি যুক্ত করা হয়নি', style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
          ),
          const SizedBox(height: 16),

          // Upload Options
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('গ্যালারি থেকে নিন'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('ক্যামেরা দিয়ে তুলুন'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // WordPress Image Alt Text & Caption Header & AI Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ওয়ার্ডপ্রেস ছবির তথ্য',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              OutlinedButton.icon(
                onPressed: _isAiGeneratingImage ? null : _handleAiGenerateImagePageOnly,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isAiGeneratingImage
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 14),
                label: Text(
                  _isAiGeneratingImage ? 'তৈরি হচ্ছে...' : '✦ Generate for This Page',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // WordPress Image Alt Text & Caption
          TextField(
            controller: _imageAltController,
            decoration: const InputDecoration(
              labelText: 'ছবির অল্টারনেটিভ টেক্সট (Image Alt Text)',
              hintText: 'গুগল এসইওর জন্য ছবির বিবরণ লিখুন...',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _imageCaptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ছবির ক্যাপশন (Image Caption)',
              hintText: 'ওয়েবসাইটে ছবির নিচে প্রদর্শিত হবে (যেমন: ফাইল চিত্র / সংগৃহীত ছবি)...',
              prefixIcon: Icon(Icons.subtitles_outlined),
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            text: 'পরবর্তী ধাপ (পাবলিশিং সেটিংস)',
            onPressed: () => _tabController.animateTo(4),
          ),
        ],
      ),
    );
  }

  // STEP 5: Publishing Settings
  Widget _buildPublishTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Custom Rajyo Flags
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('ব্রেকিং নিউজ (Breaking News)'),
                    subtitle: const Text('ওয়েবসাইটের ব্রেকিং হেডলাইনে প্রদর্শন করুন'),
                    value: _isBreakingNews,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isBreakingNews = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('ফিচার্ড পোস্ট (Homepage Hero)'),
                    subtitle: const Text('হোমপেজের প্রধান ব্যানারে প্রদর্শন করুন'),
                    value: _isFeaturedNews,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isFeaturedNews = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Schedule Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('শিডিউল প্রকাশনা (Schedule For Later)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_scheduledDateTime != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'নির্ধারিত সময়: ${DateFormat('dd MMM yyyy, hh:mm a').format(_scheduledDateTime!)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.info),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.info),
                            onPressed: () => setState(() => _scheduledDateTime = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _selectScheduleDateTime,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(_scheduledDateTime == null ? 'তারিখ ও সময় নির্ধারণ করুন' : 'সময় পরিবর্তন করুন'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          PrimaryButton(
            text: _scheduledDateTime != null ? 'শিডিউল পাবলিশ করুন' : 'এখনই প্রকাশ করুন (Publish Now)',
            isLoading: _isSubmitting,
            icon: Icons.rocket_launch,
            onPressed: () => _handlePublishAction(isDraftOnly: false),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'ড্রাফট হিসেবে রাখুন (Save Draft)',
            isOutlined: true,
            isLoading: _isSubmitting,
            onPressed: () => _handlePublishAction(isDraftOnly: true),
          ),
        ],
      ),
    );
  }

  Future<void> _selectScheduleDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
}
