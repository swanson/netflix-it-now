// ==UserScript==
// @name buttonizer
// @include http://movies.netflix.com/*
// @require http://code.jquery.com/jquery-1.6.1.js
// @require https://github.com/allmarkedup/jQuery-URL-Parser/raw/master/jquery.url.js
// @require https://github.com/douglascrockford/JSON-js/raw/master/json2.js
// ==/UserScript==

var url_base = "http://localhost:9393";
var btn_id_raw = "netflix-it-now-btn";
var btn_id = "#" + btn_id_raw;
var blue_btn_class = "btn btn-50 addlk btn-ED-50 btn-rent btn-ED-rent";
var grey_btn_class = "btn btn-50 addlk btn-ED-50 btn-inq btn-ED-inq";

function check_instant() {
    return $("[class='btn btn-50 watchlk btn-play btn-def']").length > 0;
}

function get_title_id() {
    return parseInt($.url().segment(-1));
}

function req_notification() {
    $(btn_id).unbind('click');
    $.post(url_base + "/track", {"movie_id": get_title_id()})
        .success(req_success)
        .error(disp_error_btn);
}

function req_success() {
    var local_tracked = JSON.parse(localStorage["tracked"]);
    local_tracked["tracked"].push(get_title_id());
    localStorage["tracked"] = JSON.stringify(local_tracked);
    disp_requested_btn();
}

function disp_requested_btn() {
    GM_log("displaying request button");
    $(btn_id).removeClass().addClass(grey_btn_class);
    $(btn_id+">span").text("Requested!");
    $(btn_id).show();
}

function disp_error_btn() {
    $(btn_id).removeClass().addClass(grey_btn_class);
    $(btn_id+">span").text("Error!");
    $(btn_id).show();
}

function disp_track_btn() {
    $(btn_id).removeClass().addClass(blue_btn_class);
    $(btn_id+">span").text("Track Instant");
    $(btn_id).click(req_notification);
    $(btn_id).show();
}

function disp_login_btn() {
    $(btn_id).removeClass().addClass(blue_btn_class);
    $(btn_id+">span").text("Login to Tracker");
    $(btn_id).attr('href', url_base);
    $(btn_id).show();
}

function get_tracked() {
    // get the locally tracked movies
    var locally_tracked = JSON.parse(localStorage["tracked"])["tracked"];
    // get the remotely tracked movies
    var remotely_tracked = $.getJSON(url_base + "/tracked")["tracked"];
    // return their combination
    return locally_tracked.concat(remotely_tracked);
}

function got_tracked(json) {
    // get the locally tracked movies
    var locally_tracked = JSON.parse(localStorage["tracked"])["tracked"];
    var remotely_tracked = JSON.parse(json)["tracked"];
    var tracked = locally_tracked.concat(remotely_tracked);
    // check to see if the movie has already been tracked
    if (tracked.indexOf(get_title_id()) < 0) {
        // it hasnt been, display a track button
        disp_track_btn();
    } else {
        // it has been, display the requested button
        disp_requested_btn();
    }
}

function fetch_tracked_error(req) {
    if (req.status == 401) {
        disp_login_btn();
    } else {
        disp_error_btn();
    }
}

// make sure to send cookies in the AJAX requests
$.ajaxSetup({
    xhrFields: {withCredentials: true},
});

// intialize the local storage, if needed
if (localStorage["tracked"] == null) {
    localStorage["tracked"] = JSON.stringify({"tracked": []});
}

if (!check_instant()) {
    // create the button skeleton
    $("#mdp-actions>span[class='btnWrap mltBtn mltBtn-s50']")
        .prepend('<a id="' + btn_id_raw + '"><span class="inr"></span></a>');
    $(btn_id).hide()

    // check the server for already requested movies (cached)
    $.get(url_base + "/tracked")
        .success(got_tracked)
        .error(fetch_tracked_error);
}

