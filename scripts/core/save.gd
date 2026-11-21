extends RefCounted
## Local-only persistence: settings, lifetime stats and the chapter checkpoint.
## Nothing leaves the device; there is no account, network or analytics.

const PATH := "user://hex_district.cfg"

var data := {
    # "" = follow the device language on first launch
    "lang": "",
    # one-thumb control options
    "right_handed": true,
    "stick_size": 56.0,
    "stick_opacity": 0.5,
    "sensitivity": 1.0,
    # comfort and accessibility
    "shake": true,
    "vibration": true,
    "flash": true,
    "high_contrast": false,
    "sound": true,
    # progress
    "runs": 0,
    "wins": 0,
    "best_chapter": 0,
    "best_kills": 0,
    "checkpoint": {},
}


func load_data() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) != OK:
        return
    for k in data.keys():
        data[k] = cfg.get_value("save", k, data[k])


func save_data() -> void:
    var cfg := ConfigFile.new()
    for k in data.keys():
        cfg.set_value("save", k, data[k])
    cfg.save(PATH)
