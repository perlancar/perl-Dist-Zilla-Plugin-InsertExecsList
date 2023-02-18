package Dist::Zilla::Plugin::InsertExecsList;

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

has ordered => (is => 'rw', default => sub{1});

use namespace::autoclean;

# AUTHORITY
# DATE
# DIST
# VERSION

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
        my $fullname = $file->name;
        next if $fullname =~ m!^lib[/\\]!;
        my $shortname = $fullname; $shortname =~ s!.+[/\\]!!;
        next if $shortname =~ /^_/;
        push @list, $shortname;
    }
    @list = sort @list;

    join(
        "",
        "=over\n\n",
        (map {"=item ".($self->ordered ? ($_+1).".":"*")." L<$list[$_]>\n\n"} 0..$#list),
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

 =item 1. L<script1>

 =item 2. L<script2>

 =item 3. L<script3>

 =back

 ...


=head1 DESCRIPTION

This plugin finds C<< # INSERT_EXECS_LIST >> directive in your POD/code and
replace it with a POD containing list of scripts/executables in the
distribution.


=head1 CONFIGURATION

=head2 ordered

Bool. Default true. Can be set to false to generate an unordered list instead of
ordered one.


=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertModulesList>
