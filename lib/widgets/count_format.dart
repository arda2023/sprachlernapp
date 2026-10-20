/// German thousands separator: 3000 → "3.000".
String formatCountDe(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
