#== # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# INPE - Instituto Nacional de Pesquisas Espaciais
# ETE  - Engenharia e Tecnologia Espacial
# DSE  - Divisão de Sistemas Espaciais
#
# Author: Ronan Arraes Jardim Chagas <ronan.chagas@inpe.br>
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
#
#   Conversions related to the orbit elements.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# References
#
#   [1] Schwarz, R (2014). Memorandum No. 2: Cartesian State Vectors to
#       Keplerian Orbit Elements. Available at www.rene-schwarz.com
#
#       https://downloads.rene-schwarz.com/dc/category/18
#       (Accessed on 2017-08-09).
#
#   [2] Vallado, D. A., McClain, W. D (2013). Fundamentals of Astrodynamics
#       and Applications. Microcosm Press.
#
#   [3] Kuga, H. K., Carrara, V., Rao, K. R (2005). Introdução à Mecânica
#       Orbital. 2ª ed. Instituto Nacional de Pesquisas Espaciais.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Changelog
#
# 2017-08-09: Ronan Arraes Jardim Chagas <ronan.arraes@inpe.br>
#   Initial version.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ==#

export change_oe_frame
export kepler_to_rv
export rv_to_kepler

"""
    function change_oe_frame(a::Number, e::Number, i::Number, Ω::Number, ω::Number, f::Number, conv_args...)
    function change_oe_frame(oe::Orbit, conv_args...)

Change the reference frame of orbit elements. The orbit elements can be
specified by `a`, `e`, `i`, `Ω`, `ω`, and `f`, or the structure `oe` (see
`Orbit`).

The conversion arguments `conv_args` are **the same** arguments that one should
pass to the function `rECItoECI` to convert between the desired frames. For more
information, see the documentation of the function `rECItoECI`.

# Args

* `a`: Semi-major axis [m].
* `e`: Excentricity.
* `i`: Inclination [rad].
* `Ω`: Right-ascension of the ascending node [rad].
* `ω`: Argument of perigee [rad].
* `f`: True anomaly [rad].
* `conv_args...`: Conversion arguments, which are the same arguments that one
                  would pass to the function `rECItoECI` to convert between the
                  desired frames.

* `oe`: An instance of the structure `Orbit` with the orbit elements that will
        be converted [SI units].

# Returns

An instance of the structure `Orbit` with the Keplerian elements [SI units]
converted to the new frame.

# Examples

```julia-repl
julia> eop = get_iers_eop(:IAU1980);

julia> teme_epoch = DatetoJD(2016,6,1,11,0,0);

julia> tod_epoch  = DatetoJD(2016,1,1,0,0,0);

julia> oe_teme    = Orbit(0,
                          7130.982e3,
                          0.001111,
                          98.405*pi/180,
                          227.336*pi/180,
                          90*pi/180,
                          320*pi/180)
SatelliteToolbox.Orbit{Int64,Float64,Float64,Float64,Float64,Float64,Float64}(0, 7.130982e6, 0.001111, 1.71749125042502, 3.9677617083138292, 1.5707963267948966, 5.585053606381854)

julia> oe_j2000 = change_oe_frame(oe_teme, TEME(), J2000(), teme_epoch, eop)
SatelliteToolbox.Orbit{Float64,Float64,Float64,Float64,Float64,Float64,Float64}(0.0, 7.130982000000006e6, 0.0011110000000003463, 1.7162957615449077, 3.964244089992957, 1.5718507998574123, 5.585053606382253)

julia> oe_tod   = change_oe_frame(oe_teme, TEME(), teme_epoch, TOD(), tod_epoch, eop)
SatelliteToolbox.Orbit{Float64,Float64,Float64,Float64,Float64,Float64,Float64}(0.0, 7.130981999999998e6, 0.001110999999999734, 1.7174677913643532, 3.967667652144632, 1.5708200613408134, 5.58505360638179)
```

"""
function change_oe_frame(a::Number,
                         e::Number,
                         i::Number,
                         Ω::Number,
                         ω::Number,
                         f::Number,
                         conv_args...)

    # The approach is to transform the orbit elements to Cartesian
    # representation, convert the frame, and then convert back to orbit
    # elements.
    #
    # NOTE: In my benchmarks, the operation with DCMs are faster than with
    # quaternions after the DCM representation was changed to SMatrix.

    r_o, v_o    = kepler_to_rv(a, e, i, Ω, ω, f)
    D_ECIf_ECIo = rECItoECI(DCM, conv_args...)
    r_f         = D_ECIf_ECIo*r_o
    v_f         = D_ECIf_ECIo*v_o

    rv_to_kepler(r_f, v_f)
end

function change_oe_frame(oe::Orbit, conv_args...)
    change_oe_frame(oe.a, oe.e, oe.i, oe.Ω, oe.ω, oe.f, conv_args...)
end

"""
    function kepler_to_rv(a::Number, e::Number, i::Number, Ω::Number, ω::Number, f::Number)

Convert the Keplerian elements (`a`, `e`, `i`, `Ω`, `ω`, and `f`) to a Cartesian
representation (position vector `r` and velocity vector `v`)

# Args

* `a`: Semi-major axis [m].
* `e`: Excentricity.
* `i`: Inclination [rad].
* `Ω`: Right ascension of the ascending node [rad].
* `ω`: Argument of perigee [rad].
* `f`: True anomaly [rad].

# Returns

* The position vector represented in the inertial reference frame [m].
* The velocity vector represented in the inertial reference frame [m].

# References

This algorithm was adapted from [1] and [3, p. 37-38].

"""
function kepler_to_rv(a::Number,
                      e::Number,
                      i::Number,
                      Ω::Number,
                      ω::Number,
                      f::Number)
    # Check eccentricity.
    if !(0 <= e < 1)
        throw(ArgumentError("Eccentricity must be in the interval [0,1)."))
    end

    # Auxiliary variables.
    sin_f     = sin(f)
    cos_f     = cos(f)

    # Compute the geocentric distance.
    r = a*(1-e^2)/(1+e*cos_f)

    # Compute the position vector in the orbit plane, defined as:
    #   - The X axis points towards the perigee;
    #   - The Z axis is perpendicular to the orbital plane (right-hand);
    #   - The Y axis completes a right-hand coordinate system.
    r_o = SVector{3}(r*cos_f, r*sin_f, 0)

    # Compute the velocity vector in the orbit plane without perturbations.
    n = angvel(a, e, i, :J0)
    v_o = n*a/sqrt(1-e^2)*SVector{3}(-sin_f, e+cos_f, 0)

    # Compute the matrix that rotates the orbit reference frame into the
    # inertial reference frame.
    Dio = angle2dcm(-ω, -i, -Ω, :ZXZ)

    # Compute the position and velocity represented in the inertial frame.
    r_i = Dio*r_o
    v_i = Dio*v_o

    (r_i, v_i)
end

"""
    function rv_to_kepler(r::Vector, v::Vector)

Convert a Cartesian representation (position vector `r` and velocity vector `v`)
to the Keplerian elements.

# Args

* `r`: Position vector in an inertial reference frame [m].
* `v`: Velocity vector in an inertial reference frame [m].

# Returns

An instance of the structure `Orbit` with the Keplerian elements [SI units].

# References

The algorithm was adapted from [1].

"""
function rv_to_kepler(r_i::AbstractVector, v_i::AbstractVector)
    # Position and velocity vector norms.
    r2 = r_i'*r_i
    v2 = v_i'*v_i

    r  = sqrt(r2)
    v  = sqrt(v2)

    # Angular momentum vector.
    h_i = cross( r_i, v_i )
    h   = norm(h_i)

    # Vector that points to the right ascension of the ascending node (RAAN).
    n_i = cross( [0;0;1], h_i )
    n   = norm(n_i)

    # Eccentricity vector.
    e_i = ( (v2 - m0/r)*r_i - dot(r_i, v_i)*v_i )/m0

    # Orbit energy.
    ξ = v2/2 - m0/r

    # Eccentricity
    # ============

    ecc = norm(e_i)

    # Semi-major axis
    # ===============

    if abs(ecc) <= 1.0-1e-6
        a = -m0/(2*ξ)
    else
        error("Could not convert the provided Cartesian values to Kepler elements.\n" *
              "The computed eccentricity was not between 0 and 1");
    end

    # Inclination
    # ===========
    i = acos(h_i[3]/h)

    # Right Ascension of the Ascending Node.
    # ======================================
    Ω = acos(n_i[1]/n)
    (n_i[2] < 0) && (Ω = 2*pi - Ω)

    # Argument of Perigee
    # ===================
    ω = acos(n_i'*e_i/(n*ecc))
    (e_i[3] < 0) && (ω = 2*pi - ω)

    # True anomaly
    # ============
    v = acos(e_i'*r_i/(ecc*r))
    (r_i'*v_i < 0) && (v = 2*pi - v)

    # Return the Keplerian elements.
    # ==============================

    Orbit(0.0,a,ecc,i,Ω,ω,v)
end

"""
    function rv_to_kepler(x::Number, y::Number, z::Number, vx::Number, vy::Number, vz::Number)

Convert a Cartesian representation (position vector `[x;y;z]` and velocity
vector `[vx;vy;vz]`) to the Keplerian elements.

# Args

* `x`: X component of the position vector in an inertial reference frame [m].
* `y`: Y component of the position vector in an inertial reference frame [m].
* `z`: Z component of the position vector in an inertial reference frame [m].
* `vx`: X component of the velocity vector in an inertial reference frame [m/s].
* `vy`: Y component of the velocity vector in an inertial reference frame [m/s].
* `vz`: Z component of the velocity vector in an inertial reference frame [m/s].

# Returns

* The Keplerian elements in this order:
    - Semi-major axis [km].
    - Eccentricity.
    - Inclination [rad].
    - Right ascension of the ascending node [rad].
    - Argument of perigee [rad].
    - True anomaly [rad].

"""
function rv_to_kepler(x::Number,  y::Number,  z::Number,
                      vx::Number, vy::Number, vz::Number)
    # Create the position and velocity vectors.
    r_i = SVector{3}( x, y, z)
    v_i = SVector{3}(vx,vy,vz)

    # Compute the Keplerian orbit elements.
    rv_to_kepler(r_i,v_i)
end
