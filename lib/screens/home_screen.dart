import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/notice_provider.dart';
import '../widgets/notice_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _categories = [
    'Unread',
    'Read'
  ];

  @override
  void initState() {
    super.initState();
    // Load notices on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NoticeProvider>(context, listen: false).refreshNotices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final noticeProvider = Provider.of<NoticeProvider>(context);

    // Sync server-side read statuses to notice provider cache
    if (authProvider.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        noticeProvider.loadUserReadNotices(
          authProvider.currentUser!.uid,
          authProvider.currentUser!.readNotices,
        );
      });
    }

    final String userName = authProvider.currentUser?.name ?? 'Student';
    final String userEmail = authProvider.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sathyabama Placement Notice',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => context.push('/bookmarks'),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              accountName: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(userEmail),
            ),
            
            // Drawer List Items
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('My Bookmarks'),
              onTap: () {
                Navigator.pop(context);
                context.push('/bookmarks');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Sathyabama Notices'),
              onTap: () {
                Navigator.pop(context);
                context.push('/about');
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Column(
        children: [
          // Horizontal Category Chip Filter list
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = noticeProvider.selectedCategory == category;
                
                Color chipSelectedColor = category == 'Read' 
                    ? Colors.green.shade600 
                    : Colors.orange.shade700;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      noticeProvider.setCategory(category);
                    },
                    selectedColor: chipSelectedColor,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected 
                          ? chipSelectedColor 
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Notice List with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () => noticeProvider.refreshNotices(),
              child: noticeProvider.isLoading && noticeProvider.notices.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : noticeProvider.notices.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.campaign_outlined,
                                    size: 64,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No announcements in ${noticeProvider.selectedCategory}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Pull down to refresh new updates',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: noticeProvider.notices.length,
                          itemBuilder: (context, index) {
                            final notice = noticeProvider.notices[index];
                            return NoticeCard(
                              notice: notice,
                              onTap: () {
                                context.push('/notice/${notice.id}');
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      // Floating Sync trigger button for students/admin to poll Gmail immediately
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Polling Gmail inbox for notices...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
          
          final syncResult = await noticeProvider.triggerSync();
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (syncResult['success'] == true) {
            final int imported = syncResult['imported'] ?? 0;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  imported > 0 
                      ? 'Sync complete! Imported $imported new notice(s).' 
                      : 'Sync complete. No new notices found.',
                ),
                backgroundColor: Colors.green.shade700,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sync failed: ${syncResult['error'] ?? 'Unknown Error'}'),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        child: const Icon(Icons.sync),
      ),
    );
  }
}
