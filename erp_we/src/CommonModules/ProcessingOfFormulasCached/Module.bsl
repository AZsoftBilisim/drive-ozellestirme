#Region Private

#Region DeterminationOfPropertiesOfAdditionalCharacteristics

// Returns a description of supported feature sources.
//
// Returns:
//  ValueTable - table, description of supported sources of characteristics:
//    * SourceMetadata - MetadataObject - Metadata of the characteristics source.
//    * PropertyTypePrefix - String - ID of the source of characteristics.
//    * IdField_ - String -  the name of the field (Attribute) of the identifier (or name) of the type of characteristics.
//                           For example, an "identifier for formulas" for a plan of types of characteristics of an additional session.
//    * FieldTypeOfValues   - String - the name of the field (Attribute) containing the type of value of the type of characteristics.
//    		If an expression of type is specified, then specifying the value type field is optional.
//    * ValueTypeExpressionIsUsed - Boolean - Flag for using a value type expression, then
//    		an expression will be specified instead of accessing the field.
//    		for example, for the Catalog of contact information types.
//    * ExpressionTypeOfValue - String - Value type expression. Used if there is no value type field.
//    		for example, for the Catalog of contact information types, you can use
//    		the expression "type(string)".
//    * OverridingValueTypeExpression - TypeDescription - Contains a description of the types. It must always be set when there is no real field
//    		containing the value type (not PVC, the value type expression is used = True).
//    		Redefinition in the method of the New string of the tree of the polycomposition.
//    * UniquenessOfNameWithinEntireCharacteristicsTable - Boolean - If True, then the characteristic identifier (name field) is unique
//    		in the entire characteristic table. for example, the value of the "name" field of additional Attributes
//    		and information is unique in the entire table of character planspecifications.additional
//    		information requirements (because the same Attribute may be part of different sets).
//    		If False, the uniqueness of the characteristic identifier (name field) is not ensured.
//    		For example, the identifier "Phone" of the types for contact information will be used
//    		in the sets "Counterparty" / "Organization" / "Physical person", etc.
//    		if the type of contact information is specified for one type, then we can accurately determine
//    		the parameters of the type of contact information (Presentation, type). if the type of contact information
//    		is specified for a composite type, then the parameters of the type of contact information (Presentation, type)
//    		are determined in the same way as for ordinary Attributes (the Presentation is taken with the lowest value,
//    		the type of contact information is indicated as "other").
//
Function PropertiesOfSupportedFeatureSources() Export
	
	RowDescription = New TypeDescription("String",, New StringQualifiers(0, AllowedLength.Variable));
	PropertiesTable = New ValueTable();
	DetailsBoolean = New TypeDescription("Boolean");
	PropertiesTable.Columns.Add("SourceMetadata");
	PropertiesTable.Columns.Add("PropertyTypePrefix", RowDescription);
	PropertiesTable.Columns.Add("IdField_", RowDescription);
	PropertiesTable.Columns.Add("FieldTypeOfValues", RowDescription);
	PropertiesTable.Columns.Add("ValueTypeExpressionIsUsed", DetailsBoolean);
	PropertiesTable.Columns.Add("ExpressionTypeOfValue", RowDescription);
	PropertiesTable.Columns.Add("OverridingValueTypeExpression");
	PropertiesTable.Columns.Add("UniquenessOfNameWithinEntireCharacteristicsTable", DetailsBoolean);
	
	Properties = PropertiesTable.Add();
	Properties.SourceMetadata = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo;
	Properties.PropertyTypePrefix = "DR_.";
	Properties.IdField_ = "IDForFormulas";
	Properties.FieldTypeOfValues = "ValueType";
	Properties.ValueTypeExpressionIsUsed = False;
	Properties.ExpressionTypeOfValue = "";
	Properties.UniquenessOfNameWithinEntireCharacteristicsTable = True;
	
	Properties = PropertiesTable.Add();
	Properties.SourceMetadata = Metadata.Catalogs.ContactInformationKinds;
	Properties.PropertyTypePrefix = "KI.";
	Properties.IdField_ = "IDForFormulas";
	Properties.FieldTypeOfValues = "";
	Properties.ValueTypeExpressionIsUsed = True;
	Properties.ExpressionTypeOfValue = "TYPE(STRING)";
	Properties.OverridingValueTypeExpression = New TypeDescription("String");
	Properties.UniquenessOfNameWithinEntireCharacteristicsTable = False;
	
	PropertiesTable.Indexes.Add("SourceMetadata");
	PropertiesTable.Indexes.Add("PropertyTypePrefix");
	
	Return PropertiesTable;
	
EndFunction

// Returns the correspondence of English and Russian names of standard banking details.
// 
// Returns:
// 	Map - The correspondence of English and Russian names of standard details.
//
Function MatchesNamesOfStandardProps() Export
	
	MatchingNames = New Map;
	MatchingNames.Insert("DeletionMark", "DeletionMark");
	MatchingNames.Insert("Owner", "Owner");
	MatchingNames.Insert("Code", "Code");
	MatchingNames.Insert("Parent", "Parent");
	MatchingNames.Insert("Predefined", "Predefined");
	MatchingNames.Insert("IsFolder", "IsFolder");
	MatchingNames.Insert("Description", "Description");
	MatchingNames.Insert("Ref", "Ref");
	MatchingNames.Insert("PredefinedDataName", "PredefinedDataName");
	MatchingNames.Insert("Date", "Date");
	MatchingNames.Insert("Number", "Number");
	MatchingNames.Insert("Posted", "Posted");
	MatchingNames.Insert("ValueType", "ValueType");
	MatchingNames.Insert("Type", "Kind");
	MatchingNames.Insert("Order", "Order");
	MatchingNames.Insert("ActionPeriodIsBasic", "OffBalance");
	MatchingNames.Insert("HeadTask", "HeadTask");
	MatchingNames.Insert("Completed", "Completed");
	MatchingNames.Insert("Started", "Started");
	MatchingNames.Insert("BusinessProcess", "BusinessProcess");
	MatchingNames.Insert("Executed", "Executed");
	MatchingNames.Insert("RoutePoint", "RoutePoint");
	MatchingNames.Insert("SentNo", "SentNo");
	MatchingNames.Insert("ReceivedNo", "ReceivedNo");
	MatchingNames.Insert("ThisNode", "ThisNode");
	
	
	// Inverse correspondence.
	For Each KeyAndValue In MatchingNames Do
		MatchingNames.Insert(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;
	
	Return MatchingNames;
	
EndFunction

#EndRegion

Function FullNameOfDataTable(FullMetadataObjectName) Export
	Return ProcessingOfFormulas.FullNameOfDataTable(FullMetadataObjectName);
EndFunction


#Region MethodsForUpdatingInformationBase


// LongDesc
// 
// Returns:
// 	Map - matching performance and destination characteristics:
// 	 *Key - String - Performance characteristics.
// 	 *Value - Map - matching the type of metadata object that the characteristic belongs to and its parameters:
// 	        **Key - Type - the type of metadata object that the characteristic belongs to. One characteristic
// 	        				can be specified for several types.
// 	        **Value - Structure - Characteristic Parameters:
// 	             ***Characteristic - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo, CatalogRef.ContactInformationKinds - Link to the characteristic.
// 	             ***Id - String - ID of a characteristic of the type {Prefix.ID}
// 	             ***ValueType - TypeDescription - Type of the characteristic value.
//
Function CharacteristicsByPresentation() Export
	
	AllRefsType = Common.AllRefsTypeDetails();
	Return ProcessingOfFormulas.CharacteristicsByPresentation(AllRefsType);
	
EndFunction

#EndRegion




#EndRegion