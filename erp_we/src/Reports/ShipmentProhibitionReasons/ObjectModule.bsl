#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = False;
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	ParametersForm = ThisForm.ParametersForm;
	
	If ParametersForm.Property("Filter") And ParametersForm.Filter.Property("Contract") And ValueIsFilled(ParametersForm.Filter.Contract) Then
		ParametersContent = "
		|LimitDebtAmount,
		|AllowableAmountPayable,
		|ShipmentIsProhibitedInCaseOfARAPOverdue";
		
		ContractData = Common.ObjectAttributesValues(ParametersForm.Filter.Contract, ParametersContent);
		ParametersForm.Filter.Insert("AllowableAmountPayable", ContractData.AllowableAmountPayable);
		
		If ContractData.LimitDebtAmount And ContractData.ShipmentIsProhibitedInCaseOfARAPOverdue Then
			CurrentVariantKey = "ProhibitionOfShipmentOnCreditAndDelay";
		ElsIf ContractData.LimitDebtAmount Then
			CurrentVariantKey = "ProhibitionOfCreditShipment";
		ElsIf ContractData.ShipmentIsProhibitedInCaseOfARAPOverdue Then
			CurrentVariantKey = "ProhibitionOfShipmentByDelay";
		EndIf;
	EndIf;
	
	If Parameters.Property("DataOnSaleAmount") And Parameters.DataOnSaleAmount.Property("AmountARAP") Then
		ParametersForm.Filter.Insert("SalesAmount", Parameters.DataOnSaleAmount.AmountARAP);
	ElsIf Parameters.Property("DataOnSaleAmount") Then
		ParametersForm.Filter.Insert("SalesAmount", CalculateAmountOfSettlements(Parameters.DataOnSaleAmount));
	EndIf;
	
	If Parameters.Property("DataOnSaleAmount") And Parameters.DataOnSaleAmount.Property("Date") Then
		PerDate_ = ?(Parameters.DataOnSaleAmount.Date > CurrentSessionDate(), EndOfDay(Parameters.DataOnSaleAmount.Date), EndOfDay(CurrentSessionDate()));
		ParametersForm.Filter.Insert("ReportDate", PerDate_);       
	Else
		ParametersForm.Filter.Insert("ReportDate", EndOfDay(CurrentSessionDate())); 
	EndIf;
	
EndProcedure

// When loading user settings on the server.
//  Called in the report form handler of the same name after executing the form code. 
// Parameters:
//  ThisForm = Client Application Form - Report form.  
//  NewDCUserSettings - DataCompositionUserSettings - Custom CD settings
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCUserSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	
	PartnersAndCounterparties.DeleteItemFromReportSelectionSettings(Report.SettingsComposer, "Counterparty");
	
	NewDCUserSettings = FormSettingsComposer.UserSettings;
	
EndProcedure

#EndRegion

#Region Private
Function CalculateAmountOfSettlements(ParametersStructure)
	
	ParametersStructure.Insert("AmountARAP");
	ARAPAccountingServer.FillInAmountOfSettlements(ParametersStructure);
	Return ParametersStructure.AmountARAP;
	
EndFunction
#EndRegion

#EndIf