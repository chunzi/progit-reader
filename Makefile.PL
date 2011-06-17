use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'progit::reader',
    AUTHOR       => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM => 'lib/progit/reader.pm',
    ABSTRACT     => 'YOUR APPLICATION ABSTRACT',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'YAML'           => 0,
        'Dancer'         => 1.3060,
        'FindBin'        => 0,
        'Path::Class'    => 0,
        'Text::Markdown' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'progit-reader-*' },
);

