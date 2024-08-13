import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:io';
import 'dart:html' as html;
import 'api_key.dart';

void main() {
  runApp(ResumeTailorApp());
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
      body: '{"contents": [{"parts":[{"text":"Tailor this resume to the below job posting $resume job_posting $jobPosting"}]}]}',
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
    var pdf = pw.Document();
    String markdownText = tailoredResumeController.text;

    // Convert markdown to HTML
    String htmlText = md.markdownToHtml(markdownText);

    // Add the HTML content to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            children: [
              pw.Text(htmlText, style: pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );

    // Generate PDF in memory and provide a download link
    var bytes = await pdf.save();
    var blob = html.Blob([bytes], 'application/pdf');
    var url = html.Url.createObjectUrlFromBlob(blob);
    var anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'tailored_resume.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
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