import markdown
import sys
import re
import html

def extract_title(markdown_text):
    # 最初の行がタイトルになる
    title_md = markdown_text.split('\n')[0]
    title_html = markdown.markdown(title_md)
    # 最初の１行を削除
    markdown_text = '\n'.join(markdown_text.split('\n')[1:])
    return markdown_text, title_html

def extract_code_blocks(markdown_text):
    code_blocks = []
    placeholder = "<!-- code -->"

    def replacement(match):
        language = match.group(1) if match.group(1) else "No language specified"
        code = match.group(2)
        escaped_code = html.escape(code)
        code_blocks.append((language, escaped_code))
        return placeholder

    processed_markdown = re.sub(r'```([a-zA-Z]*)\n(.*?)```', replacement, markdown_text, flags=re.DOTALL)
    return processed_markdown, code_blocks

def convert_markdown_to_html(file_name, markdown_folder, html_folder, template_file_name):
    try:
        with open(f"{markdown_folder}{file_name}.md", 'r') as file:
            markdown_text = file.read()
    except FileNotFoundError:
        print(f"Error: Markdown file '{file_name}.md' not found in '{markdown_folder}'.")
        return
    title_md, title = extract_title(markdown_text)
    code_md, code_blocks = extract_code_blocks(title_md)
    html_content = markdown.markdown(code_md)

    # Replace placeholders with styled code blocks
    for language, code in code_blocks:
        styled_block = f'<pre class="prettyprint default">\n  <div class="sorcefile">{language}</div>\n  <i class="fas fa-copy"></i>\n  <code>\n{code}\n  </code>\n</pre>'
        html_content = html_content.replace("<!-- code -->", styled_block, 1)

    try:
        with open(template_file_name, 'r') as file:
            html_template = file.read()
    except FileNotFoundError:
        print(f"Error: Template file '{template_file_name}' not found.")
        return
    
    title_html = html_template.replace("<!-- insert title -->", title)
    final_html = title_html.replace("<!-- insert html -->", html_content)

    try:
        with open(f"{html_folder}{file_name}.html", 'w') as file:
            file.write(final_html)
    except IOError as e:
        print(f"Error writing to file: {e}")

def main():
    markdown_folder = 'markdown/'
    html_folder = 'html/'
    template_file_name = 'style/template.html'
    file_name = 'test'

    args = sys.argv
    if len(args) == 2:
        file_name = args[1]

    convert_markdown_to_html(file_name, markdown_folder, html_folder, template_file_name)

if __name__ == '__main__':
    main()
