import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/repositories.dart';
import 'package:quick_social/widgets/widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with AutomaticKeepAliveClientMixin {
  late final List<UserNotification> _notifications =
      DummyDataSource.instance.notifications;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;
    final NotificationRepository repository =
        context.watch<NotificationRepository>();

    final bool hasUnread = repository.hasUnread(_notifications);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: ResponsivePadding(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifikasi', style: textTheme.headlineSmall),
                  TextButton.icon(
                    onPressed: hasUnread
                        ? () => repository.markAllRead(_notifications)
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Tandai telah dibaca'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ResponsivePadding(
        child: ListView.builder(
          itemCount: _notifications.length,
          itemBuilder: (_, index) {
            return NotificationTile(notification: _notifications[index]);
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
