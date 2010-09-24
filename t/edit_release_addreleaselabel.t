#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'MusicBrainz::Server::Edit::Release::AddReleaseLabel' }

use MusicBrainz::Server::Constants qw( $EDIT_RELEASE_ADDRELEASELABEL );
use MusicBrainz::Server::Test qw( accept_edit reject_edit );

my $c = MusicBrainz::Server::Test->create_test_context();
MusicBrainz::Server::Test->prepare_test_database($c, '+edit_release_label');
MusicBrainz::Server::Test->prepare_raw_test_database($c);

my $edit = create_edit();
isa_ok($edit, 'MusicBrainz::Server::Edit::Release::AddReleaseLabel');

my ($edits) = $c->model('Edit')->find({ release => 1 }, 10, 0);
is(scalar @$edits, 1);
is($edits->[0]->id, $edit->id);

my $release = $c->model('Release')->get_by_id(1);
is($release->edits_pending, 1, 'Release has edits pending');

reject_edit($c, $edit);

$release = $c->model('Release')->get_by_id(1);
$c->model('ReleaseLabel')->load($release);
is($release->label_count, 1, "Release still has one label after rejected edit");
is($release->labels->[0]->id, 1, "Release label id is 1");

$edit = create_edit();
accept_edit($c, $edit);

$release = $c->model('Release')->get_by_id(1);
$c->model('ReleaseLabel')->load($release);
is($release->label_count, 2, "Release has two labels after accepting edit");
is($release->labels->[0]->id, 1, "First release label is unchanged");
is($release->labels->[1]->id, 2, "Second release label has id 1");
is($release->labels->[1]->label_id, 1, "Second release label has label_id 1");
is($release->labels->[1]->catalog_number, 'AVCD-51002', "Second release label has catalog number AVCD-51002");

done_testing;

sub create_edit {
    return $c->model('Edit')->create(
        edit_type => $EDIT_RELEASE_ADDRELEASELABEL,
        editor_id => 1,
        release_id => 1,
        label_id => 1,
        catalog_number => 'AVCD-51002',
    );
}
