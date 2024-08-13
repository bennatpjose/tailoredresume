import 'dart:io';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';

void main(htmlText) {
  createDocument(htmlText);
}



  Future<List<int>> createDocument(String htmlText) async {
    final newpdf = Document();
    final List<Widget> widgets = await HTMLToPdf().convert(htmlText);

    newpdf.addPage(
      MultiPage(
        build: (context) => widgets,
      ),
    );

    return newpdf.save();
  }