import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../models/notice.dart';
import '../providers/auth_provider.dart';
import '../providers/notice_provider.dart';
import '../widgets/notice_card.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final noticeProvider = Provider.of<NoticeProvider>(context);

    final List<String> bookmarkIds = authProvider.currentUser?.bookmarks ?? [];

    // Filter notices to get bookmarked items
    final List<Notice> bookmarkedNotices = noticeProvider.notices
        .where((notice) => bookmarkIds.contains(notice.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookmarks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: bookmarkedNotices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border_outlined,
                      size: 72,
                      color: AppColors.textSecondary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No bookmarked notices',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can bookmark notices from the dashboard or detail screen to read them later, even offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: bookmarkedNotices.length,
              itemBuilder: (context, index) {
                final notice = bookmarkedNotices[index];
                return NoticeCard(
                  notice: notice,
                  onTap: () {
                    context.push('/notice/${notice.id}');
                  },
                );
              },
            ),
    );
  }
}
