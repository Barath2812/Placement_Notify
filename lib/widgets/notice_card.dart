import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../models/notice.dart';
import '../providers/auth_provider.dart';
import '../providers/notice_provider.dart';
import '../services/api_service.dart';

class NoticeCard extends StatefulWidget {
  final Notice notice;
  final VoidCallback onTap;

  const NoticeCard({
    super.key,
    required this.notice,
    required this.onTap,
  });

  @override
  State<NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<NoticeCard> {
  bool _isExpandedSummary = false;
  bool _isLoadingSummary = false;
  String? _summaryText;
  String? _summaryError;

  Future<void> _openAttachmentUrl(BuildContext context, String url) async {
    String targetUrl = url;
    if (url.startsWith('https://placeholder-url.com') ||
        url.contains('localhost:5000') ||
        url.contains('127.0.0.1:5000') ||
        url.contains('10.0.2.2:5000')) {
      final Uri tempUri = Uri.parse(url);
      if (tempUri.pathSegments.isNotEmpty) {
        final String filename = tempUri.pathSegments.last;
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
    final noticeProvider = Provider.of<NoticeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final bool isRead = noticeProvider.readNoticeIds.contains(widget.notice.id);
    final bool isBookmarked = authProvider.currentUser?.bookmarks.contains(widget.notice.id) ?? false;
    
    final Color categoryColor = AppColors.categoryColors[widget.notice.category] ?? AppColors.primary;
    final String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(widget.notice.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(
          color: isRead ? const Color(0xFFE2E8F0) : AppColors.accent.withOpacity(0.3),
          width: isRead ? 1 : 1.5,
        ),
      ),
      elevation: isRead ? 0 : 2,
      shadowColor: AppColors.accent.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          noticeProvider.markAsRead(widget.notice.id, authProvider.currentUser?.uid ?? 'guest');
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Chip & Date & Unread Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.notice.category.toUpperCase(),
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Notice Subject
              Text(
                widget.notice.subject,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Sender info
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.notice.from,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Short preview text
              Text(
                widget.notice.bodyText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Inline AI Summary Panel (if expanded)
              if (_isExpandedSummary || _isLoadingSummary) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.accent, size: 15),
                          const SizedBox(width: 6),
                          const Text(
                            'AI Summary',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoadingSummary)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.accent,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingSummary)
                        const Text(
                          'Generating summary using Groq...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else if (_summaryText != null)
                        Text(
                          _summaryText!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        )
                      else if (_summaryError != null)
                        Text(
                          _summaryError!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Attachments pills (directly download from card)
              if (widget.notice.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.notice.attachments.map((attach) {
                    final isPdf = attach.name.toLowerCase().endsWith('.pdf') || 
                                  attach.mimeType == 'application/pdf';
                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                        foregroundColor: isPdf ? Colors.red.shade700 : Colors.blue.shade800,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isPdf ? Colors.red.shade100 : Colors.blue.shade100,
                          ),
                        ),
                      ),
                      icon: Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                        size: 13,
                      ),
                      label: Text(
                        attach.name.length > 20 
                            ? '${attach.name.substring(0, 17)}...' 
                            : attach.name,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openAttachmentUrl(context, attach.url),
                    );
                  }).toList(),
                ),
              ],
              
              const Divider(height: 24, color: Color(0xFFE2E8F0)),
              
              // Bottom Action bar inside Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Summarize Toggle Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      _isExpandedSummary ? Icons.expand_less : Icons.auto_awesome,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    label: Text(
                      _isExpandedSummary ? 'Hide Summary' : 'Summarize',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      if (_isExpandedSummary) {
                        setState(() {
                          _isExpandedSummary = false;
                        });
                        return;
                      }

                      if (_summaryText != null) {
                        setState(() {
                          _isExpandedSummary = true;
                        });
                        return;
                      }

                      setState(() {
                        _isLoadingSummary = true;
                        _summaryError = null;
                      });

                      try {
                        final summary = await noticeProvider.fetchAiSummary(
                          widget.notice.id, 
                          widget.notice.bodyText,
                        );
                        setState(() {
                          _summaryText = summary;
                          _isExpandedSummary = true;
                        });
                      } catch (_) {
                        setState(() {
                          _summaryError = 'Failed to load AI summary.';
                        });
                      } finally {
                        setState(() {
                          _isLoadingSummary = false;
                        });
                      }
                    },
                  ),
                  
                  // Bookmark Toggle Button
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppColors.accent : AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () {
                      noticeProvider.toggleBookmark(
                        widget.notice.id,
                        !isBookmarked,
                        (id, status) => authProvider.toggleLocalBookmark(id, status),
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
