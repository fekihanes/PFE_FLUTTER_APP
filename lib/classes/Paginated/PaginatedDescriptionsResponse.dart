import 'package:flutter_application/classes/Descriptions.dart';
import 'package:flutter_application/classes/Paginated/PageLink.dart';

class PaginatedDescriptionsResponse {
  final int currentPage;
  final List<Descriptions> data;
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final List<PageLink> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  PaginatedDescriptionsResponse({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory PaginatedDescriptionsResponse.fromJson(Map<String, dynamic> json) {
    // Gestion des données paginées
    final dataList = (json['data'] as List<dynamic>?) ?? [];
    final descriptions = dataList
        .map((e) => Descriptions.fromJson(e as Map<String, dynamic>))
        .toList();

    // Gestion des liens de pagination
    final linksList = (json['links'] as List<dynamic>?) ?? [];
    final pageLinks = linksList
        .map((e) => PageLink.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaginatedDescriptionsResponse(
      currentPage: (json['current_page'] as int?) ?? 1,
      data: descriptions,
      firstPageUrl: json['first_page_url'] as String?,
      from: json['from'] as int?,
      lastPage: (json['last_page'] as int?) ?? 1,
      lastPageUrl: json['last_page_url'] as String?,
      links: pageLinks,
      nextPageUrl: json['next_page_url'] as String?,
      path: (json['path'] as String?) ?? '',
      perPage: (json['per_page'] as int?) ?? 10,
      prevPageUrl: json['prev_page_url'] as String?,
      to: json['to'] as int?,
      total: (json['total'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'data': data.map((item) => item.toJson()).toList(),
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

