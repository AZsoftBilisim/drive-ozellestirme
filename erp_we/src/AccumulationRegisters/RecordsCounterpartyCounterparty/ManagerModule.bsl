#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
#Region Public
// Determines the sources to clarify the account is available in the register and their properties.
//
//
// Parameters:
//  SourceProperties - String - "Field name" - the name of the attribute of the accumulation register, from which you plan to get the source
//                               of account refinement.
//
// Returns:
//  Map - The key is the name of the source of the invoice refinement. 
//                 Value - the structure of the properties of the invoice refinement source.
//
Function SourcesOfInvoiceRefinement(SourceProperties) Export
	
	SourcesOfInvoiceRefinement = New Map;
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAPCr,
		New Structure(SourceProperties, "HFCCalculations"));

	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAPDr,
		New Structure(SourceProperties, "CorHFCCalculations"));

	Return SourcesOfInvoiceRefinement;
	
EndFunction

// Defines the sources of register divisions and their properties.
//
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDivisions() Export

	SourcesOfDivisions = New Map;
	
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.BusinessOperation, "Department");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.ARAPObjectForSettlementsWithCounterparty, "ObjectOfCalculationsDivision");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.CorCounterpartyARAPAccountingObject, "CorObjectOfCalculationsDivision");
	
    Return SourcesOfDivisions;
	
EndFunction

// Defines the sources of register directions and their properties.
//
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDirections() Export

	Result = New Map;
	
	SourcesOfDirections = Enums.SourceOfLinesOfBusinessOfAnalyticalRegister;
	Result.Insert(SourcesOfDirections.LineOfBusiness, "LineOfBusiness");
	Result.Insert(SourcesOfDirections.CorLineOfBusiness, "CorLineOfBusiness");

	Return Result;

EndFunction

// Defines the sources of sub-content filling.
//
//
// Returns:
//  Array - array of register attributes.
//
Function SourcesOfExtdimension() Export

	ExtDimensionArrayDr = New Array;
	ExtDimensionArrayDr.Add("CorPartner");
	ExtDimensionArrayDr.Add("CorCounterparty");
	ExtDimensionArrayDr.Add("CorContract");
	
	ExtDimensionArrayCr = New Array;
	ExtDimensionArrayCr.Add("Partner");
	ExtDimensionArrayCr.Add("Counterparty");
	ExtDimensionArrayCr.Add("Contract");

	Return New Structure("ExtDimensionDr, ExtDimensionCr", ExtDimensionArrayDr, ExtDimensionArrayCr);
	
EndFunction

// Identifies indicators in the currency of the register.
//
//
// Parameters:
//  PropertiesOfIndicators - String - "Sourcecurrency" - the currency source for the register indicator.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function IndicatorsInCurrency(PropertiesOfIndicators) Export

	IndicatorsInCurrency = New Map;
	
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInCurrency, New Structure(PropertiesOfIndicators, "Currency"));
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInARAPCurrencyCr, New Structure(PropertiesOfIndicators, "ARAPCurrency"));
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInDebitARAPCurrency, New Structure(PropertiesOfIndicators, "CorCurrencyOfARAPAccounting"));
	
	Return IndicatorsInCurrency;

EndFunction

// Identifies indicators in the currency of the register.
//
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function QuantityIndicators() Export

	QuantityIndicators = New Map;
	Return QuantityIndicators;

EndFunction

// Defines register metrics.
//
//
// Parameters:
//  Properties - Structure - containing the keys of the properties of Indicators, properties of Resources.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function Indicators(Properties) Export

	Indicators = New Map;
	
	PropertiesOfIndicators = Properties.PropertiesOfIndicators;
	ResourceProperties = Properties.ResourceProperties;
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "Sum", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "SumCompl", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInCurrency", "Currency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInARAPCurrency", "ARAPCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AdjAmountInARAPCurrency", "CorCurrencyOfARAPAccounting"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVAT", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "LocalAmountExcludingVAT", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVATInCurrency", "Currency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVATInARAPCurrency", "ARAPCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AdjAmountExcludingVATInARAPCurrency", "CorCurrencyOfARAPAccounting"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmount", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountCompl", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "NDSAmountInCurrency", "Currency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountOfNDSInCurrencyOfMutualSettlements", "ARAPCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "CorAmountOfNDSInCurrencyOfMutualSettlements", "CorCurrencyOfARAPAccounting"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	Return Indicators;
	
EndFunction

#EndRegion
#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Department)
	|	AND ValueAllowed(Organization)
	|	AND( ValueAllowed(Partner)
	|	OR ValueAllowed(CorPartner)
	|	) ";

EndProcedure

// End StandardSubsystems.AccessManagement

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - Undefined, TempTablesManager - Temporary table data is used when creating new tasks.
//  DataForRegisteringTasks - ValueTable - A table with data for registering new tasks.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalDocumentVerification(RecordSet, KindsOfTasks,
	TempTablesManager, DataForRegisteringTasks) Export
	
		
	If KindsOfTasks.Find(Catalogs.BackdateJobKinds.RecordInFinancialAccounting) <> Undefined Then
		TypesOfRegistrarsReflectionOfDocumentsInInternationalAccounting = Metadata.InformationRegisters.DocumentPostingInFinancialAccounting.StandardAttributes.Recorder.Type;
	EndIf;
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	For Each CurrentTypeOfTask In KindsOfTasks Do

		
		If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordInFinancialAccounting Then
			TableOfDocumentsToBeReflected = InformationRegisters.DocumentPostingInFinancialAccounting.TableOfDocumentsToBeReflectedInInternationalAccounting();
			For Each CurrentData In DataForRegisteringTasks Do
				If TypesOfRegistrarsReflectionOfDocumentsInInternationalAccounting.ContainsType(TypeOf(CurrentData.Recorder)) Then
					NewRow = TableOfDocumentsToBeReflected.Add();
					NewRow.Organization = CurrentData.Organization;
					NewRow.Document = CurrentData.Recorder;
					NewRow.DateRecord = BegOfDay(CurrentData.Period);
					NewRow.Period = BegOfDay(CurrentData.Period);
				EndIf;
			EndDo;
			TableOfDocumentsToBeReflected.GroupBy("Document, Organization, DateRecord, Period");
			Return TableOfDocumentsToBeReflected;
		EndIf;
		If Not RecordSet.AdditionalProperties.Property("UpdatingOfRegisteredRecordsCounterpartyCounterparty") Then
			For Each CurrentData In DataForRegisteringTasks Do
				NewRow = DataTable.Add();
				NewRow.Organization = CurrentData.Organization;
				NewRow.TaskPeriod = CurrentData.Period;
				NewRow.Document = CurrentData.Recorder;
				NewRow.JobKind = CurrentTypeOfTask;
			EndDo;
		EndIf;
		
	EndDo;
	
	DataTable.GroupBy("Organization, TaskPeriod, Document, JobKind");
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
