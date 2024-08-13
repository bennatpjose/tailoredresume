import 'dart:convert';
import 'dart:html' as html; // Import for web-specific functionality
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:markdown/markdown.dart' as md;
import 'api_key.dart';
import 'create_pdf.dart';


void main() {
  runApp(ResumeTailorApp() );
}

class ResumeTailorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ResumeTailorPage(),
    );
  }
}

class ResumeTailorPage extends StatefulWidget {
  @override
  _ResumeTailorPageState createState() => _ResumeTailorPageState();
}

class _ResumeTailorPageState extends State<ResumeTailorPage> {
  TextEditingController resumeController = TextEditingController();
  TextEditingController jobPostingController = TextEditingController();
  TextEditingController tailoredResumeController = TextEditingController();
  int selectedSegment = 0;

  Future<void> generateTailoredResume() async {
    var resume = resumeController.text;
    var jobPosting = jobPostingController.text;

    // Call Google Gemini API (mocked for this example)
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$geminiApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [{
          'parts': [{
            'text': 'Tailor this resume to the below job posting $resume job_posting $jobPosting. Do not include any other text than the resume.'
          }]
        }]
      }),
    );

    if (response.statusCode == 200) {
      var parsedResponse = json.decode(response.body);
      String textContent = parsedResponse['candidates'][0]['content']['parts'][0]['text'];
      setState(() {
        tailoredResumeController.text = textContent;
      });
    } else {
      // Handle error
      print('Failed to generate tailored resume');
    }
  }

  Future<void> downloadPDF() async {
    
    String markdownText = tailoredResumeController.text;

    // Convert Markdown to HTML
    String htmlText = md.markdownToHtml(markdownText);

    // Convert HTML to PDF
    // pdf.addPage(
    //   pw.Page(
    //     build: (pw.Context context) => pw.Column(
    //       crossAxisAlignment: pw.CrossAxisAlignment.start,
    //       children: parseHtmlToWidgets(htmlText),
    //     ),
    //   ),
    // );

    // Generate PDF in memory and provide a download link

    final pdfBytes = await createDocument(htmlText);
    var blob = html.Blob([pdfBytes], 'application/pdf');
    var url = html.Url.createObjectUrlFromBlob(blob);
    var anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'tailored_resume.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }



  List<pw.Widget> parseHtmlToWidgets(String htmlText) {
    // Basic HTML to PDF conversion
    List<pw.Widget> widgets = [];

    // For simple text content, we'll just create Text widgets
    widgets.add(pw.Text(htmlText)); // This is a placeholder; replace with actual HTML parsing

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resume Tailor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CupertinoSegmentedControl<int>(
                    children: {
                      0: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Paste Resume Here'),
                      ),
                      1: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Job Posting'),
                      ),
                    },
                    groupValue: selectedSegment,
                    onValueChanged: (int value) {
                      setState(() {
                        selectedSegment = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: selectedSegment == 0
                  ? TextField(
                      controller: resumeController,
                      decoration: InputDecoration(labelText: 'Paste Resume Here'),
                      maxLines: 10,
                    )
                  : TextField(
                      controller: jobPostingController,
                      decoration: InputDecoration(labelText: 'Paste Job Posting Here'),
                      maxLines: 10,
                    ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: generateTailoredResume,
              child: Text('Generate Tailored Resume'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: tailoredResumeController,
                decoration: InputDecoration(labelText: 'Tailored Resume'),
                maxLines: 10,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: downloadPDF,
              child: Text('Download as PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
