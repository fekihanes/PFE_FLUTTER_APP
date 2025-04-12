import 'package:flutter_application/classes/AppNotification.dart';
import 'package:flutter_application/classes/Paginated/PageLink.dart';

class PaginatedNotificationResponse {
  int currentPage;
  List<AppNotification> data;
  String? firstPageUrl;
  int from;
  int lastPage;
  String? lastPageUrl;
  List<PageLink> links;
  String? nextPageUrl;
  String path;
  int perPage;
  String? prevPageUrl;
  int to;
  int total;

  PaginatedNotificationResponse({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    required this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  // From JSON
  factory PaginatedNotificationResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<AppNotification> notifications =
        list.map((productJson) => AppNotification.fromJson(productJson as Map<String, dynamic>)).toList();

    var linkList = json['links'] as List? ?? [];
    List<PageLink> pageLinks =
        linkList.map((linkJson) => PageLink.fromJson(linkJson as Map<String, dynamic>)).toList();

    return PaginatedNotificationResponse(
      currentPage: json['current_page'] as int? ?? 0,
      data: notifications,
      firstPageUrl: json['first_page_url'] as String?,
      from: json['from'] as int? ?? 0,
      lastPage: json['last_page'] as int? ?? 0,
      lastPageUrl: json['last_page_url'] as String?,
      links: pageLinks,
      nextPageUrl: json['next_page_url'] as String?,
      path: json['path'] as String? ?? '',
      perPage: json['per_page'] as int? ?? 0,
      prevPageUrl: json['prev_page_url'] as String?,
      to: json['to'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'data': data.map((notification) => notification.toJson()).toList(),
      'first_page_url': firstPageUrl,
      'from': from,
      'last_page': lastPage,
      'last_page_url': lastPageUrl,
      'links': links.map((link) => link.toJson()).toList(),
      'next_page_url': nextPageUrl,
      'path': path,
      'per_page': perPage,
      'prev_page_url': prevPageUrl,
      'to': to,
      'total': total,
    };
  }
}