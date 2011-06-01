<div class='input'>
    <label><?php  echo __("widget:page_title"); ?></label><br />
    <?php echo view("input/text", array(
        'name' => 'title',
        'id' => 'title',
        'style' => "width:170px",
        'maxlength' => '22',
        'track_dirty' => true,        
        'value' => @$vars['value']
    )); 
    
    if (!@$vars['value'])
    {
        echo "<div class='help'>".__('widget:page_title_help')."</div>";
    }
    ?>
</div>
