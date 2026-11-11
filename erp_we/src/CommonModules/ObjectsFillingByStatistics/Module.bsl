#Region Public

// Fills in the object's details based on their usage statistics.
//
// Parameters:
//  Object - DocumentObject - the object whose details must be filled in:
//  	* AdditionalProperties - Structure - Additional object properties:
//  		** DisableObjectFillingBasedOnStatistics - Boolean - True if you need to disable filling in details based on statistics.
//  		                                                     For example, in the scenario of loading objects from another system.
//  FillingData - Arbitrary - the value that is used to fill in the object.
//  DescriptionOfBankingDetailsToFillIn - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//      If the parameter is omitted, the description of The Attributes will be obtained from the function
//      Set the description of the filled-in requirements to the statistics() defined in the object manager module.
//
// Returns:
//  Structure - the details of the object that were filled in according to statistics,
//      where the Key is the name of the props, and the Value is its new value.
//
Function FillObjectAttributes(Object, FillingData, DescriptionOfBankingDetailsToFillIn = Undefined) Export
	
	If Object.AdditionalProperties.Property("DisableObjectFillingBasedOnStatistics")
		And Object.AdditionalProperties.DisableObjectFillingBasedOnStatistics Then
		Return New Structure;
	EndIf;
	
	FillInAccordingToStatistics = CommonSettingsStorage.Load(
		"DocumentSettings_", "FillInDocumentAttributesUsingStatisticalData");
	If FillInAccordingToStatistics = False Then
		Return New Structure;
	EndIf;

	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"CommonModule.ObjectsFillingByStatistics.FillObjectAttributes");
	ReturnValue = FillInBankingDetails(Object, "", FillingData, DescriptionOfBankingDetailsToFillIn);
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	Return ReturnValue
	
EndFunction

// Fills in the object's details based on the statistics of their use,
// which were subordinated to the specified key details in the description of the object's details to be filled in.
//
// Parameters:
//  Object - DocumentObject - the object whose details must be filled in
//  KeyAttribute - String - the name of the item's details, whose subordinate details must be filled in according to statistics.
//  DescriptionOfBankingDetailsToFillIn - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//      If the parameter is omitted, the description of The Attributes will be obtained from the function
//      Set the description of the filled-in requirements to the statistics() defined in the object manager module.
//  ToCheckSettings - Boolean - if the attribute is True, the subordinate Attributes are filled in depending on
//      the "Fill in Attributes of documents for statistics" setting.
//
// Returns:
//  Structure - the details of the object that were filled in according to statistics,
//      where the Key is the name of the props, and the Value is its new value.
//
Function FillInSubordinateDetailsOfObject(Object, KeyAttribute, DescriptionOfBankingDetailsToFillIn = Undefined, ToCheckSettings = True) Export
	
	If ToCheckSettings Then
		FillInAccordingToStatistics = CommonSettingsStorage.Load(
			"DocumentSettings_", "FillInDocumentAttributesUsingStatisticalData");
		If FillInAccordingToStatistics = False Then
			Return New Structure;
		EndIf;
	EndIf;
	
	Return FillInBankingDetails(Object, KeyAttribute, Undefined, DescriptionOfBankingDetailsToFillIn);
	
EndFunction

// Gets the values of details based on statistics of their use in a specific type of object.
//
// Parameters:
//  Ref - AnyRef - a reference to an object that defines the type that you need to get values from
//  DescriptionOfBankingDetailsToFillIn - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//  KeyDetails_ - Structure - values of key details within which statistics are collected.
//
// Returns:
//  Structure - the details for which the values were obtained according to statistics,
//      where the Key is the name of the prop, and the Value is its value.
//
Function GetBankingDetailsValues(Ref, DescriptionOfBankingDetailsToFillIn, KeyDetails_ = Undefined) Export
	
	MetadataObjectName = Ref.Metadata().FullName();
	
	// We will get a description of the structure of the details to fill in
	DescriptionOfItemDetails =
		Common.CopyRecursive(
			ObjectsFillingByStatisticsInternal.DescriptionOfItemDetails(
				MetadataObjectName,
				DescriptionOfBankingDetailsToFillIn));
	
	If ValueIsFilled(DescriptionOfItemDetails.ErrorText) Then // error in the description of the details to be filled in
		Raise DescriptionOfItemDetails.ErrorText;
	EndIf;
	
	// Let's add information about the object itself to the description of the object's details
	DescriptionOfItemDetails.Object.Insert("Ref",               Ref);
	DescriptionOfItemDetails.Object.Insert("MetadataObjectName", MetadataObjectName);
	// We take the author not from the document details, but from the information security user, because statistics need to be collected on this person.
	DescriptionOfItemDetails.CacheOfPropsValues.Insert("Author", Users.AuthorizedUser());
	
	ReceivedValues_ = New Structure;
	
	// We bypass the props tree - from the top-level "parents" to the props that do not have "subordinate" props.
	For Each CurLevelDetails In DescriptionOfItemDetails.ProcedureForFillingInBankingDetails Do
		
		// Fill in each of the props of the current level of the props tree
		For Each Attribute In CurLevelDetails Do
			
			// Add to the cache the values of the missing "parent details" (which have not been used yet).
			For Each Parent In DescriptionOfItemDetails.ObjectAttributes[Attribute.Key] Do
				If Not DescriptionOfItemDetails.CacheOfPropsValues.Property(Parent.Key) Then
					DescriptionOfItemDetails.CacheOfPropsValues.Insert(Parent.Key);
					FillPropertyValues(DescriptionOfItemDetails.CacheOfPropsValues, KeyDetails_, Parent.Key);
				EndIf;
			EndDo;
			
			// We will form a description of the filled in props
			DetailsToFillIn_ = New Structure;
			DetailsToFillIn_.Insert("AttributeName",   Attribute.Key);
			DetailsToFillIn_.Insert("PreviousValue2", Attribute.Value);
			DetailsToFillIn_.Insert("NewValue",  Undefined);
			
			// We will get the value of the props according to statistics
			ValueOfPropsForStatistics(DescriptionOfItemDetails, DetailsToFillIn_);
			
			// Transfer the received value
			ReceivedValues_.Insert(DetailsToFillIn_.AttributeName, DetailsToFillIn_.NewValue);
			
			// Add the current account details to the cache (to fill in the "subordinate" details)
			DescriptionOfItemDetails.CacheOfPropsValues.Insert(DetailsToFillIn_.AttributeName, DetailsToFillIn_.NewValue);
			
		EndDo;
		
	EndDo;
	
	Return ReceivedValues_;
	
EndFunction

// Function-constructor of parameters to be filled in based on statistics of the object's details usage.
// Allows you to set the relationship of the details to be filled in with the" key " details of the object and, based on their values,
// use them as sections and/or conditions for collecting usage statistics.
//
// Returns:
//  Structure:
//     * StatisticsCollectionSections - Structure - list of fields that specify a filter for getting objects for which statistics will be collected:
//         * UseAlways - String - names of key details, separated by commas,
//               that participate in the selection of objects for collecting statistics.
//         * UseOnlyCompletedFields - String - comma-separated names of key details
//               that participate in the selection of objects for statistics collection only if they are filled in
//     * FillInIf - Structure - list of conditions that allow filling in details for statistics
//         * ObjectFieldsFilledIn - String - comma-separated names of key details
//               that must be filled in to start collecting statistics
//         * ObjectFieldsAreEmpty - String - comma-separated names of key details
//               that must be empty to start collecting statistics.
//     * StatisticsCollectionParameters - Structure - See NewParametersForCollectingStatistics().
//
Function ParametersOfBankingDetailsToFillIn() Export
	
	StatisticsCollectionSections = New Structure("UseAlways, UseOnlyCompletedFields");
	FillInIf    = New Structure("ObjectFieldsFilledIn, ObjectFieldsAreEmpty");
	StatisticsCollectionParameters = NewParametersForCollectingStatistics();
	
	Parameters = New Structure;
	Parameters.Insert("StatisticsCollectionSections", StatisticsCollectionSections);
	Parameters.Insert("FillInIf", FillInIf);
	Parameters.Insert("StatisticsCollectionParameters", StatisticsCollectionParameters);
	
	Return Parameters;
	
EndFunction

// Adds information to the description structure about the object details to be filled in and their relationship to the key details
// within which usage statistics are collected.
//
// Parameters:
//  DescriptionOfBankingDetailsToFillIn - Structure - variable that stores the description of the details to be filled in
//  AttributesNames - String - comma-separated names of Bank details to add a description to
//  Parameters - Structure - parameters of The Attributes to Fill
//      (See ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn)In.
//
Procedure AddDescriptionOfDetailsToFillIn(DescriptionOfBankingDetailsToFillIn, AttributesNames, Parameters = Undefined) Export
	
	For Each Attribute In StrSplit(AttributesNames, ",", False) Do
		
		KeyAttributes = New Structure;
		
		If ValueIsFilled(Parameters) Then
			AddKeyDetails(KeyAttributes, Parameters.FillInIf.ObjectFieldsFilledIn,
				"FieldsMustBeFilledIn");
			AddKeyDetails(KeyAttributes, Parameters.FillInIf.ObjectFieldsAreEmpty,
				"FieldsShouldBeEmpty");
			AddKeyDetails(KeyAttributes, Parameters.StatisticsCollectionSections.UseAlways,
				"SelectAlways");
			AddKeyDetails(KeyAttributes, Parameters.StatisticsCollectionSections.UseOnlyCompletedFields,
				"SelectOnlyCompletedFields");
			KeyAttributes.Insert("StatisticsCollectionParameters", Parameters.StatisticsCollectionParameters);
		EndIf;
		
		DescriptionOfBankingDetailsToFillIn.Insert(TrimAll(Attribute), KeyAttributes);
		
	EndDo;
	
EndProcedure

// Returns the structure of parameters for collecting statistics.
//
// Returns:
//  Structure - parameters for collecting statistics, contains the keys:
//  	* SelectionSize - Number - the number of selected objects, by default 5.
//  	* FrequencyOfUseOfValue - Number - the frequency of using the value (the weight of the value in the sample) can take
//  		values from 0 to 1, by default 0.5
//  		the weight of the value in the sample above this value allows you to consider the value "frequency".
//  	* IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor - Boolean - if True, if there is no data on the author
//  		, the value will be obtained without taking into account the author.
//
Function NewParametersForCollectingStatistics() Export
	
	StatisticsCollectionParameters = New Structure;
	StatisticsCollectionParameters.Insert("SelectionSize", 5);
	StatisticsCollectionParameters.Insert("FrequencyOfUseOfValue", 0.5);
	StatisticsCollectionParameters.Insert("IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor", False);
	
	Return StatisticsCollectionParameters;
	
EndFunction

#EndRegion

#Region Internal

// The author of the new document that is the source for the Installauthor object subscription fills in the details.
//
// Parameters:
//  Source - DocumentObject - document with the author's details
//  Cancel - Boolean - flag for refusing to write
//  WriteMode - DocumentWriteMode - the current recording mode of the document
//  PostingMode - DocumentPostingMode - the current mode of the document.
//
Procedure SetObjectAuthorBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Source.Ref) Then
		Source.Author = Users.AuthorizedUser();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region FillingMechanism

// Fills in the object's details based on statistics.
//
// Parameters:
//  Object - DocumentObjectDocumentName - object to fill in
//  SelectionByDetailsToParent - String - the name of the item's details, whose subordinate details must be filled in according to statistics.
//  FillingData - Arbitrary - parameter of the same name for the handler procedure for filling in the object module
//  DescriptionOfBankingDetailsToFillIn - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//
//  Returns:
//  Structure - Structure:
//  		* Key - String - name of the changed item's details
//  		* Value - String - new value of the object's props.
//
Function FillInBankingDetails(Object, SelectionByDetailsToParent, FillingData, DescriptionOfBankingDetailsToFillIn)
	
	MetadataObjectName = MetadataObjectName(Object);
	
	If DescriptionOfBankingDetailsToFillIn = Undefined Then
		DescriptionOfBankingDetailsToFillIn = New Structure;
		Common.ObjectManagerByFullName(MetadataObjectName).EnterDescriptionOfDetailsToFillInBasedOnStatistics(
			DescriptionOfBankingDetailsToFillIn);
	EndIf;
	
	// We will get a description of the structure of the details to fill in
	DescriptionOfItemDetails =
		Common.CopyRecursive(
			ObjectsFillingByStatisticsInternal.DescriptionOfItemDetails(
				MetadataObjectName,
				DescriptionOfBankingDetailsToFillIn,
				SelectionByDetailsToParent));
	
	If ValueIsFilled(DescriptionOfItemDetails.ErrorText) Then // error in the description of the details to be filled in
		Raise DescriptionOfItemDetails.ErrorText;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		ValuesFromFillInData =
			Common.CopyRecursive(
				ObjectsFillingByStatisticsInternal.DetailsToBeFilledInFromFillingData(MetadataObjectName));
		
		FillPropertyValues(ValuesFromFillInData, FillingData);
		
		For Each KeyAndValue In ValuesFromFillInData Do
			If ValueIsFilled(KeyAndValue.Value)
				And Not (ValueIsFilled(Object[KeyAndValue.Key]) And Object[KeyAndValue.Key] <> False) Then
				// Let's transfer the value from the fill data to the object.
				// This is necessary in order not to fill in the details according to statistics,
				// which should be filled out from the filling data.
				Object[KeyAndValue.Key] = KeyAndValue.Value;
			EndIf;
		EndDo;
		
	EndIf;
	
	// Let's add information about the object itself to the description of the object's details
	DescriptionOfItemDetails.Object.Insert("Ref",               Object.Ref);
	DescriptionOfItemDetails.Object.Insert("MetadataObjectName", MetadataObjectName);
	// We take the author not from the document details, but from the information security user, because statistics need to be collected on this person.
	DescriptionOfItemDetails.CacheOfPropsValues.Insert("Author", Users.AuthorizedUser());
	
	ChangedBankingDetails = New Structure; // changed item Attributes
	
	// We bypass the props tree - from the top-level "parents" to the props that do not have "subordinate" props.
	For Each CurLevelDetails In DescriptionOfItemDetails.ProcedureForFillingInBankingDetails Do
		
		// What should be filled in at this iteration
		DetailsToFillIn = Common.CopyRecursive(CurLevelDetails);
		FillPropertyValues(DetailsToFillIn, Object);
		
		// Fill in each of the props of the current level of the props tree
		For Each Attribute In DetailsToFillIn Do
			
			// Add to the cache the values of the missing "parent details" (which have not been used yet).
			For Each Parent In DescriptionOfItemDetails.ObjectAttributes[Attribute.Key] Do
				If Not DescriptionOfItemDetails.CacheOfPropsValues.Property(Parent.Key) Then
					DescriptionOfItemDetails.CacheOfPropsValues.Insert(Parent.Key);
					FillPropertyValues(DescriptionOfItemDetails.CacheOfPropsValues, Object, Parent.Key);
				EndIf;
			EndDo;
			
			// We will form a description of the filled in props
			DetailsToFillIn_ = New Structure;
			DetailsToFillIn_.Insert("AttributeName",   Attribute.Key);
			DetailsToFillIn_.Insert("PreviousValue2", Attribute.Value);
			DetailsToFillIn_.Insert("NewValue",  Undefined);
			
			// We will get the value of the props according to statistics
			ValueOfPropsForStatistics(DescriptionOfItemDetails, DetailsToFillIn_);
			
			If ValueIsFilled(DetailsToFillIn_.NewValue)
				And DetailsToFillIn_.NewValue <> DetailsToFillIn_.PreviousValue2 Then
				
				// The value of the object Attribute differs from the value obtained from statistics
				ChangedBankingDetails.Insert(DetailsToFillIn_.AttributeName, DetailsToFillIn_.NewValue);
				
				Object[DetailsToFillIn_.AttributeName] = DetailsToFillIn_.NewValue;
				
			EndIf;
			
			// Add the current account details to the cache (to fill in the "subordinate" details)
			DescriptionOfItemDetails.CacheOfPropsValues.Insert(DetailsToFillIn_.AttributeName, DetailsToFillIn_.NewValue);
			
		EndDo;
		
	EndDo;
	
	Return ChangedBankingDetails; // for reference, the Attributes of the object have already been changed
	
EndFunction

// The definition of the parameters for gathering statistics.
//
// Parameters:
//  DescriptionOfItemDetails - Structure - description of the structure of the details to fill in, contains the keys
//  	The object Structure contains the keys
//  		Link-any Link - link to the object
//  		Metadata ObjectName-String-full name of the metadata object
//  	other keys See ObjectsFillingByStatisticsInternal.DescriptionOfItemDetails
//  DetailsToFillIn_ - Structure - description of the filled-in details, contains keys
//  	Markusica - String - the name of the fill in the props object
//
// Returns:
//  Structure - parameters for collecting statistics, contains the keys
//  	The selection size is a number (x > 0) - the number of selected objects, by default 5
//  	The frequency of use of the value is a number (0 <= x <= 1) - the frequency of use of the value (the weight of the value in the sample), by default 0.5
//  		the weight of the value in the sample above this value allows you to consider the value "frequency".
//
Function StatisticsCollectionParameters(Val DescriptionOfItemDetails, DetailsToFillIn_)
	
	If DescriptionOfItemDetails.StatisticsCollectionParameters.Property(DetailsToFillIn_.AttributeName) Then
		Return DescriptionOfItemDetails.StatisticsCollectionParameters[DetailsToFillIn_.AttributeName];
	EndIf;
	
	StatisticsCollectionParameters = NewParametersForCollectingStatistics();
	
	Return StatisticsCollectionParameters;
	
EndFunction

// Defines the value of the props, which according to statistics is "frequency".
//
// Parameters:
//  DescriptionOfItemDetails - Structure - description of the structure of Attributes to fill in, contains the keys:
//  	* Object - Structure - Contains keys:
//  		* Ref - AnyRef - object reference
//  		* MetadataObjectName - String - full name of the metadata object
//  	other keys See ObjectsFillingByStatisticsInternal.DescriptionOfItemDetails
//  DetailsToFillIn_ - Structure - description of the filled-in details, contains keys
//  	Markusica - String - the name of the fill in the props object
//  	Old value-Custom - the current value of the filled-in props
//  	New value-Arbitrary - the new value of the filled-in props, Undefined by default.
//
Procedure ValueOfPropsForStatistics(DescriptionOfItemDetails, DetailsToFillIn_)
	
	// If the details are already filled in, then its value is not overfilled
	If ValueIsFilled(DetailsToFillIn_.PreviousValue2) And DetailsToFillIn_.PreviousValue2 <> False Then
		DetailsToFillIn_.NewValue = DetailsToFillIn_.PreviousValue2;
		Return;
	EndIf;
	
	// We will process the details for which you need to select data for statistics
	ParentDetailsValues = New Structure;
	For Each ParentDetails In DescriptionOfItemDetails.ObjectAttributes[DetailsToFillIn_.AttributeName] Do
		AttributeValue = DescriptionOfItemDetails.CacheOfPropsValues[ParentDetails.Key];
		PropsValueFilledIn = ValueIsFilled(AttributeValue) And AttributeValue <> False;
		
		If ParentDetails.Value.Property("FieldsMustBeFilledIn") And Not PropsValueFilledIn
			Or ParentDetails.Value.Property("FieldsShouldBeEmpty") And PropsValueFilledIn Then
			Return;
		EndIf;
		
		If ParentDetails.Value.Property("SelectOnlyCompletedFields") And PropsValueFilledIn
			Or ParentDetails.Value.Property("SelectAlways") Then
			ParentDetailsValues.Insert(ParentDetails.Key, AttributeValue);
		EndIf;
	EndDo;
	
	// Let's define the parameters for collecting statistics
	StatisticsCollectionParameters = StatisticsCollectionParameters(DescriptionOfItemDetails, DetailsToFillIn_);
	
	DetailsToFillIn_.NewValue = ObjectsFillingByStatisticsInternal.ValueOfPropsForStatistics(
		DescriptionOfItemDetails.Object.Ref, DescriptionOfItemDetails.Object.MetadataObjectName,
		DetailsToFillIn_.AttributeName, ParentDetailsValues,
		StatisticsCollectionParameters);
	
	If Not DataIsRelevant(DetailsToFillIn_.NewValue) Then
		DetailsToFillIn_.NewValue = Undefined;
	EndIf;
	
	If DetailsToFillIn_.NewValue = Undefined
		And StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor Then
		DetailsToFillIn_.NewValue = ObjectsFillingByStatisticsInternal.ValueOfPropsForStatistics(
			DescriptionOfItemDetails.Object.Ref, DescriptionOfItemDetails.Object.MetadataObjectName,
			DetailsToFillIn_.AttributeName, ParentDetailsValues,
			StatisticsCollectionParameters, True);
		If Not DataIsRelevant(DetailsToFillIn_.NewValue) Then
			DetailsToFillIn_.NewValue = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

Function DataIsRelevant(Value)
	
	DataIsRelevant = True;
	
	If Not ValueIsFilled(Value) Then
		Return DataIsRelevant;
	EndIf;
	
	ValueType = TypeOf(Value);
	AttributeNameDeletionMark = "DeletionMark";
	AttributeNameStatus = "Status";
	AttributeNameIsClosed = "Closed";
	
	SetPrivilegedMode(True);
	If Common.IsReference(ValueType)
		And Common.IsStandardAttribute(Value.Metadata().StandardAttributes, "DeletionMark")
		And Common.ObjectAttributeValue(Value, AttributeNameDeletionMark) Then
		DataIsRelevant = False;
	ElsIf (ValueType = Type("CatalogRef.BusinessStructure")
		Or ValueType = Type("CatalogRef.Companies"))
		And Common.ObjectAttributeValue(Value, AttributeNameStatus) = Enums.BusinessUnitCompanyStatuses.NotValid Then
		DataIsRelevant = False;
	ElsIf (ValueType = Type("CatalogRef.CounterpartyBankAccounts")
		Or ValueType = Type("CatalogRef.CompaniesBankAccounts"))
		And Common.ObjectAttributeValue(Value, AttributeNameIsClosed) Then
		DataIsRelevant = False;
	EndIf;
	SetPrivilegedMode(False);
	
	Return DataIsRelevant;

EndFunction

Function MetadataObjectName(Object)
	
	If TypeOf(Object) = Type("FormDataStructure") Then
		MetadataObject = Object.Ref.Metadata();
	Else // DocumentObject
		MetadataObject = Object.Metadata();
	EndIf;
	
	Return MetadataObject.FullName();
	
EndFunction

Procedure AddKeyDetails(KeyAttributes, AttributesNames, PropertyName)
	For Each KeyAttribute In StrSplit(AttributesNames, ",", False) Do
		AttributeName = TrimAll(KeyAttribute);
		If Not KeyAttributes.Property(AttributeName) Then
			KeyAttributes.Insert(AttributeName, New Structure());
		EndIf;
		KeyAttributes[AttributeName].Insert(PropertyName);
	EndDo;
EndProcedure

#EndRegion

#EndRegion
