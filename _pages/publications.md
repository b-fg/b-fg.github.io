---
layout: article
key: page-publications
show_title: false
---

<div class="mt-4"></div>

<div class="card" style="max-width:100%">
<div class="card__content">
<div markdown="1">
[Google scholar:](https://scholar.google.com/citations?user={{ site.data.scholar.id }})
Citations = **{{ site.data.scholar.citations }}**,
h-index = **{{ site.data.scholar.h_index }}**,
i10-index = **{{ site.data.scholar.i10_index }}**
</div></div></div>

<div class="mt-4"></div>

<h4 id="articles" class="pubyear">Journal Articles</h4>
{% bibliography -f main -q @article %}

<h4 id="inproceedings" class="pubyear">Peer-reviewed Symposium Proceedings</h4>
{% bibliography -f main -q @inproceedings %}

<h4 id="conference" class="pubyear">Conference Proceedings</h4>
{% bibliography -f main -q @proceedings %}

<h4 id="theses" class="pubyear">Theses</h4>
{% bibliography -f main -q @thesis %}

<h4 id="talks" class="pubyear">Invited Talks</h4>
{% bibliography -f main -T {{reference}} -q @bill%}

<p style="margin-top:1cm;"></p>

<script src=
"https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.1/jquery.min.js"
        integrity=
"sha512-v2CJ7UaYy4JwqLDIrZUI/4hqeoQieOmAZNXBeQyjo21dadnwR+8ZaIJVT8EE2iyI61OV8e6M8PP2/4hpQINQ/g=="
        crossorigin="anonymous"
        referrerpolicy="no-referrer">
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