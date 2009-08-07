// Used to validate the begining and ending times from a timesheet
function validate_time (element) {
    if ( /^(([0-1])[0-9]|[2][0-3]|[1-9])\:([0-5][0-9])$/.test($(element).value) )
        $(element).removeClassName('check_fail').addClassName('check_ok');
    else
        $(element).removeClassName('check_ok').addClassName('check_fail');
}

// Used to clear timesheet's error times before submit
function clear_error_times () {
    elements = $('add_here').getElementsByClassName('check_fail');
    for (i=0; i<elements.length; i++) { elements[i].value = "" }
}

// Used to get the issues from the selected project
function get_issues (element_id, project_id, url, timesheet_id){
	new Ajax.Request(url ,{'method': 'post', evalScripts: true, 'parameters': {'project_id': project_id, 'element_id': element_id, 'id': timesheet_id}});
}

function showTip(e){
	var obj = $('tip');
	var element = Event.element(e);
	Element.clonePosition(obj, element, {'offsetLeft': element.getDimensions().width + 20, 'setWidth': false, 'setHeight': false});
	obj.innerHTML = element.getAttribute("tipValue");
	obj.show();
}
