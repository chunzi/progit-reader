package progit::reader;
use Dancer ':syntax';
our $VERSION = '0.01';

use FindBin;
use Path::Class;
use Text::Markdown;

our $repos = dir("$FindBin::Bin/../../progit")->absolute;
die "No progit git repos found: $repos\n" unless -d $repos;
$repos = $repos->resolve;

before sub {
    var repos => $repos;
};

get '/figures/:name' => sub {
    my $name = params->{'name'};
    my $file = $repos->subdir('figures')->file($name)->stringify;
    send_file $file, system_path => 1;
};

get '/' => sub {
    my @langs = grep { /^[a-z]{2}(-[a-z]{2})?$/  }
        map { $_->dir_list(-1) } grep { -d $_ } $repos->children;
    var langs => \@langs;
    template 'index', vars;
};

get '/:lang' => sub {
    my $lang = params->{'lang'};
    my ( $chapters ) = chapters_for_lang( $lang );

    var lang => $lang;
    var chapters => $chapters;
    template 'toc', vars;
};

get '/:lang/:page' => sub {
    my $lang = params->{'lang'};
    my $page = params->{'page'};
    my $lan = get_page( $lang, $page );
    var lan => $lan;
    template 'page', vars;
};

get '/pair/:lang/:page' => sub {
    my $lang = params->{'lang'};
    my $page = params->{'page'};

    my $eng = get_page( 'en', $page );
    my $lan = get_page( $lang, $page );
    var lan => $lan;
    var eng => $eng;

    my @eng_para = split /\n\n/, $eng->{'html'};
    my @lan_para = split /\n\n/, $lan->{'html'};

    my @paras = ();
    while( scalar @eng_para and scalar @lan_para ){
        push @paras, { eng => shift @eng_para, lan => shift @lan_para };
    }
    var paras => \@paras;

    template 'pair', vars;
};

sub get_page {
    my $lang = shift;
    my $page = shift;

    my ( $chapters, $chain ) = chapters_for_lang( $lang );

    my ( $chapter, $section ) = map { int($_) } ( $page =~ /^ch(\d+)-(\d+)\.html$/ );
    $chapter = 1 if $chapter < 1; $chapter = scalar @$chapters if $chapter > scalar @$chapters;
    my $sections = $chapters->[$chapter-1]{'sections'};
    $section = 0 if $section < 0; $section = scalar @$sections if $section > scalar @$sections;

    my $path = $chapters->[$chapter-1]{'path'};
    
    my $this = sprintf "ch%d-%d.html", $chapter, $section;
    my $prev = $this; 
    my $next = $this;
    for my $pos ( 0 .. $#{$chain} ){
        if ( $chain->[$pos] eq $this ){
            $prev = $chain->[$pos-1]; 
            $next = $chain->[$pos+1]; 
        }
    }

    my $text = $sections->[$section]->{'content'};
    $text =~ s{Insert\s+(.*?)\.png\s*\n?\s*(.*?)\n}{![$2](/figures/$1-tn.png "$2")\n\n$2\n}sg;

    my $m = Text::Markdown->new;
    my $html = $m->markdown($text);

    return { lang => $lang, page => $page, html => $html, prev => $prev, next => $next, path => $path };
}

sub chapters_for_lang {
    my $lang = shift;

    #------------------------------------
    # prepare the markdown file list
    # fallback to english version if that chapter missing in the given language
    my @chapter_files = map {
        my $langfile = $_; 
        $langfile =~ s{\ben\b}{$lang}e;
        my $path = ( -f $langfile ) ? $langfile : $_;
        file $path;
    }
    map { map { $_->stringify } grep { -f } $_->children } 
    sort grep { -d } $repos->subdir('en')->children;


    #------------------------------------
    # grab the table of content
    my @chapters; my @chain = ( 'index.html' );
    for my $path ( @chapter_files ){
        my $text = $path->slurp;
        my ( $chapter_title ) = ( $text =~ /#\s+(.*?)\s+#\n/ );
        my @sections;
        my $cid = scalar @chapters + 1;
        for ( split(/(?=##\s+.*?\s+##\n)/, $text) ){
            my ( $section_title ) = ( /##\s+(.*?)\s+##/ );
            my $sid = scalar @sections;
            push @chain, sprintf "ch%d-%d.html", $cid, $sid;
            push @sections, {
                title => $section_title,
                content => $_,
            }
        }
        push @chapters, {
            title => $chapter_title,
            sections => \@sections, 
            path => $path,
        }
    }
    return \@chapters, \@chain;
}

true;
