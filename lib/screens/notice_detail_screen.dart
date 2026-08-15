import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../core/constants.dart';
import '../models/notice.dart';
import '../providers/auth_provider.dart';
import '../providers/notice_provider.dart';

class NoticeDetailScreen extends StatefulWidget {
  final String noticeId;

  const NoticeDetailScreen({
    super.key,
    required this.noticeId,
  });

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  bool _isLoadingSummary = false;
  String? _aiSummary;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    // Mark as read when entering details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid ?? 'guest';
      Provider.of<NoticeProvider>(context, listen: false).markAsRead(widget.noticeId, currentUserId);
    });
  }

  Future<void> _generateSummary(Notice notice) async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final noticeProvider = Provider.of<NoticeProvider>(context, listen: false);
      final summary = await noticeProvider.fetchAiSummary(notice.id, notice.bodyText);
      setState(() {
        _aiSummary = summary;
      });
    } catch (e) {
      setState(() {
        _summaryError = 'Failed to load AI summary.';
      });
    } finally {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _openAttachmentUrl(String url) async {
    String targetUrl = url;
    if (url.startsWith('https://placeholder-url.com') ||
        url.contains('localhost:5000') ||
        url.contains('127.0.0.1:5000') ||
        url.contains('10.0.2.2:5000')) {
      final Uri tempUri = Uri.parse(url);
      if (tempUri.pathSegments.isNotEmpty) {
        final String filename = tempUri.pathSegments.last;
        // Replace base with production API base URL
        targetUrl = '${ApiConfig.baseUrl}/attachments/${Uri.encodeComponent(filename)}';
      }
    }

    final Uri uri = Uri.parse(targetUrl);
    try {
      await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open attachment link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final noticeProvider = Provider.of<NoticeProvider>(context);

    // Find notice from the unfiltered list
    Notice? foundNotice;
    try {
      foundNotice = noticeProvider.allNotices.firstWhere((n) => n.id == widget.noticeId);
    } catch (_) {
      foundNotice = null;
    }

    if (foundNotice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcement Details')),
        body: const Center(
          child: Text('Announcement not found or cached locally.'),
        ),
      );
    }

    final Notice notice = foundNotice;

    final bool isBookmarked = authProvider.currentUser?.bookmarks.contains(notice.id) ?? false;
    final bool isRead = noticeProvider.readNoticeIds.contains(notice.id);
    final Color categoryColor = AppColors.categoryColors[notice.category] ?? AppColors.primary;
    final String formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(notice.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        actions: [
          // Bookmark Action
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              noticeProvider.toggleBookmark(
                notice.id,
                !isBookmarked,
                (id, status) => authProvider.toggleLocalBookmark(id, status),
              );
            },
          ),
          // Mark Read/Unread Action
          IconButton(
            icon: Icon(isRead ? Icons.mark_email_read : Icons.mark_email_unread),
            onPressed: () {
              noticeProvider.toggleReadStatus(notice.id, authProvider.currentUser?.uid ?? 'guest');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isRead ? 'Marked notice as unread' : 'Marked notice as read'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tag and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notice.category.toUpperCase(),
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject Title
            Text(
              notice.subject,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // From / Sender Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: categoryColor.withOpacity(0.2),
                    child: Icon(Icons.person, color: categoryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sender / Channel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          notice.from,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Smart Summarizer Panel
            Card(
              color: AppColors.accent.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.accent.withOpacity(0.15), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Smart Summary',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        if (_aiSummary == null && !_isLoadingSummary)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.bolt, size: 16),
                            label: const Text('Summarize'),
                            onPressed: () => _generateSummary(notice),
                          )
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingSummary)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          ),
                        ),
                      )
                    else if (_aiSummary != null)
                      Text(
                        _aiSummary!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      )
                    else if (_summaryError != null)
                      Text(
                        _summaryError!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      )
                    else
                      const Text(
                        'Want a quick overview? Generate a 2-line summary of this notice.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Main Notice Body Content
            const Text(
              'Notice Details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            MarkdownBody(
              data: notice.bodyText,
              selectable: true,
              softLineBreak: true,
              extensionSet: md.ExtensionSet.gitHubFlavored,
              onTapLink: (text, href, title) {
                if (href != null) {
                  _openAttachmentUrl(href);
                }
              },
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.6,
                ),
                a: const TextStyle(
                  color: AppColors.accent,
                  decoration: TextDecoration.underline,
                ),
                strong: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                em: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Attachments Section
            if (notice.attachments.isNotEmpty) ...[
              const Text(
                'Attachments',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notice.attachments.length,
                itemBuilder: (context, index) {
                  final attach = notice.attachments[index];
                  final isPdf = attach.name.toLowerCase().endsWith('.pdf') || 
                                attach.mimeType == 'application/pdf';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                        color: isPdf ? Colors.red : Colors.blue,
                        size: 32,
                      ),
                      title: Text(
                        attach.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        isPdf ? 'PDF Document' : 'Attachment File',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.download, color: AppColors.accent),
                      onTap: () => _openAttachmentUrl(attach.url),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
