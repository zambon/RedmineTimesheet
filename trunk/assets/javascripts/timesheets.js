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

// Used to set and show the Tip container
function showTip(e){
	var obj = $('tip');
	var element = Event.element(e);
	Element.clonePosition(obj, element, {'offsetLeft': element.getDimensions().width + 20, 'setWidth': false, 'setHeight': false});
	obj.innerHTML = element.getAttribute("tipValue");
	obj.show();
}

// Used to help the drop down to set the selected item
function selectValue(e){
	var obj = Event.element(e);
	var parent = obj.parentNode.parentNode;
	parent.getElementsByTagName('span')[0].innerHTML = obj.innerHTML;
	parent.getElementsByTagName('input')[0].value = obj.getAttribute("value");
}

// Used to verify if the current user belongs to the selected project
function belongsToProject(id){
	if($('project_relation_' + id)){
		return true;
	}
	else{
		return false;
	}
}

// Used to validate the project before submit
function beforeSubmit(obj){
	var parentForm = $(obj).up('form');
	var selectProject = parentForm.getElementsBySelector('select[select]')[0];
	var selectedId = selectProject.options[selectProject.selectedIndex].value;
	if(belongsToProject(selectedId)){
		parentForm.onsubmit();
	}
	else{
		if(selectedId != 0){
			if(confirm('This user does not belong to the selected project. Save anyway?')){
				parentForm.onsubmit();
			}
			else{
				return;
			}
		}
		else{
			parentForm.onsubmit();
		}
	}
}