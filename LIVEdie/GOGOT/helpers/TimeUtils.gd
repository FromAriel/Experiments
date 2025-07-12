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
    var now := Time.get_unix_time_from_system() * 1000
    var d := now - epoch_ms
    var sec := epoch_ms / 1000
    if d < 60_000:
        return Time.get_datetime_string_from_unix_time(sec, true)
    if d < 3_600_000:
        return Time.get_datetime_string_from_unix_time(sec).substr(0, 8)
    if d < 86_400_000:
        return Time.get_datetime_string_from_unix_time(sec).substr(0, 5)
    if d < 172_800_000:
        return "Yesterday " + Time.get_datetime_string_from_unix_time(sec).substr(0, 5)
    return (
        Time.get_date_string_from_unix_time(sec)
        + " "
        + Time.get_datetime_string_from_unix_time(sec).substr(0, 5)
    )
