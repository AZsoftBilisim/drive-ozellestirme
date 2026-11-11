#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Checks the use of the object
//
// Parameters:
//  Parameters		- Structure - contains an object that you want to check for usage
//  StorageAddress	- String - address of the storage where the verification result will be placed.
//
Procedure CheckObjectUsage(Parameters, StorageAddress) Export
	
	ThereAreRefs = Common.RefsToObjectFound(Parameters.Object);
	If Not ThereAreRefs Then
		ThereAreRefs = CheckUsageOfItemInActionSettingsForBudgetPreparationStages(Parameters.Object);
	EndIf;
	PutToTempStorage(ThereAreRefs, StorageAddress);
	
EndProcedure

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of String - names of blocked Bank details:
//		* AttributeToLock - String - Name of the blocked account.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("TypeOfIndicatorInputForm");
	
	Return Result;
	
EndFunction

// Returns a flag for using the template in documents to set the values of the NFP
//
// Parameters:
//  Template - CatalogRef.NonFinancialItemProfiles
//  DocumentException - DocumentRef.SetValuesForNonFinancialItems
//
// Returns:
//  Boolean - True if the template is used in the documents setting the values of the NFP
//
Function TemplateIsUsedInDocuments(Val Template, Val DocumentException = Undefined) Export
	
	If Not ValueIsFilled(Template) Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(DocumentException) Then
		DocumentException = Documents.SetValuesForNonFinancialItems.EmptyRef();
	EndIf;
	
	Query = New Query("SELECT TOP 1
	                      |	DocumentSettingValues.Ref
	                      |FROM
	                      |	Document.SetValuesForNonFinancialItems AS DocumentSettingValues
	                      |WHERE
	                      |	DocumentSettingValues.InputTemplate = &InputTemplate
	                      |	AND NOT DocumentSettingValues.Ref = &Exception");
	
	Query.SetParameter("InputTemplate", Template);
	Query.SetParameter("Exception", DocumentException);
	
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// The function defines the input template for the selected non-financial indicator.
//
// Returns a template for entering a non-financial metric, if one template is found.
// Returns Undefined if no template is found or there are more than one templates.
//
// Parameters:
//  Factor - CatalogRef.NonFinancialItemsOfBudgets - Non-financial indicator
//
// Returns:
//	CatalogRef.NonFinancialItemProfiles - The found input template.
//
Function DefaultInputPattern(Factor) Export
	
	Result = Undefined;
	
	Query = New Query("
	|SELECT ALLOWED DISTINCT TOP 2
	|	TemplateIndicators.Ref AS Ref
	|FROM
	|	Catalog.NonFinancialItemProfiles.TemplateIndicators AS TemplateIndicators
	|WHERE
	|	NOT TemplateIndicators.Ref.DeletionMark
	|	AND TemplateIndicators.Factor = &Factor
	|");
	
	Query.SetParameter("Factor", Factor);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		If Selection.Count() = 1 Then
			Selection.Next();
			Result = Selection.Ref;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private
Function CheckUsageOfItemInActionSettingsForBudgetPreparationStages(Ref)
	
	ThereAreRefs = False;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	BudgetingSteps.Ref,
	|	BudgetingSteps.SettingOfAction
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Action = VALUE(Enum.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ActionSettingsStore = Selection.SettingOfAction; // ValueStorage
		SettingOfAction = ActionSettingsStore.Get();
		If TypeOf(SettingOfAction) <> Type("ValueTable") Then
			Continue;
		EndIf;
		
		SearchParameters = New Structure("Name, Value","InputTemplate", Ref);
		Rows = SettingOfAction.FindRows(SearchParameters);
		If Rows.Count() = 0 Then 
			Continue;
		EndIf;
		
		ThereAreRefs = True;
		
	EndDo;
	
	Return ThereAreRefs;
	
EndFunction
#EndRegion

#EndIf
