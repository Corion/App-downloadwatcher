# App::downloadwatcher

## Why

I wrote this app to unclutter my Downloads directory where all my browsers
store all the files I download.

## Rules

The idea of the program is that you configure a set of filespecs and for each
filespec a program that should be invoked.
The following example
shows two rules. The first rule finds downloads in progress from the Chrome
browser via a rule that matches `*.crdownload` files. No action is taken for
such files. The second rule matches all PDF files that start with "printme"
and runs a custom program to immediately print these files.

    ---
    actions:
        - name: "Download in progress"
          file_glob:
              - "*.crdownload"
        - name: "Print out Research PDFs"
          file_glob:
              - "printme-*.pdf"
          handler: "print-pdf \"$file\" --printer my-printer"

