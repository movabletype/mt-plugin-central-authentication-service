package MT_CAS::Tags;

use strict;
use warnings;

sub _hdlr_sign_in_link {
    my ($ctx, $args) = @_;    
    my $cfg = $ctx->{config};
    my $blog = $ctx->stash('blog');
    my $path = $ctx->_hdlr_cgi_path();
    $path .= '/' unless $path =~ m!/$!;
    my $comment_script = $cfg->CommentScript;
    my $static_arg = $args->{static} ? "&static=" . $args->{static} : '';
    my $e = $ctx->stash('entry');
    return "$path$comment_script?__mode=cas_login$static_arg" .
        ($blog ? '&blog_id=' . $blog->id : '') .
        ($e ? '&entry_id=' . $e->id : '');
}

sub _hdlr_sign_out_link {
    my ($ctx, $args) = @_;
    my $cfg = $ctx->{config};
    my $path = $ctx->_hdlr_cgi_path();
    $path .= '/' unless $path =~ m!/$!;
    my $comment_script = $cfg->CommentScript;
    my $static_arg;
    if ($args->{no_static}) {
        $static_arg = q();
    } else {
        my $url = $args->{static};
        if ($url && ($url ne '1')) {
            $static_arg = "&static=" . MT::Util::encode_url($url);
        } elsif ($url) {
            $static_arg = "&static=1";
        } else {
            $static_arg = "&static=0";
        }
    }
    my $e = $ctx->stash('entry');
    return "$path$comment_script?__mode=handle_sign_in$static_arg&logout=1" .
        ($e ? "&amp;entry_id=" . $e->id : '');
}

1;
__END__
