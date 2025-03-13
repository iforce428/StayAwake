import 'dart:io'; // For using Directory and File

import 'package:flutter/services.dart'; // For accessing assets
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class dbHelper {
  static final dbHelper _instance = dbHelper._internal();
  static Database? _database;

  dbHelper._internal();

  factory dbHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dataDirectoryPath = join(documentsDirectory.path);
    final dataDirectory = Directory(dataDirectoryPath);
    if (!await dataDirectory.exists()) {
      await dataDirectory.create(recursive: true);
    }
    String dbPath = join(dataDirectoryPath, 'stayawake.db');
    if (FileSystemEntity.typeSync(dbPath) == FileSystemEntityType.notFound) {
      ByteData data = await rootBundle.load('assets/databases/stayawake.db');
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes);
    }
    return await openDatabase(dbPath);
  }

  Future<Map<String, dynamic>?> getParameters() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT * FROM parameters LIMIT 1
    ''');
    print(result);
    if (result.isNotEmpty) {
      return result[0];
    } else {
      return null;
    }
  }

  Future<void> updateBillGeneratedHantarData(List<String> bundles) async {
    String placeholders = List.filled(bundles.length, '?').join(', ');
    final db = await database;
    await db.rawUpdate(
      'UPDATE BillGenerated SET IsPushedToGateway = 1 WHERE BundleNo IN ($placeholders)',
      bundles,
    );
  }

  Future<void> updateBillGeneratedHantarDataTest() async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE BillGenerated SET IsPushedToGateway = 0',
    );
  }

  Future<void> updateIsPrinted0To3() async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE BillGenerated SET IsPrinted = 3 WHERE ReadBy != "NULL" AND IsPrinted = 0',
    );
  }

  Future<List<String>> getBundleHantarData() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT BundleNo FROM BillGenerated WHERE ReadBy IS NOT NULL AND IsPushedToGateway = 0 GROUP BY BundleNo HAVING MIN(IsPrinted) != 0 ORDER BY BundleNo;
  ''');
    print(result);
    return List.generate(result.length, (i) {
      return result[i]['BundleNo'].toString(); // Ensure conversion to String
    });
  }

  Future<List<Map<String, dynamic>>> getSequenceHantarData(
      String bundle) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT AccountNo, NewBillDate, NewReading, NewReadingDate, NewReadingCode, NewConsumption, NewCharges, NewChargesGST, NewAmountPayable, 
    NewRoundingAmount, NewSubMeterCount, NewSubMeterReadCount, NewSubMeterConsumption, NewTaxRate, NewTaxCode, NewTaxAmount, NewTaxInvoiceNo    
    FROM BillGenerated
    WHERE BundleNo = ?
    ''', [bundle]);
    return result.map((category) {
      return {
        'AccountNo': category['AccountNo'].toString(),
        'NewBillDate': category['NewBillDate'].toString(),
        'NewReading': category['NewReading'].toString(),
        'NewReadingDate': category['NewReadingDate'].toString(),
        'NewReadingCode': category['NewReadingCode'].toString(),
        'NewConsumption': category['NewConsumption'].toString(),
        'NewCharges': category['NewCharges'].toString(),
        'NewChargesGST': category['NewChargesGST'].toString(),
        'NewAmountPayable': category['NewAmountPayable'].toString(),
        'NewRoundingAmount': category['NewRoundingAmount'].toString(),
        'NewSubMeterCount': category['NewSubMeterCount'].toString(),
        'NewSubMeterReadCount': category['NewSubMeterReadCount'].toString(),
        'NewSubMeterConsumption': category['NewSubMeterConsumption'].toString(),
        'NewTaxRate': category['NewTaxRate'].toString(),
        'NewTaxCode': category['NewTaxCode'].toString(),
        'NewTaxAmount': category['NewTaxAmount'].toString(),
        'NewTaxInvoiceNo': category['NewTaxInvoiceNo'].toString(),
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getBillDetailsForRowId(String rowId) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT bg.rowid, dc.ShortCode, bg.BundleNo, bg.AccountNo, AccountStatus, CustomerName,
           bg.TariffCode, DepositAmount,
           NewBillNo, NewTaxInvoiceNo, MeterNo, ReadBy, strftime('%d-%m-%Y', DateUpdated) as DateUpdated,
           Address1, Address2, Address3,
           strftime('%d-%m-%Y', NewBillDate) as NewBillDate, strftime('%H:%M:%S', NewBillDate) as NewBillTime,
           NewReading, NewReadingCode, PreviousReading, NewConsumption,
           NewRoundingAmount, PRINTF('%.2f', NewAmountPayable) as NewAmountPayable,
           PRINTF('%.2f', NewCharges) as NewCharges, NewChargesGST, PreviousBillNo, PreviousBillAmountPayable,
           strftime('%d-%m-%Y', PreviousReadingDate) as PreviousReadingDate,
           LatestReceiptNo, strftime('%d-%m-%Y', LatestPaymentDate) as LatestPaymentDate, LatestPaymentAmount,
           NewTaxCode, PRINTF('%.0f',NewTaxRate) as NewTaxRate, PRINTF('%.2f', NewTaxAmount) AS NewTaxAmount,
           bge.LastAdjustmentRef, strftime('%d-%m-%Y', bge.LastAdjustmentDate) as LastAdjustmentDate, bge.LastAdjustmentAmount,
           ng.NoticeNo, ng.NoticeTaxInvoiceNo, strftime('%d-%m-%Y', ng.PreviousNoticeDate) as PreviousNoticeDate,
           PRINTF('%.2f', bg.WaterAccountBalance) AS WaterAccountBalance,
           PRINTF('%.2f', ng.NoticeAmount) AS NoticeAmount, PRINTF('%.2f', ng.NoticeCharge) AS NoticeCharge,
           PRINTF('%.2f', ng.NoticeArrearsAmount) AS NoticeArrearsAmount,
           PRINTF('%.2f', ng.NoticeAmountPayable) AS NoticeAmountPayable,
           ng.NoticeAmountPayablePenggenapan,
           CASE WHEN ng.NoticeAmountPayablePenggenapan IS NULL THEN PRINTF('%.2f', ng.NoticeAmountPayable) ELSE PRINTF('%.2f', ng.NoticeAmountPayable+ng.NoticeAmountPayablePenggenapan) END AS NoticeAmountPayableActual,
           CAST((JULIANDAY(strftime('%Y-%m-%d', NewBillDate)) - JULIANDAY(strftime('%Y-%m-%d', PreviousReadingDate))) AS INTEGER) AS NoOfDay,
           ROUND((JULIANDAY(strftime('%Y-%m-%d', NewBillDate)) - JULIANDAY(strftime('%Y-%m-%d', PreviousReadingDate)))/30 , 3) AS proRateDay,
           IFNULL(ng.NoticeNo,'N/A') AS NoticeNo,
           CASE WHEN NewCharges <= tt.MinCharges THEN 'Y' ELSE 'T' END AS IsMinCharges,
           PRINTF('%.2f', tt.MinCharges) AS MinCharges,
           rc.CodeDescription AS ReadingCodeDesc
    FROM BillGenerated bg
    LEFT JOIN DistrictCodes dc ON dc.Id = bg.DistrictCode
    LEFT JOIN ReadingCodes rc ON rc.ReadingCode = bg.NewReadingCode
    LEFT JOIN BillGeneratedExt bge ON bge.AccountNo = bg.AccountNo
    LEFT JOIN NoticeGenerated ng ON ng.AccountNo = bg.AccountNo
    LEFT JOIN TariffTable tt ON tt.TariffCode = bg.TariffCode AND tt.Tier = 1
      AND tt.EffectiveDate = ( SELECT MAX(ttq.EffectiveDate) FROM TariffTable ttq
      WHERE ttq.TariffCode = tt.TariffCode AND ttq.EffectiveDate <= DATE('NOW') )
    WHERE bg.rowid = ?
  ''', [rowId]);
    if (result.isNotEmpty) {
      return result[0];
    } else {
      return null;
    }
  }

  Future<List<double>> getStatusMenuUtama() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT 
      COUNT(CASE WHEN rc.IsEstimated = 'T' AND bg.isprinted > 0 THEN 1 ELSE NULL END) AS bacaanNormal,
      COUNT(CASE WHEN rc.IsEstimated = 'Y' AND bg.isprinted > 0 THEN 1 ELSE NULL END) AS bacaanAnggaran,
      COUNT(CASE WHEN bg.isprinted > 0 THEN 1 ELSE NULL END) AS akaunSudah,
      COUNT(*) AS Jumlah
    FROM billgenerated bg 
    LEFT JOIN readingcodes rc ON rc.readingcode = bg.newreadingcode
    WHERE IsPushedToGateway = 0;
  ''');
    return [
      (result[0]['bacaanNormal'] ?? 0).toDouble(),
      (result[0]['bacaanAnggaran'] ?? 0).toDouble(),
      (result[0]['akaunSudah'] ?? 0).toDouble(),
      (result[0]['Jumlah'] ?? 0).toDouble(),
    ];
  }

  Future<List<Map<String, dynamic>>?> getAduan() async {
    final db = await database;
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM ADUAN');
    if (result.isNotEmpty) {
      return result;
    } else {
      return null;
    }
  }

  Future<String> getMPMacAddressFromParameter() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Parameters',
      columns: ['MobilePrinterMacAddress'],
    );
    return result[0]['MobilePrinterMacAddress'].toString();
  }

  Future<String> getMacAddress(String MPID) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'MobilePrinter',
      columns: ['MacAddress'],
      where: 'MobilePrinterID = ?',
      whereArgs: [MPID],
    );
    return result[0]['MacAddress'].toString();
  }

  // Future<List<String>> getAvailableBundleNos() async {
  //   final db = await database;
  //   final List<Map<String, dynamic>> result =
  //       await db.rawQuery('SELECT DISTINCT BundleNo FROM BillGenerated');
  //   List<String> bundleNos =
  //       result.map((row) => row['BundleNo'].toString()).toList();
  //   return bundleNos;
  // }

  Future<void> updateBillGenerated(String meterno, int status,
      String jenisbacaan, int newread, String readby) async {
    print(jenisbacaan);
    final db = await database;
    await db.rawUpdate(
      'UPDATE BillGenerated SET IsPrinted = ? , NewReadingCode = ?, NewReading = ?, ReadBy = ? WHERE MeterNo = ?',
      [status, jenisbacaan, newread, readby, meterno],
    );
  }

  Future<void> updateMP(String MPID, String MPIDnew) async {
    var macAddress = await getMacAddress(MPIDnew);
    final db = await database;
    await db.rawUpdate(
      'UPDATE Parameters SET MobilePrinterId = ? , MobilePrinterMacAddress = ? WHERE MobilePrinterId = ?',
      [MPIDnew, macAddress, MPID],
    );
  }

  Future<int> getDistinctBundleCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(DISTINCT BundleNo) as count FROM BillGenerated WHERE ReadBy = "NULL";',
    );
    if (result.isNotEmpty) {
      return result.first['count'] as int;
    } else {
      return 0;
    }
  }

  Future<List<String>> getSequencesByBundleNo(String bundleno) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'BillGenerated',
      columns: ['RowId'],
      where: 'BundleNo = ?',
      whereArgs: [bundleno],
      orderBy: 'WalkSequencePrevious',
    );
    // Map the result to a List<String> containing RowId values
    return List.generate(maps.length, (i) {
      return maps[i]['rowid'].toString(); // Convert RowId to a string
    });
  }

  Future<String> getRowIdForBundle(String bundleNo) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT rowid
    FROM billgenerated
    WHERE ReadBy = 'NULL'
      AND bundleno = ?
    ORDER BY walksequenceprevious
    LIMIT 1
  ''', [bundleNo]);

    if (result.isNotEmpty) {
      return result[0]['rowid'].toString();
    } else {
      return 'null';
    }
  }

  Future<String> getNotReadBundleNo() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT BundleNo
    FROM billgenerated
    WHERE ReadBy = 'NULL'
    ORDER BY DaySequence,BundleNo
    LIMIT 1
  ''');
    if (result.isNotEmpty) {
      return result[0]['BundleNo'].toString();
    } else {
      return 'null';
    }
  }

  Future<List<String>> getSequencesByRowIdAduan(String rowid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      MeterNo,
      BundleNo,
      AccountNo
    FROM billgenerated bg
    WHERE rowid = ? LIMIT 1
  ''', [rowid]);
    if (maps.isNotEmpty) {
      return [
        maps[0]['MeterNo'],
        maps[0]['BundleNo'],
        maps[0]['AccountNo'],
      ];
    } else {
      throw Exception('Sequence not found for rowid: $rowid');
    }
  }

  Future<Map<String, dynamic>?> loginUser(
      String username, String password) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'Parameters',
      where: 'MeterReaderId = ? AND LoginPassword = ?',
      whereArgs: [username, password],
    );
    print(result);

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> getDistinctBundleCount1() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT COUNT(DISTINCT BundleNo) as count FROM BillGenerated WHERE IsPushedToGateway = 0;');
    return result.isNotEmpty ? result.first['count'] as int : 0;
  }

  Future<int> getTotalAccountCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM BillGenerated WHERE IsPushedToGateway = 0;');
    return result.isNotEmpty ? result.first['count'] as int : 0;
  }

  Future<Map<String, int>> getBundleCounts() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT BundleNo, COUNT(*) as count FROM BillGenerated GROUP BY BundleNo;');
    return {for (var row in result) row['BundleNo']: row['count']};
  }

  Future<Map<int, int>> getIsPrintedCounts() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT IsPrinted, COUNT(*) as count FROM BillGenerated WHERE IsPushedToGateway = 0 GROUP BY IsPrinted;');
    return {for (var row in result) row['IsPrinted']: row['count']};
  }

  Future<int> getEstimatedStatusCountsY() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT COUNT(*) AS cnt
    FROM BillGenerated bg
    INNER JOIN ReadingCodes rc ON rc.ReadingCode = bg.NewReadingCode
    WHERE rc.IsEstimated IS NOT NULL
    AND ReadBy != 'NULL'
    AND IsPushedToGateway = 0
    AND IsEstimated = 'Y'
  ''');

    return result.isNotEmpty ? result[0]['cnt'] as int : 0;
  }

  Future<int> getEstimatedStatusCountsT() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT COUNT(*) AS cnt
    FROM BillGenerated bg
    INNER JOIN ReadingCodes rc ON rc.ReadingCode = bg.NewReadingCode
    WHERE rc.IsEstimated IS NOT NULL
    AND ReadBy != 'NULL'
    AND IsPushedToGateway = 0
    AND IsEstimated = 'T'
  ''');

    return result.isNotEmpty ? result[0]['cnt'] as int : 0;
  }

  Future<List<Map<String, dynamic>>> getBillGroupedByReadingCode() async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT bg.NewReadingCode, rc.CodeDescription, COUNT(*) as cnt
    FROM BillGenerated bg
    INNER JOIN ReadingCodes rc ON rc.ReadingCode = bg.NewReadingCode
    WHERE rc.CodeDescription IS NOT NULL
    AND bg.IsPrinted > 0
    AND bg.IsPushedToGateway = 0
    GROUP BY bg.NewReadingCode, rc.CodeDescription
    ORDER BY rc.SortOrder, bg.NewReadingCode
  ''');

    return result;
  }

  Future<List<Map<String, String>>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT CategoryId, CategoryDesc
    FROM aduancategories
    WHERE CategoryParentId IS NULL OR CategoryParentId = ''
  ''');

    // Convert the dynamic values to String
    return result.map((category) {
      return {
        'CategoryId': category['CategoryId'].toString(),
        'CategoryDesc': category['CategoryDesc'].toString(),
      };
    }).toList();
  }

  Future<List<Map<String, String>>> getChildCategories(String parentId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT CategoryId, CategoryDesc
    FROM aduancategories 
    WHERE CategoryParentId = ?
  ''', [parentId]);
    return result.map((category) {
      return {
        'CategoryId': category['CategoryId'].toString(),
        'CategoryDesc': category['CategoryDesc'].toString(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getListBundle() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT DaySequence, BundleNo, count(*) as cnt, COUNT(CASE WHEN ReadBy != 'NULL' THEN 1 END) AS READ
    FROM BillGenerated WHERE IsPushedToGateway = 0
	  GROUP BY DaySequence, BundleNo;''');

    return result;
  }

  Future<void> insertAduan(Map<String, dynamic> aduan) async {
    final db = await database;
    await db.insert(
      'Aduan',
      aduan,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAduanBil(String noAkaun) async {
    final db = await database;
    await db.delete(
      'Aduan', // The table name
      where: 'AccountNo = ?', // WHERE clause to specify the row
      whereArgs: [noAkaun], // Arguments to replace the ? placeholder
    );
  }

  Future<void> deleteAduanAm(int rowid) async {
    final db = await database;
    await db.delete(
      'Aduan',
      where: 'rowid = ?',
      whereArgs: [rowid],
    );
  }

  Future<void> insertNotification(Map<String, String> notification) async {
    final db = await database;
    await db.insert(
      'Notifikasi',
      {
        'Tajuk': '${notification['tajuk']}',
        'Kandungan': '${notification['kandungan']}',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getNotificationCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Notifikasi WHERE IsSeen = 0',
    );
    if (result.isNotEmpty) {
      return result.first['count'] as int;
    } else {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getNotification() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT * FROM Notifikasi ORDER BY ID DESC',
    );
    if (result.isNotEmpty) {
      return result;
    } else {
      return [];
    }
  }

  Future<void> deleteSemuaNotifikasi() async {
    final db = await database;
    await db.rawQuery('DELETE FROM Notifikasi');
  }

  Future<void> syncMobilePrinter(List<Map<String, dynamic>> data) async {
    final db = await database;
    await db.delete('MobilePrinter');
    for (var item in data) {
      await db.insert(
        'MobilePrinter',
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> syncBillGenerated(List<Map<String, dynamic>> data) async {
    final db = await database;
    await db.delete('BillGenerated');
    await db.delete('Aduan');
    for (var item in data) {
      await db.insert(
        'BillGenerated',
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await updateIsPrinted0To3();
  }

  Future<void> selectDumpPartialHantarData(List<String> a) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dataDirectoryPath = join(documentsDirectory.path, 'data');
    final db = await database;
    String placeholders = List.filled(a.length, '?').join(', ');
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT BillId, AccountNo, MeterNo, NewBillNo, NewBillDate, NewReading, '
      'NewReadingDate, NewReadingCode, NewConsumption, NewCharges, NewChargesGST, '
      'NewAmountPayable, NewRoundingAmount, NewSubMeterCount, NewSubMeterReadCount, '
      'NewSubMeterConsumption, NewGPSLatitude, NewGPSLongitude, ReadBy, NewTaxAmount, '
      'NewTaxInvoiceNo, IsAduan FROM BillGenerated WHERE BundleNo IN ($placeholders)',
      a,
    );
    print(result.length);
    final filePath = '$dataDirectoryPath/handheld.txt';
    final file = File(filePath);
    await file.writeAsString('$result');
  }

  Future<void> selectDumpHantarDataAduan() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dataDirectoryPath = join(documentsDirectory.path, 'data');
    final db = await database;
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM Aduan');
    print(result.length);
    final filePath = '$dataDirectoryPath/images/aduan/aduan.txt';
    final file = File(filePath);
    await file.writeAsString('$result');
  }

  Future<void> selectDumpHantarDataAduanAM(List<String> a) async {
    String placeholders = List.filled(a.length, '?').join(', ');
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dataDirectoryPath =
        join(documentsDirectory.path, 'data', 'images', 'aduan');
    final filePath = join(dataDirectoryPath, 'aduan.txt');
    await Directory(dataDirectoryPath).create(recursive: true);
    final db = await database;
    final result = await db.rawQuery(
      'SELECT * FROM Aduan WHERE AccountNo = "N/A" AND rowid IN ($placeholders)',
      a,
    );
    print('Number of records: ${result.length}');
    await File(filePath).writeAsString(result.toString());
  }

  Future<bool> isAduanAmExist() async {
    final db = await database;
    final result = await db.rawQuery(
        '''SELECT District FROM Aduan WHERE AccountNo = 'N/A' LIMIT 1''');
    print(result);
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> updateAduanAMHantarData(List<String> a) async {
    String placeholders = List.filled(a.length, '?').join(', ');
    final db = await database;
    await db.rawUpdate(
      'UPDATE Aduan SET IsSentToGateway = 1 WHERE rowid IN ($placeholders)',
      a,
    );
  }

  Future<String> getPathImageAM(String a) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT ImageAduanFileName FROM Aduan WHERE rowid IN ($a) LIMIT 1');
    return result.first['ImageAduanFileName'];
  }

  Future<List<String>> getSequencesMeterNoByBundleNo(String bundleno) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'BillGenerated',
      columns: ['MeterNo'],
      where: 'BundleNo = ?',
      whereArgs: [bundleno],
      orderBy: 'WalkSequencePrevious',
    );
    // Map the result to a List<String> containing RowId values
    return List.generate(maps.length, (i) {
      return maps[i]['MeterNo'].toString(); // Convert RowId to a string
    });
  }

  Future<String> findRowIDFromMeterNo(String meterNo) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'BillGenerated',
      columns: ['rowid'],
      where: 'MeterNo = ?',
      whereArgs: [meterNo],
      orderBy: 'WalkSequencePrevious',
    );
    return maps[0]['rowid'].toString();
  }
}
