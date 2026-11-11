////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of working with objects of operation
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public
#Region FillVerificationProceduresAndFunctions

// Initializes the structure of cached fill check values
//
// Parameters:
// 		CachedValues - Structure - The structure of the cached values of the test fill.
//
Procedure InitializeCachedFillCheckValues(CachedValues) Export
	
	If CachedValues <> Undefined Then
		If CachedValues.Property("Initialized") Then
			Return;
		EndIf;
	EndIf;
	
	CachedValues = New Structure;
	
	CachedValues.Insert("RequiredDetails_", New Map);
	CachedValues.Insert("MandatoryAdditionalDetails", New Map);
	CachedValues.Insert("RunningTimeRecordingParameters", New Map);
	
	CachedValues.Insert("TempTablesManager", New TempTablesManager);
	
	Query = New Query(
		"SELECT
		|	CAST(AttributeSet.Name AS STRING(255)) AS Name,
		|	CAST(AttributeSet.Synonym AS STRING(255)) AS Synonym,
		|	CAST(AttributeSet.RequiredForFilling AS BOOLEAN) AS RequiredForFilling,
		|	CAST(AttributeSet.RequiredForViewOnly AS BOOLEAN) AS RequiredForViewOnly
		|INTO ObjectsAttributes
		|FROM
		|	&ItemDetails__ AS AttributeSet
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CAST(AttributeSet.Name AS STRING(255)) AS Name,
		|	CAST(AttributeSet.Synonym AS STRING(255)) AS Synonym,
		|	CAST(AttributeSet.RequiredForFilling AS BOOLEAN) AS RequiredForFilling,
		|	CAST(AttributeSet.RequiredForViewOnly AS BOOLEAN) AS RequiredForViewOnly
		|INTO DetailsOfNodes
		|FROM
		|	&NodeAttributesContent AS AttributeSet
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AddAttributes.Property,
		|	AddAttributes.Property.RequiredToFill AS RequiredToFill
		|INTO GeneralAdditionalDetailsOfObjects
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AddAttributes
		|WHERE
		|	AddAttributes.Ref = &Set_Catalog_Assets_Overall
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AddAttributes.Property,
		|	AddAttributes.Property.RequiredToFill AS RequiredToFill
		|INTO GeneralAdditionalDetailsOfNodes
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AddAttributes
		|WHERE
		|	AddAttributes.Ref = &Set_Catalog_SubAssets_Overall");
	
	Query.SetParameter("ItemDetails__", Catalogs.Assets.CompositionOfDetailsOfObjectOfOperation());
	Query.SetParameter("NodeAttributesContent", Catalogs.SubAssets.AttributeSet());
	Query.SetParameter("Set_Catalog_Assets_Overall", PropertyManager.PropertiesSetByName("Catalog_Assets_Overall"));
	Query.SetParameter("Set_Catalog_SubAssets_Overall", PropertyManager.PropertiesSetByName("Catalog_SubAssets_Overall"));
	
	Query.TempTablesManager = CachedValues.TempTablesManager;
	Query.Execute();
	
	CachedValues.Insert("Initialized");
	
EndProcedure

// Initializes the structure of the fill check error flow
//
// Parameters:
// 		ErrorStream - Structure - Structure of the fill check error flow.
//
Procedure InitializeErrorFlow(ErrorStream) Export
	
	If ErrorStream <> Undefined Then
		If ErrorStream.Property("Initialized") Then
			Return;
		EndIf;
	EndIf;
	
	ErrorStream = New Structure;
	
	ErrorStream.Insert("ErrorList", New Array);
	ErrorStream.Insert("ErrorGroups", New Map);
	ErrorStream.Insert("ErrorCounter", New Map);
	
	ErrorStream.Insert("Initialized");
	
EndProcedure

// Adds a new user error to the error list for further sending
// using the report error to User () procedure.
//  It is used in the procedures for processing check-Completion.
//
// Parameters:
// 		Errors - Structure - Contains a stream of errors:
// 		              * ErrorList - Array -
// 		              * ErrorCounter - Map - 
//
// 		ErrorObject - CatalogRef.Assets, CatalogRef.SubAssets - object that owns the error.
//
// 		ErrorField - String - the value that is set in the field property of the message object to the User.
//                    For auto-substitution, the line number must contain "%1".
//                    For Example, " Object.INN " or " Object.Users[%1].User".
//
// 		SingleErrorText - String - error text for the case when there is only one error group in the collection,
//                    for example, NStr("ru = 'User not selected.'").
//
// 		ErrorsGroup1 - Arbitrary - used to select either text for a single error
//                    or text for multiple errors, such as the name " Object.Users".
//                    If the value is not filled in, then the text for one error is used.
//
// 		LineNumber - Number - a value from 0 ... that specifies the line number to be inserted
//                    in the error Field string and in the text for multiple Errors (string Number + 1 is substituted).
//
// 		SeveralErrorsText - String - error text for the case when several errors were added with the same
//                    error group property, for example, NStr ("ru = 'User not selected in line %1.'").
//
Procedure AddUserError(Errors, Val ErrorObject, Val ErrorField, Val SingleErrorText, Val ErrorsGroup1 = "", Val LineNumber = 0, Val SeveralErrorsText = "") Export
	
	If ValueIsFilled(ErrorsGroup1) Then
		
		If Errors.ErrorGroups[ErrorsGroup1] = Undefined Then
			// The error group was used once, the text for one error is used.
			Errors.ErrorGroups.Insert(ErrorsGroup1, False);
		Else
			// The error group has been used several times, the text is used for several errors.
			Errors.ErrorGroups.Insert(ErrorsGroup1, True);
		EndIf;
	EndIf;
	
	Error = New Structure;
	Error.Insert("ErrorObject",             ErrorObject);
	Error.Insert("ErrorField",               ErrorField);
	Error.Insert("SingleErrorText",      SingleErrorText);
	Error.Insert("ErrorsGroup1",             ErrorsGroup1);
	Error.Insert("LineNumber",              LineNumber);
	Error.Insert("RowIndex",             LineNumber);
	Error.Insert("SeveralErrorsText", SeveralErrorsText);
	
	Errors.ErrorList.Add(Error);
	
	Counter = Errors.ErrorCounter.Get(ErrorObject);
	If Counter = Undefined Then
		Errors.ErrorCounter.Insert(ErrorObject, 1);
	Else
		Errors.ErrorCounter.Insert(ErrorObject, Counter+1);
	EndIf;
	
EndProcedure

// The procedure reports fill-in verification errors
//
// Parameters:
// 		Errors  - Undefined - return the value set in the procedure ObservableCollection.Add an error to the user().
// 		Cancel - Boolean - set to True if errors were reported.
//
Procedure ReportFillVerificationErrors(Errors, Cancel=False) Export
	
	If Errors.ErrorList.Count() = 0 Then
		Return;
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

#EndRegion
#EndRegion

