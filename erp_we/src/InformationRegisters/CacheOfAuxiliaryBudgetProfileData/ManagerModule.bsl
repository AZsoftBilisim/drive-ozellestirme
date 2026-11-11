#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Caches budget view settings by writing to the information register
// 
// Parameters:
//	BudgetProfile - CatalogRef.BudgetProfiles - type of budget that you want to write to the cache
//	CacheKind - EnumRef.BudgetCacheKinds - type of budget cache
//	Value - Boolean, ValueStorage - for cache types the result of Checking and using the border of factual Data takes the value Boolean
//	GenerationMode - EnumRef.ModesOfBudgetReportGeneration - modes for budget reports.
//
Procedure SetCacheValue(BudgetProfile, CacheKind, Value, GenerationMode = Undefined) Export
	
	Record = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordManager();
	
	Record.BudgetProfile = BudgetProfile;
	Record.CacheKind = CacheKind;
	Record.GenerationMode = GenerationMode;
	
	If TypesOfCacheTypeBoolean().Find(CacheKind) = Undefined Then
		Record.ValueBinaryData = New ValueStorage(Value);
	Else
		Record.ValueBoolean = Value;
	EndIf;
	
	Record.Write();
	
EndProcedure

// Returns settings saved in the cache
// 
// Parameters:
//	BudgetProfile - CatalogRef.BudgetProfiles - type of budget that you want to write to the cache
//	CacheKind - EnumRef.BudgetCacheKinds - type of budget cache
//	GenerationMode - EnumRef.ModesOfBudgetReportGeneration - (optional) modes for budget reports.
//
// Returns:
//	Boolean, Structure, Arbitrary - for cache types, the result of the verification and the use of the border of the factual data takes the value Boolean.
// 
Function GetCacheValue(BudgetProfile, CacheKind, GenerationMode = Undefined) Export
	
	If TypesOfCacheTypeBoolean().Find(CacheKind) = Undefined Then
		AttributeName = "ValueBinaryData";
	Else
		AttributeName = "ValueBoolean";
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	CacheOfAuxiliaryBudgetProfileData." + AttributeName + " AS VALUE
		|FROM
		|	InformationRegister.CacheOfAuxiliaryBudgetProfileData AS CacheOfAuxiliaryBudgetProfileData
		|WHERE
		|	CacheOfAuxiliaryBudgetProfileData.BudgetProfile = &BudgetProfile
		|	AND CacheOfAuxiliaryBudgetProfileData.CacheKind = &CacheKind";
		
	If GenerationMode <> Undefined Then
		Query.Text = Query.Text + "
		|	AND CacheOfAuxiliaryBudgetProfileData.GenerationMode = &GenerationMode";
	EndIf;
	
	Query.SetParameter("BudgetProfile", BudgetProfile);
	Query.SetParameter("CacheKind", CacheKind);
	Query.SetParameter("GenerationMode", GenerationMode);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	SelectionDetailRecords = QueryResult.Select();
	SelectionDetailRecords.Next();
	
	If AttributeName = "ValueBoolean" Then
		Return SelectionDetailRecords.Value;
	Else
		DataStorage = SelectionDetailRecords.Value; // ValueStorage
		Return DataStorage.Get();
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Function TypesOfCacheTypeBoolean()
	
	Array = New Array;
	Array.Add(Enums.BudgetCacheKinds.CheckResult);
	Array.Add(Enums.BudgetCacheKinds.UsesActualDataOffset);
	
	Return Array;
	
EndFunction

#EndRegion 

#EndIf