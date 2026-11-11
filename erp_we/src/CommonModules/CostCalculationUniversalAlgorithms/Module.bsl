///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Batch accounting (universal algorithms)
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region DistributionByMethodOfReducedRemainder

#Region DescriptionOfDistributionAlgorithm
	
// Let's consider the example of the task of filling in inventory types in the cost register,
// when cost accounting was initially conducted without taking into account inventory types, and from a certain period there was a need
// to account for cost with detailing to the inventory type of the nomenclature.
// Balances with empty inventory types are in the Inventory Cost register.
// The balances with the filled types of stocks are in the register of commodity organizations.
// It is necessary to divide the balances for each accounting item of the cost register by the available types of stocks of goods of organizations in proportion to the amount of the balance.
// We will reduce the number of fields in the tables – we do not specify fields that do not affect the logic of distribution.

// INITIAL DATA FOR DISTRIBUTION
// 1. Source table (TI). These data need to be distributed (adjusted).
// 2. Table-distribution base (TB). This data is used to increase the granularity of data from TI.
// 3. Description of TI and BB fields:
// The connection fields are the common TI and TB fields by which the data of these tables will be compared
// - Organization
// - Analyticscountainment of Nomenclature
// TI basis field – the name of the field for storing the reduced balance in TI
// - Quantity
// TB basis field – a similar field in TB
// - Quantity
// TI resources – TI sum fields distributed proportionally to the remainder
// - Cost
// - Additional expenses
// Other TI fields – TI fields that are not directly involved in the distribution, but are necessary in the distribution result table (TR)
// - Party (there will also be analytics of Party accounting, Accounting division, activity types...)
// - the number of such fields can be any;
// - the order of enumeration of these fields is important – it will be used for sorting TI
// Other TB fields – similar fields in TB
// - Type of supplies
// Rules for filling in other fields as a result of distribution: specify which field to take from which table (only for fields present in both TI and TB)
// - always from TI
// - always from TB
// - from TI if filled, then from TB
// - from TB if filled, then from TI

// DESCRIPTION OF THE DISTRIBUTION ALGORITHM
// 1. Data numbering
// 1.1. Select all the DIFFERENT values of the TI and TB communication fields, arrange them by <Communication Fields> and number them.
// We get the table in the connection field

// 1.2. Arrange TI by <Communication fields> + <Other fields TI> and we will number, at the same time
// - add Price fields<Resource name> = <Resource name > / (positive quantity) 
// - we will bring the Quantity field to a positive value, and its initial sign (+1 or -1) will be placed in the Base sign field
// - we impose a selection Quantity <> 0
// We get the table in the input

// 1.3. Arrange TB by <Communication fields> + <Other fields TB> and we will number, at
// - the same time we will bring the Quantity field to a positive value
// - at the same time, we will impose a selection Number <> 0
// We will get the table in the input

// 2. Data distribution

// 3. End of distribution

// 3.1. We get a general table of distribution results
// - We combine all tables of the form in the result of the description<Rule number>
// We get the resultsreferences

// 3.2. We form the final table of the generated adjustments 
// - we connect the results of the list with the Vtishodnayati and VTISHODNAYATB
// 	- We take the quantity from the result of the list and multiply it by the base sign from the input
// 	- we take resources from the results of the description (their sign is already correct)
// 	- we take the communication fields from the input
// 	- we take the other fields from the entry or entry according to the specified rules
// 	- if the register is adjusted, then add the columns Period, type of movement = Arrival, Registrar, Record type
// - if the register is adjusted, then add the same entries to the result (for reverse Balances), but
// 	- with a negative amount and resources
// 	- with other fields taken only from the input (if there is no field in the input, then we write an empty value of the corresponding type into it)
// - if the register is adjusted, then the columns that are not in the corrected register are discarded.
// We get the resultdistribution

// 3.3. Diagnose distribution errors
// - we subtract from the input the table of the resultsreferences
// 	- if there is not a single row for the link key in the result list ("there is no data in the distribution database")
// 	- if there are rows where the number is <> 0 ("there is not enough data in the distribution database")
// - we subtract the Result list table from the input
// 	- if there is not a single row for the link key in the result of the description ("there is no data in the TI for distribution")
// 	- if there are rows where the number is <> 0 ("there is not enough data in the TI for distribution")

// 3.4. We delete all the remaining unnecessary tables formed during the calculation
// - we leave only the result of the distribution, the source's undistributed data, the database's undistributed data

#EndRegion 

#Region InitializingDistribution

// Initializes the main distribution parameters.
// Obligatory.
//
// Parameters:
//  SourceTableName - String - name of the temporary table that contains data for distribution.
//  NameOfDatabaseTable - String - name of the temporary table containing the database to distribute data from the source table Name.
// 	LinkFields- String - the list of fields (separated by commas) by which the data of the source table name will be compared with the data of the distribution table name table;
//		the field names of these tables must match;
//		The comparison is performed according to the condition "The name of the source table.Field Connection1 = Name of the Distribution database table.Field connection1 and the name of the source table.Polesvyazi2 = Name of the Distribution database table.Polesvyazi2 And ...".
//	DeleteSourceAfterDistribution - Boolean - specifies whether the source TableName should be deleted after the distribution is complete.
//	DeleteDatabaseAfterDistribution - Boolean - specifies whether to delete the table table_name of the distribution Base after the end of the distribution.
// Returns:
// 	Structure - LongDesc:
// * Templates - Structure -:
// ** FieldSelectionRules - String -
// ** DatabaseFields_ - String -
// ** DatabaseFieldsNotNamed - String -
// ** NamedDatabaseFields - String -
// ** SourceFieldsNotNamed - String -
// ** NamedSourceFields - String -
// ** ConnectionFieldsJoin - String -
// ** LinkFieldsNotNamed - String -
// ** NamedCommunicationFields - String -
// ** JoiningStringsOr - String -
// ** ConnectingStringsAnd - String -
// ** FieldSeparator - String -
// * RulesForFillingInOtherFields - Structure -
// * DoNotIncludeDatabaseFields - String -
// * DonTIncludeSourceFields - String -
// * OtherDatabaseFields - String -
// * OtherSourceFields - String -
// * AllocationRules - Array of Structure-
// * DatabaseSortingFields - String -
// * DeleteDatabaseAfterDistribution - Boolean -
// * DeleteSourceAfterDistribution - Boolean -
// * NegativeBasesArePossible - Boolean -
//
Function InitializeDistributionParametersUsingReducedRemainderMethod(
			SourceTableName, NameOfDatabaseTable, LinkFields,
			DeleteSourceAfterDistribution = False, DeleteDatabaseAfterDistribution = False) Export
	
	DistributionParameters = New Structure;
	// Description of sources and receivers of distribution data
	DistributionParameters.Insert("SourceTableName", 				 SourceTableName);
	DistributionParameters.Insert("DeleteSourceAfterDistribution", DeleteSourceAfterDistribution);
	DistributionParameters.Insert("NameOfDatabaseTable", 		 NameOfDatabaseTable);
	DistributionParameters.Insert("DeleteDatabaseAfterDistribution", 	 DeleteDatabaseAfterDistribution);
	DistributionParameters.Insert("NegativeBasesArePossible", 	 	 False);
	// Description of communication fields
	DistributionParameters.Insert("LinkFields",			LinkFields);
	// Description of numeric fields
	DistributionParameters.Insert("AllocationRules",	New Array); // contains structures with the fields of a resource source, a field base, a field base base
	// Description of other fields
	DistributionParameters.Insert("OtherSourceFields",	"");
	DistributionParameters.Insert("OtherDatabaseFields",		"");
	// Description of the database sorting fields
	DistributionParameters.Insert("DatabaseSortingFields",	"");
	// Description of filling in the fields
	DistributionParameters.Insert("DonTIncludeSourceFields", 		"");
	DistributionParameters.Insert("DoNotIncludeDatabaseFields", 			"");
	DistributionParameters.Insert("RulesForFillingInOtherFields",	New Structure);
	
	// Description of the resulting tables.
	InitializeDistributionResultTables(DistributionParameters,
		"TTDistributionResult",
		"TTUnallocatedSourceData",
		"TTUnallocatedDatabaseData");
	
	// Query Field Templates
	Templates = New Structure;
	Templates.Insert("FieldSeparator", "," + Chars.LF + Chars.Tab);
	Templates.Insert("ConnectingStringsAnd", Chars.LF + Chars.Tab + "And ");
	Templates.Insert("JoiningStringsOr", Chars.LF + Chars.Tab + "OR ");
	
	NamedCommunicationFields   = "";
	LinkFieldsNotNamed = "";
	ConnectionFieldsJoin    = "";
	
	For Each FieldName In StringFunctionsClientServer.SplitStringIntoSubstringsArray(LinkFields, ",", True, True) Do
		SupplementString(NamedCommunicationFields,   "%1." + FieldName + " AS " + FieldName,,,, Templates.FieldSeparator);
		SupplementString(LinkFieldsNotNamed, "%1." + FieldName ,,,, Templates.FieldSeparator);
		SupplementString(ConnectionFieldsJoin, "%1." + FieldName + " = %2." + FieldName,,,, Templates.ConnectingStringsAnd);
	EndDo;
	
	Templates.Insert("NamedCommunicationFields",   	  NamedCommunicationFields);
	Templates.Insert("LinkFieldsNotNamed", 	  LinkFieldsNotNamed);
	Templates.Insert("ConnectionFieldsJoin",    	  ConnectionFieldsJoin);
	Templates.Insert("NamedSourceFields",   "");
	Templates.Insert("SourceFieldsNotNamed", "");
	Templates.Insert("NamedDatabaseFields",   	  "");
	Templates.Insert("DatabaseFieldsNotNamed", 	  "");
	Templates.Insert("DatabaseFields_", 	 	  "");
	Templates.Insert("FieldSelectionRules", 		  "");
	
	DistributionParameters.Insert("Templates", Templates);
	
	Return DistributionParameters;
	
EndFunction

// Initializes the description of the tables where the distribution results are placed.
// Optional.
//
// Parameters:
//	DistributionParameters - Structure - the result of the function initializationparameters of the distribution of the method of decreasing the limit()
//	NameOfResultTable - String - name of the temporary table where the distribution result is placed.
//	NameOfUnallocatedSourceDataTable - String - name of the temporary table that contains source data that is not distributed across the database;
//		if an empty row is specified, the table will not be formed.
//	NameOfDatabaseSUnallocatedDataTable - String - name of the temporary table that contains database data for which there is no data in the source;
//		if an empty row is specified, the table will not be formed.
//
//	Returns:
//		Structure - distribution parameters.
//
Function InitializeDistributionResultTables(DistributionParameters,
			NameOfResultTable,
			NameOfUnallocatedSourceDataTable = "",
			NameOfDatabaseSUnallocatedDataTable = "") Export
	
	DistributionParameters.Insert("NameOfResultTable", 					 NameOfResultTable);
	DistributionParameters.Insert("NameOfUnallocatedSourceDataTable", NameOfUnallocatedSourceDataTable);
	DistributionParameters.Insert("NameOfDatabaseSUnallocatedDataTable", 	 NameOfDatabaseSUnallocatedDataTable);
	
	Return DistributionParameters;
	
EndFunction

// Initializes a description of the numeric fields of the tables to be distributed.
// Obligatory. You can call multiple times.
// There may be situations when the distribution of different resources of the source table must be performed on different bases.
// For example, the Resource1 resource must be allocated to the Basis1 field, and the Resource2 resource must be allocated to the Basis2 field.
// In this case, you need to call the procedure two times:
// initialize the numberdistribution field with the method of decreasing the stat (distribution Parameters, "Resource1", "Basis1", " Basis1");
// Initializeddistribution Numberdistribution Method (Distributionparameters, "Resource2", "Basis2", " Basis2");
//
// Parameters:
//	DistributionParameters - See CostCalculationUniversalAlgorithms.InitializeDistributionParametersUsingReducedRemainderMethod
//	SourceResources - String - list of distributed numeric fields in the source table (separated by commas).
//	SourceBasisField - String - name of the source table basis field to allocate resources to.
//	BASEBASEField - String - the name of the field in a basis table of the database that you want to perform the allocation of resources; may not coincide with Polemoniaceae.
//
Procedure InitializeNumericalDistributionFieldsUsingReducedRemainderMethod(DistributionParameters,
			SourceResources = "", SourceBasisField = "Count", BASEBASEField = "Count") Export
			
	AllocatedAccordingToRule = New Structure;
	AllocatedAccordingToRule.Insert("SourceResources",		SourceResources);
	AllocatedAccordingToRule.Insert("SourceBasisField",	SourceBasisField);
	AllocatedAccordingToRule.Insert("BASEBASEField",			BASEBASEField);
	
	// Query Field Templates
	AllocatedAccordingToRule.Insert("Templates",				New Structure);
	
	SourceBasis 			  	 = "%1." + SourceBasisField;
	NamedSourceBasis 	 = "%1." + SourceBasisField + " AS " + SourceBasisField;
	BaseBase 			 	  	 = "%1." + BASEBASEField;
	NamedBaseBase 	     = "%1." + BASEBASEField + " AS " + BASEBASEField;
	SelectingNonzeroSourceBasis = SourceBasis + " <> 0";
	SelectingNonZeroBasisBase 	 = BaseBase + " <> 0";
	SourceBasisDistributed = "SUM(%1.Basis_Distributed) AS " + SourceBasisField;
	
	CalculationOfBasisForWriteOff =
		"CASE WHEN %2." + BASEBASEField + " IS NULL
		|			THEN 0
		|		WHEN %3." + SourceBasisField + " < %2." + BASEBASEField + "
		|			THEN %3." + SourceBasisField + "
		|		ELSE %2." + BASEBASEField + "
		|	END AS BasisForDebiting";
	
	CalculationIsTBLine = "CASE WHEN %2." + BASEBASEField + " IS NULL THEN FALSE ELSE TRUE END AS ThereIsTBLine";
	BasisForDebiting = "%1.BasisForDebiting AS " + SourceBasisField;
	ZeroSourceBasis = "0 AS " + SourceBasisField;
	ReducingSourceBasis = "%1." + SourceBasisField + " - ISNULL(%4." + SourceBasisField + ", 0) AS " + SourceBasisField;
	ReducingBasisOfBase = "%1." + BASEBASEField + " - ISNULL(%4." + SourceBasisField + ", 0) AS " + BASEBASEField;
	FilterReducingSourceBasis = "%1." + SourceBasisField + " - ISNULL(%4." + SourceBasisField + ", 0) > 0 ";
	FilterReducingBasisOfBase = "%1." + BASEBASEField + " - ISNULL(%4." + SourceBasisField + ", 0) > 0 ";
	
	SourceBasisIsPositive = "SUM(CASE WHEN %1." + SourceBasisField + " < 0 THEN -%1." + SourceBasisField + " ELSE %1." + SourceBasisField + " END)";
	SourceBasisIsOriginal	= "SUM(%1." + SourceBasisField + ")";
	BasisOfBaseIsPositive      = "SUM(CASE WHEN %1." + BASEBASEField + " < 0 THEN -%1." + BASEBASEField + " ELSE %1." + BASEBASEField + " END)";
	
	SumOfSourceBases = "SUM(%1." + SourceBasisField + ") AS " + SourceBasisField;
	SumOfBaseBases = "SUM(%1." + BASEBASEField + ") AS " + BASEBASEField;
	NonZeroSumOfDistributedBaseBases = "SUM(%1." + BASEBASEField + ") <> 0";
	
	SourceBasisPositiveNamed = SourceBasisIsPositive + " AS " + SourceBasisField;
	SourceBasisOriginalNamed = SourceBasisIsOriginal + " AS " + SourceBasisField;
	BasisOfBaseIsPositiveNamed      = BasisOfBaseIsPositive + " AS " + BASEBASEField;
	
	SourceBasisSign 			 = "CASE WHEN %1." + SourceBasisField + " < 0 THEN -1 ELSE 1 END AS Character" + SourceBasisField;
	SourceBaseSignNotNamed = "CASE WHEN %1." + SourceBasisField + " < 0 THEN -1 ELSE 1 END";
	BaseSign      			 = "CASE WHEN " + BASEBASEField + " < 0 THEN -1 ELSE 1 END AS Character" + BASEBASEField;
	BaseSignBaseNotNamed		 = "CASE WHEN " + BASEBASEField + " < 0 THEN -1 ELSE 1 END";
	SourceBasisWithOriginalSign 	 = "%1." + SourceBasisField + " * ISNULL(%3.Character" + SourceBasisField + ", 1) AS " + SourceBasisField;
	BasisOfBaseWithOriginalSign 	 	 = "%1." + SourceBasisField + " * ISNULL(%2.Character" + BASEBASEField + ", 1) AS " + BASEBASEField;
	
	SelectionIsNonzeroSumOfSourceBases = SourceBasisIsPositive + " <> 0";
	SelectionIsNonZeroSumOfBasesOfBase = BasisOfBaseIsPositive + " <> 0";
	
	NamedResources = "";
	CalculatedResourcesNamed = "";
	NamedResourceAmounts = "";
	SelectingNonZeroSourceAmounts = "";
	NamedResourcePrices = "";
	PricesOfResourceAmountsNamed  = "";
	ResourcesToWriteOff = "";
	ZeroSourceResources = "";
	ReducingSourceResources = "";
	AmountOfSourceResources = "";
	NonZeroAmountOfDistributedSourceResources = "";
	
	For Each FieldName In StringFunctionsClientServer.SplitStringIntoSubstringsArray(SourceResources, ",", True, True) Do
		
		SupplementString(NamedResources, "%1." + FieldName + " AS " + FieldName);
		SupplementString(CalculatedResourcesNamed, "%1.Basis_Distributed * ISNULL(%2.Price" + FieldName + ", 0) AS " + FieldName);
		SupplementString(NamedResourceAmounts, "SUM(%1." + FieldName + ") AS " + FieldName);
		SupplementString(SelectingNonZeroSourceAmounts, "SUM(%1." + FieldName + ") <> 0",,,, " OR ");
		
		SupplementString(NamedResourcePrices,  "%1.Price" + FieldName + " AS Price" + FieldName);
		SupplementString(PricesOfResourceAmountsNamed,  "CASE WHEN " + SourceBasisIsPositive + " = 0 THEN 0
			|	ELSE SUM(%1." + FieldName + ") / " + SourceBasisIsPositive + " END AS Price" + FieldName);
		
		SupplementString(ResourcesToWriteOff, "
			|	CAST(CASE WHEN NOT %1.ThereIsTBLine
			|			THEN 0
			|		WHEN %1.BasisForDebiting = %3." + SourceBasisField + "
			|			THEN %3." + FieldName + " 
			|		ELSE %1.BasisForDebiting * %3.Price" + FieldName + "
			|	END AS NUMBER (31,2)) AS " + FieldName);
		
		SupplementString(ZeroSourceResources, "0 AS " + FieldName);
		SupplementString(ReducingSourceResources, "%1." + FieldName + " - ISNULL(%4." + FieldName + ", 0) AS " + FieldName);
		
		SupplementString(AmountOfSourceResources, "SUM(%1." + FieldName + ") AS " + FieldName);
		SupplementString(NonZeroAmountOfDistributedSourceResources, "SUM(%1." + FieldName + ") <> 0",,,, DistributionParameters.Templates.JoiningStringsOr);
		
	EndDo;
	
	AllocatedAccordingToRule.Templates.Insert("SourceBasis", 						SourceBasis);
	AllocatedAccordingToRule.Templates.Insert("NamedSourceBasis", 				NamedSourceBasis);
	AllocatedAccordingToRule.Templates.Insert("SourceBasisDistributed", 			SourceBasisDistributed);
	AllocatedAccordingToRule.Templates.Insert("BaseBase", 								BaseBase);
	AllocatedAccordingToRule.Templates.Insert("NamedBaseBase", 					NamedBaseBase);
	AllocatedAccordingToRule.Templates.Insert("SelectingNonzeroSourceBasis", 			SelectingNonzeroSourceBasis);
	AllocatedAccordingToRule.Templates.Insert("SelectingNonZeroBasisBase", 				SelectingNonZeroBasisBase);
	AllocatedAccordingToRule.Templates.Insert("SourceBasisPositiveNamed", SourceBasisPositiveNamed);
	AllocatedAccordingToRule.Templates.Insert("SourceBasisOriginalNamed",	SourceBasisOriginalNamed);
	AllocatedAccordingToRule.Templates.Insert("BasisOfBaseIsPositiveNamed", 		BasisOfBaseIsPositiveNamed);
	AllocatedAccordingToRule.Templates.Insert("SourceBasisSign", 					SourceBasisSign);
	AllocatedAccordingToRule.Templates.Insert("BaseSign", 						BaseSign);
	AllocatedAccordingToRule.Templates.Insert("SourceBaseSignNotNamed", 		SourceBaseSignNotNamed);
	AllocatedAccordingToRule.Templates.Insert("BaseSignBaseNotNamed", 			BaseSignBaseNotNamed);
	AllocatedAccordingToRule.Templates.Insert("SelectionIsNonzeroSumOfSourceBases", 	SelectionIsNonzeroSumOfSourceBases);
	AllocatedAccordingToRule.Templates.Insert("SelectionIsNonZeroSumOfBasesOfBase",			SelectionIsNonZeroSumOfBasesOfBase);
	AllocatedAccordingToRule.Templates.Insert("NamedResources",						NamedResources);
	AllocatedAccordingToRule.Templates.Insert("CalculatedResourcesNamed",			CalculatedResourcesNamed);
	AllocatedAccordingToRule.Templates.Insert("NamedResourceAmounts",				NamedResourceAmounts);
	AllocatedAccordingToRule.Templates.Insert("SelectingNonZeroSourceAmounts",			SelectingNonZeroSourceAmounts);
	AllocatedAccordingToRule.Templates.Insert("NamedResourcePrices",				NamedResourcePrices);
	AllocatedAccordingToRule.Templates.Insert("PricesOfResourceAmountsNamed",			PricesOfResourceAmountsNamed);
	AllocatedAccordingToRule.Templates.Insert("ResourcesToWriteOff",						ResourcesToWriteOff);
	AllocatedAccordingToRule.Templates.Insert("NonzeroSumOfSourceNumberFields",   NonZeroAmountOfDistributedSourceResources);
	
	AllocatedAccordingToRule.Templates.Insert("CalculationOfBasisForWriteOff",					CalculationOfBasisForWriteOff);
	AllocatedAccordingToRule.Templates.Insert("CalculationIsTBLine",						CalculationIsTBLine);
	AllocatedAccordingToRule.Templates.Insert("BasisForDebiting",							BasisForDebiting);
	AllocatedAccordingToRule.Templates.Insert("ZeroSourceBasis",					ZeroSourceBasis);
	AllocatedAccordingToRule.Templates.Insert("ZeroSourceResources",				ZeroSourceResources);
	AllocatedAccordingToRule.Templates.Insert("ReducingSourceBasis",				ReducingSourceBasis);
	AllocatedAccordingToRule.Templates.Insert("ReducingBasisOfBase",					ReducingBasisOfBase);
	AllocatedAccordingToRule.Templates.Insert("ReducingSourceResources",			ReducingSourceResources);
	AllocatedAccordingToRule.Templates.Insert("FilterReducingSourceBasis",			FilterReducingSourceBasis);
	AllocatedAccordingToRule.Templates.Insert("FilterReducingBasisOfBase",				FilterReducingBasisOfBase);
	
	If DistributionParameters.AllocationRules.Count() = 0 Then
		DistributionParameters.Templates.Insert("AllSourceBases", 					  		"");
		DistributionParameters.Templates.Insert("AllSourceResources", 					  		"");
		DistributionParameters.Templates.Insert("SourceBasis", 						  		"");
		DistributionParameters.Templates.Insert("NamedSourceBasis", 			  		"");
		DistributionParameters.Templates.Insert("SourceBasisDistributed",			  		"");
		DistributionParameters.Templates.Insert("BaseBase", 							  		"");
		DistributionParameters.Templates.Insert("NamedBaseBase", 				  		"");
		DistributionParameters.Templates.Insert("SourceBasisPositiveNamed", 		"");
		DistributionParameters.Templates.Insert("SourceBasisOriginalNamed",		"");
		DistributionParameters.Templates.Insert("BasisOfBaseIsPositiveNamed", 	  		"");
		DistributionParameters.Templates.Insert("SourceBasisSign", 					  		"");
		DistributionParameters.Templates.Insert("BaseSign", 						  		"");
		DistributionParameters.Templates.Insert("SourceBaseSignNotNamed", 			"");
		DistributionParameters.Templates.Insert("BaseSignBaseNotNamed", 					"");
		DistributionParameters.Templates.Insert("SelectionIsNonzeroSumOfSourceBases", 	  		"");
		DistributionParameters.Templates.Insert("SelectionIsNonZeroSumOfBasesOfBase", 		  		"");
		DistributionParameters.Templates.Insert("NamedResources", 			  		  		"");
		DistributionParameters.Templates.Insert("CalculatedResourcesNamed", 			  	"");
		DistributionParameters.Templates.Insert("NamedResourceAmounts", 			  		"");
		DistributionParameters.Templates.Insert("SelectingNonZeroSourceAmounts",			  		"");
		DistributionParameters.Templates.Insert("NamedResourcePrices", 			  	  		"");
		DistributionParameters.Templates.Insert("PricesOfResourceAmountsNamed", 			  		"");
		DistributionParameters.Templates.Insert("ZeroSourceBases",				  		"");
		DistributionParameters.Templates.Insert("ZeroSourceResources_",				  		"");
		DistributionParameters.Templates.Insert("SourceBasisWithOriginalSign",		  		"");
		DistributionParameters.Templates.Insert("BasisOfBaseWithOriginalSign",		  				"");
		DistributionParameters.Templates.Insert("SumOfSourceNumericFields",		  		  	"");
		DistributionParameters.Templates.Insert("SumOfBaseBases",		  				  		"");
		DistributionParameters.Templates.Insert("NonZeroSumOfDistributedBaseBases",	   	"");
		
	EndIf;
	
	DistributionParameters.Templates.Insert("AllSourceBases",
		ConnectLines(DistributionParameters.Templates.AllSourceBases, SourceBasisField,,,, ","));
	DistributionParameters.Templates.Insert("AllSourceResources",
		ConnectLines(DistributionParameters.Templates.AllSourceResources, SourceResources,,,, ","));
	DistributionParameters.Templates.Insert("SourceBasis",
		ConnectLines(DistributionParameters.Templates.SourceBasis, SourceBasis,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("NamedSourceBasis",
		ConnectLines(DistributionParameters.Templates.NamedSourceBasis, NamedSourceBasis,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SourceBasisDistributed",
		ConnectLines(DistributionParameters.Templates.SourceBasisDistributed, SourceBasisDistributed,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("BaseBase",
		ConnectLines(DistributionParameters.Templates.BaseBase, BaseBase,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("NamedBaseBase",
		ConnectLines(DistributionParameters.Templates.NamedBaseBase, NamedBaseBase,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SourceBasisPositiveNamed",
		ConnectLines(DistributionParameters.Templates.SourceBasisPositiveNamed, SourceBasisPositiveNamed,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SourceBasisOriginalNamed",
		ConnectLines(DistributionParameters.Templates.SourceBasisOriginalNamed, SourceBasisOriginalNamed,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("BasisOfBaseIsPositiveNamed",
		ConnectLines(DistributionParameters.Templates.BasisOfBaseIsPositiveNamed, BasisOfBaseIsPositiveNamed,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SourceBasisSign",
		ConnectLines(DistributionParameters.Templates.SourceBasisSign, SourceBasisSign,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("BaseSign",
		ConnectLines(DistributionParameters.Templates.BaseSign, BaseSign,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SourceBaseSignNotNamed",
		ConnectLines(DistributionParameters.Templates.SourceBaseSignNotNamed, SourceBaseSignNotNamed,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("BaseSignBaseNotNamed",
		ConnectLines(DistributionParameters.Templates.BaseSignBaseNotNamed, BaseSignBaseNotNamed,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SelectionIsNonzeroSumOfSourceBases",
		ConnectLines(DistributionParameters.Templates.SelectionIsNonzeroSumOfSourceBases, SelectionIsNonzeroSumOfSourceBases,,,, DistributionParameters.Templates.JoiningStringsOr));
	DistributionParameters.Templates.Insert("SelectionIsNonZeroSumOfBasesOfBase",
		ConnectLines(DistributionParameters.Templates.SelectionIsNonZeroSumOfBasesOfBase, SelectionIsNonZeroSumOfBasesOfBase,,,, DistributionParameters.Templates.JoiningStringsOr));
	DistributionParameters.Templates.Insert("NamedResources",
		ConnectLines(DistributionParameters.Templates.NamedResources, NamedResources,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("CalculatedResourcesNamed",
		ConnectLines(DistributionParameters.Templates.CalculatedResourcesNamed, CalculatedResourcesNamed,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("NamedResourceAmounts",
		ConnectLines(DistributionParameters.Templates.NamedResourceAmounts, NamedResourceAmounts,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SelectingNonZeroSourceAmounts",
		ConnectLines(DistributionParameters.Templates.SelectingNonZeroSourceAmounts, SelectingNonZeroSourceAmounts,,,, " OR "));
	DistributionParameters.Templates.Insert("NamedResourcePrices",
		ConnectLines(DistributionParameters.Templates.NamedResourcePrices, NamedResourcePrices,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("PricesOfResourceAmountsNamed",
		ConnectLines(DistributionParameters.Templates.PricesOfResourceAmountsNamed, PricesOfResourceAmountsNamed,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("ZeroSourceBases",
		ConnectLines(DistributionParameters.Templates.ZeroSourceBases, ZeroSourceBasis,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("ZeroSourceResources_",
		ConnectLines(DistributionParameters.Templates.ZeroSourceResources_, ZeroSourceResources,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SourceBasisWithOriginalSign",
		ConnectLines(DistributionParameters.Templates.SourceBasisWithOriginalSign, SourceBasisWithOriginalSign,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("BasisOfBaseWithOriginalSign",
		ConnectLines(DistributionParameters.Templates.BasisOfBaseWithOriginalSign, BasisOfBaseWithOriginalSign,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SumOfSourceNumericFields",
		ConnectLines(DistributionParameters.Templates.SumOfSourceNumericFields, SumOfSourceBases, AmountOfSourceResources,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("SumOfBaseBases",
		ConnectLines(DistributionParameters.Templates.SumOfBaseBases, SumOfBaseBases,,,, DistributionParameters.Templates.FieldSeparator));
	DistributionParameters.Templates.Insert("NonZeroSumOfDistributedBaseBases",
		ConnectLines(DistributionParameters.Templates.NonZeroSumOfDistributedBaseBases, NonZeroSumOfDistributedBaseBases,,,, DistributionParameters.Templates.JoiningStringsOr));
	
	DistributionParameters.AllocationRules.Add(AllocatedAccordingToRule);
	
	For Each CurRule In DistributionParameters.AllocationRules Do
		
		OtherZeroBases = "";
		OtherZeroResources = "";
		
		For Each OtherRules In DistributionParameters.AllocationRules Do
			
			If CurRule = OtherRules Then
				Continue;
			EndIf;
			
			SupplementString(OtherZeroBases, OtherRules.Templates.ZeroSourceBasis,,,, DistributionParameters.Templates.FieldSeparator);
			SupplementString(OtherZeroResources, OtherRules.Templates.ZeroSourceResources,,,, DistributionParameters.Templates.FieldSeparator);
			
		EndDo;
		
		CurRule.Templates.Insert("OtherZeroBases",  OtherZeroBases);
		CurRule.Templates.Insert("OtherZeroResources", OtherZeroResources);
		
	EndDo;
	
EndProcedure

// Initializes the description of other table fields to include in the distribution result.
// Optional.
// Other source/database fields that are present in the link fields will be excluded from the list of other fields.
//
// Parameters:
//	DistributionParameters - See CostCalculationUniversalAlgorithms.InitializeDistributionParametersUsingReducedRemainderMethod
//	OtherSourceFields - String - list of other fields in the source table (separated by commas);
//		these fields will be used for ordering data in the source table before distribution.
//	OtherDatabaseFields - String - list of other fields in the database table (separated by commas);
//		these fields will be used for ordering data in the database table before distribution.
//	DonTIncludeSourceFields - String - a comma-separated list of fields in the source table that are required for data ordering, but are not needed as a result of distribution.
//	DoNotIncludeDatabaseFields - String - a comma-separated list of fields in the database table that are necessary for ordering data, but are not needed as a result of distribution.
//	DatabaseSortingFields - String - the list of fields (separated by commas) of the database table, by which the database will be sorted to set the order of debiting from the database.
//
Procedure InitializeOtherDistributionFieldsUsingReducedRemainderMethod(DistributionParameters,
			OtherSourceFields = "", OtherDatabaseFields = "", DonTIncludeSourceFields = "", DoNotIncludeDatabaseFields = "", DatabaseSortingFields = "") Export
	
	DistributionParameters.Insert("DatabaseSortingFields",	DatabaseSortingFields);
	
	// Query Field Templates
	SourceFields = "";
	DatabaseFields = "";
	NamedSourceFields = "";
	SourceFieldsNotNamed = "";
	StructureOfCommunicationField = New Structure(DistributionParameters.LinkFields);
	
	ExcludedFields = New Structure(DonTIncludeSourceFields);
	
	For Each FieldName In StringFunctionsClientServer.SplitStringIntoSubstringsArray(OtherSourceFields, ",", True, True) Do
		
		If ExcludedFields.Property(FieldName) Or StructureOfCommunicationField.Property(FieldName) Then
			Continue;
		EndIf;
		
		SupplementString(SourceFields, FieldName);
		SupplementString(NamedSourceFields,   "%1." + FieldName + " AS " + FieldName,,,, DistributionParameters.Templates.FieldSeparator);
		SupplementString(SourceFieldsNotNamed, "%1." + FieldName ,,,, DistributionParameters.Templates.FieldSeparator);
		
		DistributionParameters.RulesForFillingInOtherFields.Insert(FieldName, 1);
		
	EndDo;
	
	DistributionParameters.Templates.Insert("NamedSourceFields",   NamedSourceFields);
	DistributionParameters.Templates.Insert("SourceFieldsNotNamed", SourceFieldsNotNamed);
	
	NamedDatabaseFields = "";
	DatabaseFieldsNotNamed = "";
	DatabaseFields_ = "";
	
	ExcludedFields = New Structure(DoNotIncludeDatabaseFields);
	FieldStructure   = New Structure(ConnectLines(OtherDatabaseFields, DatabaseSortingFields));
	
	For Each KeyAndValue In FieldStructure Do
		
		FieldName = KeyAndValue.Key;
		
		If ExcludedFields.Property(FieldName) Or StructureOfCommunicationField.Property(FieldName) Then
			Continue;
		EndIf;
		
		SupplementString(DatabaseFields, FieldName);
		SupplementString(NamedDatabaseFields,   "%1." + FieldName + " AS " + FieldName,,,, DistributionParameters.Templates.FieldSeparator);
		SupplementString(DatabaseFieldsNotNamed, "%1." + FieldName ,,,, DistributionParameters.Templates.FieldSeparator);
		
		If Not DistributionParameters.RulesForFillingInOtherFields.Property(FieldName) Then
			
			// There is no field with this name in the source - let's take it from the database.
			DistributionParameters.RulesForFillingInOtherFields.Insert(FieldName, 2);
			
			SupplementString(DatabaseFields_, "&EmptyBaseValue_" + FieldName + " AS " + FieldName,,,, DistributionParameters.Templates.FieldSeparator);
			
		Else
			
			// We will take the fields that are in the source and in the database with the priority of the database.
			DistributionParameters.RulesForFillingInOtherFields.Insert(FieldName, 4);
			
		EndIf;
		
	EndDo;
	
	DistributionParameters.Templates.Insert("NamedDatabaseFields",   NamedDatabaseFields);
	DistributionParameters.Templates.Insert("DatabaseFieldsNotNamed", DatabaseFieldsNotNamed);
	DistributionParameters.Templates.Insert("DatabaseFields_", 	 DatabaseFields_);
	
	DistributionParameters.Insert("OtherSourceFields", 			 SourceFields);
	DistributionParameters.Insert("DonTIncludeSourceFields", 		 DonTIncludeSourceFields);
	DistributionParameters.Insert("DoNotIncludeDatabaseFields", 			 DoNotIncludeDatabaseFields);
	DistributionParameters.Insert("OtherDatabaseFields", 				 DatabaseFields);
	
	InitializeRulesForFillingInOtherDistributionFieldsUsingReducedRemainderMethod(DistributionParameters);
	
EndProcedure

// Initializes rules for filling in other table fields as a result of distribution.
// Optional.
//
// Parameters:
//	DistributionParameters - Structure - the result of the function initializationparameters of the distribution of the method of decreasing the limit()
//	FieldsToFillInFromSource - String - list of other fields in the source table (separated by commas) that should be unconditionally transferred to the distribution result.
//		you must specify only the fields that are present in both the source table and the database table.
//	FieldsToFillInFromDatabase - String - the list of other fields in the database table (separated by commas)that must be transferred to the distribution result.
//		you must specify only the fields that are present in both the source table and the database table.
//	FieldsWithSourcePriority - String - a comma-separated list of other fields in the source table that should be moved to the distribution result
//		if the field value in the source is filled in. if the field value in the source is not filled in, the field value from the database will be moved to the result.
//		you must specify only the fields that are present in both the source table and the database table.
//	FieldsWithBasePriority - String - list of other fields in the database table (separated by commas) that should be transferred to the distribution result
//		if the field value in the database is filled in.if the field value in the database is not filled in, the field value from the source will be transferred to the result.
//		you must specify only the fields that are present in both the source table and the database table.
//
Procedure InitializeRulesForFillingInOtherDistributionFieldsUsingReducedRemainderMethod(DistributionParameters,
			FieldsToFillInFromSource = "", FieldsToFillInFromDatabase = "",
			FieldsWithSourcePriority = "", FieldsWithBasePriority = "") Export
	
	For Each KeyAndValue In New Structure(FieldsToFillInFromSource) Do
		DistributionParameters.RulesForFillingInOtherFields.Insert(KeyAndValue.Key, 1);
	EndDo;
	
	For Each KeyAndValue In New Structure(FieldsToFillInFromDatabase) Do
		DistributionParameters.RulesForFillingInOtherFields.Insert(KeyAndValue.Key, 2);
	EndDo;
	
	For Each KeyAndValue In New Structure(FieldsWithSourcePriority) Do
		DistributionParameters.RulesForFillingInOtherFields.Insert(KeyAndValue.Key, 3);
	EndDo;
	
	For Each KeyAndValue In New Structure(FieldsWithBasePriority) Do
		DistributionParameters.RulesForFillingInOtherFields.Insert(KeyAndValue.Key, 4);
	EndDo;
	
	// Query Field Templates
	FieldSelectionRules = "";

	For Each KeyAndValue In DistributionParameters.RulesForFillingInOtherFields Do
		
		OtherField = "";
		
		If KeyAndValue.Value = 1 Then
			OtherField = "%3." + KeyAndValue.Key + " AS " + KeyAndValue.Key;
		ElsIf KeyAndValue.Value = 2 Then
			OtherField = "%2." + KeyAndValue.Key + " AS " + KeyAndValue.Key;
		ElsIf KeyAndValue.Value = 3 Then
			OtherField = "CASE WHEN %3." + KeyAndValue.Key + " = &EmptySourceValue_" + KeyAndValue.Key + "
				|		THEN %2." + KeyAndValue.Key + " ELSE %3." + KeyAndValue.Key + "
				|	END AS " + KeyAndValue.Key;
		Else
			OtherField = "CASE WHEN %2." + KeyAndValue.Key + " = &EmptyBaseValue_" + KeyAndValue.Key + "
				|		THEN %3." + KeyAndValue.Key + " ELSE %2." + KeyAndValue.Key + "
				|	END AS " + KeyAndValue.Key;
		EndIf;
		
		SupplementString(FieldSelectionRules, OtherField,,,, DistributionParameters.Templates.FieldSeparator);
		
	EndDo;
	
	DistributionParameters.Templates.Insert("FieldSelectionRules", FieldSelectionRules);
	
EndProcedure

#EndRegion

#Region RunningDistribution

// Distributes data from temporary tables using the reduced remainder method.
// The result will be formed following temporary tables:
//	Tresulttype - the result of the distribution;
//		contains the fields of the link Field + (all resources of the Source + Source base field) + (other source Field without not including the source Field)
//		also contains the service fields "Keyti" and " Keytb"
//	VT-distributed source data - data from the source table Name for which there was not enough data in the distribution database;
//		contains the same fields as in the distribution Result, with the exception of service fields;
//		also contains a utility field Estimate of type Boolean:
//			- if true, then there was a database for this source record, but the number in the base field of the database table was not enough to fully distribute the data of the source table;
//				numeric fields contain Unallocated balances; other fields are filled in from the source table.
//			- if equal to False, then there was no distribution base for this source record;
//				numeric fields contain the original values from the source table; other fields are filled in from the source table.
//	Vtneraspredelennyedannyebases - data from the table name of the distribution Database, for which there was not enough data in the source.
//		contains fields Possesi + (all Polemoniales) + (Procapitales without Newlocations)
// You can redefine the names of the result tables in the initializationdistribution result Tables () procedure.
//
// Also, a distribution Result key with the structure type will be added to the distribution Parameters. the Following data will be added (Key - Value):
//	number of Iterations - total number of iterations of the distribution
//	Calculation timestamp - total calculation time in seconds
//	source Size - number of records in the table source TableName
//	Razormaze - the number of records in the table of Metalcyberspace
//	Resumeresultset - the number of records in the table of Tresulttype
//	The size of the undistributed recordsource is the number of records in the table of the undistributed data Source
//	Size of the VT - allocated recordsbase-the number of entries in the VT-allocated Datebase table
//
// Parameters:
//	CalculationParameters - Structure - calculation parameters containing a temporary table Manager containing the source table Name and distribution table Name tables.
//	DistributionParameters - See CostCalculationUniversalAlgorithms.InitializeDistributionParametersUsingReducedRemainderMethod
//
Procedure DistributeUsingReducedRemainderMethod(CalculationParameters, DistributionParameters) Export
	
	TempTablesManager = CostCalculationAppliedAlgorithms.GetTTManagerFromContainer(CalculationParameters);
	
	#Region AuxiliaryData
	
	// We will prepare auxiliary data
	BeginTime = CurrentUniversalDateInMilliseconds();
	
	DistributionParameters.Insert("DistributionResults", New Structure);
	
	ParametersOfUniversalMechanisms = InitializeParametersForUsingUniversalMechanisms(TempTablesManager);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(
		TempTablesManager,
		ConnectLines(
			DistributionParameters.NameOfResultTable,
			DistributionParameters.NameOfUnallocatedSourceDataTable,
			DistributionParameters.NameOfDatabaseSUnallocatedDataTable)); // results of the previous distribution
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	SourceFieldsForOrdering = "";
	DatabaseFieldsForOrdering = "";
	
	// We get the types of empty values of all other fields of the source and database
	// We will put the values of these types in the query parameters in order to use them to determine the filling of fields when selecting field values according to the rules
	If ValueIsFilled(DistributionParameters.Templates.NamedSourceFields) Then
		
		Query.Text =
		"SELECT TOP 0
		|	T.NamedSourceFields
		|FROM
		|	&SourceTableName AS T";
		
		Query.Text = StrReplace(Query.Text, "T.NamedSourceFields", DistributionParameters.Templates.NamedSourceFields);
		Query.Text = StrReplace(Query.Text, "&SourceTableName", DistributionParameters.SourceTableName);
		
		Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, "T");
		
		Columns = Query.Execute().Unload().Columns;
		
		For Each CurrentColumn In Columns Do
			
			ColumnValueType = NonNullTypeDescriptions(CurrentColumn.ValueType);
			
			Query.SetParameter(
				"EmptySourceValue_" + CurrentColumn.Name,
				ColumnValueType.AdjustValue(Undefined));
			
			SupplementString(
				SourceFieldsForOrdering,
				CurrentColumn.Name + ?(ThisIsDescriptionOfDocumentTypes(ColumnValueType), ".PointInTime", ""));
			
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(DistributionParameters.Templates.NamedDatabaseFields) Then
		
		Query.Text =
		"SELECT TOP 0
		|	T.NamedDatabaseFields
		|FROM
		|	&NameOfDatabaseTable AS T";
		
		Query.Text = StrReplace(Query.Text, "T.NamedDatabaseFields", DistributionParameters.Templates.NamedDatabaseFields);
		Query.Text = StrReplace(Query.Text, "&NameOfDatabaseTable", DistributionParameters.NameOfDatabaseTable);
		
		Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, "T");
		
		Columns = Query.Execute().Unload().Columns;
		StructureOfSortingField = New Structure(DistributionParameters.DatabaseSortingFields);
		
		For Each CurrentColumn In Columns Do
			
			ColumnValueType = NonNullTypeDescriptions(CurrentColumn.ValueType);
			
			Query.SetParameter(
				"EmptyBaseValue_" + CurrentColumn.Name,
				ColumnValueType.AdjustValue(Undefined));
			
			If Not StructureOfSortingField.Property(CurrentColumn.Name) Then
				SupplementString(
					DatabaseFieldsForOrdering,
					CurrentColumn.Name + ?(ThisIsDescriptionOfDocumentTypes(ColumnValueType), ".PointInTime", ""));
			EndIf;
			
		EndDo;
		
	EndIf;
	
	#EndRegion 
	
	#Region DataPreparation
	
	// 1.1
	Query.Text =
	"SELECT DISTINCT
	|	T.LinkFields
	|INTO TTAllCommunicationFields
	|FROM
	|	(SELECT DISTINCT
	|		T.LinkFields
	|	FROM
	|		&SourceTableName AS T
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		T.LinkFields
	|	FROM
	|		&NameOfDatabaseTable AS T) AS T";
	
	Query.Text = StrReplace(Query.Text, "&SourceTableName", 		  DistributionParameters.SourceTableName);
	Query.Text = StrReplace(Query.Text, "&NameOfDatabaseTable", DistributionParameters.NameOfDatabaseTable);
	Query.Text = StrReplace(Query.Text, "T.LinkFields",
		StringFunctionsClientServer.SubstituteParametersToString(DistributionParameters.Templates.NamedCommunicationFields, "T"));
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"",
		"",
		DistributionParameters.LinkFields, // Ordering
		"ConnectionKey"); // Line number
		
	CostCalculationAppliedAlgorithms.FillInTemporaryTableRowNumbers(
		ParametersOfUniversalMechanisms,
		NumberingParameters,
		"TTAllCommunicationFields",
		"TTCommunicationFieldKeys");
	
	// 1.2
	Query.Text =
	"SELECT
	|	Keys.ConnectionKey AS ConnectionKey,
	|	&AllSourceFields
	|INTO TTOriginalTiWithoutNumbering
	|FROM
	|	SourceTableName AS T
	|	LEFT JOIN TTCommunicationFieldKeys AS Keys
	|	ON &ConnectionFieldsJoin
	|GROUP BY
	|	Keys.ConnectionKey,
	|	T.GroupFields
	|	,&SelectingNonZeroSourceAmounts";
	
	NumericFields = ConnectLines(
		?(DistributionParameters.NegativeBasesArePossible,
			DistributionParameters.Templates.SourceBasisOriginalNamed,
			DistributionParameters.Templates.SourceBasisPositiveNamed),
		DistributionParameters.Templates.SourceBasisSign,
		DistributionParameters.Templates.NamedResourceAmounts,
		DistributionParameters.Templates.PricesOfResourceAmountsNamed,,
		DistributionParameters.Templates.FieldSeparator);
	
	AllFields = ConnectLines(
		DistributionParameters.Templates.NamedCommunicationFields,
		DistributionParameters.Templates.NamedSourceFields,
		NumericFields,,,
		DistributionParameters.Templates.FieldSeparator);
		
	GroupFields = ConnectLines(
		DistributionParameters.Templates.LinkFieldsNotNamed,
		DistributionParameters.Templates.SourceFieldsNotNamed,
		DistributionParameters.Templates.SourceBaseSignNotNamed,,,
		DistributionParameters.Templates.FieldSeparator);
	
	Query.Text = StrReplace(Query.Text, "SourceTableName", 				  DistributionParameters.SourceTableName);
	Query.Text = StrReplace(Query.Text, "&AllSourceFields",    				  AllFields);
	Query.Text = StrReplace(Query.Text, "&ConnectionFieldsJoin", 				  DistributionParameters.Templates.ConnectionFieldsJoin);
	Query.Text = StrReplace(Query.Text, "T.GroupFields", 	  				  GroupFields);
	Query.Text = StrReplace(Query.Text, ",&SelectingNonZeroSourceAmounts",
		"HAVING" + Chars.LF + DistributionParameters.Templates.SelectionIsNonzeroSumOfSourceBases
		+ ?(DistributionParameters.Templates.SelectingNonZeroSourceAmounts = "", "",  "
			|	AND (" + DistributionParameters.Templates.SelectingNonZeroSourceAmounts + ")"));
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, "T", "Keys");
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"",
		"",
		ConnectLines(DistributionParameters.LinkFields, SourceFieldsForOrdering), // Ordering
		"KeyTI", // number column
		"KeyTI"); // IndexOf
		
	CostCalculationAppliedAlgorithms.FillInTemporaryTableRowNumbers(
		ParametersOfUniversalMechanisms,
		NumberingParameters,
		"TTOriginalTiWithoutNumbering",
		"TTInitialTi");
	
	// 1.3
	Query.Text =
	"SELECT
	|	Keys.ConnectionKey AS ConnectionKey,
	|	&AllDatabaseFields
	|INTO TTOriginalTBWithoutNumbering
	|FROM
	|	NameOfDatabaseTable AS T
	|	LEFT JOIN TTCommunicationFieldKeys AS Keys
	|	ON &ConnectionFieldsJoin
	|GROUP BY
	|	Keys.ConnectionKey,
	|	T.GroupFields
	|	,&SelectionIsNonZeroSumOfBasesOfBase";
	
	AllFields = ConnectLines(
		DistributionParameters.Templates.NamedCommunicationFields,
		DistributionParameters.Templates.NamedDatabaseFields,
		DistributionParameters.Templates.BasisOfBaseIsPositiveNamed,
		DistributionParameters.Templates.BaseSign,,
		DistributionParameters.Templates.FieldSeparator);
	
	GroupFields = ConnectLines(
		DistributionParameters.Templates.LinkFieldsNotNamed,
		DistributionParameters.Templates.DatabaseFieldsNotNamed,
		DistributionParameters.Templates.BaseSignBaseNotNamed,,,
		DistributionParameters.Templates.FieldSeparator);
	
	Query.Text = StrReplace(Query.Text, "NameOfDatabaseTable", 	 DistributionParameters.NameOfDatabaseTable);
	Query.Text = StrReplace(Query.Text, "&AllDatabaseFields",    				 AllFields);
	Query.Text = StrReplace(Query.Text, "&ConnectionFieldsJoin", 			 DistributionParameters.Templates.ConnectionFieldsJoin);
	Query.Text = StrReplace(Query.Text, "T.GroupFields", 	  			 GroupFields);
	Query.Text = StrReplace(Query.Text, ",&SelectionIsNonZeroSumOfBasesOfBase",
		"HAVING" + Chars.LF + DistributionParameters.Templates.SelectionIsNonZeroSumOfBasesOfBase);
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, "T", "Keys");
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"",
		"",
		ConnectLines(DistributionParameters.LinkFields, DistributionParameters.DatabaseSortingFields, DatabaseFieldsForOrdering), // Ordering
		"TBKey", // number column
		"TBKey"); // IndexOf
		
	CostCalculationAppliedAlgorithms.FillInTemporaryTableRowNumbers(
		ParametersOfUniversalMechanisms,
		NumberingParameters,
		"TTOriginalTBWithoutNumbering",
		"TTOriginalTB");
		
	// We will destroy unnecessary watts
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(TempTablesManager,
		"TTAllCommunicationFields, TTOriginalTiWithoutNumbering, TTOriginalTBWithoutNumbering");
	
	#EndRegion
	
	#Region Distribution_Bases
	
	NamesOfResultTables = "";
	RuleNumber = 0;
	ArrangeByKey = ValueIsFilled(DistributionParameters.DatabaseSortingFields);
	
	For Each AllocatedAccordingToRule In DistributionParameters.AllocationRules Do // by distribution bases
		
		RuleNumber = RuleNumber + 1;
		
		DataDetails = New Structure;
		DataDetails.Insert("NameTT", "TTInitialTi");
		DataDetails.Insert("TTResultName", "TTBasesWithCumulativeTotal");
		DataDetails.Insert("RecordKeyField", "KeyTI");
		DataDetails.Insert("BasisField", AllocatedAccordingToRule.SourceBasisField);
		
		CalculateTableFieldByCumulativeTotal(
			CalculationParameters,
			Query,
			DataDetails,
			DistributionParameters.NegativeBasesArePossible);
			
		DataDetails = New Structure;
		DataDetails.Insert("NameTT", "TTOriginalTB");
		DataDetails.Insert("TTResultName", "TTBasesBasesCumulatively");
		DataDetails.Insert("RecordKeyField", "TBKey");
		DataDetails.Insert("BasisField", AllocatedAccordingToRule.BASEBASEField);
		
		CalculateTableFieldByCumulativeTotal(
			CalculationParameters,
			Query,
			DataDetails,
			DistributionParameters.NegativeBasesArePossible,
			ArrangeByKey);
			
		CostCalculationProtocol.StartCreatingTemporaryTable(CalculationParameters, "TTDistributionByBasis");
		
		Query.Text =
		"SELECT
		|	T.ConnectionKey AS ConnectionKey,
		|	MAX(T.KeyTI) AS KeyTI,
		|	MAX(T.TBKey) AS TBKey,
		|	T.Basis_Total AS Basis_Total
		|FROM
		|	(SELECT
		|		T.ConnectionKey AS ConnectionKey,
		|		T.KeyTI AS KeyTI,
		|		-1 AS TBKey,
		|		T.Basis_Total
		|	FROM
		|		TTBasesWithCumulativeTotal AS T
		|
		|	UNION ALL
		|
		|	SELECT
		|		T.ConnectionKey AS ConnectionKey,
		|		-1 AS KeyTI,
		|		T.TBKey AS TBKey,
		|		T.Basis_Total
		|	FROM
		|		TTBasesBasesCumulatively AS T) AS T
		|GROUP BY
		|	T.ConnectionKey,
		|	T.Basis_Total
		|ORDER BY
		|	ConnectionKey,
		|	Basis_Total DESC";
			
		TableOfBases = Query.Execute().Unload();
		
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(TempTablesManager,
			"TTBasesWithCumulativeTotal, TTBasesBasesCumulatively");
		
		ConnectionKey = Undefined;
		KeyTI = -1;
		TBKey = -1;
		
		For Each CurrentRow In TableOfBases Do
			
			If ConnectionKey <> CurrentRow.ConnectionKey Then
				
				ConnectionKey = CurrentRow.ConnectionKey;
				KeyTI = CurrentRow.KeyTI;
				TBKey = CurrentRow.TBKey;

			Else
				
				If CurrentRow.KeyTI = -1 Then
					CurrentRow.KeyTI = KeyTI;
				Else
					KeyTI = CurrentRow.KeyTI;
				EndIf;
				
				If CurrentRow.TBKey = -1 Then
					CurrentRow.TBKey = TBKey;
				Else
					TBKey = CurrentRow.TBKey;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		TableOfBases.Sort("ConnectionKey, Basis_Total");
		
		TableOfBases.Columns.Add("Basis_Distributed", TableOfBases.Columns.Basis_Total.ValueType);
		
		ConnectionKey = Undefined;
		Basis_Total = 0;
		
		For Each CurrentRow In TableOfBases Do
			
			If ConnectionKey <> CurrentRow.ConnectionKey Then
				ConnectionKey = CurrentRow.ConnectionKey;
				CurrentRow.Basis_Distributed = CurrentRow.Basis_Total;
			Else
				CurrentRow.Basis_Distributed = CurrentRow.Basis_Total - Basis_Total;
			EndIf;
			
			Basis_Total = CurrentRow.Basis_Total; // the total of the previous row for the distribution of the next row
			
		EndDo;
		
		Query.SetParameter("TableOfBases", TableOfBases);
		
		Query.Text =
		"SELECT
		|	T.ConnectionKey,
		|	T.KeyTI,
		|	T.TBKey,
		|	T.Basis_Total,
		|	T.Basis_Distributed
		|INTO TTDistributionByBasis
		|FROM
		|	&TableOfBases AS T
		|INDEX BY
		|	KeyTI";
			
		Query.Execute();
		
		Query.Parameters.Delete("TableOfBases");
		TableOfBases = Undefined;
		
		CostCalculationProtocol.EndFormationOfTemporaryTable(CalculationParameters);
		
		If AllocatedAccordingToRule.SourceResources = "" Then
			
			Query.Text =
			"SELECT
			|	T.KeyTI,
			|	T.TBKey,
			|	&SourceBasisDistributed
			|INTO TTWriteOffResultsInterim
			|FROM
			|	TTDistributionByBasis AS T
			|GROUP BY
			|	T.KeyTI,
			|	T.TBKey
			|INDEX BY
			|	T.KeyTI
			|";
			
		Else
			
			Query.Text =
			"SELECT
			|	T.ConnectionKey,
			|	T.KeyTI,
			|	T.TBKey,
			|	T.Basis_Distributed,
			|	T.CalculatedResourcesNamed
			|INTO TTWriteOffResultsPreliminary
			|FROM
			|	TTDistributionByBasis AS T
			|	LEFT JOIN TTInitialTi AS Sources
			|		ON T.KeyTI = Sources.KeyTI
			|INDEX BY
			|	T.KeyTI
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	T.KeyTI,
			|	&NamedResourceAmounts
			|INTO TTDistributionDeviation
			|FROM
			|	(SELECT
			|		T.KeyTI,
			|		&ResourcesNamedNegative
			|	FROM
			|		TTWriteOffResultsPreliminary AS T
			|	WHERE
			|		T.KeyTI <> -1
			|
			|	UNION ALL
			|
			|	SELECT
			|		T.KeyTI,
			|		&NamedResources
			|	FROM
			|		TTInitialTi AS T) AS T
			|GROUP BY
			|	T.KeyTI
			|	,&NonzeroSumOfSourceNumberFields
			|INDEX BY
			|	T.KeyTI
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	T.KeyTI,
			|	MAX(T.Basis_Distributed) AS Basis_Distributed
			|INTO TTWriteOffOfQuantityDeviations
			|FROM
			|	TTWriteOffResultsPreliminary AS T
			|	INNER JOIN TTDistributionDeviation AS Variances
			|		ON T.KeyTI = Variances.KeyTI
			|GROUP BY
			|	T.KeyTI
			|INDEX BY
			|	T.KeyTI
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	T.KeyTI,
			|	MIN(T.TBKey) AS TBKey
			|INTO TTWriteOffDeviationsInTB
			|FROM
			|	TTWriteOffResultsPreliminary AS T
			|	INNER JOIN TTWriteOffOfQuantityDeviations AS Variances
			|		ON T.KeyTI = Variances.KeyTI
			|		AND T.Basis_Distributed = Variances.Basis_Distributed
			|GROUP BY
			|	T.KeyTI
			|INDEX BY
			|	T.KeyTI
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	T.KeyTI,
			|	T.TBKey,
			|	&SourceBasisDistributed,
			|	&NamedResourceAmounts
			|INTO TTWriteOffResultsInterim
			|FROM
			|	(SELECT
			|		T.KeyTI,
			|		T.TBKey,
			|		T.Basis_Distributed,
			|		&NamedResources
			|	FROM
			|		TTWriteOffResultsPreliminary AS T
			|
			|	UNION ALL
			|
			|	SELECT
			|		T.KeyTI,
			|		Variances.TBKey,
			|		0,
			|		&NamedResources
			|	FROM
			|		TTDistributionDeviation AS T
			|		INNER JOIN TTWriteOffDeviationsInTB AS Variances
			|			ON T.KeyTI = Variances.KeyTI
			|	) AS T
			|GROUP BY
			|	T.KeyTI,
			|	T.TBKey
			|INDEX BY
			|	T.KeyTI
			|";
			
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "T.CalculatedResourcesNamed", AllocatedAccordingToRule.Templates.CalculatedResourcesNamed);
		Query.Text = StrReplace(Query.Text, "&NamedResourceAmounts",
			ConnectLines(AllocatedAccordingToRule.Templates.NamedResourceAmounts,
				AllocatedAccordingToRule.Templates.OtherZeroBases,
				AllocatedAccordingToRule.Templates.OtherZeroResources));
		Query.Text = StrReplace(Query.Text, ",&NonzeroSumOfSourceNumberFields",
			"HAVING" + Chars.LF + AllocatedAccordingToRule.Templates.NonzeroSumOfSourceNumberFields);
		Query.Text = StrReplace(Query.Text, "&SourceBasisDistributed", AllocatedAccordingToRule.Templates.SourceBasisDistributed);
		Query.Text = StrReplace(Query.Text, "&ResourcesNamedNegative",
			StringFunctionsClientServer.SubstituteParametersToString(AllocatedAccordingToRule.Templates.NamedResources, "-T"));
		Query.Text = StrReplace(Query.Text, "&NamedResources", AllocatedAccordingToRule.Templates.NamedResources);
				
		Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, "T", "Sources");
		
		NameOfResultTable = "TTWriteOffResults" + ?(DistributionParameters.AllocationRules.Count() = 1, "", NumberPerLineWithoutSpaces(RuleNumber));
		Query.Text = StrReplace(Query.Text, "TTWriteOffResultsInterim", NameOfResultTable);
		SupplementString(NamesOfResultTables, NameOfResultTable);
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(TempTablesManager,
			"TTDistributionByBasis, TTDistributionDeviation, TTWriteOffResultsPreliminary,
			|TTDistributionDeviation, TTWriteOffOfQuantityDeviations, TTWriteOffDeviationsInTB");
		
	EndDo; // distribution bases
	
	#EndRegion
	
	#Region DistributionResults
	
	// 3.1
	If Not IsBlankString(NamesOfResultTables) Then
		
		If StrFind(NamesOfResultTables, ",") > 0 Then
			
			CostCalculationAppliedAlgorithms.MergeTemporaryTables(
				TempTablesManager,
				NamesOfResultTables,
				"TTWriteOffResults",
				ConnectLines("KeyTI, TBKey", DistributionParameters.Templates.AllSourceBases, DistributionParameters.Templates.AllSourceResources),
				ConnectLines(DistributionParameters.Templates.AllSourceBases, DistributionParameters.Templates.AllSourceResources),
				"KeyTI",
				True);
				
		EndIf;
			
		Query.Text = "";
		
	Else
		
		Query.Text =
		"SELECT TOP 0
		|	0 AS KeyTI,
		|	0 AS TBKey,
		|	&FieldsTTWriteOffResult
		|INTO TTWriteOffResults";
		
		Query.Text = StrReplace(Query.Text, "&FieldsTTWriteOffResult",
			ConnectLines(DistributionParameters.Templates.ZeroSourceBases, DistributionParameters.Templates.ZeroSourceResources_,,,, DistributionParameters.Templates.FieldSeparator));
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
	EndIf;
	
	// 3.2
	Query.Text =
	"SELECT
	|	T.KeyTI,
	|	T.TBKey,
	|	&FieldsTTWriteOffResult
	|INTO NameOfResultTable
	|FROM
	|	TTWriteOffResults AS T
	|		INNER JOIN TTInitialTi AS TILines
	|		ON T.KeyTI = TILines.KeyTI
	|		INNER JOIN TTOriginalTB AS TBRows
	|		ON T.TBKey = TBRows.TBKey
	|";
	
	Query.Text = StrReplace(Query.Text, "NameOfResultTable", DistributionParameters.NameOfResultTable);
	Query.Text = StrReplace(Query.Text, "&FieldsTTWriteOffResult",
		ConnectLines(StringFunctionsClientServer.SubstituteParametersToString(DistributionParameters.Templates.NamedCommunicationFields, "TILines"),
			DistributionParameters.Templates.FieldSelectionRules,
			DistributionParameters.Templates.NamedSourceBasis,
			DistributionParameters.Templates.NamedResources,,
			DistributionParameters.Templates.FieldSeparator));
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, "T", "TBRows", "TILines");
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	// 3.3
	Query.Text = "";
	
	If ValueIsFilled(DistributionParameters.NameOfUnallocatedSourceDataTable) Then
		
		Query.Text = Query.Text +
		"SELECT
		|	&SourceFieldsAreNonNumeric,
		|	&SourceRemainderFieldsAreNumeric
		|INTO NameOfUnallocatedSourceDataTable
		|FROM
		|	TTInitialTi AS T
		|	INNER JOIN TTWriteOffResults AS Balance
		|		ON T.KeyTI = Balance.KeyTI
		|		AND Balance.TBKey = -1
		|";
		
	EndIf;
	
	If ValueIsFilled(DistributionParameters.NameOfDatabaseSUnallocatedDataTable) Then
		
		If ValueIsFilled(Query.Text) Then
			Query.Text = Query.Text + "
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
		EndIf;
		
		Query.Text = Query.Text +
		"SELECT
		|	&BaseFieldsAreNonNumeric,
		|	&BasisOfBaseWithOriginalSign
		|INTO NameOfDatabaseSUnallocatedDataTable
		|FROM
		|	TTOriginalTB AS T
		|	INNER JOIN TTWriteOffResults AS Balance
		|		ON Balance.KeyTI = -1
		|		AND T.TBKey = Balance.TBKey
		|";
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		
		Query.Text = StrReplace(Query.Text, "NameOfUnallocatedSourceDataTable", DistributionParameters.NameOfUnallocatedSourceDataTable);
		Query.Text = StrReplace(Query.Text, "NameOfDatabaseSUnallocatedDataTable", DistributionParameters.NameOfDatabaseSUnallocatedDataTable);
		Query.Text = StrReplace(Query.Text, "&SourceFieldsAreNonNumeric",
			ConnectLines(DistributionParameters.Templates.NamedCommunicationFields, DistributionParameters.Templates.NamedSourceFields, DistributionParameters.Templates.DatabaseFields_,,, DistributionParameters.Templates.FieldSeparator));
		Query.Text = StrReplace(Query.Text, "&SourceRemainderFieldsAreNumeric",
			ConnectLines(
				StringFunctionsClientServer.SubstituteParametersToString(DistributionParameters.Templates.SourceBasisWithOriginalSign, "Balance", "", "T"),
				StringFunctionsClientServer.SubstituteParametersToString(DistributionParameters.Templates.NamedResources, "Balance")
				,,,,
				DistributionParameters.Templates.FieldSeparator));
		Query.Text = StrReplace(Query.Text, "&BasisOfBaseWithOriginalSign",
			StringFunctionsClientServer.SubstituteParametersToString(DistributionParameters.Templates.BasisOfBaseWithOriginalSign, "Balance", "T"));
		Query.Text = StrReplace(Query.Text, "&BaseFieldsAreNonNumeric",
			ConnectLines(DistributionParameters.Templates.NamedCommunicationFields, DistributionParameters.Templates.NamedDatabaseFields,,,, DistributionParameters.Templates.FieldSeparator));
		
		Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, "T", "TBRows", "TILines");
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(TempTablesManager, "TTRemainsOfSourceNumberFields");
		
	EndIf;
	
	// 3.4
	// We will destroy unnecessary watts
	TablesNames = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
		TempTablesManager,
		ConnectLines(
			ExistingTT,
			DistributionParameters.NameOfResultTable,
			DistributionParameters.NameOfUnallocatedSourceDataTable,
			DistributionParameters.NameOfDatabaseSUnallocatedDataTable)); // results of the previous distribution
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(TempTablesManager, TablesNames);
	
	// Fill in the reference indicators of the distribution result.
	DistributionParameters.DistributionResults.Insert("CalculationTime",
		(CurrentUniversalDateInMilliseconds() - BeginTime) / 1000);
	DistributionParameters.DistributionResults.Insert("SourceSize",
		CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, DistributionParameters.SourceTableName));
	DistributionParameters.DistributionResults.Insert("BaseSize_",
		CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, DistributionParameters.NameOfDatabaseTable));
	DistributionParameters.DistributionResults.Insert("ResultSize",
		CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, DistributionParameters.NameOfResultTable));
	
	If ValueIsFilled(DistributionParameters.NameOfUnallocatedSourceDataTable) Then
		DistributionParameters.DistributionResults.Insert("SizeOfUnallocatedSourceRecords",
			CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, DistributionParameters.NameOfUnallocatedSourceDataTable));
	EndIf;
		
	If ValueIsFilled(DistributionParameters.NameOfDatabaseSUnallocatedDataTable) Then
		DistributionParameters.DistributionResults.Insert("SizeOfUnallocatedDatabaseRecords",
			CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, DistributionParameters.NameOfDatabaseSUnallocatedDataTable));
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#EndRegion


#Region StringFunctions

Function ConnectLines(String1 = "", String2 = "", String3 = "", String4 = "", String5 = "", Separator = ", ") Export
	
	RowsArray = New Array;
	
	If Not IsBlankString(String1) Then
		RowsArray.Add(String1);
	EndIf;
	If Not IsBlankString(String2) Then
		RowsArray.Add(String2);
	EndIf;
	If Not IsBlankString(String3) Then
		RowsArray.Add(String3);
	EndIf;
	If Not IsBlankString(String4) Then
		RowsArray.Add(String4);
	EndIf;
	If Not IsBlankString(String5) Then
		RowsArray.Add(String5);
	EndIf;
	
	Return StrConcat(RowsArray, Separator);;
	
EndFunction

Procedure SupplementString(DestinationRow = "", String2 = "", String3 = "", String4 = "", String5 = "", Separator = ", ") Export
	
	DestinationRow = ConnectLines(
		DestinationRow,
		String2,
		String3,
		String4,
		String5,
		Separator);
	
EndProcedure

Function NumberPerLineWithoutSpaces(NumberValue) Export
	
	Return Format(NumberValue, "NG=");
	
EndFunction

Function RemoveElementsFromTemplateString(TemplateRow, ItemsToRemove) Export
	
	RowsArray 	= StringFunctionsClientServer.SplitStringIntoSubstringsArray(TemplateRow, ",", True, True);
	ArrayDeletition = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ItemsToRemove, ",", True, True);
	
	For Each ItemToRemove In ArrayDeletition Do
		
		SourceElement = RowsArray.Find(ItemToRemove);
		
		If SourceElement <> Undefined Then
			RowsArray.Delete(SourceElement);
		EndIf;
		
	EndDo;
	
	Return StrConcat(RowsArray, ", ");
	
EndFunction

#EndRegion

#Region OperationsWithValueTypes

Function ThisIsDescriptionOfDocumentTypes(FieldType)
	
	FieldTypesDetails 		   = NonNullTypeDescriptions(FieldType);
	DocumentTypes 			   = DescriptionOfDocumentTypes();
	TypeContainsOnlyDocuments = (FieldTypesDetails.Types().Count() > 0);
	
	For Each Current_Type In FieldTypesDetails.Types() Do
		
		If Not DocumentTypes.ContainsType(Current_Type) Then
			TypeContainsOnlyDocuments = False;
			Break;
		EndIf;
		
	EndDo;
	
	Return TypeContainsOnlyDocuments;
	
EndFunction

Function NonNullTypeDescriptions(InitialTypes) Export
	
	If TypeOf(InitialTypes) = Type("Type") Or TypeOf(InitialTypes) = Type("String") Then
		
		TypesArray = New Array;
		TypesArray.Add(InitialTypes);
		LongDesc = New TypeDescription(TypesArray);
		
	ElsIf TypeOf(InitialTypes) = Type("Array") Then
		
		LongDesc = New TypeDescription(InitialTypes);
		
	Else // this is a description of the types
		
		LongDesc = InitialTypes;
		
	EndIf;
	
	Return New TypeDescription(LongDesc,, "Null");
	
EndFunction

// Returns a description of the types of all documents, taking into account the documents from the configuration extensions.
//
// Returns:
//	TypeDescription - description of the types of all documents
//
Function DescriptionOfDocumentTypes() Export
	
	// In the platform as a result returned by the Documents method.The type of the link() does not contain document types from extensions.
	// It is planned to support document types from extensions in the Platform version 8.3.20
	
	TypesArray = New Array;
	
	For Each MetaDocument In Metadata.Documents Do
		TypesArray.Add(Type("DocumentRef." + MetaDocument.Name));
	EndDo;
	
	DocumentTypes = New TypeDescription(TypesArray);
	
	Return DocumentTypes;
	
EndFunction

// Returns a string representation of an empty value of the specified type for the request.
//
// Parameters:
//	DescriptionOfValueType_ - TypeDescription -
//
// Returns:
//	String - 
//
Function PresentationOfEmptyTypeValueForQuery(DescriptionOfValueType_) Export
	
	DescriptionOfAdjustedType = NonNullTypeDescriptions(DescriptionOfValueType_);
	
	Result = "UNDEFINED";
	
	If DescriptionOfAdjustedType.Types().Count() = 1 Then
		
		ValueType = DescriptionOfAdjustedType.Types()[0];
		
		If ValueType = Type("Boolean") Then
			Result = "FALSE";
		ElsIf ValueType = Type("Date") Then
			Result = "DATETIME(1,1,1,0,0,0)";
		ElsIf ValueType = Type("String") Then
			Result = """""";
		ElsIf ValueType = Type("Number") Then
			Result = "0";
		ElsIf ValueType = Type("AccumulationRecordType")
		 Or ValueType = Type("UUID")
		 Or ValueType = Type("Type") Then
			Result = "UNDEFINED";
		Else // Reference type
			
			If Metadata.FindByType(ValueType) <> Undefined Then
				Result = "VALUE(" + DescriptionOfAdjustedType.AdjustValue(Undefined).Metadata().FullName() + ".EmptyRef)";
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the full name of the metadata object by its type.
//
// Parameters:
//	ObjectType - Type - type of metadata object
//
// Returns:
//	String - full name of the metadata object
//
Function NameOfMetadataObjectByType(ObjectType) Export
	
	MetaObject = Metadata.FindByType(ObjectType);
	
	If MetaObject = Undefined Then
		Return "UNDEFINED";
	EndIf;
	
	Return MetaObject.FullName();
	
EndFunction

// Returns the full name of the metadata object corresponding to the cost item value type.
//
// Parameters:
//	AssetRef - ChartOfCharacteristicTypesRef.ExpenseItems - item of expenditure
//
// Returns:
//	String - full name of the metadata object
//
Function PresentationOfArticleValueType(AssetRef) Export
	
	TypeOfAnalytics = Common.ObjectAttributeValue(AssetRef, "ValueType");
	Return NameOfMetadataObjectByType(TypeOfAnalytics.Types()[0]);
	
EndFunction

#EndRegion

#Region TableColumns

// Returns a string containing the names of all columns in the temporary table.
//
// Parameters:
//	ContainerManagerTT - Structure - Structure containing a temporary table Manager
//	TempTableName - String - name of the temporary table
//
// Returns:
//	String - comma-separated list of column names
//
Function GetColumnNamesOfTemporaryTableByString(ContainerManagerTT, TempTableName) Export
	
	Table = CostCalculationAppliedAlgorithms.UnloadTemporaryTable(ContainerManagerTT, TempTableName, 0);
	Columns = Table.Columns;
	
	ColumnsNames = "";
	For Each Column In Columns Do
		ColumnsNames = ColumnsNames + ?(ColumnsNames = "", "", ", ") + Column.Name;
	EndDo;
	
	Return ColumnsNames;
	
EndFunction

// Converts a table of values into a tabular document.
// Parameters:
//	Table - ValueTable -
//	DatesInFormatMonthYear - Boolean - convert dates to the "Month Year" format
//
// Returns:
//	SpreadsheetDocument -
Function TableOfValuesInTabularDocument(Table, DatesInFormatMonthYear = True) Export
	
	UnloadingTable = New SpreadsheetDocument; // table of values converted to mxl
	
	LineNumber  = 1;
	ColumnNumber = 0;
	
	// Let's form the header of the tabular document - output the names of the columns of the table of values
	For Each CurColumn In Table.Columns Do
		
		ColumnNumber = ColumnNumber + 1;
		
		Area = UnloadingTable.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
		
		Area.Text 		  = CurColumn.Name;
		Area.ColumnWidth = CurColumn.Width;
		Area.Font 		  = Metadata.StyleItems.ImportantLabelFont.Value; 
		Area.BottomBorder  = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
		
	EndDo;
	
	// Output the rows of the table of values
	For Each CurrRow In Table Do
		
		LineNumber = LineNumber + 1;
		ColumnNumber = 0;
		
		For Each CurColumn In Table.Columns Do
			
			ColumnNumber = ColumnNumber + 1;
			
			Area = UnloadingTable.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
			If DatesInFormatMonthYear And TypeOf(CurrRow[CurColumn.Name]) = Type("Date") Then
				Area.Text = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(CurrRow[CurColumn.Name]);
			Else
				Area.Text = CurrRow[CurColumn.Name];
			EndIf;
			
		EndDo;
		
	EndDo;
	
	UnloadingTable.FixedTop = 1;
	UnloadingTable.FixedLeft  = 1;
	
	Return UnloadingTable;
	
EndFunction

#EndRegion

#Region WorkingWithMetadata

// Checks whether the specified metadata object is an independent data register.
//
// Parameters:
//	RegisterMetadata - MetadataObject - the metadata object being checked
//
// Returns:
//	Boolean - Test result
//
Function IsIndependentInformationRegister(RegisterMetadata) Export
	
	Result = Metadata.InformationRegisters.Contains(RegisterMetadata)
		And RegisterMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent;
	
	Return Result;
	
EndFunction

// Checks whether the specified metadata object is a periodic register of information.
//
// Parameters:
//	RegisterMetadata - MetadataObject - the metadata object being checked
//
// Returns:
//	Boolean - Test result
//
Function ThisIsPeriodicInformationRegister(RegisterMetadata) Export
	
	Result = Metadata.InformationRegisters.Contains(RegisterMetadata)
		And RegisterMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical;
	
	Return Result;
	
EndFunction

#EndRegion

#Region HandlingRequests

// Execute a request with measurement.
// 
// Parameters:
//  Query - Query - Query
//  EventNameLR - String - Name of the log event
// 
// Returns:
//  Array, QueryResult, QueryResultSelection, Undefined - Execute A Request With Measurement
Function ExecuteRequestWithMeasurement(Query, EventNameLR) Export
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("QueryExecutionResult", "");
	
	ExecutionStarted = CurrentUniversalDateInMilliseconds();
	
	Results = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query,,, True);
	
	RunTime = (CurrentUniversalDateInMilliseconds() - ExecutionStarted) / 1000;
	
	CalculationParameters.QueryExecutionResult = 
		NStr("vi = 'Thời gian chung';
			|ru = 'Общее время';
			|en = 'Total time'; fa = 'زمان کل';
			|it = 'Tempo generale';
			|pl = 'Całkowity czas';
			|tr = 'Toplam süre'") + ": " + CostCalculationProtocol.TimePresentation(RunTime) + Chars.LF
		+ CalculationParameters.QueryExecutionResult;
	
	WriteLogEvent(
		EventNameLR,
		EventLogLevel.Information,,,
		CalculationParameters.QueryExecutionResult);
		
	Return Results;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Temporary, before transferring the algorithms of the calculation module to this module, the calculation of the Costsadjustmentalgorithms:
//		- Fill in the timestamp table number
Function InitializeParametersForUsingUniversalMechanisms(TempTablesManager)
	
	Parameters = New Structure;
	Parameters.Insert("TempTablesManager", TempTablesManager);
	
	CostCalculationAppliedAlgorithms.SetTechnologicalParametersOfCalculation(Parameters);
	
	Return Parameters;
	
EndFunction

Procedure CalculateTableFieldByCumulativeTotal(CalculationParameters, Query, DataDetails, NegativeBasesArePossible, ArrangeByKey = False)
	
	CostCalculationProtocol.StartCreatingTemporaryTable(CalculationParameters, DataDetails.TTResultName);
	
	Query.Text =
	"SELECT
	|	T.ConnectionKey,
	|	T.RecordKeyField,
	|	T.BasisField
	|FROM
	|	NameTT AS T
	|WHERE
	|	T.BasisField <> 0
	|ORDER BY
	|	ConnectionKey,
	|	BasisField DESC,
	|	RecordKeyField";
	
	If ArrangeByKey Then
		Query.Text = StrReplace(Query.Text, "BasisField DESC", DataDetails.RecordKeyField);
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "RecordKeyField", DataDetails.RecordKeyField);
	Query.Text = StrReplace(Query.Text, "BasisField", 	    DataDetails.BasisField);
	Query.Text = StrReplace(Query.Text, "NameTT",   DataDetails.NameTT);
	
	If NegativeBasesArePossible Then
		Query.Text = StrReplace(Query.Text, "DESC", "");
	EndIf;
	
	SourceTable_ = Query.Execute().Unload();
	SourceTable_.Columns.Add("Basis_Total", SourceTable_.Columns[DataDetails.BasisField].ValueType);
	
	ConnectionKey  = Undefined;
	Basis_Total = 0;
	
	For Each CurrentRow In SourceTable_ Do
		
		If ConnectionKey <> CurrentRow.ConnectionKey Then
			ConnectionKey  = CurrentRow.ConnectionKey;
			Basis_Total = 0;
		EndIf;
		
		Basis_Total = Basis_Total + CurrentRow[DataDetails.BasisField];
		CurrentRow.Basis_Total = Basis_Total;
		
	EndDo;
	
	SourceTable_.Columns.Delete(DataDetails.BasisField);
	
	Query.SetParameter("SourceTable_", SourceTable_);
	
	Query.Text =
	"SELECT
	|	T.ConnectionKey,
	|	T.RecordKeyField,
	|	T.Basis_Total
	|INTO TTResultName
	|FROM
	|	&SourceTable_ AS T
	|INDEX BY
	|	ConnectionKey";
	
	Query.Text = StrReplace(Query.Text, "RecordKeyField", DataDetails.RecordKeyField);
	Query.Text = StrReplace(Query.Text, "TTResultName", DataDetails.TTResultName);
	
	Query.Execute();

	Query.Parameters.Delete("SourceTable_");
	
	CostCalculationProtocol.EndFormationOfTemporaryTable(CalculationParameters);
	
EndProcedure

#EndRegion
