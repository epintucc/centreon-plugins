################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package database::postgres::mode::tablespace;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', default => ''},
                                  "critical:s"              => { name => 'critical', default => ''},
                                  "tablespace:s"            => { name => 'tablespace', }, # tablespace nema to check
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    
    my $target_fields = undef;

    # Query to get tablespace size
    my $query = sprintf("SELECT pg_tablespace_size('%s') FROM pg_tablespace LIMIT 1;",$self->{option_results}->{tablespace});
    $self->{sql}->query(query => $query);

    my $result = $self->{sql}->fetchrow_array();
    
    if (defined($result)) {
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $result, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my ($value, $value_unit) = $self->{perfdata}->change_bytes(value => $result);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf('Tablespace "%s" size is %d %s',$self->{option_results}->{tablespace}, $value, $value_unit));
        
        $self->{output}->perfdata_add(label => $self->{option_results}->{tablespace},
                                      value => $result,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    } else {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf('Table space "%s" is unknown ...',$self->{option_results}->{tablespace}));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check a tablespace size

=over 8

=item B<--warning>

Threshold warning in bytes, maximum size allowed.

=item B<--critical>

Threshold critical in bytes, maximum size allowed.

=back

=cut