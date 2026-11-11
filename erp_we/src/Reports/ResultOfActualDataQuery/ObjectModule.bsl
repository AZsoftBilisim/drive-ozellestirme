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
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Var DocumentsCount;
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	ReportSettings = SettingsComposer.GetSettings();
	
	CurrentVariantKey = Undefined;
	SettingsComposer.UserSettings.AdditionalProperties.Property("VariantKey", CurrentVariantKey);
	If CurrentVariantKey = "RuleOperationResultByBudgetItems" 
		Or CurrentVariantKey = "RuleOperationResultByBudgetItem" Then
		GetFactsAboutBudgetItems = True;
		GetFactBasedOnBudgetIndicators = False;
	ElsIf CurrentVariantKey = "RuleOperationResultByBudgetIndicators"
		Or CurrentVariantKey = "RuleOperationResultByBudgetIndicator" Then
		GetFactsAboutBudgetItems = False;
		GetFactBasedOnBudgetIndicators = True;
	Else
		GetFactsAboutBudgetItems = True;
		GetFactBasedOnBudgetIndicators = True;
	EndIf;
	
	FactGettingParameters = ParametersForGettingFactByReportSettings(ReportSettings);
	If GetFactsAboutBudgetItems Then
		FactOnBudgetItems = BudgetingServer.FactOnBudgetItems(ReportSettings, FactGettingParameters);
	Else
		FactOnBudgetItems = New ValueTable;
	EndIf;
	If GetFactBasedOnBudgetIndicators Then
		FactOnBudgetIndicators = BudgetingServer.FactOnBudgetIndicators(ReportSettings, FactGettingParameters);
	Else
		FactOnBudgetIndicators = New ValueTable;
	EndIf;
	
	Dimension = New ValueTable;
	For Each Field In DataCompositionSchema.DataSets.Find("Dimension").Fields Do
		Dimension.Columns.Add(Field.Field, Field.ValueType);
	EndDo;
	
	ConfigurePeriodExtension(ReportSettings);
	
	For Each StructureItem In ReportSettings.Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionNestedObjectSettings") Then
			FinancialReportingServer.CopyFilter(ReportSettings.Filter, StructureItem.Settings.Filter, True);
			For Each Parameter In ReportSettings.DataParameters.Items Do
				ParameterValue =  StructureItem.Settings.DataParameters.FindParameterValue(Parameter.Parameter);
				If ParameterValue <> Undefined Then
					FillPropertyValues(ParameterValue, Parameter);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	#Region StartBackgroundReflectionOfDocumentsInBudgeting
		Period = BudgetingClientServer.ValueOfDCSSettings(SettingsComposer, "Period"); // StandardPeriod - 
		BeginOfPeriod = Period.StartDate;
		EndOfPeriod = Period.EndDate;
		AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
		If AuxProperties.Property("NumberOfDocumentsToBeReflectedInBudgeting") Then
			AuxProperties.Delete("NumberOfDocumentsToBeReflectedInBudgeting");
			UserSettingsModified = True;
		EndIf;
		StartBackgroundTask = False;
		If InformationRegisters.JobsForPostingInBudgeting.RequiredReflectionInBudgetingForReportForPeriod(
		BeginOfPeriod, EndOfPeriod, DocumentsCount, StartBackgroundTask) Then
			
			If StartBackgroundTask Then
				ActualBudgetingDataServer.ReflectDocumentsAsBackgroundTask(BeginOfPeriod, EndOfPeriod);
			EndIf;
			AuxProperties.Insert("NumberOfDocumentsToBeReflectedInBudgeting", DocumentsCount);
			AuxProperties.Insert("BeginOfPeriod", BeginOfPeriod);
			AuxProperties.Insert("EndOfPeriod", EndOfPeriod);
			
			If CurrentVariantKey = "RuleOperationResultByBudgetItem" Then
				// If by one article
				AddParametersForCheckingDocumentReflection(AuxProperties, SettingsComposer);
			EndIf;
			
		EndIf;
	#EndRegion
	
	PathToSchemaFields = "RuleOperationResultByBudgetIndicators.Schema.DataSets.DataSet1.Fields";
	BudgetingServer.AddAnalyticsPresentationExpressionsToDCS(DataCompositionSchema.NestedDataCompositionSchema,
			PathToSchemaFields,
			"BudgetBalanceItem");
	
	PathToSchemaFields = "RuleOperationResultByBudgetItems.Schema.DataSets.DataSet1.Fields";
	BudgetingServer.AddAnalyticsPresentationExpressionsToDCS(DataCompositionSchema.NestedDataCompositionSchema,
			PathToSchemaFields,
			"BudgetFlowItem");
	
	ExternalSets = New Structure;
	ExternalSets.Insert("FactOnBudgetItems", FactOnBudgetItems);
	ExternalSets.Insert("FactOnBudgetIndicators", FactOnBudgetIndicators);
	ExternalSets.Insert("Dimension", Dimension);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	ActualBudgetingDataServer.DeduceRelevanceOfReflectionOfActualData(ResultDocument, AuxProperties,
		StartBackgroundTask);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

Procedure AddParametersForCheckingDocumentReflection(AuxProperties, Var_SettingsComposer)
	//If there is a simple selection that may affect the need for a warning about non-reflected documents, then we will add the parameters.
	NameOfLayoutField = "BudgetFlowItem";
	FilterItems1 = New Array;
	BudgetReportingCacheCalculationServer.FindSelectionByName(Var_SettingsComposer.GetSettings(), NameOfLayoutField, FilterItems1);
	If FilterItems1.Count() = 1 Then
		FilterElement = FilterItems1[0]; // DataCompositionFilterItem -
		If FilterElement.Use
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal
			And FilterElement.Parent = Undefined Then
			AuxProperties.Insert("CheckingStoredRulesAndBudgets_", FilterElement.RightValue);
		EndIf;
	EndIf;
EndProcedure

Function ParametersForGettingFactByReportSettings(ReportSettings)
	
	Parameters = BudgetingServer.TemplateForGettingFactParameters();
	
	Parameters.ReportCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency").Value;
	Parameters.FunctionalCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "FunctionalCurrency").Value;
	Parameters.Period = DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value;
	Parameters.Periodicity = DataCompositionClientServer.GetParameter(ReportSettings, "Periodicity").Value;
	Parameters.DataAcquisitionRules = True;
	Parameters.ByCompanies = True;
	Parameters.ByBusinessUnits = True;
	
	Indicators = New Structure;
	For Each StructureItem In ReportSettings.Structure Do
		If TypeOf(StructureItem) <> Type("DataCompositionNestedObjectSettings") Then
			Continue;
		EndIf;
		If DataCompositionClientServer.FieldUsed_(StructureItem.Settings, "Recorder") Then
			Parameters.ByRegistrar = True;
		EndIf;
		If DataCompositionClientServer.FieldUsed_(StructureItem.Settings, "Sum") Then
			Indicators.Insert("Sum");
		EndIf;
		If DataCompositionClientServer.FieldUsed_(StructureItem.Settings, "Count") Then
			Indicators.Insert("Count");
		EndIf;
	EndDo;
	
	Parameters.Indicators = Indicators;
	
	Return Parameters;
	
EndFunction

Procedure ConfigurePeriodExtension(ReportSettings) 
	
	Peridicity = DataCompositionClientServer.GetParameter(ReportSettings, "Periodicity").Value;
	StringPeriodicity = Common.EnumerationValueName(Peridicity);
	AdditionType = DataCompositionPeriodAdditionType[StringPeriodicity];
	
	Period = DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value; // StandardPeriod - 
	PeriodField = New DataCompositionField("Period");
	
	For Each StructureItem In ReportSettings.Structure Do
		If TypeOf(StructureItem) <> Type("DataCompositionNestedObjectSettings") Then
			Continue;
		EndIf;
		Groups = DataCompositionClientServer.GetGroupings(StructureItem.Settings);
		For Each Group In Groups Do
			CompositionGroup1 = Group.Value; // DataCompositionGroup, DataCompositionTableGroup -
			GroupItems = CompositionGroup1.GroupFields.Items;
			If GroupItems.Count() = 1 And GroupItems[0].Field = PeriodField Then
				GroupingPeriod = GroupItems[0];
				GroupingPeriod.AdditionType = AdditionType;
				GroupingPeriod.BeginOfPeriod = Period.StartDate;
				GroupingPeriod.EndOfPeriod = Period.EndDate;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure SetRequiredSettings(UserSettingsModified)
	
	CurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Currency");
	If CurrencyParameter <> Undefined And Not ValueIsFilled(CurrencyParameter.Value) Then
		DataCompositionClientServer.SetParameter(
			SettingsComposer, "Currency", Constants.ManagementAccountingCurrency.Get());
		UserSettingsModified = True;
	EndIf;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//    *Parameters - Structure -:
//     **CommandDetails - Structure -:
//       ***AdditionalParameters - Structure -:
//          ****CommandName - String - 
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "ByBudgetItem" Then
			If TypeOf(Parameters.CommandParameter) = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems") Then
				BudgetFlowItem = Common.ObjectAttributeValue(Parameters.CommandParameter, "BudgetFlowItem");
			Else
				BudgetFlowItem = Parameters.CommandParameter;
			EndIf;
			ThisForm.ParametersForm.Filter.Insert("BudgetFlowItem", BudgetFlowItem);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ByBudgetItems" Then
			If TypeOf(Parameters.CommandParameter[0]) = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems") Then
				BudgetFlowItems = Common.ObjectsAttributeValue(Parameters.CommandParameter, "BudgetFlowItem");
			Else
				BudgetFlowItems = Parameters.CommandParameter;
			EndIf;
			ThisForm.ParametersForm.Filter.Insert("BudgetFlowItem", BudgetFlowItems);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ByBudgetIndicator" Then
			If TypeOf(Parameters.CommandParameter) = Type("CatalogRef.ActualDataQueryRulesByBudgetBalanceItems") Then
				BudgetBalanceItem = Common.ObjectAttributeValue(Parameters.CommandParameter,
					"BudgetBalanceItem");
			Else
				BudgetBalanceItem = Parameters.CommandParameter;
			EndIf;
			ThisForm.ParametersForm.Filter.Insert("BudgetBalanceItem", BudgetBalanceItem);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ByBudgetIndicators" Then
			If TypeOf(Parameters.CommandParameter[0]) = Type(
				"CatalogRef.ActualDataQueryRulesByBudgetBalanceItems") Then
				BudgetBalanceItems = Common.ObjectsAttributeValue(Parameters.CommandParameter,
					"BudgetBalanceItem");
			Else
				BudgetBalanceItems = Parameters.CommandParameter;
			EndIf;
			ThisForm.ParametersForm.Filter.Insert("BudgetBalanceItem", BudgetBalanceItems);
		EndIf;
	EndIf;
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//    *Report - ReportObject - :
//     **FormSettingsComposer - DataCompositionSettingsComposer - 
//    *Parameters - Structure -:
//     **CommandDetails - Structure -:
//       ***AdditionalParameters - Structure -:
//          ****CommandName - String - 
//   NewDCSettings - DataCompositionSettings - 
//
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCSettings) Export
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	RecordByQuantity = False;
	
	If Parameters.Property("CommandDetails") Then
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "ByBudgetItem" Then
			If TypeOf(Parameters.CommandParameter) = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems") Then
				BudgetFlowItem = Common.ObjectAttributeValue(Parameters.CommandParameter, "BudgetFlowItem");
			Else
				BudgetFlowItem = Parameters.CommandParameter;
			EndIf;

			If ValueIsFilled(BudgetFlowItem) Then
				RecordByQuantity = Common.ObjectAttributeValue(BudgetFlowItem,
					"RecordByQuantity");
			EndIf;
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ByBudgetItems" Then
			If TypeOf(Parameters.CommandParameter[0]) = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems") Then
				BudgetFlowItems = Common.ObjectsAttributeValue(Parameters.CommandParameter, "BudgetFlowItem");
			Else
				BudgetFlowItems = Parameters.CommandParameter;
			EndIf;

			If BudgetFlowItems.Count() > 0 Then
				RecordByQuantity = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
					Common.ObjectsAttributeValue(BudgetFlowItems, "RecordByQuantity")).Find(True)
					<> Undefined;
			EndIf;
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ByBudgetIndicator" Then
			If TypeOf(Parameters.CommandParameter) = Type("CatalogRef.ActualDataQueryRulesByBudgetBalanceItems") Then
				BudgetBalanceItem = Common.ObjectAttributeValue(Parameters.CommandParameter,
					"BudgetBalanceItem");
			Else
				BudgetBalanceItem = Parameters.CommandParameter;
			EndIf;

			If ValueIsFilled(BudgetBalanceItem) Then
				RecordByQuantity = Common.ObjectAttributeValue(BudgetBalanceItem,
					"RecordByQuantity");
			EndIf;
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ByBudgetIndicators" Then
			If TypeOf(Parameters.CommandParameter[0]) = Type(
				"CatalogRef.ActualDataQueryRulesByBudgetBalanceItems") Then
				BudgetBalanceItems = Common.ObjectsAttributeValue(Parameters.CommandParameter,
					"BudgetBalanceItem");
			Else
				BudgetBalanceItems = Parameters.CommandParameter;
			EndIf;

			If BudgetBalanceItems.Count() > 0 Then
				RecordByQuantity = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
					Common.ObjectsAttributeValue(BudgetBalanceItems, "RecordByQuantity")).Find(
					True) <> Undefined;
			EndIf;
		EndIf;
	EndIf;
	
	If RecordByQuantity Then
		ReportSettings = FormSettingsComposer.GetSettings();
		QuantityField = New DataCompositionField("Count");
		For Each StructureItem In ReportSettings.Structure Do
			For Each ComboBox In StructureItem.Settings.Selection.Items Do
				If ComboBox.Field = QuantityField Then
					ComboBox.Use = True;
					Break;
				EndIf;
			EndDo; 
		EndDo;
		
		FormSettingsComposer.LoadSettings(ReportSettings);
	EndIf;
EndProcedure

#EndRegion

#EndIf
