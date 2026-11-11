
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser());
	
	If Partner = Undefined Or Partner.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	AgreementList.Parameters.SetParameterValue("Partner",Partner);
	AgreementList.Parameters.SetParameterValue("CurrentDate",BegOfDay(CurrentSessionDate()));
	
	UseStandardTermsOfSalesWithCustomers         = GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales  = GetFunctionalOption("UseCustomerTermsOfSales");
	OnlyStandard = UseStandardTermsOfSalesWithCustomers And Not UseCustomerTermsOfSales;
	OnlyPersonal = Not UseStandardTermsOfSalesWithCustomers And UseCustomerTermsOfSales;
	
	AgreementList.Parameters.SetParameterValue("OnlyStandard",OnlyStandard);
	AgreementList.Parameters.SetParameterValue("OnlyPersonal",OnlyPersonal);
	
	// StandardSubsystems.AttachableCommands
	TypesList = AgreementList.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.FormCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAgreementList

&AtClient
Procedure AgreementListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Print();
	
EndProcedure

&AtClient
Procedure AgreementListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Print()

	CurrentData = Items.AgreementList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SelfServiceClient.PrintClientAgreement(CurrentData.Ref);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.AgreementList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.AgreementList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.AgreementList);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
