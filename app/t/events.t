use t::common;
use parent qw(Test::Class);

use Play::DB qw(db);

sub setup :Tests(setup) {
    Dancer::session->destroy;
    reset_db();
}

sub event_perl_api :Tests {
    db->events->add({ blah => 5, boo => 6 });
    db->events->add({ foo => 'bar' });

    cmp_deeply(
        db->events->list,
        [
            { foo => 'bar', ts => re('^\d+$'), _id => re('^\S+$') }, # last in, first out
            { blah => 5, boo => 6, ts => re('^\d+$'), _id => re('^\S+$') },
        ]
    );
}

sub limit_offset :Tests {
    db->events->add({ name => "e$_" }) for (1 .. 200);

    my $list = http_json GET => '/api/event';
    is scalar @$list, 100;

    $list = http_json GET => '/api/event?limit=30';
    is scalar @$list, 30;
    cmp_deeply
        [ map { $_->{name} } @$list ],
        [ map { "e$_" } reverse 171 .. 200 ];

    $list = http_json GET => '/api/event?limit=30&offset=50';
    is scalar @$list, 30;
    cmp_deeply
        [ map { $_->{name} } @$list ],
        [ map { "e$_" } reverse 121 .. 150 ];
}

sub list :Tests {
    db->events->add({ blah => 5 });
    db->events->add({ blah => 6 });

    my $list = http_json GET => '/api/event';
    cmp_deeply
        $list,
        [
            { blah => 6, _id => re('^\S+$'), ts => re('^\d+$') },
            { blah => 5, _id => re('^\S+$'), ts => re('^\d+$') },
        ]
}

sub atom :Tests {
    # add-user event
    http_json GET => '/api/fakeuser/Frodo';

    # add-quest event
    my $add_result = http_json POST => '/api/quest', {
        user => 'Frodo',
        name => 'Destroy the Ring',
        status => 'open',
    };

    my $response = dancer_response GET => '/api/event/atom';
    is $response->status, 200;

    like $response->content, qr/Frodo joins Play Perl/;
}

__PACKAGE__->new->runtests;
