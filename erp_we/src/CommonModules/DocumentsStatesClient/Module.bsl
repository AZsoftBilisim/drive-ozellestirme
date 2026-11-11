/////////////////////////////////////////////////////////////////////////
// The module "Document Statessclientserver" contains procedures and functions
// for working with the document State mechanism.
//
/////////////////////////////////////////////////////////////////////////

#Region Public

// The post-entry handler for order forms.
// Checks the launch capability and starts the handler waiting for the task to be checked to reflect the State of orders.
// 
// Parameters:
//  Form - See DocumentsStates.AfterWriteAtServer.Form
//  HandlerName - String - the name of the waiting handler procedure for the task to reflect the State of orders.
//                            By default, "Pluggable_Check the tasks and display the status of orders."
//
Procedure AfterWrite(Form, HandlerName = "Attachable_CheckTasksToReflectStateOfOrders") Export
	
	If Not StartTaskVerificationToReflectStateOfOrders(Form) Then
		Return;
	EndIf;
	
	Form.IndicatesWhetherTaskIsBeingCheckedToReflectStateOfOrders = 2;
	
	Form.AttachIdleHandler(HandlerName, 1);
	
EndProcedure

// Returns a flag for whether task verification has started to reflect the State of orders.
// 
// Parameters:
//  Form - See DocumentsStates.AfterWriteAtServer.Form
// 
// Returns:
//  Boolean - indicates whether the task is being checked to reflect the State of orders.
//
Function StartTaskVerificationToReflectStateOfOrders(Form) Export
	
	Return Form.IndicatesWhetherTaskIsBeingCheckedToReflectStateOfOrders = 1;
	
EndFunction

// Returns a flag for whether task verification has started to reflect the State of orders.
// 
// Parameters:
//  Form - See DocumentsStates.AfterWriteAtServer.Form
// 
// Returns:
//  Boolean - indicates whether the task is being checked to reflect the State of orders.
//
Function StartOfTaskVerificationToReflectStateOfOrders(Form) Export
	
	Return Form.IndicatesWhetherTaskIsBeingCheckedToReflectStateOfOrders = 2;
	
EndFunction

// Returns the check the order to reflect the State of orders in progress flag.
// 
// Parameters:
//  Form - See DocumentsStates.AfterWriteAtServer.Form
// 
// Returns:
//  Boolean - flag for checking the order to reflect the State of orders in progress
//
Function TaskIsBeingCheckedToReflectStateOfOrders(Form) Export
	
	Return Form.IndicatesWhetherTaskIsBeingCheckedToReflectStateOfOrders = 3;
	
EndFunction

// Sets the check the order to reflect the State of orders in progress flag.
// 
// Parameters:
//  Form - See DocumentsStates.AfterWriteAtServer.Form
//
Procedure SetTaskCheckToReflectStateOfOrdersFlagInProgress(Form) Export
	
	Form.IndicatesWhetherTaskIsBeingCheckedToReflectStateOfOrders = 3;
	
EndProcedure

// Processes the result of task verification to reflect the State of orders.
// 
// Parameters:
//  Form - See DocumentsStates.AfterWriteAtServer.Form
//  ThereAreTasksToReflectStateOfOrders - Boolean - indicates whether there is a task to reflect the State of orders
//  HandlerName - See AfterWrite.HandlerName
//  NameOfElementState - String - the name of the State form element.
//                                  The default is "State".
//  GroupNameStateIsCalculated - String - the name of the group of form elements the State is calculated.
//                                              By default, "groupstates are not counted".
//
Procedure ProcessTaskVerificationResultToReflectStateOfOrders(
			Form,
			ThereAreTasksToReflectStateOfOrders,
			HandlerName = "Attachable_CheckTasksToReflectStateOfOrders",
			NameOfElementState = "State",
			GroupNameStateIsCalculated = "GroupStateIsCalculated") Export
	
	If ThereAreTasksToReflectStateOfOrders Then
		Return;
	EndIf;
	
	Form.IndicatesWhetherTaskIsBeingCheckedToReflectStateOfOrders = 0;
	
	Form.DetachIdleHandler(HandlerName);
	
	DocumentsStatesClientServer.SetItemsVisibility(
		Form.Items,
		NameOfElementState,
		GroupNameStateIsCalculated,
		False);
	
EndProcedure

// Complements the structure of the State of the order with the key "There are tasks to display the status of orders".
// 
// Parameters:
//  StateStructure_ - Structure - the structure of the State of the order.
//
Procedure CompleteStructureOfOrderState(StateStructure_) Export
	
	StateStructure_.Insert("ThereAreTasksToReflectStateOfOrders", False);
	
EndProcedure

#EndRegion