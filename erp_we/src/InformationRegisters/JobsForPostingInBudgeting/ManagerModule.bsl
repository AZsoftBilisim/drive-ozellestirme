#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// This function determines whether the fact should be reflected in budgeting when generating the report.
//
// Parameters:
//  BeginOfPeriod  - Date - Optional, start of the period.
//  EndOfPeriod  - Date - Optional, end of the period.
//  NumberOfIrrelevantDocuments  - Number - The parameter stores the number of documents to reflect the fact.
//  StartBackgroundTask - Boolean - True if you want to run a background task to reflect in budgeting.								     
//
// Returns:
//   Boolean - A sign that it is required to reflect the fact in budgeting when forming the report. 
//
Function RequiredReflectionInBudgetingForReportForPeriod(Val BeginOfPeriod = Undefined,
	Val EndOfPeriod = Undefined, NumberOfIrrelevantDocuments = 0, StartBackgroundTask = False,
	DocumentsKinds = Undefined) Export

	If Not BudgetingCached.StoredFactIsUsedForBudgetItems() Then
		Return False;
	EndIf;
	
	StartBackgroundTask = Constants.UpdateStoredActualBudgetingDataWhenGeneratingReports.Get();
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	If Not ValueIsFilled(BeginOfPeriod) Then
		BeginOfPeriod = Date(1,1,1);
	EndIf;

	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = Date(3999, 12, 31, 23, 59, 59);
	EndIf;
	
	ActualBudgetingDataServer.PlaceDocumentsForReflectionInTemporaryTable(BeginOfPeriod, EndOfPeriod, TempTablesManager, DocumentsKinds);
	
	Query.Text = 
	"SELECT
	|	COUNT(DISTINCT AllDocumentsForReflection.Document) AS Count
	|FROM
	|	DocumentsToBeReflected AS AllDocumentsForReflection";
		
	Result = Query.Execute();
	If Result.IsEmpty() Then 
		NumberOfIrrelevantDocuments = 0;
	Else
		Selection = Result.Select();
		Selection.Next();
		NumberOfIrrelevantDocuments = Selection.Count;
	EndIf;
	
	Return NumberOfIrrelevantDocuments > 0;
	
EndFunction

#EndRegion

#EndIf