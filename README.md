# Render J2 Templates

Renders Jinja2 Templates via the [J2 cli](https://github.com/kolypto/j2cli).

## Usage

<!-- start usage -->
```yaml
- uses: shopsmart/render-j2-action@v2
  with:
    # The path to the template file to render
    template: ''

    # The path to the file with data to pass to the render
    # Default:
    data: ''

    # The format the data file will be in
    # Default:
    format: ''

    # The environment variables to pass to the render. Each environment
    # variable should be in format VAR=VAL with one on each line.
    #
    # Example:
    #  env_vars: |
    #  FOO=bar
    #  BAR=baz
    #
    # Default:
    env_vars: ''

    # Load custom Jinja2 filters from a Python file: all top-level functions are
    # imported.
    # Default:
    filters: ''

    # Load custom Jinja2 tests from a Python file.
    # Default:
    tests: ''

    # A Python file that implements hooks to fine-tune the j2cli behavior
    # Default:
    customize: ''

    # If true, undefined variables will be used in templates (no error will be raised)
    # Default: false
    undefined: ''

    # The name of the output file to write rendered contents to
    # Default: output
    output: ''

    # The python version to use
    # Default: 3.x
    python_version: ''
```
<!-- end usage -->
