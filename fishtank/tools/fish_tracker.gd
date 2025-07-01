# gdlint:disable = class-variable-name,function-name
extends SceneTree

var TR_log_interval_IN := 0.333
var TR_total_time_IN := 60.0


func _initialize() -> void:
    call_deferred("_TR_run_IN")


func _TR_run_IN() -> void:
    var env := TankEnvironment.new()
    env.TE_size_IN = Vector3(128.0, 72.0, 5.0)
    env.TE_update_bounds_IN()

    var boid_sys := BoidSystem.new()
    boid_sys.BS_environment_IN = env
    boid_sys.BS_group_count_IN = 1
    get_root().add_child(boid_sys)

    var loader := ArchetypeLoader.new()
    var arches := loader.AL_load_archetypes_IN("res://data/archetypes.json")
    if arches.is_empty():
        arches.append(FishArchetype.new())
    boid_sys.BS_spawn_population_IN(arches)

    if boid_sys.BS_fish_nodes_SH.is_empty():
        push_error("No fish spawned")
        quit()
        return
    var fish: BoidFish = boid_sys.BS_fish_nodes_SH[0]
    var b := env.TE_boundaries_SH
    fish.BF_position_UP = Vector3(b.position.x + b.size.x * 0.95, b.position.y, 0.0)
    fish.BF_velocity_UP = Vector3(40.0, 0.0, 0.0)

    var steps := int(TR_total_time_IN / TR_log_interval_IN)
    for i in range(steps):
        boid_sys._physics_process(TR_log_interval_IN)
        print(
            (
                "%0.2f, %f, %f, %f"
                % [
                    i * TR_log_interval_IN,
                    fish.BF_position_UP.x,
                    fish.BF_position_UP.y,
                    fish.BF_position_UP.z
                ]
            )
        )
    quit()
