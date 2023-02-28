---
layout: article
permalink: /publications/
title: Publications
show_title: false
---
<div class="mt-3"></div>

<h4 id="articles" class="pubyear">Journal Articles</h4>
{% bibliography -f papers -q @article %}

<h4 id="inproceedings" class="pubyear">Peer-reviewed Symposium Proceedings</h4>
{% bibliography -f papers -q @inproceedings %}

<h4 id="conference" class="pubyear">Conference Proceedings</h4>
{% bibliography -f papers -q @proceedings %}

<h4 id="abstracts" class="pubyear">Conference Abstracts</h4>
{% bibliography -f papers -q @conference %}

<h4 id="theses" class="pubyear">Theses</h4>
{% bibliography -f papers -q @thesis %}

<h4 id="talks" class="pubyear">Invited Talks</h4>
{% bibliography -f papers -T {{reference}} -q @booklet%}

<p style="margin-top:1cm;"></p>

<div class="card" style="max-width:100%">
<div class="card__content">
<div markdown="1">
[Google scholar:](https://scholar.google.com/citations?user={{ site.data.scholar.id }})
Citations = **{{ site.data.scholar.citations }}**,
h-index = **{{ site.data.scholar.h_index }}**,
i10-index = **{{ site.data.scholar.i10_index }}**
</div></div></div>

<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
<script>
$(document).ready(function(){
    var str =$(this).attr('id');

    $(".btnId").click(function(){
        var str = $(this).attr('id');
        var ret = str.split("_");
        var id = ret[1];
        $('#' + id).toggle();
    });
});
</script>
