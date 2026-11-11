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
	Settings.Events.OnLoadVariantAtServer = True;
	
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
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		Contract = Parameters.CommandParameter;
		If TypeOf(Parameters.CommandParameter) = Type("CatalogRef.OptionsOfLoansAndDepositsSchedules") Then
			Contract = Common.ObjectAttributeValue(Parameters.CommandParameter, "Owner");
		EndIf;
		ThisForm.ParametersForm.Filter.Insert("Contract", Contract);
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   NewDCSettings - DataCompositionSettings - customization.
	Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

#EndRegion

#Region Private

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
	UseLoanAndDepositContracts = GetFunctionalOption("UseLoanAndDepositContracts");
	
	ItemsToDelete_ = New Array;
	For Each StructureItem In FormSettingsComposer.Settings.Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings") Then
			If StructureItem.ObjectID = "CreditsDeposits" And Not UseLoanAndDepositContracts Then
				ItemsToDelete_.Add(StructureItem);
			EndIf;
		EndIf;
	EndDo;
	
	For Each ElementToDelete In ItemsToDelete_ Do
		FormSettingsComposer.Settings.Structure.Delete(ElementToDelete);
	EndDo;
	
EndProcedure

#EndRegion

#EndIf