# hybuild

(README generated using ChatGPT)

**hybuild** is a makefile generator designed to utilize Lisp syntax (specifically, HyLang) with full Python support and Bash one-liners. It offers an alternative for those who need complex makefiles without having to learn another syntax like CMake, while also leveraging the flexibility of Python.

## Features

- **Lisp-Like Syntax**: The expression syntax closely resembles actual makefiles, making it intuitive for users familiar with Makefile syntax. For example:
  
  ```lisp
  (RULE 
    :target "fs.img"
    :deps (+ ["mkfs" "README"] (GET "UPROGS"))
    :recipes [
      (+ "./mkfs fs.img README "	
         (.join " " (GET "UPROGS")))
    ])
  ```

- **QUOTE-RULE Function**: Allows for generating makefile rules verbatim, useful for debugging or step-by-step conversion of makefiles to hybuild format.

- **Automatic Hybuild File Generation**: Provides basic conversion from makefile to hybuild format.

## Installation

Currently, hybuild relies on a few Python packages and has not been packaged as a wheel. Therefore, it needs to be run from the source. 

## Usage

An example hybuild file, `makefile.hy`, is included in the repository, which is a conversion of MIT's XV6 makefile. To generate a makefile, use the following command:

```bash
python main.py makefile.hy
```

The generated makefile should work seamlessly and is straightforward to review.

## API

- **RULE Syntax**: Demonstrated as mentioned above.
  
- **QUOTE-RULE**: Syntax for generating makefile rules verbatim.
  
- **GET and SET**: For using variables (not included in makefile).
  
- **RUN**: For executing Bash one-liners and obtaining output for further processing.

## Contributing

Currently, there are no specific guidelines for contributing to the project. This area is still to be determined.
