/// Model untuk representasi user dalam sistem chat/matching
class ChatUser {
  final String uid;
  final String username;
  final String? imageUrl;
  final String? gender;
  final String? dob;
  final String? bio;
  final String? agama;
  final List<String>? hobi;

  ChatUser({
    required this.uid,
    required this.username,
    this.imageUrl,
    this.gender,
    this.dob,
    this.bio,
    this.agama,
    this.hobi,
  });

  factory ChatUser.fromMap(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    // Parse hobi dari Firebase (bisa berupa List atau null)
    List<String>? hobiList;
    if (data['hobi'] != null) {
      hobiList = List<String>.from(data['hobi']);
    }

    return ChatUser(
      uid: documentId,
      username: data['name'] ?? 'No Name',
      imageUrl: data['imageUrl'],
      gender: data['gender'],
      dob: data['dob'],
      bio: data['bio'],
      agama: data['agama'],
      hobi: hobiList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': username,
      'imageUrl': imageUrl,
      'gender': gender,
      'dob': dob,
      'bio': bio,
      'agama': agama,
      'hobi': hobi,
    };
  }

  /// Menghitung umur dari tanggal lahir
  int? get umur {
    if (dob == null || dob!.isEmpty) return null;

    try {
      final parts = dob!.split(' ');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final year = int.parse(parts[2]);

      const bulanMap = {
        'Januari': 1,
        'Februari': 2,
        'Maret': 3,
        'April': 4,
        'Mei': 5,
        'Juni': 6,
        'Juli': 7,
        'Agustus': 8,
        'September': 9,
        'Oktober': 10,
        'November': 11,
        'Desember': 12,
      };

      final month = bulanMap[parts[1]];
      if (month == null) return null;

      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();
      int age = now.year - birthDate.year;

      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return null;
    }
  }
}

/// Model untuk kontak dalam daftar chat
class ChatContactModel {
  final String name;
  final String imageUrl;
  final String latestMessage;
  final String latestTimestamp;
  final String chatRoomId;
  final String id;
  final ChatUser otherUser;

  ChatContactModel({
    required this.name,
    required this.imageUrl,
    required this.latestMessage,
    required this.latestTimestamp,
    required this.chatRoomId,
    required this.id,
    required this.otherUser,
  });
}

/// Model untuk pesan dalam chat room
class MessageModel {
  final String messageId;
  final bool isSentByMe;
  final String text;
  final bool isImage;
  final String timestamp;

  MessageModel({
    required this.messageId,
    required this.isSentByMe,
    required this.text,
    required this.isImage,
    required this.timestamp,
  });
}
