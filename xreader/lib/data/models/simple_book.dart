// import 'package:isar/isar.dart';  // 暂时注释掉

// part 'simple_book.g.dart';  // 暂时注释掉

// @collection  // 暂时注释掉
class SimpleBook {
  int id = 0; // Id id = Isar.autoIncrement;  // 暂时修改
  
  late String title;
  late String author;
  late String filePath;
  late String fileType;
  
  int currentPage = 0;
  int totalPages = 0;
  double readingProgress = 0.0;
  
  bool isFavorite = false;
  DateTime? addedDate;
  DateTime? lastReadDate;
}