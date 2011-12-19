$(function() {
    $('#province').change(function() {
        $.get('city_get.pl', {province: $('#province').val()}, function(result){
            if(result){
                var html = '';
                for(var i = 0; i < result.length; i++){
                    html += '<option value="' + result[i].id + '">' + result[i].name + '</option>';
                };
                $('#city')
                    .find('option:gt(0)')
                    .remove()
                    .end()
                    .append(html)
                    .val(-1);
                }
        });
    });
});
