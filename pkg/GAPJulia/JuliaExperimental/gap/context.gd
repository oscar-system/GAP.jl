##############################################################################
##
##  context.gd
##
##  declarations for context objects,
##  which are used for generic conversions between GAP and Nemo/Singular
##


##############################################################################
##
#C  IsContextObj( <obj> )
##
DeclareCategory( "IsContextObj", IsObject );


##############################################################################
##
#V  ContextObjectsFamily
##
BindGlobal( "ContextObjectsFamily", NewFamily( "ContextObjectsFamily" ) );


##############################################################################
##
#A  ContextGAPNemo( <D> )
#A  ContextGAPSingular( <D> )
##
##  Note that a GAP domain can have conversions to both Nemo and Singular.
##
DeclareAttribute( "ContextGAPNemo", IsDomain );

DeclareAttribute( "ContextGAPSingular", IsDomain );


##############################################################################
##
#F  NewContextGAPJulia( "Nemo", <arec> )
#F  NewContextGAPJulia( "Singular", <arec> )
##
##  checks the record <arec> for the availability of the mandatory components,
##  turns the record <arec> into an object in the filter
##  <Ref Cat="IsContextObj"/>,
##  and sets attributes.
##
##  The following components (with the given filters) are mandatory.
##  Name (<C>IsString</C>),
##  GAPDomain (<C>IsDomain</C>),
##  JuliaDomain (<C>HasJuliaPointer</C>),
##  ElementType (<C>IsType</C>),
##  ElementGAPToJulia (<C>IsFunction</C>),
##  ElementJuliaToGAP (<C>IsFunction</C>),
##  ElementWrapped (<C>IsFunction</C>),
##  VectorType (<C>IsType</C>),
##  VectorGAPToJulia (<C>IsFunction</C>),
##  VectorJuliaToGAP (<C>IsFunction</C>),
##  VectorWrapped (<C>IsFunction</C>),
##  MatrixType (<C>IsType</C>),
##  MatrixGAPToJulia (<C>IsFunction</C>),
##  MatrixJuliaToGAP (<C>IsFunction</C>),
##  MatrixWrapped (<C>IsFunction</C>).
##  The functions take a converter object and the object that is to be
##  converted or wrapped, and are expected to return an object in
##  <Ref Filt="IsJuliaObject"/> (i. e., not a wrapped object with attribute
##  <Ref Attr="JuliaPointer"/>).
##
#T TODO: Provide defaults for some of them.
##
DeclareGlobalFunction( "NewContextGAPJulia" );

