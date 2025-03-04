# md-toc
A simple script to create Table of Content from a given markdown file. 

- The table of contents is generated based on the heading levels provided by the user. 
- The generated table of contents is printed to stdout by default. 
- If `-i` or `--inline` option is provided, the script will replace the line that has only `[[:ToC:]]` in it with the generated table of contents. 
- The `inline` option must be used with a file path.

## Usage
```bash
Generate table of contents of markdown content from given file or stdin.

Usage: md-toc.sh [OPTIONS]... MAX_HEADING_LEVEL MIN_HEADING_LEVEL [FILE|STDIN]

Arguments:
  MAX_HEADING_LEVEL  Maximum heading level to include in the table of contents
  MIN_HEADING_LEVEL  Minimum heading level to include in the table of contents
  FILE               File to read markdown content from. If not provided,
                     content will be read from stdin.

Options:
  -h, --help            Display this help and exit
  -v, --version         Output version information and exit
  -i, --inline          Inline substitution of the given file.
                        This will replace the line that has only '[[:ToC:]]'
                        in it with the generated table of contents.
  -I, --indent=count    Number of spaces to indent the table of contents
                        (default is 4)
```
