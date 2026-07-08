import 'dart:io' show Platform;

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart' show SizeContext;
import 'package:mysafar_sdk/src/cubit/main/news/news_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/main/widgets/news_list_view.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  static const routeName = '/notification';

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NewsCubit>(
      create: (_) => NewsCubit(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(
            "notifications_title".tr(),
            style: context.textTheme.bodyMedium,
          ),
          elevation: 4.0,
          shadowColor: Colors.black38,
        ),
        body: Padding(
          padding: context.k16horizontalPadding,
          child: Column(
            children: [
              context.szBoxHeight16,
              // Flight type row
              SizedBox(
                width: double.infinity,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Color.fromRGBO(198, 199, 201, 0.15),
                      borderRadius: BorderRadius.circular(8.0)),
                  child: TabBar(
                      controller: _tabController,
                      splashFactory:
                          Platform.isIOS ? NoSplash.splashFactory : null,
                      onTap: (value) {},
                      splashBorderRadius: BorderRadius.circular(8),
                      dividerColor: Colors.transparent,
                      indicatorColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                          color: Color(0xff0057BE),
                          borderRadius: BorderRadius.circular(8)),
                      labelColor: Colors.white,
                      tabs: [
                        Tab(
                          child: Text(
                            "notification_page_news".tr(),
                          ),
                        ),
                        Tab(
                          child: Text(
                            "notification_page_notify".tr(),
                          ),
                        )
                      ]),
                ),
              ),
              context.szBoxHeight8,
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 1-tab: Firestore'dan yangiliklar
                    const NewsListView(),
                    // 2-tab: bildirishnomalar (hozircha bo'sh holat)
                    _EmptyState(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bildirishnomalar tab'i uchun bo'sh holat.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        context.szBoxHeight16,
        Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: Image.asset(Assets.homeNotificationEmpty),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            "notification_page_empty_header".tr(),
            style: context.textTheme.displayMedium?.copyWith(fontSize: 14.0),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            "notification_page_empty_sub".tr(),
            style: context.textTheme.titleMedium?.copyWith(fontSize: 14.0),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
