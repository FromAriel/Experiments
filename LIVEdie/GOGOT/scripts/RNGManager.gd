# gdlint:disable=class-variable-name,function-name,class-definitions-order
###############################################################
# LIVEdie/GOGOT/scripts/RNGManager.gd
# Key Classes      • RNGManager – centralized random number manager
# Key Functions    • RM_seed_IN, RM_generate_roll_SH
# Critical Consts  • (none)
# Editor Exports   • (none)
# Dependencies     • (none)
# Last Major Rev   • 24-07-10 – initial implementation
###############################################################
class_name RNGManager
extends Node

var RM_rng_IN: RandomNumberGenerator
var RM_http_request_IN: HTTPRequest


func _ready() -> void:
    RM_http_request_IN = HTTPRequest.new()
    add_child(RM_http_request_IN)
    RM_seed_IN()


func RM_seed_IN() -> void:
    RM_rng_IN = RandomNumberGenerator.new()
    RM_rng_IN.randomize()
    var url := "https://www.random.org/cgi-bin/randbyte?nbytes=8&format=hex"
    # TODO: use response from random.org to seed RM_rng_IN for stronger entropy
    RM_http_request_IN.request_completed.connect(_on_HTTPRequest_request_completed)
    var err := RM_http_request_IN.request(url)
    if err != OK:
        push_warning("Failed to request external entropy: " + str(err))


func RM_generate_roll_SH(num_sides: int) -> int:
    if not RM_rng_IN:
        RM_seed_IN()
    return RM_rng_IN.randi_range(1, num_sides)


func _on_HTTPRequest_request_completed(
    result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
    if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
        var hex_seed := body.get_string_from_utf8().strip_edges()
        if hex_seed != "":
            RM_rng_IN.seed = int("0x" + hex_seed)
    RM_http_request_IN.disconnect("request_completed", _on_HTTPRequest_request_completed)
