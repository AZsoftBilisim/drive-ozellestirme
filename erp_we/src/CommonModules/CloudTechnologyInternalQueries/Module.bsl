#Region Internal

// Cursor queries for independent record sets

// Get a data portion of an independent recordset.
// 
// Parameters: 
//  ObjectMetadata - MetadataObject
//  Filter - Array of Structure:
//  * ComparisonType - ComparisonType
//  * Field - String
//  * Value - Arbitrary
//  PortionSize - Number
//  YouCanContinue - Boolean
//  State - See InitializeStateForFetchingPortionsOfIndependentRecordset
//  AdditionToTableName - String
// 
// Returns: 
//  Array of ValueTable:
//   * Column - Arbitrary - an arbitrary set of columns-fields of the object.
//
Function GetChunkOfDataFromIndependentRecordset(Val ObjectMetadata, Val Filter,
		Val PortionSize, YouCanContinue, State, Val AdditionToTableName = "") Export
	
	If State = Undefined Then
		State = InitializeStateForFetchingPortionsOfIndependentRecordset(ObjectMetadata, Filter, 
			AdditionToTableName);
		YouCanContinue = True;
	EndIf;
	
	Result = New Array;
	
	ItRemainsToGet = PortionSize; // It remains to get in this portion
	
	FirstSelection = False;
	
	CurrentQuery = 0; // Cur query index
	
	While True Do // Getting fragments of portions
		PortionFragment = Undefined; // The last received portion fragment
		
		If Not State.ThereWasSelection Then // First request
			State.ThereWasSelection = True;
			FirstSelection = True;
			
			Query = New Query;
			Query.Text = StrReplace(State.Queries.First, "999", Format(ItRemainsToGet, "NG="));
		Else
			Query = New Query;
			If State.Queries.Subsequent.Count() <> 0 Then 
				QueryDetails = State.Queries.Subsequent[CurrentQuery];
				CurrentQuery = CurrentQuery + 1;
				Query.Text = StrReplace(QueryDetails.Text, "999", Format(ItRemainsToGet, "NG="));
				If QueryDetails.ConditionFields <> Undefined Then 
					For Each ConditionField In QueryDetails.ConditionFields Do
						Query.SetParameter(ConditionField, State.Key[ConditionField]);
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		
		For Each FilterParameter In State.Queries.Parameters Do
			Query.SetParameter(FilterParameter.Key, FilterParameter.Value);
		EndDo;
		
		If Not IsBlankString(Query.Text) Then 
			PortionFragment = Query.Execute().Unload();
			
			FragmentSize = PortionFragment.Count();
		Else
			FragmentSize = 0;
		EndIf;
		
		If FragmentSize > 0 Then
			Result.Add(PortionFragment);
			
			FillPropertyValues(State.Key, PortionFragment[FragmentSize - 1]);
		EndIf;
		
		If FragmentSize < ItRemainsToGet Then
			
			If Not FirstSelection // If this was the first request, there is no point in continuing
				And CurrentQuery < State.Queries.Subsequent.Count() Then
				
				ItRemainsToGet = ItRemainsToGet - FragmentSize;
				
				Continue; // Go to the next query
			Else
				YouCanContinue = False;
			EndIf;
		EndIf;
		
		Break;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Cursor queries for independent record sets

// Parameters:
// 	ObjectMetadata - MetadataObjectInformationRegister, MetadataObjectSequence - the selection object.
// 	Filter - Array - the selection conditions.
// 	AdditionToTableName - String - addition.
// Returns:
// 	Structure:
// * ThereWasSelection - Boolean
// * Key - Structure - structure for storing the value of the last key.
// * Queries - FixedStructure - Query Descriptions:
//		** First - String - text of the request for receiving the first portion.
//		** Subsequent - FixedArray - subsequent requests.
//		** Parameters - Structure - selection parameters.
Function InitializeStateForFetchingPortionsOfIndependentRecordset(Val ObjectMetadata, Val Filter, 
	Val AdditionToTableName = "")
	
	IsInformationRegister    = Metadata.InformationRegisters.Contains(ObjectMetadata);
	
	IsSequence = Metadata.Sequences.Contains(ObjectMetadata);
	
	KeyFields = New Array; // Fields that form the record key
	
	If IsInformationRegister And ObjectMetadata.InformationRegisterPeriodicity 
		<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		
		KeyFields.Add("Period");
	EndIf;
	
	If IsSequence Then 
		
		KeyFields.Add("Recorder");
		KeyFields.Add("Period");
		
	EndIf;
	
	AddDelimitersToKey(ObjectMetadata, KeyFields);
	
	For Each MetadataDimensions In ObjectMetadata.Dimensions Do
		KeyFields.Add(MetadataObjectName(MetadataDimensions));
	EndDo;
	
	SelectionFields1 = New Array; // all fields
	
	If IsInformationRegister Then 
		
		For Each ResourceMetadata In ObjectMetadata.Resources Do
			SelectionFields1.Add(MetadataObjectName(ResourceMetadata));
		EndDo;
		
		For Each AttributeMetadata In ObjectMetadata.Attributes Do
			SelectionFields1.Add(MetadataObjectName(AttributeMetadata));
		EndDo;
		
	EndIf;
	
	For Each KeyField In KeyFields Do
		SelectionFields1.Add(KeyField);
	EndDo;
	
	TableAlias = "_TableRecordset"; // Table alias in the Query Text
	
	SelectionFieldString_ = ""; // Part of the Query Text with selection fields
	For Each SelectionField In SelectionFields1 Do
		If Not IsBlankString(SelectionFieldString_) Then
			SelectionFieldString_ = SelectionFieldString_ + "," + Chars.LF;
		EndIf;
		
		SelectionFieldString_ = SelectionFieldString_ + Chars.Tab + TableAlias + "." + SelectionField + " AS " + SelectionField;
	EndDo;
	
	StringOfOrderingFields = ""; //Part of the Query Text with ordering fields
	For Each KeyField In KeyFields Do
		If Not IsBlankString(StringOfOrderingFields) Then
			StringOfOrderingFields = StringOfOrderingFields + ", ";
		EndIf;
		StringOfOrderingFields = StringOfOrderingFields + KeyField;
	EndDo;
	
	If TypeOf(Filter) = Type("Array") Then
		Filter = CreateSelectionCondition(TableAlias, Filter);
	EndIf;
	
	// Preparation of requests for receiving portions
	If KeyFields.Count() = 0 Then 
		QueryTemplate = // The general part of the request
		"SELECT
		|&SelectionFieldString_
		|FROM
		|	&Table
		|WHERE &Condition";
	Else
		// The portion size is set in the method to get a portion of the data from a non-dependent set of records
		QueryTemplate = // The general part of the request
		"SELECT TOP 999
		|&SelectionFieldString_
		|FROM
		|	&Table
		|WHERE &Condition
		|ORDER BY
		|	&StringOfOrderingFields";
	EndIf;
	QueryTemplate = StrReplace(QueryTemplate, "&SelectionFieldString_", SelectionFieldString_);
	QueryTemplate = StrReplace(QueryTemplate, "&Table", 
		ObjectMetadata.FullName() + AdditionToTableName + " AS " + TableAlias);
	QueryTemplate = StrReplace(QueryTemplate, "&StringOfOrderingFields", StringOfOrderingFields);
	
	// Request for the first portion
	If Not IsBlankString(Filter.FilterCriterion) Then
		RequestTextForFirstPortion = StrReplace(QueryTemplate, "&Condition", Filter.FilterCriterion);
	Else
		RequestTextForFirstPortion = StrReplace(QueryTemplate, "WHERE &Condition", "");
	EndIf;
	
	Queries = New Array; // Requests for subsequent portions
	For RequestCounter_ = 0 To KeyFields.UBound() Do
		
		ConditionFieldString = ""; // Part of the request text with the condition fields
		ConditionFields = New Array; // Fields participating in the condition
		
		NumberOfConditionFields = KeyFields.Count() - RequestCounter_;
		For FieldIndex = 0 To NumberOfConditionFields - 1 Do
			If Not IsBlankString(ConditionFieldString) Then
				ConditionFieldString = ConditionFieldString + " And ";
			EndIf;
			
			KeyField = KeyFields[FieldIndex];
			
			If FieldIndex = NumberOfConditionFields - 1 Then
				LogicalOperator = ">";
			Else
				LogicalOperator = "=";
			EndIf;
			
			ConditionFieldString = ConditionFieldString + TableAlias + "." + KeyField + " " 
				+ LogicalOperator + " &" + KeyField;
				
			ConditionFields.Add(KeyField);
		EndDo;
		
		If Not IsBlankString(Filter.FilterCriterion) Then
			ConditionFieldString = Filter.FilterCriterion + " And " + ConditionFieldString;
		EndIf;
		
		QueryDetails = New Structure("Text, ConditionFields");
		QueryDetails.Text = StrReplace(QueryTemplate, "&Condition", ConditionFieldString);
		QueryDetails.ConditionFields = New FixedArray(ConditionFields);
		
		Queries.Add(New FixedStructure(QueryDetails));
		
	EndDo;
	
	QueryDescriptions = New Structure;
	QueryDescriptions.Insert("First", RequestTextForFirstPortion);
	QueryDescriptions.Insert("Subsequent", New FixedArray(Queries));
	QueryDescriptions.Insert("Parameters", Filter.FilterParameters);
	
	KeyStructure1 = New Structure; // Structure for storing the value of the last key
	For Each KeyField In KeyFields Do
		KeyStructure1.Insert(KeyField);
	EndDo;
	
	State = New Structure;
	State.Insert("Queries", New FixedStructure(QueryDescriptions));
	State.Insert("Key", KeyStructure1);
	State.Insert("ThereWasSelection", False);
	
	Return State;
	
EndFunction

Procedure AddDelimitersToKey(Val ObjectMetadata, KeyFields)
	
	For Each CommonAttribute In Metadata.CommonAttributes Do 

		If Not CommonAttribute.SeparatedDataUse = 
			Metadata.ObjectProperties.CommonAttributeSeparatedDataUse.IndependentlyAndSimultaneously Then 
			Continue;
		EndIf;
		
		CommonPropsElement = CommonAttribute.Content.Find(ObjectMetadata);
		If CommonPropsElement <> Undefined Then
			
			If ElementIsUsedInSeparator(CommonAttribute, CommonPropsElement) Then  
				KeyFields.Add(CommonAttribute.Name);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ElementIsUsedInSeparator(CommonAttribute, CommonPropsElement)
	
	CommonAttributeAutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse;
	CommonAttributeUse     = Metadata.ObjectProperties.CommonAttributeUse;
	
	If CommonAttribute.AutoUse = CommonAttributeAutoUse.Use Then 
		If CommonPropsElement.Use = CommonAttributeUse.Auto
			Or CommonPropsElement.Use = CommonAttributeUse.Use Then 
				Return True;
		Else
				Return False;
		EndIf;
	Else
		If CommonPropsElement.Use = CommonAttributeUse.Auto
			Or CommonPropsElement.Use = CommonAttributeUse.DontUse Then 
				Return False;
		Else
				Return True;
		EndIf;
	EndIf;
	
EndFunction

Function CreateSelectionCondition(Val TableAlias, Val Filter)
	
	FIlterRow = ""; // Part of the query text with the condition formed by selection
	FilterParameters = New Structure;
	If Filter.Count() > 0 Then
		For Each FilterDetails In Filter Do
			If Not IsBlankString(FIlterRow) Then
				FIlterRow = FIlterRow + " And ";
			EndIf;
			
			ParameterName = "P" + Format(FilterParameters.Count(), "NZ=0; NG=");
			FilterParameters.Insert(ParameterName, FilterDetails.Value);
			
			Operand = "&" + ParameterName;
			
			If FilterDetails.ComparisonType = ComparisonType.Equal Then
				LogicalOperator = "=";
			ElsIf FilterDetails.ComparisonType = ComparisonType.NotEqual Then
				LogicalOperator = "<>";
			ElsIf FilterDetails.ComparisonType = ComparisonType.InList Then
				LogicalOperator = "In";
				Operand = "(" + Operand + ")";
			ElsIf FilterDetails.ComparisonType = ComparisonType.NotInList Then
				LogicalOperator = "NOT IN";
				Operand = "(" + Operand + ")";
			ElsIf FilterDetails.ComparisonType = ComparisonType.Greater Then
				LogicalOperator = ">";
			ElsIf FilterDetails.ComparisonType = ComparisonType.GreaterOrEqual Then
				LogicalOperator = ">=";
			ElsIf FilterDetails.ComparisonType = ComparisonType.Less Then
				LogicalOperator = "<";
			ElsIf FilterDetails.ComparisonType = ComparisonType.LessOrEqual Then
				LogicalOperator = "<=";
			Else
				MessageTemplate = NStr("vi = 'Không hỗ trợ dạng so sánh %1.';
										|ru = 'Вид сравнения %1 не поддерживается.';
										|en = 'Comparison type %1 is not supported.'; fa = 'Comparison type %1 is not supported.';
										|it = 'Il tipo di confronto %1 non viene supportato.';
										|pl = 'Widok porównania %1 nie jest obsługiwany.';
										|tr = '%1 karşılaştırma türü desteklenmiyor.'");
				MessageText = StrTemplate(MessageTemplate, FilterDetails.ComparisonType);
				Raise MessageText;
			EndIf;
			
			FIlterRow = FIlterRow + TableAlias + "." + FilterDetails.Field + " " + LogicalOperator + " " + Operand;
		EndDo;
	EndIf;
	
	Return New Structure("FilterCriterion, FilterParameters", FIlterRow, FilterParameters);
	
EndFunction

// Returns the name of the metadata object.
// 
// Parameters:
// 	MetadataObject - MetadataObject - metadata object.
// Returns:
// 	String - the name of the metadata object.
Function MetadataObjectName(MetadataObject)
	
	Return MetadataObject.Name;
	
EndFunction

#EndRegion

