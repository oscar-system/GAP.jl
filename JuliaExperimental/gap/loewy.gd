##############################################################################
##
##  loewy.gd
##
##  This file contains declarations of GAP functions for studying
##  the Loewy structure of Singer algebras $A(q,n,e)$.
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
              "loewy.jl" ) );


#############################################################################
##
##  Declare the necessary filters and operations.
##


#############################################################################
##
#C  IsSingerAlgebra( <A> )
##
DeclareCategory( "IsSingerAlgebra",
    IsAlgebraWithOne and IsAbelian and IsAssociative );


#############################################################################
##
#A  ParametersOfSingerAlgebra( <A> )
##
##  For a Singer algebra <A>A</A><M> = A(q, n, e)</M>
##  (see <Ref Func="SingerAlgebra"/>),
##  the value is the list <M>[ q, n, e ]</M>.
##
DeclareAttribute( "ParametersOfSingerAlgebra", IsSingerAlgebra );


#############################################################################
##
#A  LoewyStructureInfo( <A> )
##
##  For a Singer algebra <A>A</A> (see <Ref Func="SingerAlgebra"/>
##  with parameters <M>[ q, n, e ]</M>,
##  the value is a Julia dictionary whose keys are the following symbols.
##  <List>
##  <Mark><C>:monomials</C></Mark>
##  <Item>
##     the array of <M>q</M>-adic expansions of length <M>n</M>
##     for multiples of <M>e</M>,
##  </Item>
##  <Mark><C>:layers</C></Mark>
##  <Item>
##     the array of the Loewy layers to which the monomials belong,
##  </Item>
##  <Mark><C>:chain</C></Mark>
##  <Item>
##     an array of positions of monomials of a longest ascending chain,
##  </Item>
##  <Mark><C>:m</C></Mark>
##  <Item>
##     the value <M>m(q, e)</M>,
##  </Item>
##  <Mark><C>:ll</C></Mark>
##  <Item>
##     the Loewy length of <A>A</A>,
##     equal to the length of the <C>:layers</C> value plus <M>1</M>,
##  </Item>
##  <Mark><C>:inputs</C></Mark>
##  <Item>
##     the array <M>[ q, n, e ]</M> of parameters of <A>A</A>.
##  </Item>
##  </List>
##
DeclareAttribute( "LoewyStructureInfo", IsSingerAlgebra );


#############################################################################
##
#A  DimensionsLoewyFactors( <A> )
##
##  For a Singer algebra <A>A</A> (see <Ref Func="SingerAlgebra"/>),
##  this function returns the Loewy vector of <A>A</A>, that is,
##  the list of nonzero dimensions <M>J^{{i-1}} / J^i</M>,
##  for <M>i \geq 1</M>, where <M>J</M> is the JAcobson radical of <A>A</A>
##  and <M>J^0 = </M><A>A</A>.
##  <P/>
##  In the &GAP; Reference Manual, this attribute is declared for groups,
##  see <Ref Attr="DimensionsLoewyFactors" BookName="ref"/>.
##  In that context, it means the dimensions of the Loewy factors of the
##  group algebra of a finite <M>p</M>-group over the field with <M>p</M>
##  elements; the value can be computed just from the group,
##  without constructing a group algebra.
##
DeclareAttribute( "DimensionsLoewyFactors", IsSingerAlgebra );


#############################################################################
##
#A  LoewyLength( <A> )
#O  LoewyLength( <q>, <n>, <e> )
##
##  Let <A>q</A>, <A>n</A>, <A>e</A> be positive integers such that <A>e</A>
##  divides <A>q</A><C>^</C><A>n</A> - 1.
##  This function returns the Loewy length of the Singer algebra
##  <M>A( </M><A>q</A><M>, </M><A>n</A><M>, </M><A>e</A><M> )</M>,
##  see <Ref Func="SingerAlgebra"/>.
##  <P/>
##  Alternatively, also a Singer algebra <A>A</A> can be given
##  as an ergument.
##  <P/>
##  Note that it may be cheap to compute the Loewy length of this algebra,
##  depending on the defining parameters, even if computing its Loewy vector
##  (see <Ref Attr="DimensionsLoewyFactors"/>) would be hard.
##
DeclareAttribute( "LoewyLength", IsSingerAlgebra );

DeclareOperation( "LoewyLength", [ IsPosInt, IsPosInt, IsPosInt ] );


#############################################################################
##
#A  MinimalDegreeOfSingerAlgebra( <A> )
#O  MinimalDegreeOfSingerAlgebra( <q>, <e> )
##
##  For two coprime positive integers <A>q</A> and <A>e</A>,
##  this function computes the minimal number of powers of <q> such that
##  <e> divides the sum of these powers.
##  <P/>
##  If a Singer algebra <M>A(q, n, e)</M> is given as the argument <A>A</A>
##  (see <Ref Func="SingerAlgebra"/>) then the value for the parameters
##  <M>q</M> and <M>e</M> is returned;
##  note that the minimal degree does not depend on <M>n</M>.
##
DeclareAttribute( "MinimalDegreeOfSingerAlgebra", IsSingerAlgebra );

DeclareOperation( "MinimalDegreeOfSingerAlgebra", [ IsPosInt, IsPosInt ] );


#############################################################################
##
#F  SingerAlgebra( <q>, <n>, <e>[, <R>] )
##
##  For nonnegative integers <A>q</A>, <A>n</A>, <A>e</A>
##  with <A>q</A><M> \gt 2</M>,
##  and a field <A>R</M> (which defaults to the field of Rationals),
##  let <M>z = (<A>q</A>^{<A>n</A>} - 1) / <A>e</A></M>
##  and define <M>A(<A>q</A>, <A>n</A>, <A>e</A>)</M> as the free
##  <A>R</A>-module with basis <M>(b_0, b_1, \ldots, b_z)</M>
##  and multiplication defined as follows.
##  If there is no carry in the addition of the <A>q</A>-adic expansions of
##  <M>i</M> and <M>j</M> then <M>b_i b_j = b_{{i+j}}</M> holds,
##  and otherwise <M>b_i b_j</M> is zero.
##  <P/>
##  This function returns the algebra <M>A(<A>q</A>, <A>n</A>, <A>e</A>)</M>.
##  <P/>
##  The idea is to use the algebra object first of all as a container for the
##  Loewy data that belong to the parameters <A>q</q>, <A>n</A>, <A>e</A>.
##  This works well also for high dimensional algebras.
##  <P/>
##  If one really wants to do computations beyond this context,
##  for example compute with elements of the algebra,
##  then special methods for <Ref Oper="CanonicalBasis" BookName="ref"/>,
##  <Ref Oper="Representative" BookName="ref"/>,
##  <Ref Oper="GeneratorsOfAlgebra" BookName="ref"/>, or
##  <Ref Oper="GeneratorsOfAlgebraWithOne" BookName="ref"/> will trigger
##  the computation of a structure constants table,
##  and afterwards the algebra behaves like other algebras in &GAP;
##  that are defined via structure constants.
##
DeclareGlobalFunction( "SingerAlgebra" );

