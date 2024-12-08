import os
import tempfile
from pxr import *
from glb_to_usdz.usdStageWithGlTF import usdStageWithGlTF

class OpenParameters:
    def __init__(self):
        self.copyTextures = False
        self.searchPaths = None
        self.verbose = False
        self.metersPerUnit = 0

def glb_to_usdz(glb_path, usdz_path):
    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = os.path.join(tmp_dir, 'tmp.usdc')
        open_parameters = OpenParameters()
        usd_stage = usdStageWithGlTF(glb_path, tmp_path, None, open_parameters)
        usd_stage.SetMetadata("metersPerUnit", open_parameters.metersPerUnit)
        usd_stage.GetRootLayer().Export(tmp_path)
        UsdUtils.CreateNewARKitUsdzPackage(Sdf.AssetPath(tmp_path), usdz_path)
