# Example implementation using as few function definitions as possible
#
using StaticArrays

export FastSystem

struct FastSystem{D,ET,L<:Unitful.Length} <:
       AbstractSystem{D,ET}
    box::SVector{D,SVector{D,L}}
    boundary_conditions::SVector{D,BoundaryCondition}
    positions::Vector{SVector{D,L}}
    elements::Vector{ET}
    # janky inner constructor that we need for some reason
    FastSystem(box, boundary_conditions, positions, elements) =
        new{length(boundary_conditions),eltype(elements),eltype(eltype(positions))}(
            box,
            boundary_conditions,
            positions,
            elements,
        )
end

# convenience constructor where we don't have to preconstruct all the static stuff...
function FastSystem(
    box::AbstractVector{Vector{L}},
    boundary_conditions::AbstractVector{BC},
    positions::AbstractMatrix{M},
    elements::AbstractVector{ET},
) where {L<:Unitful.Length,BC<:BoundaryCondition,M<:Unitful.Length,ET}
    N = length(elements)
    D = length(box)
    if !all(length.(box) .== D)
        throw(ArgumentError("box must have D vectors of length D"))
    end
    if !(size(positions, 1) == N)
        throw(ArgumentError("box must have D vectors of length D"))
    end
    if !(size(positions, 2) == D)
        throw(ArgumentError("box must have D vectors of length D"))
    end
    FastSystem(
        SVector{D,SVector{D,L}}(box),
        SVector{D,BoundaryCondition}(boundary_conditions),
        Vector{SVector{D,eltype(positions)}}([positions[i, :] for i = 1:N]),
        elements,
    )
end

function Base.show(io::IO, ::MIME"text/plain", sys::FastSystem)
    print(io, "FastSystem with ", length(sys), " particles")
end

bounding_box(sys::FastSystem) = sys.box
boundary_conditions(sys::FastSystem) = sys.boundary_conditions

# Base.size(sys::FastSystem) = size(sys.particles)
Base.length(sys::FastSystem{D,ET}) where {D,ET} = length(sys.elements)

# first piece of trickiness: can't do a totally abstract dispatch here because we need to know the signature of the constructor for AT
Base.getindex(sys::FastSystem{D,ET}, i::Int) where {D,ET} =
    StaticAtom{D}(sys.positions[i], sys.elements[i])
