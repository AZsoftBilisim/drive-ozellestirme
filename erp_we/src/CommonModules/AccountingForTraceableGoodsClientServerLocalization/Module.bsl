#Region Public

// Complements the structure of actions for recalculating a row in the table part, in order to fill in the 'Accountedpornpt' attribute.
//
// Parameters:
//	StructureOfActions - Structure - describes actions where:
//		* Key - String - name of the action.
//		* Value - Structure - the parameters of the action.
//	StringActionParameters - Structure, Undefined - a collection whose key is the name of the source
//															of the nomenclature field (for which the traceability attribute is checked
//															), for example, "Nomenclature Arrival".
//															And the value is the name of the field that stores information about
//															the traceability feature of the nomenclature, for example,
//															"Accounting for Accounting".
//
Procedure CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions,
																				StringActionParameters = Undefined) Export
	
	If StringActionParameters = Undefined Then
		StringActionParameters = New Structure("Products", "AccountingForTheRNPTIsMaintained");
	EndIf;
	
EndProcedure

// Returns a structure containing the fields of values used to fill in the quantity for the RNPT in the rows of the table
// part of the document.
//
// Parameters:
//	Object - FormDataStructure, Structure - object form data that contains:
//		* Ref - DocumentRef - link to the document in the information security system that you are working with.
//	StorageLocationFieldName - String - name of the Warehouse field or other storage location located in the object header or table part.
//	StorageLocationInTabularPart - Boolean - indicates whether the Warehouse or other storage location field is present in the table part of the object.
//	FieldNamesWithSuffix - Undefined, Structure - collection containing requesite names with the suffix:
//		* Key - String - the Attribute name without the suffix, for example, "Product"
//		* Value - String - the Attribute name with a suffix, for example, "nomenclature".
//
// Returns:
//	Structure - contains the following properties:
//		* ExcludedDocument - DocumentRef - a document whose movements are excluded when calculating the coefficient for the RNPT.
//		* Organization - CatalogRef.Companies - the organization for which the coefficient is calculated according to the RNPT.
//		* Terms - CatalogRef.TermsOfSale - the agreement for which the RNPT coefficient is calculated.
//		* StorageLocationInTabularPart - Boolean - indicates whether the Warehouse or other storage location field is present in the table part of the object.
//		* StorageLocationFieldName - String - name of the Warehouse field or other storage location located in the object header or table part.
//		* StorageLocation - CatalogRef.Warehouses - a warehouse or other storage location for which the RNPT coefficient is calculated.
//		* FieldNamesWithSuffix - Undefined, Structure - collection containing requesite names with the suffix:
//			** Key - String - the Attribute name without the suffix, for example, "Product"
//			** Value - String - the Attribute name with a suffix, for example, "nomenclature".
//
Function ParametersForObtainingRnptCoefficient(Object, StorageLocationFieldName = "Warehouse", StorageLocationInTabularPart = False,
	FieldNamesWithSuffix = Undefined) Export
	
	If FieldNamesWithSuffix = Undefined Then
		FieldNamesWithSuffix = New Structure;
	EndIf;
	
	FillingStructureOfRnptCoefficient = New Structure;
	FillingStructureOfRnptCoefficient.Insert("Date",							Object.Date);
	FillingStructureOfRnptCoefficient.Insert("ExcludedDocument",				Object.Ref);
	FillingStructureOfRnptCoefficient.Insert("Organization",						Object.Organization);
	FillingStructureOfRnptCoefficient.Insert("StorageLocationInTabularPart",	StorageLocationInTabularPart);
	FillingStructureOfRnptCoefficient.Insert("StorageLocationFieldName",			StorageLocationFieldName);
	FillingStructureOfRnptCoefficient.Insert("StorageLocation",					Undefined);
	FillingStructureOfRnptCoefficient.Insert("Terms",
												PredefinedValue("Catalog.TermsOfSale.EmptyRef"));
	FillingStructureOfRnptCoefficient.Insert("FieldNamesWithSuffix",			FieldNamesWithSuffix);
	
	If Not StorageLocationInTabularPart
		And CommonClientServer.HasAttributeOrObjectProperty(Object, StorageLocationFieldName) Then
		
		FillingStructureOfRnptCoefficient.Insert("StorageLocation", Object[StorageLocationFieldName]);
		
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Object, "Terms") Then
		FillingStructureOfRnptCoefficient.Terms = Object.Terms;
	EndIf;
	
	Return FillingStructureOfRnptCoefficient;
	
EndFunction

// Complements the structure of actions for recalculating a row in the table part, for the purpose of recalculating the 'Qty'field.
//
// Parameters:
//	Object - FormDataStructure - the form data object.
//	StructureOfActions - Structure - describes actions, where the Key is the name of the action,
//									The value - Structure - activity settings.
//	StorageLocationFieldName - String - name of the Warehouse field or other storage location located in the object header or table part.
//	StorageLocationInTabularPart - Boolean - indicates whether the Warehouse or other storage location field is present in the table part of the object.
//	Suffix - String - Suffix of the name of the Quantity and Quantity fields. Informs the system that you need to use the
//	names Quantity Suffix and Quantity Suffix.
//
Procedure AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(Object,
																	StructureOfActions,
																	StorageLocationFieldName = "Warehouse",
																	StorageLocationInTabularPart = False,
																	Suffix = "") Export
	
	
EndProcedure

// Returns the value of the RNPT coefficient for the current row of the table part of the object according to the specified parameters.
//
// Parameters:
//	RecalculationParameters - See AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient.
//	CurrentRow - Structure - the line of the table part for which the coefficient is calculated according to the RNPT.
//	CachedValues - Structure - cached values of the current table part row.
//
// Returns:
//	Number - the coefficient of the RNPT.
//
Function GetRnptCoefficient(RecalculationParameters, CurrentRow, CachedValues) Export
	
	Result = 0;
	
	
	Return Result;
	
EndFunction

// Called after splitting the string, for the correct distribution of the quantity by the RNPT.
// Can be transferred to processing of the notification method, Observationnelle.Break the string.
//
// Parameters:
//	NewRow - FormDataCollectionItem - string of the table part after splitting.
//	AdditionalParameters - Structure - with the following keys:
//		* InitialString - FormDataCollectionItem - link to a row in the table part that we are splitting.
//		* InitialQuantity_ - Number - the number of the source string, before splitting.
//
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export
	
	
EndProcedure

// Adds (or creates) a structure containing the necessary information for splitting a row in the table part,
// taking into account the number of RPT.
//
// Parameters:
//	CurrentRow - Structure - selected row of the table part.
//	AdditionalParameters - Structure - an input parameter of the same name for the announcement Description object.
//
// Returns:
//	Structure - the properties contain the necessary information for splitting the row of the tabular part
//				, taking into account the number of RNPT.
//
Function CompleteDescriptionOfParametersForSplittingRowInTablePart(CurrentRow,
																AdditionalParameters = Undefined) Export
	
	If Not ValueIsFilled(AdditionalParameters) Then
		AdditionalParameters = New Structure();
	EndIf;
	
	
	Return AdditionalParameters;
	
EndFunction

//	Returns the name of the selection form based on the remnants of traceable goods as part of the OS
//
// Returns:
//	String - the name of the selection form for the remnants of traceable goods in the OS
//
Function NameOfFormOfSelectionForRemainsOfTraceableGoodsVos() Export
	
	PickingFormName = "";
	Return PickingFormName;
	
EndFunction

// Fills in the parameters of the customs declaration - the registration number and a sign of whether the goods were declared in the Russian Federation.
// Procedure for obtaining the registration number of the customs declaration See VATAccountingClientServerLocalization.CheckCorrectnessOfCustomsDeclarationNumber.
// If the Type number parameter is passed, which contains a non-empty value, then the registration number will be filled
// in depending on the parameter value.
// If the registration number takes the value of an empty string, a sign will be set that the goods were not declared in the Russian Federation.
//
// Parameters:
//	TheseNumbers - Structure - a collection containing official information obtained from the number of the customs declaration.
//	CustomsDeclarationNumber - String - customs Declaration number or registration number of the customs Declaration.
//	CCDNumberType - EnumRef.CCDNumberTypes, Undefined - the type OF THE Catalog ITEM OF THE License Plate number.
//
Procedure FillInRegistrationNumberAndCountryOfImportation(TheseNumbers, CustomsDeclarationNumber, CCDNumberType = Undefined) Export
	
	
EndProcedure

// Returns a collection containing the CCD room types that are available for tracking items.
//
// Parameters:
//	TracedGoods - Boolean - a sign of keeping records of traceable items.
//
// Returns:
//	Array of EnumRef.CCDNumberTypes - a collection containing the CCD room types available for the specified
//													item type.
Function CCDNumberTypes(TracedGoods) Export
	
	CCDNumberTypes = New Array;
	
		CCDNumberTypes.Add(PredefinedValue("Enum.CCDNumberTypes.CCDNumber"));
	
	Return CCDNumberTypes;
	
EndFunction

#EndRegion

#Region Internal

Function KeyCacheCoefficientRNPT(CurrentRow, RecalculationParameters) Export
	
	CacheKey		= "";
	EmptyValue	= "EmptyValue";
	StorageLocation	= ?(RecalculationParameters.StorageLocationInTabularPart,
						CurrentRow[RecalculationParameters.StorageLocationFieldName],
						RecalculationParameters.StorageLocation);
	
	CacheKey = ?(ValueIsFilled(RecalculationParameters.Organization),
				String(RecalculationParameters.Organization.UUID()),
				EmptyValue);
	CacheKey = CacheKey + ?(ValueIsFilled(RecalculationParameters.Terms),
							String(RecalculationParameters.Terms.UUID()),
							EmptyValue);
	CacheKey = CacheKey + ?(ValueIsFilled(CurrentRow.Products),
							String(CurrentRow.Products.UUID()),
							EmptyValue);
	CacheKey = CacheKey + ?(CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "Characteristic")
								And ValueIsFilled(CurrentRow.Characteristic),
							String(CurrentRow.Characteristic.UUID()),
							EmptyValue);
	CacheKey = CacheKey + ?(ValueIsFilled(StorageLocation),
							String(StorageLocation.UUID()),
							EmptyValue);
	CacheKey = CacheKey + ?(CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "CCDNumber")
								And ValueIsFilled(CurrentRow.CCDNumber),
							String(CurrentRow.CCDNumber.UUID()),
							EmptyValue);
	CacheKey = CacheKey + ?(ValueIsFilled(RecalculationParameters.Date),
							String(RecalculationParameters.Date),
							EmptyValue);
	
	Return CacheKey;
	
EndFunction

#EndRegion
