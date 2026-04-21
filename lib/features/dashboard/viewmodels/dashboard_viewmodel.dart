import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Ye provider track karega ke drawer mein se konsi screen active hai
// 0 = Home, 1 = Products, 2 = Stores, 3 = Finance
final dashboardNavProvider = StateProvider<int>((ref) => 0);
