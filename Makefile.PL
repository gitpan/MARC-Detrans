use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'MARC::Detrans',
    VERSION_FROM	=> 'lib/MARC/Detrans.pm',
    ABSTRACT_FROM	=> 'lib/MARC/Detrans.pm', 
    AUTHOR		=> 'Ed Summers <ehs@pobox.com>',
    PREREQ_PM		=> 
			    {
                                'MARC::Record'      => '1.38',
                                'Class::Accessor'   => '0.19',
                                'XML::SAX'          => '0.12',
			    },
);
