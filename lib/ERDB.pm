package ERDB;

#
# This is a SAS component
#

    use strict;
    use base qw(Exporter);
    use vars qw(@EXPORT_OK);
    @EXPORT_OK = qw(encode);
    use Tracer;
    use Data::Dumper;
    use XML::Simple;
    use ERDBQuery;
    use ERDBObject;
    use Stats;
    use Time::HiRes qw(gettimeofday);
    use Digest::MD5 qw(md5_base64);
    use CGI qw(-nosticky);

    use ERDBExtras;
    use FreezeThaw;

=head1 Entity-Relationship Database Package

=head2 Introduction

The Entity-Relationship Database Package allows the client to create an
easily-configurable database of Entities connected by Relationships. Each entity
is represented by one or more relations in an underlying SQL database. Each
relationship is represented by a single relation that connects two entities.
Entities and relationships are collectively referred to in the documentation as
I<objects>.

Although this package is designed for general use, most examples are derived
from the world of bioinformatics, which is where this technology was first
deployed.

Each entity has at least one relation, the I<primary relation>, that has the
same name as the entity. The primary relation contains a field named C<id> that
contains the unique identifier of each entity instance. An entity may have
additional relations that contain fields which are optional or can occur more
than once. For example, the C<Feature> entity has a B<feature-type> attribute
that occurs exactly once for each feature. This attribute is implemented by a
C<feature_type> column in the primary relation C<Feature>. In addition, however,
a feature may have zero or more aliases. These are implemented using a
C<FeatureAlias> relation that contains two fields-- the feature ID (C<id>) and
the alias name (C<alias>). The C<Feature> entity also contains an optional
virulence number. This is implemented as a separate relation C<FeatureVirulence>
which contains an ID (C<id>) and a virulence number (C<virulence>). If the
virulence of a feature I<ABC> is known to be 6, there will be one row in the
C<FeatureVirulence> relation possessing the value I<ABC> as its ID and 6 as its
virulence number. If the virulence of I<ABC> is not known, there will not be any
rows for it in C<FeatureVirulence>.

Entities are connected by binary relationships implemented using single
relations possessing the same name as the relationship itself and that has an
1-to-many (C<1M>) or many-to-many (C<MM>). Each relationship's relation contains
a C<from-link> field that contains the ID of the source entity and a C<to-link>
field that contains the ID of the target entity. The name of the relationship is
generally a verb phrase with the source entity as the subject and the target
entity as the object. So, for example, the B<ComesFrom> relationship connects
the C<Genome> and C<Source> entities, and indicates that a particular source
organization participated in the mapping of the genome. A source organization
frequently participates in the mapping of many genomes, and many source
organizations can cooperate in the mapping of a single genome, so this
relationship has an arity of many-to-many (C<MM>). The relation that implements
the C<ComesFrom> relationship is called C<ComesFrom> and contains two fields--
C<from-link>, which contains a genome ID, and C<to-link>, which contains a
source ID.

A relationship may itself have attributes. These attributes, known as
I<intersection data attributes>, are implemented as additional fields in the
relationship's relation. So, for example, the B<IsMadeUpOf> relationship
connects the B<Contig> entity to the B<Sequence> entity, and is used to
determine which sequences make up a contig. The relationship has as an attribute
the B<start-position>, which indicates where in the contig that the sequence
begins. This attribute is implemented as the C<start_position> field in the
C<IsMadeUpOf> relation.

The database itself is described by an XML file. In addition to all the data
required to define the entities, relationships, and attributes, the schema
provides space for notes describing the data and what it means and information
about how to display a diagram of the database. These are used to create web
pages describing the data.

Special support is provided for text searching. An entity field can be marked as
I<searchable>, in which case it will be used to generate a text search
index in which the user searches for words in the field instead of a particular
field value.

=head2 Loading

Considerable support is provided for loading a database from flat files. The
flat files are in the standard format expected by the MySQL C<LOAD DATA INFILE>
command. This command expects each line to represent a database record and
each record to have all the fields specified, in order, with tab characters
separating the fields.

The L<ERDBLoadGroup> object can be subclassed and used to create load files
that can then be loaded using the L<ERDBLoader.pl> command; however, there
is no requirement that this be done.

=head3 Constructors

In order to use the load facility, the constructor for the database object
must be able to function with no parameters or with the parameters construed
as a hash. The following options are used by the ERDB load facility. It is
not necessary to support them all.

=over 4

=item DBD

XML database definition file.

=item dbName

Name of the database to use.

=item sock

Socket for accessing the database.

=item userData

Name and password used to log on to the database, separated by a slash.

=item dbhost

Database host name.

=back

=head2 Data Types, Queries and Filtering

=head3 Data Types

The ERDB system supports many different data types. It is possible to
configure additional user-defined types by adding PERL modules to the
code. Each new type must be a subclass of L<ERDBType>. Standard
types are listed in the compile-time STANDARD_TYPES constant. Custom
types should be listed in the C<$ERDBExtras::customERDBtypes> variable
of the configuration file. The variable must be a list reference
containing the names of the ERDBType subclasses for the custom
types.

To get complete documentation of all the types, use
the L</ShowDataTypes> method. The most common types are

=over 4

=item int

Signed whole number with a range of roughly negative 2 billion to positive
2 billion. Integers are stored in the database as a 32-bit binary number.

=item string

Variable-length string, up to around 250 characters. Strings are stored in
the database as variable-length ASCII with some escaping.

=item text

Variable-length string, up to around 65000 characters. Text is stored in the
database as variable-length ASCII with some escaping. Only the first 250
characters can be indexed.

=item float

Double-precision floating-point number, ranging from roughly -10^-300
to 10^-300, with around 14 significant digits. Floating-point numbers
are stored in the database in IEEE 8-byte floating-point format.

=item date

Date/time value, in whole seconds. Dates are stored as a number of seconds
from the beginning of the Unix epoch (January 1, 1970) in Universal
Coordinated Time. This makes it identical to a date or time number in PERL,
Unix, or Windows.

=back

All data fields are converted when stored or retrieved using the
L</EncodeField> and L</DecodeField> methods. This allows us to store
very exotic data values such as string lists, images, and PERL objects. The
conversion is not, however, completely transparent because no conversion
is performed on the parameter values for the various L</Get>-based queries.
There is a good reason for this: you can specify general SQL expressions as
filters, and it's extremely difficult for ERDB to determine the data type of
a particular parameter. This topic is dealt with in more detail below.

=head3 Standard Field Name Format

There are several places in which field names are specified by the caller.
The standard field name format is the name of the entity or relationship
followed by the field name in parentheses. In some cases there a particular
entity or relationship is considered the default. Fields in the default
object can be specified as an unmodified field name. For example,

    Feature(species-name)

would specify the species name field for the C<Feature> entity. If the
C<Feature> table were the default, it could be specified as

    species-name

without the object name. You may also use underscores in place of hyphens,
which can be syntactically more convenient in PERL programs.

    species_name

In some cases, the object name may not be the actual name of an object
in the database. It could be an alias assigned by a query, or the converse
name of a relationship. Alias names and converse names are generally
specified in the object name list of a query method. The alias or converse
name used in the query method will be carried over in all parameters to the
method and any data value structures returned by the query. In most cases,
once you decide on a name for something in a query, the name will stick for
all data returned by the query.

=head3 Queries

Queries against the database are performed by variations of the L</Get> method.
This method has three parameters: the I<object name list>, the I<filter clause>,
and the I<parameter list>. There is a certain complexity involved in queries
that has evolved over a period of many years in which the needs of the
applications were balanced against a need for simplicity. In most cases, you
just list the objects used in the query, code a standard SQL filter clause with
field names in the L</Standard Field Name Format>, and specify a list of
parameters to plug in to the parameter marks. The use of the special field name
format and the list of object names spare you the pain of writing a C<FROM>
clause and worrying about joins. For example, here's a simple query to look up
all Features for a particular genome.

    my $query = $erdb->Get('Genome HasFeature Feature', 'Genome(id) = ?', [$genomeID]);

For more complicated queries, see the rest of this section.

=head4 Object Name List

The I<object name list> specifies the names of the entities and relationships
that participate in the query. This includes every object used to filter the
query as well as every object from which data is expected. The ERDB engine will
automatically generate the join clauses required to make the query work, which
greatly simplifies the coding of the query. You can specify the object name
list using a list reference or a space-delimited string. The following two
calls are equivalent.

    my $query = $erdb->Get(['Genome', 'UsesImage', 'Image'], $filter, \@parms);

    my $query = $erdb->Get('Genome UsesImage Image', $filter, \@parms);

If you specify a string, you have a few more options.

=over 4

=item *

You can use the keyword C<AND> to start a new join chain with an object
further back in the list.

=item *

You can specify an object name more than once. If it is intended to
be a different instance of the same object, simply put a number at the
end. Each distinct number indicates a distinct instance.

=item *

You can use the converse name of a relationship to make the object name list
read more like regular English.

=back

These requirements do not come up very often, but they can make a big differance.

For example, let us say you are looking for a feature that has a role in a
particular subsystem and also belongs to a particular genome. You can't use

    my $query = $erdb->Get(['Feature', 'HasRoleInSubsystem', 'Subsystem', 'HasFeature', 'Genome'], $filter, \@parms);

because you don't want to join the C<HasFeature> table to the subsystem table.
Instead, you use

    my $query = $erdb->Get("Feature HasRoleInSubsystem Subsystem AND Feature HasFeature Genome", $filter, \@parms);

Now consider a taxonomy hierarchy using the entity C<Class> and the
relationship C<BelongsTo> and say you want to find all subclasses of a
particular class. If you code

    my $query = $erdb->Get("Class BelongsTo Class", 'Class(id) = ?', [$class])

Then the query will only return the particular class, and only if it belongs
to itself. The following query finds every class that belongs to a particular
class.

    my $query = $erdb->Get("Class BelongsTo Class2", 'Class2(id) = ?', [$class]);

This query does the converse. It finds every class belonging to a particular class.

    my $query = $erdb->Get("Class BelongsTo Class2", 'Class(id) = ?', [$class]);

The difference is indicated by the field name used in the filter clause. Because
the first occurrence of C<Class> is specified in the filter rather than the
second occurrence (C<Class2>), the query is anchored on the from-side of the
relationship.

=head4 Filter Clause

The filter clause is an SQL WHERE clause (without the WHERE) to be used to filter
and sort the query. The WHERE clause can be parameterized with parameter markers
(C<?>). Each field used in the WHERE clause must be specified in
L</Standard Field Name Format>. Any parameters specified in the filter clause should
be added to the parameter list as additional parameters. The fields in a filter
clause can come from primary entity relations, relationship relations, or
secondary entity relations; however, all of the entities and relationships
involved must be included in the list of object names on the query. There is
never a default object name for filter clause fields.

The filter clause can also specify a sort order. To do this, simply follow
the filter string with an ORDER BY clause. For example, the following filter
string gets all genomes for a particular genus and sorts them by species name.

    "Genome(genus) = ? ORDER BY Genome(species)"

Note that the case is important. Only an uppercase "ORDER BY" with a single
space will be processed. The idea is to make it less likely to find the verb by
accident.

The rules for field references in a sort order are the same as those for field
references in the filter clause in general; however, unpredictable things may
happen if a sort field is from an entity's secondary relation.

Finally, you can limit the number of rows returned by adding a LIMIT clause. The
LIMIT must be the last thing in the filter clause, and it contains only the word
"LIMIT" followed by a positive number. So, for example

    "Genome(genus) = ? ORDER BY Genome(species) LIMIT 10"

will only return the first ten genomes for the specified genus. The ORDER BY
clause is not required. For example, to just get the first 10 genomes in the
B<Genome> table, you could use

    "LIMIT 10"

as your filter clause.

=head4 Parameter List

The parameter list is a reference to a list of parameter values. The parameter
values are substituted for the parameter marks in the filter clause in strict
left-to-right order.

In the parameter list for a filter clause, you must be aware of the proper
data types and perform any necessary conversions manually. This is not normally
a problem. Most of the time, you only query against simple numeric or string
fields, and you only need to convert a string if there's a possibility it has
exotic characters like tabs or new-lines in it. Sometimes, however, this is not
enough.

When you are writing programs to query ERDB databases, you can call
L</EncodeField> directly, specifying a field name in the
L</Standard Field Name Format>. The value will be converted as if it
was being stored into a field of the specified type. Alternatively, you
can call L</encode>, specifying a data type name. Both of these techniques
are shown in the example below.

    my $query = $erdb->Get("Genome UsesImage Image",
                           "Image(png) = ? AND Genome(description) = ?",
                           [$erdb->EncodeFIeld('Image(png)', $myImage),
                            ERDB::encode(text => $myDescription)]);

You can export the L</encode> method if you expect to be doing this a lot
and don't want to bother with the package name on the call.

    use ERDB qw(encode);

    # ... much later ...

    my $query = $erdb->Get("Genome UsesImage Image",
                           "Image(png) = ? AND Genome(description) = ?",
                           [$erdb->EncodeField('Image(png)', $myImage),
                            encode(text => $myDescription)]);

=head2 XML Database Description

=head3 Global Tags

The entire database definition must be inside a B<Database> tag. The display
name of the database is given by the text associated with the B<Title> tag. The
display name is only used in the automated documentation. The entities and
relationships are listed inside the B<Entities> and B<Relationships> tags,
respectively. There is also a C<Shapes> tag that contains additional shapes to
display on the database diagram, and an C<Issues> tag that describes general
things that need to be remembered. These last two are completely optional.

    <Database>
        <Title>... display title here...</Title>
        <Issues>
            ... comments here ...
        </Issues>
        <Regions>
            ... region definitions here ...
        </Regions>
        <Entities>
            ... entity definitions here ...
        </Entities>
        <Relationships>
            ... relationship definitions here ...
        </Relationships>
        <Shapes>
           ... shape definitions here ...
        </Shapes>
    </Database>

=head3 Notes and Asides

Entities, relationships, shapes, indexes, and fields all allow text tags called
B<Notes> and B<Asides>. Both these tags contain comments that appear when the
database documentation is generated. In addition, the text inside the B<Notes>
tag will be shown as a tooltip when mousing over the diagram.

The following special codes allow a limited rich text capability in Notes and
Asides.

[b]...[/b]: Bold text

[i]...[/i]: Italics

[p]...[/p]: Paragraph

[link I<href>]...[/link]: Hyperlink to the URL I<href>

[list]...[*]...[*]...[/list]: Bullet list, with B<[*]> separating list elements.

=head3 Fields

Both entities and relationships have fields described by B<Field> tags. A
B<Field> tag can have B<Notes> associated with it. The complete set of B<Field>
tags for an object mus be inside B<Fields> tags.

    <Entity ... >
        <Fields>
            ... Field tags ...
        </Fields>
    </Entity>

The attributes for the B<Field> tag are as follows.

=over 4

=item name

Name of the field. The field name should contain only letters, digits, and
hyphens (C<->), and the first character should be a letter. Most underlying
databases are case-insensitive with the respect to field names, so a best
practice is to use lower-case letters only. Finally, the name
C<search-relevance> has special meaning for full-text searches and should not be
used as a field name.

=item type

Data type of the field.

=item relation

Name of the relation containing the field. This should only be specified for
entity fields. The ERDB system does not support optional fields or
multi-occurring fields in the primary relation of an entity. Instead, they are
put into secondary relations. So, for example, in the C<Genome> entity, the
C<group-name> field indicates a special grouping used to select a subset of the
genomes. A given genome may not be in any groups or may be in multiple groups.
Therefore, C<group-name> specifies a relation value. The relation name specified
must be a valid table name. By convention, it is usually the entity name
followed by a qualifying word (e.g. C<GenomeGroup>). In an entity, the fields
without a relation attribute are said to belong to the I<primary relation>. This
relation has the same name as the entity itself.

=item searchable

If specified, then the field is a candidate for full-text searching. A single
full-text index will be created for each relation with at least one searchable
field in it. For best results, this option should only be used for string or
text fields.

=item special

This attribute allows the subclass to assign special meaning for certain fields.
The interpretation is up to the subclass itself. Currently, only entity fields
can have this attribute.

=item default

This attribute specifies the default field value to be used while loading. The
default value is used if no value is specified in an L</InsertObject> call or in
the L<ERDBLoadGroup/Put> call that generates the load file. If no default is
specified, then the field is required and must have a value specified in the
call.

The default value is specified as a string, so it must be in an encoded
form.

=item null

If C<1>, this attribute indicates that the field can have a null value. The
default is C<0>.

=back

=head3 Indexes

An entity can have multiple alternate indexes associated with it. The fields in
an index must all be from the same relation. The alternate indexes assist in
searching on fields other than the entity ID. A relationship has at least two
indexes-- a I<to-index> and a I<from-index> that order the results when crossing
the relationship. For example, in the relationship C<HasContig> from C<Genome>
to C<Contig>, the from-index would order the contigs of a ganome, and the
to-index would order the genomes of a contig. In addition, it can have zero or
more alternate indexes. A relationship's index can only specify fields in the
relationship.

The alternate indexes for an entity or relationship are listed inside the
B<Indexes> tag. The from-index of a relationship is specified using the
B<FromIndex> tag; the to-index is specified using the B<ToIndex> tag.

Be aware of the fact that in some versions of MySQL, the maximum size of an
index key is 1000 bytes. This means at most four normal-sized strings.

The B<Index> tag has one optional attribute.

=over 4

=item unique

If C<1>, then the index is unique. The default is C<0> (a non-unique index).

=back

Each index can contain a B<Notes> tag. In addition, it will have an
B<IndexFields> tag containing the B<IndexField> tags. The B<IndexField>
tags specify, in order, the fields used in the index. The attributes of an
B<IndexField> tag are as follows.

=over 4

=item name

Name of the field.

=item order

Sort order of the field-- C<ascending> or C<descending>.

=back

The B<FromIndex>, B<ToIndex> and B<Index> tags can have a B<unique> attribute. 
If specified, the index will be generated as a unique index. The B<ToIndex>
for a one-to-many relationship is always unique.

=head3 Regions

A large database may be too big to fit comfortably on a single page. When this
happens, you have the option of dividing the diagram into regions that are shown
one at a time. When regions are present, a combo box will appear on the diagram
allowing the user to select which region to show. Each entity, relationship, or
shape can have multiple B<RegionInfo> tags describing how it should be displayed
when a particular region is selected. The regions themselves are described by
a B<Region> tag with a single attribute-- B<name>-- that indicates the region
name. The tag can be empty, or can contain C<Notes> elements that provide useful
documentation.

=over 4

=item name

Name of the region.

=back

=head3 Diagram

The diagram tag allows you to specify options for generating a diagram. If the
tag is present, then it will be used to configure diagram display in the
documentation widget (see L<ERDBPDocPage>). the tag has the following
attributes. It should not have any content; that is, it is not a container
tag.

=over 4

=item width

Width for the diagram, in pixels. The default is 750.

=item height

Height for the diagram, in pixels. The default is 800.

=item ratio

Ratio of shape height to width. The default is 0.62.

=item size

Width in pixels for each shape.

=item nonoise

If set to 1, there will be a white background instead of an NMPDR noise background.

=item editable

If set to 1, a dropdown box and buttons will appear that allow you to edit the diagram,
download your changes, and make it pretty for printing.

=item fontSize

Maximum font size to use, in points. The default is 16.

=item download

URL of the CGI script that downloads the diagram XML to the user's computer. The XML text
will be sent via the C<data> parameter and the default file name via the C<name>
parameter.

=item margin

Margin between adjacent shapes, in pixels. The default is 10.

=back

=head3 DisplayInfo

The B<DisplayInfo> tag is used to describe how an entity, relationship, or shape
should be displayed when the XML file is used to generate an interactive
diagram. A B<DisplayInfo> can have no elements, or it can have multiple
B<Region> elements inside. The permissible attributes are as follows.

=over 4

=item link

URL to which the user should be sent when clicking on the shape. For entities
and relationships, this defaults to the most likely location for the object
description in the generated documentation.

=item theme

The themes are C<black>, C<blue>, C<brown>, C<cyan>, C<gray>, C<green>,
C<ivory>, C<navy>, C<purple>, C<red>, and C<violet>. These indicate the color to
be used for the displayed object. The default is C<gray>.

=item col

The number of the column in which the object should be displayed. Fractional
column numbers are legal, though it's best to round to a multiple of 0.5. Thus,
a column of C<4.5> would be centered between columns 4 and 5.

=item row

The number of the row in which the object should be displayed. Fractional row
numbers are allowed in the same manner as for columns.

=item connected

If C<1>, the object is visibly connected by lines to the other objects
identified in the C<from> and C<to> attributes. This value is ignored for
entities, which never have C<from> or C<to>.

=item caption

Caption to be displayed on the object. If omitted, it defaults to the object's
name. You may use spaces and C<\n> codes to make the caption prettier.

=item fixed

If C<1>, then the C<row> and C<col> attributes are used to position the
object, even if it has C<from> and C<to> attributes. Otherwise, the object is
placed in the midpoint between the C<from> and C<to> shapes.

=back

=head3 RegionInfo

For large diagrams, the B<DisplayInfo> tag may have one or more B<RegionInfo>
elements inside, each belonging to one or more named regions. (The named regions
are desribed by the B<Region> tag.) The diagrammer will create a drop-down box
that can be used to choose which region should be displayed. Each region tag has
a C<name> attribute indicating the region to which it belongs, plus any of the
attributes allowed on the B<DisplayInfo> tag. The name indicates the name of a
region in which the parent object should be displayed. The other attributes
override the corresponding attributes in the B<DisplayInfo> parent. An object
with no Region tags present will be displayed in all regions. There is a default
region with no name that consists only of objects displayed in all regions. An
object with no B<DisplayInfo> tag at all will not be displayed in any region.

=head3 Object and Field Names

By convention entity and relationship names use capital casing (e.g. C<Genome>
or C<HasRegionsIn>. Most underlying databases, however, are aggressively
case-insensitive with respect to relation names, converting them internally to
all-upper case or all-lower case.

If syntax or parsing errors occur when you try to load or use an ERDB database,
the most likely reason is that one of your objects has an SQL reserved word as
its name. The list of SQL reserved words keeps increasing; however, most are
unlikely to show up as a noun or declarative verb phrase. The exceptions are
C<Group>, C<User>, C<Table>, C<Index>, C<Object>, C<Date>, C<Number>, C<Update>,
C<Time>, C<Percent>, C<Memo>, C<Order>, and C<Sum>. This problem can crop up in
field names as well.

Every entity has a field called C<id> that acts as its primary key. Every
relationship has fields called C<from-link> and C<to-link> that contain copies
of the relevant entity IDs. These are essentially ERDB's reserved words, and
should not be used for user-defined field names.

=head3 Issues

Issues are comments displayed at the top of the database documentation. They
have no effect on the database or the diagram. The C<Issue> tag is a text tag
with no attributes.

=head3 Entities

An entity is described by the B<Entity> tag. The entity can contain B<Notes> and
B<Asides>, an optional B<DisplayInfo> tag, an B<Indexes> tag containing one or
more secondary indexes, and a B<Fields> tag containing one or more fields. The
attributes of the B<Entity> tag are as follows.

=over 4

=item name

Name of the entity. The entity name, by convention, uses capital casing (e.g.
C<Genome> or C<GroupBlock>) and should be a noun or noun phrase.

=item keyType

Data type of the primary key. The primary key is always named C<id>.

=item autonumber

A value of C<1> means that after the entity's primary relation is loaded, the ID
field will be set to autonumber, so that new records inserted will have
automatic keys generated. Use this option with care. Once the relation is loaded,
it cannot be reloaded unless the table is first dropped and re-created. In addition,
the key must be an integer type.

=back

=head3 Relationships

A relationship is described by the B<Relationship> tag. Within a relationship,
there can be B<DisplayInfo>, B<Notes> and B<Asides> tags, a B<Fields> tag
containing the intersection data fields, a B<FromIndex> tag containing the
index used to cross the relationship in the forward direction, a B<ToIndex> tag
containing the index used to cross the relationship in reverse, and an
C<Indexes> tag containing the alternate indexes.

The B<Relationship> tag has the following attributes.

=over 4

=item name

Name of the relationship. The relationship name, by convention, uses capital
casing (e.g. C<ContainsRegionIn> or C<HasContig>), and should be a declarative
verb phrase, designed to fit between the from-entity and the to-entity (e.g.
Block C<ContainsRegionIn> Genome).

=item from

Name of the entity from which the relationship starts.

=item to

Name of the entity to which the relationship proceeds.

=item arity

Relationship type: C<1M> for one-to-many and C<MM> for many-to-many.

=item converse

A name to be used when travelling backward through the relationship. This
value can be used in place of the real relationship name to make queries
more readable.

=item loose

If TRUE (C<1>), then deletion of an entity instance on the B<from> side
will NOT cause deletion of the connected entity instances on the B<to>
side. All many-to-many relationships are automatically loose. A one-to-many
relationship is generally not loose, but specifying this attribute can make
it so.

=back

=head3 Shapes

Shapes are objects drawn on the database diagram that do not physically exist
in the database. Entities are always drawn as rectangles and relationships are
always drawn as diamonds, but a shape can be either of those, an arrow, a
bidirectional arrow, or an oval. The B<Shape> tag can contain B<Notes>,
B<Asides>, and B<DisplayInfo> tags, and has the
following attributes.

=over 4

=item type

Type of shape: C<arrow> for an arrow, C<biarrow> for a bidirectional arrow,
C<oval> for an ellipse, C<diamond> for a diamond, and C<rectangle> for a
rectangle.

=item from

Object from which this object is oriented. If the shape is an arrow, it
will point toward the from-object.

=item to

Object toward which this object is oriented. If the shape is an arrow, it
will point away from the to-object.

=item name

Name of the shape. This is used by other shapes to identify it in C<from>
and C<to> directives.

=back

=cut

# GLOBALS

# Table of information about our datatypes.
my $TypeTable;

my @StandardTypes = qw(ERDBTypeBoolean ERDBTypeChar ERDBTypeCounter ERDBTypeDate
                       ERDBTypeFloat ERDBTypeHashString ERDBTypeInteger ERDBTypeString
                       ERDBTypeText);

# Table translating arities into natural language.
my %ArityTable = ( '1M' => 'one-to-many',
                   'MM' => 'many-to-many'
                 );

# Options for XML input and output.

my %XmlOptions = (GroupTags =>  { Relationships => 'Relationship',
                                  Entities => 'Entity',
                                  Fields => 'Field',
                                  Indexes => 'Index',
                                  IndexFields => 'IndexField',
                                  Issues => 'Issue',
                                  Regions => 'Region',
                                  Shapes => 'Shape'
                                },
                  KeyAttr =>    { Relationship => 'name',
                                  Entity => 'name',
                                  Field => 'name',
                                  Shape => 'name'
                                },
                  SuppressEmpty => 1,
                 );

my %XmlInOpts  = (
                  ForceArray => [qw(Field Index Issues IndexField Relationship Entity Shape)],
                  ForceContent => 1,
                  NormalizeSpace => 2,
                 );
my %XmlOutOpts = (
                  RootName => 'Database',
                  XMLDecl => 1,
                 );

# Table for flipping between FROM and TO
my %FromTo = (from => 'to', to => 'from');

# Name of metadata table.
use constant METADATA_TABLE => '_metadata';

=head2 Special Methods

=head3 new

    my $database = ERDB->new($dbh, $metaFileName, %options);

Create a new ERDB object.

=over 4

=item dbh

L<DBKernel> database object for the target database.

=item metaFileName

Name of the XML file containing the metadata.

=item options

Hash of configuration options.

=back

The supported configuration options are as follows. Options not in this list
will be presumed to be relevant to the subclass and will be ignored.

=over 4

=item demandDriven

If TRUE, the database will be configured for a I<forward-only cursor>. Instead
of caching the query results, the query results will be provided at the rate
in which they are demanded by the client application. This is less stressful
on memory and disk space, but means you cannot have more than one query active
at the same time.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $dbh, $metaFileName, %options) = @_;
    # Insure we have a type table.
    GetDataTypes();
    # See if we want to use demand-driven flow control for queries.
    if ($options{demandDriven}) {
        $dbh->set_demand_driven(1);
    }
    # Get the quote character.
    my $quote = "";
    if (defined $dbh) {
        $quote = $dbh->quote;
    }
    # Create the object.
    my $self = { _dbh => $dbh,
                 _metaFileName => $metaFileName,
                 _autonumbered => {},
                 _quote => $quote
               };
    # Bless it.
    bless $self, $class;
    # Check for a load directory.
    if ($options{loadDirectory}) {
        $self->{loadDirectory} = $options{loadDirectory};
    }
    # Load the meta-data. (We must be blessed before doing this, because it
    # involves a virtual method.)
    $self->{_metaData} = _LoadMetaData($self, $metaFileName, $options{externalDBD});
    # Return the object.
    return $self;
}

=head3 SplitKeywords

    my @keywords = ERDB::SplitKeywords($keywordString);

This method returns a list of the positive keywords in the specified
keyword string. All of the operators will have been stripped off,
and if the keyword is preceded by a minus operator (C<->), it will
not be in the list returned. The idea here is to get a list of the
keywords the user wants to see. The list will be processed to remove
duplicates.

It is possible to create a string that confuses this method. For example

    frog toad -frog

would return both C<frog> and C<toad>. If this is a problem we can deal
with it later.

=over 4

=item keywordString

The keyword string to be parsed.

=item RETURN

Returns a list of the words in the keyword string the user wants to
see.

=back

=cut

sub SplitKeywords {
    # Get the parameters.
    my ($keywordString) = @_;
    # Make a safety copy of the string. (This helps during debugging.)
    my $workString = $keywordString;
    # Convert operators we don't care about to spaces.
    $workString =~ tr/+"()<>/ /;
    # Split the rest of the string along space boundaries. Note that we
    # eliminate any words that are zero length or begin with a minus sign.
    my @wordList = grep { $_ && substr($_, 0, 1) ne "-" } split /\s+/, $workString;
    # Use a hash to remove duplicates.
    my %words = map { $_ => 1 } @wordList;
    # Return the result.
    return sort keys %words;
}

=head3 GetDatabase

    my $erdb = ERDB::GetDatabase($name, $dbd, %parms);

Return an ERDB object for the named database. It is assumed that the
database name is also the name of a class for connecting to it.

=over 4

=item name

Name of the desired database.

=item dbd

Alternate DBD file to use when processing the database definition.

=item parms

Additional command-line parameters.

=item RETURN

Returns an ERDB object for the named database.

=back

=cut

sub GetDatabase {
    # Get the parameters.
    my ($name, $dbd, %parms) = @_;
    # Get access to the database's package.
    require "$name.pm";
    # Plug in the DBD parameter (if any).
    if (defined $dbd) {
        $parms{DBD} = $dbd;
    }
    # Construct the desired object.
    my $retVal = eval("$name->new(%parms)");
    # Fail if we didn't get it.
    Confess("Error connecting to database \"$name\": $@") if $@;
    # Return the result.
    return $retVal;
}

=head3 ParseFieldName

    my ($tableName, $fieldName) = ERDB::ParseFieldName($string, $defaultName);

or

    my $normalizedName = ERDB::ParseFieldName($string, $defaultName);


Analyze a standard field name to separate the object name part from the
field part.

=over 4

=item string

Standard field name string to be parsed.

=item defaultName (optional)

Default object name to be used if the object name is not specified in the
input string.

=item RETURN

In list context, returns the table name followed by the base field name. In
scalar context, returns the field name in a normalized L</Standard Field Name Format>,
with underscores converted to hyphens and an object name present. If the
parse fails, will return an undefined value.

=back

=cut

sub ParseFieldName {
    # Get the parameters.
    my ($string, $defaultName) = @_;
    # Declare the return values.
    my ($tableName, $fieldName);
    # Get a copy of the input string with underscores converted to hyphens.
    my $realString = $string;
    $realString =~ tr/_/-/;
    # Parse the input string.
    if ($realString =~ /^(\w+)\(([\w\-]+)\)$/) {
        # It's a standard name. Return the pieces.
        ($tableName, $fieldName) = ($1, $2);
    } elsif ($realString =~ /^[\w\-]+$/ && defined $defaultName) {
        # It's a plain name, and we have a default table name.
        ($tableName, $fieldName) = ($defaultName, $realString);
    }
    # Return the results.
    if (wantarray()) {
        return ($tableName, $fieldName);
    } elsif (! defined $tableName) {
        return undef;
    } else {
        return "$tableName($fieldName)";
    }
}

=head3 CountParameterMarks

    my $count = ERDB::CountParameterMarks($filterString);

Return the number of parameter marks in the specified filter string.

=over 4

=item filterString

ERDB filter clause to examine.

=item RETURN

Returns the number of parameter marks in the specified filter clause.

=back

=cut

sub CountParameterMarks {
    # Get the parameters.
    my ($filterString) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Get a safety copy of the filter string.
    my $filterCopy = $filterString;
    # Remove all escaped quotes.
    $filterCopy =~ s/\\'//g;
    # Remove all quoted strings.
    $filterCopy =~ s/'[^']*'//g;
    # Count the question marks.
    while ($filterCopy =~ /\?/g) {
        $retVal++
    }
    # Return the result.
    return $retVal;
}


=head2 Query Methods

=head3 GetEntity

    my $entityObject = $erdb->GetEntity($entityType, $ID);

Return an object describing the entity instance with a specified ID.

=over 4

=item entityType

Entity type name.

=item ID

ID of the desired entity.

=item RETURN

Returns a L<ERDBObject> object representing the desired entity instance, or
an undefined value if no instance is found with the specified key.

=back

=cut

sub GetEntity {
    # Get the parameters.
    my ($self, $entityType, $ID) = @_;
    # Encode the ID value.
    my $coded = $self->EncodeField("$entityType(id)", $ID);
    # Create a query.
    my $query = $self->Get($entityType, "$entityType(id) = ?", [$coded]);
    # Get the first (and only) object.
    my $retVal = $query->Fetch();
    if (T(3)) {
        if ($retVal) {
            Trace("Entity $entityType \"$ID\" found.");
        } else {
            Trace("Entity $entityType \"$ID\" not found.");
        }
    }
    # Return the result.
    return $retVal;
}

=head3 GetChoices

    my @values = $erdb->GetChoices($entityName, $fieldName);

Return a list of all the values for the specified field that are represented in
the specified entity.

Note that if the field is not indexed, then this will be a very slow operation.

=over 4

=item entityName

Name of an entity in the database.

=item fieldName

Name of a field belonging to the entity in L</Standard Field Name Format>.

=item RETURN

Returns a list of the distinct values for the specified field in the database.

=back

=cut

sub GetChoices {
    # Get the parameters.
    my ($self, $entityName, $fieldName) = @_;
    # Get the entity data structure.
    my $entityData = $self->_GetStructure($entityName);
    # Get the field descriptor.
    my $fieldData = $self->_FindField($fieldName, $entityName);
    # Get the name of the relation containing the field.
    my $relation = $fieldData->{relation};
    # Fix up the field name.
    my $realName = _FixName($fieldData->{name});
    # Get the field type.
    my $type = $fieldData->{type};
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Query the database.
    my $results = $dbh->SQL("SELECT DISTINCT $self->{_quote}$realName$self->{_quote} FROM $self->{_quote}$relation$self->{_quote}");
    # Clean the results. They are stored as a list of lists,
    # and we just want the one list. Also, we want to decode the values.
    my @retVal = sort map { $TypeTable->{$type}->decode($_->[0]) } @{$results};
    # Return the result.
    return @retVal;
}

=head3 GetEntityValues

    my @values = $erdb->GetEntityValues($entityType, $ID, \@fields);

Return a list of values from a specified entity instance. If the entity instance
does not exist, an empty list is returned.

=over 4

=item entityType

Entity type name.

=item ID

ID of the desired entity.

=item fields

List of field names in L</Standard_Field_Name_Format>.

=item RETURN

Returns a flattened list of the values of the specified fields for the specified entity.

=back

=cut

sub GetEntityValues {
    # Get the parameters.
    my ($self, $entityType, $ID, $fields) = @_;
    # Get the specified entity.
    my $entity = $self->GetEntity($entityType, $ID);
    # Declare the return list.
    my @retVal = ();
    # If we found the entity, push the values into the return list.
    if ($entity) {
        push @retVal, $entity->Values($fields);
    }
    # Return the result.
    return @retVal;
}

=head3 GetAll

    my @list = $erdb->GetAll(\@objectNames, $filterClause, \@parameters, \@fields, $count);

Return a list of values taken from the objects returned by a query. The first
three parameters correspond to the parameters of the L</Get> method. The final
parameter is a list of the fields desired from each record found by the query
in L</Standard Field Name Format>. The default object name is the first one in the
object name list.

The list returned will be a list of lists. Each element of the list will contain
the values returned for the fields specified in the fourth parameter. If one of the
fields specified returns multiple values, they are flattened in with the rest. For
example, the following call will return a list of the features in a particular
spreadsheet cell, and each feature will be represented by a list containing the
feature ID followed by all of its essentiality determinations.

    @query = $erdb->Get('ContainsFeature Feature'], "ContainsFeature(from-link) = ?",
                        [$ssCellID], ['Feature(id)', 'Feature(essential)']);

=over 4

=item objectNames

List containing the names of the entity and relationship objects to be retrieved.
See L</Object Name List>.

=item filterClause

WHERE/ORDER BY clause (without the WHERE) to be used to filter and sort the query.
See L</Filter Clause>.

=item parameterList

List of the parameters to be substituted in for the parameters marks
in the filter clause. See L</Parameter List>.

=item fields

List of the fields to be returned in each element of the list returned, or a
string containing a space-delimited list of field names. The field names should
be in L</Standard Field Name Format>.

=item count

Maximum number of records to return. If omitted or 0, all available records will
be returned.

=item RETURN

Returns a list of list references. Each element of the return list contains the
values for the fields specified in the B<fields> parameter.

=back

=cut
#: Return Type @@;
sub GetAll {
    # Get the parameters.
    my ($self, $objectNames, $filterClause, $parameterList, $fields, $count) = @_;
    # Translate the parameters from a list reference to a list. If the parameter
    # list is a scalar we convert it into a singleton list.
    my @parmList = ();
    if (ref $parameterList eq "ARRAY") {
        Trace("GetAll parm list is an array.") if T(4);
        @parmList = @{$parameterList};
    } else {
        Trace("GetAll parm list is a scalar: $parameterList.") if T(4);
        push @parmList, $parameterList;
    }
    # Insure the counter has a value.
    if (!defined $count) {
        $count = 0;
    }
    # Add the row limit to the filter clause.
    if ($count > 0) {
        $filterClause .= " LIMIT $count";
    }
    # Create the query.
    my $query = $self->Get($objectNames, $filterClause, \@parmList);
    # Set up a counter of the number of records read.
    my $fetched = 0;
    # Convert the field names to a list if they came in as a string.
    my $fieldList = (ref $fields ? $fields : [split /\s+/, $fields]);
    # Loop through the records returned, extracting the fields. Note that if the
    # counter is non-zero, we stop when the number of records read hits the count.
    my @retVal = ();
    while (($count == 0 || $fetched < $count) && (my $row = $query->Fetch())) {
        my @rowData = $row->Values($fieldList);
        push @retVal, \@rowData;
        $fetched++;
    }
    # Return the resulting list.
    return @retVal;
}

=head3 Exists

    my $found = $erdb->Exists($entityName, $entityID);

Return TRUE if an entity exists, else FALSE.

=over 4

=item entityName

Name of the entity type (e.g. C<Feature>) relevant to the existence check.

=item entityID

ID of the entity instance whose existence is to be checked.

=item RETURN

Returns TRUE if the entity instance exists, else FALSE.

=back

=cut
#: Return Type $;
sub Exists {
    # Get the parameters.
    my ($self, $entityName, $entityID) = @_;
    # Check for the entity instance.
    Trace("Checking existence of $entityName with ID=$entityID.") if T(4);
    my $testInstance = $self->GetEntity($entityName, $entityID);
    # Return an existence indicator.
    my $retVal = ($testInstance ? 1 : 0);
    return $retVal;
}

=head3 GetCount

    my $count = $erdb->GetCount(\@objectNames, $filter, \@params);

Return the number of rows found by a specified query. This method would
normally be used to count the records in a single table. For example,

    my $count = $erdb->GetCount('Genome', 'Genome(genus-species) LIKE ?',
                                ['homo %']);

would return the number of genomes for the genus I<homo>. It is conceivable,
however, to use it to return records based on a join. For example,

    my $count = $erdb->GetCount('HasFeature Genome', 'Genome(genus-species) LIKE ?',
                                ['homo %']);

would return the number of features for genomes in the genus I<homo>. Note that
only the rows from the first table are counted. If the above command were

    my $count = $erdb->GetCount('Genome HasFeature', 'Genome(genus-species) LIKE ?',
                                ['homo %']);

it would return the number of genomes, not the number of genome/feature pairs.

=over 4

=item objectNames

Reference to a list of the objects (entities and relationships) included in the
query, or a string containing a space-delimited list of object names. See
L</ObjectNames>.

=item filter

A filter clause for restricting the query. See L</Filter Clause>.

=item params

Reference to a list of the parameter values to be substituted for the parameter
marks in the filter. See L</Parameter List>.

=item RETURN

Returns a count of the number of records in the first table that would satisfy
the query.

=back

=cut

sub GetCount {
    # Get the parameters.
    my ($self, $objectNames, $filter, $params) = @_;
    # Insure the params argument is an array reference if the caller left it
    # off.
    if (! defined($params)) {
        $params = [];
    }
    # Declare the return variable.
    my $retVal;
    # Create the SQL command suffix to get the desired records.
    my ($suffix, $mappedNameListRef, $mappedNameHashRef) =
        $self->_SetupSQL($objectNames, $filter);
    # Get the object we're counting.
    my $firstObject = $mappedNameListRef->[0];
    # Find out if we're counting an entity or a relationship.
    my $countedField;
    if ($self->IsEntity($mappedNameHashRef->{$firstObject}->[0])) {
        $countedField = "id";
    } else {
        # For a relationship we count the to-link because it's usually more
        # numerous. Note we're automatically converting to the SQL form
        # of the field name (to_link vs. to-link), and we're not worried
        # about converses.
        $countedField = "to_link";
    }
    # Prefix it with text telling it we want a record count.
    my $command = "SELECT COUNT($self->{_quote}$firstObject$self->{_quote}.$countedField) $suffix";
    # Prepare and execute the command.
    my $sth = $self->_GetStatementHandle($command, $params);
    # Get the count value.
    ($retVal) = $sth->fetchrow_array();
    # Check for a problem.
    if (! defined($retVal)) {
        if ($sth->err) {
            # Here we had an SQL error.
            Confess("Error retrieving row count: " . $sth->errstr());
        } else {
            # Here we have no result.
            Confess("No result attempting to retrieve row count.");
        }
    }
    # Return the result.
    return $retVal;
}

=head3 GetList

    my @dbObjects = $erdb->GetList(\@objectNames, $filterClause, \@params);

Return a list of L<ERDBObject> objects for the specified query.

This method is essentially the same as L</Get> except it returns a list of
objects rather than a query object that can be used to get the results one
record at a time. This is almost always preferable to L</Get> when the result
list is a manageable size.

=over 4

=item objectNames

Reference to a list containing the names of the entity and relationship objects
to be retrieved, or a string containing a space-delimited list of object names.
See L</Object Name List>.

=item filterClause

WHERE clause (without the WHERE) to be used to filter and sort the query. See
L</Filter Clause>.

=item params

Reference to a list of parameter values to be substituted into the filter clause.
See L</Parameter List>.

=item RETURN

Returns a list of L<ERDBObject> objects that satisfy the query conditions.

=back

=cut
#: Return Type @%
sub GetList {
    # Get the parameters.
    my ($self, $objectNames, $filterClause, $params) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Perform the query.
    my $query = $self->Get($objectNames, $filterClause, $params);
    # Loop through the results.
    while (my $object = $query->Fetch) {
        push @retVal, $object;
    }
    # Return the result.
    return @retVal;
}

=head3 Get

    my $query = $erdb->Get(\@objectNames, $filterClause, \@params);

This method returns a query object for entities of a specified type using a
specified filter.

=over 4

=item objectNames

List containing the names of the entity and relationship objects to be retrieved,
or a string containing a space-delimited list of names. See L</Object Name List>.

=item filterClause

WHERE clause (without the WHERE) to be used to filter and sort the query. See
L</Filter Clause>.

=item params

Reference to a list of parameter values to be substituted into the filter
clause. See L</Parameter List>.

=item RETURN

Returns an L</ERDBQuery> object that can be used to iterate through all of the
results.

=back

=cut

sub Get {
    # Get the parameters.
    my ($self, $objectNames, $filterClause, $params) = @_;
    # Process the SQL stuff.
    my ($suffix, $mappedNameListRef, $mappedNameHashRef) =
        $self->_SetupSQL($objectNames, $filterClause);
    # Create the query.
    my $command = "SELECT " . join(", ", map { "$self->{_quote}$_$self->{_quote}.*" } @$mappedNameListRef) .
        " $suffix";
    my $sth = $self->_GetStatementHandle($command, $params);
    # Now we create the relation map, which enables ERDBQuery to determine the
    # order, name and mapped name for each object in the query.
    my @relationMap = _RelationMap($mappedNameHashRef, $mappedNameListRef);
    # Return the statement object.
    my $retVal = ERDBQuery::_new($self, $sth, \@relationMap);
    return $retVal;
}

=head3 Prepare

    my $query = $erdb->Prepare($objects, $filterString, $parms);

Prepare a query for execution but do not create a statement handle. This
is useful if you have a query that you want to validate but you do not
yet want to acquire the resources to run it.

=over 4

=item objects

List containing the names of the entity and relationship objects to be retrieved,
or a string containing a space-delimited list of names. See L</Object Name List>.

=item filterString

WHERE clause (without the WHERE) to be used to filter and sort the query. See
L</Filter Clause>.

=item parms

Reference to a list of parameter values to be substituted into the filter
clause. See L</Parameter List>.

=item RETURN

Returns an L<ERDBQuery> object that can be used to check field names
or that can be populated with artificial data.

=back

=cut

sub Prepare {
    # Get the parameters.
    my ($self, $objects, $filterString, $parms) = @_;
    # Process the SQL stuff.
    my ($suffix, $mappedNameListRef, $mappedNameHashRef) =
        $self->_SetupSQL($objects, $filterString);
    # Create the query.
    my $command = "SELECT " . join(".*, ", @{$mappedNameListRef}) .
        ".* $suffix";
    # Now we create the relation map, which enables ERDBQuery to determine the
    # order, name and mapped name for each object in the query.
    my @relationMap = _RelationMap($mappedNameHashRef, $mappedNameListRef);
    # Create the query object without a statement handle.
    my $retVal = ERDBQuery::_new($self, undef, \@relationMap);
    # Cache the command and the parameters.
    $retVal->_Prepare($command, $parms);
    # Return the result.
    return $retVal;
}

=head3 Search

    my $query = $erdb->Search($searchExpression, $idx, \@objectNames, $filterClause, \@params);

Perform a full text search with filtering. The search will be against a
specified object in the object name list. That object will get an extra field
containing the search relevance. Note that except for the search expression, the
parameters of this method are the same as those for L</Get> and follow the same
rules.

=over 4

=item searchExpression

Boolean search expression for the text fields of the target object. The default
mode for a Boolean search expression is OR, but we want the default to be AND,
so we will add a C<+> operator to each word with no other operator before it.

=item idx

Name of the object to be searched in full-text mode. If the object name list is
a list reference, you can also specify the index into the list.

=item objectNames

List containing the names of the entity and relationship objects to be retrieved,
or a string containing a space-delimited list of names. See L</Object Name List>.

=item filterClause

WHERE clause (without the WHERE) to be used to filter and sort the query. See
L</Filter Clause>.

=item params

Reference to a list of parameter values to be substituted into the filter
clause. See L</Parameter List>.

=item RETURN

Returns an L<ERDBQuery> object for the specified search.

=back

=cut

sub Search {
    # Get the parameters.
    my ($self, $searchExpression, $idx, $objectNames, $filterClause, $params) = @_;
    # Declare the return variable.
    my $retVal;
    # Create a safety copy of the parameter list. Note we have to be careful to
    # insure a parameter list exists before we copy it.
    my @myParams = ();
    if (defined $params) {
        @myParams = @{$params};
    }
    # Get the first object's structure so we have access to the searchable fields.
    my $object1Name = ($idx =~ /^\d+$/ ? $objectNames->[$idx] : $idx);
    my $object1Structure = $self->_GetStructure($object1Name);
    # Get the field list.
    if (! exists $object1Structure->{searchFields}) {
        Confess("No searchable index for $object1Name.");
    } else {
        # Get the field list.
        my @fields = @{$object1Structure->{searchFields}};
        # Clean the search expression.
        my $actualKeywords = $self->CleanKeywords($searchExpression);
        Trace("Actual keywords for search are\n$actualKeywords") if T(3);
        # We need two match expressions, one for the filter clause and one in
        # the query itself. Both will use a parameter mark, so we need to push
        # the search expression onto the front of the parameter list twice.
        unshift @myParams, $actualKeywords, $actualKeywords;
        # Build the match expression.
        my @matchFilterFields = map { "$object1Name." . _FixName($_) } @fields;
        my $matchClause = "MATCH (" . join(", ", @matchFilterFields) . ") AGAINST (? IN BOOLEAN MODE)";
        # Process the SQL stuff.
        my ($suffix, $mappedNameListRef, $mappedNameHashRef) =
            $self->_SetupSQL($objectNames, $filterClause, $matchClause);
        # Create the query. Note that the match clause is inserted at the front of
        # the select fields.
        my $command = "SELECT $matchClause, " . join(".*, ", @{$mappedNameListRef}) .
            ".* $suffix";
        my $sth = $self->_GetStatementHandle($command, \@myParams);
        # Now we create the relation map, which enables ERDBQuery to determine the order, name
        # and mapped name for each object in the query.
        my @relationMap = _RelationMap($mappedNameHashRef, $mappedNameListRef);
        # Return the statement object.
        $retVal = ERDBQuery::_new($self, $sth, \@relationMap, $object1Name);
    }
    return $retVal;
}

=head3 GetFlat

    my @list = $erdb->GetFlat(\@objectNames, $filterClause, \@parameterList, $field);

This is a variation of L</GetAll> that asks for only a single field per record
and returns a single flattened list.

=over 4

=item objectNames

List containing the names of the entity and relationship objects to be retrieved,
or a string containing a space-delimited list of names. See L</Object_Name_List>.

=item filterClause

WHERE clause (without the WHERE) to be used to filter and sort the query. See
L</Filter Clause>.

=item params

Reference to a list of parameter values to be substituted into the filter
clause. See L</Parameter List>.

=item field

Name of the field to be used to get the elements of the list returned. The
default object name for this context is the first object name specified.

=item RETURN

Returns a list of values.

=back

=cut

sub GetFlat {
    # Get the parameters.
    my ($self, $objectNames, $filterClause, $parameterList, $field) = @_;
    # Construct the query.
    my $query = $self->Get($objectNames, $filterClause, $parameterList);
    # Create the result list.
    my @retVal = ();
    # Loop through the records, adding the field values found to the result list.
    while (my $row = $query->Fetch()) {
        push @retVal, $row->Value($field);
    }
    # Return the list created.
    return @retVal;
}

=head3 IsUsed

    my $flag = $erdb->IsUsed($relationName);

Returns TRUE if the specified relation contains any records, else FALSE.

=over 4

=item relationName

Name of the relation to check.

=item RETURN

Returns the number of records in the relation, which will be TRUE if the
relation is nonempty and FALSE otherwise.

=back

=cut

sub IsUsed {
    # Get the parameters.
    my ($self, $relationName) = @_;
    # Get the data base handle.
    my $dbh = $self->{_dbh};
    # Construct a query to count the records in the relation.
    my $cmd = "SELECT COUNT(*) FROM $self->{_quote}$relationName$self->{_quote}";
    my $results = $dbh->SQL($cmd);
    # We'll put the count in here.
    my $retVal = 0;
    if ($results && scalar @$results) {
        $retVal = $results->[0][0];
    }
    # Return the count.
    return $retVal;
}

=head2 Documentation and Metadata Methods

=head3 ComputeFieldTable

    my ($header, $rows) = ERDB::ComputeFieldTable($wiki, $name, $fieldData);

Generate the header and rows of a field table for an entity or
relationship. The field table describes each field in the specified
object.

=over 4

=item wiki

L<WikiTools> object (or equivalent) for rendering HTML or markup.

=item name

Name of the object whose field table is being generated.

=item fieldData

Field structure of the specified entity or relationship.

=item RETURN

Returns a reference to a list of the labels for the header row and
a reference to a list of lists representing the table cells.

=back

=cut

sub ComputeFieldTable {
    # Get the parameters.
    my ($wiki, $name, $fieldData) = @_;
    # We need to sort the fields. First comes the ID, then the
    # primary fields and the secondary fields.
    my %sorter;
    for my $field (keys %$fieldData) {
        # Get the field's descriptor.
        my $fieldInfo = $fieldData->{$field};
        # Determine whether or not we have a primary field.
        my $primary;
        if ($field eq 'id') {
            $primary = 'A';
        } elsif ($fieldInfo->{relation} eq $name) {
            $primary = 'B';
        } else {
            $primary = 'C';
        }
        # Form the sort key from the flag and the name.
        $sorter{$field} = "$primary$field";
    }
    # Create the header descriptor for the table.
    my @header = qw(Name Type Notes);
    # We'll stash the rows in here.
    my @rows;
    # Loop through the fields in their proper order.
    for my $field (Tracer::SortByValue(\%sorter)) {
        # Get the field's descriptor.
        my $fieldInfo = $fieldData->{$field};
        # Format the type.
        my $type = "$fieldInfo->{type}";
        if ($fieldInfo->{null}) {
            $type .= " (nullable)";
        }
        # Secondary fields have "C" as the first letter in
        # the sort value. If a field is secondary, we mark
        # it as an array.
        if ($sorter{$field} =~ /^C/) {
            $type .= " array";
        }
        # Format its table row.
        push @rows, [$field, $type, ObjectNotes($fieldInfo, $wiki)];
    }
    # Return the results.
    return (\@header, \@rows);
}

=head3 FindEntity

    my $objectData = $erdb->FindEntity($name);

Return the structural descriptor of the specified entity, or an undefined
value if the entity does not exist.

=over 4

=item name

Name of the desired entity.

=item RETURN

Returns the definition structure for the specified entity, or C<undef>
if the named entity does not exist.

=back

=cut

sub FindEntity {
    # Get the parameters.
    my ($self, $name) = @_;
    # Return the result.
    return $self->_FindObject(Entities => $name);
}

=head3 FindRelationship

    my $objectData = $erdb->FindRelationship($name);

Return the structural descriptor of the specified relationship, or an undefined
value if the relationship does not exist.

=over 4

=item name

Name of the desired relationship.

=item RETURN

Returns the definition structure for the specified relationship, or C<undef>
if the named relationship does not exist.

=back

=cut

sub FindRelationship {
    # Get the parameters.
    my ($self, $name) = @_;
    # Return the result.
    return $self->_FindObject(Relationships => $name);
}

=head3 ComputeTargetEntity

    my $targetEntity = $erdb->ComputeTargetEntity($relationshipName);

Return the target entity of a relationship. If the relationship's true
name is specified, this is the source (from) entity. If its converse
name is specified, this is the target (to) entity. The returned name is
the one expected to follow the relationship name in an object name string.

=over 4

=item relationshipName

The name of the relationship to be used to identify the target entity.

=item RETURN

Returns the name of the entity that would be found after crossing
the relationship in the direction indicated by the chosen relationship
name. If the relationship name is invalid, an undefined value will be
returned.

=back

=cut

sub ComputeTargetEntity {
    # Get the parameters.
    my ($self, $relationshipName) = @_;
    # Declare the return variable.
    my $retVal;
    # Look for it in the alias table.
    my $realName = $self->{_metaData}->{AliasTable}->{$relationshipName};
    # Only proceed if it was found.
    if (defined $realName) {
        # Get the relationship's from and to entities.
        my ($fromEntity, $toEntity) = $self->GetRelationshipEntities($realName);
        # Return the appropriate one.
        if ($realName eq $relationshipName) {
            $retVal = $toEntity;
        } else {
            $retVal = $fromEntity;
        }
    }
    # Return the entity name found.
    return $retVal;
}

=head3 FindShape

    my $objectData = $erdb->FindShape($name);

Return the structural descriptor of the specified shape, or an undefined
value if the shape does not exist.

=over 4

=item name

Name of the desired shape.

=item RETURN

Returns the definition structure for the specified shape, or C<undef>
if the named shape does not exist.

=back

=cut

sub FindShape {
    # Get the parameters.
    my ($self, $name) = @_;
    # Return the result.
    return $self->_FindObject(Shapes => $name);
}

=head3 GetObjectsTable

    my $objectHash = $erdb->GetObjectsTable($type);

Return the metadata hash of objects of the specified type-- entity,
relationship, or shape.

=over 4

=item type

Type of object desired-- C<entity>, C<relationship>, or C<shape>.

=item RETURN

Returns a reference to a hash containing all metadata for database
objects of the specified type. The hash maps object names to object
descriptors. The descriptors represent a cleaned and normalized
version of the definition XML. Specifically, all of the implied
defaults are filled in.

=back

=cut

sub GetObjectsTable {
    # Get the parameters.
    my ($self, $type) = @_;
    # Return the result.
    return $self->{_metaData}->{ERDB::Plurals($type)};
}

=head3 Plurals

    my $plural = ERDB::Plurals($singular);

Return the plural form of the specified object type (entity,
relationship, or shape). This is extremely useful in generating
documentation.

=over 4

=item singular

Singular form of the specified object type.

=item RETURN

Plural form of the specified object type, in capital case.

=back

=cut

sub Plurals {
    # Get the parameters.
    my ($singular) = @_;
    # Convert to capital case.
    my $retVal = ucfirst $singular;
    # Handle a "y" at the end.
    $retVal =~ s/y$/ie/;
    # Add the "s".
    $retVal .= "s";
    # Return the result.
    return $retVal;
}

=head3 ReadMetaXML

    my $rawMetaData = ERDB::ReadDBD($fileName);

This method reads a raw database definition XML file and returns it.
Normally, the metadata used by the ERDB system has been processed and
modified to make it easier to load and retrieve the data; however,
this method can be used to get the data in its raw form.

=over 4

=item fileName

Name of the XML file to read.

=item RETURN

Returns a hash reference containing the raw XML data from the specified file.

=back

=cut

sub ReadMetaXML {
    # Get the parameters.
    my ($fileName) = @_;
    # Read the XML.
    my $retVal = XML::Simple::XMLin($fileName, %XmlOptions, %XmlInOpts);
    Trace("XML metadata loaded from file $fileName.") if T(1);
    # Return the result.
    return $retVal;
}

=head3 FieldType

    my $type = $erdb->FieldType($string, $defaultName);

Return the L<ERDBType> object for the specified field.

=over 4

=item string

Field name string to be parsed. See L</Standard Field Name Format>.

=item defaultName (optional)

Default object name to be used if the object name is not specified in the
input string.

=item RETURN

Return the type object for the field's type.

=back

=cut

sub FieldType {
    # Get the parameters.
    my ($self, $string, $defaultName) = @_;
    # Get the field descriptor.
    my $fieldData = $self->_FindField($string, $defaultName);
    # Compute the type.
    my $retVal = $TypeTable->{$fieldData->{type}};
    # Return the result.
    return $retVal;
}

=head3 IsSecondary

    my $type = $erdb->IsSecondary($string, $defaultName);

Return TRUE if the specified field is in a secondary relation, else
FALSE.

=over 4

=item string

Field name string to be parsed. See L</Standard Field Name Format>.

=item defaultName (optional)

Default object name to be used if the object name is not specified in the
input string.

=item RETURN

Returns TRUE if the specified field is in a secondary relation, else FALSE.

=back

=cut

sub IsSecondary {
    # Get the parameters.
    my ($self, $string, $defaultName) = @_;
    # Get the field's name and object.
    my ($objName, $fieldName) = ERDB::ParseFieldName($string, $defaultName);
    # Retrieve its descriptor from the metadata.
    my $fieldData = $self->_FindField($fieldName, $objName);
    # Compare the table name to the object name.
    my $retVal = ($fieldData->{relation} ne $objName);
    # Return the result.
    return $retVal;
}

=head3 FindRelation

    my $relData = $erdb->FindRelation($relationName);

Return the descriptor for the specified relation.

=over 4

=item relationName

Name of the relation whose descriptor is to be returned.

=item RETURN

Returns the object that describes the relation's indexes and fields.

=back

=cut
sub FindRelation {
    # Get the parameters.
    my ($self, $relationName) = @_;
    # Get the relation's structure from the master relation table in the
    # metadata structure.
    my $metaData = $self->{_metaData};
    my $retVal = $metaData->{RelationTable}->{$relationName};
    # Return it to the caller.
    return $retVal;
}

=head3 GetRelationshipEntities

    my ($fromEntity, $toEntity) = $erdb->GetRelationshipEntities($relationshipName);

Return the names of the source and target entities for a relationship. If
the specified name is not a relationship, an empty list is returned.

=over 4

=item relationshipName

Name of the relevant relationship.

=item RETURN

Returns a two-element list. The first element is the name of the relationship's
from-entity, and the second is the name of the to-entity. If the specified name
is not for a relationship, both elements are undefined.

=back

=cut

sub GetRelationshipEntities {
    # Get the parameters.
    my ($self, $relationshipName) = @_;
    # Declare the return variable.
    my @retVal = (undef, undef);
    # Try to find the caller-specified name in the relationship table.
    my $relationships = $self->{_metaData}->{Relationships};
    if (exists $relationships->{$relationshipName}) {
        # We found it. Return the from and to.
        @retVal = map { $relationships->{$relationshipName}->{$_} } qw(from to);
    }
    # Return the results.
    return @retVal;
}


=head3 ValidateFieldName

    my $okFlag = ERDB::ValidateFieldName($fieldName);

Return TRUE if the specified field name is valid, else FALSE. Valid field names must
be hyphenated words subject to certain restrictions.

=over 4

=item fieldName

Field name to be validated.

=item RETURN

Returns TRUE if the field name is valid, else FALSE.

=back

=cut

sub ValidateFieldName {
    # Get the parameters.
    my ($fieldName) = @_;
    # Declare the return variable. The field name is valid until we hear
    # differently.
    my $retVal = 1;
    # Look for bad stuff in the name.
    if ($fieldName =~ /--/) {
        # Here we have a doubled minus sign.
        Trace("Field name $fieldName has a doubled hyphen.") if T(1);
        $retVal = 0;
    } elsif ($fieldName !~ /^[A-Za-z]/) {
        # Here the field name is missing the initial letter.
        Trace("Field name $fieldName does not begin with a letter.") if T(1);
        $retVal = 0;
    } else {
        # Strip out the minus signs. Everything remaining must be a letter
        # or digit.
        my $strippedName = $fieldName;
        $strippedName =~ s/-//g;
        if ($strippedName !~ /^([a-z]|\d)+$/i) {
            Trace("Field name $fieldName contains illegal characters.") if T(1);
            $retVal = 0;
        }
    }
    # Return the result.
    return $retVal;
}

=head3 GetFieldTable

    my $fieldHash = $self->GetFieldTable($objectnName);

Get the field structure for a specified entity or relationship.

=over 4

=item objectName

Name of the desired entity or relationship.

=item RETURN

The table containing the field descriptors for the specified object.

=back

=cut

sub GetFieldTable {
    # Get the parameters.
    my ($self, $objectName) = @_;
    # Get the descriptor from the metadata.
    my $objectData = $self->_GetStructure($objectName);
    # Return the object's field table.
    return $objectData->{Fields};
}

=head3 EstimateRowSize

    my $rowSize = $erdb->EstimateRowSize($relName);

Estimate the row size of the specified relation. The estimated row size is
computed by adding up the average length for each data type.

=over 4

=item relName

Name of the relation whose estimated row size is desired.

=item RETURN

Returns an estimate of the row size for the specified relation.

=back

=cut
#: Return Type $;
sub EstimateRowSize {
    # Get the parameters.
    my ($self, $relName) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Find the relation descriptor.
    my $relation = $self->FindRelation($relName);
    # Get the list of fields.
    for my $fieldData (@{$relation->{Fields}}) {
        # Get the field type and add its length.
        my $fieldLen = $TypeTable->{$fieldData->{type}}->averageLength();
        $retVal += $fieldLen;
    }
    # Return the result.
    return $retVal;
}

=head3 SortNeeded

    my $parms = $erdb->SortNeeded($relationName);

Return the pipe command for the sort that should be applied to the specified
relation when creating the load file.

For example, if the load file should be sorted ascending by the first
field, this method would return

    sort -k1 -t"\t"

If the first field is numeric, the method would return

    sort -k1n -t"\t"

=over 4

=item relationName

Name of the relation to be examined. This could be an entity name, a relationship
name, or the name of a secondary entity relation.

=item

Returns the sort command to use for sorting the relation, suitable for piping.

=back

=cut
#: Return Type $;
sub SortNeeded {
    # Get the parameters.
    my ($self, $relationName) = @_;
    # Declare a descriptor to hold the names of the key fields.
    my @keyNames = ();
    # Get the relation structure.
    my $relationData = $self->FindRelation($relationName);
    # Get the relation's field list.
    my @fields = @{$relationData->{Fields}};
    my @fieldNames = map { $_->{name} } @fields;
    # Find out if the relation is a primary entity relation,
    # a relationship relation, or a secondary entity relation.
    my $entityTable = $self->{_metaData}->{Entities};
    my $relationshipTable = $self->{_metaData}->{Relationships};
    if (exists $entityTable->{$relationName}) {
        # Here we have a primary entity relation. We sort on the ID, and the
        # ID only.
        push @keyNames, "id";
    } elsif (exists $relationshipTable->{$relationName}) {
        # Here we have a relationship. We sort using the FROM index followed by
        # the rest of the fields, in order. First, we get all of the fields in
        # a hash.
        my %fieldsLeft = map { $_ => 1 } @fieldNames;
        # Get the index.
        my $index = $relationData->{Indexes}->{idxFrom};
        # Loop through its fields.
        for my $keySpec (@{$index->{IndexFields}}) {
            # Mark this field as used. The field may have a modifier, so we only
            # take the part up to the first space.
            $keySpec =~ /^(\S+)/;
            $fieldsLeft{$1} = 0;
            push @keyNames, $keySpec;
        }
        # Push the rest of the fields on.
        push @keyNames, grep { $fieldsLeft{$_} } @fieldNames;
    } else {
        # Here we have a secondary entity relation, so we have a sort on the whole
        # record. This essentially gives us a sort on the ID followed by the
        # secondary data field.
        push @keyNames, @fieldNames;
    }
    # Now we parse the key names into sort parameters. First, we prime the return
    # string.
    my $retVal = "sort $ERDBExtras::sort_options -u -T\"$ERDBExtras::temp\" -t\"\t\" ";
    # Loop through the keys.
    for my $keyData (@keyNames) {
        # Get the key and the ordering.
        my ($keyName, $ordering);
        if ($keyData =~ /^([^ ]+) DESC/) {
            ($keyName, $ordering) = ($1, "descending");
        } else {
            ($keyName, $ordering) = ($keyData, "ascending");
        }
        # Find the key's position and type.
        my $fieldSpec;
        for (my $i = 0; $i <= $#fields && ! $fieldSpec; $i++) {
            my $thisField = $fields[$i];
            if ($thisField->{name} eq $keyName) {
                # Get the sort modifier for this field type. The modifier
                # decides whether we're using a character, numeric, or
                # floating-point sort.
                my $modifier = $TypeTable->{$thisField->{type}}->sortType();
                # If the index is descending for this field, denote we want
                # to reverse the sort order on this field.
                if ($ordering eq 'descending') {
                    $modifier .= "r";
                }
                # Store the position and modifier into the field spec, which
                # will stop the inner loop. Note that the field number is
                # 1-based in the sort command, so we have to increment the
                # index.
                my $realI = $i + 1;
                $fieldSpec = "$realI,$realI$modifier";
            }
        }
        # Add this field to the sort command.
        $retVal .= " -k$fieldSpec";
    }
    # Return the result.
    return $retVal;
}

=head3 SpecialFields

    my %specials = $erdb->SpecialFields($entityName);

Return a hash mapping special fields in the specified entity to the value of their
C<special> attribute. This enables the subclass to get access to the special field
attributes without needed to plumb the internal ERDB data structures.

=over 4

=item entityName

Name of the entity whose special fields are desired.

=item RETURN

Returns a hash. The keys of the hash are the special field names, and the values
are the values from each special field's C<special> attribute.

=back

=cut

sub SpecialFields {
    # Get the parameters.
    my ($self, $entityName) = @_;
    # Declare the return variable.
    my %retVal = ();
    # Find the entity's data structure.
    my $entityData = $self->{_metaData}->{Entities}->{$entityName};
    # Loop through its fields, adding each special field to the return hash.
    my $fieldHash = $entityData->{Fields};
    for my $fieldName (keys %{$fieldHash}) {
        my $fieldData = $fieldHash->{$fieldName};
        if (exists $fieldData->{special}) {
            $retVal{$fieldName} = $fieldData->{special};
        }
    }
    # Return the result.
    return %retVal;
}


=head3 GetTableNames

    my @names = $erdb->GetTableNames;

Return a list of the relations required to implement this database.

=cut

sub GetTableNames {
    # Get the parameters.
    my ($self) = @_;
    # Get the relation list from the metadata.
    my $relationTable = $self->{_metaData}->{RelationTable};
    # Return the relation names.
    return keys %{$relationTable};
}

=head3 GetEntityTypes

    my @names = $erdb->GetEntityTypes;

Return a list of the entity type names.

=cut

sub GetEntityTypes {
    # Get the database object.
    my ($self) = @_;
    # Get the entity list from the metadata object.
    my $entityList = $self->{_metaData}->{Entities};
    # Return the list of entity names in alphabetical order.
    return sort keys %{$entityList};
}


=head3 GetConnectingRelationships

    my @list = $erdb->GetConnectingRelationships($entityName);

Return a list of the relationships connected to the specified entity.

=over 4

=item entityName

Entity whose connected relationships are desired.

=item RETURN

Returns a list of the relationships that originate from the entity.
If the entity is on the I<from> end, it will return the relationship
name. If the entity is on the I<to> end it will return the converse of
the relationship name.

=back

=cut

sub GetConnectingRelationships {
    # Get the parameters.
    my ($self, $entityName) = @_;
    # Declare the return variable.
    my @retVal;
    # Get the relationship list.
    my $relationships = $self->{_metaData}->{Relationships};
    # Find the entity.
    my $entity = $self->{_metaData}->{Entities}->{$entityName};
    # Only proceed if the entity exists.
    if (! defined $entity) {
        Trace("Entity $entityName not found.") if T(3);
    } else {
        # Loop through the relationships.
        my @rels = keys %$relationships;
        Trace(scalar(@rels) . " relationships found in connection search.") if T(3);
        for my $relationshipName (@rels) {
            my $relationship = $relationships->{$relationshipName};
            if ($relationship->{from} eq $entityName) {
                # Here we have a forward relationship.
                push @retVal, $relationshipName;
            } elsif ($relationship->{to} eq $entityName) {
                # Here we have a backward relationship. In this case, the
                # converse relationship name is preferred if it exists.
                my $converse = $relationship->{converse} || $relationshipName;
                push @retVal, $converse;
            }
        }
    }
    # Return the result.
    return @retVal;
}

=head3 GetConnectingRelationshipData

    my ($froms, $tos) = $erdb->GetConnectingRelationshipData($entityName);

Return the relationship data for the specified entity. The return will be
a two-element list, each element of the list a reference to a hash that
maps relationship names to structures. The first hash will be
relationships originating from the entity, and the second element a
reference to a hash of relationships pointing to the entity.

=over 4

=item entityName

Name of the entity of interest.

=item RETURN

Returns a two-element list, each list being a map of relationship names
to relationship metadata structures. The first element lists relationships
originating from the entity, and the second element lists relationships that
point to the entity.

=back

=cut

sub GetConnectingRelationshipData {
    # Get the parameters.
    my ($self, $entityName) = @_;
    # Create a hash that holds the return values.
    my %retVal = (from => {}, to => {});
    # Get the relationship table in the metadata.
    my $relationships = $self->{_metaData}->{Relationships};
    # Loop through it twice, once for each direction.
    for my $direction (qw(from to)) {
        # Get the return hash for this direction.
        my $hash = $retVal{$direction};
        # Loop through the relationships, looking for our entity in the
        # current direction.
        for my $rel (keys %$relationships) {
            my $relData = $relationships->{$rel};
            if ($relData->{$direction} eq $entityName) {
                # Here we've found our entity, so we put it in the
                # return hash.
                $hash->{$rel} = $relData;
            }
        }
    }
    # Return the results.
    return ($retVal{from}, $retVal{to});
}

=head3 GetDataTypes

    my $types = ERDB::GetDataTypes();

Return a table of ERDB data types. The table returned is a hash of
L</ERDBType> objects keyed by type name.

=cut

sub GetDataTypes {
    # Insure we have a type table.
    if (! defined $TypeTable) {
        # Get a list of the names of the standard type classes.
        my @types = @StandardTypes;
        # Add in the custom types, if any.
        if (defined $ERDBExtras::customERDBtypes) {
            push @types, @$ERDBExtras::customERDBtypes;
        }
        Trace("Type List: " . join(", ", @types)) if T(Types => 3);
        # Initialize the table.
        $TypeTable = {};
        # Loop through all of the types, creating the type objects.
        for my $type (@types) {
            # Create the type object.
            my $typeObject;
            eval {
                require "$type.pm";
                $typeObject = eval("$type->new()");
            };
            # Ensure we didn't have an error.
            if ($@) {
                Confess("Error building ERDB type table: $@");
            } else {
                # Add the type to the type table.
                $TypeTable->{$typeObject->name()} = $typeObject;
            }
        }
    }
    # Return the type table.
    return $TypeTable;
}


=head3 ShowDataTypes

    my $markup = ERDB::ShowDataTypes($wiki, $erdb);

Display a table of all the valid data types for this installation.

=over 4

=item wiki

An object used to render the table, similar to L</WikiTools>.

=item erdb (optional)

If specified, an ERDB object for a specific database. Only types used by
the database will be put in the table. If omitted, all types are returned.


=back

=cut

sub ShowDataTypes {
    my ($wiki, $erdb) = @_;
    # Compute the hash of types to display.
    my $typeHash = ();
    if (! defined $erdb) {
        # No ERDB object, so we list all the types.
        $typeHash = GetDataTypes();
    } else {
        # Here we must extract the types used in the ERDB object.
        for my $relationName ($erdb->GetTableNames()) {
            my $relationData = $erdb->FindRelation($relationName);
            for my $fieldData (@{$relationData->{Fields}}) {
                my $type = $fieldData->{type};
                my $typeData = $TypeTable->{$type};
                if (! defined $typeData) {
                    Confess("Invalid data type \"$type\" in relation $relationName.");
                } else {
                    $typeHash->{$type} = $typeData;
                }
            }
        }
    }
    # We'll build table rows in here. We start with the header.
    my @rows = [qw(Type Indexable Sort Pos Format Description)];
    # Loop through the types, generating rows.
    for my $type (sort keys %$typeHash) {
        # Get the type object.
        my $typeData = $typeHash->{$type};
        # Compute the indexing column.
        my $flag = $typeData->indexMod();
        if (! defined $flag) {
            $flag = "no";
        } elsif ($flag eq "") {
            $flag = "yes";
        } else {
            $flag = "prefix";
        }
        # Compute the sort type.
        my $sortType = $typeData->sortType();
        if ($sortType eq 'g' || $sortType eq 'n') {
            $sortType = "numeric";
        } else {
            $sortType = "alphabetic";
        }
        # Get the position (pretty-sort value).
        my $pos = $typeData->prettySortValue();
        # Finally, the format.
        my $format = $typeData->objectType() || "scalar";
        # Build the data row.
        my $row = [$type, $flag, $sortType, $pos, $format, $typeData->documentation()];
        # Put it into the table.
        push @rows, $row;
    }
    # Form up the table.
    my $retVal = $wiki->Table(@rows);
    # Return the result.
    return $retVal;
}

=head3 IsEntity

    my $flag = $erdb->IsEntity($entityName);

Return TRUE if the parameter is an entity name, else FALSE.

=over 4

=item entityName

Object name to be tested.

=item RETURN

Returns TRUE if the specified string is an entity name, else FALSE.

=back

=cut

sub IsEntity {
    # Get the parameters.
    my ($self, $entityName) = @_;
    # Test to see if it's an entity.
    return exists $self->{_metaData}->{Entities}->{$entityName};
}

=head3 GetSecondaryFields

    my %fieldTuples = $erdb->GetSecondaryFields($entityName);

This method will return a list of the name and type of each of the secondary
fields for a specified entity. Secondary fields are stored in two-column tables
separate from the primary entity table. This enables the field to have no value
or to have multiple values.

=over 4

=item entityName

Name of the entity whose secondary fields are desired.

=item RETURN

Returns a hash mapping the field names to their field types.

=back

=cut

sub GetSecondaryFields {
    # Get the parameters.
    my ($self, $entityName) = @_;
    # Declare the return variable.
    my %retVal = ();
    # Look for the entity.
    my $table = $self->GetFieldTable($entityName);
    # Loop through the fields, pulling out the secondaries.
    for my $field (sort keys %{$table}) {
        if ($table->{$field}->{relation} ne $entityName) {
            # Here we have a secondary field.
            $retVal{$field} = $table->{$field}->{type};
        }
    }
    # Return the result.
    return %retVal;
}

=head3 GetFieldRelationName

    my $name = $erdb->GetFieldRelationName($objectName, $fieldName);

Return the name of the relation containing a specified field.

=over 4

=item objectName

Name of the entity or relationship containing the field.

=item fieldName

Name of the relevant field in that entity or relationship.

=item RETURN

Returns the name of the database relation containing the field, or C<undef> if
the field does not exist.

=back

=cut

sub GetFieldRelationName {
    # Get the parameters.
    my ($self, $objectName, $fieldName) = @_;
    # Declare the return variable.
    my $retVal;
    # Get the object field table.
    my $table = $self->GetFieldTable($objectName);
    # Only proceed if the field exists.
    if (exists $table->{$fieldName}) {
        # Determine the name of the relation that contains this field.
        $retVal = $table->{$fieldName}->{relation};
    }
    # Return the result.
    return $retVal;
}

=head3 DumpMetaData

    $erdb->DumpMetaData();

Return a dump of the metadata structure.

=cut

sub DumpMetaData {
    # Get the parameters.
    my ($self) = @_;
    # Dump the meta-data.
    return Data::Dumper::Dumper($self->{_metaData});
}

=head3 GenerateWikiData

    my @wikiLines = $erdb->GenerateWikiData($wiki);

Build a description of the database for a wiki. The database will be
organized into a single page, with sections for each entity and relationship.
The return value is a list of text lines.

The parameter must be an object that mimics the object-based interface of the
L</WikiTools> object. If it is omitted, L</WikiTools> is used.

=cut

sub GenerateWikiData {
    # Get the parameters.
    my ($self, $wiki) = @_;
    # If there's no Wiki object, use the default one.
    require WikiTools;
    $wiki = WikiTools->new() if ! defined $wiki;
    # We'll build the wiki text in here.
    my @retVal = ();
    # Get the metadata object.
    my $metadata = $self->{_metaData};
    # Get the title string. This will become the page name.
    my $title = $metadata->{Title}->{content};
    # Get the entity and relationship lists.
    my $entityList = $metadata->{Entities};
    my $relationshipList = $metadata->{Relationships};
    my $shapeList = $metadata->{Shapes};
    # Start with the introductory text.
    push @retVal, $wiki->Heading(2, "Introduction");
    if (my $notes = $metadata->{Notes}) {
        push @retVal, _WikiNote($notes->{content}, $wiki);
    }
    # Generate the issue list.
    if (my $issues = $metadata->{Issues}) {
        push @retVal, $wiki->Heading(3, 'Issues');
        push @retVal, $wiki->List(map { $_->{content} } @{$issues});
    }
    # Generate the region list.
    if (my $regions = $metadata->{Regions}) {
        push @retVal, $wiki->Heading(3, 'Diagram Regions');
        for my $region (@$regions) {
            # Check for notes.
            my $notes = "";
            if ($region->{Notes}) {
                $notes = $region->{Notes}->{content};
            }
            # Put out the region name as a heading.
            push @retVal, $wiki->Heading(4, $region->{name});
            # Output the notes for the region.
            push @retVal, _WikiNote($notes, $wiki);
        }
    }
    # Generate the type table.
    push @retVal, $wiki->Heading(2, "Data Types");
    push @retVal, ShowDataTypes($wiki, $self);
    # Start the entity section.
    push @retVal, $wiki->Heading(2, "Entities");
    # Loop through the entities. Note that unlike the situation with HTML, we
    # don't need to generate the table of contents manually, just the data
    # itself.
    for my $key (sort keys %$entityList) {
        # Create a header for this entity.
        push @retVal, "", $wiki->Heading(3, $key);
        # Get the entity data.
        my $entityData = $entityList->{$key};
        # Plant the notes here, if there are any.
        push @retVal, ObjectNotes($entityData, $wiki);
        # Now we list the entity's relationships (if any). First, we build a list
        # of the relationships relevant to this entity.
        my @rels = ();
        for my $rel (sort keys %$relationshipList) {
            my $relStructure = $relationshipList->{$rel};
            # Find out if this relationship involves this entity.
            my $dir;
            if ($relStructure->{from} eq $key) {
                $dir ='from';
            } elsif ($relStructure->{to} eq $key) {
                $dir = 'to';
            }
            if ($dir) {
                # Get the relationship sentence.
                my $relSentence = _ComputeRelationshipSentence($wiki, $rel, $relStructure, $dir);
                # Add it to the relationship list.
                push @rels, $relSentence;
            }
        }
        # Add the relationships as a Wiki list.
        push @retVal, $wiki->List(@rels);
        # Finally, the field table.
        push @retVal, _WikiObjectTable($key, $entityData->{Fields}, $wiki);
    }
    # Now the entities are documented. Next we do the relationships.
    push @retVal, $wiki->Heading(2, "Relationships");
    for my $key (sort keys %$relationshipList) {
        my $relationshipData = $relationshipList->{$key};
        # Create the relationship heading.
        push @retVal, $wiki->Heading(3, $key);
        # Describe the relationship arity. Note there's a bit of trickiness
        # involving recursive many-to-many relationships. In a normal
        # many-to-many we use two sentences to describe the arity (one for each
        # direction). This is a bad idea for a recursive relationship, since
        # both sentences will say the same thing.
        my $arity = $relationshipData->{arity};
        my $fromEntity = $relationshipData->{from};
        my $toEntity = $relationshipData->{to};
        my @listElements = ();
        if ($arity eq "11") {
            push @listElements, "Each " . $wiki->Bold($fromEntity) .
                " relates to at most one " . $wiki->Bold($toEntity) . ".";
        } else {
            push @listElements, "Each " . $wiki->Bold($fromEntity) .
                " relates to multiple " . $wiki->Bold(Tracer::Pluralize($toEntity)) . ".";
            if ($arity eq "MM" && $fromEntity ne $toEntity) {
                push @listElements, "Each " . $wiki->Bold($toEntity) .
                    " relates to multiple " . $wiki->Bold(Tracer::Pluralize($fromEntity));
            }
        }
        if ($relationshipData->{converse}) {
            push @listElements, "Converse name is $relationshipData->{converse}."
        }
        push @retVal, $wiki->List(@listElements);
        # Plant the notes here, if there are any.
        push @retVal, ObjectNotes($relationshipData, $wiki);
        # Finally, the field table.
        push @retVal, _WikiObjectTable($key, $relationshipData->{Fields}, $wiki);
    }
    # Now loop through the miscellaneous shapes.
    if ($shapeList) {
        push @retVal, $wiki->Heading(2, "Miscellaneous");
        for my $shape (sort keys %$shapeList) {
            push @retVal, $wiki->Heading(3, $shape);
            my $shapeData = $shapeList->{$shape};
            push @retVal, ObjectNotes($shapeData, $wiki);
        }
    }
    # All done. Return the lines.
    return @retVal;
}

=head3 ObjectNotes

    my @noteParagraphs = ERDB::ObjectNotes($objectData, $wiki);

Return a list of the notes and asides for an entity or relationship in
Wiki format.

=over 4

=item objectData

The metadata for the desired entity or relationship.

=item wiki

Wiki object used to render text.

=item RETURN

Returns a list of text paragraphs in Wiki markup form.

=back

=cut

sub ObjectNotes {
    # Get the parameters.
    my ($objectData, $wiki) = @_;
    # Declare the return variable.
    my @retVal;
    # Loop through the types of notes.
    for my $noteType (qw(Notes Asides)) {
        my $text = $objectData->{$noteType};
        if ($text) {
            push @retVal, _WikiNote($text->{content}, $wiki);
        }
    }
    # Return the result.
    return @retVal;
}

=head3 CheckObjectNames

    my @errors = $erdb->CheckObjectNames($objectNameString);

Check an object name string for errors. The return value will be a list
of error messages. If no error is found, an empty list will be returned.
This process does not guarantee a correct object name list, but it
catches the most obvious errors without the need for invoking a
full-blown L</Get> method.

=over 4

=item objectNameString

An object name string, consisting of a space-delimited list of entity and
relationship names.

=item RETURN

Returns an empty list if successful, and a list of error messages if the
list is invalid.

=back

=cut

sub CheckObjectNames {
    # Get the parameters.
    my ($self, $objectNameString) = @_;
    # Declare the return variable.
    my @retVal;
    # Separate the string into pieces.
    my @objectNames = split m/\s+/, $objectNameString;
    # Start in a blank state.
    my $currentObject;
    # Get the alias table.
    my $aliasTable = $self->{_metaData}->{AliasTable};
    # Loop through the object names.
    for my $objectName (@objectNames) {
        # If we have an AND, clear the current object.
        if ($objectName eq 'AND') {
            # Insure we don't have an AND at the beginning or after another AND.
            if (! defined $currentObject) {
                push @retVal, "An AND was found in the wrong place.";
            }
            # Clear the context.
            undef $currentObject;
        } else {
            # Here the user has specified an object name. Get
            # the root name.
            unless ($objectName =~ /([A-Za-z]+)(\d*)/) {
                # Here the name has bad characters in it. Note that an error puts
                # us into a blank state.
                push @retVal, "Invalid characters found in \"$objectName\".";
                undef $currentObject;
            } else {
                # Get the real name from the alias table.
                my $name = $aliasTable->{$1};
                if (! defined $name) {
                    push @retVal, "Could not find an entity or relationship named \"$objectName\".";
                    undef $currentObject;
                } else {
                    # Okay, we've got the real entity or relationship name. Does it belong here?
                    # That's only an issue if there is a previous value in $currentObject.
                    if (defined $currentObject) {
                        my $joinClause = $self->_JoinClause($currentObject, $name);
                        if (! $joinClause) {
                            push @retVal, "There is no connection between $currentObject and $name."
                        }
                    }
                    # Save this object as the new current object.
                    $currentObject = $name;
                }
            }
        }
    }
    # Return the result.
    return @retVal;
}

=head3 GetTitle

    my $text = $erdb->GetTitle();

Return the title for this database.

=cut

sub GetTitle {
    # Get the parameters.
    my ($self) = @_;
    # Declare the return variable.
    my $retVal = $self->{_metaData}->{Title};
    if (! $retVal) {
        # Here no title was supplied, so we make one up.
        $retVal = "Unknown Database";
    } else {
        # Extract the content of the title element. This is the real title.
        $retVal = $retVal->{content};
    }
    # Return the result.
    return $retVal;
}

=head3 GetDiagramOptions

    my $hash = $erdb->GetDiagramOptions();

Return the diagram options structure for this database. The diagram
options are used by the ERDB documentation widget to configure the
database diagram. If the options are not present, an undefined value will
be returned.

=cut

sub GetDiagramOptions {
    # Get the parameters.
    my ($self) = @_;
    # Extract the options element.
    my $retVal = $self->{_metaData}->{Diagram};
    # Return the result.
    return $retVal;
}

=head3 GetMetaFileName

    my $fileName = $erdb->GetMetaFileName();

Return the name of the database definition file for this database.

=cut

sub GetMetaFileName {
    # Get the parameters.
    my ($self) = @_;
    # Return the result.
    return $self->{_metaFileName};
}


=head2 Database Administration and Loading Methods

=head3 LoadTable

    my $results = $erdb->LoadTable($fileName, $relationName, %options);

Load data from a tab-delimited file into a specified table, optionally
re-creating the table first.

=over 4

=item fileName

Name of the file from which the table data should be loaded.

=item relationName

Name of the relation to be loaded. This is the same as the table name.

=item options

A hash of load options.

=item RETURN

Returns a statistical object containing a list of the error messages.

=back

The permissible options are as follows.

=over 4

=item truncate

If TRUE, then the table will be erased before loading.

=item mode

Mode in which the load should operate, either C<low_priority> or C<concurrent>.
This option is only applicable to a MySQL database.

=item partial

If TRUE, then it is assumed that this is a partial load, and the table will not
be analyzed and compacted at the end.

=item failOnError

If TRUE, then when an error occurs, the process will be killed; otherwise, the
process will stay alive, but a message will be put into the statistics object.

=item dup

If C<ignore>, duplicate rows will be ignored. If C<replace>, duplicate rows will 
replace previous instances. If omitted, duplicate rows will cause an error.

=back

=cut

sub LoadTable {
    # Get the parameters.
    my ($self, $fileName, $relationName, %options) = @_;
    # Record any error message in here. If it's defined when we're done
    # and failOnError is set, we confess it.
    my $errorMessage;
    # Create the statistical return object.
    my $retVal = _GetLoadStats();
    # Trace the fact of the load.
    Trace("Loading table $relationName from $fileName") if T(2);
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Get the input file size.
    my $fileSize = -s $fileName;
    # Get the relation data.
    my $relation = $self->FindRelation($relationName);
    # Check the truncation flag.
    if ($options{truncate}) {
        Trace("Creating table $relationName") if T(2);
        # Compute the row count estimate. We take the size of the load file,
        # divide it by the estimated row size, and then multiply by 8 to
        # leave extra room. We postulate a minimum row count of 10000 to
        # prevent problems with incoming empty load files.
        my $rowSize = $self->EstimateRowSize($relationName);
        my $estimate = $fileSize * 8 / $rowSize;
        if ($estimate < 10000) {
            $estimate = 10000;
        }
        # Re-create the table without its index.
        $self->CreateTable($relationName, 0, $estimate);
        # If this is a pre-index DBMS, create the index here.
        if ($dbh->{_preIndex}) {
            eval {
                $self->CreateIndex($relationName);
            };
            if ($@) {
                $retVal->AddMessage($@);
                $errorMessage = $@;
            }
        }
    }
    # Load the table.
    my $rv;
    eval {
        $rv = $dbh->load_table(file => $fileName, tbl => $relationName,
                               style => $options{mode}, 'local' => 'LOCAL', 
                               dup => $options{dup} );
    };
    if (!defined $rv) {
        $retVal->AddMessage($@) if ($@);
        $errorMessage = "Table load failed for $relationName using $fileName.";
        $retVal->AddMessage("$errorMessage: " . $dbh->error_message);
    } else {
        # Here we successfully loaded the table.
        my $size = -s $fileName;
        Trace("$size bytes loaded into $relationName.") if T(2);
        $retVal->Add("bytes-loaded", $size);
        $retVal->Add("tables-loaded" => 1);
        # If we're rebuilding, we need to create the table indexes.
        if ($options{truncate}) {
            # Indexes are created here for PostGres. For PostGres, indexes are
            # best built at the end. For MySQL, the reverse is true.
            if (! $dbh->{_preIndex}) {
                eval {
                    $self->CreateIndex($relationName);
                };
                if ($@) {
                    $errorMessage = $@;
                    $retVal->AddMessage($errorMessage);
                }
            }
            # The full-text index (if any) is always built last, even for MySQL.
            # First we need to see if this table HAS a full-text index. Only
            # primary relations are allowed that privilege.
            Trace("Checking for full-text index on $relationName.") if T(2);
            if ($self->_IsPrimary($relationName)) {
                $self->CreateSearchIndex($relationName);
            }
        }
    }
    if ($errorMessage && $options{failOnError}) {
        # Here the load failed and we want to error out.
        Confess($errorMessage);
    }
    # Analyze the table to improve performance.
    if (! $options{partial}) {
        Trace("Analyzing and compacting $relationName.") if T(3);
        $self->Analyze($relationName);
    }
    Trace("$relationName load completed.") if T(3);
    # Return the statistics.
    return $retVal;
}

=head3 InsertNew

    my $newID = $erdb->InsertNew($entityName, %fields);

Insert a new entity into a table that uses sequential integer IDs. A new,
unique ID will be computed automatically and returned to the caller.

=over 4

=item entityName

Type of the entity being inserted. The entity must have an integer ID.

=item fields

Hash of field names to field values. Every field in the entity's primary relation
should be specified.

=item RETURN

Returns the ID of the inserted entity.

=back

=cut

sub InsertNew {
    # Get the parameters.
    my ($self, $entityName, %fields) = @_;
    # Declare the return variable.
    my $retVal;
    # If this is our first insert, we update the ID field definition.
    if (! exists $self->{_autonumber}->{$entityName}) {
        # Check to see if this is an autonumbered entity.
        my $entityData = $self->FindEntity($entityName);
        if (! defined $entityData || ! $entityData->{autonumber}) {
            Confess("Cannot use InsertNew for a entity $entityName.");
        } else {
            # Create the alter table command.
            my $fieldString = $self->_FieldString($entityData->{Fields}->{id});
            my $command = "ALTER TABLE $self->{_quote}$entityName$self->{_quote} CHANGE COLUMN id $fieldString AUTO_INCREMENT";
            # Execute the command.
            my $dbh = $self->{_dbh};
            $dbh->SQL($command);
            # Insure we don't do this again.
            $self->{_autonumber}->{$entityName} = 1;
        }
    }
    # Insert the entity.
    $self->InsertObject($entityName, %fields, id => undef);
    # Get the last ID inserted.
    my $dbh = $self->{_dbh};
    $retVal = $dbh->last_insert_id();
    # Return the result.
    return $retVal;
}


=head3 Analyze

    $erdb->Analyze($tableName);

Analyze and compact a table in the database. This is useful after a load
to improve the performance of the indexes.

=over 4

=item tableName

Name of the table to be analyzed and compacted.

=back

=cut

sub Analyze {
    # Get the parameters.
    my ($self, $tableName) = @_;
    # Analyze the table.
    $self->{_dbh}->vacuum_it($tableName);
}

=head3 TruncateTable

    $erdb->TruncateTable($table);

Delete all rows from a table quickly. This uses the built-in SQL
C<TRUNCATE> statement, which effectively drops and re-creates a table
with all its settings intact.

=over 4

=item table

Name of the table to be cleared.

=back

=cut

sub TruncateTable {
    # Get the parameters.
    my ($self, $table) = @_;
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Execute a truncation comment.
    $dbh->truncate_table($table);
}

=head3 VerifyTable

    my $newFlag = $erdb->VerifyTable($table, $indexFlag, $estimatedRows);

If the specified table does not exist, create it. This method will return TRUE
if the table is created, else FALSE.

=over 4

=item table

Name of the table to verify.

=item indexFlag

TRUE if the indexes for the relation should be created, else FALSE. If FALSE,
L</CreateIndexes> must be called later to bring the indexes into existence.

=item estimatedRows (optional)

If specified, the estimated maximum number of rows for the relation. This
information allows the creation of tables using storage engines that are
faster but require size estimates, such as MyISAM.

=item RETURN

Returns TRUE if the table was created, FALSE if it already existed in the
database.

=back

=cut

sub VerifyTable {
    # Get the parameters.
    my ($self, $table, $indexFlag, $estimatedRows) = @_;
    # Declare the return variable.
    my $retVal;
    # Only proceed if the table does NOT exist.
    if (! $self->{_dbh}->table_exists($table)) {
        # Attempt to create the table.
        $self->CreateTable($table, $indexFlag, $estimatedRows);
        # Denote we did so.
        $retVal = 1;
    }
    # Return the determination indicator.
    return $retVal;
}

=head3 CreateSearchIndex

    $erdb->CreateSearchIndex($objectName);

Check for a full-text search index on the specified entity or relationship object, and
if one is required, rebuild it.

=over 4

=item objectName

Name of the entity or relationship to be indexed.

=back

=cut

sub CreateSearchIndex {
    # Get the parameters.
    my ($self, $objectName) = @_;
    # Get the relation's entity/relationship structure.
    my $structure = $self->_GetStructure($objectName);
    # Get the database handle.
    my $dbh = $self->{_dbh};
    Trace("Checking for search fields in $objectName.") if T(3);
    # Check for a searchable fields list.
    if (exists $structure->{searchFields}) {
        # Here we know that we need to create a full-text search index.
        # Get an SQL-formatted field name list.
        my $fields = join(", ", _FixNames(@{$structure->{searchFields}}));
        # Create the index. If it already exists, it will be dropped.
        $dbh->create_index(tbl => $objectName, idx => "search_idx",
                           flds => $fields, kind => 'fulltext');
        Trace("Index created for $fields in $objectName.") if T(2);
    }
}

=head3 DropRelation

    $erdb->DropRelation($relationName);

Physically drop a relation from the database.

=over 4

=item relationName

Name of the relation to drop. If it does not exist, this method will have
no effect.

=back

=cut

sub DropRelation {
    # Get the parameters.
    my ($self, $relationName) = @_;
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Drop the relation. The method used here has no effect if the relation
    # does not exist.
    Trace("Invoking DB Kernel to drop $relationName.") if T(3);
    $dbh->drop_table(tbl => $relationName);
}

=head3 DumpRelations

    $erdb->DumpRelations($outputDirectory);

Write the contents of all the relations to tab-delimited files in the specified directory.
Each file will have the same name as the relation dumped, with an extension of DTX.

=over 4

=item outputDirectory

Name of the directory into which the relation files should be dumped.

=back

=cut

sub DumpRelations {
    # Get the parameters.
    my ($self, $outputDirectory) = @_;
    # Now we need to run through all the relations. First, we loop through the entities.
    my $metaData = $self->{_metaData};
    my $entities = $metaData->{Entities};
    for my $entityName (keys %{$entities}) {
        my $entityStructure = $entities->{$entityName};
        # Get the entity's relations.
        my $relationList = $entityStructure->{Relations};
        # Loop through the relations, dumping them.
        for my $relationName (keys %{$relationList}) {
            $self->_DumpRelation($outputDirectory, $relationName);
        }
    }
    # Next, we loop through the relationships.
    my $relationships = $metaData->{Relationships};
    for my $relationshipName (keys %{$relationships}) {
        # Dump this relationship's relation.
        $self->_DumpRelation($outputDirectory, $relationshipName);
    }
}

=head3 DumpTable

    my $count = $erdb->DumpTable($tableName, $directory);

Dump the specified table to the named directory. This will create a load
file having the same name as the relation with an extension of DTX. This
file can then be used to reload the table at a later date. If the table
does not exist, no action will be taken.

=over 4

=item tableName

Name of the table to dump.

=item directory

Name of the directory in which the dump file should be placed.

=item RETURN

Returns the number of records written.

=back

=cut

sub DumpTable {
    # Get the parameters.
    my ($self, $tableName, $directory) = @_;
    # Declare the return variable.
    my $retVal;
    # Insure the table name is valid.
    if (exists $self->{_metaData}->{RelationTable}->{$tableName}) {
        # Call the internal dumper.
        $retVal = $self->_DumpRelation($directory, $tableName);
    }
    # Return the result.
    return $retVal;
}


=head3 TypeDefault

    my $value = ERDB::TypeDefault($type);

Return the default value for fields of the specified type.

=over 4

=item type

Relevant type name.

=item RETURN

Returns a default value suitable for fields of the specified type.

=back

=cut

sub TypeDefault {
    # Get the parameters.
    my ($type) = @_;
    # Validate the type.
    if (! exists $TypeTable->{$type}) {
        Confess("TypeDefault called for invalid type \"$type\".")
    }
    # Return the result.
    return $TypeTable->{$type}->default();
}

=head3 LoadTables

    my $stats = $erdb->LoadTables($directoryName, $rebuild);

This method will load the database tables from a directory. The tables must
already have been created in the database. (This can be done by calling
L</CreateTables>.) The caller passes in a directory name; all of the relations
to be loaded must have a file in the directory with the same name as the
relation with a suffix of C<.dtx>. Each file must be a tab-delimited table of
encoded field values. Each line of the file will be loaded as a row of the
target relation table.

=over 4

=item directoryName

Name of the directory containing the relation files to be loaded.

=item rebuild

TRUE if the tables should be dropped and rebuilt, else FALSE.

=item RETURN

Returns a L</Stats> object describing the number of records read and a list of
the error messages.

=back

=cut

sub LoadTables {
    # Get the parameters.
    my ($self, $directoryName, $rebuild) = @_;
    # Start the timer.
    my $startTime = gettimeofday;
    # Clean any trailing slash from the directory name.
    $directoryName =~ s!/\\$!!;
    # Declare the return variable.
    my $retVal = Stats->new();
    # Get the relation names.
    my @relNames = $self->GetTableNames();
    for my $relationName (@relNames) {
        # Try to load this relation.
        my $result = $self->_LoadRelation($directoryName, $relationName,
                                          $rebuild);
        # Accumulate the statistics.
        $retVal->Accumulate($result);
    }
    # Add the duration of the load to the statistical object.
    $retVal->Add('duration', gettimeofday - $startTime);
    # Return the accumulated statistics.
    return $retVal;
}

=head3 CreateTables

    $erdb->CreateTables();

This method creates the tables for the database from the metadata structure
loaded by the constructor. It is expected this function will only be used on
rare occasions, when the user needs to start with an empty database. Otherwise,
the L</LoadTables> method can be used by itself with the truncate flag turned
on.

=cut

sub CreateTables {
    # Get the parameters.
    my ($self) = @_;
    # Get the relation names.
    my @relNames = $self->GetTableNames();
    # Loop through the relations.
    for my $relationName (@relNames) {
        # Create a table for this relation.
        $self->CreateTable($relationName, 1);
        Trace("Relation $relationName created.") if T(2);
    }
}

=head3 CreateTable

    $erdb->CreateTable($tableName, $indexFlag, $estimatedRows);

Create the table for a relation and optionally create its indexes.

=over 4

=item relationName

Name of the relation (which will also be the table name).

=item indexFlag

TRUE if the indexes for the relation should be created, else FALSE. If FALSE,
L</CreateIndexes> must be called later to bring the indexes into existence.

=item estimatedRows (optional)

If specified, the estimated maximum number of rows for the relation. This
information allows the creation of tables using storage engines that are
faster but require size estimates, such as MyISAM.

=back

=cut

sub CreateTable {
    # Get the parameters.
    my ($self, $relationName, $indexFlag, $estimatedRows) = @_;
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Determine whether or not the relation is primary.
    my $rootFlag = $self->_IsPrimary($relationName);
    # Create a list of the field data.
    my $fieldThing = $self->ComputeFieldString($relationName);
    # Insure the table is not already there.
    $dbh->drop_table(tbl => $self->{_quote} . $relationName . $self->{_quote});
    Trace("Table $relationName dropped.") if T(2);
    # Create an estimate of the table size.
    my $estimation;
    if ($estimatedRows) {
        $estimation = [$self->EstimateRowSize($relationName), $estimatedRows];
        Trace("$estimation->[1] rows of $estimation->[0] bytes each.") if T(3);
    }
    # Create the table.
    Trace("Creating table $relationName: $fieldThing") if T(2);
    $dbh->create_table(tbl => $self->{_quote} . $relationName . $self->{_quote}, flds => $fieldThing,
                       estimates => $estimation);
    Trace("Relation $relationName created in database.") if T(2);
    # If we want to build the indexes, we do it here. Note that the full-text
    # search index will not be built until the table has been loaded.
    if ($indexFlag) {
        $self->CreateIndex($relationName);
    }
}

=head3 ComputeFieldString

	my $fieldString = $erdb->ComputeFieldString($relationName);
	
Return the comma-delimited field definition string for a relation. This can be plugged directly into an SQL
C<CREATE> statement.

=over 4

=item relationName

Name of the relation whose field definition string is desired.

=item RETURN

Returns a string listing SQL field definitions, in the proper order, separated by commas.

=back

=cut

sub ComputeFieldString {
	# Get the parameters.
	my ($self, $relationName) = @_;
    # Get the relation data.
    my $relationData = $self->FindRelation($relationName);
    # Create a list of the field data.
    my @fieldList;
    for my $fieldData (@{$relationData->{Fields}}) {
        # Assemble the field name and type.
        my $fieldString = $self->_FieldString($fieldData);
        # Push the result into the field list.
        push @fieldList, $fieldString;
    }
    # Convert the field list into a comma-delimited string.
    my $retVal = join(', ', @fieldList);
    return $retVal;
}

=head3 VerifyFields

    $erdb->VerifyFields($relName, \@fieldList);

Run through the list of proposed field values, insuring that all of them are
valid.

=over 4

=item relName

Name of the relation for which the specified fields are destined.

=item fieldList

Reference to a list, in order, of the fields to be put into the relation.

=back

=cut

sub VerifyFields {
    # Get the parameters.
    my ($self, $relName, $fieldList) = @_;
    # Initialize the return value.
    my $retVal = 0;
    # Get the relation definition.
    my $relData = $self->FindRelation($relName);
    # Get the list of field descriptors.
    my $fieldThings = $relData->{Fields};
    my $fieldCount = scalar @{$fieldThings};
    # Loop through the two lists.
    for (my $i = 0; $i < $fieldCount; $i++) {
        # Get the descriptor and type of the current field.
        my $fieldThing = $fieldThings->[$i];
        my $fieldType = $TypeTable->{$fieldThing->{type}};
        Confess("Undefined field type $fieldThing->{type} in position $i ($fieldThing->{name}) of $relName.") if (! defined $fieldType);
        # Validate it.
        my $message = $fieldType->validate($fieldList->[$i]);
        if ($message) {
            # It's invalid. Generate an error.
            Confess("Error in field $i ($fieldThing->{name}) of $relName: $message");
        }
    }
    # Return a 0 value, for backward compatibility.
    return 0;
}

=head3 DigestFields

    $erdb->DigestFields($relName, $fieldList);

Prepare the fields of a relation for output to a load file.

=over 4

=item relName

Name of the relation to which the fields belong.

=item fieldList

List of field contents to be loaded into the relation.

=back

=cut
#: Return Type ;
sub DigestFields {
    # Get the parameters.
    my ($self, $relName, $fieldList) = @_;
    # Get the relation definition.
    my $relData = $self->FindRelation($relName);
    # Get the list of field descriptors.
    my $fieldTypes = $relData->{Fields};
    my $fieldCount = scalar @{$fieldTypes};
    # Loop through the two lists.
    for (my $i = 0; $i < $fieldCount; $i++) {
        # Get the type of the current field.
        my $fieldType = $fieldTypes->[$i]->{type};
        # Encode the field value in place.
        $fieldList->[$i] = $TypeTable->{$fieldType}->encode($fieldList->[$i], 1);
    }
}

=head3 EncodeField

    my $coding = $erdb->EncodeField($fieldName, $value);

Convert the specified value to the proper format for storing in the
specified database field. The field name should be specified in the
standard I<object(field)> format, e.g. C<Feature(id)> for the C<id> field
of the C<Feature> table.

=over 4

=item fieldName

Name of the field, specified in as an object name with the field name
in parentheses.

=item value

Value to encode for placement in the field.

=item RETURN

Coded value ready to put in the database. In most cases, this will be
identical to the original input.

=back

=cut

sub EncodeField {
    # Get the parameters.
    my ($self, $fieldName, $value) = @_;
    # Find the field type.
    my $fieldSpec = $self->_FindField($fieldName);
    my $retVal = encode($fieldSpec->{type}, $value);
    # Return the result.
    return $retVal;
}

=head3 encode

    my $coding = ERDB::encode($type, $value);

Encode a value of the specified type for storage in the database or for
use as a query parameter. Encoding is automatic for all ERDB methods except
when loading a table from a user-supplied load file or when processing
the parameters for a query filter string. This method can be used in
those situations to remedy the lack.

=over 4

=item type

Name of the incoming value's data type.

=item value

Value to encode into a string.

=item RETURN

Returns the encoded value.

=back

=cut

sub encode {
    # Get the parameters.
    my ($type, $value) = @_;
    # Get the type definition.
    my $typeData = $TypeTable->{$type};
    # Complain if it doesn't exist.
    Confess("Invalid data type \"$type\" specified in encoding.") if ! defined $typeData;
    # Encode the value.
    my $retVal = $typeData->encode($value);
    # Return the result.
    return $retVal;
}

=head3 DecodeField

    my $value = $erdb->DecodeField($fieldName, $coding);

Convert the stored coding of the specified field to the proper format for
use by the client program. This is essentially the inverse of
L</EncodeField>.

=over 4

=item fieldName

Name of the field, specified as an object name with the field name
in parentheses.

=item coding

Coded data from the database.

=item RETURN

Returns the original form of the coded data.

=back

=cut

sub DecodeField {
    # Get the parameters.
    my ($self, $fieldName, $coding) = @_;
    # Declare the return variable.
    my $retVal = $coding;
    # Get the field type.
    my $fieldSpec = $self->_FindField($fieldName);
    my $type = $fieldSpec->{type};
    Trace("Decoding field $fieldName of type $type.") if T(ERDBType => 3);
    # Process according to the type.
    $retVal = $TypeTable->{$type}->decode($coding);
    # Return the result.
    return $retVal;
}

=head3 DigestKey

    my $digested = ERDB::DigestKey($longString);

Return the digested value of a string. The digested value is a fixed
length (22 characters) MD5 checksum. It can be used as a more convenient
version of a symbolic key.

=over 4

=item longString

String to digest.

=item RETURN

Digested value of the string.

=back

=cut

sub DigestKey {
    # Allow object-based calls for backward compatability.
    shift if UNIVERSAL::isa($_[0], __PACKAGE__);
    # Get the parameters.
    my ($keyValue) = @_;
    # Compute the digest.
    my $retVal = md5_base64($keyValue);
    # Return the result.
    return $retVal;
}

=head3 CreateIndex

    $erdb->CreateIndex($relationName);

Create the indexes for a relation. If a table is being loaded from a large
source file (as is the case in L</LoadTable>), it is sometimes best to create
the indexes after the load. If that is the case, then L</CreateTable> should be
called with the index flag set to FALSE, and this method used after the load to
create the indexes for the table.

=cut

sub CreateIndex {
    # Get the parameters.
    my ($self, $relationName) = @_;
    # Get the relation's descriptor.
    my $relationData = $self->FindRelation($relationName);
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Now we need to create this relation's indexes. We do this by looping
    # through its index table.
    my $indexHash = $relationData->{Indexes};
    for my $indexName (keys %{$indexHash}) {
        my $indexData = $indexHash->{$indexName};
        # Get the index's field list.
        my @rawFields = @{$indexData->{IndexFields}};
        # Get a hash of the relation's field types.
        my %types = map { $_->{name} => $_->{type} } @{$relationData->{Fields}};
        # We need to check for partial-indexed fields so we can append a length limitation
        # for them. To do that, we need the relation's field list.
        my $relFields = $relationData->{Fields};
        for (my $i = 0; $i <= $#rawFields; $i++) {
            # Split the ordering suffix from the field name.
            my ($field, $suffix) = split(/\s+/, $rawFields[$i]);
            $suffix = "" if ! defined $suffix;
            # Get the field type.
            my $type = $types{$field};
            # Ask if it requires using prefix notation for the index.
            my $mod = $TypeTable->{$type}->indexMod();
            if (! defined($mod)) {
                Confess("Non-indexable type $type specified for index field in $relationName.");
            } elsif ($mod) {
                # Here we have an indexed field that requires a modification in order
                # to work. This means we need to insert it between the
                # field name and the ordering suffix. Note we make sure the
                # suffix is defined.
                $rawFields[$i] =  join(" ", $dbh->index_mod($self->{_quote} .
                    $field . $self->{_quote}, $mod), $suffix);
            } else {
                # Here we have a normal field, so we quote it.
                $rawFields[$i] = join(" ", $self->{_quote} . $field .
                    $self->{_quote}, $suffix);
            }
        }
        my @fieldList = _FixNames(@rawFields);
        my $flds = join(', ', @fieldList);
        # Get the index's uniqueness flag.
        my $unique = ($indexData->{primary} ? 'primary' : ($indexData->{unique} ? 'unique' : undef));
        # Create the index.
        my $rv = $dbh->create_index(idx => "$indexName$relationName", tbl => $self->{_quote} . $relationName . $self->{_quote},
                                    flds => $flds, kind => $unique);
        if ($rv) {
            Trace("Index created: $indexName for $relationName ($flds)") if T(1);
        } else {
            Confess("Error creating index $indexName for $relationName using ($flds): " .
                    $dbh->error_message());
        }
    }
}

=head3 SetTestEnvironment

    $erdb->SetTestEnvironment();

Denote that this is a test environment. Certain performance-enhancing
features may be disabled in a test environment.

=cut

sub SetTestEnvironment {
    # Get the parameters.
    my ($self) = @_;
    # Tell the database we're in test mode.
    $self->{_dbh}->test_mode();
}

=head3 dbName

    my $dbName = $erdb->dbName();

Return the physical name of the database currently attached to this object.

=cut

sub dbName {
    # Get the parameters.
    my ($self) = @_;
    # We'll return the database name in here.
    my $retVal;
    # Get the connection string.
    my $connect = $self->{_dbh}->{_connect};
    # Extract the database name.
    if ($connect =~ /dbname\=([^;])/) {
        $retVal = $1;
    }
    # Return the result.
    return $retVal;
}

=head3 FixEntity

    my $stats = $erdb->FixEntity($name);

This method scans an entity and insures that all of the instances
connect to an owning relationship instance. Any entity that does
not connect will be deleted.

=over 4

=item name

Name of the one-to-many relationship that owns the entity.

=item RETURN

Returns a L<Stats> object describing the scan results.

=back

=cut

sub FixEntity {
    # Get the parameters.
    my ($self, $name) = @_;
    # Create the statistics object to return.
    my $retVal = Stats->new();
    # Compute the name of the to-entity.
    my (undef, $toEntity) = $self->GetRelationshipEntities($name);
    # Loop through the relationship instances, memorizing to-keys.
    my %keys = map { $_ => 1 } $self->GetFlat($name, "", [], 'to-link');
    $retVal->Add("$name-keysRead" => scalar keys %keys);
    # Loop through the entity instances, checking the IDs against the
    # relationship.
    my $query = $self->Get($toEntity, "", []);
    while (my $row = $query->Fetch()) {
        # Get this instance's ID.
        my ($id) = $row->Value('id');
        $retVal->Add("$toEntity-rows" => 1);
        # Check the relationship.
        if (! $keys{$id}) {
            # Not found, so delete the entity instance.
            $retVal->Add("$name-KeyNotFound" => 1);
            my $subStats = $self->Delete($toEntity, $id);
            $retVal->Accumulate($subStats);
        }
    }
    # Return the statistics.
    return $retVal;
}

=head3 FixRelationship

    my $stats = $erdb->FixRelationship($name, $testOnly);

This method scans a relationship and insures that all of the
instances connect to valid entities on both sides. If any instance
fails to connect, it will be deleted. The process is fairly
memory-intensive.

=over 4

=item name

Name of the relationship to scan.

=item testOnly

If TRUE, then statistics will be accumulated but no deletions will be performed.

=item RETURN

Returns a L<Stats> object describing the scan results.

=back

=cut

sub FixRelationship {
    # Get the parameters.
    my ($self, $name, $testOnly) = @_;
    # Create the statistics object to return.
    my $retVal = Stats->new();
    # Compute the names of the entities on either side.
    my ($fromEntity, $toEntity) = $self->GetRelationshipEntities($name);
    my %entities = (from => $fromEntity, to => $toEntity);
    # Loop through the relationship, saving the from and to
    # entity ids.
    my %idHash = (from => {}, to => {});
    my $query = $self->Get($name, "", []);
    while (my $row = $query->Fetch()) {
        my ($from, $to) = $row->Values('from-link to-link');
        $idHash{from}{$from} = 1;
        $idHash{to}{$to} = 1;
        $retVal->Add("${name}In" => 1);
    }
    # Now verify that the entities exist. We process each direction
    # separately.
    for my $dir (qw(from to)) {
        my $entity = $entities{$dir};
        $retVal->Add("${name}dir" => 1);
        # Loop through the entity IDs in this direction.
        # We process them in batches of 50.
        my @idList = ();
        for my $id (sort keys %{$idHash{$dir}}) {
            $retVal->Add("key$name$dir" => 1);
            push @idList, $id;
            if (scalar(@idList) >= 50) {
                $self->_ProcessFixRelationshipBatch($retVal, $name, $entity, $dir, \@idList, $testOnly);
                @idList = ();
            }
        }
        # Process the residual batch (if any).
        if (@idList) {
        	$self->_ProcessFixRelationshipBatch($retVal, $name, $entity, $dir, \@idList, $testOnly);
        }
    }
    # Return the statistics object with the results.
    return $retVal;
}

# Utility method to process a batch for FixRelationship. The IDs are
# checked to see if they are valid. If they are not, then the relevant
# relationship rows are deleted.
sub _ProcessFixRelationshipBatch {
    # Get the parameters.
    my ($self, $stats, $name, $entity, $dir, $idList, $testOnly) = @_;
    # Construct a query to look up the entity IDs.
    my $n = scalar(@$idList);
    my $filter = "$entity(id) IN (" . join(", ", ('?') x $n) . ")";
    my %keysFound = map { $_ => 1 } $self->GetFlat($entity, $filter,
            $idList, 'id');
    $stats->Add("$entity-keyFound" => scalar keys %keysFound);
    $stats->Add("$entity-keyQuery" => 1);
    # Now we format a delete filter for any key we DIDN'T find.
    $filter = "$name($dir-link) = ?";
    # Loop through all the keys.
    for my $id (@$idList) {
        if (! $keysFound{$id}) {
            # Key was not found, so delete its relationship rows.
            $stats->Add("$entity-keyNotFound" => 1);
            if (! $testOnly) {
	            my $count = $self->DeleteLike($name, $filter, [$id]);
	            $stats->Add("$name-delete$dir" => $count);
            }
        }
    }
}

=head3 CleanRelationship

    my $stats = $erdb->CleanRelationship($relName, @fields);

Remove duplicate rows from a relationship. A row is duplicate if the from- and to-links
match and the zero or more specified additional fields also match.

=over 4

=item relName

Name of the relationship to clean.

=item fields

List of additional fields in the relationship to be used to determine whether or
not we have a duplicate row. The fields must be scalars and not that they cannot


=item RETURN

Returns a L<Stats> object describing what happened during the cleanup.

=back

=cut

sub CleanRelationship {
    # Get the parameters.
    my ($self, $relName, @fields) = @_;
    # Build the ORDER BY clause for the query. For best performance, the extra fields
    # should be those in the from-index, in order.
    my $clause = "$relName(from-link) = ? ORDER BY " . 
            join(", ", map { "$relName($_)" } (@fields, 'to-link'));
    # Create the return statistics object.
    my $retVal = Stats->new();
    # Get the relationship's full field list.
    my $fieldTable = $self->GetFieldTable($relName);
    my @allFields = keys %{$fieldTable};
    # Loop through the possible from-links.
    my ($fromEntity) = $self->GetRelationshipEntities($relName);
    my $idQry = $self->Get($fromEntity, "", []);
    while (my $idRow = $idQry->Fetch()) {
        my $fromID = $idRow->PrimaryValue('id');
        # We will create a list of delete requests. Each consists of a 3-tuple of a from-link,
        # a to-link, and a hash of other fields.
        my @deletes;
        # This is a list of insert-back requests. Each consists of a hash of field values.
        my @inserts;
        # Set up to loop through the relationship for this from-link value.
        my $qry = $self->Get($relName, $clause, [$fromID]);
        # Create a dummy key for the first row.
        my @key = ("", "", map { "" } @fields);
        # Remember its size.
        my $keylen = scalar @key;
        # Denote that the current key is not being deleted.
        my $deleteInProgress = 0;
        # Loop through the rows.
        while (my $row = $qry->Fetch()) {
            # Get the key for this row.
            my @key2 = $row->Values(['from-link', 'to-link', @fields]);
            $retVal->Add(rowsRead => 1);
            # Verify that they are different.
            my $equal = 1;
            for (my $i = 0; $i < $keylen && $equal; $i++) {
                if ($key[$i] ne $key2[$i]) {
                    $equal = 0;
                }
            }
            if (! $equal) {
                # Here the keys are different. No delete is needed.
                $deleteInProgress = 0;
                # Update the key.
                @key = @key2;
            } elsif ($deleteInProgress) {
                # Here the keys are the same, but this key set is already being deleted.
                # Record the fact in the statistics.
                $retVal->Add(extraDuplicates => 1);
            } else {
                # Here the keys are the same and we have not already scheduled them for
                # deletion. Save the information we need to delete the duplicates and
                # re-insert the current record.
                $retVal->Add(duplicateGroups => 1);
                my %delHash;
                for (my $i = 2; $i < $keylen; $i++) {
                    $delHash{$fields[$i - 2]} = $key2[$i];
                }
                push @deletes, [$key2[0], $key2[1], \%delHash];
                my %insHash;
                for my $field (@allFields) {
                    $insHash{$field} = $row->PrimaryValue($field);
                }
                push @inserts, \%insHash;
                # Denote a delete is in progress.
                $deleteInProgress = 1;
            }
        }
        # Now we have a list of deletions and insertions to perform. These are done outside the
        # loop so as not to mess up the query progress. We also expect them to be small in number
        # and capable of fitting in memory.
        for my $delete (@deletes) {
            $self->DeleteRow($relName, $delete->[0], $delete->[1], $delete->[2]);
            $retVal->Add(deletes => 1);
        }
        for my $insert (@inserts) {
            $self->InsertObject($relName, $insert);
            $retVal->Add(inserts => 1);
        }
    }
    # Return the statistics object.
    return $retVal;
}

=head2 Database Update Methods

=head3 BeginTran

    $erdb->BeginTran();

Start a database transaction.

=cut

sub BeginTran {
    my ($self) = @_;
    $self->{_dbh}->begin_tran();

}

=head3 CommitTran

    $erdb->CommitTran();

Commit an active database transaction.

=cut

sub CommitTran {
    my ($self) = @_;
    $self->{_dbh}->commit_tran();
}

=head3 RollbackTran

    $erdb->RollbackTran();

Roll back an active database transaction.

=cut

sub RollbackTran {
    my ($self) = @_;
    $self->{_dbh}->roll_tran();
}

=head3 UpdateField

    my $count = $erdb->UpdateField($fieldName, $oldValue, $newValue, $filter, $parms);

Update all occurrences of a specific field value to a new value. The number of
rows changed will be returned.

=over 4

=item fieldName

Name of the field in L</Standard Field Name Format>.

=item oldValue

Value to be modified. All occurrences of this value in the named field will be
replaced by the new value.

=item newValue

New value to be substituted for the old value when it's found.

=item filter

A standard ERDB filter clause. See L</Filter Clause>. The filter will be applied before
any substitutions take place. Note that the filter clause in this case must only
specify fields in the table containing fields.

=item parms

Reference to a list of parameter values in the filter. See L</Parameter List>.

=item RETURN

Returns the number of rows modified.

=back

=cut

sub UpdateField {
    # Get the parameters.
    my ($self, $fieldName, $oldValue, $newValue, $filter, $parms) = @_;
    # Get the object and field names from the field name parameter.
    my ($objectName, $realFieldName) = ERDB::ParseFieldName($fieldName);
    $realFieldName = _FixName($realFieldName);
    # Add the old value to the filter. Note we allow the possibility that no
    # filter was specified.
    my $realFilter = "$fieldName = ?";
    if ($filter) {
        $realFilter .= " AND $filter";
    }
    # Format the query filter.
    my ($suffix) = $self->_SetupSQL([$objectName], $realFilter);
    # Create the query. Since there is only one object name, the mapped-name
    # data is not necessary. Neither is the FROM clause.
    $suffix =~ s/^FROM.+WHERE\s+//;
    # Create the update statement.
    my $command = "UPDATE $self->{_quote}$objectName$self->{_quote} SET $self->{_quote}$realFieldName$self->{_quote} = ? WHERE $suffix";
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Add the old and new values to the parameter list. Note we allow the
    # possibility that there are no user-supplied parameters.
    my @params = ($newValue, $oldValue);
    if (defined $parms) {
        push @params, @{$parms};
    }
    # Execute the update.
    my $retVal = $dbh->SQL($command, 0, @params);
    # Make the funky zero a real zero.
    if ($retVal == 0) {
        $retVal = 0;
    }
    # Return the result.
    return $retVal;
}

=head3 InsertValue

    $erdb->InsertValue($entityID, $fieldName, $value);

This method will insert a new value into the database. The value must be one
associated with a secondary relation, since primary values cannot be inserted:
they occur exactly once. Secondary values, on the other hand, can be missing
or multiply-occurring.

=over 4

=item entityID

ID of the object that is to receive the new value.

=item fieldName

Field name for the new value in L</Standard Field Name Format>. This specifies
the entity name and the field name in a single string.

=item value

New value to be put in the field.

=back

=cut

sub InsertValue {
    # Get the parameters.
    my ($self, $entityID, $fieldName, $value) = @_;
    # Parse the entity name and the real field name.
    my ($entityName, $fieldTitle) = ERDB::ParseFieldName($fieldName);
    if (! defined $entityName) {
        Confess("Invalid field name specification \"$fieldName\" in InsertValue call.");
    } else {
        # Insure we are in an entity.
        if (!$self->IsEntity($entityName)) {
            Confess("$entityName is not a valid entity.");
        } else {
            my $entityData = $self->{_metaData}->{Entities}->{$entityName};
            # Find the relation containing this field.
            my $fieldHash = $entityData->{Fields};
            if (! exists $fieldHash->{$fieldTitle}) {
                Confess("$fieldTitle not found in $entityName.");
            } else {
                my $relation = $fieldHash->{$fieldTitle}->{relation};
                if ($relation eq $entityName) {
                    Confess("Cannot do InsertValue on primary field $fieldTitle of $entityName.");
                } else {
                    # Now we can create an INSERT statement.
                    my $dbh = $self->{_dbh};
                    my $fixedName = _FixName($fieldTitle);
                    my $statement = "INSERT INTO $self->{_quote}$relation$self->{_quote} (id, $self->{_quote}$fixedName$self->{_quote}) VALUES(?, ?)";
                    # Execute the command.
                    my $codedValue = $self->EncodeField($fieldName, $value);
                    $dbh->SQL($statement, 0, $entityID, $codedValue);
                }
            }
        }
    }
}

=head3 InsertObject

    $erdb->InsertObject($objectType, %fieldHash);
    
    or
    
    $erdb->InsertObject($objectType, \%fieldHash, %options);

Insert an object into the database. The object is defined by a type name and
then a hash of field names to values. All field values should be
represented by scalars. (Note that for relationships, the primary relation is
the B<only> relation.) Field values for the other relations comprising the
entity are always list references. For example, the following line inserts an
inactive PEG feature named C<fig|188.1.peg.1> with aliases C<ZP_00210270.1> and
C<gi|46206278>.

    $erdb->InsertObject('Feature', id => 'fig|188.1.peg.1', active => 0,
                        feature-type => 'peg', alias => ['ZP_00210270.1',
                        'gi|46206278']);

The next statement inserts a C<HasProperty> relationship between feature
C<fig|158879.1.peg.1> and property C<4> with an evidence URL of
C<http://seedu.uchicago.edu/query.cgi?article_id=142>.

    $erdb->InsertObject('HasProperty', 'from-link' => 'fig|158879.1.peg.1',
                        'to-link' => 4,
                        evidence => 'http://seedu.uchicago.edu/query.cgi?article_id=142');


=over 4

=item newObjectType

Type name of the object to insert.

=item fieldHash

Hash of field names to values. The field names should be specified in
L</Standard Field Name Format>. The default object name is the name of the
object being inserted. The values will be encoded for storage by this method.
Note that this can be an inline hash (for backward compatibility) or a hash
reference.

=item options

Hash of insert options. The current list of options is

=over 8

=item ignore (deprecated)

If TRUE, then duplicate-record errors will be suppressed. If the record already exists, the insert
will not take place.

=item dup

If specified, then duplicate-record errors will be suppressed. If C<ignore> is specified, duplicate
records will be discarded. If C<replace> is specified, duplicate records will replace the previous
version.

=item encoded

If TRUE, the fields are presumed to be already encoded for loading.

=back

=back

=cut

sub InsertObject {
    # Get the parameters.
    my ($self, $newObjectType, $first, @leftOvers) = @_;
    # Denote that so far we appear successful.
    my $retVal = 1;
    # Create the field hash.
    my ($fieldHash, $options);
    if (ref $first eq 'HASH') {
        $fieldHash = $first;
        $options = { @leftOvers }
    } else {
        $fieldHash = { $first, @leftOvers };
        $options = {}
    }
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Parse the field hash. We need to strip off the table names and
    # convert underscores in field names to hyphens. We will also
    # encode the values.
    my %fixedHash = $self->_SingleTableHash($fieldHash, $newObjectType, $options->{encoded});
    # Get the relation descriptor.
    my $relationData = $self->FindRelation($newObjectType);
    # We'll need a list of the fields being inserted, a list of the corresponding
    # values, and a list of fields the user forgot to specify.
    my @fieldNameList = ();
    my @valueList = ();
    my @missing = ();
    # Get the quote character.
    my $q = $self->{_quote};
    # Loop through the fields in the relation.
    for my $fieldDescriptor (@{$relationData->{Fields}}) {
        # Get the field name and save it. Note we need to fix it up so the hyphens
        # are converted to underscores.
        my $fieldName = $fieldDescriptor->{name};
        my $fixedName = _FixName($fieldName);
        # Look for the named field in the incoming structure. As a courtesy to the
        # caller, we accept both the real field name or the fixed-up one.
        if (exists $fixedHash{$fieldName}) {
            # Here we found the field. There is a special case for the ID that
            # we have to check for.
            if (! defined $fixedHash{$fieldName} && $fieldName eq 'id') {
                # This is the special case. The ID is going to be computed at
                # insert time, so we skip it.
            } else {
                # Normal case. Stash it in both lists.
                push @valueList, $fixedHash{$fieldName};
                push @fieldNameList, "$q$fixedName$q";
                Trace("Value for $fixedName is \"$fixedHash{$fieldName}\".") if T(SQL => 4);
            }
        } else {
            # Here the field is not present. Check for a default.
            my $default = $self->_Default($newObjectType, $fieldName);
            if (defined $default) {
                # Yes, we have a default. Push it into the two lists.
                push @valueList, $default;
                push @fieldNameList, "$q$fixedName$q";
                Trace("Default value for $fixedName is \"$default\".") if T(SQL => 4);
            } else {
                # No, this field is officially missing.
                push @missing, $fieldName;
            }
        }
    }
    # Only proceed if there are no missing fields.
    if (@missing > 0) {
        Trace("Relation $newObjectType for $newObjectType skipped due to missing fields: " .
            join(' ', @missing)) if T(1);
    } else {
        # Build the INSERT statement.
        my $command = "INSERT";
        if ($options->{ignore}) {
        	$command = "INSERT IGNORE";       	
        } elsif ($options->{dup}) {
        	if ($options->{dup} eq 'ignore') {
        		$command = "INSERT IGNORE";
        	} elsif ($options->{dup} eq 'replace') {
        		$command = "REPLACE";
        	}
        }
        my $statement = "$command INTO $q$newObjectType$q (" . join (', ', @fieldNameList) .
            ") VALUES (";
        # Create a marker list of the proper size and put it in the statement.
        my @markers = ();
        while (@markers < @fieldNameList) { push @markers, '?'; }
        $statement .= join(', ', @markers) . ")";
        # We have the insert statement, so prepare it.
        my $sth = $dbh->prepare_command($statement);
        Trace("Insert statement prepared: $statement") if T(Insert => 3);
        # Execute the INSERT statement with the specified parameter list.
        $retVal = $sth->execute(@valueList);
        if (!$retVal) {
            my $errorString = $sth->errstr();
            Confess("Error inserting into $newObjectType: $errorString");
        } else {
            Trace("Insert successful for $newObjectType.") if T(Insert => 3);
        }
    }
    # Is this object an entity?
    if ($self->IsEntity($newObjectType)) {
        # Yes. Check for secondary fields.
        my %fieldTuples = $self->GetSecondaryFields($newObjectType);
        # Loop through them, inserting their values (if any);
        for my $field (keys %fieldTuples) {
            # Get the value.
            my $values = $fieldHash->{$field};
            # Only proceed if it IS there.
            if (defined $values) {
                Trace("Inserting values for secondary field $field in $newObjectType.") if T(3);
                # Insure we have a list reference.
                if (ref $values ne 'ARRAY') {
                    $values = [$values];
                }
                # Loop through the values, inserting them.
                for my $value (@$values) {
                    $self->InsertValue($fieldHash->{id}, "$newObjectType($field)", $value);
                }
            }
        }
    }
    # Return a 1 for backward compatibility.
    return 1;
}

=head3 UpdateEntity

    $erdb->UpdateEntity($entityName, $id, %fields);
    
or
    
    my $ok = $erdb->UpdateEntity($entityName, $id, \%fields, $optional);

Update the values of an entity. This is an unprotected update, so it should only be
done if the database resides on a database server.

=over 4

=item entityName

Name of the entity to update. (This is the entity type.)

=item id

ID of the entity to update. If no entity exists with this ID, an error will be thrown.

=item fields

Hash mapping field names to their new values. All of the fields named
must be in the entity's primary relation, and they cannot any of them be the ID field.
Field names should be in the L</Standard Field Name Format>. The default object name in
this case is the entity name.

=item optional

If specified and TRUE, then the update is optional and will return TRUE if successful and FALSE
if the entity instance was not found. If this parameter is present, I<fields> must be a hash
reference and not a raw hash.

=back

=cut

sub UpdateEntity {
    # Get the parameters.
    my ($self, $entityName, $id, $first, @leftovers) = @_;
    # Get the field hash and optional-update flag.
    my ($fields, $optional);    
    if (ref $first eq 'HASH') {
        $fields = $first;
        $optional = $leftovers[0];
    } else {
        $fields = { $first, @leftovers };
    }
    # Fix up the field name hash.
    my @fieldList = keys %{$fields};
    # Verify that the fields exist.
    my $checker = $self->GetFieldTable($entityName);
    for my $field (@fieldList) {
        my $normalizedField = $field;
        $normalizedField =~ tr/_/-/;
        if ($normalizedField eq 'id') {
            Confess("Cannot update the ID field for entity $entityName.");
        } elsif ($checker->{$normalizedField}->{relation} ne $entityName) {
            Confess("Cannot find $field in primary relation of $entityName.");
        }
    }
    # Build the SQL statement.
    my @sets = ();
    my @valueList = ();
    for my $field (@fieldList) {
        push @sets, $self->{_quote} . _FixName($field) . $self->{_quote} . " = ?";
        my $value = $self->EncodeField("$entityName($field)", $fields->{$field});
        push @valueList, $value;
    }
    my $command = "UPDATE $self->{_quote}$entityName$self->{_quote} SET " . join(", ", @sets) . " WHERE id = ?";
    # Add the ID to the list of binding values.
    push @valueList, $id;
    # This will be the return value.
    my $retVal = 1;
    # Call SQL to do the work.
    my $rows = $self->{_dbh}->SQL($command, 0, @valueList);
    # Check for errors.
    if ($rows == 0) {
        if ($optional) {
            $retVal = 0;
        } else {
            Confess("Entity $id of type $entityName not found.");
        }
    }
    # Return the success indication.
    return $retVal;
}

=head3 Reconnect

    my $changeCount = $erdb->Reconnect($relName, $linkType, $oldID, $newID);

Move a relationship so it points to a new entity instance. All instances that reference
a specified ID will be updated to specify a new ID.

=over 4

=item relName

Name of the relationship to update.

=item linkType

C<from> to update the from-link. C<to> to update the to-link.

=item oldID

Old ID value to be changed.

=item new ID

New ID value to be substituted for the old one.

=item RETURN

Returns the number of rows updated.

=back

=cut

sub Reconnect {
    # Get the parameters.
    my ($self, $relName, $linkType, $oldID, $newID) = @_;
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Compute the link name.
    my $linkName = $linkType . "_link";
    # Create the update statement.
    my $stmt = "UPDATE $relName SET $linkName = ? WHERE $linkName = ?";
    # Apply the update.
    my $retVal = $dbh->SQL($stmt, 0, $newID, $oldID);
    # Return the number of rows changed.
    return $retVal;
}

=head3 MoveEntity

    my $stats = $erdb->MoveEntity($entityName, $oldID, $newID);

Transfer all relationship records pointing to a specified entity instance so they
point to a different entity instance. This requires calling L</Reconnect> on all
the relationships that connect to the entity.

=over 4

=item entityName

Name of the relevant entity type.

=item oldID

ID of the obsolete entity instance. All relationship records containing this ID will be
changed.

=item newID

ID of the new entity instance. The relationship records containing the old ID will have
this ID substituted for it.

=item RETURN

Returns a L<Stats> object describing the updates.

=back

=cut

sub MoveEntity {
    # Get the parameters.
    my ($self, $entityName, $oldID, $newID) = @_;
    # Create the statistics object.
    my $retVal = Stats->new();
    # Find the entity's connecting relationships.
    my ($froms, $tos) = $self->GetConnectingRelationshipData($entityName);
    # Process the relationship directions.
    my %dirHash = (from => $froms, to => $tos);
    for my $dir (keys %dirHash) {
        # Reconnect the relationships in this direction.
        for my $relName (keys %{$dirHash{$dir}}) {
            my $changes = $self->Reconnect($relName, $dir, $oldID, $newID);
            $retVal->Add("$dir-$relName" => $changes);
        }
    }
    # Return the statistics.
    return $retVal;
}

=head3 Delete

    my $stats = $erdb->Delete($entityName, $objectID, %options);

Delete an entity instance from the database. The instance is deleted along with
all entity and relationship instances dependent on it. The definition of
I<dependence> is recursive.

An object is always dependent on itself. An object is dependent if it is a
1-to-many or many-to-many relationship connected to a dependent entity or if it
is the "to" entity connected to a 1-to-many dependent relationship.

The idea here is to delete an entity and everything related to it. Because this
is so dangerous, and option is provided to simply trace the resulting delete
calls so you can verify the action before performing the delete.

=over 4

=item entityName

Name of the entity type for the instance being deleted.

=item objectID

ID of the entity instance to be deleted.

=item options

A hash detailing the options for this delete operation.

=item RETURN

Returns a statistics object indicating how many records of each particular table were
deleted.

=back

The permissible options for this method are as follows.

=over 4

=item testMode

If TRUE, then the delete statements will be traced, but no changes will be made
to the database. If C<dump>, then the data is dumped to load files instead
of being traced.

=item keepRoot

If TRUE, then the entity instances will not be deleted, only the dependent
records.

=item print

If TRUE, then all of the DELETE statements will be written to the standard
output.

=item onlyRoot

If TRUE, then the entity instance will be deleted, but none of the attached
data will be removed (the opposite of C<keepRoot>).

=back

=cut

sub Delete {
    # Get the parameters.
    my ($self, $entityName, $objectID, %options) = @_;
    # Declare the return variable.
    my $retVal = Stats->new();
    # Encode the object ID.
    my $idParameter = $self->EncodeField("$entityName(id)", $objectID);
    # Get the DBKernel object.
    my $db = $self->{_dbh};
    # We're going to generate all the paths branching out from the starting
    # entity. One of the things we have to be careful about is preventing loops.
    # We'll use a hash to determine if we've hit a loop.
    my %alreadyFound = ();
    # These next lists will serve as our result stack. We start by pushing
    # object lists onto the stack, and then popping them off to do the deletes.
    # This means the deletes will start with the longer paths before getting to
    # the shorter ones. That, in turn, makes sure we don't delete records that
    # might be needed to forge relationships back to the original item. We have
    # two lists-- one for TO-relationships, and one for FROM-relationships and
    # entities.
    my @fromPathList = ();
    my @toPathList = ();
    # This final list is used to remember what work still needs to be done. We
    # push paths onto the list, then pop them off to extend the paths. We prime
    # it with the starting point. Note that we will work hard to insure that the
    # last item on a path in the to-do list is always an entity.
    my @todoList = ([$entityName]);
    while (@todoList) {
        # Get the current path.
        my $current = pop @todoList;
        # Copy it into a list.
        my @stackedPath = @{$current};
        # Pull off the last item on the path. It will always be an entity.
        my $myEntityName = pop @stackedPath;
        Trace("Processing entity $myEntityName with path (" . join(", ", @stackedPath) . ").") if T(Delete => 3);
        # Add it to the alreadyFound list.
        $alreadyFound{$myEntityName} = 1;
        # Figure out if we need to delete this entity.
        if ($myEntityName ne $entityName || ! $options{keepRoot}) {
            # Get the entity data.
            my $entityData = $self->_GetStructure($myEntityName);
            # Loop through the entity's relations. A DELETE command will be
            # needed for each of them.
            my $relations = $entityData->{Relations};
            Trace("Recording delete of relations for $myEntityName.") if T(Delete => 3);
            for my $relation (keys %{$relations}) {
                my @augmentedList = (@stackedPath, $relation);
                push @fromPathList, \@augmentedList;
            }
        }
        # Now we need to look for relationships connected to this entity. We skip
        # this if "onlyRoot" is specified.
        if (! $options{onlyRoot}) {
            my $relationshipList = $self->{_metaData}->{Relationships};
            for my $relationshipName (keys %{$relationshipList}) {
                my $relationship = $relationshipList->{$relationshipName};
                # Check the FROM field. We're only interested if it's us.
                if ($relationship->{from} eq $myEntityName) {
                    Trace("Relationship $relationshipName found from $myEntityName.") if T(Delete => 3);
                    # Add the path to this relationship.
                    my @augmentedList = (@stackedPath, $myEntityName, $relationshipName);
                    push @fromPathList, \@augmentedList;
                    # Check the arity. If it's MM or loose, we're done. If it's
                    # 1M and the target hasn't been seen yet, we want to
                    # stack the entity for future processing.
                    if ($relationship->{arity} eq '1M' && ! $relationship->{loose}) {
                        my $toEntity = $relationship->{to};
                        if (! exists $alreadyFound{$toEntity}) {
                            # Here we have a new entity that's dependent on
                            # the current entity, so we need to stack it.
                            Trace("Stacking request for $toEntity.") if T(Delete => 3);
                            my @stackList = (@augmentedList, $toEntity);
                            push @todoList, \@stackList;
                        } else {
                            Trace("$toEntity ignored because it occurred previously.") if T(Delete => 3);
                        }
                    }
                }
                # Now check the TO field. In this case only the relationship needs
                # deletion, and only if it's not already in the path.
                if ($relationship->{to} eq $myEntityName) {
                    Trace("Relationship $relationshipName found to $myEntityName.") if T(Delete => 3);
                    if (scalar(grep { $_ eq $relationshipName } @stackedPath) != 0) {
                        Trace("$relationshipName ignored because it's already in the path.") if T(Delete => 3);
                    } else {
                        my @augmentedList = (@stackedPath, $myEntityName, $relationshipName);
                        push @toPathList, \@augmentedList;
                    }
                }
            }
        }
    }
    # We need to make two passes. The first is through the to-list, and
    # the second through the from-list. The from-list is second because
    # the to-list may need to pass through some of the entities the
    # from-list would delete.
    my %stackList = ( from_link => \@fromPathList, to_link => \@toPathList );
    # Now it's time to do the deletes. We do it in two passes.
    for my $keyName ('to_link', 'from_link') {
        # Get the list for this key.
        my @pathList = @{$stackList{$keyName}};
        Trace(scalar(@pathList) . " entries in path list for $keyName.") if T(Delete => 3);
        # Loop through this list.
        while (my $path = pop @pathList) {
            # Get the table whose rows are to be deleted.
            my @pathTables = @{$path};
            Trace("Processing delete path (" . join(", ", @pathTables) . ").") if T(Delete => 3);
            # Get ready for the DELETE statement. First we need the table being
            # deleted.
            my $target = $pathTables[$#pathTables];
            # We start with the WHERE. The first thing is the ID field from the starting 
            # table. That starting table will either be the entity relation or one of 
            # the entity's sub-relations.
            my $stmt = " WHERE $self->{_quote}$pathTables[0]$self->{_quote}.id = ?";
            # Now we run through the remaining entities in the path, connecting them up.
            for (my $i = 1; $i <= $#pathTables; $i += 2) {
                # Connect the current relationship to the preceding entity.
                my ($entity, $rel) = @pathTables[$i-1,$i];
                if ($i + 1 <= $#pathTables) {
                    # Here there's a next entity, so connect from the relationship's from-link
                    # and through its to-link.
                    $stmt .= " AND $self->{_quote}$entity$self->{_quote}.id = $self->{_quote}$rel$self->{_quote}.from_link";
                    my $entity2 = $pathTables[$i+1];
                    $stmt .= " AND $self->{_quote}$rel$self->{_quote}.to_link = $self->{_quote}$entity2$self->{_quote}.id";
                } else {
                    # Here theres no next entity, so we connect according to the style of the path.
                    $stmt .= " AND $self->{_quote}$entity$self->{_quote}.id = $self->{_quote}$rel$self->{_quote}.$keyName";
                }
            }
            # Now we have the WHERE clause of our desired DELETE statement.
            if ($options{testMode} eq 'dump') {
                # Here the user wants to dump the data without deleting it.
                # First we get the data.
                $stmt = "SELECT $self->{_quote}$target$self->{_quote}.* FROM " .
                    join(", ", map { $self->{_quote} . $_ . $self->{_quote} } @pathTables) .
                    $stmt;
                Trace("Executing dump from $target using '$idParameter': $stmt.") if T(Delete => 3);
                my $rows = $db->SQL($stmt, 0, $idParameter);
                # Compute the number of rows read.
                my $count = scalar @$rows;
                # If we found any rows, dump them.
                if ($count > 0) {
                    # Open the dump file.
                    my $fileName = $self->LoadDirectory() . "/$target.dtx";
                    my $oh = Tracer::Open(undef, ">>$fileName");
                    # Write the rows.
                    for my $row (@$rows) {
                        my $line = join("\t", @$row);
                        print $oh "$line\n";
                        $retVal->Add("rows-$target" => 1);
                        $retVal->Add("data-$target" => length $line);
                    }
                    # Close the file.
                    close $oh;
                }
            } elsif ($options{testMode}) {
                # Here the user wants to trace without executing.
                $stmt = $db->SetUsing(@pathTables) . $stmt;
                Trace($stmt) if T(0);
            } else {
                # Here we can delete. Note that the SQL method dies with a confession
                # if an error occurs, so we just go ahead and do it without handling
                # errors afterward.
                $stmt = $db->SetUsing(@pathTables) . $stmt;
                Trace("Executing delete from $target using '$idParameter': $stmt.") if T(Delete => 3);
                if ($options{'print'}) {
                    print "Deleting using '$idParameter': $stmt\n";
                }
                my $rv = $db->SQL($stmt, 0, $idParameter);
                # Accumulate the statistics for this delete. The only rows deleted
                # are from the target table, so we use its name to record the
                # statistic.
                $retVal->Add("delete-$target", $rv);
            }
        }
    }
    # Return the result.
    return $retVal;
}

=head3 Disconnect

    my $count = $erdb->Disconnect($relationshipName, $originEntityName, $originEntityID);

Disconnect an entity instance from all the objects to which it is related via
a specific relationship. This will delete each relationship instance that
connects to the specified entity.

=over 4

=item relationshipName

Name of the relationship whose instances are to be deleted.

=item originEntityName

Name of the entity that is to be disconnected.

=item originEntityID

ID of the entity that is to be disconnected.

=item RETURN

Returns the number of rows deleted.

=back

=cut

sub Disconnect {
    # Get the parameters.
    my ($self, $relationshipName, $originEntityName, $originEntityID) = @_;
    # Initialize the return count.
    my $retVal = 0;
    # Encode the entity ID.
    my $idParameter = $self->EncodeField("$originEntityName(id)", $originEntityID);
    # Get the relationship descriptor.
    my $structure = $self->_GetStructure($relationshipName);
    # Insure we have a relationship.
    if (! exists $structure->{from}) {
        Confess("$relationshipName is not a relationship in the database.");
    } else {
        # Get the database handle.
        my $dbh = $self->{_dbh};
        # We'll set this value to 1 if we find our entity.
        my $found = 0;
        # Loop through the ends of the relationship.
        for my $dir ('from', 'to') {
            if ($structure->{$dir} eq $originEntityName) {
                $found = 1;
                # Here we want to delete all relationship instances on this side of the
                # entity instance.
                Trace("Disconnecting in $dir direction with ID \"$idParameter\".") if T(3);
                # We do this delete in batches to keep it from dragging down the
                # server.
                my $limitClause = ($ERDBExtras::delete_limit ? "LIMIT $ERDBExtras::delete_limit" : "");
                my $done = 0;
                while (! $done) {
                    # Do the delete.
                    my $rows = $dbh->SQL("DELETE FROM $self->{_quote}$relationshipName$self->{_quote} WHERE ${dir}_link = ? $limitClause", 0, $idParameter);
                    $retVal += $rows;
                    # See if we're done. We're done if no rows were found or the delete is unlimited.
                    $done = ($rows == 0 || ! $limitClause);
                }
            }
        }
        # Insure we found the entity on at least one end.
        if (! $found) {
            Confess("Entity \"$originEntityName\" does not use $relationshipName.");
        }
        # Return the count.
        return $retVal;
    }
}

=head3 DeleteRow

    $erdb->DeleteRow($relationshipName, $fromLink, $toLink, \%values);

Delete a row from a relationship. In most cases, only the from-link and to-link are
needed; however, for relationships with intersection data values can be specified
for the other fields using a hash.

=over 4

=item relationshipName

Name of the relationship from which the row is to be deleted.

=item fromLink

ID of the entity instance in the From direction.

=item toLink

ID of the entity instance in the To direction.

=item values

Reference to a hash of other values to be used for filtering the delete.

=back

=cut

sub DeleteRow {
    # Get the parameters.
    my ($self, $relationshipName, $fromLink, $toLink, $values) = @_;
    # Create a hash of all the filter information.
    my %filter = ('from-link' => $fromLink, 'to-link' => $toLink);
    if (defined $values) {
        for my $key (keys %{$values}) {
            $filter{$key} = $values->{$key};
        }
    }
    # Build an SQL statement out of the hash.
    my @filters = ();
    my @parms = ();
    for my $key (keys %filter) {
        my ($keyTable, $keyName) = ERDB::ParseFieldName($key, $relationshipName);
        push @filters, $self->{_quote} . _FixName($keyName) . $self->{_quote} . " = ?";
        push @parms, $self->EncodeField("$keyTable($keyName)", $filter{$key});
    }
    Trace("Parms for delete row are " . join(", ", map { "\"$_\"" } @parms) . ".") if T(SQL => 4);
    my $command = "DELETE FROM $self->{_quote}$relationshipName$self->{_quote} WHERE " .
                  join(" AND ", @filters);
    # Execute it.
    my $dbh = $self->{_dbh};
    $dbh->SQL($command, undef, @parms);
}

=head3 DeleteLike

    my $deleteCount = $erdb->DeleteLike($relName, $filter, \@parms);

Delete all the relationship rows that satisfy a particular filter condition.
Unlike a normal filter, only fields from the relationship itself can be used.

=over 4

=item relName

Name of the relationship whose records are to be deleted.

=item filter

A filter clause for the delete query. See L</Filter Clause>.

=item parms

Reference to a list of parameters for the filter clause. See L</Parameter List>.

=item RETURN

Returns a count of the number of rows deleted.

=back

=cut

sub DeleteLike {
    # Get the parameters.
    my ($self, $objectName, $filter, $parms) = @_;
    # Declare the return variable.
    my $retVal;
    # Insure the parms argument is an array reference if the caller left it off.
    if (! defined($parms)) {
        $parms = [];
    }
    # Insure we have a relationship. The main reason for this is if we delete an entity
    # instance we have to yank out a bunch of other stuff with it.
    if ($self->IsEntity($objectName)) {
        Confess("Cannot use DeleteLike on $objectName, because it is not a relationship.");
    } else {
        # Create the SQL command suffix to get the desierd records.
        my ($suffix) = $self->_SetupSQL([$objectName], $filter);
        # Convert it to a DELETE command.
        my $command = "DELETE $suffix";
        # Execute the command.
        my $dbh = $self->{_dbh};
        my $result = $dbh->SQL($command, 0, @{$parms});
        # Check the results. Note we convert the "0D0" result to a real zero.
        # A failure causes an abnormal termination, so the caller isn't going to
        # worry about it.
        if (! defined $result) {
            Confess("Error deleting from $objectName: " . $dbh->errstr());
        } elsif ($result == 0) {
            $retVal = 0;
        } else {
            $retVal = $result;
        }
    }
    # Return the result count.
    return $retVal;
}

=head3 DeleteValue

    my $numDeleted = $erdb->DeleteValue($entityName, $id, $fieldName, $fieldValue);

Delete secondary field values from the database. This method can be used to
delete all values of a specified field for a particular entity instance, or only
a single value.

Secondary fields are stored in two-column relations separate from an entity's
primary table, and as a result a secondary field can legitimately have no value
or multiple values. Therefore, it makes sense to talk about deleting secondary
fields where it would not make sense for primary fields.

=over 4

=item id

ID of the entity instance to be processed. If the instance is not found, this
method will have no effect. If C<undef> is specified, all values for all of
the entity instances will be deleted.

=item fieldName

Name of the field whose values are to be deleted, in L</Standard Field Name Format>.

=item fieldValue (optional)

Value to be deleted. If not specified, then all values of the specified field
will be deleted for the entity instance. If specified, then only the values
which match this parameter will be deleted.

=item RETURN

Returns the number of rows deleted.

=back

=cut

sub DeleteValue {
    # Get the parameters.
    my ($self, $entityName, $id, $fieldName, $fieldValue) = @_;
    # Declare the return value.
    my $retVal = 0;
    # We need to set up an SQL command to do the deletion. First, we
    # find the name of the field's relation.
    my $table = $self->GetFieldTable($entityName);
    # Now we need some data about this field.
    my $field = $table->{$fieldName};
    my $relation = $field->{relation};
    # Make sure this is a secondary field.
    if ($relation eq $entityName) {
        Confess("Cannot delete values of $fieldName for $entityName.");
    } else {
        # Set up the SQL command to delete all values.
        my $sql = "DELETE FROM $self->{_quote}$relation$self->{_quote}";
        # Build the filter.
        my @filters = ();
        my @parms = ();
        # Check for a filter by ID.
        if (defined $id) {
            push @filters, "id = ?";
            push @parms, $self->EncodeField("$entityName(id)", $id);
        }
        # Check for a filter by value.
        if (defined $fieldValue) {
            push @filters, $self->{_quote} . _FixName($fieldName) . $self->{_quote} . " = ?";
            push @parms, encode($field->{type}, $fieldValue);
        }
        # Append the filters to the command.
        if (@filters) {
            $sql .= " WHERE " . join(" AND ", @filters);
        }
        # Execute the command.
        my $dbh = $self->{_dbh};
        $retVal = $dbh->SQL($sql, 0, @parms);
    }
    # Return the result.
    return $retVal;
}


=head2 Data Mining Methods

=head3 GetUsefulCrossValues

    my @attrNames = $sprout->GetUsefulCrossValues($sourceEntity, $relationship);

Return a list of the useful attributes that would be returned by a B<Cross> call
from an entity of the source entity type through the specified relationship.
This means it will return the fields of the target entity type and the
intersection data fields in the relationship. Only primary table fields are
returned. In other words, the field names returned will be for fields where
there is always one and only one value.

=over 4

=item sourceEntity

Name of the entity from which the relationship crossing will start.

=item relationship

Name of the relationship being crossed.

=item RETURN

Returns a list of field names in L</Standard Field Name Format>.

=back

=cut

sub GetUsefulCrossValues {
    # Get the parameters.
    my ($self, $sourceEntity, $relationship) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Determine the target entity for the relationship. This is whichever entity
    # is not the source entity. So, if the source entity is the FROM, we'll get
    # the name of the TO, and vice versa.
    my $relStructure = $self->_GetStructure($relationship);
    my $targetEntityType = ($relStructure->{from} eq $sourceEntity ? "to" : "from");
    my $targetEntity = $relStructure->{$targetEntityType};
    # Get the field table for the entity.
    my $entityFields = $self->GetFieldTable($targetEntity);
    # The field table is a hash. The hash key is the field name. The hash value
    # is a structure. For the entity fields, the key aspect of the target
    # structure is that the {relation} value must match the entity name.
    my @fieldList = map { "$targetEntity($_)" } grep { $entityFields->{$_}->{relation} eq $targetEntity }
                        keys %{$entityFields};
    # Push the fields found onto the return variable.
    push @retVal, sort @fieldList;
    # Get the field table for the relationship.
    my $relationshipFields = $self->GetFieldTable($relationship);
    # Here we have a different rule. We want all the fields other than
    # "from-link" and "to-link". This may end up being an empty set.
    my @fieldList2 = map { "$relationship($_)" } grep { $_ ne "from-link" && $_ ne "to-link" }
                        keys %{$relationshipFields};
    # Push these onto the return list.
    push @retVal, sort @fieldList2;
    # Return the result.
    return @retVal;
}

=head3 FindColumn

    my $colIndex = ERDB::FindColumn($headerLine, $columnIdentifier);

Return the location a desired column in a data mining header line. The data
mining header line is a tab-separated list of column names. The column
identifier is either the numerical index of a column or the actual column
name.

=over 4

=item headerLine

The header line from a data mining command, which consists of a tab-separated
list of column names.

=item columnIdentifier

Either the ordinal number of the desired column (1-based), or the name of the
desired column.

=item RETURN

Returns the array index (0-based) of the desired column.

=back

=cut

sub FindColumn {
    # Get the parameters.
    my ($headerLine, $columnIdentifier) = @_;
    # Declare the return variable.
    my $retVal;
    # Split the header line into column names.
    my @headers = ParseColumns($headerLine);
    # Determine whether we have a number or a name.
    if ($columnIdentifier =~ /^\d+$/) {
        # Here we have a number. Subtract 1 and validate the result.
        $retVal = $columnIdentifier - 1;
        if ($retVal < 0 || $retVal > $#headers) {
            Confess("Invalid column identifer \"$columnIdentifier\": value out of range.");
        }
    } else {
        # Here we have a name. We need to find it in the list.
        for (my $i = 0; $i <= $#headers && ! defined($retVal); $i++) {
            if ($headers[$i] eq $columnIdentifier) {
                $retVal = $i;
            }
        }
        if (! defined($retVal)) {
            Confess("Invalid column identifier \"$columnIdentifier\": value not found.");
        }
    }
    # Return the result.
    return $retVal;
}

=head3 ParseColumns

    my @columns = ERDB::ParseColumns($line);

Convert the specified data line to a list of columns.

=over 4

=item line

A data mining input, consisting of a tab-separated list of columns terminated by a
new-line.

=item RETURN

Returns a list consisting of the column values.

=back

=cut

sub ParseColumns {
    # Get the parameters.
    my ($line) = @_;
    # Chop off the line-end.
    chomp $line;
    # Split it into a list.
    my @retVal = split(/\t/, $line);
    # Return the result.
    return @retVal;
}

=head2 Virtual Methods

=head3 CleanKeywords

    my $cleanedString = $erdb->CleanKeywords($searchExpression);

Clean up a search expression or keyword list. This is a virtual method that may
be overridden by the subclass. The base-class method removes extra spaces
and converts everything to lower case.

=over 4

=item searchExpression

Search expression or keyword list to clean. Note that a search expression may
contain boolean operators which need to be preserved. This includes leading
minus signs.

=item RETURN

Cleaned expression or keyword list.

=back

=cut

sub CleanKeywords {
    # Get the parameters.
    my ($self, $searchExpression) = @_;
    # Lower-case the expression and copy it into the return variable. Note that we insure we
    # don't accidentally end up with an undefined value.
    my $retVal = lc($searchExpression || "");
    # Remove extra spaces.
    $retVal =~ s/\s+/ /g;
    $retVal =~ s/(^\s+)|(\s+$)//g;
    # Return the result.
    return $retVal;
}

=head3 GetSourceObject

    my $source = $erdb->GetSourceObject();

Return the object to be used in creating load files for this database. This is
only the default source object. Loaders have the option of overriding the chosen
source object when constructing the L</ERDBLoadGroup> objects.

=cut

sub GetSourceObject {
    Confess("Pure virtual GetSourceObject called.");
}

=head3 SectionList

    my @sections = $erdb->SectionList();

Return a list of the names for the different data sections used when loading this database.
The default is a single string, in which case there is only one section representing the
entire database.

=cut

sub SectionList {
    # Get the parameters.
    my ($self) = @_;
    # Return the section list.
    return ("all");
}

=head3 GlobalSection

    my $flag = $sap->GlobalSection($name);

Return TRUE if the specified section name is the global section, FALSE
otherwise.

=over 4

=item name

Section name to test.

=item RETURN

Returns TRUE if the parameter is the string C<Global>, else FALSE.

=back

=cut

sub GlobalSection {
    # Get the parameters.
    my ($self, $name) = @_;
    # Return the result.
    return ($name eq 'Global');
}

=head3 PreferredName

    my $name = $erdb->PreferredName();

Return the variable name to use for this database when generating code. The default
is C<erdb>.

=cut

sub PreferredName {
    return 'erdb';
}

=head3 Loader

    my $groupLoader = $erdb->Loader($groupName, $options);

Return an L</ERDBLoadGroup> object for the specified load group. This method is used
by L<ERDBGenerator.pl> to create the load group objects. If you are not using
L<ERDBGenerator.pl>, you don't need to override this method.

=over 4

=item groupName

Name of the load group whose object is to be returned. The group name is
guaranteed to be a single word with only the first letter capitalized.

=item options

Reference to a hash of command-line options.

=item RETURN

Returns an L</ERDBLoadGroup> object that can be used to process the specified load group
for this database.

=back

=cut

sub Loader {
    # Get the parameters.
    my ($self, $groupName, $options) = @_;

}

=head3 LoadGroupList

    my @groups = $erdb->LoadGroupList();

Returns a list of the names for this database's load groups. This method is used
by L<ERDBGenerator.pl> when the user wishes to load all table groups. The default
is a single group called 'All' that loads everything.

=cut

sub LoadGroupList {
    # Return the list.
    return qw(All);
}

=head3 LoadDirectory

    my $dirName = $erdb->LoadDirectory();

Return the name of the directory in which load files are kept. The default is
the FIG temporary directory, which is a really bad choice, but it's always there.

=cut

sub LoadDirectory {
    # Get the parameters.
    my ($self) = @_;
    # Return the directory name.
    return $self->{loadDirectory} || $ERDBExtras::temp;
}

=head3 Cleanup

    $erdb->Cleanup();

Clean up data structures. This method is called at the end of each
section when loading the database. The subclass can use it to free up
memory that may have accumulated due to caching or accumulation of hash
structures. The default method does nothing.

=cut

sub Cleanup { }

=head3 UseInternalDBD

    my $flag = $erdb->UseInternalDBD();

Return TRUE if this database should be allowed to use an internal DBD.
The internal DBD is stored in the C<_metadata> table, which is created
when the database is loaded. The default is TRUE.

=cut

sub UseInternalDBD {
    return 1;
}


=head2 Internal Utility Methods

=head3 _FieldString

    my $fieldString = $erdb->_FieldString($descriptor);

Compute the definition string for a particular field from its descriptor
in the relation table.

=over 4

=item descriptor

Field descriptor containing the field's name and type.

=item RETURN

Returns the SQL declaration string for the field.

=back

=cut

sub _FieldString {
    # Get the parameters.
    my ($self, $descriptor) = @_;
    # Get the fixed-up name.
    my $fieldName = _FixName($descriptor->{name});
    # Compute the SQL type.
    my $fieldType = $self->_TypeString($descriptor);
    # Check for nulls. We need to insure that the field is null-capable if it
    # specifies nulls and that the nullability flag is prepared for the
    # declaration.
    my $nullFlag = "NOT NULL";
    if ($descriptor->{null}) {
        $nullFlag = "";
        if (! $TypeTable->{$descriptor->{type}}->nullable()) {
            Confess("Invalid DBD: field \"$fieldName\" is null, but not of a nullable type.");
        }
    }
    # Assemble the result.
    my $retVal = "$self->{_quote}$fieldName$self->{_quote} $fieldType $nullFlag";
    # Return the result.
    return $retVal;
}

=head3 _TypeString

    my $typeString = $erdb->_TypeString($descriptor);

Determine the SQL type corresponding to a field from its descriptor in the
relation table.

=over 4

=item descriptor

Field descriptor containing the field's name and type.

=item RETURN

Returns the SQL type string for the field.

=back

=cut

sub _TypeString {
    # Get the parameters.
    my ($self, $descriptor) = @_;
    # Compute the SQL type.
    my $typeDescriptor = $TypeTable->{$descriptor->{type}};
    my $retVal = $typeDescriptor->sqlType($self->{_dbh});
    # Return it.
    return $retVal;
}

=head3 _Default

    my $defaultValue = $self->_Default($objectName, $fieldName);

Return the default value for the specified field in the specified object.
If no default value is specified, an undefined value will be returned.

=over 4

=item objectName

Name of the object containing the field.

=item fieldName

Name of the field whose default value is desired.

=item RETURN

Returns the default value for the specified field, or an undefined value if
no default is available.

=back

=cut

sub _Default {
    # Get the parameters.
    my ($self, $objectName, $fieldName) = @_;
    # Declare the return variable.
    my $retVal;
    # Get the field descriptor.
    my $fieldTable = $self->GetFieldTable($objectName);
    my $fieldData = $fieldTable->{$fieldName};
    # Check for a default value. The default value is already encoded,
    # so no conversion is required.
    if (exists $fieldData->{default}) {
        $retVal = $fieldData->{default};
    } else {
        # No default for the field, so get the default for the type.
        # This will be undefined if the type has no default, either.
        $retVal = TypeDefault($fieldData->{type});
    }
    # Return the result.
    return $retVal;
}


=head3 _SingleTableHash

    my %fixedHash = $self->_SingleTableHash($fieldHash, $objectName, $unchanged);

Convert a hash of field names in L</Standard Field Name Format> to field values
into a hash of simple field names to encoded values. This is a common
utility function performed by most update-related methods.

=over 4

=item fieldHash

A hash mapping field names to values. The field names must be in
L</Standard Field Name Format>.

=item objectName

The default object name to be used when no object name is specified for
the field.

=item unchanged

If TRUE, the field values will not be encoded for storage. (It is presumed they already are.) The default is FALSE.

=item RETURN

Returns a hash of simple field names to encoded values for those fields.

=back

=cut

sub _SingleTableHash {
    # Get the parameters.
    my ($self, $fieldHash, $objectName, $unchanged) = @_;
    # Declare the return variable.
    my %retVal;
    # Loop through the fields.
    for my $key (keys %$fieldHash) {
        my $fieldData = $self->_FindField($key, $objectName);
        my $value = $fieldHash->{$key};
        if (! $unchanged) {
        	$value = encode($fieldData->{type}, $value);
        }
        $retVal{$fieldData->{name}} = $value;
    }
    # Return the result.
    return %retVal;
}


=head3 _FindField

    my $fieldData = $erdb->_FindField($string, $defaultName);

Return the descriptor for the named field. If the field does not exist or
the name is invalid, an error will occur.

=over 4

=item string

Field name string to be parsed. See L</Standard Field Name Format>.

=item defaultName (optional)

Default object name to be used if the object name is not specified in the
input string.

=item RETURN

Returns the descriptor for the specified field.

=back

=cut

sub _FindField {
    # Get the parameters.
    my ($self, $string, $defaultName) = @_;
    # Declare the return variable.
    my $retVal;
    # Parse the string.
    my ($tableName, $fieldName) = ERDB::ParseFieldName($string, $defaultName);
    if (! defined $tableName) {
        # Here the field name string has an invalid format.
        Confess("Invalid field name specification \"$string\".");
    } else {
        # Find the structure for the specified object.
        $retVal = $self->_CheckField($tableName, $fieldName);
        if (! defined $retVal) {
            Confess("Field \"$fieldName\" not found in \"$tableName\".");
        }
    }
    # Return the result.
    return $retVal;
}

=head3 _CheckField

    my $descriptor = $erdb->_CheckField($objectName, $fieldName);

Return the descriptor for the specified field in the specified entity or
relationship, or an undefined value if the field does not exist.

=over 4

=item objectName

Name of the relevant entity or relationship. If the object does not exist,
an error will be thrown.

=item fieldName

Name of the relevant field.

=item RETURN

Returns the field descriptor from the metadata, or C<undef> if the field
does not exist.

=back

=cut

sub _CheckField {
    # Get the parameters.
    my ($self, $objectName, $fieldName) = @_;
    # Declare the return variable.
    my $retVal;
        # Find the structure for the specified object. This will fail
        # if the object name is invalid.
        my $objectData = $self->_GetStructure($objectName);
        # Look for the field.
        my $fields = $objectData->{Fields};
        if (exists $fields->{$fieldName}) {
            # We found it, so return the descriptor.
            $retVal = $fields->{$fieldName};
        }
    # Return the result.
    return $retVal;
}

=head3 _RelationMap

    my @relationMap = _RelationMap($mappedNameHashRef, $mappedNameListRef);

Create the relation map for an SQL query. The relation map is used by
L</ERDBObject> to determine how to interpret the results of the query.

=over 4

=item mappedNameHashRef

Reference to a hash that maps object name aliases to real object names.

=item mappedNameListRef

Reference to a list of object name aliases in the order they appear in the
SELECT list.

=item RETURN

Returns a list of 3-tuples. Each tuple consists of an object name alias followed
by the actual name of that object and a flag that is TRUE if the alias is a converse.
This enables the L</ERDBObject> to determine the order of the tables in the
query and which object name belongs to each object alias name. Most of the time
the object name and the alias name are the same; however, if an object occurs
multiple times in the object name list, the second and subsequent occurrences
may be given a numeric suffix to indicate it's a different instance. In
addition, some relationship names may be specified using their converse name.

=back

=cut

sub _RelationMap {
    # Get the parameters.
    my ($mappedNameHashRef, $mappedNameListRef) = @_;
    # Declare the return variable.
    my @retVal = ();
    # Build the map.
    for my $mappedName (@{$mappedNameListRef}) {
        push @retVal, [$mappedName, @{$mappedNameHashRef->{$mappedName}}];
    }
    # Return it.
    return @retVal;
}


=head3 _SetupSQL

    my ($suffix, $nameList, $nameHash) = $erdb->_SetupSQL($objectNames, $filterClause, $matchClause);

Process a list of object names and a filter clause so that they can be used to
build an SQL statement. This method takes in an object name list and a
filter clause. It will return a corrected filter clause, a list of mapped names
and the mapped name hash.

This is an instance method.

=over 4

=item objectNames

Object name list from a query. See L</Object Name List>.

=item filterClause

A string containing the WHERE clause for the query (without the C<WHERE>) and also
optionally the C<ORDER BY> and C<LIMIT> clauses. See L</Filter Clause>.

=item matchClause

An optional full-text search clause. If specified, it will be inserted at the
front of the WHERE clause. It should already be SQL-formatted; that is, the
field names should be in the form I<table>C<.>I<fieldName>.

=item RETURN

Returns a three-element list. The first element is the SQL statement suffix,
beginning with the FROM clause. The second element is a reference to a list of
the names to be used in retrieving the fields. The third element is a hash
mapping the names to 2-tuples consisting of the real name of the object and
a flag indicating whether or not the mapping is via a converse relationship name.

=back

=cut

sub _SetupSQL {
    my ($self, $objectNames, $filterClause, $matchClause) = @_;
    # This list will contain the object names as they are to appear in the
    # FROM list.
    my @fromList = ();
    # This list contains the object alias name for each object.
    my @mappedNameList = ();
    # This hash translates from an object alias name to the real object name.
    my %mappedNameHash = ();
    # This will be used to build the join clauses.
    my @joinWhere = ();
    # Finally, this variable contains the previous object encountered in the
    # name list. It is used to create the joins. An empty string means we
    # don't need a join yet.
    my $previousObject = "";
    # Get pointers to the alias and join tables.
    my $aliasTable = $self->{_metaData}->{AliasTable};
    # Get a list of the object names.
    my @objectNameList;
    if (ref $objectNames eq 'ARRAY') {
        push @objectNameList, @$objectNames;
    } else {
        # Here we need to convert a name string into a list. We start by
        # trimming excess whitespace at the front.
        my $objectNameString = $objectNames;
        $objectNameString =~ s/^\s+//;
        # Now we connect each AND to the object name after it.
        $objectNameString =~ s/\s+AND\s+(\w+)/ AND=$1/g;
        Trace("Object name string = $objectNameString") if T(4);
        # Split on whitespace to form the final list.
        @objectNameList = split /\s+/, $objectNameString;
        Trace("Objects are " . join(" ", @objectNameList)) if T(4);
    }
    # Loop through the object name list.
    for my $objectName (@objectNameList) {
        Trace("Object name is $objectName") if T(4);
        # Parse this object name.
        my $alias;
        if ($objectName =~ /AND=(.+)/) {
            # Here we have an AND situation. We blank the previous-object
            # indicator to insure we don't try to set up a join.
            $previousObject = "";
            # Save the object name itself.
            $alias = $1;
        } else {
            # Here we need have a normal object name.
            $alias = $objectName;
        }
        # Have we seen this object name before?
        if (! exists $mappedNameHash{$alias}) {
            # No, so we need to compute its real name, put it in the
            # map hash, and add it to the FROM list. First, we strip
            # off any number suffix the caller supplied.
            if ($alias =~ /^(\D+)(\d*)$/) {
                my ($baseName, $suffix) = ($1, $2);
                # Does the base name exist in the database?
                my $realName = $aliasTable->{$baseName};
                if (! defined $realName) {
                    Confess("Invalid name in query: \"$baseName\".");
                } else {
                    # Yes. Put the real name in the map.
                    $mappedNameHash{$alias} = [$realName, $baseName ne $realName];
                    # Put the alias and its real name into the FROM list. This
                    # informs SQL of the mapping.
                    my $tableSpec = $self->{_quote} . $realName . $self->{_quote};
                    if ($alias ne $realName) {
                        $tableSpec .= " $self->{_quote}$alias$self->{_quote}";
                    }
                    push @fromList, $tableSpec;
                    # Add the alias to the mapped name list.
                    push @mappedNameList, $alias;
                }
            } else {
                # Here the alias parse failed.
                Confess("Invalid name in query: \"$alias\".");
            }
        }
        # Do we need a join here?
        if ($previousObject) {
            # Yes. Compute the join clause.
            my $joinClause = $self->_JoinClause($previousObject, $alias);
            if (! $joinClause) {
                Confess("There is no path from $previousObject to $alias.");
            }
            push @joinWhere, $joinClause;
        }
        # Save this object as the last object for the next iteration.
        $previousObject = $alias;
    }
    # Begin the SELECT suffix. It starts with
    #
    # FROM name1, name2, ... nameN
    #
    my $suffix = "FROM " . join(', ', @fromList);
    # Now for the WHERE. First, we need a place for the filter string.
    my $filterString = "";
    # Check for a filter clause.
    if ($filterClause) {
        # We have one, so we convert its field names and add it to the query. First,
        # We create a copy of the filter string we can work with.
        $filterString = $filterClause;
        # Next, we sort the object names by length. This helps protect us from finding
        # object names inside other object names when we're doing our search and replace.
        my @sortedNames = sort { length($b) - length($a) } @mappedNameList;
        Trace("Sorted name list is " . join(", ", @sortedNames) . ".") if T(4);
        # The final preparatory step is to create a hash table of relation names. The
        # table begins with the relation names already in the SELECT command. We may
        # need to add relations later if there is filtering on a field in a secondary
        # relation. The secondary relations are the ones that contain multiply-
        # occurring or optional fields.
        my %fromNames = map { $_ => 1 } @sortedNames;
        # We are ready to begin. We loop through the object names, replacing each
        # object name's field references by the corresponding SQL field reference.
        # Along the way, if we find a secondary relation, we will need to add it
        # to the FROM clause.
        for my $mappedName (@sortedNames) {
            # Get the length of the object name plus 2. This is the value we add to the
            # size of the field name to determine the size of the field reference as a
            # whole.
            my $nameLength = 2 + length $mappedName;
            # Get the real object name for this mapped name.
            my ($objectName, $converse) = @{$mappedNameHash{$mappedName}};
            Trace("Processing $mappedName for object $objectName.") if T(4);
            # Get the object's field list.
            my $fieldList = $self->GetFieldTable($objectName);
            # Find the field references for this object.
            while ($filterString =~ m/$mappedName\(([^)]*)\)/g) {
                # At this point, $1 contains the field name, and the current position
                # is set immediately after the final parenthesis. We pull out the name of
                # the field and the position and length of the field reference as a whole.
                my $fieldName = $1;
                my $len = $nameLength + length $fieldName;
                my $pos = pos($filterString) - $len;
                # Convert any underscores in the field name to hyphens.
                # This is to allow users to specify the real SQL field name
                # instead of its ERDB name.
                $fieldName =~ tr/_/-/;
                # Insure the field exists.
                if (!exists $fieldList->{$fieldName}) {
                    Confess("Field $fieldName not found for object $objectName.");
                } else {
                    Trace("Processing $fieldName at position $pos.") if T(4);
                    # Get the field's relation.
                    my $relationName = $fieldList->{$fieldName}->{relation};
                    # This will hold the mapped relation name to be used in the
                    # filter clause. The default is the mapped name.
                    my $mappedRelationName = $mappedName;
                    # We may have a secondary relation.
                    if ($relationName ne $objectName) {
                        # This adds a bit of complexity, because we need to insure
                        # the secondary relation is pulled in. First, we peel off
                        # the suffix from the mapped name.
                        my $mappingSuffix = substr $mappedName, length($objectName);
                        # Put the mapping suffix onto the relation name to get the
                        # mapped relation name.
                        $mappedRelationName = "$relationName$mappingSuffix";
                        # Insure the relation is in the FROM clause.
                        if (!exists $fromNames{$mappedRelationName}) {
                            Trace("Working with $mappedRelationName.") if T(4);
                            # Add the relation to the FROM clause.
                            if ($mappedRelationName eq $relationName) {
                                # The name is un-mapped, so we add it without
                                # any frills.
                                $suffix .= ", $relationName";
                                push @joinWhere, "$self->{_quote}$objectName$self->{_quote}.id = $self->{_quote}$relationName$self->{_quote}.id";
                            } else {
                                # Here we have a mapping situation.
                                $suffix .= ", $self->{_quote}$relationName$self->{_quote} $self->{_quote}$mappedRelationName$self->{_quote}";
                                push @joinWhere, "$self->{_quote}$mappedRelationName$self->{_quote}.id = $self->{_quote}$mappedName$self->{_quote}.id";
                            }
                            # Denote we have this relation available for future fields.
                            $fromNames{$mappedRelationName} = 1;
                        }
                    }
                    # Is this a converse mapping? Form an SQL field reference
                    # from the relation name and the field name.
                    my $sqlReference = "$self->{_quote}$mappedRelationName$self->{_quote}.$self->{_quote}" . _FixName($fieldName,
                                                                         $converse) . $self->{_quote};
                    # Put it into the filter string in place of the old value.
                    substr($filterString, $pos, $len) = $sqlReference;
                    # Reposition the search.
                    pos $filterString = $pos + length $sqlReference;
                }
            }
        }
    }
    # Now we need to handle the whole ORDER BY / LIMIT thing. The important part
    # here is we want the filter clause to be empty if there's no WHERE filter.
    # We'll put the ORDER BY / LIMIT clauses in the following variable.
    my $orderClause = "";
    # This is only necessary if we have a filter string in which the ORDER BY
    # and LIMIT clauses can live.
    if ($filterString) {
        # Locate the ORDER BY or LIMIT verbs (if any). We use a non-greedy
        # operator so that we find the first occurrence of either verb.
        if ($filterString =~ m/^(.*?)\s*(ORDER BY|LIMIT)(.+)/) {
            # Here we have an ORDER BY or LIMIT verb. Split it off of the filter string.
            $orderClause = $2 . $3;
            $filterString = $1;
        }
    }
    # All the things that are supposed to be in the WHERE clause of the
    # SELECT command need to be put into @joinWhere so we can string them
    # together. We begin with the match clause. It gets put at the end of
    # the join section so that the match clause's parameter mark precedes
    # any parameter marks in the filter string.
    if ($matchClause) {
        push @joinWhere, $matchClause;
    }
    # Add the filter string. We put it in parentheses to avoid operator
    # precedence problems with the match clause or the joins.
    if ($filterString) {
        Trace("Filter string is \"$filterString\".") if T(4);
        push @joinWhere, "($filterString)";
    }
    # String it all together into a big filter clause.
    if (@joinWhere) {
        $suffix .= " WHERE " . join(' AND ', @joinWhere);
    }
    # Add the sort or limit clause (if any).
    if ($orderClause) {
        $suffix .= " $orderClause";
    }
    # Return the suffix, the mapped name list, and the mapped name hash.
    return ($suffix, \@mappedNameList, \%mappedNameHash);
}

=head3 _GetStatementHandle

    my $sth = $erdb->_GetStatementHandle($command, $params);

This method will prepare and execute an SQL query, returning the statement handle.
The main reason for doing this here is so that everybody who does SQL queries gets
the benefit of tracing.

=over 4

=item command

Command to prepare and execute.

=item params

Reference to a list of the values to be substituted in for the parameter marks.

=item RETURN

Returns a prepared and executed statement handle from which the caller can extract
results.

=back

=cut

sub _GetStatementHandle {
    # Get the parameters.
    my ($self, $command, $params) = @_;
    Confess("Invalid parameter list.") if (! defined($params) || ref($params) ne 'ARRAY');
    # Trace the query.
    Trace("SQL query: $command") if T(SQL => 3);
    if (T(SQL => 4)) {
        if (! scalar(@$params)) {
            Trace("PARMS: none");
        } else {
            Trace("PARMS: " . join(", ", map { "'$_'" } @$params));
        }
    }
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Prepare the command.
    my $retVal = $dbh->prepare_command($command);
    # Execute it with the parameters bound in. This may require multiple retries.
    my $rv = $retVal->execute(@$params);
    # The number of retries will be counted in here.
    my $retries = 0;
    while (! $rv) {
        # Get the error message.
        my $msg = $dbh->ErrorMessage($retVal);
        # Is a retry worthwhile?
        if ($retries >= $ERDBExtras::query_retries) {
            # No, we've tried too many times.
            Confess($msg);
        } elsif ($msg =~ /^DBServer Error/) {
            # Yes. Wait, then try reconnecting.
            Trace("SELECT error requires reconnection. $msg") if T(2);
            sleep($ERDBExtras::sleep_time);
            $dbh->Reconnect();
            # Try executing the statement again.
            $retVal = $dbh->prepare_command($command);
            $rv = $retVal->execute(@$params);
            # Denote we've made another retry.
            $retries++;
        } else {
            # No. This error cannot be recovered by reconnecting.
            Confess($msg);
        }
    }
    # Return the statement handle.
    return $retVal;
}

=head3 _GetLoadStats

    my $stats = ERDB::_GetLoadStats();

Return a blank statistics object for use by the load methods.

=cut

sub _GetLoadStats{
    return Stats->new();
}

=head3 _DumpRelation

    my $count = $erdb->_DumpRelation($outputDirectory, $relationName);

Dump the specified relation to the specified output file in tab-delimited format.

=over 4

=item outputDirectory

Directory to contain the output file.

=item relationName

Name of the relation to dump.

=item RETURN

Returns the number of records dumped.

=back

=cut

sub _DumpRelation {
    # Get the parameters.
    my ($self, $outputDirectory, $relationName) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Open the output file.
    my $fileName = "$outputDirectory/$relationName.dtx";
    open(DTXOUT, ">$fileName") || Confess("Could not open dump file $fileName: $!");
    # Create a query for the specified relation.
    my $dbh = $self->{_dbh};
    my $query = $dbh->prepare_command("SELECT * FROM $relationName");
    # Execute the query.
    $query->execute() || Confess("SELECT error dumping $relationName.");
    # Loop through the results.
    while (my @row = $query->fetchrow) {
        # Escape any tabs or new-lines in the row text, and convert NULLs.
        for my $field (@row) {
            if (! defined $field) {
                $field = "\\N";
            } else {
                $field =~ s/\n/\\n/g;
                $field =~ s/\t/\\t/g;
            }
        }
        # Tab-join the row and write it to the output file.
        my $rowText = join("\t", @row);
        print DTXOUT "$rowText\n";
        $retVal++;
    }
    # Close the output file.
    close DTXOUT;
    # Return the write count.
    return $retVal;
}

=head3 _GetStructure

    my $objectData = $self->_GetStructure($objectName);

Get the data structure for a specified entity or relationship.

=over 4

=item objectName

Name of the desired entity or relationship.

=item RETURN

The descriptor for the specified object.

=back

=cut

sub _GetStructure {
    # Get the parameters.
    my ($self, $objectName) = @_;
    # Get the metadata structure.
    my $metadata = $self->{_metaData};
    # Declare the variable to receive the descriptor.
    my $retVal;
    # Get the descriptor from the metadata.
    if (exists $metadata->{Entities}->{$objectName}) {
        $retVal = $metadata->{Entities}->{$objectName};
    } elsif (exists $metadata->{Relationships}->{$objectName}) {
        $retVal = $metadata->{Relationships}->{$objectName};
    } else {
        Confess("Object $objectName not found in database.");
    }
    # Return the descriptor.
    return $retVal;
}


=head3 _GetRelationTable

    my $relHash = $erdb->_GetRelationTable($objectName);

Get the list of relations for a specified entity or relationship.

=over 4

=item objectName

Name of the desired entity or relationship.

=item RETURN

A table containing the relations for the specified object.

=back

=cut

sub _GetRelationTable {
    # Get the parameters.
    my ($self, $objectName) = @_;
    # Get the descriptor from the metadata.
    my $objectData = $self->_GetStructure($objectName);
    # Return the object's relation list.
    return $objectData->{Relations};
}

=head3 _ValidateFieldNames

    $erdb->ValidateFieldNames($metadata);

Determine whether or not the field names in the specified metadata
structure are valid. If there is an error, this method will abort.

=over 4

=item metadata

Metadata structure loaded from the XML data definition.

=back

=cut

sub _ValidateFieldNames {
    # Get the object.
    my ($metadata) = @_;
    # Declare the return value. We assume success.
    my $retVal = 1;
    # Loop through the sections of the database definition.
    for my $section ('Entities', 'Relationships') {
        # Loop through the objects in this section.
        for my $object (values %{$metadata->{$section}}) {
            # Loop through the object's fields.
            for my $fieldName (keys %{$object->{Fields}}) {
                # If this field name is invalid, set the return value to zero
                # so we know we encountered an error.
                if (! ValidateFieldName($fieldName)) {
                    $retVal = 0;
                }
            }
        }
    }
    # If an error was found, fail.
    if ($retVal  == 0) {
        Confess("Errors found in field names.");
    }
}

=head3 _LoadRelation

    my $stats = $erdb->_LoadRelation($directoryName, $relationName, $rebuild);

Load a relation from the data in a tab-delimited disk file. The load will only
take place if a disk file with the same name as the relation exists in the
specified directory.

=over 4

=item dbh

DBKernel object for accessing the database.

=item directoryName

Name of the directory containing the tab-delimited data files.

=item relationName

Name of the relation to load.

=item rebuild

TRUE if the table should be dropped and re-created before loading.

=item RETURN

Returns a statistical object describing the number of records read and a list of
error messages.

=back

=cut

sub _LoadRelation {
    # Get the parameters.
    my ($self, $directoryName, $relationName, $rebuild) = @_;
    # Create the file name.
    my $fileName = "$directoryName/$relationName";
    # If the file doesn't exist, try adding the .dtx suffix.
    if (! -e $fileName) {
        $fileName .= ".dtx";
        if (! -e $fileName) {
            $fileName = "";
        }
    }
    # Create the return object.
    my $retVal = _GetLoadStats();
    # If a file exists to load the table, its name will be in $fileName. Otherwise, $fileName will
    # be a null string.
    if ($fileName ne "") {
        # Load the relation from the file.
        $retVal = $self->LoadTable($fileName, $relationName, truncate => $rebuild);
    } elsif ($rebuild) {
        # Here we are rebuilding, but no file exists, so we just re-create the table.
        $self->CreateTable($relationName, 1);
    }
    # Return the statistics from the load.
    return $retVal;
}


=head3 _LoadMetaData

    my $metadata = ERDB::_LoadMetaData($self, $filename, $external);

This method loads the data describing this database from an XML file into a
metadata structure. The resulting structure is a set of nested hash tables
containing all the information needed to load or use the database. The schema
for the XML file is F<ERDatabase.xml>.

=over 4

=item self

Blessed ERDB object.

=item filename

Name of the file containing the database definition.

=item external (optional)

If TRUE, then the internal DBD stored in the database (if any) will be
bypassed. This option is usually used by the load-related command-line
utilities.

=item RETURN

Returns a structure describing the database.

=back

=cut

sub _LoadMetaData {
    # Get the parameters.
    my ($self, $filename, $external) = @_;
    # Declare the return variable.
    my $metadata;
    # Get the database handle.
    my $dbh = $self->{_dbh};
    # Check for an internal DBD.
    if (defined $dbh && ! $external && $self->UseInternalDBD()) {
        Trace("Checking for internal DBD.") if T(3);
        # Check for a metadata table.
        if ($dbh->table_exists(METADATA_TABLE)) {
            # Check for an internal DBD.
            my $rv = $dbh->SQL("SELECT data FROM " . METADATA_TABLE . " WHERE id = ?",
                               0, "DBD");
            if ($rv && scalar @$rv > 0) {
                # Here we found something. The return value is a reference to a
                # list containing a 1-tuple.
                my $frozen = $rv->[0][0];
                Trace(length($frozen) . " characters read from metadata record.") if T(3);
                ($metadata) = FreezeThaw::thaw($frozen);
                Trace("DBD loaded  from database.") if T(2);
            }
        }
    }
    # If we didn't get an internal DBD, read the external one.
    if (! defined $metadata) {
        Trace("Reading DBD from $filename.") if T(2);
        # Slurp the XML file into a variable. Extensive use of options is used to
        # insure we get the exact structure we want.
        $metadata = ReadMetaXML($filename);
        # Before we go any farther, we need to validate the field and object names.
        # If an error is found, the method below will fail.
        _ValidateFieldNames($metadata);
        # Next we need to create a hash table for finding relations. The entities
        # and relationships are implemented as one or more database relations.
        my %masterRelationTable = ();
        # We also have a table for mapping alias names to object names. This is
        # useful when processing object name lists.
        my %aliasTable = ();
        # Loop through the entities.
        my $entityList = $metadata->{Entities};
        for my $entityName (keys %{$entityList}) {
            my $entityStructure = $entityList->{$entityName};
            #
            # The first step is to fill in all the entity's missing values. For
            # C<Field> elements, the relation name must be added where it is not
            # specified. For relationships, the B<from-link> and B<to-link> fields
            # must be inserted, and for entities an B<id> field must be added to
            # each relation. Finally, each field will have a C<PrettySort> attribute
            # added that can be used to pull the implicit fields to the top when
            # displaying the field documentation.
            #
            # Fix up this entity.
            _FixupFields($entityStructure, $entityName);
            # Add the ID field.
            _AddField($entityStructure, 'id', { type => $entityStructure->{keyType},
                                                name => 'id',
                                                relation => $entityName,
                                                Notes => { content => "Unique identifier for this \[b\]$entityName\[/b\]." },
                                                PrettySort => 0});
            # Store the entity in the alias table.
            $aliasTable{$entityName} = $entityName;
            #
            # The current field list enables us to quickly find the relation
            # containing a particular field. We also need a list that tells us the
            # fields in each relation. We do this by creating a Relations structure
            # in the entity structure and collating the fields into it based on
            # their C<relation> property. There is one tricky bit, which is that
            # every relation has to have the C<id> field in it. Note also that the
            # field list is put into a C<Fields> member of the relation's structure
            # so that it looks more like the entity and relationship structures.
            #
            # First we need to create the relations list.
            my $relationTable = { };
            # Loop through the fields. We use a list of field names to prevent a problem with
            # the hash table cursor losing its place during the loop.
            my $fieldList = $entityStructure->{Fields};
            my @fieldNames = keys %{$fieldList};
            for my $fieldName (@fieldNames) {
                my $fieldData = $fieldList->{$fieldName};
                # Get the current field's relation name.
                my $relationName = $fieldData->{relation};
                # Insure the relation exists.
                if (!exists $relationTable->{$relationName}) {
                    $relationTable->{$relationName} = { Fields => { } };
                }
                # Add the field to the relation's field structure.
                $relationTable->{$relationName}->{Fields}->{$fieldName} = $fieldData;
            }
            # Now that we've organized all our fields by relation name we need to do
            # some serious housekeeping. We must add the C<id> field to every
            # relation and convert each relation to a list of fields. First, we need
            # the ID field itself.
            my $idField = $fieldList->{id};
            # Loop through the relations.
            for my $relationName (keys %{$relationTable}) {
                my $relation = $relationTable->{$relationName};
                # Get the relation's field list.
                my $relationFieldList = $relation->{Fields};
                # Add the ID field to it. If the field's already there, it will not make any
                # difference.
                $relationFieldList->{id} = $idField;
                # Convert the field set from a hash into a list using the pretty-sort number.
                $relation->{Fields} = _ReOrderRelationTable($relationFieldList);
                # Add the relation to the master table.
                $masterRelationTable{$relationName} = $relation;
            }
            # The indexes come next. The primary relation will have a unique-keyed
            # index based on the ID field. The other relations must have at least
            # one index that begins with the ID field. In addition, the metadata may
            # require alternate indexes. We do those alternate indexes first. To
            # begin, we need to get the entity's field list and index list.
            my $indexList = $entityStructure->{Indexes};
            # Loop through the indexes.
            for my $indexData (@{$indexList}) {
                # We need to find this index's fields. All of them should belong to
                # the same relation. The ID field is an exception, since it's in all
                # relations.
                my $relationName = '0';
                for my $fieldDescriptor (@{$indexData->{IndexFields}}) {
                    # Get this field's name.
                    my $fieldName = $fieldDescriptor->{name};
                    # Only proceed if it is NOT the ID field.
                    if ($fieldName ne 'id') {
                        # Insure the field name is valid.
                        my $fieldThing = $fieldList->{$fieldName};
                        if (! defined $fieldThing) {
                            Confess("Invalid index: field $fieldName does not belong to $entityName.");
                        } else {
                            # Find the relation containing the current index field.
                            my $thisName = $fieldList->{$fieldName}->{relation};
                            if ($relationName eq '0') {
                                # Here we're looking at the first field, so we save its
                                # relation name.
                                $relationName = $thisName;
                            } elsif ($relationName ne $thisName) {
                                # Here we have a field mismatch.
                                Confess("Mixed index: field $fieldName does not belong to relation $relationName.");
                            }
                        }
                    }
                }
                # Now $relationName is the name of the relation that contains this
                # index. Add the index structure to the relation.
                push @{$relationTable->{$relationName}->{Indexes}}, $indexData;
            }
            # Now each index has been put in a relation. We need to add the primary
            # index for the primary relation.
            push @{$relationTable->{$entityName}->{Indexes}},
                { IndexFields => [ {name => 'id', order => 'ascending'} ], primary => 1,
                  Notes => { content => "Primary index for $entityName." }
                };
            # The next step is to insure that each relation has at least one index
            # that begins with the ID field. After that, we convert each relation's
            # index list to an index table. We first need to loop through the
            # relations.
            for my $relationName (keys %{$relationTable}) {
                my $relation = $relationTable->{$relationName};
                # Get the relation's index list.
                my $indexList = $relation->{Indexes};
                # Insure this relation has an ID index.
                my $found = 0;
                for my $index (@{$indexList}) {
                    if ($index->{IndexFields}->[0]->{name} eq "id") {
                        $found = 1;
                    }
                }
                if ($found == 0) {
                    push @{$indexList}, { IndexFields => [ {name => 'id',
                                                            order => 'ascending'} ] };
                }
                # Attach all the indexes to the relation.
                _ProcessIndexes($indexList, $relation);
            }
            # Finally, we add the relation structure to the entity.
            $entityStructure->{Relations} = $relationTable;
        }
        # Loop through the relationships. Relationships actually turn out to be much
        # simpler than entities. For one thing, there is only a single constituent
        # relation.
        my $relationshipList = $metadata->{Relationships};
        for my $relationshipName (keys %{$relationshipList}) {
            my $relationshipStructure = $relationshipList->{$relationshipName};
            # Fix up this relationship.
            _FixupFields($relationshipStructure, $relationshipName);
            # Format a description for the FROM field.
            my $fromEntity = $relationshipStructure->{from};
            my $fromComment = "[b]id[/b] of the source [b][link #$fromEntity]$fromEntity\[/link][/b].";
            # Get the FROM entity's key type.
            my $fromType = $entityList->{$fromEntity}->{keyType};
            # Add the FROM field.
            _AddField($relationshipStructure, 'from-link', { type => $fromType,
                                                        name => 'from-link',
                                                        relation => $relationshipName,
                                                        Notes => { content => $fromComment },
                                                        PrettySort => 0});
            # Format a description for the TO field.
            my $toEntity = $relationshipStructure->{to};
            my $toComment = "[b]id[/b] of the target [b][link #$toEntity]$toEntity\[/link][/b].";
            # Get the TO entity's key type.
            my $toType = $entityList->{$toEntity}->{keyType};
            # Add the TO field.
            _AddField($relationshipStructure, 'to-link', { type=> $toType,
                                                      name => 'to-link',
                                                      relation => $relationshipName,
                                                      Notes => { content => $toComment },
                                                      PrettySort => 0});
            # Create an index-free relation from the fields.
            my $thisRelation = { Fields => _ReOrderRelationTable($relationshipStructure->{Fields}),
                                 Indexes => { } };
            $relationshipStructure->{Relations} = { $relationshipName => $thisRelation };
            # Put the relationship in the alias table.
            $aliasTable{$relationshipName} = $relationshipName;
            if (exists $relationshipStructure->{converse}) {
                $aliasTable{$relationshipStructure->{converse}} = $relationshipName;
            }
            # Add the alternate indexes (if any). This MUST be done before the FROM
            # and TO indexes, because it erases the relation's index list.
            if (exists $relationshipStructure->{Indexes}) {
                _ProcessIndexes($relationshipStructure->{Indexes}, $thisRelation);
            }
            # Create the FROM and TO indexes.
            _CreateRelationshipIndex("From", $relationshipName, $relationshipStructure);
            _CreateRelationshipIndex("To", $relationshipName, $relationshipStructure);
            # Add the relation to the master table.
            $masterRelationTable{$relationshipName} = $thisRelation;
        }
        # Now store the master relation table and alias table in the metadata structure.
        $metadata->{RelationTable} = \%masterRelationTable;
        $metadata->{AliasTable} = \%aliasTable;
    }
    # Return the metadata structure.
    return $metadata;
}

=head3 _CreateRelationshipIndex

    ERDB::_CreateRelationshipIndex($indexKey, $relationshipName, $relationshipStructure);

Create an index for a relationship's relation.

=over 4

=item indexKey

Type of index: either C<"From"> or C<"To">.

=item relationshipName

Name of the relationship.

=item relationshipStructure

Structure describing the relationship that the index will sort.

=back

=cut

sub _CreateRelationshipIndex {
    # Get the parameters.
    my ($indexKey, $relationshipName, $relationshipStructure) = @_;
    # Get the target relation.
    my $relationStructure = $relationshipStructure->{Relations}->{$relationshipName};
    # Create a descriptor for the link field that goes at the beginning of this
    # index.
    my $firstField = { name => lcfirst $indexKey . '-link', order => 'ascending' };
    # Get the target index descriptor.
    my $newIndex = $relationshipStructure->{$indexKey . "Index"};
    # Add the first field to the index's field list. Due to the craziness of
    # PERL, if the index descriptor does not exist, it will be created
    # automatically so we can add the field to it.
    unshift @{$newIndex->{IndexFields}}, $firstField;
    # If this is a one-to-many relationship, the "To" index is unique. The index
    # can also be forced unique by the user.
    if ($relationshipStructure->{arity} eq "1M" && $indexKey eq "To" ||
    	$relationshipStructure->{unique}) {
        $newIndex->{unique} = 1;
    }
    # Add the index to the relation.
    _AddIndex("idx$indexKey", $relationStructure, $newIndex);
}

=head3 _ProcessIndexes

    ERDB::_ProcessIndexes($indexList, $relation);

Build the data structures for the specified indexes in the specified relation.

=over 4

=item indexList

Reference to a list of indexes. Each index is a hash reference containing an
optional C<Notes> value that describes the index and an C<IndexFields> value
that is a reference to a list of index field structures. An index field
structure, in turn, is a reference to a hash that contains a C<name> attribute
for the field name and an C<order> attribute that specifies either C<ascending>
or C<descending>. In this sense the index list encapsulates the XML C<Indexes>
structure in the database definition.

=item relation

The structure that describes the current relation. The new index descriptors
will be stored in the structure's C<Indexes> member. Any previous data in the
structure will be lost.

=back

=cut

sub _ProcessIndexes {
    # Get the parameters.
    my ($indexList, $relation) = @_;
    # Now we need to convert the relation's index list to an index table. We
    # begin by creating an empty table in the relation structure.
    $relation->{Indexes} = { };
    # Loop through the indexes.
    my $count = 0;
    for my $index (@{$indexList}) {
        # Add this index to the index table.
        _AddIndex("idx$count", $relation, $index);
        # Increment the counter so that the next index has a different name.
        $count++;
    }
}

=head3 _AddIndex

    ERDB::_AddIndex($indexName, $relationStructure);

Add an index to a relation structure.

This is a static method.

=over 4

=item indexName

Name to give to the new index.

=item relationStructure

Relation structure to which the new index should be added.

=item newIndex

New index to add.

=back

=cut

sub _AddIndex {
    # Get the parameters.
    my ($indexName, $relationStructure, $newIndex) = @_;
    # We want to re-do the index's field list. Instead of an object for each
    # field, we want a string consisting of the field name optionally followed
    # by the token DESC.
    my @fieldList = ( );
    for my $field (@{$newIndex->{IndexFields}}) {
        # Create a string containing the field name.
        my $fieldString = $field->{name};
        # Add the ordering token if needed.
        if ($field->{order} && $field->{order} eq "descending") {
            $fieldString .= " DESC";
        }
        # Push the result onto the field list.
        push @fieldList, $fieldString;
    }
    # Store the field list just created as the new index field list.
    $newIndex->{IndexFields} = \@fieldList;
    # Add the index to the relation's index list.
    $relationStructure->{Indexes}->{$indexName} = $newIndex;
}

=head3 _FixupFields

    ERDB::_FixupFields($structure, $defaultRelationName);

This method fixes the field list for the metadata of an entity or relationship.
It will add the caller-specified relation name to fields that do not have a name
and set the C<PrettySort> values.

=over 4

=item structure

Entity or relationship structure to be fixed up.

=item defaultRelationName

Default relation name to be added to the fields.


=back

=cut

sub _FixupFields {
    # Get the parameters.
    my ($structure, $defaultRelationName) = @_;
    # Insure the structure has a field list.
    if (!exists $structure->{Fields}) {
        # Here it doesn't, so we create a new one.
        $structure->{Fields} = { };
    } else {
        # Here we have a field list. We need to track the searchable fields, so
        # we create a list for stashing them.
        my @textFields = ();
        # Loop through the fields.
        my $fieldStructures = $structure->{Fields};
        for my $fieldName (keys %{$fieldStructures}) {
            Trace("Processing field $fieldName of $defaultRelationName.") if T(metadata => 4);
            my $fieldData = $fieldStructures->{$fieldName};
            # Store the field name so we can find it when we're looking at a descriptor
            # without its key.
            $fieldData->{name} = $fieldName;
            # Get the field type.
            my $type = $fieldData->{type};
            # Validate it.
            if (! exists $TypeTable->{$type}) {
                Confess("Field $fieldName of $defaultRelationName has unknown type \"$type\".");
            }
            # Plug in a relation name if one is needed.
            Tracer::MergeOptions($fieldData, { relation => $defaultRelationName });
            # Check for searchability.
            if ($fieldData->{searchable}) {
                # Only allow this for a primary relation.
                if ($fieldData->{relation} ne $defaultRelationName) {
                    Confess("Field $fieldName of $defaultRelationName is in secondary relations and cannot be searchable.");
                } else {
                    push @textFields, $fieldName;
                }
            }
            # Add the PrettySortValue.
            $fieldData->{PrettySort} = $TypeTable->{$type}->prettySortValue();
        }
        # If there are searchable fields, remember the fact.
        if (@textFields) {
            $structure->{searchFields} = \@textFields;
        }
    }
}

=head3 _FixName

    my $fixedName = ERDB::_FixName($fieldName, $converse);

Fix the incoming field name so that it is a legal SQL column name.

=over 4

=item fieldName

Field name to fix.

=item converse

If TRUE, then "from" and "to" will be exchanged.

=item RETURN

Returns the fixed-up field name.

=back

=cut

sub _FixName {
    # Get the parameter.
    my ($fieldName, $converse) = @_;
    # Replace its minus signs with underscores.
    $fieldName =~ s/-/_/g;
    # Check for from/to flipping.
    if ($converse) {
        if ($fieldName eq 'from_link') {
            $fieldName = 'to_link';
        } elsif ($fieldName eq 'to_link') {
            $fieldName = 'from_link';
        }
    }
    # Return the result.
    return $fieldName;
}

=head3 _FixNames

    my @fixedNames = ERDB::_FixNames(@fields);

Fix all the field names in a list. This is essentially a batch call to
L</_FixName>.

=over 4

=item fields

List of field names to fix.

=item RETURN

Returns a list of fixed-up versions of the incoming field names.

=back

=cut

sub _FixNames {
    # Create the result list.
    my @result = ( );
    # Loop through the incoming parameters.
    for my $field (@_) {
        push @result, _FixName($field);
    }
    # Return the result.
    return @result;
}

=head3 _AddField

    ERDB::_AddField($structure, $fieldName, $fieldData);

Add a field to a field list.

=over 4

=item structure

Structure (usually an entity or relationship) that is to contain the field.

=item fieldName

Name of the new field.

=item fieldData

Structure containing the data to put in the field.

=back

=cut

sub _AddField {
    # Get the parameters.
    my ($structure, $fieldName, $fieldData) = @_;
    # Create the field structure by copying the incoming data.
    my $fieldStructure = {%{$fieldData}};
    # Get a reference to the field list itself.
    my $fieldList = $structure->{Fields};
    # Add the field to the field list.
    $fieldList->{$fieldName} = $fieldStructure;
}

=head3 _ReOrderRelationTable

    my \@fieldList = ERDB::_ReOrderRelationTable(\%relationTable);

This method will take a relation table and re-sort it according to the implicit
ordering of the C<PrettySort> property. Instead of a hash based on field names,
it will return a list of fields. This requires creating a new hash that contains
the field name in the C<name> property but doesn't have the C<PrettySort>
property, and then inserting that new hash into the field list.

This is a static method.

=over 4

=item relationTable

Relation hash to be reformatted into a list.

=item RETURN

A list of field hashes.

=back

=cut

sub _ReOrderRelationTable {
    # Get the parameters.
    my ($relationTable) = @_;
    # Create the return list.
    my @resultList;
    # Rather than copy all the fields in a single pass, we make multiple passes
    # and only copy fields whose PrettySort value matches the current pass
    # number. This process continues until we process all the fields in the
    # relation.
    my $fieldsLeft = (values %{$relationTable});
    for (my $sortPass = 0; $fieldsLeft > 0; $sortPass++) {
        # Loop through the fields. Note that we lexically sort the fields. This
        # makes field name secondary to pretty-sort number in the final
        # ordering.
        for my $fieldName (sort keys %{$relationTable}) {
            # Get this field's data.
            my $fieldData = $relationTable->{$fieldName};
            # Verify the sort pass.
            if ($fieldData->{PrettySort} == $sortPass) {
                # Here we're in the correct pass. Denote we've found a field.
                $fieldsLeft--;
                # The next step is to create the field structure. This done by
                # copying all of the field elements except PrettySort and adding
                # the name.
                my %thisField;
                for my $property (keys %{$fieldData}) {
                    if ($property ne 'PrettySort') {
                        $thisField{$property} = $fieldData->{$property};
                    }
                }
                $thisField{name} = $fieldName;
                # Now we add this field to the end of the result list.
                push @resultList, \%thisField;
            }
        }
    }
    # Return a reference to the result list.
    return \@resultList;

}

=head3 _IsPrimary

    my $flag = $erdb->_IsPrimary($relationName);

Return TRUE if a specified relation is a primary relation, else FALSE. A
relation is primary if it has the same name as an entity or relationship.

=over 4

=item relationName

Name of the relevant relation.

=item RETURN

Returns TRUE for a primary relation, else FALSE.

=back

=cut

sub _IsPrimary {
    # Get the parameters.
    my ($self, $relationName) = @_;
    # Check for the relation in the entity table.
    my $entityTable = $self->{_metaData}->{Entities};
    my $retVal = exists $entityTable->{$relationName};
    if (! $retVal) {
        # Check for it in the relationship table.
        my $relationshipTable = $self->{_metaData}->{Relationships};
        $retVal = exists $relationshipTable->{$relationName};
    }
    # Return the determination indicator.
    return $retVal;
}

=head3 _JoinClause

    my $joinClause = $erdb->_JoinClause($source, $target);

Create a join clause that connects the source object to the target
object. If we are crossing from an entity to a relationship, we key off
the relationship's from-link. If we are crossing from a relationship to
an entity, we key off of it's to-link. It is also possible to cross from
relationship to relationship if the two have an entity in common.
Finally, we must be aware of converse names for relationships, and for
nonrecursive relationships we allow crossing via the wrong link.

=over 4

=item source

Name of the object from which we are starting.

=item target

Name of the object to which we are proceeding.

=item RETURN

Returns a string that may be used in an SQL WHERE in order to connect the
two objects. If no connection is possible, an undefined value will be
returned.

=back

=cut

sub _JoinClause {
    # Get the parameters.
    my ($self, $source, $target) = @_;
    # Declare the return variable. If no join can be constructed, it will
    # remain undefined.
    my $retVal;
    # We need for both objects (1) an indication of whether it is an entity, a
    # relationship, or a converse relationship, and (2) its descriptor.
    my (@types, @descriptors);
    for my $object ($source, $target) {
        # Compute this object's real name. We trim off any ending number and
        # check the alias table.
        my $realName = $self->_Resolve($object);
        # If no alias table entry was found, it's an error.
        if (! defined $realName) {
            push @types, 'Error';
        } else {
            # Is this an entity or a relationship?
            my $descriptor = $self->FindEntity($realName);
            if ($descriptor) {
                # Here it's an entity.
                push @types, 'Entity';
                push @descriptors, $descriptor;
            } else {
                # Here it's a relationship. If the name doesn't match the
                # real name, it's a converse.
                $descriptor = $self->FindRelationship($realName);
                push @types, ($object =~ /$realName/ ? 'Relationship' : 'Converse');
                push @descriptors, $descriptor;
            }
        }
    }
    # Now we check the types. Note that if one of the object names was in error,
    # the big IF below will not match anything and we'll return undef.
    my $type = join("/", @types);
    Trace("Join type for $source to $target is $type.") if T(Joins => 3);
    if ($type eq 'Entity/Relationship') {
        $retVal = $self->_BuildJoin(id =>   $source, $descriptors[0],
                                    from => $target, $descriptors[1]);
    } elsif ($type eq 'Entity/Converse') {
        $retVal = $self->_BuildJoin(id =>   $source, $descriptors[0],
                                    to =>   $target, $descriptors[1]);
    } elsif ($type eq 'Relationship/Entity') {
        $retVal = $self->_BuildJoin(id =>   $target, $descriptors[1],
                                    to =>   $source, $descriptors[0]);
    } elsif ($type eq 'Converse/Entity') {
        $retVal = $self->_BuildJoin(id =>   $target, $descriptors[1],
                                    from => $source, $descriptors[0]);
    } elsif ($type eq 'Relationship/Relationship') {
        $retVal = $self->_BuildJoin(to =>   $source, $descriptors[0],
                                    from => $target, $descriptors[1]);
    } elsif ($type eq 'Converse/Relationship') {
        $retVal = $self->_BuildJoin(from => $source, $descriptors[0],
                                    from => $target, $descriptors[1]);
    } elsif ($type eq 'Relationship/Converse') {
        $retVal = $self->_BuildJoin(to =>   $source, $descriptors[0],
                                    to =>   $target, $descriptors[1]);
    } elsif ($type eq 'Converse/Converse') {
        $retVal = $self->_BuildJoin(from => $source, $descriptors[0],
                                    to =>   $target, $descriptors[1]);
    }
    # Return the result.
    return $retVal;
}

=head3 _BuildJoin

    my $joinString = $erdb->_BuildJoin($fld1 => $source, $sourceData,
                                       $fld2 => $target, $targetData);

Create a join string between the two objects. The second object must be a
relationship; the first can be an entity or a relationship. The fields
indicators specify the nature of the connection: C<id> for an entity
connection, C<from> for the front of a relationship, and C<to> for the
back of a relationship. The theory is that if everything is compatible,
you just connect the indicated fields in the two objects. This may not be
possible if the second relationship does not match the first object in
the proper manner. If that is the case, attempts will be made to find a
workable connection.

=over 4

=item fld1

Join direction for the first object: C<id> if it's an entity, C<from> if it's
a relationship and we're coming out the front, or C<to> if it's a relationship
and we're coming out the end.

=item source

Name to use for the first object in constructing the field reference.

=item sourceData

Entity or relationship descriptor for the first object.

=item fld2

Join direction for the second object: C<from> if it's a relationship and we're
going in the front, or C<to> if it's a relationship and we're going in the end.

=item target

Name to use for the second object in constructing the field reference.

=item targetData

Relationship descriptor for the second object.

=item RETURN

Returns a string that can be used in an SQL WHERE clause to connect the two
objects, or C<undef> if no connection is possible.

=back

=cut

sub _BuildJoin {
    # Get the parameters.
    my ($self, $fld1, $source, $sourceData, $fld2, $target, $targetData) = @_;
    Trace("BuildJoin called for $fld1 => $source against $fld2 => $target,") if T(Joins => 4);
    # Declare the return variable. If we can do this join, we'll put
    # the string in here.
    my $retVal;
    # Are we starting from an entity?
    if ($fld1 eq 'id') {
        # Compute the real entity name.
        my $realName = $self->_Resolve($source);
        # Try to find a direction in which the entity connects.
        for my $dir ($fld2, $FromTo{$fld2}) { last if defined $retVal;
            # Check this direction.
            Trace("Join check: $dir of $targetData->{$dir} eq $realName.") if T(Joins => 4);
            if ($targetData->{$dir} eq $realName) {
                # Yes, we can connect.
                $retVal = "$self->{_quote}$source$self->{_quote}.id = $self->{_quote}$target$self->{_quote}.${dir}_link";
            }
        }
    } else {
        # Here we have two relationships. We need to try all four
        # combinations, stopping at the first match.
        for my $srcDir ($fld1, $FromTo{$fld1}) { last if defined $retVal;
            for my $tgtDir ($fld2, $FromTo{$fld2}) { last if defined $retVal;
                # Check this pair of directions.
                Trace("Join check: $srcDir to $tgtDir of $sourceData->{$srcDir} eq $targetData->{$tgtDir}.") if T(Joins => 4);
                if ($sourceData->{$srcDir} eq $targetData->{$tgtDir}) {
                    # We can connect.
                    $retVal = "$self->{_quote}$source$self->{_quote}.${srcDir}_link = $self->{_quote}$target$self->{_quote}.${tgtDir}_link";
                }
            }
        }
    }
    # Return the result.
    return $retVal;
}

=head3 _Resolve

    my $realName = $erdb->_Resolve($objectName);

Determine the real object name for a name from an object name list.
Trailing numbers are peeled off, and the alias table is checked. If the
incoming name is invalid, the return value will be undefined.

=over 4

=item objectName

Incoming object name to parse.

=item RETURN

Returns the object's real name, or C<undef> if the name is invalid.

=back

=cut

sub _Resolve {
    # Get the parameters.
    my ($self, $objectName) = @_;
    # Declare the return variable.
    my $retVal;
    # Parse off any numbers at the end. The pattern below will always match
    # a valid name.
    if ($objectName =~ /^(\D+)(\d*)$/) {
        # Check the alias table. Real names map to themselves, and converse
        # names map to the real name.
        $retVal = $self->{_metaData}->{AliasTable}->{$1};
    }
    # Return the result.
    return $retVal;
}

=head3 InternalizeDBD

    $erdb->InternalizeDBD();

Save the DBD metadata into the database so that it can be retrieved in the
future.

=cut

sub InternalizeDBD {
    # Get the parameters.
    my ($self) = @_;
    # Only proceed if an internal DBD is supported.
    if ($self->UseInternalDBD()) {
        # Get the database handle.
        my $dbh = $self->{_dbh};
        # Insure we have a metadata table.
        if (! $dbh->table_exists(METADATA_TABLE)) {
            Trace("Creating metadata table.") if T(3);
            $dbh->create_table(tbl => METADATA_TABLE,
                               flds => 'id VARCHAR(20) NOT NULL PRIMARY KEY, data MEDIUMTEXT');
        }
        # Delete the current DBD record.
        $dbh->SQL("DELETE FROM " . METADATA_TABLE . " WHERE id = ?", 0, 'DBD');
        # Freeze the DBD metadata.
        my $frozen = FreezeThaw::freeze($self->{_metaData});
        # Store it in the database.
        Trace("Storing DBD in metadata table.") if T(3);
        $dbh->SQL("INSERT INTO " . METADATA_TABLE . " (id, data) VALUES (?, ?)", 0, 'DBD',
                  $frozen);
    }
}


=head2 Internal Documentation-Related Methods

=head3 _FindObject

    my $objectData = $erdb->_FindObject($list => $name);

Return the structural descriptor of the specified object (entity,
relationship, or shape), or an undefined value if the object does not
exist.

=over 4

=item list

Name of the list containing the desired type of object (C<Entities>,
C<Relationships>, or C<Shapes>).

=item name

Name of the desired object.

=item RETURN

Returns the object descriptor if found, or C<undef> if the object does
not exist or is not of the proper type.

=back

=cut

sub _FindObject {
    # Get the parameters.
    my ($self, $list, $name) = @_;
    # Declare the return variable.
    my $retVal;
    # If the object exists, return its descriptor.
    my $thingHash = $self->{_metaData}->{$list};
    if (exists $thingHash->{$name}) {
        $retVal = $thingHash->{$name};
    }
    # Return the result.
    return $retVal;
}

=head3 _WikiNote

    my $wikiText = ERDB::_WikiNote($dataString, $wiki);

Convert a note or comment to Wiki text by replacing some bulletin-board codes
with HTML. The codes supported are C<[b]> for B<bold>, C<[i]> for I<italics>,
C<[link]> for links, C<[list]> for bullet lists. and C<[p]> for a new paragraph.
All the codes are closed by slash-codes. So, for example, C<[b]Feature[/b]>
displays the string C<Feature> in boldface.

=over 4

=item dataString

String to convert to Wiki text.

=item wiki

Wiki object used to format the text.

=item RETURN

An Wiki text string derived from the input string.

=back

=cut

sub _WikiNote {
    # Get the parameter.
    my ($dataString, $wiki) = @_;
    # HTML-escape the text.
    my $retVal = CGI::escapeHTML($dataString);
    # Substitute the italic code.
    $retVal =~ s#\[i\](.+?)\[/i\]#$wiki->Italic($1)#sge;
    # Substitute the bold code.
    $retVal =~ s#\[b\](.+?)\[/b\]#$wiki->Bold($1)#sge;
    # Substitute for the paragraph breaks.
    $retVal =~ s#\[p\](.+?)\[/p\]#$wiki->Para($1)#sge;
    # Now we do the links, which are complicated by the need to know two
    # things: the target URL and the text.
    $retVal =~ s#\[link\s+([^\]]+)\]([^\[]+)\[/link\]#$wiki->LinkMarkup($1, $2)#sge;
    # Finally, we have bullet lists.
    $retVal =~ s#\[list\](.+?)\[/list\]#$wiki->List(split /\[\*\]/, $1)#sge;
    Trace("Wiki Note is\n$retVal") if T(Wiki => 3);
    # Return the result.
    return $retVal;
}

=head3 _ComputeRelationshipSentence

    my $text = ERDB::_ComputeRelationshipSentence($wiki, $relationshipName, $relationshipStructure, $dir);

The relationship sentence consists of the relationship name between the names of
the two related entities and an arity indicator.

=over 4

=item wiki

L<WikiTools> object for rendering links. If this parameter is undefined, no
link will be put in place.

=item relationshipName

Name of the relationship.

=item relationshipStructure

Relationship structure containing the relationship's description and properties.

=item dir (optional)

Starting point of the relationship: C<from> (default) or C<to>.

=item RETURN

Returns a string containing the entity names on either side of the relationship
name and an indicator of the arity.

=back

=cut

sub _ComputeRelationshipSentence {
    # Get the parameters.
    my ($wiki, $relationshipName, $relationshipStructure, $dir) = @_;
    # This will contain the first, second, and third pieces of the sentence.
    my @relWords;
    # Process according to the direction.
    if (! $dir || $dir eq 'from') {
        # Here we're going forward.
        @relWords = ($relationshipStructure->{from}, $relationshipName,
                     $relationshipStructure->{to});
    } else {
        # Here we're going backward. Compute the relationship name, using
        # converse if one is available.
        my $relName;
        if (exists $relationshipStructure->{converse}) {
            $relName = $relationshipStructure->{converse};
        } else {
            $relName = "($relationshipName)";
        }
        @relWords = ($relationshipStructure->{to}, $relName,
                     $relationshipStructure->{from});
    }
    # Now we need to set up the link. This is only necessary if the wiki object
    # is defined.
    if (defined $wiki) {
        $relWords[1] = $wiki->LinkMarkup("#$relationshipName", $relWords[1]);
    }
    # Compute the arity.
    my $arityCode = $relationshipStructure->{arity};
    push @relWords, "($ArityTable{$arityCode})";
    # Form the sentence.
    my $retVal = join(" ", @relWords) . ".";
    return $retVal;
}

=head3 _WikiObjectTable

    my $tableMarkup = _WikiObjectTable($name, $fieldStructure, $wiki);

Generate the field table for the named entity or relationship.

=over 4

=item name

Name of the object whose field table is being generated.

=item fieldStructure

Field structure for the object. This is a hash mapping field names to field
data.

=item wiki

L<WikiTools> object (or equivalent) for rendering HTML.

=item RETURN

Returns the markup for a table of field information.

=back

=cut

sub _WikiObjectTable {
    # Get the parameters.
    my ($name, $fieldStructure, $wiki) = @_;
    # Compute the table header row and data rows.
    my ($header, $rows) = ComputeFieldTable($wiki, $name, $fieldStructure);
    # Convert it to a table.
    my $retVal = $wiki->Table($header, @$rows);
    # Return the result.
    return $retVal;
}

1;
