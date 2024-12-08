import sys
from glb_to_usdz import glb_to_usdz

glb_path = sys.argv[1]
usdz_path = sys.argv[2]
glb_to_usdz(glb_path, usdz_path)
