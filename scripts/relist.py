#!/usr/bin/env python3
from dataclasses import dataclass
from io import FileIO
import os
import sys
import re
from typing import *
import glob

# TODO: need ability to override this from environment or cmd line
FAIL_ON_WARNING = True
warning_flag = False

@dataclass
class Segment:
    name: str = ""
    offset: int = 0
    size: int = 0

class Module:
    def __init__(self, module_name):
        self.name = module_name
        self.segments = {}
    
    def add_segment(self, name: str, offset: int, size: int):
        self.segments[name] = Segment(name, offset, size)
    
    def get_unique_name(self) -> str:
        segs = list(self.segments.values())
        segs.sort(key= lambda v: v.name)
        segment_name_size = ([f"{s.name}_{s.size:04X}" for s in segs if s.size > 0])
        return f"{self.name}_{'_'.join(segment_name_size)}"
    
    def get_segment_offset(self, segment_name):
        return self.segments[segment_name].offset

# Scan the map file for modules and segments. Note that module names do not uniquely identify a module. See scan_lst below.
# TODO: It's probably more efficient for scan map to return a map of all modules, not just the one we're interested during
#       this iteration.
def scan_map(map_filename: str, lst_filename:str, segment_map:Dict[str,Segment], module_map:Dict[str,Module]):
    segment_matcher = re.compile("^([A-Z][A-Z0-9_]*) *([0-9A-F]{6})  ([0-9A-F]{6})  ([0-9A-F]{6})  ([0-9A-F]{5})$", re.IGNORECASE)
    lst_matcher = re.compile("^    ([A-Z][A-Z0-9_]*) *Offs=([0-9A-F]{6})  Size=([0-9A-F]{6})  Align=([0-9A-F]{5})  Fill=([0-9A-F]{4})$", re.IGNORECASE)
    obj_filename = f"{os.path.basename(os.path.splitext(lst_filename)[0])}.o:"

    # print(f"Looking for {os.path.basename(os.path.splitext(lst_filename)[0])}.o")

    with open(map_filename) as f:
        line_num = 0
        reading_segments = False
        reading_module_segments = False
        cur_module: Module = None
        for line in f:
            line_num += 1
            
            if line.rstrip() == obj_filename:
                module_name = os.path.splitext(obj_filename)[0]
                cur_module = Module(module_name)
                # print(f"Found module {obj_filename} on line {line_num}")
                reading_module_segments = True
            elif reading_module_segments:
                match = lst_matcher.match(line)
                if match:
                    name, _offs, _size, _, _ = match.groups()
                    name = name.upper()
                    offs = int(_offs, 16)
                    size = int(_size, 16)
                    cur_module.add_segment(name, offs, size)
                else:
                    module_map[cur_module.get_unique_name()] = cur_module
                    reading_module_segments = False
                    cur_module = None
            elif line.rstrip() == "Segment list:":
                # print(f"Found segment list on line {line_num}")
                reading_segments = True
            elif reading_segments:
                if line.rstrip() == "":
                    # print(f"Segment list finished on line {line_num}")
                    reading_segments = False
                match = segment_matcher.match(line)
                if match:
                    name, _start, _, _size, _ = match.groups()
                    name = name.upper()
                    start = int(_start, 16)
                    size = int(_size, 16)
                    segment_map[name] = Segment(name, start, size)
        # print(f"Done reading {line_num} lines")
        return segment_map, module_map

lst_matcher = re.compile("^([0-9A-F]{6})r \\d  (\w\w |   )(\w\w |   )(\w\w |   )(\w\w |   )\s*$")
seg_matcher = re.compile(r'^\s*\.segment "([A-Z_][A-Z0-9_]*)"', re.IGNORECASE)
spc_matcher = re.compile(r'^\s*\.(bss|code|data|rodata|zeropage)(\s|$)', re.IGNORECASE)

# Because the map file stores modules by object file name with no path, we need to determine which lst files go with which 
# module file. We do this by creating a "hopefully unique" fingerprint of the module consisting of the module name, and
# each segment and the size of the segment for that module. E.g.: the module
# memory.o:
#    MEMDRV            Offs=000000  Size=00011E  Align=00001  Fill=0000
#    KERNRAM           Offs=000000  Size=00001E  Align=00001  Fill=0000
#    KERNRAM2          Offs=000000  Size=000037  Align=00001  Fill=0000
# should get the "hopefully unique" name 'memory_KERNRAM_30_KERNRAM2_52_MEMDRV_286'. The order of the segments is sorted
# so that they should always match.
# 
# This shortcoming of ld65 is the entire reason we need to perform this scan.
def scan_lst(lst_filename) -> str:
    # I really hope these regex's continue working in the future.
    base_lst_filename = os.path.basename(os.path.splitext(lst_filename)[0])
    module = Module(base_lst_filename)
    with open(lst_filename) as f:
        line_num = 0
        cur_segment = None
        cur_size = 0
        for line in f:
            line_num += 1
            lst_part = line[0:24]
            code_part = line[24:]
            segment_match = seg_matcher.match(code_part)
            if not segment_match: # Wasn't .segment, check one of the special segment names
                segment_match = spc_matcher.match(code_part)
            if segment_match:
                if cur_segment != None:
                    # print(f"{line_num}: Creating new segment {cur_segment} with size ${cur_size:04X}")
                    module.add_segment(cur_segment, 0, cur_size)
                cur_segment = segment_match.group(1).upper()
                cur_size = 0
                # print(f"Scanning new segment {cur_segment}")
            else:
                lst_match = lst_matcher.match(lst_part)
                if lst_match:
                    ops = [x for x in lst_match.groups()[1:] if x.strip() != '']
                    offset = int(lst_match.group(1), 16)
                    new_size = offset + len(ops)
                    # print(f"{line_num}: new_size = {new_size} + {len(ops)} ?> {cur_size}")
                    if new_size > cur_size:
                        # print(f"{line_num}: new_offset {new_size:X}, old_offset {cur_size:X}")
                        cur_size = new_size
        if cur_segment != None and cur_size != 0:
            # print(f"{line_num}: Creating new segment {cur_segment} with size ${cur_size:04X}")
            module.add_segment(cur_segment, 0, cur_size)
    # print(f"Done scanning {lst_filename}")
    return module.get_unique_name()

# re-lst the lst file with offsets.
def relst(lst_filename: str, module: Module, rlst_file: FileIO) -> None:
    # for k,v in module.segments.items():
    #     print(f"key = {k}, value = {v}")
    with open(lst_filename) as f:
        line_num = 0
        cur_segment:Segment = None
        for line in f:
            line_num += 1
            lst_part = line[0:24]
            code_part = line[24:]

            # Check for a segment change
            segment_match = seg_matcher.match(code_part)
            if not segment_match: # Wasn't .segment, check one of the special segment names
                segment_match = spc_matcher.match(code_part)
            if segment_match:
                matched_segment_name = segment_match.group(1).upper()
                if matched_segment_name in module.segments:
                    cur_segment = module.segments[matched_segment_name]
                else:
                    print(f"INFO: Could not find segment matching '{matched_segment_name}' in module {module.name}, assuming zero offset", file=sys.stderr)
                    cur_segment = Segment(matched_segment_name, 0, 0)
            if cur_segment:
                # Only update lst-file-like lines
                lst_match = lst_matcher.match(lst_part)
                if lst_match:
                    # Found a normal lst file line, replace its relative offset with the absolute offset.
                    # TODO: This labels comment blocks of functions with the address of the first instruction of the
                    #       function. It looks kind of ugly. Perhaps if the offset of the current line hasn't changed
                    #       from the previous line, we should just scrub the offset altogether to improve readability.
                    location = int(lst_match.group(1),16) + cur_segment.offset
                    rlst_file.write(f"{location:06X} a {line[9:].rstrip()}\n")
                else:
                    rlst_file.write(line)
            else:
                # Writing these lines will often put a large chunk of include file spew at the top
                # of the file. Not sure if this is something we'd want in the rlst file or not.
                # It's already in the regular .lst file so for now we'll scrub these lines.
                #rlst_file.write(line)
                pass

# Process a map and lst file.
def process(map_filename, lst_filename):
    # print(f"Processing {lst_filename}")

    map_modules: Dict[str,Module] = {}       # A dict of all modules in the map file
    map_segments: Dict[str,Segment] = {}     # A dict of all segments in the map file

    # Scan map file, populate map dictionaries
    scan_map(map_filename, lst_filename, map_segments, map_modules)
    
    # Scan lst file, construct the unique module name we'll be looking for in the map file
    module_name = scan_lst(lst_filename)

    if module_name not in map_modules:
        print(f"INFO: unique module name {module_name} did not appear map file modules. We're going to wing it...", file=sys.stderr)
        bare_module_name = os.path.basename(os.path.splitext(lst_filename)[0])
        # Find the first module with the same name as the lst file and roll with it...
        module_name = None
        for key,mod in map_modules.items():
            if mod.name == bare_module_name:
                module_name = key
                break
        if module_name == None: # we still didn't find anything...
            print(f"WARNING: we couldn't even find a map file module named {bare_module_name}", file=sys.stderr)
            global warning_flag
            warning_flag = True
        else:
            print(f"INFO: we're going to go with {module_name}.", file=sys.stderr)
    # Add the segment base address to the offset of each segment within the module
    # TODO: Would be better to deepcopy the module and update that instead of changing the one in the map.
    module = map_modules[module_name]
    for name,segment in module.segments.items():
        # print(f"segment name = {segment.name}, size = {segment.size}, offset = {segment.offset:X} + {map_segments[name].offset:X}")
        segment.offset += map_segments[name].offset

    rlst_filename = os.path.splitext(lst_filename)[0]+".rlst"
    with open(rlst_filename, "w") as rlst_file:
        # print(f"Writing relisting to {rlst_filename}")
        relst(lst_filename, module, rlst_file)

if __name__ == "__main__":
    # Note: no command line safety here - don't make a mistake!
    map_filename = sys.argv[1]
    lst_path = sys.argv[2]
    if lst_path.endswith(".lst"):
        all_lst = [lst_path]
    else:
        glob_pattern = os.sep.join([lst_path,"**", "*.lst"])
        # print(f"glob pattern = {glob_pattern}")
        all_lst = glob.glob(glob_pattern, recursive=True)
    if len(all_lst) == 0:
        warning_flag = True
        print(f"WARNING: No lst file(s) to process.", file=sys.stderr)
    for lst in all_lst:
        process(map_filename, lst)
    if warning_flag and FAIL_ON_WARNING:
        exit(1)
    else:
        exit(0)
