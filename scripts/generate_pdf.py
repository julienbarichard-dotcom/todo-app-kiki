import io
import os
from html.parser import HTMLParser

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer

INPUT_HTML = os.path.join(os.path.dirname(__file__), '..', 'docs', 'TodoApp_Kiki_A4.html')
OUTPUT_PDF = os.path.join(os.path.dirname(__file__), '..', 'docs', 'TodoApp_Kiki_A4.pdf')


class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.result = []

    def handle_starttag(self, tag, attrs):
        if tag in ('h1', 'h2', 'h3'):
            self.result.append('\n')

    def handle_data(self, data):
        self.result.append(data)

    def handle_endtag(self, tag):
        if tag in ('p', 'div', 'li'):
            self.result.append('\n')

    def text(self):
        return ''.join(self.result)


def html_to_text(path):
    with open(path, 'r', encoding='utf-8') as f:
        html = f.read()
    parser = TextExtractor()
    parser.feed(html)
    return parser.text()


def build_pdf(text, out_path):
    doc = SimpleDocTemplate(out_path, pagesize=A4,
                            rightMargin=20*mm, leftMargin=20*mm,
                            topMargin=20*mm, bottomMargin=20*mm)
    styles = getSampleStyleSheet()
    story = []

    # Title style
    title_style = ParagraphStyle('Title', parent=styles['Heading1'], fontSize=20, spaceAfter=10)
    normal = styles['BodyText']

    # Try to split by lines and create paragraphs
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    if lines:
        story.append(Paragraph(lines[0], title_style))
    for ln in lines[1:]:
        story.append(Paragraph(ln.replace('\n', '<br/>'), normal))
        story.append(Spacer(1, 6))

    doc.build(story)


def main():
    if not os.path.exists(INPUT_HTML):
        print('Fichier source HTML introuvable:', INPUT_HTML)
        return
    text = html_to_text(INPUT_HTML)
    build_pdf(text, OUTPUT_PDF)
    print('PDF généré:', OUTPUT_PDF)


if __name__ == '__main__':
    main()
