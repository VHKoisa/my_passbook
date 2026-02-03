import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/models/models.dart';

/// Service for exporting data to CSV and PDF
class ExportService {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _fileNameDateFormat = DateFormat('yyyy-MM-dd');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // ==================== CSV EXPORT ====================

  /// Export transactions to CSV
  Future<String> exportTransactionsToCsv(List<TransactionModel> transactions) async {
    final List<List<dynamic>> rows = [
      // Header row
      ['Date', 'Type', 'Category', 'Amount', 'Description', 'Note'],
    ];

    // Data rows
    for (final t in transactions) {
      rows.add([
        _dateFormat.format(t.date),
        t.type.name.toUpperCase(),
        t.categoryName,
        t.amount.toStringAsFixed(2),
        t.description ?? '',
        t.note ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    
    if (kIsWeb) {
      // For web, return the CSV string directly
      return csvData;
    }

    // Save to file
    final fileName = 'transactions_${_fileNameDateFormat.format(DateTime.now())}.csv';
    final filePath = await _saveToFile(csvData, fileName);
    return filePath;
  }

  /// Export transactions for a specific period to CSV
  Future<String> exportTransactionsForPeriod(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final filtered = transactions.where((t) =>
        t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endDate.add(const Duration(days: 1)))).toList();

    return exportTransactionsToCsv(filtered);
  }

  // ==================== PDF EXPORT ====================

  /// Generate PDF report
  Future<Uint8List> generatePdfReport({
    required List<TransactionModel> transactions,
    required Map<String, double> summary,
    required DateTime startDate,
    required DateTime endDate,
    String? userName,
  }) async {
    final pdf = pw.Document();

    // Calculate category-wise breakdown
    final Map<String, double> expenseByCategory = {};
    final Map<String, double> incomeByCategory = {};

    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        expenseByCategory[t.categoryName] =
            (expenseByCategory[t.categoryName] ?? 0) + t.amount;
      } else {
        incomeByCategory[t.categoryName] =
            (incomeByCategory[t.categoryName] ?? 0) + t.amount;
      }
    }

    // Sort categories by amount
    final sortedExpenseCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedIncomeCategories = incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          _buildPdfHeader(userName, startDate, endDate),
          pw.SizedBox(height: 20),

          // Summary Card
          _buildPdfSummaryCard(summary),
          pw.SizedBox(height: 20),

          // Expense Breakdown
          if (sortedExpenseCategories.isNotEmpty) ...[
            _buildPdfSectionTitle('Expense Breakdown'),
            pw.SizedBox(height: 10),
            _buildPdfCategoryTable(sortedExpenseCategories, summary['expense'] ?? 0),
            pw.SizedBox(height: 20),
          ],

          // Income Breakdown
          if (sortedIncomeCategories.isNotEmpty) ...[
            _buildPdfSectionTitle('Income Breakdown'),
            pw.SizedBox(height: 10),
            _buildPdfCategoryTable(sortedIncomeCategories, summary['income'] ?? 0),
            pw.SizedBox(height: 20),
          ],

          // Transaction List
          _buildPdfSectionTitle('Transactions'),
          pw.SizedBox(height: 10),
          _buildPdfTransactionTable(transactions),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(String? userName, DateTime startDate, DateTime endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Financial Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        if (userName != null) ...[
          pw.SizedBox(height: 5),
          pw.Text(
            'Generated for: $userName',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
        ],
        pw.Text(
          'Generated on: ${_dateFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummaryCard(Map<String, double> summary) {
    final income = summary['income'] ?? 0;
    final expense = summary['expense'] ?? 0;
    final balance = income - expense;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildPdfStatItem('Income', income, PdfColors.green700),
          _buildPdfStatItem('Expense', expense, PdfColors.red700),
          _buildPdfStatItem('Balance', balance, balance >= 0 ? PdfColors.blue700 : PdfColors.red700),
        ],
      ),
    );
  }

  pw.Widget _buildPdfStatItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          _currencyFormat.format(amount),
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ),
    );
  }

  pw.Widget _buildPdfCategoryTable(List<MapEntry<String, double>> categories, double total) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: [
            _buildPdfTableCell('Category', isHeader: true),
            _buildPdfTableCell('Amount', isHeader: true),
            _buildPdfTableCell('%', isHeader: true),
          ],
        ),
        // Data rows
        ...categories.map((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0;
          return pw.TableRow(
            children: [
              _buildPdfTableCell(entry.key),
              _buildPdfTableCell(_currencyFormat.format(entry.value)),
              _buildPdfTableCell('${percentage.toStringAsFixed(1)}%'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildPdfTransactionTable(List<TransactionModel> transactions) {
    // Limit to last 50 transactions for readability
    final displayTransactions = transactions.take(50).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(3),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: [
            _buildPdfTableCell('Date', isHeader: true),
            _buildPdfTableCell('Type', isHeader: true),
            _buildPdfTableCell('Category', isHeader: true),
            _buildPdfTableCell('Amount', isHeader: true),
            _buildPdfTableCell('Description', isHeader: true),
          ],
        ),
        // Data rows
        ...displayTransactions.map((t) => pw.TableRow(
              children: [
                _buildPdfTableCell(_dateFormat.format(t.date)),
                _buildPdfTableCell(
                  t.type == TransactionType.income ? 'IN' : 'OUT',
                ),
                _buildPdfTableCell(t.categoryName),
                _buildPdfTableCell(_currencyFormat.format(t.amount)),
                _buildPdfTableCell(t.description ?? '-'),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  // ==================== FILE HANDLING ====================

  Future<String> _saveToFile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file.path;
  }

  /// Share a file
  Future<void> shareFile(String filePath, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
    );
  }

  /// Share CSV content (for web)
  Future<void> shareCsvContent(String csvContent, String fileName) async {
    await Share.share(csvContent, subject: fileName);
  }

  /// Print or share PDF
  Future<void> printPdf(Uint8List pdfBytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: fileName,
    );
  }

  /// Share PDF
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}

/// Provider for export service
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
