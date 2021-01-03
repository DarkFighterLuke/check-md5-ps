# check-md5-ps
Powershell script to compare md5 checksum of two lists of files

If you need speed and performance check the multithread Golang version of this script: 

# Prerequisites
At first you need `md5deep` installed to run this script. You can find it here for Windows, Linux and Mac OS: http://md5deep.sourceforge.net/ .

Then you need `Powershell 7.1` at least. You can download it here for Windows, Linux and Mac OS: https://docs.microsoft.com/it-it/powershell/scripting/install/installing-powershell?view=powershell-7.1 .

# Scope
Once you installed `md5deep` you will need to dump checksums of the two files (or lists of files) into two text files. 
You can now pass them to the script and it will find all the files which have a md5 checksum mismatch and it will write it down to the specified results file.

At the end of the execution you will know all the corrupted files and the copy them again.

# Usage
The script requires 3 parameters:
  ```
  1. First checksum file
  2. Second checksum file
  3. File where to write negative results of the comparison
 ```
The script is equiped with a resume mechanism, so it will start from the last occurence when you interrupted the execution.

# Implementation
This script uses a sequential search algorithm, which has a O(n²) complexity, so it is very slow and doesn't suite cases where there are a lot of lines to compare.
For those cases use the Goland version, which uses a faster algorithm and multithread performances.
