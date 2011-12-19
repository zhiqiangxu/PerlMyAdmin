$(function() {
    $('#reset').click(function() {
        $('#province, #city').val(-1);
        $('#search_text').val('');
        $('#search_button').click();
    });        
});
