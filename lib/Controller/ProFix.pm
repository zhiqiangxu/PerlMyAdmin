package Controller::ProFix;
use strict;
use warnings;
use HTML::Entities;

#work around for Pro's weakness, ugly,never extensible, use once and throw away!
sub rows_to_html {
    my ($self, $rows_ref, $pk) = @_;
    my $html = '';
    if(exists $rows_ref->[0]){
        $html .= '<tr>';
        $html .= '<th>OP</th>';
        while(my ($k, $v) = each(%{$rows_ref->[0]})){
            $html .= "<th>$k</th>";
        }
        $html .= '</tr>';
        foreach my $h_ref (@{$rows_ref}){
            $html .= '<tr>';
            $html .= '<td><span><a href="?for=right&model=' . $self->param('model') . '&action=before_update&' . $pk . '=' . $h_ref->{$pk} . '">Edit</a></span>|<span><a href="?for=right&model=' . $self->param('model') . '&action=before_delete&' . $pk . '=' . $h_ref->{$pk} . '">Delete</a></span></td>';
            while(my ($k, $v) = each(%{$h_ref})){
                $html .= "<td>" . encode_entities($v, '<>&"') . "</td>";
            }
            $html .= '</tr>';
        }
    }
    else{
    }
    return $html;
}

sub row_to_literal_html {
    my ($self, $row_ref, $pk, $model_name) = @_;
    my $referrer = $self->query->referer;
    my $html = <<END;
        <form method="POST" action="?for=right&model=$model_name&action=delete&$pk=$row_ref->{$pk}">
            <table>
                <tr>
                    <td>$pk</td>
                    <td>
                        <span>$row_ref->{$pk}</span>
                        <input type="hidden" name="$pk" value="$row_ref->{$pk}" />
                        <input type="hidden" name="referrer" value="$referrer" />
                    </td>
                </tr>
END
    while( my ($k, $v) = each(%{$row_ref} )){
        if($pk ne $k){
            $v = encode_entities($v, '<>&"');
            $html .= <<END;
                <tr><td>$k</td><td><span>$v</span></td></tr>
END
        }
    }
    $html .= <<END;
                <tr><td><input type="submit" value="Confirm!" /></td><td><input onclick="javascript:window.location='$referrer';" type="button" value="Cancel" /></td></tr>
            </table>
        </form>
END
    return $html;

}

sub empty_row_to_html {
    my ($self, $row_ref, $pk, $model_name) = @_;
    my $referrer = $self->query->referer;
    my $html = <<END;
        <form method="POST" action="?for=right&model=$model_name&action=insert">
            <input type="hidden" name="referrer" value="$referrer">
            <table>
END
    while( my ($k, $v) = each(%{$row_ref} )){
        if($pk ne $k){
            $v = encode_entities($v, '<>&"');
            $html .= <<END;
                <tr><td>$k</td><td><input type="text" value="$v" name="$k"></td></tr>
END
        }
    }
    $html .= <<END;
                <tr><td><input type="submit" value="Submit" /></td><td><input onclick="javascript:window.location='$referrer';" type="button" value="Cancel" /></td></tr>
            </table>
        </form>
END
    return $html;

}

sub row_to_html {
    my ($self, $row_ref, $pk, $model_name) = @_;
    my $referrer = $self->query->referer;
    my $html = <<END;
        <form method="POST" action="?for=right&model=$model_name&action=update&$pk=$row_ref->{$pk}">
            <table>
                <tr>
                    <td>$pk</td>
                    <td>
                        $row_ref->{$pk}
                        <input type="hidden" name="$pk" value="$row_ref->{$pk}">
                        <input type="hidden" name="referrer" value="$referrer">
                    </td>
                </tr>
END
    while( my ($k, $v) = each(%{$row_ref} )){
        if($pk ne $k){
            $v = encode_entities($v, '<>&"');
            $html .= <<END;
                <tr><td>$k</td><td><input type="text" value="$v" name="$k"></td></tr>
END
        }
    }
    $html .= <<END;
                <tr><td><input type="submit" value="Submit" /></td><td><input onclick="javascript:window.location='$referrer';" type="button" value="Cancel" /></td></tr>
            </table>
        </form>
END
    return $html;
}

sub html_new {
    my ($self, $model_name) = @_;
    my $referrer = $self->query->referer;
    my $html = <<END;
            <table>
                <tr>
                    <td><a href="?for=right&model=$model_name&action=before_insert">New</a></td>
                </tr>
            </table>
            <hr />
END
    return $html;
}

1
