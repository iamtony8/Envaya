<div class='padded'>
<?php

PageContext::add_header_html('<meta name="robots" content="noindex,follow" />'); 

$sector = $vars['sector'];
$region = $vars['region'];
$items = $vars['items'];
$first_id = (int)$vars['first_id'];

?>

<script type='text/javascript'>
function sectorChanged()
{
    var sectorList = $('sectorList');
    var regionList = $('regionList');
    var sector = sectorList.options[sectorList.selectedIndex].value;
    var region = regionList.options[regionList.selectedIndex].value;
    window.location.href = "/org/feed?sector=" + sector + "&region=" + region;
}
</script>

<form method='GET' action='/org/feed'>
<?php

echo view('input/pulldown', array(
    'name' => 'sector',
    'id' => 'sectorList',
    'options' => OrgSectors::get_options(),
    'empty_option' => __('sector:empty_option'),
    'value' => $sector,
    'js' => "onchange='sectorChanged()' onkeypress='sectorChanged()'"
));

echo view('input/pulldown', array(
    'name' => 'region',
    'id' => 'regionList',
    'options' => Geography::get_region_options('tz'),
    'empty_option' => __('region:empty_option'),
    'value' => $region,
    'js' => "onchange='sectorChanged()' onkeypress='sectorChanged()'"
));
    
?>
<noscript>
<?php echo view('input/submit', array('value' => __('go'))); ?>
</noscript>

</form>
</div>

<div id='feed_container'>
<?php	
	echo view('feed/list', array('items' => $items, 'show_edit_controls' => Session::isadminloggedin()));
?>
<div class='separator'></div>
</div>

<?php 
if ($first_id)
{
?>

<script type='text/javascript'>
<?php
    echo view('js/xhr');
    echo view('js/dom');
?>
var fetchMoreXHR = null;
var first_id = <?php echo json_encode($first_id); ?>;

function loadMore()
{
    if (first_id)
    {
        var link = $('load_more_link');
        if (link.blur)
        {
            link.blur();
        }
        link.style.display = 'none';
        $('load_more_progress').style.display = 'block';    
    
        var $src = "/org/feed_more?before_id=" + first_id + "&sector=" +
            <?php echo json_encode(escape($sector)); ?> + "&region=" + <?php echo json_encode(escape($region)); ?>;

        if (fetchMoreXHR)
        {
            fetchMoreXHR.abort();
            fetchMoreXHR = null;
        }
        fetchMoreXHR = fetchJson($src, itemsLoaded);
    }
}
function itemsLoaded(res)
{
    var container = $('feed_container');
    var childContainer = createElem('div');
    childContainer.innerHTML = res.items_html + "<div class='separator'></div>";
    container.appendChild(childContainer);
    first_id = res.first_id;
        
    $('load_more_link').style.display = 'inline';
    $('load_more_progress').style.display = 'none';
    
    if (!res.first_id)
    {
        $('load_more').style.display = 'none';
    }
}
</script>
<div id='load_more'>
<a id='load_more_link' href='javascript:loadMore()'><?php echo __('feed:show_more'); ?></a>
<div id='load_more_progress' style='display:none'><?php echo __('loading'); ?></div>
</div>
<?php 
 }
?>