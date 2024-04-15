# Compilers Winter 2024 Final Project
Author: Daniel Park

Design and implementation of a custom programming language parser and runtime environment using ANTLR for parsing and Kotlin for execution

The language supports basic data types such as integers, strings, and booleans, along with complex data structure like lists

Users can define variables, perform arithmetic and boolean operations, and manipulate lists through methods such as append and extend.

The grammar allows for control structures including if-else conditions and for loops, which can iterate over numeric ranges or through elements of collections. 

## Setup

This project extends Assignment 3 and utilizes it's provided runtime environment in JupyterLab

To setup, simply copy 'expr', 'data', and 'PL.g4' into their respective directories.

Then run command 'make clean build run' from the terminal while inside the root directory of the project.
