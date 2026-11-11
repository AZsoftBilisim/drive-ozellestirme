////////////////////////////////////////////////////////////////////////////////
// Report Options - UT Report Form (Server call, redefined)
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a structure of parameters and selection of the decoding
// Parameters:
//   Details - DataCompositionDetailsID - the value obtained from the report during decryption.
//   DetailsDataAddress - String - an address that points to a value in temporary storage.
//   ParametersList - Array - contains the names of parameters and fields used for decryption
//   DecryptionFields - String - contains the names of the fields used for decryption.
//
// Returns:
//   Structure - the name of the parameter or selection for the receiver report is returned as the key,
//   			and the value of the parameter or selection is returned as the value.
//
Function ExplanationFormParameters(Details, DetailsDataAddress, ParametersList, DecryptionFields) Export

	ExplanationFormParameters = New Structure;
	
	DetailsData = GetFromTempStorage(DetailsDataAddress);
	
	CheckingDecryptionFields = New ValueTable;
	CheckingDecryptionFields.Columns.Add("Value");
	CheckingDecryptionFields.Columns.Add("FieldName");
	CheckingDecryptionFields.Columns.Add("Hierarchy", New TypeDescription("Boolean"));
	
	AddParents(DetailsData.Items[Details], CheckingDecryptionFields);
	
	For Each FieldData In CheckingDecryptionFields Do
		FieldName = StrReplace(FieldData.FieldName, ".", "_");
		If DecryptionFields.Find(FieldName) = Undefined Then
			Continue;
		EndIf;
		
		If Not ExplanationFormParameters.Property(FieldName) Then
			
			If FieldData.Hierarchy Then
				DetailsValue = New Structure;
				DetailsValue.Insert("ComparisonType", DataCompositionComparisonType.InHierarchy);
				DetailsValue.Insert("RightValue", FieldData.Value);
				ExplanationFormParameters.Insert(FieldName, DetailsValue);
			Else
				ExplanationFormParameters.Insert(FieldName, FieldData.Value);
			EndIf;
		ElsIf Not ExplanationFormParameters.Property(FieldName + "_Parent") Then
			If FieldData.Value = Null Then
				Continue;
			EndIf;
			DetailsValue = New Structure;
			DetailsValue.Insert("ComparisonType", DataCompositionComparisonType.InHierarchy);
			DetailsValue.Insert("RightValue", FieldData.Value);
			ExplanationFormParameters.Insert(FieldName + "_Parent", DetailsValue);
		EndIf;
	EndDo;
	
	ConfigurationDecryptionData = DetailsData.Settings; // DataCompositionSettings -
	For Each ParameterName In ParametersList Do
		ParameterValue = ConfigurationDecryptionData.DataParameters.Items.Find(ParameterName);
		If ParameterValue = Undefined Or Not ParameterValue.Use Then
			Continue;
		EndIf;
		ExplanationFormParameters.Insert(ParameterName, ParameterValue.Value);
	EndDo; 
	
	ExplanationFormParameters.Insert("Filter", DetailsData.Settings.Filter);
	
	If ExplanationFormParameters.Count() <> 0 Then
		Return ExplanationFormParameters;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Procedure AddParents(DetailsItem, CheckingDecryptionFields)
	
	If TypeOf(DetailsItem) = Type("DataCompositionFieldDetailsItem") Then
		For Each Field In DetailsItem.GetFields() Do
			Filter = New Structure("Value, FieldName, Hierarchy", Field.Value, Field.Field, Field.Hierarchy);
			FoundRows = CheckingDecryptionFields.FindRows(Filter);
			
			If FoundRows.Count() = 0 Then
				NewField = CheckingDecryptionFields.Add();
				NewField.Value = Field.Value;
				NewField.FieldName = Field.Field;
				NewField.Hierarchy = Field.Hierarchy;
			EndIf;
		EndDo;
	EndIf;
	For Each Parent In DetailsItem.GetParents() Do
		AddParents(Parent, CheckingDecryptionFields);
	EndDo;
	
EndProcedure

#EndRegion