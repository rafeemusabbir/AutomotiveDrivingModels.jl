immutable VehicleState
    posG::VecSE2 # global
    posF::Frenet # lane-relative frame
    v::Float64
end
VehicleState() = VehicleState(VecSE2(), Frenet(NaN,NaN,NaN), NaN)
VehicleState(posG::VecSE2, v::Float64) = VehicleState(posG, Frenet(NaN,NaN,NaN), v)
VehicleState(posG::VecSE2, frenet_speed::FrenetSpeed) = VehicleState(posG, frenet_speed.posF, frenet_speed.v)

Base.show(io::IO, s::VehicleState) = print(io, "VehicleState(", s.posG, ", ", s.posF, ", ", @sprintf("%.3f", s.v), ")")
function Base.write(io::IO, ::MIME"text/plain", s::VehicleState)
    @printf(io, "%.16e %.16e %.16e", s.posG.x, s.posG.y, s.posG.θ)
    @printf(io, " %d %.16e %d %d", s.posF.roadind.ind.i, s.posF.roadind.ind.t, s.posF.roadind.tag.segment, s.posF.roadind.tag.lane)
    @printf(io, " %.16e %.16e %.16e", s.posF.s, s.posF.t, s.posF.ϕ)
    @printf(io, " %.16e", s.v)
end
function Base.read(io::IO, ::MIME"text/plain", ::Type{VehicleState})
    tokens = split(strip(readline(io)), ' ')
    i = 0
    posG = VecSE2(parse(Float64, tokens[i+=1]), parse(Float64, tokens[i+=1]), parse(Float64, tokens[i+=1]))
    roadind = RoadIndex(CurveIndex(parse(Int, tokens[i+=1]), parse(Float64, tokens[i+=1])),
                        LaneTag(parse(Int, tokens[i+=1]), parse(Int, tokens[i+=1])))
    posF = Frenet(roadind, parse(Float64, tokens[i+=1]), parse(Float64, tokens[i+=1]), parse(Float64, tokens[i+=1]))
    v = parse(Float64, tokens[i+=1])
    return VehicleState(posG, posF, v)
end

# are these needed?
get_vel_s(s::VehicleState) = s.v * cos(s.posF.ϕ) # velocity along the lane
get_vel_t(s::VehicleState) = s.v * sin(s.posF.ϕ) # velocity ⟂ to lane

# TODO: move these to the correct typewise folder
VehicleState(posG::VecSE2, roadway::Roadway, v::Float64) = VehicleState(posG, Frenet(posG, roadway), v)
VehicleState(posG::VecSE2, lane::Lane, roadway::Roadway, v::Float64) = VehicleState(posG, Frenet(posG, roadway), v)
VehicleState(posF::Frenet, roadway::Roadway, v::Float64) = VehicleState(get_posG(posF, roadway), posF, v)

function _mod2pi2(x::Float64)
    val = mod2pi(x)
    if val > pi
        val -= 2pi
    end
    return val
end
function Frenet(roadind::RoadIndex, roadway::Roadway; t::Float64=0.0, ϕ::Float64=0.0)
    s = roadway[roadind].s
    ϕ = _mod2pi2(ϕ)
    Frenet(roadind, s, t, ϕ)
end
function Frenet(roadproj::RoadProjection, roadway::Roadway)
    roadind = RoadIndex(roadproj.curveproj.ind, roadproj.tag)
    s = roadway[roadind].s
    t = roadproj.curveproj.t
    ϕ = _mod2pi2(roadproj.curveproj.ϕ)
    Frenet(roadind, s, t, ϕ)
end
Frenet(posG::VecSE2, roadway::Roadway) = Frenet(proj(posG, roadway), roadway)

# function Vec.lerp(a::VehicleState, b::VehicleState, t::Float64, roadway::Roadway)
#     posG = lerp(a.posG, b.posG, t)
#     v = lerp(a.v, b.v, t)
#     VehicleState(posG, roadway, v)
# end

# function move_along(vehstate::VehicleState, roadway::Roadway, Δs::Float64;
#     ϕ₂::Float64=vehstate.posF.ϕ, t₂::Float64=vehstate.posF.t, v₂::Float64=vehstate.v
#     )

#     roadind = move_along(vehstate.posF.roadind, roadway, Δs)
#     try
#         footpoint = roadway[roadind]
#     catch
#         println(roadind)
#     end
#     footpoint = roadway[roadind]
#     posG = convert(VecE2, footpoint.pos) + polar(t₂, footpoint.pos.θ + π/2)
#     posG = VecSE2(posG.x, posG.y, footpoint.pos.θ + ϕ₂)
#     VehicleState(posG, roadway, v₂)
# end