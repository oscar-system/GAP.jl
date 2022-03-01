#############################################################################
##
##  JuliaInterface package
##
#############################################################################

#! @Chapter Conversions between &GAP; and &Julia;

#! @Section Conversion rules
#! @SectionLabel Conversion_rules

#! @Subsection Guiding principles
#! <List>
#! <Mark>Avoid conversions, use wrapper objects instead.</Mark>
#! <Item>
#!   Naively, one may think that in order to use &Julia; functionality
#!   from &GAP;,
#!   one has to convert all data to a format usable by &Julia;,
#!   then call &Julia; functions on that data, and finally convert it back;
#!   rinse and repeat.
#!   While this is certainly sometimes so, in many cases,
#!   things are a bit different:
#!   Some initial (usually very small) data may need to be converted.
#!   But afterwards, the output of one &Julia; function is used as input
#!   of the next one, and so on.
#!   Converting the data to &GAP; format and back then is needlessly wasteful.
#!   It is much better to not perform any conversion here.
#!   Instead, we create special <Q>wrapper</Q> objects on the &GAP; side,
#!   which wraps a given &Julia; object without converting it.
#!   This operation is thus very cheap, both in terms of performance and in
#!   memory usage.
#!   Such a wrapped object can then be transparently used as input for
#!   &Julia; functions.
#!   <P/>
#!   On the &GAP; C kernel level, the internal functions used for this are
#!   <C>NewJuliaObj</C>, <C>IS_JULIA_OBJ</C>, <C>GET_JULIA_OBJ</C>.
#!   On the &GAP; language level,
#!   this is <Ref Filt="IsJuliaObject" Label="for IsObject"/>.
#!   On the &Julia; side, there is usually no need for a wrapper,
#!   as (thanks to the shared garbage collector)
#!   most &GAP; objects are valid &Julia; objects of type
#!   <C>GAP.GapObj</C>.
#!   The exception to that rule are immediate &GAP; objects,
#!   more on that in the next section.
#! </Item>
#! <Mark>Perform automatic conversions only if absolutely necessary,
#!       or if unambiguous and free.</Mark>
#! <Item>
#!   Any conversion which the user cannot prevent,
#!   and which has some cost or choice involved, may cause several problems.
#!   The added overhead may turn an otherwise reasonable computation into an
#!   infeasible one (think about a conversion triggered several million
#!   times).
#!   And the conversion can add extra complications if one wants to detect
#!   and undo it.
#! </Item>
#! <Mark>Provide explicit conversion functions for as many data types
#!       as possible.</Mark>
#! <Item>
#!   While users should not be forced into conversions,
#!   it nevertheless should be possible to perform sensible conversions.
#!   The simpler it is to do so, the easier it is to use the interface.
#! </Item>
#! <Mark>Conversion round trip fidelity.</Mark>
#! <Item>
#!   If an object is converted from &Julia; to &GAP; and back to &Julia;
#!   (or conversely, from &GAP; to &Julia; and back to &GAP;),
#!   then ideally the result should be equal and of equal type
#!   to the original value.
#!   At the very least,
#!   the automatic conversions should follow this principle.
#!   This is not always possible, due to mismatches in existing types,
#!   but we strive to get as close as possible.
#! </Item>
#! </List>

#! @Subsection Automatic (implicit) conversions
#!  &GAP; has a notion of <Q>immediate</Q> objects,
#!  whose values are stored inside the <Q>pointer</Q> referencing them.
#!  &GAP; uses this to store small integers
#!  and elements of small finite fields,
#!  <!-- (see <Ref Chap="Immediate Integers and FFEs" BookName="dev"/>). -->
#!  see for example the beginning of Chapter
#!  <Ref Chap="Integers" BookName="ref"/> in the &GAP; Reference Manual.
#!  Since these are not valid pointers, &Julia; cannot treat them like other
#!  &GAP; objects, which are simply &Julia; objects of type
#!  <C>GAP.GapObj</C>.
#!  Instead, a conversion is unavoidable, at least when immediate objects
#!  are passed as stand-alone arguments to a function.
#!  <P/>
#!  To this end, the interface converts &GAP; immediate integers into
#!  &Julia; <C>Int64</C> objects, and vice versa.
#!  However, &GAP; immediate integers on a 64 bit system can only store
#!  61 bits, so not all <C>Int64</C>objects can be converted into immediate
#!  integers;
#!  integers exceeding the 61 bits limit are therefore wrapped like any other
#!  &Julia; object.
#!  Other &Julia; integer types, like <C>UInt64</C>, <C>Int32</C>,
#!  are also wrapped by default,
#!  in order to ensure that conversion round trips do not arbitrary change
#!  object types.
#!  <P/>
#!  All automatic conversions and wrappings are handled on the C functions
#!  <C>julia_gap</C> and <C>gap_julia</C>
#!  in <Package>JuliaInterface</Package>.
#!  <!-- What is meant by this:
#!       Whenever one calls a GAP function on Julia arguments or a Julia
#!       functions on GAP arguments, julia_gap or gap_julia are called
#!       on the arguments and on the result,
#!       and this way the automatic conversions are guaranteed. -->
#!  <P/>
#!  The following conversions are performed by <C>julia_gap</C>
#!  (from &GAP;'s <C>Obj</C> to &Julia;'s <C>jl_value_t*</C>).
#!  <!-- see JuliaInterface/src/convert.c -->
#!  <List>
#!  <Item>
#!    <C>NULL</C> to <C>jl_nothing</C>,
#!  </Item>
#!  <Item>
#!    immediate integer to <C>Int64</C>,
#!  </Item>
#!  <Item>
#!    immediate FFE to the <C>GapFFE</C> &Julia; type,
#!  </Item>
#!  <Item>
#!    &GAP; <K>true</K> to &Julia; <C>true</C>,
#!  </Item>
#!  <Item>
#!    &GAP; <K>false</K> to &Julia; <C>false</C>,
#!  </Item>
#!  <Item>
#!    &Julia; object wrapper to &Julia; object,
#!  </Item>
#!  <Item>
#!    &Julia; function wrapper to &Julia; function,
#!  </Item>
#!  <Item>
#!    other &GAP; objects to <C>GAP.GapObj</C>.
#!  </Item>
#!  </List>
#!
#!  The following conversions are performed by <C>gap_julia</C>
#!  (from &Julia;'s <C>jl_value_t*</C> to &GAP;'s <C>Obj</C>).
#!  <List>
#!  <Item>
#!    <C>Int64</C> to immediate integer when it fits,
#!    otherwise to a &GAP; large integer,
#!  </Item>
#!  <Item>
#!    <C>GapFFE</C> to immediate FFE,
#!  </Item>
#!  <Item>
#!    &Julia; <C>true</C> to &GAP; <K>true</K>,
#!  </Item>
#!  <Item>
#!    &Julia; <C>false</C> to &GAP; <K>false</K>,
#!  </Item>
#!  <Item>
#!    <C>GAP.GapObj</C> to <C>Obj</C>,
#!  </Item>
#!  <Item>
#!    other &Julia; objects to &Julia; object wrapper.
#!  </Item>
#!  </List>
#TODO: re-enter the cross-reference to the "dev" manual when this is possible

#! @Subsection Manual (explicit) conversions
#!  Manual conversion in &GAP; is done via the functions
#!  <Ref Func="GAPToJulia"/> and
#!  <Ref Constr="JuliaToGAP" Label="for IsObject, IsObject"/>.
#!  In &Julia;, conversion is done via <C>gap_to_julia</C> and
#!  <C>julia_to_gap</C>.
#!
#!  <E>Conversion from &GAP; to &Julia;</E>
#!
#!  In &GAP;, the function <Ref Func="GAPToJulia"/> calls
#!  (after automatic conversion of the &GAP; object if applicable)
#!  the &Julia; function <C>gap_to_julia</C>;
#!  If a &Julia; type has been entered as the first argument of
#!  <Ref Func="GAPToJulia"/> then this is the type to which the
#!  &GAP; object shall be converted, and if such a conversion is implemented
#!  then a &Julia; object of this type is returned,
#!  otherwise an <C>ArgumentError</C> is thrown.
#!
#!  <!-- in GAP.jl/src/gap_to_julia.jl -->
#!  <List>
#!  <Item>
#!    <C>IsBool</C> to
#!    <C>Bool</C>,
#!  </Item>
#!  <Item>
#!    <C>IsFFE and IsInternalRep</C> to
#!    <C>GapFFE</C>,
#!  </Item>
#!  <Item>
#!    <C>IsInt and IsSmallIntRep</C> to
#!    <C>Int8</C>,
#!    <C>Int16</C>,
#!    <C>Int32</C>,
#!    <C>Int64</C> (default),
#!    <C>Int128</C>,
#!    <C>UInt8</C>,
#!    <C>UInt16</C>,
#!    <C>UInt32</C>,
#!    <C>UInt64</C>,
#!    <C>UInt128</C>,
#!    <C>BigInt</C>,
#!    <C>Rational{T} where T &lt;:&nbsp;Integer</C>,
#!  </Item>
#!  <Item>
#!    <C>GapObj and IsInt</C> to
#!    <C>BigInt</C> (default),
#!    <C>Rational{T} where T &lt;:&nbsp;Integer</C>,
#!  </Item>
#!  <Item>
#!    <C>GapObj and IsRat</C> to
#!    <C>Rational{BigInt}</C> (default),
#!    <C>Rational{T} where T &lt;:&nbsp;Integer</C>,
#!  </Item>
#!  <Item>
#!    <C>IsFloat</C> to
#!    <C>Float16</C>,
#!    <C>Float32</C>,
#!    <C>Float64</C> (default),
#!    <C>BigFloat</C>,
#!  </Item>
#!  <Item>
#!    <C>IsChar</C> to
#!    <C>Cuchar</C>,
#!    <!-- also to Char, Int8, UInt8 ? -->
#!  </Item>
#!  <Item>
#!    <C>IsString</C> to
#!    <C>AbstractString</C> (default),
#!    <C>String</C>,
#!    <C>Symbol</C>,
#!    <C>Vector{UInt8}</C>,
#!    or types available for <C>IsList</C>,
#!  </Item>
#!  <Item>
#!    <C>IsRange</C> to
#!    <C>StepRange{Int64,Int64}</C> (default),
#!    <C>StepRange{T1,T2}</C>,
#!    <C>UnitRange{T}</C>,
#!    or types available for <C>IsList</C>,
#!  </Item>
#!  <Item>
#!    <C>IsBlist</C> to
#!    <C>BitVector</C> (default),
#!    or types available for <C>IsList</C>,
#!  </Item>
#!  <Item>
#!    <C>IsList</C> to
#!    <C>Vector{Union{Any,Nothing}}</C> (default),
#!    <C>Vector{T}</C>,
#!    <C>Matrix{T}</C>,
#!    <C>T &lt;: Tuple</C>,
#!  </Item>
#!  <Item>
#!    <C>IsRecord</C> to
#!    <C>Dict{Symbol,Any}</C> (default),
#!    <C>Dict{Symbol,T}</C>.
#!  </Item>
#!  </List>
#!
#!  If no &Julia; type is specified then a &Julia; type is chosen,
#!  based on the filters of the &GAP; object,
#!  see the <Q>(default)</Q> markers in the above list.
#!  Note that this might include checking various filters and will be,
#!  in almost all cases, slower than the typed version.
#!
#!  <E>Conversion from &Julia; to &GAP;</E>
#!
#!  The function <Ref Constr="JuliaToGAP" Label="for IsObject, IsObject"/>
#!  is a &GAP; constructor taking two arguments,
#!  a &GAP; filter and an object to be converted.
#!  Various methods for this constructor then take care of input validation
#!  and the actual conversion, either by delegating to the &Julia; function
#!  <C>julia_to_gap</C>
#!  (which takes just one argument and chooses the &GAP; filters of its
#!  result depending on the &Julia; type),
#!  or by automatic conversion.
#!  The supported &Julia; types are as follows.
#!
#!  <Table Align="|l|l|l|">
#!    <HorLine/>
#!    <Row>
#!      <Item>&Julia; type</Item>
#!      <Item>&GAP; filter</Item>
#!      <Item>comment</Item>
#!    </Row>
#!    <HorLine/>
#!    <Row>
#!      <Item><C>Int64</C>, <C>GapObj</C>, <C>GapFFE</C>, and <C>Bool</C></Item>
#!      <Item></Item>
#!      <Item>automatic conversion</Item>
#!    </Row>
#!    <Row>
#!      <Item>other integers, including <C>BigInt</C></Item>
#!      <Item><C>IsInt</C></Item>
#!      <Item>integers</Item>
#!    </Row>
#!    <Row>
#!      <Item><C>Rational{T}</C></Item>
#!      <Item><C>IsRat</C></Item>
#!      <Item>rationals</Item>
#!    </Row>
#!    <Row>
#!      <Item><C>Float16</C>, <C>Float32</C>, <C>Float64</C></Item>
#!      <Item><C>IsFloat</C></Item>
#!      <Item>machine floats</Item>
#!    </Row>
#!    <Row>
#!      <Item><C>AbstractString</C></Item>
#!      <Item><C>IsString</C></Item>
#!      <Item>strings</Item>
#!    </Row>
#!    <Row>
#!      <Item>Symbol</Item>
#!      <Item><C>IsString</C></Item>
#!      <Item>strings</Item>
#!    </Row>
#!    <Row>
#!      <Item><C>Vector{T}</C></Item>
#!      <Item><C>IsList</C></Item>
#!      <Item>plain lists</Item>
#!    </Row>
#!    <Row>
#!      <Item><C>Vector{Bool}</C>, <C>BitVector</C></Item>
#!      <Item><C>IsBList</C></Item>
#!      <Item>bit lists</Item>
#!    </Row>
#!    <Row>
#!      <Item><C>Tuple{T}</C></Item>
#!      <Item><C>IsList</C></Item>
#!      <Item>plain lists</Item>
#!    </Row>
#!    <Row>
#!      <Item><C>Dict{String,T}</C>, <C>Dict{Symbol,T}</C></Item>
#!      <Item><C>IsRecord</C></Item>
#!      <Item>records</Item>
#!    </Row>
#!    <Row>
#!      <Item><C>UnitRange{T}</C>, <C>StepRange{T}</C></Item>
#!      <Item><C>IsRange</C></Item>
#!      <Item>ranges</Item>
#!    </Row>
#!    <HorLine/>
#!  </Table>

#! @Section Conversion functions
#! @SectionLabel Conversion_functions

#! @Arguments filt, juliaobj[, recursive]
#! @Returns a &GAP; object in the filter <A>filt</A>
#! @Description
#!  Let <A>juliaobj</A> be a Julia object in
#!  for which a conversion to &GAP; is provided,
#!  in the sense of Section <Ref Sect="Section_Conversion_rules"/>,
#!  such that the corresponding &GAP; object is in the filter <A>filt</A>.
#!  Then <Ref Constr="JuliaToGAP" Label="for IsObject, IsObject"/>
#!  returns this &GAP; object.
#!
#!  For recursive structures (&GAP; lists and records),
#!  only the outermost level is converted except if the optional argument
#!  <A>recursive</A> is given and has the value <K>true</K>,
#!  in this case all layers are converted recursively.
#!
#!  Note that this default is different from the default in the other
#!  direction (see <Ref Func="GAPToJulia"/>).
#!  The idea behind this choice is that from the viewpoint of a &GAP; session,
#!  it is more likely to use plain &Julia; objects for computations on the
#!  &Julia; side than &Julia; objects that contain &GAP; subobjects,
#!  whereas <Q>shallow conversion</Q> of &Julia; objects to &GAP; yields
#!  something useful on the &GAP; side.
#!
#! @BeginExampleSession
#! gap> s:= GAPToJulia( "abc" );
#! <Julia: "abc">
#! gap> JuliaToGAP( IsString, s );
#! "abc"
#! gap> l:= GAPToJulia( [ 1, 2, 4 ] );
#! <Julia: Any[1, 2, 4]>
#! gap> JuliaToGAP( IsList, l );
#! [ 1, 2, 4 ]
#! @EndExampleSession
#!
#!  The following values for <A>filt</A> are supported.
#!  <Ref Filt="IsInt" BookName="ref"/>,
#!  <Ref Filt="IsRat" BookName="ref"/>,
#!  <Ref Filt="IsFFE" BookName="ref"/>,
#!  <C>IsFloat</C> (see <Ref Chap="Floats" BookName="ref"/>),
#!  <Ref Filt="IsBool" BookName="ref"/>,
#!  <Ref Filt="IsChar" BookName="ref"/>,
#!  <Ref Filt="IsRecord" BookName="ref"/>,
#!  <Ref Filt="IsString" BookName="ref"/>,
#!  <Ref Filt="IsRange" BookName="ref"/>,
#!  <Ref Filt="IsBlist" BookName="ref"/>,
#!  <Ref Filt="IsList" BookName="ref"/>.
#!  See Section <Ref Sect="Section_Conversion_rules"/> for the admissible types
#!  of <A>juliaobj</A> in these cases.
DeclareConstructor("JuliaToGAP", [IsObject, IsObject]);

DeclareConstructor("JuliaToGAP", [IsObject, IsObject, IsBool]);

#! @Arguments [juliatype, ]gapobj[, recursive]
#! @Returns a &Julia; object
#! @Description
#!  Let <A>gapobj</A> be an object
#!  for which a conversion to &Julia; is provided,
#!  in the sense of Section <Ref Sect="Section_Conversion_rules"/>,
#!  such that a corresponding &Julia; object with type <A>juliatype</A>
#!  can be constructed.
#!  Then <Ref Func="GAPToJulia"/> returns this &Julia; object.
#!
#!  If <A>juliatype</A> is not given then a default type is chosen.
#!  The function is implemented via the &Julia; function
#!  <C>GAP.gap_to_julia</C>.
#!
#! <!-- Note that the Julia output contains the "forbidden" sequence "]]>",
#!      thus the CDATA syntax cannot be used. -->
#!<Example>
#!gap> GAPToJulia( 1 );
#!1
#!gap> GAPToJulia( JuliaEvalString( "Rational{Int64}" ), 1 );
#!&lt;Julia: 1//1>
#!gap> l:= [ 1, 3, 4 ];;
#!gap> GAPToJulia( l );
#!&lt;Julia: Any[1, 3, 4]>
#!gap> GAPToJulia( JuliaEvalString( "Vector{Int}" ), l );
#!&lt;Julia: [1, 3, 4]>
#!gap> m:= [ [ 1, 2 ], [ 3, 4 ] ];;
#!gap> GAPToJulia( m );
#!&lt;Julia: Any[Any[1, 2], Any[3, 4]]>
#!gap> GAPToJulia( JuliaEvalString( "Matrix{Int}" ), m );
#!&lt;Julia: [1 2; 3 4]>
#!gap> r:= rec( a:= 1, b:= [ 1, 2, 3 ] );;
#!gap> GAPToJulia( r );
#!&lt;Julia: Dict{Symbol,Any}(:a => 1,:b => Any[1, 2, 3])>
#!</Example>
#!
#!  If <A>gapobj</A> is a list or a record, one may want that its subobjects
#!  are also converted to &Julia; or that they are kept as they are,
#!  which can be decided by entering <K>true</K> or <K>false</K> as the value
#!  of the optional argument <A>recursive</A>;
#!  the default is <K>true</K>, that is, the subobjects of <A>gapobj</A> are
#!  converted recursively.
#!
#!  Note that this default is different from the default in the other
#!  direction,
#!  see the description of
#!  <Ref Constr="JuliaToGAP" Label="for IsObject, IsObject"/>.
#!
#!<Example>
#!gap> jl:= GAPToJulia( m, false );
#!&lt;Julia: Any[GAP: [ 1, 2 ], GAP: [ 3, 4 ]]>
#!gap> jl[1];
#![ 1, 2 ]
#!gap> jr:= GAPToJulia( r, false );
#!&lt;Julia: Dict{Symbol,Any}(:a => 1,:b => GAP: [ 1, 2, 3 ])>
#!gap> Julia.Base.get( jr, JuliaSymbol( "b" ), fail );
#![ 1, 2, 3 ]
#!</Example>
DeclareGlobalFunction("GAPToJulia");

#! @Section Using &Julia; random number generators in &GAP;
#! @Arguments obj
#! @Description
#!  This filter allows one to use &Julia;'s random number generators in &GAP;,
#!  see <Ref Sect="Random Sources" BookName="ref"/> for the background.
#!  Calling <Ref Oper="RandomSource" BookName="ref"/> with only argument
#!  <Ref Filt="IsRandomSourceJulia" Label="for IsRandomSource"/> yields a
#!  &GAP; random source that uses a copy of &Julia;'s default random number
#!  generator <C>Julia.Random.default_rng()</C>.
#!  Note that different calls with only argument
#!  <Ref Filt="IsRandomSourceJulia" Label="for IsRandomSource"/> yield
#!  different random sources.
#!  <P/>
#!  Called with <Ref Filt="IsRandomSourceJulia" Label="for IsRandomSource"/>
#!  and a positive integer,
#!  <Ref Oper="RandomSource" BookName="ref"/> returns a random source that is
#!  based on a copy of <C>Julia.Random.default_rng()</C> but got initialized
#!  with the given integer as a seed.
#!  <P/>
#!  Called with <Ref Filt="IsRandomSourceJulia" Label="for IsRandomSource"/>
#!  and a &Julia; random number generator,
#!  <Ref Oper="RandomSource" BookName="ref"/> returns a random source
#!  that uses this random number generator.
#!  Note that we do <E>not</E> make a copy of the second argument,
#!  in order to be able to use the given random number generator both on the
#!  &GAP; side and the &Julia; side.
#!  <P/>
#!  <Ref Oper="State" BookName="ref"/> for random sources in
#!  <Ref Filt="IsRandomSourceJulia" Label="for IsRandomSource"/> returns
#!  a copy of the underlying &Julia; random number generator.
#! @BeginExampleSession
#! gap> rs1:= RandomSource( IsRandomSourceJulia );
#! <RandomSource in IsRandomSourceJulia>
#! gap> rs2:= RandomSource( IsRandomSourceJulia,
#! >                        Julia.Random.default_rng() );
#! <RandomSource in IsRandomSourceJulia>
#! gap> repeat
#! >   x:= Random( rs1, [ 1 .. 100 ] );
#! >   y:= Random( rs2, [ 1 .. 100 ] );
#! > until x <> y;
#! gap> Random( rs1, 1, 100 ) in [ 1 .. 100 ];
#! true
#! gap> from:= 2^70;;  to:= from + 100;;
#! gap> x:= Random( rs1, from, to );;
#! gap> from <= x and x <= to;
#! true
#! gap> g:= SymmetricGroup( 10 );;
#! gap> Random( rs1, g ) in g;
#! true
#! gap> State( rs1 ) = JuliaPointer( rs1 );
#! true
#! @EndExampleSession
DeclareCategory( "IsRandomSourceJulia", IsRandomSource );

#! @Section Open items
#! <List>
#! <Item>
#!   Discuss/add more dedicated conversion functions and/or special wrapper
#!   kinds, e.g.:
#!   <List>
#!   <Item>
#!     There could be a &Julia; type hierarchy of wrappers, e.g.,
#!     <C>GAPInt &lt;: GAPRat &lt;: GAPCyc</C>;
#!     those types would wrap the corresponding &GAP; objects,
#!     i.e., they would simply wrap a <C>Union{GapObj,Int64}</C>,
#!     but perhaps provided nicer integration with the rest of &Julia;,
#!     like methods for <C>gcd</C>, say, which are properly type restricted;
#!     or nicer printing (w/o the <C>GAP:</C> prefix even?).
#!     Not really sure whether this is useful, though.
#!   </Item>
#!   </List>
#! </Item>
#! <Item>
#!   Should we allow the three argument case of
#!   <Ref Constr="JuliaToGAP" Label="for IsObject, IsObject"/> in all cases,
#!   e.g., <C>JuliaToGAP( IsInt, 1, true )</C>?
#! </Item>
#! <Item>
#!   Many tests of conversions are missing.
#! </Item>
#! </List>
