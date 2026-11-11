#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of String - names of blocked Bank details:
//		* AttributeToLock - String - Name of the blocked account.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			Result.Add("DimensionKind" + DimensionNumber);
	EndDo;
	Result.Add("IndicatorKind");
	Result.Add("SetAValueForEachPeriod");
	Result.Add("ImportFromOtherSubsystems");
	Result.Add("ByCompanies");
	Result.Add("ByPeriods");
	Result.Add("ByScenarios");
	Result.Add("ByBusinessUnits");
	Result.Add("Periodicity");
	Result.Add("SubperiodFrequency");
	
	Return Result;
	
EndFunction

// Returns a predefined schema for getting data
//
// Parameters:
//	TemplateName - String - name of the layout to get the description and schema from.
//	DataReceiptMode - EnumRef.BudgetingDataReceiptMode
//
// Returns:
//	DataCompositionSchema - data acquisition scheme.
//
Function PredefinedDataAcquisitionScheme(TemplateName, DataReceiptMode = Undefined) Export
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	If (TemplateName = "ItemsPrices" And UsePriceManagementSystem25) Then
		NewTemplateName_ = "ItemsPrices2_5";
	ElsIf (TemplateName = "ItemsPrices2_5" And Not UsePriceManagementSystem25) Then
		NewTemplateName_ = "ItemsPrices";
	Else
		NewTemplateName_ = TemplateName;
	EndIf;
	
	DataAcquisitionScheme = Catalogs.NonFinancialItemsOfBudgets.GetTemplate(NewTemplateName_);
	
	If DataReceiptMode = Enums.BudgetingDataReceiptMode.All Then
		For Each Set In DataAcquisitionScheme.DataSets Do
			If ValueIsFilled(Set.Query) Then 
				Set.Query = RequestSchemes.SetSelectionOfAllowedRecordsInEntireRequest(Set.Query, False);
			EndIf;
		EndDo;
	EndIf;
	
	Return  DataAcquisitionScheme;
	
EndFunction

// Returns a table of non-financial indicators based on the selection of data layout
//
// Parameters:
// 	 DataLayoutSelection - DataCompositionSettings - Data layout settings that contain the selection.
// Returns:
// 	ValueTable - Table of non-financial indicators:
//		* NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets - Non-financial indicator.
//		* DimensionCurrencyField - String - Source of filling in the currency.
//		* FieldOfDimensionUnitOfMeasure - String - Source of filling in the unit of measurement.
//
Function NonFinancialIndicatorsBasedOnSelection(DataLayoutSelection) Export
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSetScenarios = DataCompositionServer.AddEmptyDataSet(
		DataCompositionSchema,
		Type("DataCompositionSchemaDataSetQuery"));
	DataSetScenarios.Query = 
	"SELECT ALLOWED
	|	NonFinancialIndicators.Ref AS NonFinancialItem,
	|	NonFinancialIndicators.DimensionCurrencies.CurrencyFilling AS DimensionCurrencyField,
	|	NonFinancialIndicators.DimensionUnitsOfMeasurement.UnitOfMeasureFilling AS FieldOfDimensionUnitOfMeasure,
	|	*
	|FROM
	|	Catalog.NonFinancialItemsOfBudgets AS NonFinancialIndicators
	|WHERE
	|	NOT NonFinancialIndicators.DeletionMark
	|	AND NOT NonFinancialIndicators.IsFolder
	|";
	DataSetScenarios.AutoFillAvailableFields = True;
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	
	Settings = New DataCompositionSettings;
	DataCompositionClientServer.AddGrouping(Settings);
	For Each Item In SettingsComposer.Settings.SelectionAvailableFields.Items Do
		If Item.Folder Then
			Continue;
		EndIf;
		DataCompositionClientServer.AddSelectedField(Settings, Item.Field);
	EndDo;
	DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema, Settings, DataLayoutSelection);
	
	Return FinancialReportingServer.UploadDCSResults(DataCompositionSchema, Settings);
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsFolder OR
	|	ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region Other

// Returns DCS templates for non-financial budget indicators.
//
// Returns:
//  Array of Structure:
//   *Name - String - the name of the DCS Template
//   *Synonym - String - synonym for the DCS Template
//
Function DataLayoutSchemaTemplates() Export
	
	Templates = New Array;
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	For Each Template In Metadata.Catalogs.NonFinancialItemsOfBudgets.Templates Do
		
		If Template.TemplateType <> Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			Continue;
			
		EndIf;
		
		If (Template.Name = "ItemsPrices" And UsePriceManagementSystem25) 
				Or (Template.Name = "ItemsPrices2_5" And Not UsePriceManagementSystem25) Then
			
			Continue;
			
		EndIf;
		
		Templates.Add(New Structure("Name, Synonym", Template.Name, Template.Synonym));
		
	EndDo;
	
	Return Templates;
	
EndFunction

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	Reports.NonFinancialItemValues.AddReportCommand(ReportsCommands);
EndProcedure

#EndRegion

#EndRegion

#EndIf
