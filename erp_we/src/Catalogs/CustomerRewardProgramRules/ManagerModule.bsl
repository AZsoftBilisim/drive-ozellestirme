
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//  Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	
	Result.Add("DataCompositionSchema;EditDataCompositionSchema");
	Result.Add("ActionPeriod;ValidityGroup");
	Result.Add("NumberOfValidityPeriods");
	Result.Add("NumberOfActionStartDelayPeriods");
	Result.Add("PeriodOfActionStartDelay;DeferredActionGroup");
	Result.Add("RuleKind");
	Result.Add("Owner");
	
	Return Result;

EndFunction

// Performs the formation of a new SKD.
//
// Returns:
//  DataCompositionSchema - the circuit layout data.
//
Function CreateNewDataLayoutScheme() Export
	
	Return GetTemplate("ArbitrarySchemeTemplate");
	
EndFunction

// Returns a structure with a synonym and
// a data layout scheme by the layout name.
//
// Parameters:
//	Ref - CatalogRef.TypesOfPrices - Link to the price view
//	TemplateName - String - name of the layout to get the description and schema from.
//
// Returns:
//	Structure - description and layout diagram of the data.
//
Function GetDescriptionAndLayoutDiagramOfDataByTemplateName(Ref, TemplateName = Undefined) Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("LongDesc",                  "");
	ReturnValue.Insert("DataCompositionSchema",     Undefined);
	ReturnValue.Insert("DataCompositionSettings", Undefined);
	
	Query = New Query(
	"SELECT
	|	AutomaticAccrual.StorageOfDataCompositionSchema AS StorageOfDataCompositionSchema,
	|	AutomaticAccrual.StorageOfDataCompositionSettings AS StorageOfDataCompositionSettings
	|FROM
	|	Catalog.CustomerRewardProgramRules AS AutomaticAccrual
	|WHERE
	|	AutomaticAccrual.Ref = &Ref");
	
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Not ValueIsFilled(TemplateName) Then
		
		ReturnValue.LongDesc = TemplateName;
		If Selection.Next() Then
			
			SamplingDataLayoutSchemaStorage = Selection.StorageOfDataCompositionSchema; // ValueStorage
			DataCompositionSchema = SamplingDataLayoutSchemaStorage.Get();
			If DataCompositionSchema = Undefined Then
				ReturnValue.DataCompositionSchema = CreateNewDataLayoutScheme();
				ReturnValue.DataCompositionSettings = Undefined;
			Else
				ReturnValue.DataCompositionSchema = DataCompositionSchema;
				SelectionStorageOfDataLayoutSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage
				ReturnValue.DataCompositionSettings = SelectionStorageOfDataLayoutSettings.Get();
			EndIf;
			
		EndIf;
		
	Else
		
		ReturnValue.LongDesc = Metadata.FindByType(TypeOf(Ref)).Templates.Find(TemplateName).Synonym;
		ReturnValue.DataCompositionSchema = Catalogs.CustomerRewardProgramRules.GetTemplate(TemplateName);
		If Selection.Next() Then
			SelectionStorageOfDataLayoutSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage
			ReturnValue.DataCompositionSettings = SelectionStorageOfDataLayoutSettings.Get();
		EndIf;
		
	EndIf;
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#EndIf