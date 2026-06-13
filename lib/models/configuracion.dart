class Configuracion {
  final int id;
  final String streamRadio;
  final String streamTv;
  final String facebook;
  final String instagram;
  final String youtube;
  final String tiktok;
  final String twitter;

  Configuracion({
    required this.id,
    required this.streamRadio,
    required this.streamTv,
    required this.facebook,
    required this.instagram,
    required this.youtube,
    required this.tiktok,
    required this.twitter,
  });

  factory Configuracion.fromJson(Map<String, dynamic> json) {
    return Configuracion(
      id: json['id'] as int? ?? 1,
      streamRadio: json['stream_radio'] as String? ?? '',
      streamTv: json['stream_tv'] as String? ?? '',
      facebook: json['facebook'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      youtube: json['youtube'] as String? ?? '',
      tiktok: json['tiktok'] as String? ?? '',
      twitter: json['twitter'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream_radio': streamRadio,
      'stream_tv': streamTv,
      'facebook': facebook,
      'instagram': instagram,
      'youtube': youtube,
      'tiktok': tiktok,
      'twitter': twitter,
    };
  }
}
