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
#!   <C>Main.ForeignGAP.MPtr</C>.
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
#!  (see <Ref Chap="Immediate Integers and FFEs" BookName="dev"/>).
#!  Since these are not valid pointers, &Julia; cannot treat them like other
#!  &GAP; objects, which are simply &Julia; objects of type
#!  <C>Main.ForeignGAP.MPtr</C>.
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
#!    other &GAP; objects to <C>ForeignGAP.MPtr</C>.
#!  </Item>
#!  </List>
#!
#!  The following conversions are performed by <C>gap_julia</C>
#!  (from &Julia;'s <C>jl_value_t*</C> to &GAP;'s <C>Obj</C>).
#!  <List>
#!  <Item>
#!    <C>Int64</C> to immediate integer when it fits,
#!    otherwise to &Julia; object wrapper,
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
#!    <C>ForeignGAP.MPtr</C> to <C>Obj</C>,
#!  </Item>
#!  <Item>
#!    other &Julia; objects to &Julia; object wrapper.
#!  </Item>
#!  </List>

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
#!    <C>Rational{T} where T &lt;: Integer</C>,
#!  </Item>
#!  <Item>
#!    <C>MPtr and IsInt</C> to
#!    <C>BigInt</C> (default),
#!    <C>Rational{T} where T &lt;: Integer</C>,
#!  </Item>
#!  <Item>
#!    <C>MPtr and IsRat</C> to
#!    <C>Rational{BigInt}</C> (default),
#!    <C>Rational{T} where T &lt;: Integer</C>,
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
#!    <C>Array{UInt8,1}</C>,
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
#!    <C>BitArray{1}</C> (default),
#!    or types available for <C>IsList</C>,
#!  </Item>
#!  <Item>
#!    <C>IsList</C> to
#!    <C>Array{Union{Any,Nothing},1}</C> (default),
#!    <C>Array{T,1}</C>,
#!    <C>Array{T,2}</C>,
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
#!      <Item><C>Int64</C>, <C>MPtr</C>, <C>GapFFE</C>, and <C>Bool</C></Item>
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
#!      <Item><C>Array{T,1}</C></Item>
#!      <Item><C>IsList</C></Item>
#!      <Item>plain lists</Item>
#!    </Row>
#!    <Row>
#!      <Item><C>Array{Bool,1}</C>, <C>BitArray{1}</C></Item>
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
#!  Let <A>juliaobj</A> be an object in
#!  <Ref Filt="IsArgumentForJuliaFunction" Label="for IsObject"/>
#!  for which a conversion to &GAP; is provided,
#!  in the sense of Section <Ref Sect="Section_Conversion_rules"/>,
#!  such that the corresponding &GAP; object is in the filter <A>filt</A>.
#!  Then <Ref Constr="JuliaToGAP" Label="for IsObject, IsObject"/>
#!  returns this &GAP; object.
#!  <P/>
#!  For recursive structures (&GAP; lists and records),
#!  only the outermost level is converted except if the optional argument
#!  <A>recursive</A> is given and has the value <K>true</K>.
#!  <P/>
#! <!-- Note that the Julia output contains the "forbidden" sequence "]]>",
#!      thus the CDATA syntax cannot be used. -->
#! <Example>
#! gap> s:= GAPToJulia( "abc" );
#! &lt;Julia: "abc">
#! gap> JuliaToGAP( IsString, s );
#! "abc"
#! gap> l:= GAPToJulia( [ 1, 2, 4 ] );
#! &lt;Julia: Any[1, 2, 4]>
#! gap> JuliaToGAP( IsList, l );
#! [ 1, 2, 4 ]
#! </Example>
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

#! @Arguments [juliatype, ]gapobj
#! @Returns a &Julia; object
#! @Description
#!  Let <A>gapobj</A> be an object
#!  for which a conversion to &Julia; is provided,
#!  in the sense of Section <Ref Sect="Section_Conversion_rules"/>,
#!  such that a corresponding &Julia; object with type <A>juliatype</A>
#!  can be constructed.
#!  Then <Ref Func="GAPToJulia"/> returns this &Julia; object.
#!  <P/>
#!  If <A>juliatype</A> is not given then a default type is chosen.
#!  The function is implemented via the &Julia; function
#!  <C>GAP.gap_to_julia</C>.
#!  <P/>
#! <!-- Note that the Julia output contains the "forbidden" sequence "]]>",
#!      thus the CDATA syntax cannot be used. -->
#! <Example>
#! gap> GAPToJulia( 1 );
#! 1
#! gap> GAPToJulia( JuliaEvalString( "Rational{Int64}" ), 1 );
#! &lt;Julia: 1//1>
#! gap> l:= [ 1, 3, 4 ];;
#! gap> GAPToJulia( l );
#! &lt;Julia: Any[1, 3, 4]>
#! gap> GAPToJulia( JuliaEvalString( "Array{Int,1}" ), l );
#! &lt;Julia: [1, 3, 4]>
#! gap> m:= [ [ 1, 2 ], [ 3, 4 ] ];;
#! gap> GAPToJulia( m );
#! &lt;Julia: Any[Any[1, 2], Any[3, 4]]>
#! gap> GAPToJulia( JuliaEvalString( "Array{Int,2}" ), m );
#! &lt;Julia: [1 2; 3 4]>
#! gap> r:= rec( a:= 1, b:= [ 1, 2, 3 ] );;
#! gap> GAPToJulia( r );
#! &lt;Julia: Dict{Symbol,Any}(:a => 1,:b => Any[1, 2, 3])>
#! </Example>
DeclareGlobalFunction("GAPToJulia");

#! @Section Open items
#! <List>
#! <Item>
#!   On the &Julia; side,
#!   an alternative to <C>gap_to_julia</C> would be a bunch of
#!   constructor methods, e.g., <C>BigInt(x::MPtr)</C> or <C>big(x::MPtr)</C>
#!   to convert a &GAP; object to a &Julia; <C>BigInt</C>, if possible.
#!   Explain why we did not do this instead of <C>gap_to_julia</C>;
#!   think about the possibility of still prodiving these,
#!   implemented by calling <C>gap_to_julia</C> or vice versa.
#!   (Pro constructors: <C>BigInt(x)</C> is shorter than
#!   <C>gap_to_julia(BigInt, x)</C>.
#!   Con constructors: symmetry perhaps?)
#! </Item>
#! <Item>
#!   Discuss/add more dedicated conversion functions and/or special wrapper
#!   kinds, e.g.:
#!   <List>
#!   <Item>
#!     Add a custom <C>big</C> or <C>BigInt</C> method (or both?)
#!     which converts &GAP; integers to &Julia;;
#!     similar for &GAP; rationals, but there we may want to let the user
#!     choose which integer type to use on the &Julia; side for numerator
#!     and denominator.
#!   </Item>
#!   <Item>
#!     Add conversions from &Julia; bigints and rationals over
#!     various integer types, including bigints, to &GAP;.
#!   </Item>
#!   <Item>
#!     There could be a &Julia; type hierarchy of wrappers, e.g.,
#!     <C>GAPInt &lt;: GAPRat &lt;: GAPCyc</C>;
#!     those types would wrap the corresponding &GAP; objects,
#!     i.e., they would simply wrap a <C>Union{MPtr,Int64}</C>,
#!     but perhaps provided nicer integration with the rest of &Julia;,
#!     like methods for <C>gcd</C>, say, which are properly type restricted;
#!     or nicer printing (w/o the <C>GAP:</C> prefix even?).
#!     Not really sure whether this is useful, though.
#!   </Item>
#!   <Item>
#!     How do other types of integers, e.g., fmpz from FLINT,
#!     enter this setup? Are &Julia;'s <C>Big</C> really useful?
#!   </Item>
#!   </List>
#! </Item>
#! <Item>
#!   Should we restrict the automatic FFE conversion to <C>IsInternalRep</C>?
#! </Item>
#! <Item>
#!   Why is <Ref Func="GAPToJulia"/> always recursive?
#! </Item>
#! <Item>
#!   Is there a way to call &Julia; functions with named arguments
#!   from &GAP; via the interface?
#! </Item>
#! <Item>
#!   Should we allow the three argument case of <C>JuliaToGAP</C> in all
#!   cases, e.g., <C>JuliaToGAP( IsInt, 1, true )</C>?
#! </Item>
#! <Item>
#!   Would it make sense to show &Julia; help in a &GAP; session,
#!   for example via <C>?Julia:length</C> or <C>?Julia:Base.length</C>?
#!   (What is the easiest way to regard <C>"Julia"</C> as a &GAP; help book?)
#!   <!-- see REPL/src/docview.jl in Julia -->
#! </Item>
#! <Item>
#!   The introductory chapter/section
#!   (see <Ref Chap="Chapter_Introduction_to_PackageJuliaInterfacePackage"/>)
#!   is missing.
#! </Item>
#! <Item>
#!   Many tests of conversions are missing.
#! </Item>
#! </List>
