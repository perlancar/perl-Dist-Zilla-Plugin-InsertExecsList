package Dist::Zilla::Plugin::InsertExecsList;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;
    if ($content =~ s{^#\s*INSERT_EXECS_LIST\s*$}{$self->_insert_execs_list($1, $2)."\n"}egm) {
        $self->log(["inserting execs list into '%s'", $file->name]);
        $file->content($content);
    }
}

sub _insert_execs_list {
    my($self, $file, $name) = @_;

    # XXX use DZR:FileFinderUser's multiple finder feature instead of excluding
    # it manually again using regex

    my @list;
    for my $file (@{ $self->found_files }) {
        my $name = $file->name;
        next if $name =~ s!^lib[/\\]!!;
        $name =~ s!.+[/\\]!!;
        push @list, $name;
    }
    @list = sort @list;

    join(
        "",
        "=over\n\n",
        (map {"=item * L<$_>\n\n"} @list),
        "=back\n\n",
    );
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert a POD containing a list of scripts/executables in the distribution

=for Pod::Coverage .+

=head1 SYNOPSIS

In dist.ini:

 [InsertExecsList]

In lib/Foo.pm:

 ...

 =head1 DESCRIPTION

 This distribution contains the following utilities:

 #INSERT_EXECS_LIST

 ...

After build, lib/Foo.pm will contain:

 ...

 =head1 DESCRIPTION

 This distribution contains the following utilities:

 =over

 =item * L<script1>

 =item * L<script2>

 =item * L<script3>

 =back

 ...


=head1 DESCRIPTION

This plugin finds C<< # INSERT_EXECS_LIST >> directive in your POD/code and
replace it with a POD containing list of scripts/executables in the
distribution.


=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertModulesList>
