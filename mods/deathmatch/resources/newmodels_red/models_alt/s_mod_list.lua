-- mod_list.lua
-- This system was used in newmodels v3, and can now function in newmodels v6 to add new models.
--
-- ..........................
-- AVAILABLE PARAMETERS .....
-- ..........................
--
-- > Old parameters from newmodels v3:
--
--     'id' must be unique and out of the default GTA (& preferrably SA-MP too) ID ranges
--
--     'base_id' is the model the mod will inherit some properties from
--	    Doesn't make much difference on peds(skins), but it does on vehicles & objects
--
--     'path' can be:
--    		» a string, in which case it expects files to be named ID.dff or ID.txd in that folder
--     		» an array(table), in which case it expects an array of file names like
--              {dff="filepath.dff", txd="filepath.txd", col="filepath.col"}.
--      		For files encrypted using NandoCrypt, don't add the .nandocrypt extension, it is
--              defined by the 'NANDOCRYPT_EXT' setting.
--     	All paths defined manually in this file need to be local (this resource)
--	    	» To add a mod from another resource see the examples provided in the documentation.
--
--     'name' can be whatever you want (string)
--
--     +++ Optional parameters +++
--
--     		» 'lodDistance' : custom LOD distance in GTA units (number), see possible values https://wiki.multitheftauto.com/wiki/EngineSetModelLODDistance
--     		» 'ignoreTXD', 'ignoreDFF', 'ignoreCOL' : if true, the script won't try to load TXD/DFF/COL for the mod
--    		» 'metaDownloadFalse' : if true, the mod will be only be downloaded when needed (when trying to set model); files must contain download="false" in meta.xml
--     		» 'disableAutoFree' : if true, the allocated mod ID will not be freed when no element streamed in is no longer using the mod ID
--      		This causes the mod to stay in memory, be careful when enabling for big mods
--     		» 'filteringEnabled' (engineLoadTXD)
--     		» 'alphaTransparency' (engineReplaceModel)
--
-- > New parameters added in newmodels v6:
--
--     None.
--
-- ..........................
-- AVAILABLE TYPES .....
-- ..........................
--
-- New models need to be grouped by type in the 'modList' table below.
--
--   - 'ped' (skins for players and peds)
--   - 'object' (for objects, buildings and pickups)
--   - 'vehicle'
--

-- NOTE: models_alt folders are empty. Keep modList empty to avoid load failures.
-- Add entries back only when the corresponding files exist under models_alt/.
modList = {
	ped = {},
	vehicle = {},
	object = {},
}
