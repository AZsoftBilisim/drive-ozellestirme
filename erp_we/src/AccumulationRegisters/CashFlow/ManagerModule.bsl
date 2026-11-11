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
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfCashCr,
		New Structure(SourceProperties, "HFCCash"));
		
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfCashDr,
		New Structure(SourceProperties, "CorHFCCash"));
		
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
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.CashManagementDimensionOfSender, "CashDivision");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.CashManagementDimensionOfRecipient, "CorCashDivision");
	
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
	ExtDimensionArrayDr.Add("CorCash");
	ExtDimensionArrayDr.Add("CorCashType");
	ExtDimensionArrayDr.Add("CashFlowItem");
	
	ExtDimensionArrayCr = New Array;
	ExtDimensionArrayCr.Add("Cash");
	ExtDimensionArrayCr.Add("CashType");
	ExtDimensionArrayCr.Add("CashFlowItem");

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
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInCorCurrency, New Structure(PropertiesOfIndicators, "CorrespondingCurency"));
	
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
	ArrayOfResources.Add(New Structure(ResourceProperties, "Sum", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "SumCompl", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInCurrency", "Currency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInCorCurrency", "CorrespondingCurency"));
	
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaidWithinLimit", "Currency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidWithinLimit, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaidAboveLimit", "Currency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidAboveLimit, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountToBePaid", "Currency"));
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
	|	AND( CASE WHEN VALUETYPE(Cash) = TYPE(Catalog.CashAccounts) THEN ValueAllowed(Cash)
	|	WHEN VALUETYPE(Cash) = TYPE(Catalog.CashRegisters) THEN ValueAllowed(Cash)
	|	WHEN VALUETYPE(Cash) = TYPE(Catalog.Persons) THEN ValueAllowed(Cash)
	|	ELSE TRUE END) ";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.CashFlow.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.7.62";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("4df05b3f-a9da-45d8-af29-c23f052d162e");
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.CashFlow.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật bản ghi kết chuyển chứng từ theo biểu ghi tích lũy ""Bản ghi kết chuyển vốn bằng tiền""';
							|ru = 'Обновляет движения документов по регистру накопления ""Движения денежных средств""';
							|en = 'Updates document register records in the ""Cash flow"" accumulation register'; fa = 'Updates document register records in the ""Cash flow"" accumulation register';
							|it = 'Aggiorna il movimento dei documenti in base al registro di accumulo ""Flussi di cassa""';
							|pl = 'Aktualizuje przepływy dokumentów wg rejestru akumulacji ""Przepływy środków pieniężnych""';
							|tr = '""Nakit akışı"" birikim kaydı ile belge akışını güncelliyor'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.CashFlow.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.CashFlow.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// The procedure for registering data for the update handler is to process the data for the transition Version.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName  = "AccumulationRegister.CashFlow";
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	Data.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CashFlow AS Data
	|WHERE
	|	(Data.PaymentRequest = UNDEFINED
	|		OR Data.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef))
	|	AND Data.Recorder REFS Document.PaymentRequest
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Data.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CashFlow AS Data
	|WHERE
	|	(Data.PaymentRequest = UNDEFINED
	|		OR Data.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef))
	|	AND Data.Recorder REFS Document.ApplicationForBusinessTrip
	|	
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Data.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CashFlow AS Data
	|WHERE
	|	(Data.PaymentRequest = UNDEFINED
	|		OR Data.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef))
	|	AND Data.Recorder REFS Document.CashVoucher
	|	AND CAST(Data.Recorder AS Document.CashVoucher).PaymentByRequests
	|	
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Data.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CashFlow AS Data
	|WHERE
	|	(Data.PaymentRequest = UNDEFINED
	|		OR Data.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef))
	|	AND Data.Recorder REFS Document.BankAccountIssue
	|	AND CAST(Data.Recorder AS Document.BankAccountIssue).PaymentByRequests
	|";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = True;
	
	Recorders = New Array;
	Recorders.Add("Document.BankAccountIssue");
	Recorders.Add("Document.CashVoucher");
	Recorders.Add("Document.PaymentRequest");
	Recorders.Add("Document.ApplicationForBusinessTrip");
	
	ProcessingCompleted = InfobaseUpdateTM.OverwriteRegisteredRecordsFromQueue(
		Recorders, "AccumulationRegister.CashFlow", Parameters.Queue);
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndIf
