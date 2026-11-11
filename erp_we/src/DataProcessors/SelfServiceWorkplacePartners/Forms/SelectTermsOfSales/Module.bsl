
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Partner") Then
		
		Partner = Parameters.Partner;
		AgreementList.Parameters.SetParameterValue("Partner",Parameters.Partner);
		AgreementList.Parameters.SetParameterValue("CurrentDate",BegOfDay(CurrentSessionDate()));
		AgreementList.Parameters.SetParameterValue("ThePlanningDetailsAreSpecified",Parameters.Property("ThePlanningDetailsAreSpecified"));
		
		If Parameters.Property("Terms") Then
			Items.AgreementList.CurrentRow = Parameters.Terms;
		EndIf;
		
		If Parameters.Property("BusinessOperation") Then
			CommonClientServer.SetDynamicListFilterItem(
			             AgreementList, "BusinessOperation",
			             Parameters.BusinessOperation, DataCompositionComparisonType.Equal);
		EndIf;
	Else
		
		Cancel = True;
		Return;
		
	EndIf;
	
	ReturnOnlyAgreement = Parameters.ReturnOnlyAgreement;
	
	UseMultipleCurrencies                      = GetFunctionalOption("UseMultipleCurrencies");
	If Not UseMultipleCurrencies Then
		IBCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
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

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAgreementList

&AtClient
Procedure AgreementListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	ProcessSelection();
	
EndProcedure

&AtClient
Procedure AgreementListBeforeRowChange(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessSelection();
	
	CurrentData = Items.AgreementList.CurrentData;
	If CurrentData = Undefined Then
		
		Close();
		
	ElsIf ReturnOnlyAgreement Then
		
		NotifyChoice(CurrentData.Ref);
		
	Else
		
		ReturnStructure = New Structure;
		ReturnStructure.Insert("Terms", CurrentData.Ref);
		ReturnStructure.Insert("AgreementLine", CurrentData.Description);
		ReturnStructure.Insert("Currency", ?(ValueIsFilled(IBCurrency), IBCurrency, CurrentData.Currency));
		ReturnStructure.Insert("Warehouse", CurrentData.Warehouse);
		ReturnStructure.Insert("PriceIncludesVAT", CurrentData.PriceIncludesVAT);
		ReturnStructure.Insert("PaymentSchedule", CurrentData.PaymentSchedule);
		ReturnStructure.Insert("Counterparty", CurrentData.Counterparty);
		ReturnStructure.Insert("Organization", CurrentData.Organization);
		ReturnStructure.Insert("BusinessOperation", CurrentData.BusinessOperation);
		ReturnStructure.Insert("ARAPObjectSettings", CurrentData.ARAPObjectSettings);
		ReturnStructure.Insert("ThisIsWarehouseGroup", CurrentData.ThisIsWarehouseGroup);
		ReturnStructure.Insert("ContractsAreUsed", CurrentData.ContractsAreUsed);
		ReturnStructure.Insert("ProductSegment", CurrentData.ProductSegment);
		ReturnStructure.Insert("Scenario", CurrentData.Scenario);
		ReturnStructure.Insert("PlanProfile", CurrentData.PlanProfile);
		ReturnStructure.Insert("Periodicity", CurrentData.Periodicity);
		ReturnStructure.Insert("PlanByAmount", CurrentData.PlanByAmount);
		ReturnStructure.Insert("Partner",Partner);
		ReturnStructure.Insert("ToReturnReusablePackage", CurrentData.ToReturnReusablePackage);
		ReturnStructure.Insert("ReusablePackageReturnCycleLength", CurrentData.ReusablePackageReturnCycleLength);
		ReturnStructure.Insert("PackageDepositIsRequired", CurrentData.PackageDepositIsRequired);
		
		If Not ValueIsFilled(CurrentData.PaymentSchedule) Then
			PaymentMethod = CurrentData.PaymentMethod;
		Else
			PaymentMethod = GetFormOfPayment(CurrentData.PaymentSchedule);
		EndIf;
		
		Close(ReturnStructure);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetFormOfPayment(PaymentSchedule)
	Return Common.ObjectAttributeValue(PaymentSchedule, "PaymentMethod");
EndFunction

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
