###############################################################
# LIVEdie/GOGOT/helpers/TimeUtils.gd
# Key Classes      • TimeUtils – helper for friendly timestamps
# Key Functions    • friendly
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • (none)
# Last Major Rev   • 24-07-14 – initial version
###############################################################
class_name TimeUtils
extends Node


static func friendly(epoch_ms: int) -> String:
    var now = int(Time.get_unix_time_from_system() * 1000)
    var d = now - epoch_ms
    if d < 60_000:
        return Time.get_datetime_string_from_unix_time(epoch_ms / 1000.0, true)
    if d < 3_600_000:
        return Time.get_datetime_string_from_unix_time(epoch_ms / 1000.0).substr(0, 8)
    if d < 86_400_000:
        return Time.get_datetime_string_from_unix_time(epoch_ms / 1000.0).substr(0, 5)
    if d < 172_800_000:
        return (
            "Yesterday " + Time.get_datetime_string_from_unix_time(epoch_ms / 1000.0).substr(0, 5)
        )
    return (
        Time.get_date_string_from_unix_time(epoch_ms / 1000.0)
        + " "
        + Time.get_datetime_string_from_unix_time(epoch_ms / 1000.0).substr(0, 5)
    )
