# The Bash Auto-Grader and Reporter Script Collection
This collection of scripts is written with the intention to collect information about files specified during setup. It will then compare those files against a 'key' file to see if they meet the requirements to pass. Upon meeting the requirements. The script will post to an HTTP endpoint within Microsoft Power Automate to store and report on the grade of a file.

## Project Feature List
Below are some anticipated features. If a feature is not checked off, then it is not completed yet.

- Configuration of how to grade files. Options are:
- [ ] File content changes (useful for checking if configuration files contain the correct configuration)
- [ ] Search for custom values within files (useful for checking logfiles to ensure the correct items are being logged)
- [ ] Comparison of key files to specified files to validate if an input is correct (useful to check if two files have matching content)
- [ ] Offloading of autograding jobs to an HTTP server, preventing modification of grading routines

- Other features:
- [ ] Install and removal scripts
- [ ] Communication with outside HTTP servers to report on grading success or failure
- [ ] Storage of key information to uniquely identify each environment with the HTTP server
- [ ] Encryption of key files to ensure user doesn't obtain access to them
- [ ] Ability to receive HTTP responses back from the HTTP server to verify metadata about the recording of the grade
- [ ] Student mode, which allows the student to trigger the grading process directly

Beyond this, there will be other features added. This will coincide with the development of an HTTP endpoint utilizing Microsoft Power Automate. New features will be developed in conjunction with Power Automate.

## AutoGrader script structure
The autograder script is contained within [main.sh](./main.sh). This script will be the script which's always called to start the grading. The main script is laid out by 
1. Verifying the input
2. Calling one or more grading scripts (options on how to grade the files)
3. Calculating the grade based on the rubric
4. Sending the grading information to an HTTP server to store and input the grade to the LMS
