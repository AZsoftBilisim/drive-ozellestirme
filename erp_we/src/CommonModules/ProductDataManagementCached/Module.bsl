////////////////////////////////////////////////////////////////////////////////
// NSI of production: Procedures of the subsystem of product data management
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a description of the operand data sources by manager.
//
// Parameters:
//  ManagerName - String	 - name of the directory Manager.
// 
// Returns:
//  Structure - See Catalogs.BillsOfMaterials.DescriptionOfOperandDataSources
//
Function DescriptionOfOperandDataSources(ManagerName) Export
	
	Return Catalogs[ManagerName].DescriptionOfOperandDataSources();
	
EndFunction

#Region KitsInProduction

// Caches the value of the constant of the source of the composition of the production.
// 
// Returns:
//  EnumRef.SourcesOfCompositionOfSetsInProduction - The source of the composition of sets in production
Function SourceOfCompositionOfSetsInProduction() Export
	
	SetPrivilegedMode(True);
	
	Return Constants.SourceOfCompositionOfSetsInProduction.Get();
	
EndFunction

// Determines the availability of the use of kits in production.
// 
// Returns:
//  Boolean - Result
Function UseOfKitsInProductionIsAvailable() Export
	
	SourceOfCompositionOfSetsInProduction = ProductDataManagementCached.SourceOfCompositionOfSetsInProduction();
	
	Return ValueIsFilled(SourceOfCompositionOfSetsInProduction)
		And SourceOfCompositionOfSetsInProduction <> Enums.SourcesOfCompositionOfSetsInProduction.DontUse;
	
EndFunction

// Determines the availability of storage of the set composition in the specifications.
// 
// Returns:
//  Boolean - Result
Function ItIsAvailableToStoreCompositionOfSetInSpecifications() Export
	
	SourceOfCompositionOfSetsInProduction = ProductDataManagementCached.SourceOfCompositionOfSetsInProduction();
	
	Return (SourceOfCompositionOfSetsInProduction = Enums.SourcesOfCompositionOfSetsInProduction.Specifications)
		Or (SourceOfCompositionOfSetsInProduction = Enums.SourcesOfCompositionOfSetsInProduction.SpecificationsOrConfigurationOptions);
	
EndFunction

// Determines the availability of storage of the set composition in the configuration options.
// 
// Returns:
//  Boolean - Result
Function StorageOfCompositionOfSetIsAvailableInConfigurationOptions() Export
	
	SourceOfCompositionOfSetsInProduction = ProductDataManagementCached.SourceOfCompositionOfSetsInProduction();
	
	Return (SourceOfCompositionOfSetsInProduction = Enums.SourcesOfCompositionOfSetsInProduction.KitConfigurations)
		Or (SourceOfCompositionOfSetsInProduction = Enums.SourcesOfCompositionOfSetsInProduction.SpecificationsOrConfigurationOptions);
	
EndFunction

#EndRegion

#Region AssignmentParameters

// Checks the use of the type of specification assignment parameter.
//
// Parameters:
//  ParameterKind - EnumRef.TypesOfBOMAssignmentParameters - type of parameter to define
//  CheckFunctionalOption - Boolean - specifies whether to check when the function option is disabled
//
// Returns:
//   Boolean - indication of the use of the type of destination parameter
//
Function TypeOfDestinationParameterIsUsed(ParameterKind, CheckFunctionalOption = True) Export
	
	If CheckFunctionalOption
			And Not GetFunctionalOption("UseBOMAssignmentParameters") Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.BOMAssignmentParameters AS T
	|WHERE
	|	T.ParameterKind IN (&TypesOfParameters)";
	
	Query = New Query(QueryText);
	Query.SetParameter("TypesOfParameters", ProductDataManagement.TypeOfDestinationParameterInArray(ParameterKind));
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Checks the use of the specification assignment parameter.
// 
// Parameters:
//  ParameterKind - EnumRef.TypesOfBOMAssignmentParameters - type of parameter
//  Attribute - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - parameter details
//  CheckFunctionalOption - Boolean - specifies whether to check when the function option is disabled
// 
// Returns:
//  Boolean - The destination parameter is used
Function DestinationParameterIsUsed(ParameterKind, Attribute, CheckFunctionalOption = True) Export
	
	If CheckFunctionalOption
			And Not GetFunctionalOption("UseBOMAssignmentParameters") Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.BOMAssignmentParameters AS T
	|WHERE
	|	T.ParameterKind = &ParameterKind
	|	AND T.Attribute = &Attribute";
	
	Query = New Query(QueryText);
	Query.SetParameter("ParameterKind", ParameterKind);
	Query.SetParameter("Attribute",     Attribute);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region PackageData

// Constructor of the packaging data structure.
// 
// Parameters:
//  Numerator - Number - Numerator
//  Denominator - Number - Denominator
// 
// Returns:
//  FixedStructure - Packing Data Structure:
// * Numerator - Number - Numerator
// * Denominator - Number - Denominator
Function PackingDataStructure(Numerator = 1, Denominator = 1) Export
	
	Return New FixedStructure("Numerator, Denominator", ?(Numerator = 0, 1, Numerator), ?(Denominator = 0, 1, Denominator));
	
EndFunction

#EndRegion
#Region DescriptionsOfPlugInFunctions

// Returns a description of the functions used in the formula constructor.
// 
// Returns:
//  See ProductDataManagementClientServer.DescriptionOfFormulaConstructorFunctions
//
Function DescriptionOfFormulaConstructorFunctions() Export
	
	Return ProductDataManagementClientServer.DescriptionOfFormulaConstructorFunctions();
	
EndFunction

// Generates an array of descriptions of auto-selection functions.
// 
// Returns:
//  See ProductDataManagement.DescriptionOfAutoSelectFeatureFunctions
//
Function DescriptionOfAutoSelectFeatureFunctions() Export
	
	Return ProductDataManagement.DescriptionOfAutoSelectFeatureFunctions();
	
EndFunction

// Generates an array of descriptions of auto-selection functions.
// 
// Returns:
//  See ProductDataManagement.DescriptionOfAutoSelectionFunctionsForProductItemPropertyValue
//
Function DescriptionOfAutoSelectionFunctionsForProductItemPropertyValue() Export
	
	Return ProductDataManagement.DescriptionOfAutoSelectionFunctionsForProductItemPropertyValue();
	
EndFunction

#EndRegion
#Region ImportProductionMasterData

// List OF groups OF Attributes of the uploaded data ELEMENT
// Parameters:
//  ToExclude - Boolean - include Attributes that are not available for interactive configuration
// 
// Returns:
//  Array of String
Function AttributesGroups(ToExclude = False) Export
	
	Return ProductDataManagementClientServer.AttributesGroups(ToExclude);
	
EndFunction

// List of groups of Attributes of the item header
// Parameters:
//  ToExclude - Boolean - include Attributes that are not available for interactive configuration
// 
// Returns:
//  Array of String
Function GroupsOfAttributesForItemHeader(ToExclude = False) Export
	
	Return ProductDataManagementClientServer.GroupsOfAttributesForItemHeader(ToExclude);
	
EndFunction

#EndRegion
#Region Other

// Returns an array of all reference types defined in the configuration.
//
// Returns:
// Array of Type
Function AllConfigurationReferenceTypes() Export
	
	Result = New Array;
	
	CommonClientServer.SupplementArray(Result, Catalogs.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Documents.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, BusinessProcesses.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfCharacteristicTypes.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfAccounts.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfCalculationTypes.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Tasks.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ExchangePlans.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Enums.AllRefsType().Types());
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion