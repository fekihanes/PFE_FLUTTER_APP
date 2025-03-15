import 'package:flutter_application/classes/Paginated/PageLink.dart';
import 'package:flutter_application/classes/Product.dart';

class PaginatedProductResponse {
  int currentPage;
  List<Product> data;
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

  PaginatedProductResponse({
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
  factory PaginatedProductResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<Product> products =
        list.map((productJson) => Product.fromJson(productJson)).toList();

    var linkList = json['links'] as List? ?? [];
    List<PageLink> pageLinks =
        linkList.map((linkJson) => PageLink.fromJson(linkJson)).toList();

    return PaginatedProductResponse(
      currentPage: json['current_page'] ?? 0,
      data: products,
      firstPageUrl: json['first_page_url'],
      from: json['from'] ?? 0,
      lastPage: json['last_page'] ?? 0,
      lastPageUrl: json['last_page_url'],
      links: pageLinks,
      nextPageUrl: json['next_page_url'],
      path: json['path'] ?? '',
      perPage: json['per_page'] ?? 0,
      prevPageUrl: json['prev_page_url'],
      to: json['to'] ?? 0,
      total: json['total'] ?? 0,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'data': data.map((product) => product.toJson()).toList(),
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


