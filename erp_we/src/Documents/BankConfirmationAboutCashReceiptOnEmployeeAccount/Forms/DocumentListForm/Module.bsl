
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
	EndIf;
	
	If Parameters.Filter.Property("Organization") Then
		
		CompanyFilter = Parameters.Filter.Organization;
		Items.CompanyFilter.ReadOnly = True;
		
	EndIf;
	
	UnconfirmedPayments.Parameters.SetParameterValue(
		"UseCashDepositToListEmployees",
		GetFunctionalOption("UseCashDepositToListEmployees"));
	UnconfirmedPayments.Parameters.SetParameterValue(
		"UsePayroll",
		GetFunctionalOption("UsePayrollTM"));
	
	StartDateOfSalaryTransferViaTransfersOnWay = '00010101';
	StartDateOfSalaryTransferViaTransfersOnWay = 
		Constants.StartDateOfSalaryTransferViaTransfersOnWay.Get();
	UnconfirmedPayments.Parameters.SetParameterValue(
		"StartDateOfSalaryTransferViaTransfersOnWay",
		StartDateOfSalaryTransferViaTransfersOnWay);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.CommandBarForm;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)

	ApplySelection = ValueIsFilled(CompanyFilter);
	
	CommonClientServer.SetDynamicListFilterItem(List,
																			"Organization",
																			CompanyFilter, , ,
																			ApplySelection);
	CommonClientServer.SetDynamicListFilterItem(UnconfirmedPayments,
																			"Organization",
																			CompanyFilter, , ,
																			ApplySelection);

EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.EnrollmentPage Then
		Items.List.Refresh();
	Else
		Items.UnconfirmedPayments.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)

	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure CreateDeposit(Command)
	
	DocumentWriteOffs = Items.UnconfirmedPayments.CurrentRow;
	
	If DocumentWriteOffs = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Basis", DocumentWriteOffs);
	OpenForm("Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.ObjectForm", FormParameters, Items.UnconfirmedPayments);
	
EndProcedure

#EndRegion
