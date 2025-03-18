# MasonryIndex-3D

## Overview
This repository contains MATLAB files for analyzing 3D stone geometric properties and computing the line of minimum trace (LMT) from binary images.

## Repository Structure

### 01_3D_stones_properties
Contains scripts for computing various 3D stone properties, including:
- Volume calculation
- Bounding box dimensions (axis-aligned & oriented)
- Aspect ratio, elongation, and flatness index
- Shape factor computation

To compute:
run ('main_script.m')

### 02_line_of_minimum_trace
Contains scripts for computing and analyzing the line of minimum trace for: 
- Analysis of vertical joint staggering
- Evaluation of horizontal bed joint characteristics
- Assessment of wall leaf connections

To compute:
run ('line_minimum_trace.m')


## Prerequisites
- MATLAB (R2022a or later)
- Image Processing Toolbox (required for bwgraph.m)

## License
Please refer to the License.txt file included in this repository for licensing information.

## Acknowledgments
- The `bwgraph.m` function is a modification of the original work by George Abrahams, published under the MIT License.
- For more information on the original `bwgraph` function, visit: https://github.com/WD40andTape/bwgraph


