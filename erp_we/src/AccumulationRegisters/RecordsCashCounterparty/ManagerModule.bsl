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
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfCash,
		New Structure(SourceProperties, "HFCCash"));
		
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAP,
		New Structure(SourceProperties, "HFCCalculations"));
		
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
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.CashManagementDimension, "CashDivision");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.ARAPObjectForSettlementsWithCounterparty, "ObjectOfCalculationsDivision");
	
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
	Result.Insert(SourcesOfDirections.LineOfBusinessCash, "LineOfBusinessCash");
	Result.Insert(SourcesOfDirections.CounterpartyLineOfBusiness, "CounterpartyLineOfBusiness");

	Return Result;

EndFunction

// Defines the sources of sub-content filling.
//
//
// Returns:
//  Array - array of register attributes.
//
Function SourcesOfExtdimension() Export

	ExtDimensionArray = New Array;
	ExtDimensionArray.Add("Cash");
	ExtDimensionArray.Add("CashType");
	ExtDimensionArray.Add("CashFlowItem");
	ExtDimensionArray.Add("Partner");
	ExtDimensionArray.Add("Counterparty");
	ExtDimensionArray.Add("Contract");

	Return New Structure("ExtDimensionDr, ExtDimensionCr", ExtDimensionArray, ExtDimensionArray);
	
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
	
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInPaymentCurrency, New Structure(PropertiesOfIndicators, "PaymentCurrency"));
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInARAPCurrency, New Structure(PropertiesOfIndicators, "ARAPCurrency"));
	
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
	
	// The array contains not only register resources, but also fields derived from them in queries.
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "PayAmount", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PaymentAmountLocal", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PaymentAmountPaymentCurrency", "PaymentCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PaymentAmountInTheSettlementCurrency", "ARAPCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.PayAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "PostpaymentAmount", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PostpaymentAmountLocal", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PaymentAmountInPaymentCurrency", "PaymentCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PostPaymentAmountInARAPCurrency", "ARAPCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.PostpaymentAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentAmountMan", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentAmountLocal", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentAmount", "PaymentCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentAmountInARAPCurrency", "ARAPCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmount", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountCompl", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountVATCurrencyPayment", "PaymentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaidWithinLimit", "PaymentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidWithinLimit, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaidAboveLimit", "PaymentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidAboveLimit, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaid", "PaymentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaid, New Structure(PropertiesOfIndicators, ArrayOfResources));

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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Partner)
	|	AND( CASE WHEN VALUETYPE(Cash) = TYPE(Catalog.CashAccounts) THEN ValueAllowed(Cash)
	|	WHEN VALUETYPE(Cash) = TYPE(Catalog.CashRegisters) THEN ValueAllowed(Cash)
	|	WHEN VALUETYPE(Cash) = TYPE(Catalog.Persons) THEN ValueAllowed(Cash)
	|	ELSE TRUE END) ";

EndProcedure

// End StandardSubsystems.AccessManagement

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalDocumentVerification(RecordSet, KindsOfTasks,
	TempTablesManager = Undefined, DataForRegisteringTasks = Undefined) Export
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
		
	If KindsOfTasks.Find(Catalogs.BackdateJobKinds.RecordInFinancialAccounting) <> Undefined Then
		TypesOfRegistrarsReflectionOfDocumentsInInternationalAccounting = Metadata.InformationRegisters.DocumentPostingInFinancialAccounting.StandardAttributes.Recorder.Type;
	EndIf;
	DataForCreatingTasks = DataForRegisteringTasks.Copy();

	For Each CurrentTypeOfTask In KindsOfTasks Do
		
		
		If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordInFinancialAccounting Then
			TableOfDocumentsToBeReflected = InformationRegisters.DocumentPostingInFinancialAccounting.TableOfDocumentsToBeReflectedInInternationalAccounting();
			For Each CurrentData In DataForCreatingTasks Do
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
		If Not RecordSet.AdditionalProperties.Property("UpdatingOfRegisteredRecordedCashCounterparty") Then
			For Each CurrentData In DataForCreatingTasks Do
				NewRow = DataTable.Add();
				NewRow.Organization = CurrentData.Organization;
				NewRow.TaskPeriod = CurrentData.Period;
				NewRow.Document = CurrentData.Recorder;
				NewRow.JobKind = CurrentTypeOfTask;
			EndDo;
		EndIf;
		
	EndDo;

	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
