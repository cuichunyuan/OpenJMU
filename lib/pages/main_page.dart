import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/pages/home/app_center_page.dart';
import 'package:openjmu/pages/home/apps_page.dart';
import 'package:openjmu/pages/home/marketing_page.dart';
import 'package:openjmu/pages/home/message_page.dart';
import 'package:openjmu/pages/home/post_square_page.dart';
import 'package:openjmu/pages/home/self_page.dart';

@FFRoute(
  name: 'openjmu://home',
  routeName: '首页',
  argumentNames: ['initAction'],
)
class MainPage extends StatefulWidget {
  const MainPage({
    Key key,
    this.initAction,
  }) : super(key: key);

  /// Which page should be loaded at the first init time.
  /// 设置应初始化加载的页面索引
  final int initAction;

  @override
  State<StatefulWidget> createState() => MainPageState();
}

class MainPageState extends State<MainPage> with AutomaticKeepAliveClientMixin {
  /// Titles for bottom navigation.
  /// 底部导航的各项标题
  static const List<String> pagesTitle = <String>['广场', '集市', '课业', '消息'];

  /// Icons for bottom navigation.
  /// 底部导航的各项图标
  static const List<String> pagesIcon = <String>[
    R.ASSETS_ICONS_BOTTOM_NAVIGATION_SQUARE_SVG,
    R.ASSETS_ICONS_BOTTOM_NAVIGATION_MARKET_SVG,
    R.ASSETS_ICONS_BOTTOM_NAVIGATION_SCHOOL_WORK_SVG,
    R.ASSETS_ICONS_BOTTOM_NAVIGATION_MESSAGES_SVG,
  ];

  /// Bottom navigation bar's height;
  /// 底部导航的高度
  static const double bottomBarHeight = 72.0;

  /// Base text style for [TabBar].
  /// 顶部Tab的文字样式基类
  static TextStyle get _baseTabTextStyle => TextStyle(
        fontSize: 23.0.sp,
        textBaseline: TextBaseline.alphabetic,
      );

  /// Selected text style for [TabBar].
  /// 选中的Tab文字样式
  static TextStyle get tabSelectedTextStyle => _baseTabTextStyle.copyWith(
        fontWeight: FontWeight.bold,
      );

  /// Un-selected text style for [TabBar].
  /// 未选中的Tab文字样式
  static TextStyle get tabUnselectedTextStyle => _baseTabTextStyle.copyWith(
        fontWeight: FontWeight.w300,
      );

  /// Controller for app center page.
  /// 应用页控制器
  final PageController appPageController = PageController();

  /// Stream controller for vertical page scrolling offset percent.
  /// 垂直滚动偏移百分比的流控制器，用于更改遮罩
  final StreamController<double> pageOffsetStreamController = StreamController<double>();

  /// Index for pages.
  /// 当前页面索引
  int _currentIndex;

  /// Icon size for bottom navigation bar's item.
  /// 底部导航的图标大小
  double get bottomBarIconSize => bottomBarHeight / 2.25;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    trueDebugPrint('CurrentUser ${UserAPI.currentUser}');

    /// Initialize current page index.
    /// 设定初始页面
    _currentIndex = widget.initAction ??
        Provider.of<SettingsProvider>(currentContext, listen: false).homeSplashIndex;

    appPageController.addListener(() {
      pageOffsetStreamController.add(appPageController.page);
    });

    Instances.eventBus
      ..on<ActionsEvent>().listen((ActionsEvent event) {
        /// Listen to actions event to react with quick actions both on Android and iOS.
        /// 监听原生捷径时间以切换页面
        final int index = Constants.quickActionsList.keys.toList().indexOf(event.type);
        if (index != -1) {
          _selectedTab(index);
          if (mounted) setState(() {});
        }
      });
  }

  /// Method to update index.
  /// 切换页面方法
  void _selectedTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  /// Announcement widget.
  /// 公告组件
  Widget get announcementWidget => Selector<SettingsProvider, bool>(
        selector: (_, SettingsProvider provider) => provider.announcementsUserEnabled,
        builder: (_, bool announcementsUserEnabled, __) {
          if (announcementsUserEnabled) {
            return const AnnouncementWidget(gap: 24.0, canClose: true);
          } else {
            return const SizedBox.shrink();
          }
        },
      );

  /// Bottom navigation bar.
  /// 底部导航栏
  Widget get bottomNavigationBar => FABBottomAppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        color: Colors.grey[600].withOpacity(currentIsDark ? 0.8 : 0.4),
        height: bottomBarHeight,
        iconSize: bottomBarIconSize,
        selectedColor: currentThemeColor,
        itemFontSize: 16.0,
        onTabSelected: _selectedTab,
        showText: true,
        initIndex: _currentIndex,
        items: List<FABBottomAppBarItem>.generate(
          pagesTitle.length,
          (int i) => FABBottomAppBarItem(iconPath: pagesIcon[i], text: pagesTitle[i]),
        ),
      );

  /// Backdrop for content when app center part lifting up.
  /// 当应用中心拉起时内容区的遮罩
  Widget get contentBackdrop => StreamBuilder<double>(
        initialData: 0.0,
        stream: pageOffsetStreamController.stream,
        builder: (BuildContext _, AsyncSnapshot<double> snapshot) {
          final double page = snapshot.data;
          return BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5.0 * page, sigmaY: 5.0 * page),
            child: IgnorePointer(
              ignoring: page < 0.7,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  appPageController.animateToPage(
                    0,
                    duration: kThemeAnimationDuration,
                    curve: Curves.easeInOut,
                  );
                },
                child: Opacity(opacity: page, child: Container(color: Colors.black54)),
              ),
            ),
          );
        },
      );

  /// Search bar for search pages.
  /// 搜索框
  Widget get searchBar => Padding(
        padding: EdgeInsets.only(top: 20.0.h),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            navigatorState.pushNamed(
              Routes.OPENJMU_SEARCH,
              arguments: <String, dynamic>{'content': null},
            );
          },
          child: Container(
            height: 56.0.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0.w),
              color: Theme.of(context).canvasColor,
            ),
            child: Row(
              children: <Widget>[
                const Spacer(),
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Center(
                    child: SvgPicture.asset(
                      R.ASSETS_ICONS_SEARCH_SVG,
                      width: 24.0.w,
                      color: currentThemeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: doubleBackExit,
      child: Material(
        type: MaterialType.transparency,
        child: ListView(
          padding: EdgeInsets.zero,
          controller: appPageController,
          physics: const PageScrollPhysics(),
          children: <Widget>[
            SizedBox(
              width: Screens.width,
              height: Screens.height,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Scaffold(
                      key: Instances.mainPageScaffoldKey,
                      body: SafeArea(
                        child: Column(
                          children: <Widget>[
                            announcementWidget,
                            Expanded(
                              child: IndexedStack(
                                children: <Widget>[
                                  const PostSquarePage(),
                                  const MarketingPage(),
                                  AppsPage(key: Instances.appsPageStateKey),
                                  const MessagePage(),
                                ],
                                index: _currentIndex,
                              ),
                            ),
                          ],
                        ),
                      ),
                      drawer: SelfPage(),
                      drawerEdgeDragWidth: Screens.width * 0.25,
                      bottomNavigationBar: bottomNavigationBar,
                    ),
                  ),
                  Positioned.fill(child: contentBackdrop),
                ],
              ),
            ),
            Container(
              width: Screens.width,
              height: Screens.height * 0.7,
              padding: EdgeInsets.symmetric(horizontal: 28.0.w),
              color: Theme.of(context).primaryColor,
              child: Column(
                children: <Widget>[
                  searchBar,
                  const Expanded(child: AppCenterPage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
