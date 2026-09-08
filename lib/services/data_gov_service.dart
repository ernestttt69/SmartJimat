import 'package:http/http.dart' as http;

class DataGovService {
  Future<String> downloadCurrentMonthPriceCatcherCsv() async {
    final now = DateTime.now();

    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');

    final url = Uri.parse(
      'https://storage.data.gov.my/'
          'pricecatcher/'
          'pricecatcher_$year-$month.csv',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download PriceCatcher data',
      );
    }

    return response.body;
  }
}