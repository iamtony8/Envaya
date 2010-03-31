<div class='section_content'>
<?php 
    $widget = $vars['widget'];
    $org = $widget->getContainerEntity();

    $offset = (int) get_input('offset');
    $limit = 10;

    $count = $org->getNewsUpdates($limit, $offset, true);
    $entities = $org->getNewsUpdates($limit, $offset);            
?>

<?php if (!empty($entities)) { ?>
<div class='blogView'>
    <strong><?php echo elgg_echo('list') ?></strong> | <a href='<?php echo $entities[0]->getURL() ?>'><?php echo elgg_echo('blog:timeline') ?></a>
</div>
<div style='clear:both'></div>
<?php } ?>
<?php

    echo elgg_view_entity_list($entities, $count, $offset, $limit, false, false, $pagination = true);
    
    if (!$count)
    {
        echo "<div class='padded'>".elgg_echo("widget:news:empty")."</div>";
    }

?>
</div>