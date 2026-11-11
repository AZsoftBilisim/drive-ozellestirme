#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//  			registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Budgeting");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.SettingOfEstimatesOpeningBalance") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	TablesForRegisteredRecords = New Structure;
	CreateTableOfOpeningBalancesOfCalculatedIndicators(TablesForRegisteredRecords, DocumentRef, Registers);
	
	Return TablesForRegisteredRecords;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Document.SettingOfEstimatesOpeningBalance.BalanceOfEstimate AS BalanceOfEstimate
	|	ON BalanceOfEstimate.Ref = ThisList.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(Scenario, EmptyRef AS TRUE)
	| AND ValueAllowed(BudgetBalanceItem)
	| AND ForAllRows(ValueAllowed(BalanceOfEstimate.Organization, EmptyRef AS TRUE, NULL AS TRUE))
	| AND ForAllRows(ValueAllowed(BalanceOfEstimate.Department, EmptyRef AS TRUE, NULL AS TRUE))";

EndProcedure

// End StandardSubsystems.AccessManagement

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndRegion

#Region Private

#Region CarryingOutDocument

Procedure CreateTableOfOpeningBalancesOfCalculatedIndicators(TablesForRegisteredRecords, Document, Registers)
	
	RegisterName = "OpeningBalanceOfEstimates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref", Document);
	
	QueryText =
	"SELECT
	|	SettingOfEstimatesOpeningBalance.DateOfRemainingGoods AS DateOfRemainingGoods,
	|	SettingOfEstimatesOpeningBalance.BudgetBalanceItem AS BudgetBalanceItem,
	|	SettingOfEstimatesOpeningBalance.Scenario AS Scenario
	|INTO Attributes
	|FROM
	|	Document.SettingOfEstimatesOpeningBalance AS SettingOfEstimatesOpeningBalance
	|WHERE
	|	SettingOfEstimatesOpeningBalance.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Attributes.DateOfRemainingGoods AS DateOfRemainingGoods,
	|	Attributes.BudgetBalanceItem AS BudgetBalanceItem,
	|	Attributes.Scenario AS Scenario,
	|	BalanceOfEstimate.Organization AS Organization,
	|	BalanceOfEstimate.Department AS Department,
	|	&TextOfDimensionsFields,
	|	BalanceOfEstimate.Currency AS Currency,
	|	BalanceOfEstimate.Count AS Count,
	|	BalanceOfEstimate.AmountInCurrency AS AmountInCurrency,
	|	BalanceOfEstimate.SumMan AS SumMan,
	|	BalanceOfEstimate.SumCompl AS SumCompl
	|FROM
	|	Document.SettingOfEstimatesOpeningBalance.BalanceOfEstimate AS BalanceOfEstimate
	|		LEFT JOIN Attributes AS Attributes
	|		ON (TRUE)
	|WHERE
	|	BalanceOfEstimate.Ref = &Ref";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ArrayOfAnalystFields = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
		"BalanceOfEstimate.Dimension%1 AS Dimension%1", DimensionNumber));
	EndDo;
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", StrConcat(ArrayOfAnalystFields, "," + Chars.LF + Chars.Tab));
	Query.Text = QueryText;
	
	TableOfConduct = Query.Execute().Unload();
	
	TablesForRegisteredRecords.Insert("TableOpeningBalancesOfCalculatedIndicators", TableOfConduct);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

#EndRegion

Function SettingsForFillingOutDocumentForBudgetIssue(Document, BudgetBalanceItem) Export
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	BudgetTaskDocumentsList.Ref AS Ref,
	|	BudgetTaskDocumentsList.Ref.SettingOfAction AS SettingOfAction
	|FROM
	|	Task.BudgetTask.DocumentsList AS BudgetTaskDocumentsList
	|WHERE
	|	BudgetTaskDocumentsList.Document = &Document
	|	AND NOT BudgetTaskDocumentsList.Ref.Executed
	|	AND NOT BudgetTaskDocumentsList.Ref.DeletionMark";
	
	Query.SetParameter("Document", Document);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		Selection.Next();
		
		ActionSettingsStore = Selection.SettingOfAction; // ValueStorage
		SettingOfAction = ActionSettingsStore.Get();
		
		If Not TypeOf(SettingOfAction) = Type("ValueTable") Then
			Return Undefined;
		EndIf;
		
		BudgetAnalyticsLine = SettingOfAction.Find("BudgetPopulationDimension", "Name");
		IndicatorLine = SettingOfAction.Find("BalancesOfCalculatedIndicators", "Name");
		If BudgetAnalyticsLine = Undefined
			Or IndicatorLine = Undefined Then
			Return Undefined;
		EndIf;
		
		IndicatorLine_ = IndicatorLine.Value.Find(BudgetBalanceItem, "BudgetBalanceItem");
		If IndicatorLine_ = Undefined Then
			Return Undefined;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("RowKey", IndicatorLine_.DimensionSettingLineKey);
		
		Return New Structure("Setting, BudgetTask", BudgetAnalyticsLine.Value.Copy(TheStructureOfTheSearch),
			Selection.Ref);
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

#EndRegion

#EndIf