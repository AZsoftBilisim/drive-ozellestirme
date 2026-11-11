#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region SoftwareInterface

// Performs the execution of documents on the register of assets and liabilities.
// Parameters:
//	Parameters - Structure - Results of the method.
//	StorageAddress - String - The address where the results of the work will be placed.
//
Procedure GenerateRegisteredRecordsByCase(Parameters, StorageAddress = "") Export
	
	NotRecordRegisteredRecords_ = Parameters.NotRecordRegisteredRecords_;
	
	Measurements = New Structure;
	BeginningOfFormationOfRegisteredRecords = CurrentUniversalDateInMilliseconds();
	
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	TypesOfLoggers = NumberOfRegistrars();
	AddMeasurement(Measurements, "FormationOfListOfDocumentsForCarryingOut", MeasurementStart);
	OutputProtocol(NStr("vi = 'Bắt đầu điền. Để được xử lý:';
						|ru = 'Начало заполнения. Предстоит обработать:';
						|en = 'Population start. To be processed:'; fa = 'Population start. To be processed:';
						|it = 'Inizio di compilazione. Da elaborare:';
						|pl = 'Zacznij wypełniać. Do przetworzenia:';
						|tr = 'Doldurma başlangıcı. İşlenecek:'"), TypesOfLoggers);
	
	Process_ = InitializeInformationAboutFilling(TypesOfLoggers);
	ProcessedTypes = Process_.ProcessedTypes;
	LastProcessedItem = "";
	If ProcessedTypes.Count() > 0 Then
		LastProcessedItem = ProcessedTypes[ProcessedTypes.Count()-1].Name;
	EndIf;
	For Each TypeOfRegistrar In TypesOfLoggers Do
		
		ProcessedType = ProcessedTypes.Find(TypeOfRegistrar.Name, "Name");
		DocumentProcessed = ProcessedType <> Undefined;
		If DocumentProcessed And ProcessedType.Name <> LastProcessedItem Then
			Continue;
		EndIf;
		
		FillInRegisterInformationOnDocuments(TypeOfRegistrar, ProcessedTypes, NotRecordRegisteredRecords_);
		
	EndDo;
	Totals = ProcessedTypes.Add();
	Totals.Name = NStr("vi = 'Tổng số';
						|ru = 'Итого';
						|en = 'Total'; fa = 'جمع کل';
						|it = 'Totale';
						|pl = 'Total';
						|tr = 'Toplam'");
	Totals.TotalDocuments = ProcessedTypes.Total("TotalDocuments");
	Totals.TotalRegisteredRecords = ProcessedTypes.Total("TotalRegisteredRecords");
	Totals.FillingTime = ProcessedTypes.Total("FillingTime");
	Totals.TotalSpent = TimePresentation(Totals.FillingTime);
	
	InformationRecords = Constants.IBUpdateInfo.Get().Get(); //Structure
	InformationRecords.Delete("FillingInAssetsLiabilities");
	Constants.IBUpdateInfo.Set(New ValueStorage(InformationRecords));
	
	AddMeasurement(Measurements, "FormationOfRegisteredRecords", BeginningOfFormationOfRegisteredRecords);
	OutputProtocol(NStr("vi = 'Sự kết thúc điền. Tổng số đã xử lý:';
						|ru = 'Конец заполнения. Всего обработано:';
						|en = 'Population end. Total processed:'; fa = 'Population end. Total processed:';
						|it = 'Termine di compilazione. Totale elaborati:';
						|pl = 'Koniec wypełnienia. Całość przetworzona:';
						|tr = 'Doldurma sonu. Toplam işlenen:'"), ProcessedTypes, Measurements);
	
	Constants.UseBalanceSheetStatement.Set(True);
	Constants.AssetLiabilityRecordsArePopulated.Set(True);
	
	Parameters.Insert("ImportIsCompleted", True);
	Parameters.Insert("Measurements", Measurements);
	If IsBlankString(StorageAddress) Then
		Parameters.Insert("TypesOfLoggers", ProcessedTypes);
	Else
		PutToTempStorage(Parameters, StorageAddress);
	EndIf;
	
EndProcedure

// generates movements by the register of other active arrays
// The principle of the formation of movements, see the presentation of the project https://partners.v8.1c.ru/forum/topic/1484492#m_1484492 
//
// Parameters:
//  DocumentReference - DocumentRef, Structure of KeyAndValue - the link of the document for which it is necessary to generate and record the movements of the balance control:
//                                      * Ref - DocumentRef
//  RegisterRecords - Structure of KeyAndValue:
//               * Key - String - Register name as in metadata
//               * Value - AccumulationRegisterRecordSet.OtherAssetsLiabilities
//             Collections of movements - sets of register entries of a document stored in a collection of movements or a structure simulating this collection.
//
Procedure AddDocumentRegisteredRecords(DocumentReference, RegisterRecords) Export
	
	BeginningOfFormationOfRegisteredRecords = CurrentUniversalDateInMilliseconds();
	
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	TimeToUnloadMotionSets = 0;
	TimeOfUnloadingOfCalculationsAccordingToDocuments = 0;
	If TypeOf(RegisterRecords) = Type("RegisterRecordsCollection") Then
		DocumentMovementTables = UnloadMotionSets(DocumentReference, RegisterRecords);
		TimeToUnloadMotionSets = (CurrentUniversalDateInMilliseconds() - MeasurementStart) / 1000;
		DocumentMovementTables.Property("TimeOfUnloadingOfCalculationsAccordingToDocuments", TimeOfUnloadingOfCalculationsAccordingToDocuments);
		DocumentMovementTables.Delete("TimeOfUnloadingOfCalculationsAccordingToDocuments");
	Else
		UploadCalculationsByTimeFrame(DocumentReference, RegisterRecords);
		DocumentMovementTables = RegisterRecords;
	EndIf;
	
	MotionParameters = New Structure;
	MotionParameters.Insert("Ref", DocumentReference);
	MotionParameters.Insert("TablesForRegisteredRecords", DocumentMovementTables);
	
	RequestRegisteredRecords = RequestRegisteredRecords(MotionParameters);
	
	If RequestRegisteredRecords <> Undefined Then
		Measurements = MotionParameters.Protocol.Measurements;
		Measurements.Insert("UnloadingMotionSets", TimeToUnloadMotionSets);
		Measurements.Insert("UploadingCalculationsBasedOnDocuments", TimeOfUnloadingOfCalculationsAccordingToDocuments);
		
		MeasurementStart = CurrentUniversalDateInMilliseconds();
		FlowOfAssetsAndLiabilities = RequestRegisteredRecords.Execute().Unload();
		AddMeasurement(Measurements, "ExecutingMotionRequest", MeasurementStart);
		
		If TypeOf(RegisterRecords) = Type("RegisterRecordsCollection") Then
			RegisterRecords.OtherAssetsLiabilities.Load(FlowOfAssetsAndLiabilities);
			RegisterRecords.OtherAssetsLiabilities.Write = True;
		ElsIf TypeOf(RegisterRecords) = Type("Structure") Then
			RegisterRecords.Insert("OtherAssetsLiabilities", FlowOfAssetsAndLiabilities);
		EndIf;
		
		AddMeasurement(Measurements, "TotalFormationOfRegisteredRecords", BeginningOfFormationOfRegisteredRecords);
	EndIf;
	
EndProcedure

// Updates movements on the balance sheet after the distribution of deferred settlements.
//
// Parameters:
//  LoggersToReflection - Array - documents processed by deferred settlement allocation
//  DebugParameters - Structure - advanced setting.
//
Procedure UpdateRegisteredRecordsForSettlementsWithPartners(LoggersToReflection, DebugParameters = Undefined) Export
	
	If TypeOf(LoggersToReflection) = Type("Array") And LoggersToReflection.Count() = 0 Then
		Return;
	EndIf;
	
	StartUpdatingSettlementsWithPartners = CurrentUniversalDateInMilliseconds();
	MotionParameters = New Structure;
	MotionParameters.Insert("TypeOfDeferredCalculation", Enums.MovementSourcesKinds.PartnersARAPAccounting);
	MotionParameters.Insert("DocumentsToBeReflected", LoggersToReflection);
	MotionParameters.Insert("NameOfTemporaryResultTable", "TTNewRegisteredRecordsOfAssetsLiabilities");
	
	RequestRegisteredRecords = RequestRegisteredRecords(MotionParameters, DebugParameters);
	If RequestRegisteredRecords = Undefined Then
		Return;
	EndIf;
	
	Measurements = MotionParameters.Protocol.Measurements;
	
	RequestRegisteredRecords.Text = RequestRegisteredRecords.Text +
	"// Movements of assets And liabilities NOT affected by the update of settlements with partners
	|SELECT
	|	T.Period,
	|	T.Recorder,
	|	T.RecordType,
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.AssetRef,
	|	T.Dimension,
	|	T.Sum,
	|	T.CalculationOfCost,
	|	T.SourceKind,
	|	T.Source
	|FROM
	|	AccumulationRegister.OtherAssetsLiabilities AS T
	|	LEFT JOIN TTNewRegisteredRecordsOfAssetsLiabilities AS NewRegisteredRecords_
	|	ON T.Period = NewRegisteredRecords_.Period
	|	AND T.Recorder = NewRegisteredRecords_.Recorder
	|	AND T.Organization = NewRegisteredRecords_.Organization
	|	AND T.Source = NewRegisteredRecords_.Source
	|WHERE
	|	T.Recorder IN (&ArrayOfLoggers)
	|	AND NOT T.SourceKind IN (
	|		&TypeOfDeferredCalculation,
	|		VALUE(Enum.MovementSourcesKinds.BalanceCalculation))
	|	AND NewRegisteredRecords_.Recorder IS NULL
	|
	|UNION ALL
	|
	|// Updated movements of assets and liabilities
	|SELECT
	|	T.Period,
	|	T.Recorder,
	|	T.RecordType,
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.AssetRef,
	|	T.Dimension,
	|	T.Sum,
	|	T.CalculationOfCost,
	|	T.SourceKind,
	|	T.Source
	|FROM
	|	TTNewRegisteredRecordsOfAssetsLiabilities AS T
	|
	|TOTALS BY
	|	T.Recorder";
	
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	QueryResult = RequestRegisteredRecords.Execute();
	SelectionByDocuments = QueryResult.Select(QueryResultIteration.ByGroups);
	AddMeasurement(Measurements, "ExecutingMotionRequest", MeasurementStart);
	TypesOfLoggers = Metadata.AccumulationRegisters.OtherAssetsLiabilities.StandardAttributes.Recorder.Type;
	
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	While SelectionByDocuments.Next() Do
		If Not TypesOfLoggers.ContainsType(TypeOf(SelectionByDocuments.Recorder)) Then
			Continue;
		EndIf;
		RecordSet = AccumulationRegisters.OtherAssetsLiabilities.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SelectionByDocuments.Recorder);
		Selection = SelectionByDocuments.Select();
		While Selection.Next() Do
			FillPropertyValues(RecordSet.Add(), Selection);
		EndDo;
		If RecordSet.Count() > 0 Then
			InfobaseUpdate.WriteData(RecordSet);
		EndIf;
	EndDo;
	AddMeasurement(Measurements, "WritingRegisterRecords", MeasurementStart);
		
	AddMeasurement(Measurements, "TotalUpdateOfSettlementsWithPartners", StartUpdatingSettlementsWithPartners);
	
	If TypeOf(DebugParameters) = Type("Structure") Then
		DebugParameters.Insert("Protocol", MotionParameters.Protocol);
	EndIf;
	
EndProcedure

// Generates a query to the database to obtain the movements of the management balance
//
// Parameters:
//  MotionParameters - Structure - input data for the formation of movements on the Man. balance (See InitializeMotionParameters)
//  DebugParameters - Structure - advanced setting.
//
// Returns:
//  Query - configured request object for receiving movements on the upr. balance.
//
Function RequestRegisteredRecords(MotionParameters, DebugParameters = Undefined) Export
	
	InitializeMotionParameters(MotionParameters, DebugParameters);
	
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	
	RequestRegisteredRecords = RequestRegisteredRecordsDirections(MotionParameters);
	If RequestRegisteredRecords.Parameters.AllTables.Count() > 0 Then
		AddQueryTextForTemporaryBalanceControlTables(RequestRegisteredRecords);
		If GetFunctionalOption("GenerateFinancialResult") Then
			AddCashFlowQueryText(RequestRegisteredRecords);
			AddRequestTextForInputOutputRegisteredRecordsByDirection(RequestRegisteredRecords);
		EndIf;
		AddQueryTextForAssetLiabilityRegisteredRecords(RequestRegisteredRecords);
		
		TemporaryTableNames = StrConcat(RequestRegisteredRecords.Parameters.AllTables, ",");
		TemporaryTableNames = StrReplace(TemporaryTableNames,",SampleResult","");
		RequestRegisteredRecords.SetParameter("TemporaryTableNames", TemporaryTableNames);
	EndIf;
	
	RequestRegisteredRecords.Text = StrConcat(RequestRegisteredRecords.Parameters.QueriesTexts, TheSeparatorQueries());
	RequestRegisteredRecords.Parameters.Delete("QueriesTexts");
	
	AddMeasurement(MotionParameters.Protocol.Measurements, "RequestAssembly", MeasurementStart);
	
	If IsBlankString(RequestRegisteredRecords.Text) Then
		Return Undefined;
	EndIf;
	Return RequestRegisteredRecords;
	
EndFunction

// Reflects the transferred documents in the management balance sheet
//
// Parameters:
//  DocumentsToBeReflected - DocumentRef, Array of DocumentRef, TempTablesManager - documents to be reflected in the Man. balance sheet
//                        If the temporary table manager is passed, 
//                        then by default the temporary table containing the registrars should have the name
//                        "Reflection Document" and contain the "Registrar" field, otherwise, in the additional parameters,
//                        in the "Registrars Table" key, a structure with a description of the temporary table can be passed.
//                        The structure should have the following keys: Table name, Logger field.
//  TablesForRegisteredRecords - Structure - The names of the balance registers are transmitted in the structure keys. 
//                       If it is not transmitted, then a sample request will be generated for all
//                       balance registers in the system for the transmitted documents. List of balance registers See Enum.SourcesOfBalanceSheetStatement.
//
Procedure ReflectDocumentsInManagementBalanceSheet(DocumentsToBeReflected, TablesForRegisteredRecords = Undefined, AdditionalParameters = Undefined) Export
	
	MovementData = DataOfRegisteredRecordsOfReflectionOfDocumentsInManagementBalanceSheet(DocumentsToBeReflected, TablesForRegisteredRecords,
		AdditionalParameters);
	
	If MovementData <> Undefined Then
		SelectionByDocuments = MovementData.Select(QueryResultIteration.ByGroups);
		While SelectionByDocuments.Next() Do
			RecordRegisteredRecordsOfOtherAssetsLiabilities(SelectionByDocuments);
		EndDo;
	EndIf;
	
EndProcedure

// The data of Registered Records of the reflection of documents in the management balance sheet.
// 
// Parameters:
//  DocumentsToBeReflected - DocumentRef, Array of DocumentRef, TempTablesManager - documents to be reflected in the Man. balance sheet
//                        If the temporary table manager is passed, 
//                        then by default the temporary table containing the registrars should have the name
//                        "Reflection Document" and contain the "Registrar" field, otherwise, in the additional parameters,
//                        in the "Registrars Table" key, a structure with a description of the temporary table can be passed.
//                        The structure should have the following keys: Table name, Logger field.
//  TablesForRegisteredRecords - Structure - The names of the balance registers are transmitted in the structure keys. 
//                       If it is not transmitted, then a sample request will be generated for all
//                       balance registers in the system for the transmitted documents. List of balance registers See Enum.SourcesOfBalanceSheetStatement
//  AdditionalParameters - Undefined, Structure - Additional parameters for RegisteringRecorded movements
// 
// Returns:
//  Undefined, QueryResult - The Registered Records data for the reflection of documents in the management balance sheet
//
Function DataOfRegisteredRecordsOfReflectionOfDocumentsInManagementBalanceSheet(DocumentsToBeReflected, TablesForRegisteredRecords = Undefined,
	AdditionalParameters = Undefined) Export
	
	MotionParameters = New Structure;
	MotionParameters.Insert("TypeOfDeferredCalculation", Enums.MovementSourcesKinds.BalanceCalculation);
	MotionParameters.Insert("SamplingByRegistrar", True);
	MotionParameters.Insert("DocumentsToBeReflected",   DocumentsToBeReflected);
	If AdditionalParameters <> Undefined Then
		For Each Parameter In AdditionalParameters Do
			MotionParameters.Insert(Parameter.Key, Parameter.Value);
		EndDo;
	EndIf;
	If TablesForRegisteredRecords <> Undefined Then
		MotionParameters.Insert("TablesForRegisteredRecords", TablesForRegisteredRecords);
	EndIf;
	
	RequestRegisteredRecords = RequestRegisteredRecords(MotionParameters);
	
	MovementData = Undefined;
	If RequestRegisteredRecords <> Undefined Then
		MovementData = RequestRegisteredRecords.Execute();
	EndIf;// Request for asset movements/liabilities prepared without errors
	
	Return MovementData;
	
EndFunction

// Write down the register records "Register Records Counterparty - Counterparty"
// 
// Parameters:
//  Fetchingdocuments - fetchingresultsquestions - Fetching by registrars

//
Procedure RecordRegisteredRecordsOfOtherAssetsLiabilities(SelectionByDocuments) Export
	
	TypesOfLoggers = Metadata.AccumulationRegisters.OtherAssetsLiabilities.StandardAttributes.Recorder.Type;
	If Not TypesOfLoggers.ContainsType(TypeOf(SelectionByDocuments.Recorder)) Then
		Return;
	EndIf;
	
	RecordSet = AccumulationRegisters.OtherAssetsLiabilities.CreateRecordSet();
	RecordSet.Filter.Recorder.Set(SelectionByDocuments.Recorder);
	Selection = SelectionByDocuments.Select();
	While Selection.Next() Do
		FillPropertyValues(RecordSet.Add(), Selection);
	EndDo;
	If RecordSet.Count() > 0 Then
		RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
		RecordSet.AdditionalProperties.Insert("DonTRegisterNonOperationalQueueTasks");
		RecordSet.Write();
	EndIf;
	
EndProcedure

// Service procedure used in update handlers.
// Returns a list of management balance source registers.
//
// Returns:
//  Structure - balance registers that form the management balance sheet
// 
Function BalanceRegisters(IncludingOnlineCalculations = False) Export
	
	Exceptions = New Map;
	If Not IncludingOnlineCalculations Then
		Exceptions.Insert("CustomersARAPAccounting", True);
		Exceptions.Insert("VendorsARAPAccounting", True);
	EndIf;
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		Exceptions.Insert("CustomersARAPAccountingByDocuments", True);
		Exceptions.Insert("VendorsARAPAccountingByDocuments", True);
	Else
		Exceptions.Insert("CustomersARAPAccountingByDueDates", True);
		Exceptions.Insert("VendorsARAPAccountingByDueDates", True);
	EndIf;
	
	Tables = New Structure;
	SourcesOfBalance = Metadata.Enums.SourcesOfBalanceSheetStatement;
	For Each Source In SourcesOfBalance.EnumValues Do
		If Exceptions[Source.Name] = True Then
			Continue;
		EndIf;
		If Metadata.AccumulationRegisters.Find(Source.Name) = Undefined Then
			Continue;
		EndIf;
		Tables.Insert(Source.Name, True);
	EndDo;
	Return Tables;
	
EndFunction

// generates and records movements according to the register of other active arrays
// The principle of the formation of movements, see the presentation of the project https://partners.v8.1c.ru/forum/topic/1484492#m_1484492 
//
// Parameters:
//  DocumentReference - DocumentRef, Structure of KeyAndValue - the link of the document for which it is necessary to generate and record the movements of the balance control:
//                                      * Ref - DocumentRef
//  RegisterRecords - Structure of KeyAndValue:
//               * Key - String- Register name
//               * Value - AccumulationRegisterRecordSet.OtherAssetsLiabilities
//             Collections of movements - sets of register entries of a document stored in a collection of movements or a structure simulating this collection.
//
Procedure UpdateDocumentRegisteredRecords(DocumentReference, RegisterRecords) Export
	
	If TypeOf(RegisterRecords) = Type("RegisterRecordsCollection") 
		And RegisterRecords.Find("OtherAssetsLiabilities") = Undefined Then
		Return;
	EndIf;
	
	AddDocumentRegisteredRecords(DocumentReference, RegisterRecords);
	If TypeOf(RegisterRecords) = Type("RegisterRecordsCollection") And RegisterRecords.OtherAssetsLiabilities.Count() > 0 Then
		RegisterRecords.OtherAssetsLiabilities.AdditionalProperties.Insert("FormationOfManagementBalance");
		RegisterRecords.OtherAssetsLiabilities.Write();
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfFormationOfManagementBalanceSheetRegisteredRecords

#Region GenerateRequestForRegisteredRecordsOfAssetsAndLiabilities

// Request for direction movements.
// 
// Parameters:
//  Parameters - Structure - Parameters:
// * Ref - DocumentRef, Structure of KeyAndValue -
// * TablesForRegisteredRecords - Structure, ValueTable -:
// ** TimeOfUnloadingOfCalculationsAccordingToDocuments - Number -
// 
// Returns:
//  Query
Function RequestRegisteredRecordsDirections(Parameters)
	
	Query = Parameters.RequestRegisteredRecords;
	Query.SetParameter("QueriesTexts", New Array);
	
	PrimaryRegisteredRecords = Parameters.TablesForRegisteredRecords;
	ThereAreSettlementsWithClientsOnDocuments = ThereAreCalculationsOnDocuments(PrimaryRegisteredRecords, "CustomersARAPAccounting");
	ThereAreSettlementsWithSuppliersAccordingToDocuments = ThereAreCalculationsOnDocuments(PrimaryRegisteredRecords, "VendorsARAPAccounting");
	For Each RegisterRecords In PrimaryRegisteredRecords Do
		
		TableName = RegisterRecords.Key;
		Prefix = "Table";
		If StrStartsWith(TableName, Prefix) Then
			TableName = Right(TableName, StrLen(TableName)-StrLen(Prefix));
		EndIf;
		
		If TableName = "BankAccountCash" Then
			AddRequestTextFunds(Query, RegisterRecords.Value, "BankAccountPayments_");
			
		ElsIf TableName = "CashAccountBalance" Then
			AddRequestTextFunds(Query, RegisterRecords.Value, "CashPayment");
			
		ElsIf TableName = "CashInCashRegistersCR" Then
			AddTextOfRequestFundsInCashCashRegister(Query, RegisterRecords.Value);
			
		ElsIf TableName = "CashInTransit" Then
			AddRequestTextFundsInTransit(Query, RegisterRecords.Value);
			
		ElsIf TableName = "AdvanceHolderCash" Then
			AddTextOfRequestFundsFromAccountablePersons(Query, RegisterRecords.Value);

		ElsIf TableName = "CustomersARAPAccountingByDueDates" Then
			AddRequestTextSettlementsWithCustomersByDueDate(Query, RegisterRecords.Value);
			
		ElsIf TableName = "CustomersARAPAccountingByDocuments" Then
			AddRequestTextSettlementsWithDocumentPartners(Query, RegisterRecords.Value, "CustomersARAPAccounting");
			
		ElsIf TableName = "CustomersARAPAccounting" And (Not ThereAreSettlementsWithClientsOnDocuments Or Parameters.RegisterFilling) Then
			AddRequestTextSettlementsWithPartners(Query, RegisterRecords.Value, "CustomersARAPAccounting");
			
		ElsIf TableName = "VendorsARAPAccountingByDueDates" Then
			AddRequestTextSettlementsWithSuppliersByDeadline(Query, RegisterRecords.Value);
			
		ElsIf TableName = "VendorsARAPAccountingByDocuments" Then
			AddRequestTextSettlementsWithDocumentPartners(Query, RegisterRecords.Value, "VendorsARAPAccounting");
			
		ElsIf TableName = "VendorsARAPAccounting" And (Not ThereAreSettlementsWithSuppliersAccordingToDocuments Or Parameters.RegisterFilling) Then
			AddRequestTextSettlementsWithPartners(Query, RegisterRecords.Value, "VendorsARAPAccounting");
		
		ElsIf TableName = "FinancialInstrumentsARAP" Then
			AddQueryTextSettlementsOnFinancialInstruments(Query, RegisterRecords.Value);
		
		ElsIf TableName = "GiftCertificates" Then
			AddRequestTextGiftCertificates(Query, RegisterRecords.Value);
			
		ElsIf TableName = "TransferredReturnablePackaging" Then
			AddRequestTextPassedReturnContainer(Query, RegisterRecords.Value);
			
		ElsIf TableName = "ReceivedReturnablePackaging" Then
			AddRequestTextAcceptedReturnContainer(Query, RegisterRecords.Value);
			
		ElsIf TableName = "OtherIncome" Then
			AddQueryTextOtherIncome(Query, RegisterRecords.Value);
			
		ElsIf TableName = "OtherExpenses" Then
			AddQueryTextOtherExpenses(Query, RegisterRecords.Value);
			
		ElsIf TableName = "InventoryCost" Then
			AddQueryTextCostOfGoods(Query, RegisterRecords.Value);
			
		ElsIf TableName = "GoodsCostVariances" Then
			AddQueryTextForDeviationsInCostOfGoods(Query, RegisterRecords.Value);
			
		ElsIf TableName = "GoodsToBeRegisteredInReportsToConsignor" Then
			AddTextOfProductsRequestToCommitteeSReportingFormat(Query, RegisterRecords.Value);
			
		ElsIf TableName = "ServicesForRegistrationOfReportsToPrincipal" Then
			AddTextOfServiceRequestToDesignOfReportsToPrincipal(Query, RegisterRecords.Value);
		
		ElsIf TableName = "GoodsAndServicesToRegisterPurchasingReportsToConsignor" Then
			AddQueryTextOfGoodsAndServicesToCommitteeSProcurementReports(Query, RegisterRecords.Value);
		ElsIf TableName = "WIPLaborCosts" Then
			AddQueryTextWorkInProgress(Query, RegisterRecords.Value);
			
		ElsIf TableName = "FixedAssetsDepreciationCharge" Then
			AddQueryTextDepreciationFA(Query, RegisterRecords.Value);
			
		ElsIf TableName = "FACost" Then
			AddFACostRequestText(Query, RegisterRecords.Value);
			
		ElsIf TableName = "IntangibleAssetsAmortizationCharge" Then
			AddQueryTextDepreciationIA(Query, RegisterRecords.Value);
			
		ElsIf TableName = "IACost" Then
			AddQueryTextCostOfIa(Query, RegisterRecords.Value);
			
		ElsIf TableName = "ImpairmentFA" Then
			AddTextOfRequestDevaluationOfVNA(Query, RegisterRecords.Value);
			
		ElsIf TableName = "OtherWorkInProgressExpenses" Then
			AddQueryTextOtherWorkInProgressExpenses(Query, RegisterRecords.Value);
			
		ElsIf TableName = "LossAllowance" Then
			AddQueryTextProvisionsForDoubtfulDebts(Query, RegisterRecords.Value);

		ElsIf TableName = "InvestmentInRent" Then
			AddQueryTextForInvestmentInRent(Query, RegisterRecords.Value);
		ElsIf TableName = "DiscountInterestExpense" Then
			AddQueryTextInterestExpenseDiscounting(Query, RegisterRecords.Value);
			
		ElsIf TableName = "OtherAssetsLiabilities" Then
			AddQueryTextOtherAssetsLiabilities(Query, RegisterRecords.Value);
			
		ElsIf TableName = "RegisterRecordsByExcises" Then
			AddQueryTextOfRegisteredRecordsForExciseTaxes(Query, RegisterRecords.Value);
			
		EndIf;
		
	EndDo;// according to the tables of primary movements
	
	Return Query;
	
EndFunction

#Region TrafficRequestTextsByRegister

// Designintelligence
// Designessentials
// Leninismmaoism
Procedure AddRequestTextFunds(Query, RegisterRecordTable, CashType_)
	
	TableName = "BankAccountCash";
	If CashType_ = "CashPayment" Then
		TableName = "CashAccountBalance";
	EndIf;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
		
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText = 
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.BankAccount AS BankAccount,
		|	T.SumMan AS SumMan,
		|	T.ReversingEntry AS ReversingEntry
		|	
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.SumMan <> 0";
		If CashType_ = "CashPayment" Then
			QueryText = StrReplace(QueryText, "BankAccount", "CashAccount");
		EndIf;
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
		
	EndIf;
	
	QueryText = 
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	CashStorageLocations.Department AS Department,
	|	CashStorageLocations.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceBankAccountCash) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.SumMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.SumMan ELSE T.SumMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry,
	|	CASE WHEN CashStorageLocations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS EmptyDirection
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS CashStorageLocations
	|	ON T.BankAccount = CashStorageLocations.Ref
	|WHERE
	|	T.SumMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Period,
	|	T.Recorder,
	|	T.Organization,
	|	T.RecordType,
	|	CashStorageLocations.Department,
	|	CashStorageLocations.LineOfBusiness,
	|	T.BankAccount,
	|	T.ReversingEntry";
	
	If CashType_ = "CashPayment" Then
		QueryText = StrReplace(QueryText, "ManBalanceBankAccountCash", "ManBalanceCashAccountBalance");
		QueryText = StrReplace(QueryText, "CompaniesBankAccounts", "CashAccounts");
		QueryText = StrReplace(QueryText, "BankAccount", "CashAccount");
	EndIf;
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// CashInCashRegistersCR
Procedure AddTextOfRequestFundsInCashCashRegister(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.CashInCashRegistersCR.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
		
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText = 
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.CashRegister AS CashRegister,
		|	T.SumMan AS SumMan,
		|	T.ReversingEntry AS ReversingEntry
		|	
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.SumMan <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
		
	EndIf;
	
	QueryText = 
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	CashStorageLocations.Department AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashAccountBalance) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.SumMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.SumMan ELSE T.SumMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry,
	|	TRUE AS EmptyDirection
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN Catalog.CashRegisters AS CashStorageLocations
	|	ON T.CashRegister = CashStorageLocations.Ref
	|WHERE
	|	T.SumMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Period,
	|	T.Recorder,
	|	T.Organization,
	|	T.RecordType,
	|	CashStorageLocations.Department,
	|	T.CashRegister,
	|	T.ReversingEntry";
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// CashInTransit
Procedure AddRequestTextFundsInTransit(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.CashInTransit.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Recipient AS Recipient,
		|	T.SumMan AS SumMan,
		|	T.ReversingEntry AS ReversingEntry
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.SumMan <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
		
	Else
		PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(T.Recipient) = TYPE(Catalog.CompaniesBankAccounts)
	|			THEN ISNULL(CAST(T.Recipient AS Catalog.CompaniesBankAccounts).Department, VALUE(Catalog.BusinessStructure.EmptyRef))
	|		WHEN VALUETYPE(T.Recipient) = TYPE(Catalog.CashAccounts)
	|			THEN ISNULL(CAST(T.Recipient AS Catalog.CashAccounts).Department, VALUE(Catalog.BusinessStructure.EmptyRef))
	|		ELSE
	|			VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	CASE
	|		WHEN VALUETYPE(T.Recipient) = TYPE(Catalog.CompaniesBankAccounts)
	|			THEN ISNULL(CAST(T.Recipient AS Catalog.CompaniesBankAccounts).LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|		WHEN VALUETYPE(T.Recipient) = TYPE(Catalog.CashAccounts)
	|			THEN ISNULL(CAST(T.Recipient AS Catalog.CashAccounts).LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|		ELSE
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashInTransit) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.SumMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.SumMan ELSE T.SumMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.SumMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.Organization,
	|	T.Recipient,
	|	T.ReversingEntry";
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// AdvanceHolderCash
Procedure AddTextOfRequestFundsFromAccountablePersons(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.AdvanceHolderCash.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.SumMan AS SumMan,
		|	T.ReversingEntry AS ReversingEntry
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.SumMan <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAdvanceHolderCash) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.SumMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.SumMan ELSE T.SumMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.SumMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	T.ReversingEntry";
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// Settlement By Clients, Settlement By Suppliers
// 
// Parameters:
// 	Query - Query -
// 	RegisterRecordTable - ValueTable - 
// 	PaymentType_ - String - LongDesc
Procedure AddRequestTextSettlementsWithPartners(Query, RegisterRecordTable, PaymentType_)
	
	TableNameByDocuments = "CustomersARAPAccountingByDocuments";
	If PaymentType_ = "VendorsARAPAccounting" Then
		TableNameByDocuments = "VendorsARAPAccountingByDocuments";
	EndIf;
	ThereAreCalculationsOnDocuments = Query.Parameters.TablesOfRegisteredRecordsOfDirections.Find(TableNameByDocuments) <> Undefined;
	If ThereAreCalculationsOnDocuments And Not Query.Parameters.RegisterFilling Or Query.Parameters.NewSettlements Then
		Return;
	EndIf;
	
	TableName = PaymentType_;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ARAPObject AS ARAPObject,
		|	T.SumMan AS SumMan,
		|	T.ReversingEntry AS ReversingEntry
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.SumMan <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	PartnerAnalytics_.Organization AS Organization,
	|	T.ARAPObject.Department AS Department,
	|	T.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCustomersAccountsReceivable) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.SumMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.SumMan ELSE T.SumMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.PartnersARAPAccounting) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS PartnerAnalytics_
	|	ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
	|	AND &CalculationsAccordingToDocuments
	|WHERE
	|	T.SumMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Period,
	|	T.Recorder,
	|	PartnerAnalytics_.Organization,
	|	T.RecordType,
	|	T.ARAPObject.Department,
	|	T.ARAPObject.LineOfBusiness,
	|	T.ReversingEntry";
	
	If Query.Parameters.RegisterFilling Then
		QueryText = StrReplace(QueryText,
						"AND &CalculationsAccordingToDocuments",
						"LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDocuments AS CalculationsAccordingToDocuments
						|	ON T.Recorder = CalculationsAccordingToDocuments.Recorder");
		QueryText = StrReplace(QueryText,
						"AND &Filter",
						"AND CalculationsAccordingToDocuments.Recorder IS NULL
						|	AND &Filter");
	Else
		QueryText = StrReplace(QueryText,"AND &CalculationsAccordingToDocuments","");
	EndIf;
	
	If PaymentType_ = "VendorsARAPAccounting" Then
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
		QueryText = StrReplace(QueryText, "CustomersAccountsReceivable", "VendorAccountsReceivable");
	EndIf;
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords, "PartnerAnalytics_.Organization");
	
EndProcedure

// Resetaccountstat, Resetinputcontext
Procedure AddRequestTextSettlementsWithDocumentPartners(Query, RegisterRecordTable, PaymentType_)
	
	If Query.Parameters.NewSettlements Then
		Return;
	EndIf;
	
	TableName = "CustomersARAPAccountingByDocuments";
	If PaymentType_ = "VendorsARAPAccounting" Then
		TableName = "VendorsARAPAccountingByDocuments";
	EndIf;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.SalesOrder AS SalesOrder,
		|	T.ARAPMan AS ARAPMan,
		|	T.PrepaymentMan AS PrepaymentMan
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.ARAPMan <> 0 OR T.PrepaymentMan <> 0";
		
		If PaymentType_ = "VendorsARAPAccounting" Then
			QueryText = StrReplace(QueryText, "SalesOrder", "PurchaseOrder");
		EndIf;
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	PartnerAnalytics_.Organization AS Organization,
	|	T.SalesOrder.Department AS Department,
	|	T.SalesOrder.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN PartnerAnalytics_.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|			THEN &Article3OfOwnOrganizations
	|		ELSE
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCustomersAccountsReceivable)
	|	END AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.ARAPMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.ARAPMan ELSE T.ARAPMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.PartnersARAPAccounting) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	FALSE AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS PartnerAnalytics_
	|	ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
	|WHERE
	|	T.ARAPMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Period,
	|	T.Recorder,
	|	PartnerAnalytics_.Organization,
	|	T.RecordType,
	|	T.SalesOrder.Department,
	|	T.SalesOrder.LineOfBusiness,
	|	CASE
	|		WHEN PartnerAnalytics_.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|			THEN &Article3OfOwnOrganizations
	|		ELSE
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCustomersAccountsReceivable)
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	PartnerAnalytics_.Organization AS Organization,
	|	T.SalesOrder.Department AS Department,
	|	T.SalesOrder.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN PartnerAnalytics_.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|			THEN &ArticlePrepaymentsOfOwnOrganizations
	|		ELSE
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsFromCustomerLayout)
	|	END AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.PrepaymentMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.PrepaymentMan ELSE T.PrepaymentMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.PartnersARAPAccounting) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	FALSE AS ReversingEntry
	|
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS PartnerAnalytics_
	|	ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
	|WHERE
	|	T.PrepaymentMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Period,
	|	T.Recorder,
	|	PartnerAnalytics_.Organization,
	|	T.RecordType,
	|	T.SalesOrder.Department,
	|	T.SalesOrder.LineOfBusiness,
	|	CASE
	|		WHEN PartnerAnalytics_.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|			THEN &ArticlePrepaymentsOfOwnOrganizations
	|		ELSE
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsFromCustomerLayout)
	|	END";
	
	If PaymentType_ = "VendorsARAPAccounting" Then
		QueryText = StrReplace(QueryText, "SalesOrder", "PurchaseOrder");
		QueryText = StrReplace(QueryText, "CustomersAccountsReceivable", "VendorAccountsReceivable");
		QueryText = StrReplace(QueryText, "PrepaymentsFromCustomerLayout", "PrepaymentsToVendor_");
		QueryText = StrReplace(QueryText, "Article3OfOwnOrganizations", "Article3OfOwnOrganizationsSuppliers");
		QueryText = StrReplace(QueryText, "ArticlePrepaymentsOfOwnOrganizations", "ArticlePrepaymentsOfOwnOrganizationsSuppliers");
		Article3OfOwnOrganizationsSuppliers = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayblesIntercompnay;
		ArticlePrepaymentsOfOwnOrganizationsSuppliers = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnCompaniesARAP;
		Query.SetParameter("Article3OfOwnOrganizationsSuppliers", Article3OfOwnOrganizationsSuppliers);
		Query.SetParameter("ArticlePrepaymentsOfOwnOrganizationsSuppliers", ArticlePrepaymentsOfOwnOrganizationsSuppliers);
	EndIf;
	
	Article3OfOwnOrganizations = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnCompaniesARAP;
	ArticlePrepaymentsOfOwnOrganizations = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayblesIntercompnay;
	Query.SetParameter("Article3OfOwnOrganizations", Article3OfOwnOrganizations);
	Query.SetParameter("ArticlePrepaymentsOfOwnOrganizations", ArticlePrepaymentsOfOwnOrganizations);
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords, "PartnerAnalytics_.Organization");
	
EndProcedure

// Resetaccountstat, Reshetilovskaya
Procedure AddRequestTextSettlementsWithCustomersByDueDate(Query, RegisterRecordTable)
	
	TableName = "CustomersARAPAccountingByDueDates";
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS DocumentRecorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ARAPObject AS ARAPObject,
		|	T.ARAPMan AS ARAPMan,
		|	T.PrepaymentMan AS PrepaymentMan,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.BusinessOperation AS BusinessOperation
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.ARAPMan <> 0 OR T.PrepaymentMan <> 0
		|
		|INDEX BY
		|	AccountingDimensionByPartners";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|		T.DocumentRecorder AS Recorder,
	|		T.Period AS Period,
	|		PartnerAnalytics_.Organization AS Organization,
	|		T.ARAPObject AS ARAPObject,
	|		T.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		CASE
	|			WHEN PartnerAnalytics_.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|				THEN &Article3OfOwnOrganizationsClients
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCustomersAccountsReceivable)
	|		END AS AssetRef,
	|		UNDEFINED AS Dimension,
	|		T.ReversingEntry AS ReversingEntry,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.ARAPMan ELSE T.ARAPMan END AS Sum,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.ARAPMan ELSE T.ARAPMan END AS AmountOfBalance
	|INTO TableOfRegisteredRecordsOfClientsByTerms
	|	FROM
	|		PrimaryRegisteredRecords AS T
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS PartnerAnalytics_
	|		ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
	|	WHERE
	|		T.ARAPMan <> 0
	|		AND &Filter
	|
	|	UNION ALL
	|
	|	SELECT
	|		T.DocumentRecorder AS Recorder,
	|		T.Period AS Period,
	|		PartnerAnalytics_.Organization AS Organization,
	|		T.ARAPObject AS ARAPObject,
	|		T.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		CASE
	|			WHEN PartnerAnalytics_.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|				THEN &ArticlePrepaymentsOfOwnOrganizationsCustomers
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsFromCustomerLayout)
	|		END AS AssetRef,
	|		UNDEFINED AS Dimension,
	|		T.ReversingEntry AS ReversingEntry,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -T.PrepaymentMan ELSE T.PrepaymentMan END AS Sum,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -T.PrepaymentMan ELSE T.PrepaymentMan END AS AmountOfBalance
	|
	|	FROM
	|		PrimaryRegisteredRecords AS T
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS PartnerAnalytics_
	|		ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
	|	WHERE
	|		T.PrepaymentMan <> 0
	|		AND &Filter
	|
	|INDEX BY
	|	ARAPObject;
	|
	|SELECT
	|	NestedQuery.Recorder AS Recorder,
	|	CASE WHEN NestedQuery.Sum > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	NestedQuery.Period AS Period,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.AssetRef AS AssetRef,
	|	NestedQuery.Dimension AS Dimension,
	|	CASE WHEN NestedQuery.Sum > 0
	|		THEN NestedQuery.Sum
	|		ELSE -NestedQuery.Sum
	|	END AS Sum,
	|	NestedQuery.AmountOfBalance AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.PartnersARAPAccounting) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	NestedQuery.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM (
	|	SELECT
	|		T.Recorder AS Recorder,
	|		T.Period AS Period,
	|		T.Organization AS Organization,
	|		ARAPObjects.Department AS Department,
	|		T.LineOfBusiness AS LineOfBusiness,
	|		T.AssetRef AS AssetRef,
	|		T.Dimension AS Dimension,
	|		T.ReversingEntry AS ReversingEntry,
	|		SUM(T.Sum) AS Sum,
	|		SUM(T.AmountOfBalance) AS AmountOfBalance
	|
	|	FROM
	|		TableOfRegisteredRecordsOfClientsByTerms AS T
	|			LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|				ON T.ARAPObject = ARAPObjects.Ref
	|	
	|	GROUP BY
	|		T.Period,
	|		T.Recorder,
	|		T.Organization,
	|		ARAPObjects.Department,
	|		T.LineOfBusiness,
	|		T.AssetRef,
	|		T.Dimension,
	|		T.ReversingEntry)AS NestedQuery
	|
	|WHERE
	|	NestedQuery.Sum <> 0;
	|
	|DROP TableOfRegisteredRecordsOfClientsByTerms";
	
	Article3OfOwnOrganizationsClients = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnCompaniesARAP;
	ArticlePrepaymentsOfOwnOrganizationsCustomers = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayblesIntercompnay;
	Query.SetParameter("Article3OfOwnOrganizationsClients", Article3OfOwnOrganizationsClients);
	Query.SetParameter("ArticlePrepaymentsOfOwnOrganizationsCustomers", ArticlePrepaymentsOfOwnOrganizationsCustomers);
	
	AddLoggersConnection(Query, QueryText, PrimaryRegisteredRecords);
	QueryText  = StrReplace(QueryText,
						"T.Recorder = DocumentsToBeReflected.Recorder",
						"T.DocumentRecorder = DocumentsToBeReflected.Recorder");
	AddFilter(Query, QueryText, "PartnerAnalytics_.Organization", "T.DocumentRecorder");
	ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords);
	
	AddValueToParameter(Query, "QueriesTexts", QueryText);
	AddValueToParameter(Query, "TablesOfRegisteredRecordsOfDirections", TableName);
	AddValueToParameter(Query, "AllTables", TableName);
	
EndProcedure

Procedure AddRequestTextSettlementsWithSuppliersByDeadline(Query, RegisterRecordTable)
	
	TableName = "VendorsARAPAccountingByDueDates";
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS DocumentRecorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ARAPObject AS ARAPObject,
		|	T.ARAPMan AS ARAPMan,
		|	T.PrepaymentMan AS PrepaymentMan,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.BusinessOperation AS BusinessOperation
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.ARAPMan <> 0 OR T.PrepaymentMan <> 0
		|
		|INDEX BY
		|	AccountingDimensionByPartners";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|		T.DocumentRecorder AS Recorder,
	|		T.Period AS Period,
	|		PartnerAnalytics_.Organization AS Organization,
	|		T.ARAPObject AS ARAPObject,
	|		T.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		CASE
	|			WHEN PartnerAnalytics_.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|				THEN &Article3OfOwnOrganizationsSuppliers
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceVendorAccountsReceivable)
	|		END AS AssetRef,
	|		UNDEFINED AS Dimension,
	|		T.ReversingEntry AS ReversingEntry,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -T.ARAPMan ELSE T.ARAPMan END AS Sum,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -T.ARAPMan ELSE T.ARAPMan END AS AmountOfBalance
	|INTO TableOfRegisteredRecordsOfSuppliersByTerms
	|	FROM
	|		PrimaryRegisteredRecords AS T
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS PartnerAnalytics_
	|		ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
	|	WHERE
	|		T.ARAPMan <> 0
	|		AND &Filter
	|
	|	UNION ALL
	|
	|	SELECT
	|		T.DocumentRecorder AS Recorder,
	|		T.Period AS Period,
	|		PartnerAnalytics_.Organization AS Organization,
	|		T.ARAPObject AS ARAPObject,
	|		T.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		CASE
	|			WHEN PartnerAnalytics_.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|				THEN &ArticlePrepaymentsOfOwnOrganizationsSuppliers
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsToVendor_)
	|		END AS AssetRef,
	|		UNDEFINED AS Dimension,
	|		T.ReversingEntry AS ReversingEntry,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.PrepaymentMan ELSE T.PrepaymentMan END AS Sum,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.PrepaymentMan ELSE T.PrepaymentMan END AS AmountOfBalance
	|
	|	FROM
	|		PrimaryRegisteredRecords AS T
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS PartnerAnalytics_
	|		ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
	|	WHERE
	|		T.PrepaymentMan <> 0
	|		AND &Filter
	|
	|INDEX BY
	|	ARAPObject
	|;
	|
	|SELECT
	|	NestedQuery.Recorder AS Recorder,
	|	CASE WHEN NestedQuery.Sum > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	NestedQuery.Period AS Period,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.AssetRef AS AssetRef,
	|	NestedQuery.Dimension AS Dimension,
	|	CASE WHEN NestedQuery.Sum > 0
	|		THEN NestedQuery.Sum
	|		ELSE -NestedQuery.Sum
	|	END AS Sum,
	|	NestedQuery.AmountOfBalance AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.PartnersARAPAccounting) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	NestedQuery.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM (
	|	SELECT
	|		T.Recorder AS Recorder,
	|		T.Period AS Period,
	|		T.Organization AS Organization,
	|		ARAPObjects.Department AS Department,
	|		T.LineOfBusiness AS LineOfBusiness,
	|		T.AssetRef AS AssetRef,
	|		T.Dimension AS Dimension,
	|		T.ReversingEntry AS ReversingEntry,
	|		SUM(T.Sum) AS Sum,
	|		SUM(T.AmountOfBalance) AS AmountOfBalance
	|	FROM
	|		TableOfRegisteredRecordsOfSuppliersByTerms AS T
	|			LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|				ON T.ARAPObject = ARAPObjects.Ref
	|
	|	GROUP BY
	|		T.Period,
	|		T.Recorder,
	|		T.Organization,
	|		ARAPObjects.Department,
	|		T.LineOfBusiness,
	|		T.AssetRef,
	|		T.Dimension,
	|		T.ReversingEntry)AS NestedQuery
	|
	|
	|WHERE
	|	NestedQuery.Sum <> 0;
	|
	|DROP TableOfRegisteredRecordsOfSuppliersByTerms";
	
	Article3OfOwnOrganizationsSuppliers = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceAccountsPayblesIntercompnay;
	ArticlePrepaymentsOfOwnOrganizationsSuppliers = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnCompaniesARAP;
	Query.SetParameter("Article3OfOwnOrganizationsSuppliers", Article3OfOwnOrganizationsSuppliers);
	Query.SetParameter("ArticlePrepaymentsOfOwnOrganizationsSuppliers", ArticlePrepaymentsOfOwnOrganizationsSuppliers);
	
	AddLoggersConnection(Query, QueryText, PrimaryRegisteredRecords);
	QueryText  = StrReplace(QueryText,
						"T.Recorder = DocumentsToBeReflected.Recorder",
						"T.DocumentRecorder = DocumentsToBeReflected.Recorder");
	AddFilter(Query, QueryText, "PartnerAnalytics_.Organization", "T.DocumentRecorder");
	ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords);
	
	AddValueToParameter(Query, "QueriesTexts", QueryText);
	AddValueToParameter(Query, "TablesOfRegisteredRecordsOfDirections", TableName);
	AddValueToParameter(Query, "AllTables", TableName);
	
EndProcedure

// FinancialInstrumentsARAP
Procedure AddQueryTextSettlementsOnFinancialInstruments(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.FinancialInstrumentsARAP.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.Contract AS Contract,
		|	T.AmountType AS AmountType,
		|	T.SumMan AS SumMan,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.BusinessOperation AS BusinessOperation
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.SumMan <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	ContractData.Organization AS Organization,
	|	ContractData.Department AS Department,
	|	ContractData.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN ContractData.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLoansPayables)
	|		WHEN ContractData.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceDepositsInBanks)
	|		WHEN ContractData.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings)
	|	END AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.SumMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.SumMan ELSE T.SumMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN Catalog.LoanAndDepositContracts AS ContractData
	|	ON T.Contract = ContractData.Ref
	|WHERE
	|	T.SumMan <> 0
	|	AND T.Contract REFS Catalog.LoanAndDepositContracts
	|	AND &Filter
	|
	|GROUP BY
	|	T.Period,
	|	T.Recorder,
	|	ContractData.Organization,
	|	T.RecordType,
	|	ContractData.ContractKind,
	|	ContractData.Department,
	|	ContractData.LineOfBusiness,
	|	T.ReversingEntry
	|
	|UNION ALL
	|
	|SELECT
	|	NestedQuery.Recorder AS Recorder,
	|	NestedQuery.RecordType AS RecordType,
	|	NestedQuery.Period AS Period,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.AssetRef AS AssetRef,
	|	NestedQuery.Dimension AS Dimension,
	|	SUM(NestedQuery.Sum) AS Sum,
	|	SUM(NestedQuery.AmountOfBalance) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	NestedQuery.ReversingEntry AS ReversingEntry
	|FROM
	|	(SELECT
	|		T.Recorder AS Recorder,
	|		T.RecordType AS RecordType,
	|		T.Period AS Period,
	|		ContractData.Organization AS Organization,
	|		ContractData.Department AS Department,
	|		ContractData.LineOfBusiness AS LineOfBusiness,
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing) AS AssetRef,
	|		T.Contract AS Dimension,
	|		T.SumMan AS Sum,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.SumMan ELSE T.SumMan END AS AmountOfBalance,
	|		VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|		T.ReversingEntry AS ReversingEntry
	|	
	|	FROM
	|		PrimaryRegisteredRecords AS T
	|		LEFT JOIN Catalog.LeaseContract AS ContractData
	|		ON T.Contract = ContractData.Ref
	|	WHERE
	|		T.SumMan <> 0
	|		AND T.Contract REFS Catalog.LeaseContract
	|		AND T.AmountType <> VALUE(Enum.TypesOfLeasePayments.VAT)
	|		AND &Filter
	|
	|	UNION ALL
	|
	|	SELECT
	|		T.Recorder AS Recorder,
	|		T.RecordType AS RecordType,
	|		T.Period AS Period,
	|		ContractData.Organization AS Organization,
	|		ContractData.Department AS Department,
	|		ContractData.LineOfBusiness AS LineOfBusiness,
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|		T.Contract AS Dimension,
	|		T.SumMan AS Sum,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.SumMan ELSE T.SumMan END AS AmountOfBalance,
	|		VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|		T.ReversingEntry AS ReversingEntry
	|	
	|	FROM
	|		PrimaryRegisteredRecords AS T
	|		LEFT JOIN Catalog.LeaseContract AS ContractData
	|		ON T.Contract = ContractData.Ref
	|	WHERE
	|		T.SumMan <> 0
	|		AND T.Contract REFS Catalog.LeaseContract
	|		AND T.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|		AND VALUETYPE(T.Recorder) IN (
	|			TYPE(Document.SigningOfLeaseContract),
	|			TYPE(Document.LeaseTermAdjustment),
	|			TYPE(Document.LeaseTermination),
	|			TYPE(Document.ExchangeDifferenceCalculation))
	|		AND &Filter
	|) AS NestedQuery
	|	
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.Recorder,
	|	NestedQuery.Organization,
	|	NestedQuery.AssetRef,
	|	NestedQuery.Dimension,
	|	NestedQuery.RecordType,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ReversingEntry
	|";
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords, "ContractData.Organization");
	
EndProcedure

// GiftCertificates
Procedure AddRequestTextGiftCertificates(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.GiftCertificates.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Sum AS Sum,
		|	T.GiftCertificate AS GiftCertificate,
		|	T.ReversingEntry AS ReversingEntry
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.Sum <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"SELECT
	|	T.Recorder AS Recorder,
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	T.Period AS Period,
	|	ISNULL(T.GiftCertificate.Organization.LocalAccountingCurrency, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	T.GiftCertificate.Organization AS Organization,
	|	T.ReversingEntry AS ReversingEntry,
	|	SUM(T.Sum) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN T.Sum ELSE -T.Sum END) AS AmountOfBalance
	|
	|INTO TTRegisterDataGiftCertificates
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.Sum <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.GiftCertificate.Organization.LocalAccountingCurrency,
	|	T.GiftCertificate.Organization,
	|	T.ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	ISNULL(ExchangeRates.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	ISNULL(ExchangeRates.BaseCurrency, VALUE(Catalog.Currencies.EmptyRef)) AS BaseCurrency,
	|	MAX(ExchangeRates.Period) AS Period,
	|	ManExchangeRates.Currency AS CurrencyOfMan,
	|	ManExchangeRates.BaseCurrency AS ManSBaseCurrency,
	|	MAX(ManExchangeRates.Period) AS ManPeriod
	|INTO TTGiftCertificates
	|FROM
	|	TTRegisterDataGiftCertificates AS T
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON T.Currency = ExchangeRates.Currency
	|			AND T.Currency = ExchangeRates.BaseCurrency
	|			AND T.Period >= ExchangeRates.Period
	|		
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|			AND T.Currency = ManExchangeRates.BaseCurrency
	|			AND T.Period >= ManExchangeRates.Period
	|
	|GROUP BY
	|	T.Recorder,
	|	ExchangeRates.BaseCurrency,
	|	ExchangeRates.Currency,
	|	ManExchangeRates.BaseCurrency,
	|	ManExchangeRates.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPeriods.Recorder AS Recorder,
	|	TTPeriods.Period AS Period,
	|	TTPeriods.Currency AS Currency,
	|	ISNULL(ExchangeRates.CourseNumerator, 0) / ISNULL(ExchangeRates.CourseDenominator, 1)* ISNULL(ManExchangeRates.CourseDenominator, 0) / ISNULL(ManExchangeRates.CourseNumerator, 1) AS ManSCoefficient,
	|	ISNULL(ExchangeRates.CourseNumerator, 1) AS ExchangeRateCurrencyNumerator,
	|	ISNULL(ExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorOfCurrency,
	|	&ManagementAccountingCurrency AS CurrencyOfMan,
	|	ISNULL(ManExchangeRates.CourseNumerator, 1) AS ExchangeRateNumeratorOfManSCurrency,
	|	ISNULL(ManExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorCurrencyMan
	|INTO TTExchangeRatesGiftCertificates
	|FROM
	|	TTGiftCertificates AS TTPeriods
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON TTPeriods.Currency = ExchangeRates.Currency
	|			AND TTPeriods.Period = ExchangeRates.Period
	|			AND TTPeriods.BaseCurrency = ExchangeRates.BaseCurrency
	|		
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|			AND TTPeriods.ManPeriod = ManExchangeRates.Period
	|			AND TTPeriods.ManSBaseCurrency = ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalancePrepaymentsFromCustomerLayout) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	CASE WHEN T.Currency = ExchangeRates.Currency
	|		THEN T.Sum
	|		ELSE CAST(T.Sum * ExchangeRates.ManSCoefficient AS NUMBER(31,2))
	|	END AS Sum,
	|	CASE WHEN T.Currency = ExchangeRates.Currency
	|		THEN T.AmountOfBalance
	|		ELSE CAST(T.AmountOfBalance * ExchangeRates.ManSCoefficient AS NUMBER(31,2))
	|	END AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	TTRegisterDataGiftCertificates AS T
	|	INNER JOIN TTExchangeRatesGiftCertificates AS ExchangeRates
	|	ON T.Recorder = ExchangeRates.Recorder";
	
	QueryText = StrReplace(QueryText, "%1", TableName);
	AddValueToParameter(Query, "AllTables", "TTRegisterDataGiftCertificates");
	AddValueToParameter(Query, "AllTables", "TTGiftCertificates");
	AddValueToParameter(Query, "AllTables", "TTExchangeRatesGiftCertificates");
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure
 
// TransferredReturnablePackaging
Procedure AddRequestTextPassedReturnContainer(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.TransferredReturnablePackaging.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.DocumentTransfers_ AS DocumentTransfers_,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.DepositIsRequired AS DepositIsRequired,
		|	T.Sum AS Sum,
		|	T.ReversingEntry AS ReversingEntry
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.Sum <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.DocumentTransfers_.Currency AS Currency,
	|	T.DocumentTransfers_.Organization AS Organization,
	|	ISNULL(T.DocumentTransfers_.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	ISNULL(T.DocumentTransfers_.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	T.ReversingEntry AS ReversingEntry,
	|	SUM(T.Sum) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.Sum ELSE T.Sum END) AS AmountOfBalance
	|
	|INTO TTRegisterDataTransferredTare
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.Sum <> 0
	|	AND NOT T.DepositIsRequired
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.DocumentTransfers_.Currency,
	|	T.DocumentTransfers_.Organization,
	|	ISNULL(T.DocumentTransfers_.Department, VALUE(Catalog.BusinessStructure.EmptyRef)),
	|	ISNULL(T.DocumentTransfers_.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
	|	T.ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency,
	|	MAX(ExchangeRates.Period) AS Period,
	|	ManExchangeRates.Currency AS CurrencyOfMan,
	|	ManExchangeRates.BaseCurrency AS ManSBaseCurrency,
	|	MAX(ManExchangeRates.Period) AS ManPeriod
	|INTO TTTransferredPackaging
	|FROM
	|	TTRegisterDataTransferredTare AS T
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON T.Currency = ExchangeRates.Currency
	|			AND T.Period >= ExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|			AND T.Period >= ManExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ManExchangeRates.BaseCurrency
	|
	|GROUP BY
	|	T.Recorder,
	|	ExchangeRates.Currency,
	|	ExchangeRates.BaseCurrency,
	|	ManExchangeRates.Currency,
	|	ManExchangeRates.BaseCurrency 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPeriods.Recorder AS Recorder,
	|	TTPeriods.Period AS Period,
	|	TTPeriods.Currency AS Currency,
	|	ISNULL(ExchangeRates.CourseNumerator, 0) / ISNULL(ExchangeRates.CourseDenominator, 1)* ISNULL(ManExchangeRates.CourseDenominator, 0) / ISNULL(ManExchangeRates.CourseNumerator, 1) AS ManSCoefficient,
	|	ISNULL(ExchangeRates.CourseNumerator, 1) AS ExchangeRateCurrencyNumerator,
	|	ISNULL(ExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorOfCurrency,
	|	&ManagementAccountingCurrency AS CurrencyOfMan,
	|	ISNULL(ManExchangeRates.CourseNumerator, 1) AS ExchangeRateNumeratorOfManSCurrency,
	|	ISNULL(ManExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorCurrencyMan
	|INTO TTExchangeRatesTransferredTare
	|FROM
	|	TTTransferredPackaging AS TTPeriods
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON TTPeriods.Currency = ExchangeRates.Currency
	|			AND TTPeriods.Period = ExchangeRates.Period
	|			AND TTPeriods.BaseCurrency = ExchangeRates.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|			AND TTPeriods.ManPeriod = ManExchangeRates.Period
	|			AND TTPeriods.ManSBaseCurrency = ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCustomersAccountsReceivable) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	CAST(T.Sum * ExchangeRates.ManSCoefficient AS NUMBER(31,2)) AS Sum,
	|	CAST(T.AmountOfBalance * ExchangeRates.ManSCoefficient AS NUMBER(31,2)) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	TTRegisterDataTransferredTare AS T
	|	INNER JOIN TTExchangeRatesTransferredTare AS ExchangeRates
	|	ON T.Recorder = ExchangeRates.Recorder";
	
	QueryText = StrReplace(QueryText, "%1", TableName);
	AddValueToParameter(Query, "AllTables", "TTRegisterDataTransferredTare");
	AddValueToParameter(Query, "AllTables", "TTTransferredPackaging");
	AddValueToParameter(Query, "AllTables", "TTExchangeRatesTransferredTare");
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords, "T.DocumentTransfers_.Organization");
	
EndProcedure

// ReceivedReturnablePackaging
Procedure AddRequestTextAcceptedReturnContainer(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.ReceivedReturnablePackaging.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.DocumentInflow AS DocumentInflow,
		|	T.DepositIsRequired AS DepositIsRequired,
		|	T.Sum AS Sum,
		|	T.ReversingEntry AS ReversingEntry
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.Sum <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"SELECT
	|	T.Recorder AS Recorder,
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	T.Period AS Period,
	|	T.DocumentInflow.Currency AS Currency,
	|	T.DocumentInflow.Organization AS Organization,
	|	T.DocumentInflow.Department AS Department,
	|	CASE
	|		WHEN VALUETYPE(T.DocumentInflow) = TYPE(Document.VendorInvoice)
	|			THEN CAST(T.DocumentInflow AS Document.VendorInvoice).LineOfBusiness
	|		ELSE
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	T.ReversingEntry AS ReversingEntry,
	|	SUM(T.Sum) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN T.Sum ELSE -T.Sum END) AS AmountOfBalance
	|
	|INTO TTRegisterDataAcceptedPackaging
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.Sum <> 0
	|	AND NOT T.DepositIsRequired
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.DocumentInflow.Currency,
	|	T.DocumentInflow.Organization,
	|	T.DocumentInflow.Department,
	|	CASE
	|		WHEN VALUETYPE(T.DocumentInflow) = TYPE(Document.VendorInvoice)
	|			THEN CAST(T.DocumentInflow AS Document.VendorInvoice).LineOfBusiness
	|		ELSE
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END,
	|	T.ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency,
	|	MAX(ExchangeRates.Period) AS Period,
	|	ManExchangeRates.Currency AS CurrencyOfMan,
	|	ManExchangeRates.BaseCurrency AS ManSBaseCurrency,
	|	MAX(ManExchangeRates.Period) AS ManPeriod
	|INTO TTAcceptedPackaging
	|FROM
	|	TTRegisterDataAcceptedPackaging AS T
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON T.Currency = ExchangeRates.Currency
	|			AND T.Period >= ExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|			AND T.Period >= ManExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ManExchangeRates.BaseCurrency
	|
	|GROUP BY
	|	T.Recorder,
	|	ExchangeRates.Currency,
	|	ExchangeRates.BaseCurrency,
	|	ManExchangeRates.Currency,
	|	ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPeriods.Recorder AS Recorder,
	|	TTPeriods.Period AS Period,
	|	TTPeriods.Currency AS Currency,
	|	ISNULL(ExchangeRates.CourseNumerator, 0) / ISNULL(ExchangeRates.CourseDenominator, 1)* ISNULL(ManExchangeRates.CourseDenominator, 0) / ISNULL(ManExchangeRates.CourseNumerator, 1) AS ManSCoefficient,
	|	ISNULL(ExchangeRates.CourseNumerator, 1) AS ExchangeRateCurrencyNumerator,
	|	ISNULL(ExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorOfCurrency,
	|	&ManagementAccountingCurrency AS CurrencyOfMan,
	|	ISNULL(ManExchangeRates.CourseNumerator, 1) AS ExchangeRateNumeratorOfManSCurrency,
	|	ISNULL(ManExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorCurrencyMan
	|INTO TTExchangeRatesAcceptedTare
	|FROM
	|	TTAcceptedPackaging AS TTPeriods
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON TTPeriods.Currency = ExchangeRates.Currency
	|			AND TTPeriods.Period = ExchangeRates.Period
	|			AND TTPeriods.BaseCurrency = ExchangeRates.BaseCurrency
	|
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|			AND TTPeriods.ManPeriod = ManExchangeRates.Period
	|			AND TTPeriods.ManSBaseCurrency = ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceVendorAccountsReceivable) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	CAST(T.Sum * ExchangeRates.ManSCoefficient AS NUMBER(31,2)) AS Sum,
	|	CAST(T.AmountOfBalance * ExchangeRates.ManSCoefficient AS NUMBER(31,2)) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	TTRegisterDataAcceptedPackaging AS T
	|	INNER JOIN TTExchangeRatesAcceptedTare AS ExchangeRates
	|	ON T.Recorder = ExchangeRates.Recorder";
	
	AddValueToParameter(Query, "AllTables", "TTRegisterDataAcceptedPackaging");
	AddValueToParameter(Query, "AllTables", "TTAcceptedPackaging");
	AddValueToParameter(Query, "AllTables", "TTExchangeRatesAcceptedTare");
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords, "T.DocumentInflow.Organization");
	
EndProcedure

// OtherIncome
Procedure AddQueryTextOtherIncome(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.OtherIncome.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.CalculationOfCost AS CalculationOfCost,
		|	T.Sum AS Sum,
		|	T.ReversingEntry AS ReversingEntry
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.Sum <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.Sum) AS Sum,
	|	SUM(-T.Sum) AS AmountOfBalance,
	|	CASE WHEN VALUETYPE(T.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|		THEN VALUE(Enum.MovementSourcesKinds.PartnersARAPAccounting)
	|		ELSE VALUE(Enum.MovementSourcesKinds.CalculationOfCost)
	|	END AS SourceKind,
	|	&Source AS Source,
	|	T.CalculationOfCost AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.Sum <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.CalculationOfCost,
	|	T.ReversingEntry";
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// OtherExpenses
Procedure AddQueryTextOtherExpenses(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.OtherExpenses.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.CalculationOfCost AS CalculationOfCost,
		|	T.LotCalculation AS LotCalculation,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.Sum AS Sum,
		|	T.SumMan AS SumMan
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.Sum <> 0 OR T.SumMan <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	NestedQuery.Recorder AS Recorder,
	|	NestedQuery.RecordType AS RecordType,
	|	NestedQuery.Period AS Period,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.AssetRef AS AssetRef,
	|	NestedQuery.Dimension AS Dimension,
	|	SUM(NestedQuery.Sum) AS Sum,
	|	SUM(NestedQuery.AmountOfBalance) AS AmountOfBalance,
	|	CASE WHEN VALUETYPE(NestedQuery.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|		THEN VALUE(Enum.MovementSourcesKinds.PartnersARAPAccounting)
	|		ELSE VALUE(Enum.MovementSourcesKinds.CalculationOfCost)
	|	END AS SourceKind,
	|	&Source AS Source,
	|	NestedQuery.CalculationOfCost AS CalculationOfCost,
	|	NestedQuery.LotCalculation AS LotCalculation,
	|	NestedQuery.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	(SELECT
	|		T.Recorder AS Recorder,
	|		T.RecordType AS RecordType,
	|		T.Period AS Period,
	|		T.Organization AS Organization,
	|		T.Department AS Department,
	|		T.LineOfBusiness AS LineOfBusiness,
	|		CASE
	|			WHEN ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceDeferredExpenses)
	|			WHEN ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN 
	|					CASE 
	|						WHEN NOT (&UseVNA2_4 AND T.Period >= &StartDateOfAccountingIN2_4) // OS Accounting version 2.2
	|									AND VALUETYPE(T.Recorder) <> TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|							THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodExpenses)
	|						WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.Assets)
	|							THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssetsCapitalization)
	|						WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ConstructionObjects)
	|							THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCapitalizationOfConstructionObjects)
	|						WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.IntangibleAssets)
	|							THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCapitalizationOfIntangibleAssetsAndRD)
	|						ELSE
	|							VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodExpenses)
	|					END
	|			ELSE
	|				VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodExpenses)
	|		END AS AssetRef,
	|		CASE
	|			WHEN ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|					AND &UseVNA2_4 AND T.Period >= &StartDateOfAccountingIN2_4 // OS Accounting version 2.4
	|				THEN T.DimensionOfExpenses
	|			ELSE
	|				UNDEFINED
	|		END AS Dimension,
	|		T.Sum AS Sum,
	|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.Sum ELSE T.Sum END AS AmountOfBalance,
	|		T.CalculationOfCost AS CalculationOfCost,
	|		T.LotCalculation AS LotCalculation,
	|		T.ReversingEntry AS ReversingEntry
	|
	|	FROM
	|		PrimaryRegisteredRecords AS T
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON T.ExpenseItem = ExpenseItems.Ref
	|		LEFT JOIN Document.EntryOfCapitalAssetsBalance2_4 AS EnteringResiduesInNA2_4
	|		ON T.Recorder = EnteringResiduesInNA2_4.Ref
	|		LEFT JOIN Document.DisposeFixedAssets2_4 AS DisposeFixedAssets
	|		ON T.Recorder = DisposeFixedAssets.Ref
	|	WHERE
	|		T.Sum <> 0
	|		AND (T.BusinessOperation <> VALUE(Enum.BusinessTransactions.CloseFixedAssetWriteOffExpenses)
	|			OR VALUETYPE(DisposeFixedAssets.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems))
	|		AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.CloseFixedAssetSalesExpenses)
	|		AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.CloseFixedAssetSalesExpensesWithDeferredTitleTransfer)
	|		AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer)
	|		AND &Filter
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Recorder,
	|	NestedQuery.RecordType,
	|	NestedQuery.Period,
	|	NestedQuery.Organization,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.AssetRef,
	|	NestedQuery.Dimension,
	|	NestedQuery.CalculationOfCost,
	|	NestedQuery.LotCalculation,
	|	NestedQuery.ReversingEntry
	|
	|UNION ALL
	|
	|SELECT
	|	T.Recorder AS Recorder,
	|	CASE
	|		WHEN (T.Sum - T.SumMan) > 0 AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		WHEN (T.Sum - T.SumMan) > 0 AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		WHEN (T.Sum - T.SumMan) < 0 AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE 
	|			VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	CASE WHEN SUM(T.Sum - T.SumMan) > 0
	|		THEN SUM(T.Sum - T.SumMan)
	|		ELSE -SUM(T.Sum - T.SumMan)
	|	END AS Sum,
	|	CASE WHEN SUM(T.Sum - T.SumMan) > 0
	|		THEN SUM(T.Sum - T.SumMan)
	|		ELSE -SUM(T.Sum - T.SumMan)
	|	END AS AmountOfBalance,
	|	CASE WHEN VALUETYPE(T.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|		THEN VALUE(Enum.MovementSourcesKinds.PartnersARAPAccounting)
	|		ELSE VALUE(Enum.MovementSourcesKinds.CalculationOfCost)
	|	END AS SourceKind,
	|	&Source AS Source,
	|	T.CalculationOfCost AS CalculationOfCost,
	|	T.LotCalculation AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON T.ExpenseItem = ExpenseItems.Ref
	|WHERE
	|	T.Sum - T.SumMan <> 0
	|	AND VALUETYPE(T.Recorder) IN (
	|		TYPE(Document.FixedAssetsInitialRecognition2_4),
	|		TYPE(Document.RecognizeSubAssetsComponentsOfDepreciation),
	|		TYPE(Document.IntangibleAssetsInitialRecognition2_4),
	|		TYPE(Document.FixedAssetsCostAdditions2_4),
	|		TYPE(Document.AllocateVariancesToFixedAssetCost),
	|		TYPE(Document.IntangibleAssetImprovement),
	|		TYPE(Document.ProvideAssetsToLeasee2_4))
	|	AND T.Period >= &StartDateOfAccountingIN2_4
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	CASE
	|		WHEN (T.Sum - T.SumMan) > 0 AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		WHEN (T.Sum - T.SumMan) > 0 AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		WHEN (T.Sum - T.SumMan) < 0 AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE 
	|			VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	ExpenseItems.CostAllocationOptionManag,
	|	T.CalculationOfCost,
	|	T.LotCalculation,
	|	T.ReversingEntry
	|";
	

	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// InventoryCost
Procedure AddQueryTextCostOfGoods(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.InventoryCost.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.AccountingSection AS AccountingSection,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Cost AS Cost,
		|	T.AddExpensesForGoods AS AddExpensesForGoods,
		|	T.LaborCosts AS LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
		|	T.CalculationOfCost AS CalculationOfCost,
		|	T.LotCalculation AS LotCalculation,
		|	T.ReversingEntry AS ReversingEntry
		|
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.Cost + T.AddExpensesForGoods + T.LaborCosts + T.ItemizedFixedCostsIncludingVAT + T.ItemizedVariableCostsIncludingVAT <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	CASE
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN Dimension.Department
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN Dimension.WarehouseArea.Department
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|			THEN ISNULL(Contracts.Department, ISNULL(IntercampanyTreaties.Department, VALUE(Catalog.BusinessStructure.EmptyRef)))
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN Dimension.Contract.Department
	|		ELSE
	|			UNDEFINED
	|	END AS Department,
	|	CASE
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|			AND T.CorLineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN T.CorLineOfBusiness
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|				AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|			THEN ISNULL(Contracts.LineOfBusiness, ISNULL(IntercampanyTreaties.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		ELSE
	|			ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) 
	|				AND Dimension.WarehouseArea.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsInRetailSales)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) 
	|				AND Dimension.WarehouseArea.WarehouseStore = VALUE(Enum.TypesOfWarehouses.WholesaleWarehouse) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsAtWholesaleWarehouses)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) 
	|				AND Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Partner) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsToBeRegisteredInReportsToConsignor)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodExpenses)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsTransferredToTolling)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|			OR T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceWorkInProgress)
	|
	|		WHEN T.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsInTransit)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceUninvoicedDeliveries)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners) 
	|				AND Dimension.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsAtWholesaleWarehouses)
	|
	|		ELSE
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsTransferredToCommissionAgent)
	|	END AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.Cost + T.AddExpensesForGoods + T.LaborCosts + T.ItemizedFixedCostsIncludingVAT + T.ItemizedVariableCostsIncludingVAT) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -(T.Cost + T.AddExpensesForGoods + T.LaborCosts + T.ItemizedFixedCostsIncludingVAT + T.ItemizedVariableCostsIncludingVAT) ELSE (T.Cost + T.AddExpensesForGoods + T.LaborCosts + T.ItemizedFixedCostsIncludingVAT + T.ItemizedVariableCostsIncludingVAT) END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.CalculationOfCost) AS SourceKind,
	|	&Source AS Source,
	|	T.CalculationOfCost AS CalculationOfCost,
	|	T.LotCalculation AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN Catalog.InventoryKinds AS CorTypesOfStocks
	|	ON T.CorInventoryOwnerAttribute = CorTypesOfStocks.Ref
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON T.ItemsLocationAttributes = Dimension.Ref
	|	LEFT JOIN Catalog.Assignments AS Assignments
	|	ON Dimension.Purpose = Assignments.Ref
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|	ON CorTypesOfStocks.Contract = Contracts.Ref
	|	LEFT JOIN Catalog.IntercompanyContracts AS IntercampanyTreaties
	|	ON CorTypesOfStocks.Contract = IntercampanyTreaties.Ref
	|WHERE
	|	NOT T.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
	|						VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing))
	|	AND (T.Cost + T.AddExpensesForGoods + T.LaborCosts + T.ItemizedFixedCostsIncludingVAT + T.ItemizedVariableCostsIncludingVAT) <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.Organization,
	|	CASE
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN Dimension.Department
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN Dimension.WarehouseArea.Department
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|			THEN ISNULL(Contracts.Department, ISNULL(IntercampanyTreaties.Department, VALUE(Catalog.BusinessStructure.EmptyRef)))
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN Dimension.Contract.Department
	|		ELSE
	|			UNDEFINED
	|	END,
	|	CASE
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|			AND T.CorLineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN T.CorLineOfBusiness
	|		WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|				AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|			THEN ISNULL(Contracts.LineOfBusiness, ISNULL(IntercampanyTreaties.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		ELSE
	|			ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END,
	|	CASE
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) 
	|				AND Dimension.WarehouseArea.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsInRetailSales)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) 
	|				AND Dimension.WarehouseArea.WarehouseStore = VALUE(Enum.TypesOfWarehouses.WholesaleWarehouse) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsAtWholesaleWarehouses)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) 
	|				AND Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Partner) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsToBeRegisteredInReportsToConsignor)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodExpenses)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsTransferredToTolling)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|			OR T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceWorkInProgress)
	|
	|		WHEN T.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsInTransit)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceUninvoicedDeliveries)
	|
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners) 
	|				AND Dimension.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract) THEN
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsAtWholesaleWarehouses)
	|
	|		ELSE
	|			VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsTransferredToCommissionAgent)
	|	END,
	|	T.CalculationOfCost,
	|	T.LotCalculation,
	|	T.ReversingEntry
	|
	|HAVING
	|	SUM(T.Cost + T.AddExpensesForGoods + T.LaborCosts + T.ItemizedFixedCostsIncludingVAT + T.ItemizedVariableCostsIncludingVAT) <> 0";
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// GoodsCostVariances
Procedure AddQueryTextForDeviationsInCostOfGoods(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.GoodsCostVariances.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.CostVariancesIncludingVAT AS CostVariancesIncludingVAT,
		|	T.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|	T.CalculationOfCost AS CalculationOfCost,
		|	T.LotCalculation AS LotCalculation,
		|	T.ReversingEntry AS ReversingEntry
		|
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.CostVariancesIncludingVAT + T.AdditionalExpensesIncludingVAT <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.DeviationsInValueOfInventory) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.CostVariancesIncludingVAT + T.AdditionalExpensesIncludingVAT) AS Sum,
	|	SUM(CASE
	|		WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN
	|			-(T.CostVariancesIncludingVAT + T.AdditionalExpensesIncludingVAT)
	|		ELSE (T.CostVariancesIncludingVAT + T.AdditionalExpensesIncludingVAT) END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.CalculationOfCost) AS SourceKind,
	|	&Source AS Source,
	|	T.CalculationOfCost AS CalculationOfCost,
	|	T.LotCalculation AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	(T.CostVariancesIncludingVAT + T.AdditionalExpensesIncludingVAT) <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.CalculationOfCost,
	|	T.LotCalculation,
	|	T.ReversingEntry
	|
	|HAVING
	|	SUM(T.CostVariancesIncludingVAT + T.AdditionalExpensesIncludingVAT) <> 0";
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// GoodsToBeRegisteredInReportsToConsignor
Procedure AddTextOfProductsRequestToCommitteeSReportingFormat(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Organization AS Organization,
		|	T.Period AS Period,
		|	T.Currency AS Currency,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.RevenueAmount AS RevenueAmount,
		|	T.RevenueAmountMan AS RevenueAmountMan
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.RevenueAmount <> 0 OR T.RevenueAmountMan <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	T.Organization AS Organization,
	|	T.Period AS Period,
	|	T.Currency AS Currency,
	|	ISNULL(Contracts.Department, ISNULL(IntercampanyTreaties.Department, VALUE(Catalog.BusinessStructure.EmptyRef))) AS Department,
	|	ISNULL(Contracts.LineOfBusiness, ISNULL(IntercampanyTreaties.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
	|	T.ReversingEntry AS ReversingEntry,
	|	SUM(T.RevenueAmount) AS SumCurr,
	|	SUM(T.RevenueAmountMan) AS SumMan,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN T.RevenueAmount ELSE -T.RevenueAmount END) AS BalanceAmountShaft,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN T.RevenueAmountMan ELSE -T.RevenueAmountMan END) AS ManSBalanceAmount
	|
	|INTO TTRegisterDataReadyForRegistration
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|	ON T.InventoryOwnerAttribute = InventoryKinds.Ref
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|	ON InventoryKinds.Contract = Contracts.Ref
	|	LEFT JOIN Catalog.IntercompanyContracts AS IntercampanyTreaties
	|	ON InventoryKinds.Contract = IntercampanyTreaties.Ref
	|WHERE
	|	(T.RevenueAmount <> 0 OR T.RevenueAmountMan <> 0)
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Organization,
	|	T.Period,
	|	T.Currency,
	|	InventoryKinds.Organization,
	|	ISNULL(Contracts.Department, ISNULL(IntercampanyTreaties.Department, VALUE(Catalog.BusinessStructure.EmptyRef))),
	|	ISNULL(Contracts.LineOfBusiness, ISNULL(IntercampanyTreaties.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))),
	|	T.ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency,
	|	MAX(ExchangeRates.Period) AS Period,
	|	ManExchangeRates.Currency AS CurrencyOfMan,
	|	ManExchangeRates.BaseCurrency AS ManSBaseCurrency,
	|	MAX(ManExchangeRates.Period) AS ManPeriod
	|INTO TTProductsForRegistration
	|FROM
	|	TTRegisterDataReadyForRegistration AS T
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON T.Currency = ExchangeRates.Currency
	|			AND T.Period >= ExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|		
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|			AND T.Period >= ManExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ManExchangeRates.BaseCurrency
	|GROUP BY
	|	T.Recorder,
	|	ExchangeRates.Currency,
	|	ExchangeRates.BaseCurrency,
	|	ManExchangeRates.Currency,
	|	ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPeriods.Recorder AS Recorder,
	|	TTPeriods.Period AS Period,
	|	TTPeriods.Currency AS Currency,
	|	ISNULL(ExchangeRates.CourseNumerator, 0) / ISNULL(ExchangeRates.CourseDenominator, 1)* ISNULL(ManExchangeRates.CourseDenominator, 0) / ISNULL(ManExchangeRates.CourseNumerator, 1) AS ManSCoefficient,
	|	ISNULL(ExchangeRates.CourseNumerator, 1) AS ExchangeRateCurrencyNumerator,
	|	ISNULL(ExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorOfCurrency,
	|	&ManagementAccountingCurrency AS CurrencyOfMan,
	|	ISNULL(ManExchangeRates.CourseNumerator, 1) AS ExchangeRateNumeratorOfManSCurrency,
	|	ISNULL(ManExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorCurrencyMan
	|INTO TTExchangeRatesGoodsForRegistration
	|FROM
	|	TTProductsForRegistration AS TTPeriods
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON TTPeriods.Currency = ExchangeRates.Currency
	|			AND TTPeriods.Period = ExchangeRates.Period
	|			AND TTPeriods.BaseCurrency = ExchangeRates.BaseCurrency
	|		
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|			AND TTPeriods.ManPeriod = ManExchangeRates.Period
	|			AND TTPeriods.ManSBaseCurrency = ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceGoodsToBeRegisteredInReportsToConsignor) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	CASE
	|		WHEN T.SumMan <> 0
	|			THEN T.SumMan
	|		ELSE CAST(T.SumCurr * ExchangeRates.ManSCoefficient AS NUMBER(31,2))
	|	END AS Sum,
	|	CASE
	|		WHEN T.BalanceAmountShaft <> 0
	|			THEN T.BalanceAmountShaft
	|		ELSE CAST(T.BalanceAmountShaft * ExchangeRates.ManSCoefficient AS NUMBER(31,2))
	|	END AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	TTRegisterDataReadyForRegistration AS T
	|	INNER JOIN TTExchangeRatesGoodsForRegistration AS ExchangeRates
	|	ON T.Recorder = ExchangeRates.Recorder";
	
	AddValueToParameter(Query, "AllTables", "TTRegisterDataReadyForRegistration");
	AddValueToParameter(Query, "AllTables", "TTProductsForRegistration");
	AddValueToParameter(Query, "AllTables", "TTExchangeRatesGoodsForRegistration");
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords, "InventoryKinds.Organization");
	
EndProcedure

// ServicesForRegistrationOfReportsToPrincipal
Procedure AddTextOfServiceRequestToDesignOfReportsToPrincipal(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Currency AS Currency,
		|	T.Organization AS Organization,
		|	T.Terms AS Terms,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.RevenueAmount AS RevenueAmount,
		|	T.RevenueAmountMan AS RevenueAmountMan
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.RevenueAmount <> 0 OR T.RevenueAmountMan <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"SELECT
	|	T.Recorder AS Recorder,
	|	CASE
	|		WHEN T.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	T.Period AS Period,
	|	T.Currency AS Currency,
	|	T.Organization AS Organization,
	|	CASE
	|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN T.ItemsLocationAttributes.Department
	|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN T.ItemsLocationAttributes.WarehouseArea.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	ISNULL(T.Terms.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	T.ReversingEntry AS ReversingEntry,
	|	SUM(T.RevenueAmount) AS SumCurr,
	|	SUM(T.RevenueAmountMan) AS SumMan,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN T.RevenueAmount ELSE -T.RevenueAmount END) AS BalanceAmountShaft,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN T.RevenueAmountMan ELSE -T.RevenueAmountMan END) AS ManSBalanceAmount
	|INTO TTServiceRegisterDataForRegistration
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	(T.RevenueAmount <> 0 OR T.RevenueAmountMan <> 0)
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.Currency,
	|	T.Organization,
	|	CASE
	|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN T.ItemsLocationAttributes.Department
	|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN T.ItemsLocationAttributes.WarehouseArea.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END,
	|	ISNULL(T.Terms.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
	|	T.ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency,
	|	MAX(ExchangeRates.Period) AS Period,
	|	ManExchangeRates.Currency AS CurrencyOfMan,
	|	ManExchangeRates.BaseCurrency AS ManSBaseCurrency,
	|	MAX(ManExchangeRates.Period) AS ManPeriod
	|INTO TTServicesForRegistration_0
	|FROM
	|	TTServiceRegisterDataForRegistration AS T
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON T.Currency = ExchangeRates.Currency
	|			AND T.Period >= ExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON (ManExchangeRates.Currency = &ManagementAccountingCurrency)
	|			AND T.Period >= ManExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ManExchangeRates.BaseCurrency
	|
	|GROUP BY
	|	T.Recorder,
	|	ExchangeRates.Currency,
	|	ExchangeRates.BaseCurrency,
	|	ManExchangeRates.Currency,
	|	ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPeriods.Recorder AS Recorder,
	|	TTPeriods.Period AS Period,
	|	TTPeriods.Currency AS Currency,
	|	ISNULL(ExchangeRates.CourseNumerator, 0) / ISNULL(ExchangeRates.CourseDenominator, 1) * ISNULL(ManExchangeRates.CourseDenominator, 0) / ISNULL(ManExchangeRates.CourseNumerator, 1) AS ManSCoefficient,
	|	ISNULL(ExchangeRates.CourseNumerator, 1) AS ExchangeRateCurrencyNumerator,
	|	ISNULL(ExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorOfCurrency,
	|	&ManagementAccountingCurrency AS CurrencyOfMan,
	|	ISNULL(ManExchangeRates.CourseNumerator, 1) AS ExchangeRateNumeratorOfManSCurrency,
	|	ISNULL(ManExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorCurrencyMan
	|INTO TTExchangeRatesOfServicesForRegistration
	|FROM
	|	TTServicesForRegistration_0 AS TTPeriods
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON TTPeriods.Currency = ExchangeRates.Currency
	|			AND TTPeriods.Period = ExchangeRates.Period
	|			AND TTPeriods.BaseCurrency = ExchangeRates.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON (ManExchangeRates.Currency = &ManagementAccountingCurrency)
	|			AND TTPeriods.ManPeriod = ManExchangeRates.Period
	|			AND TTPeriods.ManSBaseCurrency = ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceServicesForRegistrationOfReportsToPrincipal) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	CASE
	|		WHEN T.SumMan <> 0
	|			THEN T.SumMan
	|		ELSE CAST(T.SumCurr * ExchangeRates.ManSCoefficient AS NUMBER(31,2))
	|	END AS Sum,
	|	CASE
	|		WHEN T.ManSBalanceAmount <> 0
	|			THEN T.SumMan
	|		ELSE CAST(T.BalanceAmountShaft * ExchangeRates.ManSCoefficient AS NUMBER(31,2))
	|	END AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	TTServiceRegisterDataForRegistration AS T
	|		INNER JOIN TTExchangeRatesOfServicesForRegistration AS ExchangeRates
	|		ON T.Recorder = ExchangeRates.Recorder";
	
	AddValueToParameter(Query, "AllTables", "TTServiceRegisterDataForRegistration");
	AddValueToParameter(Query, "AllTables", "TTServicesForRegistration_0");
	AddValueToParameter(Query, "AllTables", "TTExchangeRatesOfServicesForRegistration");
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords, "InventoryKinds.Organization");
	
EndProcedure

// GoodsAndServicesToRegisterPurchasingReportsToConsignor
Procedure AddQueryTextOfGoodsAndServicesToCommitteeSProcurementReports(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Currency AS Currency,
		|	T.Organization AS Organization,
		|	T.Purpose AS Purpose,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.AmountIncludingVAT AS AmountIncludingVAT,
		|	T.SumMan AS SumMan
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.AmountIncludingVAT <> 0 OR T.SumMan <> 0
		|";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Currency AS Currency,
	|	T.Organization AS Organization,
	|	T.Purpose.Contract.Department AS Department,
	|	T.Purpose.Contract.LineOfBusiness AS LineOfBusiness,
	|	T.ReversingEntry AS ReversingEntry,
	|	SUM(T.AmountIncludingVAT) AS SumCurr,
	|	SUM(T.SumMan) AS SumMan,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.AmountIncludingVAT ELSE T.AmountIncludingVAT END) AS BalanceAmountShaft,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.SumMan ELSE T.SumMan END) AS ManSBalanceAmount
	|INTO DataOfRegisterOfGoodsAndServicesTTToCommitteeForPreparationOfReports
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	(T.AmountIncludingVAT <> 0 OR T.SumMan <> 0)
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.Currency,
	|	T.Organization,
	|	T.Purpose.Contract.Department,
	|	T.Purpose.Contract.LineOfBusiness,
	|	T.ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency,
	|	MAX(ExchangeRates.Period) AS Period,
	|	ManExchangeRates.Currency AS CurrencyOfMan,
	|	ManExchangeRates.BaseCurrency AS ManSBaseCurrency,
	|	MAX(ManExchangeRates.Period) AS ManPeriod
	|INTO TTPeriodsGoodsServicesForPreparationOfReportsToCommittee
	|FROM
	|	DataOfRegisterOfGoodsAndServicesTTToCommitteeForPreparationOfReports AS T
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON T.Currency = ExchangeRates.Currency
	|			AND T.Period >= ExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON (ManExchangeRates.Currency = &ManagementAccountingCurrency)
	|			AND T.Period >= ManExchangeRates.Period
	|			AND T.Organization.LocalAccountingCurrency = ManExchangeRates.BaseCurrency
	|
	|GROUP BY
	|	T.Recorder,
	|	ExchangeRates.Currency,
	|	ExchangeRates.BaseCurrency,
	|	ManExchangeRates.Currency,
	|	ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPeriods.Recorder AS Recorder,
	|	TTPeriods.Period AS Period,
	|	TTPeriods.Currency AS Currency,
	|	ISNULL(ExchangeRates.CourseNumerator, 0) / ISNULL(ExchangeRates.CourseDenominator, 1) * ISNULL(ManExchangeRates.CourseDenominator, 0) / ISNULL(ManExchangeRates.CourseNumerator, 1) AS ManSCoefficient,
	|	ISNULL(ExchangeRates.CourseNumerator, 1) AS ExchangeRateCurrencyNumerator,
	|	ISNULL(ExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorOfCurrency,
	|	&ManagementAccountingCurrency AS CurrencyOfMan,
	|	ISNULL(ManExchangeRates.CourseNumerator, 1) AS ExchangeRateNumeratorOfManSCurrency,
	|	ISNULL(ManExchangeRates.CourseDenominator, 1) AS ExchangeRateDenominatorCurrencyMan
	|INTO TTExchangeRatesGoodsAndServicesForPreparationOfReportsToCommittee
	|FROM
	|	TTPeriodsGoodsServicesForPreparationOfReportsToCommittee AS TTPeriods
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON TTPeriods.Currency = ExchangeRates.Currency
	|			AND TTPeriods.Period = ExchangeRates.Period
	|			AND TTPeriods.BaseCurrency = ExchangeRates.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|		ON (ManExchangeRates.Currency = &ManagementAccountingCurrency)
	|			AND TTPeriods.ManPeriod = ManExchangeRates.Period
	|			AND TTPeriods.ManSBaseCurrency = ManExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceTheGoodsOfWorkForPreparationOfReportsToCommitee) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	CASE
	|		WHEN T.SumMan <> 0
	|			THEN T.SumMan
	|		ELSE CAST(T.SumCurr * ExchangeRates.ManSCoefficient AS NUMBER(31,2))
	|	END AS Sum,
	|	CASE
	|		WHEN T.ManSBalanceAmount <> 0
	|			THEN T.ManSBalanceAmount
	|		ELSE CAST(T.BalanceAmountShaft * ExchangeRates.ManSCoefficient AS NUMBER(31,2))
	|	END AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	DataOfRegisterOfGoodsAndServicesTTToCommitteeForPreparationOfReports AS T
	|		INNER JOIN TTExchangeRatesGoodsAndServicesForPreparationOfReportsToCommittee AS ExchangeRates
	|		ON T.Recorder = ExchangeRates.Recorder";
	
	AddValueToParameter(Query, "AllTables", "DataOfRegisterOfGoodsAndServicesTTToCommitteeForPreparationOfReports");
	AddValueToParameter(Query, "AllTables", "TTPeriodsGoodsServicesForPreparationOfReportsToCommittee");
	AddValueToParameter(Query, "AllTables", "TTExchangeRatesGoodsAndServicesForPreparationOfReportsToCommittee");
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// WIPLaborCosts
// 
// Parameters:
// 	Query - Query -
// 	RegisterRecordTable - Arbitrary - LongDesc
Procedure AddQueryTextWorkInProgress(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.WIPLaborCosts.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ProductionOrder AS ProductionOrder,
		|	T.ProductionLot AS ProductionLot,
		|	T.LotCalculation AS LotCalculation,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.Cost AS Cost
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.Cost <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceWorkInProgress) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.Cost) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.Cost ELSE T.Cost END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.CalculationOfCost) AS SourceKind,
	|	&Source AS Source,
	|	&CalculationOfCost AS CalculationOfCost,
	|	T.LotCalculation AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.Cost <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	&LineOfBusiness,
	|	T.LotCalculation,
	|	T.ReversingEntry";
	
	If GetFunctionalOption("EnterpriseManagement") And GetFunctionalOption("LocalizationRFService")Then
		FieldOfActivity = "ISNULL(T.ProductionOrder.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))";
		If Query.Parameters.Production2_2 Then
			FieldOfActivity = "ISNULL(T.ProductionLot.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))";
		EndIf;
		QueryText = StrReplace(QueryText, "&LineOfBusiness", FieldOfActivity);
	Else
		QueryText = StrReplace(QueryText,"&LineOfBusiness", "VALUE(Catalog.LinesOfBusiness.EmptyRef)");
	EndIf;
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// OtherWorkInProgressExpenses
Procedure AddQueryTextOtherWorkInProgressExpenses(Query, RegisterRecordTable)
	
	TableName = Metadata.AccumulationRegisters.OtherWorkInProgressExpenses.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ProductionOrder AS ProductionOrder,
		|	T.ProductionLot AS ProductionLot,
		|	T.CalculationOfCost AS CalculationOfCost,
		|	T.LotCalculation AS LotCalculation,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.Cost AS Cost
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.Cost <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	ISNULL(CatProductionLots.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceWorkInProgress) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.Cost) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.Cost ELSE T.Cost END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.CalculationOfCost) AS SourceKind,
	|	&Source AS Source,
	|	T.CalculationOfCost AS CalculationOfCost,
	|	T.LotCalculation AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Ref = T.ProductionLot
	|WHERE
	|	T.Cost <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	ISNULL(CatProductionLots.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
	|	T.CalculationOfCost,
	|	T.LotCalculation,
	|	T.ReversingEntry";
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

// FixedAssetsDepreciationCharge
Procedure AddQueryTextDepreciationFA(Query, RegisterRecordTable)
	
	QueryOptions = New Structure;
	QueryOptions.Insert("TableName", "FixedAssetsDepreciationCharge");
	QueryOptions.Insert("ResourceName", "Depreciation");
	QueryOptions.Insert("NameOfAPArticle", "ManBalanceFixedAssets");
	QueryOptions.Insert("NameOfAnalyticsField", "FixedAsset");
	
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
	QueryOptions.Insert("NameOfAPArticle", "ProfitAndLoss");
	QueryOptions.Insert("TempTableName", QueryOptions.TableName + "_ProfitAndLoss");
	QueryOptions.Insert("PrimarySelection", SelectionOfProfitLossBeforeDepreciationAndAmortization());
	QueryOptions.Insert("InvertMotionView");
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
EndProcedure

// FACost
Procedure AddFACostRequestText(Query, RegisterRecordTable)
	
	QueryOptions = New Structure;
	QueryOptions.Insert("TableName", "FACost");
	QueryOptions.Insert("ResourceName", "Cost");
	QueryOptions.Insert("NameOfAPArticle", "ManBalanceFixedAssets");
	QueryOptions.Insert("NameOfAnalyticsField", "FixedAsset");
	
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
	QueryOptions.Insert("NameOfAPArticle", "ProfitAndLoss");
	QueryOptions.Insert("TempTableName", QueryOptions.TableName + "_ProfitAndLoss");
	QueryOptions.Insert("PrimarySelection", SelectionOfProfitLossPreValuation());
	QueryOptions.Insert("InvertMotionView");
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
	QueryOptions.Insert("NameOfAPArticle", "ProfitAndLoss");
	QueryOptions.Insert("ResourceName", "CostRevaluationReserve");
	QueryOptions.Insert("TempTableName", QueryOptions.TableName + "_RevaluationReserveOS_ProfitAndLoss");
	QueryOptions.Insert("PrimarySelection", SelectionOfGainsLossesOfFARevaluationReserve());
	QueryOptions.Insert("PositiveResource");
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
EndProcedure

// IntangibleAssetsAmortizationCharge
Procedure AddQueryTextDepreciationIA(Query, RegisterRecordTable)
	
	QueryOptions = New Structure;
	QueryOptions.Insert("TableName", "IntangibleAssetsAmortizationCharge");
	QueryOptions.Insert("ResourceName", "Depreciation");
	QueryOptions.Insert("NameOfAPArticle", "ManBalanceIntangibleAssets");
	QueryOptions.Insert("NameOfAnalyticsField", "IntangibleAsset");
	
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
	QueryOptions.Insert("NameOfAPArticle", "ProfitAndLoss");
	QueryOptions.Insert("TempTableName", QueryOptions.TableName + "_ProfitAndLoss");
	FilterText1 = StrReplace(SelectionOfProfitLossBeforeDepreciationAndAmortization(),"FADepreciation","IADepreciation");
	FilterText1 = StrReplace(FilterText1,"NOT T.AccrueDepreciation AND ","");
	QueryOptions.Insert("PrimarySelection", FilterText1);
	QueryOptions.Insert("InvertMotionView");
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
EndProcedure

// IACost
Procedure AddQueryTextCostOfIa(Query, RegisterRecordTable)
	
	QueryOptions = New Structure;
	QueryOptions.Insert("TableName", "IACost");
	QueryOptions.Insert("ResourceName", "Cost");
	QueryOptions.Insert("NameOfAPArticle", "ManBalanceIntangibleAssets");
	QueryOptions.Insert("NameOfAnalyticsField", "IntangibleAsset");
	
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
	QueryOptions.Insert("NameOfAPArticle", "ProfitAndLoss");
	QueryOptions.Insert("TempTableName", QueryOptions.TableName + "_ProfitAndLoss");
	FilterText1 = StrReplace(SelectionOfProfitLossPreValuation(),"FACosts","CostOfIA");
	QueryOptions.Insert("PrimarySelection", FilterText1);
	QueryOptions.Insert("InvertMotionView");
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
	QueryOptions.Insert("NameOfAPArticle", "ProfitAndLoss");
	QueryOptions.Insert("ResourceName", "CostRevaluationReserve");
	QueryOptions.Insert("TempTableName", QueryOptions.TableName + "_RevaluationReserveForIA_ProfitAndLoss");
	QueryOptions.Insert("PrimarySelection", SelectionOfProfitLossOfIaRevaluationReserve());
	QueryOptions.Insert("PositiveResource");
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
EndProcedure

// ImpairmentFA
Procedure AddTextOfRequestDevaluationOfVNA(Query, RegisterRecordTable)
	
	QueryOptions = New Structure;
	QueryOptions.Insert("TableName", "ImpairmentFA");
	QueryOptions.Insert("ResourceName", "ImpairmenMan");
	QueryOptions.Insert("NameOfAPArticle", "ManBalanceImpairmentFA");
	QueryOptions.Insert("NameOfAnalyticsField", "NonCurrentAsset");
	
	AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions);
	
EndProcedure

Function SelectionOfProfitLossBeforeDepreciationAndAmortization()
	
	Return
	"
	|	//Revaluation of accumulated depreciation
	|	AND (T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.IncreaseInFixedAssetDepreciation)
	|		AND (T.Depreciation <> 0 OR NOT T.AccrueDepreciation AND T.DepreciationLocal <> 0))";
	
EndFunction

Function SelectionOfProfitLossPreValuation()
	
	Return
	"
	|	//Revaluation of replacement cost
	|	AND (T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsCostAddition)
	|		AND (T.CostRevaluationReserveLocal <> 0 OR T.CostRevaluationReserve <> 0))";
	
EndFunction

Function SelectionOfGainsLossesOfFARevaluationReserve()
	
	Return
	"
	|	//Reserve for revaluation of fixed assets
	|	AND T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryFixedAssetsCosts),
	|		VALUE(Enum.BusinessTransactions.DecreaseFixedAssetCostAtFinalAppraisalExpense))";
	
EndFunction

Function SelectionOfProfitLossOfIaRevaluationReserve()
	
	Return
	"
	|	//Reserve the revaluation of intangible assets
	|	AND T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets),
	|		VALUE(Enum.BusinessTransactions.DecreaseIntangibleAssetCostAtFinalAppraisalExpense))";
	
EndFunction

Procedure AddQueryTextProvisionsForDoubtfulDebts(Query, RegisterRecordTable)
	
	TableName = "LossAllowance";
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ARAPObject AS ARAPObject,
		|	T.SumMan AS SumMan,
		|	T.ReversingEntry AS ReversingEntry
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.SumMan <> 0
		|";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	PartnerAnalytics_.Organization AS Organization,
	|	T.ARAPObject.Department AS Department,
	|	PartnerAnalytics_.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLossAllowance) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.SumMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN T.SumMan ELSE -T.SumMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS PartnerAnalytics_
	|	ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
	|WHERE
	|	T.SumMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Period,
	|	T.Recorder,
	|	T.RecordType,
	|	PartnerAnalytics_.Organization,
	|	T.ARAPObject.Department,
	|	PartnerAnalytics_.LineOfBusiness,
	|	T.ReversingEntry";
	
	AddLoggersConnection(Query, QueryText, PrimaryRegisteredRecords);
	AddFilter(Query, QueryText, "PartnerAnalytics_.Organization", "T.Recorder");
	ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords);
	
	AddValueToParameter(Query, "QueriesTexts", QueryText);
	AddValueToParameter(Query, "TablesOfRegisteredRecordsOfDirections", TableName);
	AddValueToParameter(Query, "AllTables", TableName);
	
EndProcedure

Procedure AddQueryTextForInvestmentInRent(Query, RegisterRecordTable)
	
	TableName = "InvestmentInRent";
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Contract AS Contract,
		|	T.FixedAsset AS FixedAsset,
		|	T.RentalPaymentsManag AS RentalPaymentsManag,
		|	T.NonGuaranteedResidualValueManag AS NonGuaranteedResidualValueManag,
		|	T.InterestDiscountMan AS InterestDiscountMan
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.RentalPaymentsManag + T.NonGuaranteedResidualValueManag + T.InterestDiscountMan <> 0
		|";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Contract.Department AS Department,
	|	T.Contract.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceInvestmentInRent) AS AssetRef,
	|	T.FixedAsset AS Dimension,
	|	SUM(T.RentalPaymentsManag + T.NonGuaranteedResidualValueManag + T.InterestDiscountMan) AS Sum,
	|	SUM(CASE
	|			WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				T.RentalPaymentsManag + T.NonGuaranteedResidualValueManag + T.InterestDiscountMan
	|			ELSE
	|				-(T.RentalPaymentsManag + T.NonGuaranteedResidualValueManag + T.InterestDiscountMan)
	|		END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	FALSE AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.RentalPaymentsManag + T.NonGuaranteedResidualValueManag + T.InterestDiscountMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Period,
	|	T.Recorder,
	|	T.RecordType,
	|	T.Organization,
	|	T.Contract.Department,
	|	T.Contract.LineOfBusiness,
	|	T.FixedAsset
	|";
	
	AddLoggersConnection(Query, QueryText, PrimaryRegisteredRecords);
	AddFilter(Query, QueryText, "T.Organization", "T.Recorder");
	ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords);
	
	AddValueToParameter(Query, "QueriesTexts", QueryText);
	AddValueToParameter(Query, "TablesOfRegisteredRecordsOfDirections", TableName);
	AddValueToParameter(Query, "AllTables", TableName);
	
EndProcedure
Procedure AddQueryTextInterestExpenseDiscounting(Query, RegisterRecordTable)
	
	TableName = "DiscountInterestExpense";
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ARAPObject AS ARAPObject,
		|	T.DiscountingAmountMan AS DiscountingAmountMan,
		|	T.ReversingEntry AS ReversingEntry
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.DiscountingAmountMan <> 0
		|";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.ARAPObject.Organization AS Organization,
	|	T.ARAPObject.Department AS Department,
	|	T.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceDiscountingExpenses) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.DiscountingAmountMan) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -T.DiscountingAmountMan ELSE T.DiscountingAmountMan END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.CalculationOfInterestOnDiscounting) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.DiscountingAmountMan <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Period,
	|	T.Recorder,
	|	T.RecordType,
	|	T.ARAPObject.Organization,
	|	T.ARAPObject.Department,
	|	T.ARAPObject.LineOfBusiness,
	|	T.ReversingEntry";
	
	AddLoggersConnection(Query, QueryText, PrimaryRegisteredRecords);
	AddFilter(Query, QueryText, "T.ARAPObject.Organization", "T.Recorder");
	ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords);
	
	AddValueToParameter(Query, "QueriesTexts", QueryText);
	AddValueToParameter(Query, "TablesOfRegisteredRecordsOfDirections", TableName);
	AddValueToParameter(Query, "AllTables", TableName);
	
EndProcedure

// OtherAssetsLiabilities
Function AddQueryTextOtherAssetsLiabilities(Query, RegisterRecordTable, CashOnly = False)
	
	TableName = Metadata.AccumulationRegisters.OtherAssetsLiabilities.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return "";
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.AssetRef AS AssetRef,
		|	T.Dimension AS Dimension,
		|	T.Sum AS Sum,
		|	T.SourceKind AS SourceKind,
		|	T.Source AS Source,
		|	T.CalculationOfCost AS CalculationOfCost,
		|	T.LotCalculation AS LotCalculation,
		|	T.ReversingEntry AS ReversingEntry
		|
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.Sum <> 0
		|	AND T.SourceKind = VALUE(Enum.MovementSourcesKinds.EmptyRef)";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.AssetRef AS AssetRef,
	|	T.Dimension AS Dimension,
	|	SUM(T.Sum) AS Sum,
	|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Expense) THEN -T.Sum ELSE T.Sum END) AS AmountOfBalance,
	|	T.SourceKind AS SourceKind,
	|	T.Source AS Source,
	|	T.CalculationOfCost AS CalculationOfCost,
	|	T.LotCalculation AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry,
	|	CASE WHEN T.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS EmptyDirection
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.Sum <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.RecordType,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.AssetRef,
	|	T.Dimension,
	|	T.SourceKind,
	|	T.Source,
	|	T.CalculationOfCost,
	|	T.LotCalculation,
	|	T.ReversingEntry";
	
	AddLoggersConnection(Query, QueryText, PrimaryRegisteredRecords);
	AddAssetLiabilitySelection(Query, QueryText, CashOnly);
	
	QueryText = StrReplace(QueryText, "PrimaryRegisteredRecords", PrimaryRegisteredRecords);
	QueryText = StrReplace(QueryText, "%1", TableName);
	If CashOnly Then
		Return QueryText;
	EndIf;
	QueryText = StrReplace(QueryText, "TableName", TableName);
	
	AddValueToParameter(Query, "QueriesTexts", QueryText);
	AddValueToParameter(Query, "TablesOfRegisteredRecordsOfDirections", TableName);
	AddValueToParameter(Query, "AllTables", TableName);
	
EndFunction
Function RequestTextCashByAssetsLiabilities(Query)
	
	Return AddQueryTextOtherAssetsLiabilities(Query, Undefined, True);
	
EndFunction
#EndRegion

// Parameters:
// 	Query - Query -
Procedure AddQueryTextForTemporaryBalanceControlTables(Query)
	
	BalanceControlRequestTemplate =
	"// The initial table of the control imbalance_&Tablename
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.AssetRef AS AssetRef,
	|	T.Dimension AS Dimension,
	|	T.Sum AS Sum,
	|	T.AmountOfBalance AS AmountOfBalance,
	|	T.SourceKind AS SourceKind,
	|	VALUE(Enum.SourcesOfBalanceSheetStatement.SourceName) AS Source,
	|	T.CalculationOfCost AS CalculationOfCost,
	|	T.LotCalculation AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry
	|FROM
	|	&TableName AS T";
	TextsOfRequestsForDirections = New Array;
	GenerateFinancialResult = GetFunctionalOption("GenerateFinancialResult");
	If GenerateFinancialResult Then
		RequestTemplateForFunds =
		"// Temporary table of monetary funds
		|SELECT
		|	Cash_1.Recorder AS Recorder,
		|	Cash_1.RecordType AS RecordType,
		|	Cash_1.Period AS Period,
		|	Cash_1.Organization AS Organization,
		|	Cash_1.Department AS Department,
		|	Cash_1.LineOfBusiness AS LineOfBusiness,
		|	Cash_1.AssetRef AS AssetRef,
		|	Cash_1.Dimension AS Dimension,
		|	Cash_1.Sum AS Sum,
		|	Cash_1.AmountOfBalance AS AmountOfBalance,
		|	Cash_1.SourceKind AS SourceKind,
		|	Cash_1.Source AS Source,
		|	FALSE AS CalculationOfCost,
		|	FALSE AS LotCalculation,
		|	FALSE AS ReversingEntry,
		|	Cash_1.EmptyDirection AS EmptyDirection
		|FROM
		|	&TableName AS Cash_1
		|WHERE
		|	Cash_1.EmptyDirection
		|	AND VALUETYPE(Cash_1.Recorder) <> TYPE(Document.OBEntry)
		|	AND VALUETYPE(Cash_1.Recorder) <> TYPE(Document.OBEntryOtherExpenses)
		|	AND VALUETYPE(Cash_1.Recorder) <> TYPE(Document.OBEntryOtherAssetsAndLiabilities)
		|	AND VALUETYPE(Cash_1.Recorder) <> TYPE(Document.OBEntryARAPAdvanceHolders)";
		TextsOfRequestsForFunds = New Array;
	EndIf;
	For Each TableName In Query.Parameters.TablesOfRegisteredRecordsOfDirections Do
		Source = Query.Parameters.SourceOfTemporaryTable[TableName];
		If Source = Undefined Then
			Source = TableName;
		EndIf;
		If TableName = "OtherAssetsLiabilities" Then
			BalanceControlRequestTemplate = StrReplace(BalanceControlRequestTemplate,
				"VALUE(Enum.SourcesOfBalanceSheetStatement.SourceName)",
				"CASE WHEN T.SourceKind = VALUE(Enum.MovementSourcesKinds.EmptyRef)
				|		THEN UNDEFINED
				|		ELSE VALUE(Enum.SourcesOfBalanceSheetStatement.SourceName)
				|	END");
		EndIf;
		QueryText = StrReplace(BalanceControlRequestTemplate, "&TableName", TableName);
		QueryText = StrReplace(QueryText, "SourceName", Source);
		If TextsOfRequestsForDirections.Count() = 0 Then
			QueryText = StrReplace(QueryText, "FROM", "INTO RegisteredRecordsOfDirections" + Chars.LF + "FROM");
		EndIf;
		TextsOfRequestsForDirections.Add(QueryText);
		If GenerateFinancialResult Then
			If TableName = "BankAccountCash"
				Or TableName = "CashAccountBalance"
				Or TableName = "CashInCashRegistersCR" Then
				QueryText = StrReplace(RequestTemplateForFunds, "&TableName", TableName);
				TextsOfRequestsForFunds.Add(QueryText);
			EndIf;
		EndIf;
	EndDo;
	UnionAll = "
	|
	|UNION ALL
	|
	|";
	
	QueryTextOfRegisteredRecords = StrConcat(TextsOfRequestsForDirections, UnionAll);
	
	AddValueToParameter(Query, "QueriesTexts", QueryTextOfRegisteredRecords);
	AddValueToParameter(Query, "AllTables", "RegisteredRecordsOfDirections");
	If GenerateFinancialResult Then
		QueryTextBalanceControl = 
		"// Balance control
		|SELECT
		|	T.Recorder AS Recorder,
		|	ENDOFPERIOD(T.Period, DAY) AS Period,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	CASE WHEN T.LineOfBusiness  = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS EmptyDirection,
		|	ISNULL(T.LineOfBusiness.CashAndBankAccountsByCorrespondence, FALSE) AS IndirectAccountingOfCash,
		|	SUM(T.AmountOfBalance) AS Sum
		|
		|INTO BalanceControl
		|FROM
		|	RegisteredRecordsOfDirections AS T
		|WHERE
		|	VALUETYPE(T.Recorder) <> TYPE(Document.OBEntry)
		|	AND VALUETYPE(T.Recorder) <> TYPE(Document.OBEntryOtherExpenses)
		|	AND VALUETYPE(T.Recorder) <> TYPE(Document.OBEntryOtherAssetsAndLiabilities)
		|	AND VALUETYPE(T.Recorder) <> TYPE(Document.OBEntryARAPAdvanceHolders)
		|
		|GROUP BY
		|	ENDOFPERIOD(T.Period, DAY),
		|	T.Recorder, 
		|	ISNULL(T.LineOfBusiness.CashAndBankAccountsByCorrespondence, FALSE),
		|	T.LineOfBusiness
		|HAVING
		|	SUM(T.AmountOfBalance) <> 0";
		AddValueToParameter(Query, "QueriesTexts", QueryTextBalanceControl);
		AddValueToParameter(Query, "AllTables", "BalanceControl");

		TextOfRequestForFunds = 
		"// An empty table of monetary funds
		|SELECT
		|	UNDEFINED AS Recorder,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	UNDEFINED AS Period,
		|	UNDEFINED AS Organization,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS LineOfBusiness,
		|	UNDEFINED AS AssetRef,
		|	UNDEFINED AS Dimension,
		|	0.0 AS Sum,
		|	0.0 AS AmountOfBalance,
		|	UNDEFINED AS SourceKind,
		|	UNDEFINED AS Source,
		|	FALSE AS CalculationOfCost,
		|	FALSE AS LotCalculation,
		|	FALSE AS ReversingEntry,
		|	FALSE AS EmptyDirection
		|INTO Cash
		|";
		
		RegisterFilling = Query.Parameters.RegisterFilling;
		If ValueIsFilled(Query.Parameters.TypeOfDeferredCalculation) And Not RegisterFilling Then
			QueryTextCash_1 = RequestTextCashByAssetsLiabilities(Query);
			QueryTextCash_1 = StrReplace(QueryTextCash_1, "INTO TableName", "");
			QueryTextCash_1 = StrReplace(QueryTextCash_1, "TableName", "Cash");
		ElsIf TextsOfRequestsForFunds.Count() > 0 Then
			QueryTextCash_1 = StrConcat(TextsOfRequestsForFunds, UnionAll);
		EndIf;
		If ValueIsFilled(QueryTextCash_1) Then
			TextOfRequestForFunds = TextOfRequestForFunds + UnionAll + QueryTextCash_1;
		EndIf;
		AddValueToParameter(Query, "QueriesTexts", TextOfRequestForFunds);
		AddValueToParameter(Query, "AllTables", "Cash");
	EndIf;
EndProcedure
Procedure AddCashFlowQueryText(Query)
	
	TextOfRequestForFunds = 
	"// Movement of indirect Cash
	|SELECT
	|	KB.Recorder AS Recorder,
	|	Cash.RecordType AS RecordType,
	|	KB.Period AS Period,
	|	UNDEFINED AS Organization,
	|	KB.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashLineOfBusiness) AS AssetRef,
	|	Cash.Dimension AS Dimension,
	|	CASE WHEN KB.Sum < 0 THEN -KB.Sum ELSE KB.Sum END AS Sum,
	|	VALUE(Enum.MovementSourcesKinds.BalanceCalculation) AS SourceKind,
	|	&IndirectCashFlow AS Source
	|
	|INTO CashFlow
	|FROM
	|	BalanceControl AS KB
	|	INNER JOIN Cash AS Cash
	|	ON KB.Recorder = Cash.Recorder
	|	AND Cash.EmptyDirection
	|WHERE
	|	KB.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND KB.IndirectAccountingOfCash
	|
	|UNION ALL
	|
	|// Allocation of indirect DS from the general heap due to the DS of the empty direction
	|SELECT
	|	KB.Recorder AS Recorder,
	|	CASE WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	KB.Period AS Period,
	|	UNDEFINED AS Organization,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashLineOfBusiness) AS AssetRef,
	|	Cash.Dimension AS Dimension,
	|	CASE WHEN KB.Sum < 0 THEN -KB.Sum ELSE KB.Sum END AS Sum,
	|	VALUE(Enum.MovementSourcesKinds.BalanceCalculation) AS SourceKind,
	|	&HighlightIndirectCash AS Source
	|
	|FROM
	|	BalanceControl AS KB
	|	INNER JOIN Cash AS Cash
	|	ON KB.Recorder = Cash.Recorder
	|	AND Cash.EmptyDirection
	|WHERE
	|	KB.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND KB.IndirectAccountingOfCash
	|
	|UNION ALL
	|
	|// Movements of straight DS
	|SELECT
	|	KB.Recorder AS Recorder,
	|	CASE WHEN KB.Sum > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	KB.Period AS Period,
	|	UNDEFINED AS Organization,
	|	KB.LineOfBusiness AS LineOfBusiness,
	|	CASE WHEN KB.Sum > 0
	|		THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFundsInvestments)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFundsWithdrawals)
	|	END AS AssetRef,
	|	Cash.Dimension AS Dimension,
	|	CASE WHEN KB.Sum < 0 THEN -KB.Sum ELSE KB.Sum END AS Sum,
	|	VALUE(Enum.MovementSourcesKinds.BalanceCalculation) AS SourceKind,
	|	&MovementOfDirectCash AS Source
	|
	|FROM
	|	BalanceControl AS KB
	|	INNER JOIN Cash AS Cash
	|	ON KB.Recorder = Cash.Recorder
	|	AND Cash.EmptyDirection
	|WHERE
	|	KB.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND NOT KB.IndirectAccountingOfCash
	|
	|UNION ALL
	|
	|// Input/Output of direct DS due to an empty direction
	|SELECT
	|	KB.Recorder AS Recorder,
	|	CASE WHEN KB.Sum > 0
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	KB.Period AS Period,
	|	UNDEFINED AS Organization,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	CASE WHEN KB.Sum > 0
	|		THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFundsWithdrawals)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFundsInvestments)
	|	END AS AssetRef,
	|	Cash.Dimension AS Dimension,
	|	CASE WHEN KB.Sum < 0 THEN -KB.Sum ELSE KB.Sum END AS Sum,
	|	VALUE(Enum.MovementSourcesKinds.BalanceCalculation) AS SourceKind,
	|	&MovementOfStraightLinesDSPOEmpty AS Source
	|
	|FROM
	|	BalanceControl AS KB
	|	INNER JOIN Cash AS Cash
	|	ON KB.Recorder = Cash.Recorder
	|	AND Cash.EmptyDirection
	|WHERE
	|	KB.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND NOT KB.IndirectAccountingOfCash";
	
	Query.SetParameter("IndirectCashFlow", NStr("vi = 'Chuyển động tiền gián tiếp';
												|ru = 'Движение косвенных ДС';
												|en = 'Indirect cash flow'; fa = 'Indirect cash flow';
												|it = 'Movimento dei fondi monetari indiretti';
												|pl = 'Ruch pośrednich SP';
												|tr = 'Dolaylı Nakit hareketi'"));
	Query.SetParameter("HighlightIndirectCash", NStr("vi = 'Lựa chọn tiền gián tiếp';
													|ru = 'Выделение косвенных ДС';
													|en = 'Highlight indirect cash'; fa = 'Highlight indirect cash';
													|it = 'Stanziamento dei fondi monetari indiretti';
													|pl = 'Zaznaczenie pośrednich SP';
													|tr = 'Dolaylı Nakit seçimi'"));
	Query.SetParameter("MovementOfDirectCash", NStr("vi = 'Chuyển động tiền trực tiếp';
													|ru = 'Движения прямых ДС';
													|en = 'Direct cash flow'; fa = 'Direct cash flow';
													|it = 'Movimenti dei fondi monetari diretti';
													|pl = 'Ruchu bezpośrednich SP';
													|tr = 'Doğrudan Nakit hareketi'"));
	Query.SetParameter("MovementOfStraightLinesDSPOEmpty", NStr("vi = 'Chuyển động tiền trực tiếp theo trống';
																|ru = 'Движения прямых ДС по пусто';
																|en = 'Direct cash flow in empty'; fa = 'Direct cash flow in empty';
																|it = 'Movimenti dei fondi monetari diretti per vuoto';
																|pl = 'Ruchu bezpośrednich SP na pusto';
																|tr = 'Doğrudan Nakit boş hareketi'"));
	
	AddValueToParameter(Query, "QueriesTexts", TextOfRequestForFunds);
	AddValueToParameter(Query, "AllTables", "CashFlow");
	
EndProcedure

Procedure AddRequestTextForInputOutputRegisteredRecordsByDirection(Query)
	
	TextOfInputOutputRequestForLB = 
	"// Table of directions used
	|SELECT DISTINCT
	|	KB.Recorder AS Recorder
	|INTO DirectionsUsed
	|FROM
	|	BalanceControl AS KB
	|WHERE
	|	KB.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Input/output movements in the direction of
	|SELECT
	|	KB.Recorder AS Recorder,
	|	CASE WHEN KB.Sum > 0
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	KB.Period AS Period,
	|	KB.LineOfBusiness AS LineOfBusiness,
	|	CASE WHEN KB.Sum > 0
	|		THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFundsInvestments)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFundsWithdrawals)
	|	END AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	CASE WHEN KB.Sum < 0 THEN -KB.Sum ELSE KB.Sum END AS Sum,
	|	VALUE(Enum.MovementSourcesKinds.BalanceCalculation) AS SourceKind
	|
	|INTO RegisteredRecordsInputOutputByLB
	|FROM
	|	BalanceControl AS KB
	|	LEFT JOIN CashFlow AS CashRegisteredRecords
	|	ON KB.Recorder = CashRegisteredRecords.Recorder
	|	AND KB.LineOfBusiness = CashRegisteredRecords.LineOfBusiness
	|	LEFT JOIN DirectionsUsed AS CompletedDirections
	|	ON KB.Recorder = CompletedDirections.Recorder
	|WHERE
	|	CashRegisteredRecords.Recorder IS NULL
	|	AND NOT CompletedDirections.Recorder IS NULL
	|";
	
	AddValueToParameter(Query, "QueriesTexts", TextOfInputOutputRequestForLB);
	AddValueToParameter(Query, "AllTables", "DirectionsUsed");
	AddValueToParameter(Query, "AllTables", "RegisteredRecordsInputOutputByLB");
	
EndProcedure
// Parameters:
// 	Query - Query -
Procedure AddQueryTextForAssetLiabilityRegisteredRecords(Query)
	
	QueryTextFlowOfAssetsAndLiabilities = 
	"SELECT
	|	T.Recorder AS Recorder,
	|	T.RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.AssetRef AS AssetRef,
	|	T.Dimension AS Dimension,
	|	T.Sum AS Sum,
	|	T.SourceKind AS SourceKind,
	|	T.Source AS Source,
	|	T.CalculationOfCost AS CalculationOfCost,
	|	T.LotCalculation AS LotCalculation,
	|	T.ReversingEntry AS ReversingEntry,
	|	T.Recorder AS DocumentRegisterRecords
	|,&TempTable
	|FROM
	|	RegisteredRecordsOfDirections AS T
	|WHERE
	|	&Filter";
	If GetFunctionalOption("GenerateFinancialResult") Then
		QueryTextFlowOfAssetsAndLiabilities = QueryTextFlowOfAssetsAndLiabilities + 
		"
		|
		|UNION ALL
		|
		|"+
		"SELECT
		|	T.Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	UNDEFINED AS Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.AssetRef AS AssetRef,
		|	T.Dimension AS Dimension,
		|	T.Sum AS Sum,
		|	T.SourceKind AS SourceKind,
		|	UNDEFINED AS Source,
		|	&TypeOfDeferredCalculation = VALUE(Enum.MovementSourcesKinds.CalculationOfCost) AS CalculationOfCost,
		|	FALSE AS LotCalculation,
		|	VALUETYPE(T.Recorder) = TYPE(Document.ReversingEntry) AS ReversingEntry,
		|	T.Recorder AS DocumentRegisterRecords
		|FROM
		|	CashFlow AS T
		|	LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
		|	ON T.Recorder = DocumentReversingEntry.Ref
		|WHERE
		|	NOT VALUETYPE(T.Recorder) IN (&OBEntry)
		|	AND NOT (VALUETYPE(T.Recorder) = TYPE(Document.ReversingEntry)
		|			AND VALUETYPE(DocumentReversingEntry.ReversedDocument) IN (&OBEntry))
		|
		|UNION ALL
		|
		|SELECT
		|	T.Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.AssetRef AS AssetRef,
		|	T.Dimension AS Dimension,
		|	SUM(T.Sum) AS Sum,
		|	T.SourceKind AS SourceKind,
		|	UNDEFINED AS Source,
		|	&TypeOfDeferredCalculation = VALUE(Enum.MovementSourcesKinds.CalculationOfCost) AS CalculationOfCost,
		|	FALSE AS LotCalculation,
		|	VALUETYPE(T.Recorder) = TYPE(Document.ReversingEntry) AS ReversingEntry,
		|	T.Recorder AS DocumentRegisterRecords
		|FROM
		|	RegisteredRecordsInputOutputByLB AS T
		|	LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
		|	ON T.Recorder = DocumentReversingEntry.Ref
		|WHERE
		|	NOT VALUETYPE(T.Recorder) IN (&OBEntry)
		|	AND NOT (VALUETYPE(T.Recorder) = TYPE(Document.ReversingEntry)
		|			AND VALUETYPE(DocumentReversingEntry.ReversedDocument) IN (&OBEntry))
		|
		|GROUP BY
		|	T.Recorder,
		|	T.RecordType,
		|	T.Period,
		|	T.LineOfBusiness,
		|	T.AssetRef,
		|	T.Dimension,
		|	T.SourceKind";
	EndIf;
	ResultTable2 = "";
	If ValueIsFilled(Query.Parameters.NameOfTemporaryResultTable) Then
		QueryTextFlowOfAssetsAndLiabilities = QueryTextFlowOfAssetsAndLiabilities + 
		"
		|
		|INDEX BY
		|	Period,
		|	Recorder,
		|	Organization,
		|	Source
		|";
		ResultTable2 = "INTO " + Query.Parameters.NameOfTemporaryResultTable;
		QueryTextFlowOfAssetsAndLiabilities = QueryTextFlowOfAssetsAndLiabilities + TheSeparatorQueries();
	EndIf;
	QueryTextFlowOfAssetsAndLiabilities = StrReplace(QueryTextFlowOfAssetsAndLiabilities, ",&TempTable", ResultTable2);
	
	If Query.Parameters.SamplingByRegistrar Then
		QueryTextFlowOfAssetsAndLiabilities = QueryTextFlowOfAssetsAndLiabilities + 
		"
		|
		|TOTALS BY
		|	Recorder
		|";
	EndIf;
	
	RegisterFilling = Query.Parameters.RegisterFilling;
	If ValueIsFilled(Query.Parameters.TypeOfDeferredCalculation) And Not RegisterFilling Then
		SelectionOfRegisteredRecordsOfAssetsLiabilities =  "(T.SourceKind IN (
										|		&TypeOfDeferredCalculation,
										|		VALUE(Enum.MovementSourcesKinds.BalanceCalculation),
										|		VALUE(Enum.MovementSourcesKinds.BalanceFlow))
										|	OR T.Source IN (&UpdatedSources))
										|	AND NOT T.Source IN (
										|		VALUE(Enum.SourcesOfBalanceSheetStatement.EmptyRef),
										|		VALUE(Enum.SourcesOfBalanceSheetStatement.OtherAssetsLiabilities))";
		
		QueryTextFlowOfAssetsAndLiabilities = StrReplace(QueryTextFlowOfAssetsAndLiabilities,
												"&Filter",
												SelectionOfRegisteredRecordsOfAssetsLiabilities);
	Else
		QueryTextFlowOfAssetsAndLiabilities = StrReplace(QueryTextFlowOfAssetsAndLiabilities,"&Filter","TRUE");
	EndIf;
	
	AddValueToParameter(Query, "QueriesTexts", QueryTextFlowOfAssetsAndLiabilities);
	AddValueToParameter(Query, "AllTables", "SampleResult");
	
EndProcedure

//RegisterRecordsByExcises
Procedure AddQueryTextOfRegisteredRecordsForExciseTaxes(Query, RegisterRecordTable)

	TableName = Metadata.AccumulationRegisters.RegisterRecordsByExcises.Name;
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.ExcisePaymentBusinessUnit AS ExcisePaymentBusinessUnit,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ReversingEntry AS ReversingEntry,
		|	T.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.ExciseAmountInCurrencyMgmt <> 0";
		
		PrimaryRegisteredRecords = PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.ExcisePaymentBusinessUnit AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(T.ExciseAmountInCurrencyMgmt) AS Sum,
	|	SUM(-T.ExciseAmountInCurrencyMgmt) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	&CalculationOfCost AS CalculationOfCost,
	|	T.ReversingEntry AS ReversingEntry,
	|	FALSE AS LotCalculation
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.ExciseAmountInCurrencyMgmt <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	T.Period,
	|	T.Organization,
	|	T.ExcisePaymentBusinessUnit,
	|	T.LineOfBusiness,
	|	T.ReversingEntry
	|HAVING
	|	SUM(T.ExciseAmountInCurrencyMgmt) <> 0";
	
	PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords);
	
EndProcedure

#EndRegion
 
#Region FillingInAssetsLiabilities

// The function returns the information required to fill in the other active Arrays register
//
// Parameters:
//  TypesOfLoggers - See NumberOfRegistrars
//
// Returns:
// 	Structure - Contains information about filling in the register:
// 	* LongDesc - String - 
// 	* ProcessedTypes - See DescriptionOfRegisterTypes
// 	* TotalDocuments - Number - Total documents to be processed
// 	* ProcessedDocuments_1 - Number -
// 	* User - CatalogRef.Users - 
// 	* StartTime - Date -
//
Function InitializeInformationAboutFilling(TypesOfLoggers) Export

	ProcessedTypes = DescriptionOfRegisterTypes(TypesOfLoggers);
	
	InformationRecords = Constants.IBUpdateInfo.Get().Get();
	If TypeOf(InformationRecords) <> Type("Structure") Then
		InformationRecords = New Structure;
	EndIf;
	
	If InformationRecords.Property("FillingInAssetsLiabilities") Then
		Process_ = InformationRecords.FillingInAssetsLiabilities;
	Else
		Process_ = New Structure("LongDesc,TotalDocuments,ProcessedDocuments_1", "", 0, 0);
		Process_.TotalDocuments = TypesOfLoggers.Total("TotalDocuments");
		Process_.Insert("ProcessedTypes", ProcessedTypes);
		Process_.Insert("User", Users.CurrentUser());
		Process_.Insert("StartTime", CurrentSessionDate());
		InformationRecords.Insert("FillingInAssetsLiabilities", Process_);
		Constants.IBUpdateInfo.Set(New ValueStorage(InformationRecords));
	EndIf;
	
	Return Process_;
	
EndFunction

Procedure FillInRegisterInformationOnDocuments(TypeOfRegistrar, ProcessedTypes, NotRecordRegisteredRecords_ = False)
	
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	
	DocumentName = TypeOfRegistrar.Name;
	DocumentSynonym = TypeOfRegistrar.Synonym;
	TotalDocuments = TypeOfRegistrar.TotalDocuments;
	
	InformationRecords = Constants.IBUpdateInfo.Get().Get();
	Process_ = InformationRecords.FillingInAssetsLiabilities; //Structure
	Process_.Insert("DocumentName", DocumentName);
	Constants.IBUpdateInfo.Set(New ValueStorage(InformationRecords));
	
	#Region InitializingProcessingCycle
	PortionSize = 5000;
	PointInTime = New PointInTime('39991231');
	If Process_.Property("PointInTime") Then
		PointInTime = Process_.PointInTime;
	EndIf;
	Query = InitializeDocumentRequest(DocumentName, PortionSize);
	RecordedRegisteredRecords = 0;
	ProcessedDocuments_1 = 0;
	RequiredToProcess = TotalDocuments;
	#EndRegion
	
	While RequiredToProcess > 0 Do
		
		TableManager = New TempTablesManager;
		Query.TempTablesManager = TableManager;
		Query.SetParameter("PointInTime", PointInTime);
		
		PackageResult = Query.ExecuteBatch();
		Result = PackageResult[1]; // QueryResult - 
		Selection = Result.Select();
		Selection.Next();
		PointInTime = Selection.PointInTime;
		
		MotionParameters = New Structure;
		MotionParameters.Insert("TypeOfDeferredCalculation", Enums.MovementSourcesKinds.BalanceCalculation);
		MotionParameters.Insert("DocumentsToBeReflected", TableManager);
		MotionParameters.Insert("SamplingByRegistrar", True);
		RequestRegisteredRecords = RequestRegisteredRecords(MotionParameters);
		If RequestRegisteredRecords = Undefined Then
			RequiredToProcess = RequiredToProcess - PortionSize;
			Continue;
		EndIf;
		
		Processed = RecordGeneratedRegisteredRecords(DocumentName, RequestRegisteredRecords, NotRecordRegisteredRecords_);
		ProcessedDocuments_1 = ProcessedDocuments_1 + Processed.Documents;
		RecordedRegisteredRecords = RecordedRegisteredRecords + Processed.OfRegisteredRecords;
		
		Process_.LongDesc = StrTemplate("%1 (%2 from %3)", DocumentSynonym, ProcessedDocuments_1, TotalDocuments);
		Process_.Insert("PointInTime", PointInTime);
		Constants.IBUpdateInfo.Set(New ValueStorage(InformationRecords));
		
		RequiredToProcess = RequiredToProcess - PortionSize;
		
	EndDo;
	
	#Region FixingProcessingResults
	Process_.Delete("PointInTime");
	
	ProcessedType = ProcessedTypes.Add();
	FillPropertyValues(ProcessedType, TypeOfRegistrar);
	ProcessedType.FillingTime = (CurrentUniversalDateInMilliseconds() - MeasurementStart) / 1000;
	ProcessedType.TotalRegisteredRecords = RecordedRegisteredRecords;
	ProcessedType.TotalDocuments = ProcessedDocuments_1;
	ProcessedType.TotalSpent = TimePresentation(ProcessedType.FillingTime);
	
	Process_.ProcessedDocuments_1 = Process_.ProcessedDocuments_1 + TotalDocuments;
	Process_.LongDesc = StrTemplate("%1 (%2 from %3)", DocumentSynonym, ProcessedDocuments_1, TotalDocuments);
	Process_.Insert("ProcessedTypes", ProcessedTypes);
	Constants.IBUpdateInfo.Set(New ValueStorage(InformationRecords));
	#EndRegion
	
EndProcedure

Function InitializeDocumentRequest(DocumentName, PortionSize)
	
	QueryTemplate = 
	"SELECT DISTINCT TOP 1000
	|	T.Ref AS Recorder,
	|	T.PointInTime
	|INTO DocumentsToBeReflected
	|FROM
	|	&DocumentName AS T
	|WHERE
	|	T.Posted
	|	AND T.PointInTime <= &PointInTime
	|
	|ORDER BY
	|	T.PointInTime DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	DocumentsToBeReflected.PointInTime AS PointInTime
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|
	|ORDER BY
	|	PointInTime";
	QueryText = StrReplace(QueryTemplate, "1000", Format(PortionSize, "NG=0"));
	QueryText = StrReplace(QueryText, "&DocumentName", DocumentName);
	Query = New Query(QueryText);
	Return Query;
	
EndFunction

Function RecordGeneratedRegisteredRecords(Val DocumentName, RequestRegisteredRecords, NotRecordRegisteredRecords_ = False)
	
	RecordRegisteredRecords_ = Not NotRecordRegisteredRecords_;
	RecordedRegisteredRecords = 0;
	ProcessedDocuments_1 = 0;
	If StrFind(DocumentName, ".") > 0 Then
		DocumentName = StrSplit(DocumentName, ".")[1];
	EndIf;
	RegistrarMetadata = Metadata.Documents[DocumentName];
	SelectionByDocument = RequestRegisteredRecords.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionByDocument.Next() Do

		Recorder = SelectionByDocument.Recorder;
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("Document." + DocumentName);
			LockItem.SetValue("Ref", Recorder);
			
			LockItem = Block.Add("AccumulationRegister.OtherAssetsLiabilities.RecordSet");
			LockItem.SetValue("Recorder", Recorder);
			
			Block.Lock();
			
			// Record the correct movements
			Set = AccumulationRegisters.OtherAssetsLiabilities.CreateRecordSet();
			Set.Filter.Recorder.Set(Recorder);
			
			Selection = SelectionByDocument.Select();
			While Selection.Next() Do
				FillPropertyValues(Set.Add(), Selection);
				RecordedRegisteredRecords = RecordedRegisteredRecords + 1;
			EndDo;
			If RecordRegisteredRecords_ Then
				InfobaseUpdate.WriteData(Set);
			EndIf;
			ProcessedDocuments_1 = ProcessedDocuments_1 + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = NStr("vi = 'Không thể xử lý %Document% theo nguyên nhân: %Cause%';
								|ru = 'Не удалось обработать %Document% по причине: %Cause%';
								|en = 'Cannot process %Document%. Reason: %Cause%'; fa = 'Cannot process %Document%. Reason: %Cause%';
								|it = 'Non è stato possibile elaborare %Document% a causa di: %Cause%';
								|pl = 'Nie udało się przetworzyć %Document% z powodu: %Cause%';
								|tr = '%Cause% nedeniyle %Document% işlenemedi'");
			MessageText = StrReplace(MessageText, "%Document%", Recorder);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(LogEventName_RegisterFilling(),
									EventLogLevel.Error,
									RegistrarMetadata,
									Recorder,
									MessageText);
			
		EndTry;

	EndDo;
	
	Return New Structure("Documents,OfRegisteredRecords",ProcessedDocuments_1,RecordedRegisteredRecords);
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctionsOfManagementBalanceSheet
// Collects everything necessary to form movements on the management balance
// The procedure for forming movements can be caused by:
//    - when conducting a document online
//    - after performing deferred calculations.
//
// Parameters:
//  Source data-Structure-the minimum required source data for the formation of movements
//                 during online processing these are all tables of movements for recording in the register sets of the document being conducted
//                 during offline generation the name of the deferred calculation that caused the formation 
//                     and the names of registers by which the deferred calculation changed the movements to update them in
//                     the management balance
//  DebugParameters  - Structure - for different debugging parameters, see the code.
//
// Returns:
//   Structure - The structure of parameters in which everything necessary for the formation of movements is collected, depending on
//               the context of the call.
//
Function InitializeMotionParameters(MotionParameters, DebugParameters = Undefined)
	
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	
	DocumentLink_ = Undefined;
	MotionParameters.Property("Ref", DocumentLink_);
	
	TypeOfDeferredCalculation = Undefined;
	MotionParameters.Property("TypeOfDeferredCalculation", TypeOfDeferredCalculation);
	MotionParameters.Insert("TypeOfDeferredCalculation", TypeOfDeferredCalculation);
	RegisterFilling = TypeOfDeferredCalculation = Enums.MovementSourcesKinds.BalanceCalculation;
	MotionParameters.Insert("RegisterFilling", RegisterFilling);

	#Region DocumentsToBeReflected
	// The document to the reflection can be set by a Link, an array of links, a temporary table of the document to the reflection with
	// the Registrar field.
	TableManager = New TempTablesManager;
	ArrayOfLoggers = Undefined;
	DocumentsToBeReflected = Undefined;
	TableOfLoggers = Undefined;
	If MotionParameters.Property("DocumentsToBeReflected", DocumentsToBeReflected) Then
		If TypeOf(DocumentsToBeReflected) = Type("TempTablesManager") Then
			TableManager = DocumentsToBeReflected;
			If MotionParameters.Property("TableOfLoggers") Then
				TableOfLoggers = MotionParameters.TableOfLoggers;
			Else
				TableOfLoggers = DescriptionOfLoggersTable();
			EndIf;
		Else
			ArrayOfLoggers = DocumentsToBeReflected;
		EndIf;
	EndIf;
	#EndRegion
	
	If MotionParameters.Property("TempTablesManager") Then
		TableManager = MotionParameters.TempTablesManager;
	EndIf;
	
	#Region TablesForRegisteredRecords
	If Not MotionParameters.Property("TablesForRegisteredRecords") Then
		MotionParameters.Insert("TablesForRegisteredRecords", DeferredCalculationTables(TypeOfDeferredCalculation));
	EndIf;
	
	If TypeOf(MotionParameters.TablesForRegisteredRecords) = Type("String") Then
		TablesForRegisteredRecords = New Structure(MotionParameters.TablesForRegisteredRecords);
		MotionParameters.Insert("TablesForRegisteredRecords", TablesForRegisteredRecords);
	EndIf;
	#EndRegion

	#Region Debug
	MotionParameters.Insert("Write", True);
	If TypeOf(DebugParameters) = Type("Structure") Then
		
		If DebugParameters.Property("NotRecordRegisteredRecords_") Then
			MotionParameters.Write = False;
		EndIf;
		
	EndIf;
	#EndRegion

	#Region RequestRegisteredRecords
	Query = New Query;
	Query.TempTablesManager = TableManager;
	Query.SetParameter("Recorder", DocumentLink_);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("TablesOfRegisteredRecordsOfDirections", New Array);
	Query.SetParameter("AllTables", New Array);
	Query.SetParameter("SourceOfTemporaryTable", New Map);
	Query.SetParameter("NewSettlements", Constants.NewOnlineARAPAccounting.Get());
	Query.SetParameter("StartDateOfAccountingIN2_4", '00010101');
	Query.SetParameter("UseVNA2_4", False);
	Query.SetParameter("StartDateOfAccountingIN2_4", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	Query.SetParameter("UseVNA2_4", Constants.UseNonCurrentAssets2_4.Get());
	Query.SetParameter("Production2_2", Constants.UseProductionManagement2_2.Get());
	Query.SetParameter("OBEntry", TypesOfResidueEntryDocuments());
	#Region SettingPassedParameters
	If ArrayOfLoggers <> Undefined Then
		Query.SetParameter("ArrayOfLoggers", ArrayOfLoggers);
	EndIf;
	If TableOfLoggers <> Undefined Then
		Query.SetParameter("TableOfLoggers", TableOfLoggers);
	EndIf;
	CompanyArray = Undefined;
	If MotionParameters.Property("CompanyArray", CompanyArray) Then
		Query.SetParameter("CompanyArray", CompanyArray);
	EndIf;
	Period = Undefined;
	If MotionParameters.Property("Period", Period) Then
		Query.SetParameter("BeginOfPeriod", BegOfMonth(Period));
		Query.SetParameter("EndOfPeriod", EndOfMonth(Period));
	EndIf;
	ThisIsCostCalculation = TypeOfDeferredCalculation = Enums.MovementSourcesKinds.CalculationOfCost;
	Query.SetParameter("CalculationOfCost", ThisIsCostCalculation);
	
	Query.SetParameter("TypeOfDeferredCalculation", TypeOfDeferredCalculation);
	Query.SetParameter("UpdatedSources", UpdatedSources(TypeOfDeferredCalculation));
	Query.SetParameter("RegisterFilling", RegisterFilling);
	Query.SetParameter("SamplingByRegistrar", MotionParameters.Property("SamplingByRegistrar"));
	
	NameOfTemporaryResultTable = Undefined;
	MotionParameters.Property("NameOfTemporaryResultTable", NameOfTemporaryResultTable);
	Query.SetParameter("NameOfTemporaryResultTable", NameOfTemporaryResultTable);
	#EndRegion
	#EndRegion

	Measurements = New Structure;
	Protocol = New Structure("Measurements", Measurements);
	MotionParameters.Insert("Protocol", Protocol);
	MotionParameters.Insert("RequestRegisteredRecords", Query);
	
	AddMeasurement(MotionParameters.Protocol.Measurements,"InitializingMotionParameters",MeasurementStart);
	
	Return MotionParameters;
	
EndFunction

Function TypesOfResidueEntryDocuments()
	
	Result = New Array;
	
	Result.Add(Type("DocumentRef.OBEntry"));
	Result.Add(Type("DocumentRef.OBEntryARAP"));
	Result.Add(Type("DocumentRef.OBEntryOfLeaseSettlements"));
	Result.Add(Type("DocumentRef.EntryOfCapitalAssetsBalance2_4"));
	Result.Add(Type("DocumentRef.OBEntryCash"));
	Result.Add(Type("DocumentRef.EnterRentalInvestmentBalance"));
	Result.Add(Type("DocumentRef.OBEntrySalesForPastPeriods"));
	Result.Add(Type("DocumentRef.OBEntryFinancialInstruments"));
	Result.Add(Type("DocumentRef.OBEntryOtherExpenses"));
	Result.Add(Type("DocumentRef.OBEntryOtherAssetsAndLiabilities"));
	Result.Add(Type("DocumentRef.OBEntryAcquiringContractARAP"));
	Result.Add(Type("DocumentRef.OBEntryARAPAdvanceHolders"));
	Result.Add(Type("DocumentRef.OBEntryInventoryInOperation"));
	Result.Add(Type("DocumentRef.OBEntryGoods"));
	Result.Add(Type("DocumentRef.OBEntrySubAssetsAndComponentsOfDepreciation"));
	Return Result;
	
EndFunction

// Returns the movement values of record sets uploaded to tables
// 
// Parameters:
// 	DocumentReference - DocumentRef, Structure - LongDesc
// 	DocumentRegisterRecords - RegisterRecordsCollection - LongDesc
// Returns:
// 	Structure - LongDesc:
// * TimeOfUnloadingOfCalculationsAccordingToDocuments - Number -
Function UnloadMotionSets(DocumentReference, DocumentRegisterRecords) Export
	
	MovementTables = New Structure;
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	EmptySourceView = Enums.MovementSourcesKinds.EmptyRef();
	UnloadedSettlementsWithClients = False;
	UnloadedSettlementsWithSuppliers = False;
	IsNew = False;
	If DocumentRegisterRecords.OtherAssetsLiabilities.AdditionalProperties.Property("DocumentProperties") Then
		IsNew = DocumentRegisterRecords.OtherAssetsLiabilities.AdditionalProperties.DocumentProperties.IsNew;
	EndIf;
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		UploadCalculationsByTimeFrame(DocumentReference, MovementTables);
		UnloadedSettlementsWithClients = MovementTables.Property("CustomersARAPAccountingByDueDates");
		UnloadedSettlementsWithSuppliers = MovementTables.Property("VendorsARAPAccountingByDueDates");
	ElsIf Not IsNew Then
		UnloadedSettlementsWithClients = UploadCalculationsBasedOnDocuments(MovementTables, DocumentRegisterRecords, "CustomersARAPAccounting");
		UnloadedSettlementsWithSuppliers = UploadCalculationsBasedOnDocuments(MovementTables, DocumentRegisterRecords, "VendorsARAPAccounting");
	EndIf;
	TimeOfUnloadingOfCalculationsAccordingToDocuments = (CurrentUniversalDateInMilliseconds() - MeasurementStart) / 1000;
	MovementTables.Insert("TimeOfUnloadingOfCalculationsAccordingToDocuments", TimeOfUnloadingOfCalculationsAccordingToDocuments);
	
	BalanceRegisters = BalanceRegisters();
	If Not UnloadedSettlementsWithClients Then
		BalanceRegisters.Insert("CustomersARAPAccounting");
	EndIf;
	If Not UnloadedSettlementsWithSuppliers Then
		BalanceRegisters.Insert("VendorsARAPAccounting");
	EndIf;
	For Each Set In DocumentRegisterRecords Do
		
		SetName = String(Set);
		If StrFind(SetName, "AccumulationRegister") = 0 Then
			Continue;
		EndIf;
		SetName = StrReplace(SetName, "AccumulationRegisterRecordSet.", "");
		
		BalanceSheetRegister = BalanceRegisters.Property(SetName);
		If Not BalanceSheetRegister Then
			Continue;
		EndIf;
		
		If Set.Count() = 0 And Not Set.Write Then
			Set.Read();
		EndIf;
		
		If Set.Count() = 0 Then
			Continue;
		EndIf;
		
		If SetName = "OtherAssetsLiabilities" Then
			FilterOfRegisteredRecords = New Structure("SourceKind", EmptySourceView);
			RegisterRecordTable = Set.Unload().Copy(FilterOfRegisteredRecords);
		Else
			RegisterRecordTable = Set.Unload();
		EndIf;
		
		MovementTables.Insert(SetName, RegisterRecordTable);
	EndDo;
	
	Return MovementTables;
	
EndFunction

Function UploadCalculationsBasedOnDocuments(MovementTables, RegisterRecords, Val SetName)
	
	SetName = SetName + "ByDocuments";
	SetOfCalculationsForDocuments = RegisterRecords.Find(SetName);
	If SetOfCalculationsForDocuments <> Undefined Then
		If Not SetOfCalculationsForDocuments.Write Then
			SetOfCalculationsForDocuments.Read();
			If SetOfCalculationsForDocuments.Count() > 0 Then
				MovementTables.Insert(SetName,SetOfCalculationsForDocuments.Unload());
			EndIf;
		EndIf;
	EndIf;
	Return MovementTables.Property(SetName);
	
EndFunction

Procedure UploadCalculationsByTimeFrame(DocumentRecorder, MovementTables)
	
	QueryText =
	"SELECT
	|	FALSE AS CustomersARAPAccounting,
	|	T.*
	|INTO TTCalculationsByTerms
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS T
	|WHERE
	|	T.DocumentRecorder = &DocumentRecorder
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS CustomersARAPAccounting,
	|	T.*
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS T
	|WHERE
	|	T.DocumentRecorder = &DocumentRecorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.DocumentRecorder AS Recorder,
	|	T.Recorder AS ARAPAccountingRecorder,
	|	T.*
	|FROM
	|	TTCalculationsByTerms AS T
	|TOTALS BY
	|	T.CustomersARAPAccounting";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentRecorder", DocumentRecorder);
	
	TypesOfCalculations = Query.Execute().Select(QueryResultIteration.ByGroups);
	While TypesOfCalculations.Next() Do
		
		If TypesOfCalculations.CustomersARAPAccounting Then
			RegisterName = "CustomersARAPAccountingByDueDates";
			Set = AccumulationRegisters.CustomersARAPAccountingByDueDates.CreateRecordSet();
		Else
			RegisterName = "VendorsARAPAccountingByDueDates";
			Set = AccumulationRegisters.VendorsARAPAccountingByDueDates.CreateRecordSet();
		EndIf;
		
		RegisterRecords = Set.Unload();
		RegisterRecords.Columns.Recorder.Name = "ARAPAccountingRecorder";
		RegisterRecords.Columns.DocumentRecorder.Name = "Recorder";
		Selection = TypesOfCalculations.Select();
		While Selection.Next() Do
			NewRow = RegisterRecords.Add();
			FillPropertyValues(NewRow, Selection);
		EndDo;
		MovementTables.Insert(RegisterName, RegisterRecords);
		
	EndDo;
	
EndProcedure

Function ThereAreCalculationsOnDocuments(MovementTables, ARAPType)
	
	Result = False;
	SetName = ARAPType + "ByDocuments";
	If MovementTables.Property(SetName) Then
		Result = True;
		If TypeOf(MovementTables[SetName]) = Type("ValueTable") Then
			Result = MovementTables[SetName].Count() > 0 
		EndIf;
	EndIf;
	Return Result;
	
EndFunction

Procedure AddFilter(Query, QueryText, OrganizationField = "", LoggerField = "")
	
	FilterText1 = "";
	If Query.Parameters.Property("ArrayOfLoggers") Then
		FilterText1 = FilterText1 + "AND T.Recorder IN (&ArrayOfLoggers)";
		If Not IsBlankString(LoggerField) Then
			FilterText1 = StrReplace(FilterText1, "T.Recorder", LoggerField);
		EndIf;
	EndIf;
	
	Pstab = Chars.LF+Chars.Tab;
	If Query.Parameters.Property("CompanyArray") Then
		FilterText1 = FilterText1 + ?(FilterText1 = "", "", Pstab) 
					+ "AND T.Organization IN (&CompanyArray)";
		If Not IsBlankString(OrganizationField) Then
			FilterText1 = StrReplace(FilterText1, "T.Organization", OrganizationField);
		EndIf;
	EndIf;
	
	If Query.Parameters.Property("BeginOfPeriod") Then
		FilterText1 = FilterText1 + ?(FilterText1 = "", "", Pstab)
					+ "AND T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod";
	EndIf;
	QueryText = StrReplace(QueryText,"AND &Filter",FilterText1);
	
EndProcedure

Procedure AddAssetLiabilitySelection(Query, QueryText, CashOnly = False)
	
	If Query.Parameters.RegisterFilling Then
		QueryText = StrReplace(QueryText,
									"AND &Filter",
									"AND T.SourceKind = VALUE(Enum.MovementSourcesKinds.EmptyRef)
									|	AND &Filter");
	ElsIf ValueIsFilled(Query.Parameters.TypeOfDeferredCalculation) Then
		QueryText = StrReplace(QueryText,
									"AND &Filter",
									"AND NOT T.SourceKind IN (
									|		&TypeOfDeferredCalculation,
									|		VALUE(Enum.MovementSourcesKinds.BalanceCalculation))
									|	AND NOT T.Source IN (&UpdatedSources)
									|	AND &Filter");
	Else
		QueryText = StrReplace(QueryText,
									"AND &Filter",
									"AND T.SourceKind = VALUE(Enum.MovementSourcesKinds.EmptyRef)
									|	AND &Filter");
	EndIf;
	
	If CashOnly Then
		QueryText = StrReplace(QueryText,
									"AND &Filter",
									"AND T.AssetRef IN (
									|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceBankAccountCash),
									|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashAccountBalance))
									|	AND &Filter");
	EndIf;
	
	AddFilter(Query, QueryText);
	
EndProcedure

// Parameters:
// 	Query - Query -
// 	QueryText - String - LongDesc
// 	TableName - String - LongDesc
// 	RegisterRecordTable - ValueTable - LongDesc
Function PreparePrimaryRegisteredRecords(Query, QueryText, TableName, RegisterRecordTable);
	
	PrimaryRegisteredRecords = "Primary_1" + TableName;
	Query.SetParameter(TableName, RegisterRecordTable);
	ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords);
	AddValueToParameter(Query, "QueriesTexts", QueryText);
	AddValueToParameter(Query, "AllTables", PrimaryRegisteredRecords);
	
	Return PrimaryRegisteredRecords;
	
EndFunction

// Parameters:
// 	Query - Query - 
// 	QueryText - String - 
// 	TableName - String - 
// 	PrimaryRegisteredRecords - String -
Procedure PrepareRegisteredRecords(Query, QueryText, TableName, PrimaryRegisteredRecords, OrganizationField = "")
	
	AddLoggersConnection(Query, QueryText, PrimaryRegisteredRecords);
	AddFilter(Query, QueryText, OrganizationField);
	ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords);
	
	AddValueToParameter(Query, "QueriesTexts", QueryText);
	AddValueToParameter(Query, "TablesOfRegisteredRecordsOfDirections", TableName);
	AddValueToParameter(Query, "AllTables", TableName);
	
EndProcedure

// Parameters:
// 	Query - Query - 
// 	ParameterName - String - 
// 	NewValue - String - 
Procedure AddValueToParameter(Query, ParameterName, NewValue)
	
	Parameter = Query.Parameters[ParameterName]; // Array of String -
	Parameter.Add(NewValue);
	
EndProcedure

// Parameters:
// 	Query - Query - 
// 	QueryText - String - LongDesc
// 	PrimaryRegisteredRecords - String - LongDesc
Procedure AddLoggersConnection(Query, QueryText, PrimaryRegisteredRecords)
	
	If Query.Parameters.Property("TableOfLoggers") Then
		TTRecorders = Query.Parameters.TableOfLoggers;
		ConnectionPattern = "
		|	%1 AS T
		|	INNER JOIN %2 AS DocumentsToBeReflected
		|	ON T.Recorder = DocumentsToBeReflected.%3";
		
		JoinText = StrTemplate(ConnectionPattern, PrimaryRegisteredRecords, TTRecorders.TableName, TTRecorders.LoggerField);
		QueryText = StrReplace(QueryText, "PrimaryRegisteredRecords AS T", JoinText);
	EndIf;
	
EndProcedure

Procedure ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords)
	
	Source = StrTemplate("VALUE(Enum.SourcesOfBalanceSheetStatement.%1)", TableName);
	QueryText = StrReplace(QueryText, "&Source", Source);
	QueryText = StrReplace(QueryText, "TableName", TableName);
	QueryText = StrReplace(QueryText, "%1", TableName);
	QueryText = StrReplace(QueryText, "PrimaryRegisteredRecords", PrimaryRegisteredRecords);
	
EndProcedure

Function DeferredCalculationTables(TypeOfDeferredCalculation)
	
	Tables = New Structure;
	RegisterMetadata_ = Metadata.AccumulationRegisters;
	If TypeOfDeferredCalculation = Enums.MovementSourcesKinds.CalculationOfCost Then
		Tables.Insert(RegisterMetadata_.OtherAssetsLiabilities.Name, "TTAssetsLiabilities");
		Tables.Insert(RegisterMetadata_.OtherIncome.Name, "TTOtherIncome");
		Tables.Insert(RegisterMetadata_.OtherExpenses.Name, "TTOtherExpenses_");
		Tables.Insert(RegisterMetadata_.InventoryCost.Name, "TTCostPrice");
		Tables.Insert(RegisterMetadata_.GoodsCostVariances.Name, "TTDeviationsInCostOfGoods");
		Tables.Insert(RegisterMetadata_.WIPLaborCosts.Name, "TTLaborCostsUnfinishedProduction");
		Tables.Insert(RegisterMetadata_.OtherWorkInProgressExpenses.Name, "TTOtherExpensesUnfinishedProduction");
	ElsIf TypeOfDeferredCalculation = Enums.MovementSourcesKinds.PartnersARAPAccounting Then
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			Tables.Insert(RegisterMetadata_.CustomersARAPAccountingByDueDates.Name);
			Tables.Insert(RegisterMetadata_.VendorsARAPAccountingByDueDates.Name);
		Else
			Tables.Insert(RegisterMetadata_.CustomersARAPAccountingByDocuments.Name);
			Tables.Insert(RegisterMetadata_.VendorsARAPAccountingByDocuments.Name);
		EndIf;
		Tables.Insert(RegisterMetadata_.OtherAssetsLiabilities.Name);
		Tables.Insert(RegisterMetadata_.OtherExpenses.Name);
		Tables.Insert(RegisterMetadata_.InventoryCost.Name);
		
	ElsIf TypeOfDeferredCalculation = Enums.MovementSourcesKinds.BalanceCalculation Then
		Tables = BalanceRegisters();
		
	EndIf;
	Return Tables;
	
EndFunction

Function UpdatedSources(TypeOfDeferredCalculation)
		
	Result = New Array;
	Sources = Enums.SourcesOfBalanceSheetStatement;
	If TypeOfDeferredCalculation = Enums.MovementSourcesKinds.PartnersARAPAccounting Then
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			Result.Add(Sources.CustomersARAPAccountingByDueDates);
			Result.Add(Sources.VendorsARAPAccountingByDueDates);
		Else
			Result.Add(Sources.CustomersARAPAccountingByDocuments);
			Result.Add(Sources.VendorsARAPAccountingByDocuments);
		EndIf;
		Result.Add(Sources.OtherExpenses);
		Result.Add(Sources.InventoryCost);
	EndIf;
	Return Result;
	
EndFunction

Function RequestTextForPaymentObjectDetails(
			Requestor = "T.ARAPObject",
			PaymentObjectDetails_ = "Contract",
			AttributeTypes = "DefinedTypes.ARAPObject") Export
	
	FieldText = "SELECTION" + Chars.LF;
	ConditionTemplate = "		WHEN VALUETYPE(%1) = TYPE(%2)
					|			THEN CAST(%1 AS %2).%3";
	ContractTemplate = "		WHEN VALUETYPE(%1) = TYPE(%2)
					 |			THEN %1";
	SelectionConditions = New Array;
	ContractTypes = Metadata.Catalogs.DimensionKeysOfAccountingByPartners.Attributes.Contract.Type.Types();
	ContractTypes.Add(Type("CatalogRef.GiftCertificates"));
	
	If TypeOf(AttributeTypes) = Type("String") Then
		TypesOfCalculationObjects = TMCommonUse.MetadataByName(AttributeTypes).Type.Types();
	ElsIf TypeOf(AttributeTypes) = Type("Array") Then
		TypesOfCalculationObjects = AttributeTypes;
	EndIf;
	For Each TypeOfCalculationObject In TypesOfCalculationObjects Do
		
		If TypeOfCalculationObject = Type("Null") Or TypeOfCalculationObject = Type("Undefined") Then
			Continue;
		EndIf;
		
		FullTypeName = Metadata.FindByType(TypeOfCalculationObject).FullName();
		If StrFind(FullTypeName, "Enum") > 0 Then
			Continue;
		EndIf;
		
		If Upper(PaymentObjectDetails_) = "CONTRACT" And ContractTypes.Find(TypeOfCalculationObject) <> Undefined Then
			ConditionText = StrTemplate(ContractTemplate, Requestor, FullTypeName);
		Else
			ConditionText = StrTemplate(ConditionTemplate, Requestor, FullTypeName, PaymentObjectDetails_);
		EndIf;
		SelectionConditions.Add(ConditionText);
		
	EndDo;
	ConditionText = StrConcat(SelectionConditions, Chars.LF);
	Return FieldText + ConditionText + Chars.LF + "END";
	
EndFunction

Function TheSeparatorQueries()
	
	Return "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
EndFunction

Procedure AddMeasurement(Measurements, MeasurementName, MeasurementStart)
	
	MeasurementTime = (CurrentUniversalDateInMilliseconds() - MeasurementStart) / 1000;
	Measurements.Insert(MeasurementName, TimePresentation(MeasurementTime));
	
EndProcedure

// The function returns the types of register registrars other active Arrays
//
// Returns:
// 	ValueTable - Contains a set of updated documents:
// 	* Name - String - 
// 	* Synonym - String -
// 	* TotalDocuments - Number -	
//
Function NumberOfRegistrars()
	
	Exceptions = New Map;
	Exceptions.Insert(Metadata.Documents.DepositsWithdrawalsByLineOfBusiness.Name, True);
	Exceptions.Insert(Metadata.Documents.RegisterAdjustment.Name, True);
	Exceptions.Insert(Metadata.Documents.InventoryCostCalculation.Name, True);
	
	QueryTemplate =
	"SELECT
	|	""&DocumentName"" AS Name,
	|	""&DocumentSynonym"" AS Synonym,
	|	COUNT(DISTINCT T.Ref) AS TotalDocuments
	|FROM
	|	&DocumentName AS T
	|WHERE
	|	T.Posted";
	TypesOfLoggers = Metadata.AccumulationRegisters.OtherAssetsLiabilities.StandardAttributes.Recorder.Type.Types();
	QueriesArray = New Array;
	For Each TypeOfRegistrar In TypesOfLoggers Do
		
		RegistrarMetadata = Metadata.FindByType(TypeOfRegistrar);
		If Exceptions[RegistrarMetadata.Name] = Undefined Then
			QueryText = StrReplace(QueryTemplate, "&DocumentName", "Document." + RegistrarMetadata.Name);
			QueryText = StrReplace(QueryText, "&DocumentSynonym", StrReplace(RegistrarMetadata.Synonym,"""",""));
			QueriesArray.Add(QueryText);
		EndIf;
		
	EndDo;
	
	UnionAll = 
	"
	|
	|UNION ALL
	|
	|";
	
	TheTextOfASubquery = StrConcat(QueriesArray, UnionAll);
	Template = 
	"SELECT
	|	T.Name,
	|	T.Synonym,
	|	T.TotalDocuments
	|FROM
	|	&NestedQuery AS T
	|WHERE
	|	T.TotalDocuments > 0
	|
	|ORDER BY
	|	Name";
	
	QueryText = StrReplace(Template, "&NestedQuery", "(" + TheTextOfASubquery + ")");
	Query = New Query(QueryText);
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// The function returns the types of register registrars other active Arrays
//
// Parameters:
//  TypesOfLoggers - See NumberOfRegistrars
//
// Returns:
// 	ValueTable - Contains document data:
// 	* Name - String - 
// 	* Synonym - String -
// 	* TotalDocuments - Number -
// 	* TotalRegisteredRecords - Number -
// 	* FillingTime - Number -
// 	* TotalSpent - Number - 
//
Function DescriptionOfRegisterTypes(TypesOfLoggers)
	
	ProcessedTypes = TypesOfLoggers.CopyColumns();
	ProcessedTypes.Columns.Add("TotalRegisteredRecords", New TypeDescription("Number",New NumberQualifiers(10, 0)));
	ProcessedTypes.Columns.Add("FillingTime", New TypeDescription("Number",New NumberQualifiers(15, 3)));
	ProcessedTypes.Columns.Add("TotalSpent", New TypeDescription("String",,New StringQualifiers(30)));
	
	Return ProcessedTypes;
	
EndFunction

Function TimePresentation(Val Seconds)
	
	Hours1 = Int(Seconds / 3600);
	Seconds = Seconds - Hours1*3600;
	
	Minutes1  = Int(Seconds / 60);
	Seconds = Seconds - Minutes1*60;
	
	WholeSeconds = Int(Seconds);
	
	Seconds = Seconds - WholeSeconds;
		
	TimePresentation = ""
		+ ?(Hours1 = 0, "", String(Hours1) + ":")
		+ ?(Minutes1 = 0, ?(Hours1>0,"00:",""), ?(Minutes1<10 And Hours1>0,"0"+String(Minutes1),String(Minutes1)) + ":")
		+ ?(WholeSeconds = 0, ?(Minutes1>0 Or Hours1>0,"00",""), ?(WholeSeconds<10 And (Minutes1>0 Or Hours1>0),"0"+String(WholeSeconds),String(WholeSeconds)))
		+ ?(WholeSeconds>0 Or Minutes1>0 Or Hours1>0,Right(String(Seconds),StrLen(String(Seconds))-1),String(WholeSeconds+Seconds));
		
	Return TimePresentation;
	
EndFunction

Procedure OutputProtocol(MessageText, TypesOfLoggers, Measurements = Undefined)
	
	TableText = GenerateTextFromTable(TypesOfLoggers);
	MeasurementText = GenerateMeasurementText(Measurements);
	WriteLogEvent(
		LogEventName_RegisterFilling(),
		EventLogLevel.Information,
		,
		,
		MessageText + TableText + MeasurementText);
	
EndProcedure

Function LogEventName_RegisterFilling()
	
	Return NStr("vi = 'Điền biểu ghi ''''Tài sản và nguồn vốn''''';
				|ru = 'Заполнение регистра ""Активы и пассивы""';
				|en = 'Populate the ""Assets and liabilities"" register'; fa = 'Populate the ""Assets and liabilities"" register';
				|it = 'Compilazione del registro ""Attivi e passivi""';
				|pl = 'Wypełnienie rejestru ""Aktywa i pasywa""';
				|tr = '""Varlıklar ve yükümlülükler"" kayıt defterinin doldurulması'", Common.DefaultLanguageCode());
	
EndFunction

Function GenerateTextFromTable(TypesOfLoggers)
	
	Text = Chars.LF+Chars.LF;
	TableHeading = NStr("vi = 'Tên chứng từ - Tổng chứng từ';
						|ru = 'Имя документа - Всего документов';
						|en = 'Document name - Total documents'; fa = 'Document name - Total documents';
						|it = 'Nome documento-Totale documenti';
						|pl = 'Nazwa dokumentu - Razem dokumentów';
						|tr = 'Belge adı - Toplam belgeler'");
	StringPattern = Chars.Tab + "%1 - %2" + Chars.LF;
	If TypesOfLoggers.Columns.Count() > 3 Then
		TableHeading = NStr("vi = 'Tên chứng từ - chứng từ được xử lý / Đã ghi lại bản ghi kết chuyển - Tổng chi tiêu (HH: MM: SS, ms)';
							|ru = 'Имя документа - Обработано документов / Записано движений - Всего затрачено (ЧЧ:ММ:СС,мс)';
							|en = 'Document name - Processed documents / Records saved - Total time spent (HH:MM:SS,ms)'; fa = 'Document name - Processed documents / Records saved - Total time spent (HH:MM:SS,ms)';
							|it = 'Nome documento-Elaborati documenti / Movimenti registrati - Totale impiegato (Ore:Minuti:Secondi,millisec)';
							|pl = 'Nazwa dokumentu - Przetworzone dokumenty / Zarejestrowane ruchy - Całkowite wydatki (HH:MM:SS,ms)';
							|tr = 'Belge adı - İşlenen belgeler / Kaydedilen hareketler - Toplam zaman (SS:DD:SS,ms)'");
		StringPattern = Chars.Tab + "%1 - %2 / %3 - %4" + Chars.LF;
	EndIf;
	Text = Text + TableHeading + Chars.LF+Chars.LF;
	For Each Recorder In TypesOfLoggers Do
		NewRow = StrTemplate(StringPattern, Recorder.Name, Recorder.TotalDocuments);
		If TypesOfLoggers.Columns.Count() > 3 Then
			NewRow = StrTemplate(StringPattern, Recorder.Name, Recorder.TotalDocuments, Recorder.TotalRegisteredRecords, Recorder.TotalSpent);
		EndIf;
		Text = Text + NewRow;
	EndDo;
	If TypesOfLoggers.Columns.Count() = 3 Then
		TotalString = StrTemplate(StringPattern, NStr("vi = 'Tổng số';
														|ru = 'Итого';
														|en = 'Total'; fa = 'جمع کل';
														|it = 'Totale';
														|pl = 'Łącznie';
														|tr = 'Toplam'"), TypesOfLoggers.Total("TotalDocuments"));
		Text = Text + TotalString;
	EndIf;
	Return Text;
	
EndFunction

Function GenerateMeasurementText(Measurements)
	
	If TypeOf(Measurements) <> Type("Structure") Then
		Return "";
	EndIf;
	
	Text = Chars.LF + NStr("vi = 'Thời gian sử dụng:';
							|ru = 'Затраты времени:';
							|en = 'Time expenditures:'; fa = 'Time expenditures:';
							|it = 'Tempo impiegato:';
							|pl = 'Straty czasu:';
							|tr = 'Zaman giderleri:'")+Chars.LF;
	For Each Measurement In Measurements Do
		
		Text = Text + StrTemplate("	%1 - %2", Measurement.Key, Measurement.Value)+Chars.LF;
		
	EndDo;
	Return Text;
	
EndFunction
Procedure AddSimpleCaseSensitiveQueryText(Query, RegisterRecordTable, QueryOptions)
	
	TableName = QueryOptions.TableName;
	ResourceName = QueryOptions.ResourceName;
	NameOfAPArticle = "FixedAssets";
	If QueryOptions.Property("NameOfAPArticle") Then
		NameOfAPArticle = QueryOptions.NameOfAPArticle;
	EndIf;
	NameOfAnalyticsField = QueryOptions.NameOfAnalyticsField;
	NameOfSourceType = "BalanceFlow";
	If QueryOptions.Property("SourceKind") Then
		NameOfSourceType = QueryOptions.SourceKind;
	EndIf;
	PrimarySelection = "";
	If QueryOptions.Property("PrimarySelection") Then
		PrimarySelection = QueryOptions.PrimarySelection;
	EndIf;
	TempTableName = "";
	If QueryOptions.Property("TempTableName") Then
		TempTableName = QueryOptions.TempTableName;
	EndIf;
	
	PrimaryRegisteredRecords = "AccumulationRegister."+TableName;
	
	If TypeOf(RegisterRecordTable) = Type("String") Then
		PrimaryRegisteredRecords = RegisterRecordTable;
	ElsIf TypeOf(RegisterRecordTable) = Type("ValueTable") Then
	
		If RegisterRecordTable.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText =
		"// PrimaryRegisteredRecords
		|SELECT
		|	&Recorder AS Recorder,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Dimension AS Dimension,
		|	T.ResourceName AS ResourceName
		|INTO PrimaryRegisteredRecords
		|FROM
		|	&TableName AS T
		|WHERE
		|	T.ResourceName <> 0
		|	AND &PrimarySelection";
		
		PrimaryRegisteredRecords = "Primary_1" + ?(TempTableName = "", TableName, TempTableName);
		ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords);
		QueryText = StrReplace(QueryText, "ResourceName", ResourceName);
		QueryText = StrReplace(QueryText, "Dimension", NameOfAnalyticsField);
		QueryText = StrReplace(QueryText, "AND &PrimarySelection", PrimarySelection);
		PrimarySelection = "";
		
		Query.SetParameter(TableName, RegisterRecordTable);
		AddValueToParameter(Query, "QueriesTexts", QueryText);
		AddValueToParameter(Query, "AllTables", PrimaryRegisteredRecords);
	
	EndIf;
	
	QueryText =
	"// %1
	|SELECT
	|	T.Recorder AS Recorder,
	|	&RecordType AS RecordType,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets) AS AssetRef,
	|	T.Dimension AS Dimension,
	|	SUM(T.ResourceName) AS Sum,
	|	SUM(CASE WHEN &RecordType = VALUE(AccumulationRecordType.Expense) 
	|				THEN -T.ResourceName 
	|				ELSE T.ResourceName
	|		END) AS AmountOfBalance,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow) AS SourceKind,
	|	&Source AS Source,
	|	FALSE AS CalculationOfCost,
	|	FALSE AS LotCalculation,
	|	FALSE AS ReversingEntry
	|
	|INTO TableName
	|FROM
	|	PrimaryRegisteredRecords AS T
	|WHERE
	|	T.ResourceName <> 0
	|	AND &Filter
	|
	|GROUP BY
	|	T.Recorder,
	|	&RecordType,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	T.Dimension,
	|	T.LineOfBusiness";
	
	If Not IsBlankString(PrimarySelection) Then
		QueryText = StrReplace(QueryText, "AND &Filter", "AND &Filter" + PrimarySelection);
	EndIf;
	TrafficTypeText = "T.RecordType";
	If QueryOptions.Property("PositiveResource") Then
		QueryText = StrReplace(QueryText,"T.ResourceName", "CASE WHEN T.ResourceName < 0 THEN -T.ResourceName ELSE T.ResourceName END");
	EndIf;
	If QueryOptions.Property("InvertMotionView") Then
		TrafficTypeText = "CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
							|		THEN VALUE(AccumulationRecordType.Expense)
							|		ELSE VALUE(AccumulationRecordType.Receipt)
							|	END";
	EndIf;
	QueryText = StrReplace(QueryText,"&RecordType", TrafficTypeText);
	
	AddLoggersConnection(Query, QueryText, PrimaryRegisteredRecords);
	AddFilter(Query, QueryText);
	
	ReplaceSubstitutions(QueryText, TableName, PrimaryRegisteredRecords);
	QueryText = StrReplace(QueryText, "ResourceName", ResourceName);
	If QueryOptions.NameOfAPArticle = "ProfitAndLoss" Then
		QueryText = StrReplace(QueryText, "T.Dimension", "UNDEFINED");
	Else
		QueryText = StrReplace(QueryText, "T.Dimension", "T." + NameOfAnalyticsField);
	EndIf;
	QueryText = StrReplace(QueryText, 
						"VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets)", 
						"VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems." + NameOfAPArticle + ")");
	QueryText = StrReplace(QueryText, "BalanceFlow", NameOfSourceType);
	
	If IsBlankString(TempTableName) Then
		AddValueToParameter(Query, "TablesOfRegisteredRecordsOfDirections", TableName);
		AddValueToParameter(Query, "AllTables", TableName);
	Else
		QueryText = StrReplace(QueryText, "/"+"/ " + TableName, "/"+"/ " + TempTableName);
		QueryText = StrReplace(QueryText, "INTO " + TableName, "INTO " + TempTableName);
		AddValueToParameter(Query, "TablesOfRegisteredRecordsOfDirections", TempTableName);
		AddValueToParameter(Query, "AllTables", TempTableName);
		Query.Parameters.SourceOfTemporaryTable.Insert(TempTableName, TableName);
	EndIf;
	
	AddValueToParameter(Query, "QueriesTexts", QueryText);
	
EndProcedure
// Returns a structure that describes a temporary table that contains documents to be reflected in the management balance sheet
// 
// Returns:
// 	Structure - LongDesc:
// * LoggerField - String -
// * TableName - String -
Function DescriptionOfLoggersTable() Export
	
	TableOfLoggers = New Structure;
	TableOfLoggers.Insert("TableName"      , "DocumentsToBeReflected");
	TableOfLoggers.Insert("LoggerField", "Recorder");
	
	Return TableOfLoggers;
	
EndFunction

#EndRegion

#EndRegion

#EndIf