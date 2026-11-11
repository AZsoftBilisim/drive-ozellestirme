//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm, Undefined - report form or report settings form.
//       Undefined when a call is without context.
//   VariantKey - String, Undefined - the name of the predefined
//       or unique identifier of the custom version of the report.
//       Undefined when a call is without context.
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export 
	
	If VariantKey = "CurrentRebatesOfSuppliersContext" Then
		
		Settings.GenerateImmediately = True;
		Settings.EditOptionsAllowed = False;
		
	EndIf;
	
	Settings.Events.OnCreateAtServer = True; 
	
EndProcedure

// See ReportsOverridable.OnCreateAtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	If Parameters.Property("CommandParameter") Then
		
		CommandParameter = Parameters.CommandParameter; // CatalogRef.Counterparties, CatalogRef.Partners, CatalogRef.CounterpartyContracts, CatalogRef.TermsOfPurchaseFromVendors
		CommandParameterType = TypeOf(CommandParameter);
		
		Form.ReportSettings.OptionSelectionAllowed = False;
		
		Filter = Form.ParametersForm.Filter;  // Structure
		
		If CommandParameterType = Type("CatalogRef.Counterparties") Then
			
			Filter.Insert("Counterparty", CommandParameter);
			
		ElsIf CommandParameterType = Type("CatalogRef.Partners") Then
			
			Filter.Insert("Partner", CommandParameter);
			
		ElsIf CommandParameterType = Type("CatalogRef.CounterpartyContracts") Then
			
			Filter.Insert("Contract", CommandParameter);
			
		ElsIf CommandParameterType = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			Filter.Insert("Terms", CommandParameter);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
