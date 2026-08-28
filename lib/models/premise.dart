class Premise {
  final int premiseCode;
  final String premise;
  final String? address;
  final String? premiseType;
  final String? state;
  final String? district;

  Premise({
    required this.premiseCode,
    required this.premise,
    this.address,
    this.premiseType,
    this.state,
    this.district,
  });

  factory Premise.fromJson(Map<String, dynamic> json) {
    return Premise(
      premiseCode: json['premise_code'] as int,
      premise: json['premise'] as String,
      address: json['address'] as String?,
      premiseType: json['premise_type'] as String?,
      state: json['state'] as String?,
      district: json['district'] as String?,
    );
  }
}