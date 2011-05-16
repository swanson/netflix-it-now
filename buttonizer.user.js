// ==UserScript==
// @name buttonizer
// @include http://movies.netflix.com/*
// @require http://code.jquery.com/jquery-1.6.1.js
// @require https://github.com/allmarkedup/jQuery-URL-Parser/raw/master/jquery.url.js
// @require http://courses.ischool.berkeley.edu/i290-4/f09/resources/gm_jq_xhr.js
// ==/UserScript==


function check_instant() {
    return $("[class='btn btn-50 watchlk btn-play btn-def']").length > 0;
}

function get_title_id() {
    return $.url().segment(-1);
}

function req_success() {
    $("#req-instant-btn").removeClass().addClass("btn btn-50 addlk btn-ED-50 btn-inq btn-ED-inq");
    $("#req-instant-btn>span").html("Requested!");
}

function req_error() {
    $("#req-instant-btn").removeClass().addClass("btn btn-50 addlk btn-ED-50 btn-inq btn-ED-inq");
    $("#req-instant-btn>span").html("Error!");
}

function req_notification() {
    $.post("http://netflix-it-now.heroku.com/track", {"email": "jevin@purdue.edu", "movie_id": get_title_id()})
        .success(req_success)
        .error(req_error);
}

if (!check_instant()) {
    $("#mdp-actions>span[class='btnWrap mltBtn mltBtn-s50']").prepend('<a id="req-instant-btn" class="btn btn-50 addlk btn-ED-50 btn-rent btn-ED-rent"><span class="inr">Track Instant</span></a>');
    $("#req-instant-btn").click(req_notification);
}

