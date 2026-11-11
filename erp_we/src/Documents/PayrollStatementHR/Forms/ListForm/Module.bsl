#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	#Region UniversalMechanisms
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
	List, "Organization", FilterOrganization, QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
	List, "Department", FilterDepartment, QuickFilterStructure);
	
	If Parameters.Property("Employee") Then
		FilterEmployee = Parameters.Employee;
		CommonClientServer.SetDynamicListFilterItem(List, "Ref.Content.Individual",
			GetEmployeePerson(), DataCompositionComparisonType.Equal, , True);
	EndIf;
	
	UsePaymentRequests = GetFunctionalOption("UsePaymentRequests");
	
	SetVisibilityAvailabilityATServer();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Organization", FilterOrganization,
	QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Department", FilterDepartment,
	QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", FilterOrganization,
	DataCompositionComparisonType.Equal, , ValueIsFilled(FilterOrganization));
EndProcedure

&AtClient
Procedure FilterOrganizationClearing(Item, StandardProcessing)
	If Not ValueIsFilled(FilterOrganization) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", FilterDepartment,
	DataCompositionComparisonType.Equal, , ValueIsFilled(FilterDepartment));
	
EndProcedure

&AtClient
Procedure FilterDepartmentClearing(Item, StandardProcessing)
	If Not ValueIsFilled(FilterDepartment) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterEmployeeOnChange(Item)
	
	Use = ValueIsFilled(FilterEmployee);
	Individual = GetEmployeePerson();
	
	CommonClientServer.SetDynamicListFilterItem(
	List, "Ref.Content.Individual", Individual, 
	DataCompositionComparisonType.Equal,, Use);
	
EndProcedure

&AtClient
Procedure FilterEmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ParametersForOpeningSelection = New Structure();
	
	If ValueIsFilled(FilterDepartment) Then
		ParametersForOpeningSelection.Insert("Organization", FilterOrganization);
	EndIf;
	
	If ValueIsFilled(FilterDepartment) Then
		ParametersForOpeningSelection.Insert("Department", FilterDepartment);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", ParametersForOpeningSelection);
	
	OpenForm("Catalog.EmployeesHR.Form.ChoiceFormInternational", FormParameters, Items.FilterEmployee);
	
EndProcedure

&AtClient
Procedure FilterEmployeeClearing(Item, StandardProcessing)
	If Not ValueIsFilled(FilterEmployee) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)

	If Not Item.CurrentData = Undefined And Item.CurrentData.Property("PaymentMethodHR") Then
		PaymentMethodHR = Item.CurrentData.PaymentMethodHR;
		If Not Items.Find("FormDocumentIsOutgoPaymentCashAccountToCreateOnBasisOfPayrollStatementsForPaymentOfHR")
			= Undefined Then
			Items.FormDocumentIsOutgoPaymentCashAccountToCreateOnBasisOfPayrollStatementsForPaymentOfHR.Visible = PaymentMethodHR
				= PredefinedValue("Enum.PaymentMethodsHR.CashAccount")
				And Not UsePaymentRequests;
		EndIf;
		If Not Items.Find(
			"FormDocumentOutgoingPaymentBankAccountBeCreatedOnBasisOfStatementsOnPaymentHR") = Undefined Then
			Items.FormDocumentOutgoingPaymentBankAccountBeCreatedOnBasisOfStatementsOnPaymentHR.Visible = PaymentMethodHR
				= PredefinedValue("Enum.PaymentMethodsHR.EmployeeSBankAccount")
				And Not UsePaymentRequests;
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region Universal_

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

&AtServer
Function GetEmployeePerson()

	Return Common.ObjectAttributeValue(FilterEmployee, "Individual");
	
EndFunction

&AtServer
Procedure SetVisibilityAvailabilityATServer()

	If Not Items.Find("FormDocumentPaymentRequestToCreateOnBasisOfStatementsForPayment")
		= Undefined Then
		Items.FormDocumentPaymentRequestToCreateOnBasisOfStatementsForPayment.Visible = UsePaymentRequests;
	EndIf;
	If Not Items.Find("FormDocumentIsOutgoPaymentCashAccountToCreateOnBasisOfPayrollStatementsForPaymentOfHR")
		= Undefined Then
		Items.FormDocumentIsOutgoPaymentCashAccountToCreateOnBasisOfPayrollStatementsForPaymentOfHR.Visible = Not UsePaymentRequests;
	EndIf;
	If Not Items.Find("FormDocumentOutgoingPaymentBankAccountBeCreatedOnBasisOfStatementsOnPaymentHR")
		= Undefined Then
		Items.FormDocumentOutgoingPaymentBankAccountBeCreatedOnBasisOfStatementsOnPaymentHR.Visible = Not UsePaymentRequests;
	EndIf;

EndProcedure

#EndRegion
