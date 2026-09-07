import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/repositories.dart';
import 'package:quick_social/theme/app_tokens.dart';
import 'package:quick_social/widgets/widgets.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key, this.source});

  /// Where the content comes from. Defaults to the shared source; injectable
  /// so a test can drive the empty state.
  final DummyDataSource? source;

  /// How many posts are added per page.
  static const int pageSize = 8;

  /// Stands in for a network round trip.
  ///
  /// The content is local, so without this the loading and refreshing states
  /// would never be visible — or exercised. Keep it short.
  static const Duration fetchDelay = Duration(milliseconds: 250);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ScrollController _scrollController = ScrollController();

  /// The pending simulated fetch, held so it can be cancelled.
  ///
  /// A bare `Future.delayed` cannot be cancelled, and a timer that outlives
  /// the widget fails every test that tears the tree down mid-fetch with
  /// "A Timer is still pending even after the widget tree was disposed".
  Timer? _fetchTimer;
  Completer<void>? _fetchCompleter;

  List<Post> _posts = const [];
  List<UserStory> _stories = const [];

  int _visibleCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  /// How close to the bottom the user must scroll before the next page starts
  /// loading. Roughly one post height, so the spinner rarely gets seen.
  static const double _loadMoreThreshold = 600;

  bool get _hasMore => _visibleCount < _posts.length;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _cancelFetch();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Waits [duration], but in a way that can be cancelled on dispose.
  Future<void> _wait(Duration duration) {
    _cancelFetch();

    final Completer<void> completer = Completer<void>();
    _fetchCompleter = completer;
    _fetchTimer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future;
  }

  void _cancelFetch() {
    _fetchTimer?.cancel();
    _fetchTimer = null;

    final Completer<void>? completer = _fetchCompleter;
    _fetchCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    await _wait(FeedPage.fetchDelay);
    if (!mounted) return;

    final DummyDataSource source = widget.source ?? DummyDataSource.instance;

    setState(() {
      _posts = source.posts;
      _stories = source.userStories;
      _visibleCount = min(FeedPage.pageSize, _posts.length);
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    await _load();
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.jumpTo(0);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final ScrollPosition position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - _loadMoreThreshold) return;

    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isLoading || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    await _wait(FeedPage.fetchDelay);
    if (!mounted) return;

    setState(() {
      _visibleCount = min(_visibleCount + FeedPage.pageSize, _posts.length);
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: ResponsivePadding(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            // Always scrollable, so pull-to-refresh works even when the feed
            // is empty or barely fills the screen.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: _slivers(),
          ),
        ),
      ),
    );
  }

  List<Widget> _slivers() {
    if (_isLoading) {
      return [
        const SliverToBoxAdapter(child: StoryRailSkeleton()),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        SliverList.builder(
          itemCount: 3,
          itemBuilder: _skeletonBuilder,
        ),
      ];
    }

    if (_posts.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              icon: Icons.photo_camera_outlined,
              title: 'Nothing here yet',
              message: 'Posts from people you follow will show up here. '
                  'Pull down to check again.',
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(child: _storyRail(context)),
      const SliverToBoxAdapter(child: Divider(height: 1)),
      SliverList.separated(
        // Only the posts near the viewport are built — the whole point of
        // moving off the nested `shrinkWrap` lists this page used to use.
        itemCount: _visibleCount,
        itemBuilder: (_, index) => PostCard(post: _posts[index]),
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Divider(height: 1),
        ),
      ),
      SliverToBoxAdapter(child: _listFooter()),
    ];
  }

  static Widget _skeletonBuilder(BuildContext context, int index) {
    return const PostSkeleton();
  }

  Widget _storyRail(BuildContext context) {
    // Ordered by the repository: the signed-in user first, then anyone with
    // something unseen, then the rest.
    final List<UserStory> ordered =
        context.watch<StoryRepository>().ordered(_stories);

    return SizedBox(
      height: AppSizes.storyRail,
      child: ListView.builder(
        itemCount: ordered.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemBuilder: (_, index) => UserStoryTile(
          userStory: ordered[index],
          stories: ordered,
          index: index,
        ),
      ),
    );
  }

  Widget _listFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasMore) return const SizedBox(height: AppSpacing.xl);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Text(
          'You are all caught up',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      flexibleSpace: ResponsivePadding(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Scales down rather than overflowing on a 360px phone.
                const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AppLogo(),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Messages',
                  icon: Icon(
                    Icons.send_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
