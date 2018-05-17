VERSION >= v"0.4.0-dev+6521" && __precompile__()

module SatelliteToolbox

export JD_J2000, R0, Rm, m0, J2, Rs, ne, au2m, sunRad
export a_wgs84, b_wgs84, f_wgs84, e_wgs84, el_wgs84

import Base: asin, atan2, copy, cos, deepcopy, getindex, mod, sin, show

VERSION >= v"0.7.0-DEV" && using Dates
VERSION >= v"0.7.0-DEV" && using LinearAlgebra
VERSION >= v"0.7.0-DEV" && using Printf

using ReferenceFrameRotations
using StaticArrays

# Re-exporting symbols from ReferenceFrameRotations.jl.
export DCM
export Quaternion

################################################################################
#                             Types and Structures
################################################################################

include("types.jl")

################################################################################
#                                  Constants
################################################################################

include("constants.jl")

################################################################################
#                                  Exceptions
################################################################################

################################################################################
#                                    Files
################################################################################

include("./aux/legendre.jl")
include("./aux/dlegendre.jl")

include("analysis/beta_angle.jl")
include("analysis/eclipse_time.jl")
include("analysis/lighting_conditions.jl")
include("analysis/raan.jl")
include("analysis/payload_optical_analysis.jl")
include("analysis/satellite_position_countries.jl")
include("analysis/satellite_position_groundstations.jl")
include("analysis/sun_angle.jl")
include("analysis/sun_radiation.jl")

include("earth/gravity_models/egm.jl")
include("earth/geomagnetic_field_models/igrf.jl")
include("earth/geomagnetic_field_models/igrf12_coefs.jl")
include("earth/geomagnetic_field_models/igrf12syn_coefs.jl")

include("sun/equation_of_time.jl")
include("sun/sun_position.jl")

include("orbit/general.jl")
include("orbit/anomalies.jl")
include("orbit/orbit_aux.jl")
include("orbit/orbit_sun_sync.jl")
include("orbit/orbit_sun_sync_ground_reap.jl")
include("orbit/tle.jl")
include("orbit/propagators/j2.jl")
include("orbit/propagators/j2_api.jl")
include("orbit/propagators/sgp4.jl")
include("orbit/propagators/sgp4_api.jl")
include("orbit/propagators/twobody.jl")
include("orbit/propagators/twobody_api.jl")

include("transformations/aux.jl")
include("transformations/eop.jl")
include("transformations/ecef_to_eci.jl")
include("transformations/eci_to_ecef.jl")
include("transformations/geodetic_geocentric.jl")
include("transformations/gmst.jl")
include("transformations/orbit_elements.jl")
include("transformations/position.jl")

include("transformations/fk5/fk5.jl")
include("transformations/fk5/nutation.jl")
include("transformations/fk5/precession.jl")

include("time/julian_day.jl")
include("time/time.jl")

end # module
