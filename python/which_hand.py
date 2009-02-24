#!/usr/local/bin/python
"""
This script reads Java path names from a file, for example:
/this/is/the/path/AbstractTestCase.java
And extracts the class name eg. AbstractTestCase, and determines
if the Java class can be typed with only the left or right hand :)
"""
import os, sys

leftHand = ('q', 'w', 'e', 'r', 't', 'a', 's', 'd', 'f', 'g', 'z', 'x', 'c', 'v', 'b' )
rightHand = ('y', 'u', 'i', 'o', 'p', 'h', 'j', 'k', 'l', 'n', 'm' )

if __name__ == '__main__':
    # Understanding the for loop:
    # 1) os.path.split() splits a path into two parts, everything
    # before the final slash, and everything after.
    # 2) the expression line[:-1] strips off the newline character
    for fileName in [os.path.split(line[:-1])[1] for line in sys.stdin]:
        className = os.path.splitext(fileName)[0]
        lh = 0
        rh = 0
        for c in className.lower():
            if c in leftHand:
                lh += 1
            elif c in rightHand:
                rh += 1
            else:
                raise 'bad character'
        if rh == 0:
            print 'Left hand only: ' + className
        elif lh == 0:
            print 'Right hand only: ' + className
