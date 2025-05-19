class Melange {
  final int id;
  final int idBakery;
  final DateTime day;
  final List<MelangeWork> work;

  Melange({
    required this.id,
    required this.idBakery,
    required this.day,
    required this.work,
  });

  factory Melange.fromJson(Map<String, dynamic> json) {
    var workList = (json['work'] as List<dynamic>)
        .map((e) => MelangeWork.fromJson(e))
        .toList();

    return Melange(
      id: json['id'] ?? 0,
      idBakery: json['bakery_id'],
      day: DateTime.parse(json['day']),
      work: workList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bakery_id': idBakery,
      'day': day.toIso8601String(),
      'work': work.map((e) => e.toJson()).toList(),
    };
  }
}

class MelangeWork {
  final String time;
   String? etap;

  final List<int> productIds;
  final List<int> quantities;


  MelangeWork({
    required this.time,
     this.etap,
    required this.productIds,
    required this.quantities,
  });

  factory MelangeWork.fromJson(Map<String, dynamic> json) {
    return MelangeWork(
      time: json['time'],
      etap: json['etap'] ?? '',
      productIds: List<int>.from(json['product_ids']),
      quantities: List<int>.from(json['quantities']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'product_ids': productIds,
      'quantities': quantities,
         };
  }
}
