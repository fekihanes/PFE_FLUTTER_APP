class PageLink {
  String? url;
  String label;
  bool active;

  PageLink({
    this.url,
    required this.label,
    required this.active,
  });

  // From JSON
  factory PageLink.fromJson(Map<String, dynamic> json) {
    return PageLink(
      url: json['url'],
      label: json['label'],
      active: json['active'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'label': label,
      'active': active,
    };
  }
}
