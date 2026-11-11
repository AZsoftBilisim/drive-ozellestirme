#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region StandardSubsystems

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

#EndRegion

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//  Array of String:
//   * Fields - String - a list of the names of the object's details.
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	// Header Elements
	Result.Add("Code");
	Result.Add("Description");
	Result.Add("Parent");
	Result.Add("Author");
	Result.Add("Date");
	Result.Add("Control");
	Result.Add("TemplatesPercentage");
	Result.Add("TamplatesNumber");
	Result.Add("TemplatesFilterOption");
	Result.Add("AssignmentOption");
	Result.Add("DescriptionOfUsageSpecification");
	Result.Add("ScopeView");
	
	// Elements of table parts
	Result.Add("Checks");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns the Query Text for the list of goods research card checks.
//
// Returns:
//   String - Query text
Function QueryTextOfCheckList() Export
	
	QueryText = "SELECT
	|	GoodsQualityControlCards.CheckKind,
	|	GoodsQualityControlCards.QualityIndicator,
	|	GoodsQualityControlCards.Norm
	|FROM
	|	Catalog.GoodsResearchSheets.Checks AS GoodsQualityControlCards
	|WHERE
	|	GoodsQualityControlCards.Ref = &Ref";
	
	Return QueryText;
	
EndFunction

// Checks the use of the object
//
// Parameters:
//  Parameters		- Structure - contains an object that you want to check for usage
//  StorageAddress	- String - address of the storage where the verification result will be placed
//
Procedure CheckObjectUsage(Parameters, StorageAddress) Export

	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS ThereAreRefs
	|FROM
	|	Document.GoodsQualityResearch AS GoodsQualityResearch
	|WHERE
	|	GoodsQualityResearch.GoodsResearchSheet = &Object
	|";
	
	Query.SetParameter("Object", Parameters.Object);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	ThereAreRefs = Not Result.IsEmpty();
	
	PutToTempStorage(ThereAreRefs, StorageAddress);

EndProcedure

#EndRegion

#EndIf
