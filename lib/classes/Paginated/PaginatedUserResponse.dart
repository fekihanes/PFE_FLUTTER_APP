import 'package:flutter_application/classes/Paginated/PageLink.dart';
import 'package:flutter_application/classes/user_class.dart';

class PaginatedUserResponse {
  int currentPage;
  List<UserClass> data;
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


  PaginatedUserResponse({
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
  factory PaginatedUserResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<UserClass> users =
        list.map((userJson) => UserClass.fromJson(userJson)).toList();

    var linkList = json['links'] as List;
    List<PageLink> pageLinks =
        linkList.map((linkJson) => PageLink.fromJson(linkJson)).toList();

    return PaginatedUserResponse(
      currentPage: json['current_page'],
      data: users,
      firstPageUrl: json['first_page_url'],
      from: json['from'],
      lastPage: json['last_page'],
      lastPageUrl: json['last_page_url'],
      links: pageLinks,
      nextPageUrl: json['next_page_url'],
      path: json['path'],
      perPage: json['per_page'],
      prevPageUrl: json['prev_page_url'],
      to: json['to'],
      total: json['total'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'data': data.map((user) => user.toJson()).toList(),
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
