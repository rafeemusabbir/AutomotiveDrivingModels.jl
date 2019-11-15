abstract type LaneFollowingDriver <: DriverModel{LaneFollowingAccel} end
track_longitudinal!(model::LaneFollowingDriver, v_ego::Float64, v_oth::Float64, headway::Float64) = model # do nothing by default

function observe!(model::LaneFollowingDriver, scene::Frame{Entity{State1D, D, I}}, roadway::StraightRoadway, egoid::I) where {D, I}

    vehicle_index = findfirst(egoid, scene)

    fore_res = get_neighbor_fore(scene, vehicle_index, roadway)

    v_ego = vel(scene[vehicle_index].state)
    v_oth = vel(scene[fore_res.ind].state)
    headway = fore_res.Δs

    track_longitudinal!(model, v_ego, v_oth, headway)

    return model
end

mutable struct StaticLaneFollowingDriver <: LaneFollowingDriver
    a::LaneFollowingAccel
end
StaticLaneFollowingDriver() = StaticLaneFollowingDriver(LaneFollowingAccel(0.0))
StaticLaneFollowingDriver(a::Float64) = StaticLaneFollowingDriver(LaneFollowingAccel(a))
get_name(::StaticLaneFollowingDriver) = "ProportionalSpeedTracker"
Base.rand(rng::AbstractRNG, model::StaticLaneFollowingDriver) = model.a
Distributions.pdf(model::StaticLaneFollowingDriver, a::LaneFollowingAccel) = isapprox(a.a, model.a.a) ? Inf : 0.0
Distributions.logpdf(model::StaticLaneFollowingDriver, a::LaneFollowingAccel) = isapprox(a.a, model.a.a) ? Inf : -Inf