////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the formation of movements on 
// the turnover registers of management accounting.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.RecordsCashCounterparty);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CashFlow);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.RecordsCashIncomeExpenses);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.RecordsProductsProducts);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.RecordsCounterpartyIncomeExpenses);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.RecordsCounterpartyCounterparty);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.Purchases);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.RecordsCashIncomeExpenses);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.RecordsCounterpartyIncomeExpenses);
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.RecordsProductsProducts;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		AdditionalTermsAndConditions = "NOT RegisterData.CalculationOfCost";
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument,
				AdditionalTermsAndConditions));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		AdditionalTermsAndConditions = "
		|	NOT RegisterData.LotCalculation
		|	AND NOT RegisterData.CalculationOfCost
		|";		
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument,
				AdditionalTermsAndConditions));
	EndIf;

	RegisterMetadata = Metadata.AccumulationRegisters.RecordsCashCounterparty;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		AdditionalTermsAndConditions = "
		|	NOT RegisterData.DeferredPosting
		|";
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument, AdditionalTermsAndConditions));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.CashFlow;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));	
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.RecordsCashIncomeExpenses;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.RecordsCounterpartyIncomeExpenses;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
			
	RegisterMetadata = Metadata.AccumulationRegisters.RecordsCounterpartyCounterparty;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.Purchases;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
	QueriesTexts.Insert(RegisterMetadata.FullName(),
		DocumentsPosting.TextOfReversingRequest(
			RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// Procedure for forming movements on subordinate turnover registers of management accounting.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RecordsCashCounterparty");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CashFlow");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RecordsCashIncomeExpenses");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RecordsIncomeExpensesOtherAssetsLiabilities");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RegisterRecordsProductsIncomeExpenses");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RecordsProductsProducts");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RecordsCounterpartyIncomeExpenses");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RecordsCounterpartyCounterparty");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "Purchases");
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfFormationOfDelayedRegisteredRecords

// To update all pending Registered Records on negotiable registers:
// - in the register "Registered Records of Cash - Counterparty" for customers and suppliers
// - in the register of "Registered Recorded Counterparty - Counterparty".
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef - an array of documents for which you need to generate traffic.
// 
// Returns:
//  Array of DocumentRef- the documents for which the Registered Records have been changed that affect the formation of Local accounting records.
//
Function UpdateRegisteredRecordsOnNegotiableRegisters(DocumentsArray) Export
	
	ModifiedDocuments = New ValueTable;
	ModifiedDocuments.Columns.Add("Ref");
	If DocumentsArray.Count() > 0 Then
		GenerateCashFlowsCounterpartyToCustomers(DocumentsArray, ModifiedDocuments);
	EndIf;
	If DocumentsArray.Count() > 0 Then
		GenerateCashFlowsCounterpartyToSuppliers(DocumentsArray, ModifiedDocuments);
	EndIf;
	If DocumentsArray.Count() > 0 Then
		GenerateRegisteredRecordsCounterpartyCounterparty(DocumentsArray, ModifiedDocuments);
	EndIf;
	
	ModifiedDocuments.GroupBy("Ref");
	Return ModifiedDocuments.UnloadColumn("Ref");
	
EndFunction

// The formation of the pending motions in the case "movement of funds - contractor" on the clients.
//
// Parameters:
//	DocumentsArray - Array of DocumentRef - array of documents.
//	ModifiedDocuments - ValueTable - table of modified documents.
//	ForDebugging - Structure, Undefined - The structure in which information is returned for debugging.
//
Procedure GenerateCashFlowsCounterpartyToCustomers(DocumentsArray, ModifiedDocuments = Undefined, ForDebugging = Undefined) Export
	
	Try
		TempTablesManager = New TempTablesManager;
		MovementData = RegisteredRecordsOfCashCounterparty(DocumentsArray, True, TempTablesManager,
			ForDebugging);
		
		SelectionByDocuments = MovementData.Select(QueryResultIteration.ByGroups);
		While SelectionByDocuments.Next() Do
			RecordCashFlowCounterparty(SelectionByDocuments, ModifiedDocuments, ForDebugging);
		EndDo;
		
		If ForDebugging <> Undefined Then
			ForDebugging.Insert("TempTablesManager", TempTablesManager);
			ForDebugging.Insert("MovementData", MovementData.Unload());
		EndIf;
	Except
		MessageText = NStr("vi = 'Không thể thực hiện kết chuyển hoãn lại theo biểu ghi ""Biến động Vốn bằng tiền - Đối tác""
						|khi hạch toán với khách hàng theo nguyên nhân';
						|ru = 'Не удалось выполнить отложенное проведение по регистру ""Движения Денежные средства - Контрагент""
						|при расчетах с клиентами по причине';
						|en = 'Cannot execute deferred posting for the ""Records – Cash – Counterparty"" register
						|when performing customer AR/AP. Reason:'; fa = 'Cannot execute deferred posting for the ""Records – Cash – Counterparty"" register
						|when performing customer AR/AP. Reason:';
						|it = 'Non è possibile eseguire una registrazione differita del registro ""Movimento di fondi - Controparte""
						| nel regolamento dei conti con i clienti a causa di';
						|pl = 'Nie powiodło się opóźnione zatwierdzenie po rejestru ""Przepływy pieniężne - Kontrahent""
						|w rozliczeniach z klientami z powodu';
						|tr = 'Aşağıdaki nedenden dolayı müşterilerle yapılan ödemeler için ""Nakit Hareketleri - Cari hesap""
						|kaydında bekleyen işlem gerçekleştirilemedi'") + ":" + Chars.LF + "%Cause%";
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Error, , MessageText);
		Raise MessageText;
	EndTry;

EndProcedure

// The formation of the pending motions in the case "movement of funds - contractor" on the suppliers.
//
// Parameters:
//	DocumentsArray - Array of DocumentRef - array of documents.
//	ModifiedDocuments - ValueTable - table of modified documents.
//	ForDebugging - Structure, Undefined - The structure in which information is returned for debugging.
//
Procedure GenerateCashFlowsCounterpartyToSuppliers(DocumentsArray, ModifiedDocuments = Undefined, ForDebugging = Undefined) Export

	Try
		TempTablesManager = New TempTablesManager;
		MovementData = RegisteredRecordsOfCashCounterparty(DocumentsArray, False, TempTablesManager,
			ForDebugging);
		
		SelectionByDocuments = MovementData.Select(QueryResultIteration.ByGroups);
		While SelectionByDocuments.Next() Do
			RecordCashFlowCounterparty(SelectionByDocuments, ModifiedDocuments, ForDebugging);
		EndDo;
		
		If ForDebugging <> Undefined Then
			ForDebugging.Insert("TempTablesManager", TempTablesManager);
			ForDebugging.Insert("MovementData", MovementData.Unload());
		EndIf;
	Except
		MessageText = NStr("vi = 'Không thể thực hiện kết chuyển hoãn lại theo biểu ghi ""Bản ghi kết chuyển Vốn bằng tiền - Đối tác""
						|khi hạch toán với nhà cung cấp theo nguyên nhân';
						|ru = 'Не удалось выполнить отложенное проведение по регистру ""Движения Денежные средства - Контрагент""
						|при расчетах с поставщиками по причине';
						|en = 'Cannot execute deferred posting for the ""Records – Cash – Counterparty"" register
						|when performing vendor AR/AP. Reason:'; fa = 'Cannot execute deferred posting for the ""Records – Cash – Counterparty"" register
						|when performing vendor AR/AP. Reason:';
						|it = 'Non è possibile eseguire una registrazione differita del registro ""Movimento di fondi - Controparte""
						| nel regolamento dei conti con i fornitoria causa di';
						|pl = 'Nie powiodło się opóźnione zatwierdzenie po rejestru ""Przepływy pieniężne - Kontrahent""
						|w rozliczeniach z dostawcami z powodu';
						|tr = 'Tedarikçilerle yapılan ödemeler için ""Nakit Hareketleri - Cari hesap""
						|ertelenmiş kayıt aşağıdaki nedenden dolayı gerçekleştirilemedi'") + ":" + Chars.LF + "%Cause%";
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Error, , MessageText);
		Raise MessageText;
	EndTry;
	
EndProcedure

// Formation of deferred movements in the "Counterparty - Counterparty Movements" register for suppliers.
//
// Parameters:
//	ArrayOfCalculationDocuments - Array of DocumentRef - an array of documents for which you need to generate traffic.
//	ModifiedDocuments - ValueTable - table of modified documents.
//	ForDebugging - Structure, Undefined - The structure in which information is returned for debugging.
//
Procedure GenerateRegisteredRecordsCounterpartyCounterparty(ArrayOfCalculationDocuments, ModifiedDocuments = Undefined, ForDebugging = Undefined) Export
	
	Try
		
		MovementData = RegisteredRecordedDataCounterpartyCounterparty(ArrayOfCalculationDocuments, ForDebugging);
		
		If Not MovementData = Undefined Then
			SelectionByDocuments = MovementData.Select(QueryResultIteration.ByGroups);
			While SelectionByDocuments.Next() Do
				RecordCounterpartySRegisterRecordsCounterparty(SelectionByDocuments, ModifiedDocuments);
				ToFormRegisterRecordsForOtherAssetsLiabilities(SelectionByDocuments);
			EndDo;
		EndIf;
	
	Except
		
		MessageText = NStr("vi = 'Không thể kết chuyển hoãn lại theo biểu ghi ""Bản ghi kết chuyển Đối tác - Đối tác""
									|do nguyên nhân: %Cause%';
									|ru = 'Не удалось выполнить отложенное проведение по регистру ""Движения Контрагент - Контрагент""
									|по причине: %Cause%';
									|en = 'Cannot execute deferred posting for the ""Records – Cash – Counterparty"" register.
									| Reason: %Cause%'; fa = 'Cannot execute deferred posting for the ""Records – Cash – Counterparty"" register.
									| Reason: %Cause%';
									|it = 'Non è possibile eseguire una registrazione differita del registro ""Movimento di fondi - Controparte""
									| a causa di: %Cause%';
									|pl = 'Nie powiodło się opóźnione zatwierdzenie po rejestru ""Przepływy pieniężne - Kontrahent""
									|z powodu: %Cause%';
									|tr = '""Cari hesap hareketi - Cari hesap""
									|kaydında ertelenmiş kayıt gerçekleştirilemedi çünkü: %Cause%'");
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(
			NStr("vi = 'Hoãn lại kết chuyển khấu trừ';
				|ru = 'Отложенное проведение взаимозачета';
				|en = 'Deferred offsetting'; fa = 'Deferred offsetting';
				|it = 'Regolamento dei conti differito';
				|pl = 'Opóźnione zatwierdzenie kompensaty';
				|tr = 'Ertelenmiş uzlaşma kaydı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			MessageText);
		Raise MessageText;
		
	EndTry;
	
EndProcedure

// Data of the Registered Records of "Registered Records of Cash - Counterparty".
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef - array of documents
//  TheseAreSettlementsWithCustomers - Boolean - Whether to settle accounts with clients
//  TempTablesManager - Undefined, TempTablesManager - temporary table Manager
//  ForDebugging - Undefined, Structure - The structure in which information is returned for debugging.
// 
// Returns:
//  QueryResult - Registered Records data "Registered Records of Cash - Counterparty"
//
Function RegisteredRecordsOfCashCounterparty(DocumentsArray, TheseAreSettlementsWithCustomers = True,
	TempTablesManager = Undefined, ForDebugging = Undefined) Export

	If TempTablesManager = Undefined Then
		TempTablesManager = New TempTablesManager;
	EndIf;
	
	GetReversedDocuments(TempTablesManager, DocumentsArray);
	
	If TheseAreSettlementsWithCustomers Then
		GetSettlementsWithCustomers(TempTablesManager, DocumentsArray, ForDebugging);
	Else
		GetSettlementsWithSuppliers(TempTablesManager, DocumentsArray, ForDebugging);
	EndIf;
	
	ReceiveCashFlowCounterparty(TempTablesManager, DocumentsArray);
	
	MovementData = RecordsCashCounterparty(TempTablesManager, ForDebugging);

	Return MovementData;

EndFunction

// Registered Records data "Registered Records of Counterparty - Counterparty"
// 
// Parameters:
//  ArrayOfCalculationDocuments - Array of DocumentRef - An array of documents to generate Register Records for.
//  ForDebugging - Structure, Undefined - The structure in which information is returned for debugging.
// 
// Returns:
//  Undefined, QueryResult - Registered Records data "Registered Records of Counterparty - Counterparty"
//
Function RegisteredRecordedDataCounterpartyCounterparty(ArrayOfCalculationDocuments, ForDebugging = Undefined) Export
		
		TempTablesManager = New TempTablesManager;
		GetReversedDocuments(TempTablesManager, ArrayOfCalculationDocuments);
		// We will offset accounts payable
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			QueryTextPartnersARAPAccounting = QueryTextPartnersARAPAccounting();
		Else
			QueryTextPartnersARAPAccounting = RequestTextSettlementsWithPartnersOldArchitecture();
		EndIf;
		Query = New Query(QueryTextPartnersARAPAccounting);
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("DocumentsArray", ArrayOfCalculationDocuments);
		PartnersARAPAccounting = Query.ExecuteBatch();
		LastIndex = PartnersARAPAccounting.UBound();
		ParentOrganizations  = PartnersARAPAccounting[LastIndex-2].Unload();
		DebitDocuments  = PartnersARAPAccounting[LastIndex-1].Unload(QueryResultIteration.ByGroups);
		LoanDocuments = PartnersARAPAccounting[LastIndex].Unload();
		
		Head_ = New Map;
		For Each Pair In ParentOrganizations Do
			Head_.Insert(Pair.Organization, Pair.ParentCompany);
		EndDo;
		
		RegisterRecordTable = AccumulationRegisters.RecordsCounterpartyCounterparty.CreateRecordSet().UnloadColumns();
		// We will distribute accounts receivable by accounts payable
		For Each Document In DebitDocuments.Rows Do
			SettlementOfARAP = TypeOf(Document.Recorder) = Type("DocumentRef.ARAPSettlement");
			Filter = New Structure("Recorder");
			For Each Organization In Document.Rows Do
				FillPropertyValues(Filter, Organization);
				If SettlementOfARAP Then
					Filter.Insert("ParentCompany", Head_[Organization.Organization]);
					CreditLines = LoanDocuments.FindRows(Filter);
					If ValueIsFilled(CreditLines) Then
						CarryOutNetting(Organization.Rows, CreditLines, RegisterRecordTable);
					EndIf;
				Else
					UniqueOwners = New Map;
					For Each ARAPObject In Organization.Rows Do
						Parameters = New Structure;
						Parameters.Insert("ThisIsRefundOfAdvance", ARAPObject.ThisIsRefundOfAdvance);
						Parameters.Insert("ParentCompany", ARAPObject.ParentCompany);
						UniqueOwners.Insert(ARAPObject.APARObjectOwner, Parameters);
					EndDo;
					For Each APARObjectOwner In UniqueOwners Do
						If APARObjectOwner.Value.ThisIsRefundOfAdvance Then
							Filter.Insert("ParentCompany", APARObjectOwner.Value.ParentCompany);
						Else
							Filter.Insert("APARObjectOwner", APARObjectOwner.Key);
						EndIf;
						CreditLines = LoanDocuments.FindRows(Filter);
						If ValueIsFilled(CreditLines) Then
							CarryOutNetting(Organization.Rows, CreditLines, RegisterRecordTable);
						EndIf;
					EndDo;
				EndIf;
			EndDo;// On the organization
		EndDo;// by registrars
	
	MovementData = Undefined;
	
	// We will prepare sets for recording
	If RegisterRecordTable.Count() > 0 Then
		RequestRegisteredRecords = New Query(QueryTextRecordsCounterpartyCounterparty());
		RequestRegisteredRecords.SetParameter("RegisterRecordTable", RegisterRecordTable);
		RequestRegisteredRecords.SetParameter("DocumentsArray", ArrayOfCalculationDocuments);
		MovementData = RequestRegisteredRecords.Execute();
	EndIf;
	
	If TypeOf(ForDebugging) = Type("Structure") Then
		ForDebugging.Insert("Query", Query);
		ForDebugging.Insert("QueryResult", PartnersARAPAccounting);
		ForDebugging.Insert("RegisterRecordTable", RegisterRecordTable);
		ForDebugging.Insert("RequestRegisteredRecords", RequestRegisteredRecords);
	EndIf;
	
	Return MovementData;
	
EndFunction

#EndRegion

#Region EventsSubscriptionsHandlers

// Handler for subscribing to the event get outgoing Movementregisters.
//
// Parameters:
//  Source - AccumulationRegisterRecordSet - recorded in the register of accumulation.
//  Cancel - Boolean - indicates that the register set is not being written.
//  Replacing - Boolean - True-the record is performed by replacing existing records in the database.
//
Procedure ReceiveInitialRegisterRecordsBeforeWrite(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If DoNotControlCaseChanges(Source) Then
		Return;
	EndIf;
	
	RegisterName = Source.Metadata().Name;
	QueryText = QueryTextBeforeWrite(RegisterName);
	Source.AdditionalProperties.Insert("ManagerTTManAccounting", New TempTablesManager);
	Query = New Query;
	Query.TempTablesManager = Source.AdditionalProperties.ManagerTTManAccounting;
	Query.Text = QueryText;
	Query.SetParameter("Recorder", Source.Filter.Recorder.Value);
	Query.Execute();

	If RegisterName = "RecordsCounterpartyCounterparty" Then
		RestoreDeferredTransaction(Source);
	EndIf;

EndProcedure

// Handler for subscribing to the event Getrecognizationmovementsregistersreferences.
//
// Parameters:
//  Source - AccumulationRegisterRecordSet - recorded in the register of accumulation.
//  Cancel - Boolean - indicates that the register set is not being written.
//  Replacing - Boolean - True-the record is performed by replacing existing records in the database.
//
Procedure ReceiveFlagOfRegisterRecordChangeOnWrite(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;

	If DoNotControlCaseChanges(Source) Then
		Source.AdditionalProperties.Insert("RegisterDataChanged", True);
		Return;
	EndIf;
	
	QueryText = QueryTextOnWrite(Source.Metadata().Name);
	Query = New Query;
	Query.TempTablesManager = Source.AdditionalProperties.ManagerTTManAccounting;
	Query.Text = QueryText;
	Query.SetParameter("Recorder", Source.Filter.Recorder.Value);
	Source.AdditionalProperties.Insert("RegisterDataChanged", Not Query.Execute().IsEmpty());

EndProcedure

#EndRegion

#Region BalanceSheetStatement

// For the purposes of creating a management balance, it adds movements
// in the other active Arrays register according to the rules for creating a double entry.
//
// Parameters:
//  DocumentReference - DocumentRef, Structure of KeyAndValue - the link of the document for which it is necessary to generate and record the movements of the balance control:
//                                      * Ref - DocumentRef
//  RegisterRecords - RegisterRecordsCollection - sets of records of registers of the instrument.
//
Procedure AddRegisteredRecordsOfAssetsLiabilities(DocumentReference, RegisterRecords) Export
	
	DataProcessors.FlowOfAssetsAndLiabilities.AddDocumentRegisteredRecords(DocumentReference, RegisterRecords);
	
EndProcedure

// For the purposes of forming the management balance, it updates movements in the register of other active Assets 
// after the deferred distribution of settlements with partners.
//
// Parameters:
//  LoggersToReflection - Array of DocumentRef - an array of documents affected by the delayed distribution of mutual settlements with partners.
//  DebugParameters - Structure - advanced setting.
//
Procedure UpdateMovementOfAssetsLiabilitiesOnSettlementsWithPartners(LoggersToReflection, DebugParameters = Undefined) Export
	
	DataProcessors.FlowOfAssetsAndLiabilities.UpdateRegisteredRecordsForSettlementsWithPartners(LoggersToReflection, DebugParameters);
	
EndProcedure

// For the purposes of forming the management balance, it generates a request for movements in the register of other active Assets
// after calculating the cost price.
//
// Parameters:
//  MotionParameters - Structure - parameters for forming the asset/liability balance request.
//  DebugParameters - Structure - additional parameters..
// 
// Returns:
//  Query, Undefined - Request for asset/liability movements
//
Function RequestRegisteredRecordsOfAssetsLiabilities(MotionParameters, DebugParameters = Undefined) Export
	
	Return DataProcessors.FlowOfAssetsAndLiabilities.RequestRegisteredRecords(MotionParameters, DebugParameters);
	
EndFunction

// For the purposes of creating a management balance, it records movements
// in the other active Arrays register according to the rules for creating a double record.
//
// Parameters:
//  DocumentReference - Structure of KeyAndValue
//                       * Link - Document link
//                     Documentlink - the link of the document for which it is necessary to form and record the movements of the upr. balance
//  RegisterRecords - Structure of KeyAndValue
//               * Key - Register name as in metadata
//               * Value - A set of registry entries
//             Collections of movements - sets of document register records stored in a collection of movements or a structure simulating this collection.  
//
Procedure UpdateRegisteredRecordsOfAssetsLiabilities(DocumentReference, RegisterRecords) Export
	
	DataProcessors.FlowOfAssetsAndLiabilities.UpdateDocumentRegisteredRecords(DocumentReference, RegisterRecords);
	
EndProcedure

#EndRegion

// Gets all the registrars of the register of accumulation.
//
// Parameters:
//  RegisterName - String - Name of the accumulation register.
//
// Returns:
//  Array of TypeDescription - types of registrars of the accumulation register.
//
Function ArrayOfRegisterRegistrars(RegisterName) Export

	DocumentsArray = New Array;
	TypesOfLoggers = Metadata.AccumulationRegisters[RegisterName].StandardAttributes.Recorder.Type.Types();
	For Each TypeOfRegistrar In TypesOfLoggers Do
		Recorder = Metadata.FindByType(TypeOfRegistrar);
		If Recorder <> Undefined  Then
			DocumentsArray.Add(Recorder.Name);
		EndIf;
	EndDo;
	
	Return DocumentsArray;

EndFunction

#EndRegion

#Region Private

Procedure GetReversedDocuments(TempTablesManager, DocumentsList)
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	DocumentsRegistry.Ref AS Document,
	|	DocumentsRegistry.ReversedDocument AS ReversedDocument,
	|	DocumentsRegistry.RecordingInAccountingDate AS RecordingInAccountingDate
	|INTO ReversedDocuments
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.Ref IN (&DocumentsList)
	|	AND DocumentsRegistry.ReverseTransactionCorrection
	|
	|INDEX BY
	|	Ref";
	
	Query.TempTablesManager = TempTablesManager;;
	Query.SetParameter("DocumentsList", DocumentsList);
	Query.Execute();

EndProcedure

Procedure GetSettlementsWithCustomers(TempTablesManager, DocumentsList, ForDebugging = Undefined)
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
	
	#Region TextOfRequestForSettlementsWithClientsByTerms
		QueryTextCustomersARAPAccounting = 
		"SELECT
		|	NestedQuery.Recorder AS Recorder,
		|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	NestedQuery.ARAPObject AS OrderDocument,
		|	NestedQuery.ARAPDocument AS ARAPDocument,
		|	NestedQuery.Currency AS Currency,
		|	NestedQuery.CashFlowItem AS CashFlowItem,
		|	NestedQuery.ReversingEntry AS ReversingEntry,
		|	CASE 
		|		WHEN SUM(NestedQuery.Debt) < 0 
		|			THEN -SUM(NestedQuery.Debt)
		|		ELSE SUM(NestedQuery.Debt)
		|	END AS Debt,
		|	CASE 
		|		WHEN SUM(NestedQuery.ARAPMan) < 0 
		|			THEN -SUM(NestedQuery.ARAPMan)
		|		ELSE SUM(NestedQuery.ARAPMan)
		|	END AS ARAPMan,
		|	CASE 
		|		WHEN SUM(NestedQuery.DebtLocal) < 0 
		|			THEN -SUM(NestedQuery.DebtLocal)
		|		ELSE SUM(NestedQuery.DebtLocal)
		|	END AS DebtLocal,
		|	CASE 
		|		WHEN SUM(NestedQuery.Prepayment) < 0 
		|			THEN -SUM(NestedQuery.Prepayment)
		|		ELSE SUM(NestedQuery.Prepayment)
		|	END AS Prepayment,
		|	CASE 
		|		WHEN SUM(NestedQuery.PrepaymentMan) < 0 
		|			THEN -SUM(NestedQuery.PrepaymentMan)
		|		ELSE SUM(NestedQuery.PrepaymentMan)
		|	END AS PrepaymentMan,
		|	CASE 
		|		WHEN SUM(NestedQuery.PrepaymentLocal) < 0 
		|			THEN -SUM(NestedQuery.PrepaymentLocal)
		|		ELSE SUM(NestedQuery.PrepaymentLocal)
		|	END AS PrepaymentLocal
		|INTO CustomersARAPAccounting
		|FROM
		|	(SELECT
		|		PartnersARAPAccounting.DocumentRecorder AS Recorder,
		|		PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|		PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
		|		PartnersARAPAccounting.Currency AS Currency,
		|		PartnersARAPAccounting.CashFlowItem AS CashFlowItem,
		|		FALSE AS ReversingEntry,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.Debt
		|			ELSE -PartnersARAPAccounting.Debt
		|		END AS Debt,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.ARAPMan
		|			ELSE -PartnersARAPAccounting.ARAPMan
		|		END AS ARAPMan,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.DebtLocal
		|			ELSE -PartnersARAPAccounting.DebtLocal
		|		END AS DebtLocal,
		|		PartnersARAPAccounting.Prepayment AS Prepayment,
		|		PartnersARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|		PartnersARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDueDates AS PartnersARAPAccounting
		|	WHERE
		|		PartnersARAPAccounting.DocumentRecorder IN (&DocumentsList)
		|		AND (PartnersARAPAccounting.Debt <> 0 OR PartnersARAPAccounting.Prepayment <> 0)
		|		AND PartnersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
		|		AND NOT PartnersARAPAccounting.ReversingEntry
		|
		|	UNION ALL
		|	
		|	SELECT
		|		ReversedDocuments.Document AS Recorder,
		|		PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|		PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
		|		PartnersARAPAccounting.Currency AS Currency,
		|		PartnersARAPAccounting.CashFlowItem AS CashFlowItem,
		|		TRUE AS ReversingEntry,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.Debt
		|			ELSE -PartnersARAPAccounting.Debt
		|		END AS Debt,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.ARAPMan
		|			ELSE -PartnersARAPAccounting.ARAPMan
		|		END AS ARAPMan,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.DebtLocal
		|			ELSE -PartnersARAPAccounting.DebtLocal
		|		END AS DebtLocal,
		|		PartnersARAPAccounting.Prepayment AS Prepayment,
		|		PartnersARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|		PartnersARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|	FROM
		|		ReversedDocuments AS ReversedDocuments
		|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS PartnersARAPAccounting
		|			ON ReversedDocuments.ReversedDocument = PartnersARAPAccounting.DocumentRecorder
		|	WHERE
		|		(PartnersARAPAccounting.Debt <> 0 OR PartnersARAPAccounting.Prepayment <> 0)
		|		AND PartnersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
		|		AND NOT PartnersARAPAccounting.ReversingEntry
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Recorder,
		|	NestedQuery.AccountingDimensionByPartners,
		|	NestedQuery.ARAPObject,
		|	NestedQuery.ARAPDocument,
		|	NestedQuery.Currency,
		|	NestedQuery.CashFlowItem,
		|	NestedQuery.ReversingEntry
		|HAVING
		|	SUM(NestedQuery.Debt) <> 0 OR SUM(NestedQuery.Prepayment) <> 0
		|;
		|
		|////////////////////////////////////////////
		|SELECT DISTINCT
		|	CustomersARAPAccounting.Recorder AS Recorder,
		|	Dimension.Organization AS Organization,
		|	Dimension.Partner AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	CustomersARAPAccounting.OrderDocument AS OrderDocument,
		|	CustomersARAPAccounting.Currency AS Currency,
		|	CustomersARAPAccounting.CashFlowItem AS CashFlowItem,
		|	CalculationsReturn.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	CustomersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation
		|INTO DocumentsReturnOfPayment
		|FROM
		|	CustomersARAPAccounting AS CustomersARAPAccounting
		|	LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsReturn
		|		ON CustomersARAPAccounting.Recorder = CalculationsReturn.DocumentRecorder
		|		AND CalculationsReturn.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
		|
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|	ON CalculationsReturn.AccountingDimensionByPartners = Dimension.DimensionKey
		|WHERE
		|	CalculationsReturn.DocumentRecorder IS NOT NULL
		|	AND (CustomersARAPAccounting.Debt <> 0 OR CustomersARAPAccounting.Prepayment <> 0)
		|;
		|
		|////////////////////////////////////////////
		|SELECT
		|	PartnersARAPAccounting.DocumentRecorder AS Recorder,
		|	Dimension.Organization AS Organization,
		|	Dimension.Partner AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
		|	PartnersARAPAccounting.Currency AS Currency,
		|	PartnersARAPAccounting.CashFlowItem AS CashFlowItem,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.CorARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.ARAPDocument AS CorSettlementDocument,
		|	PartnersARAPAccounting.Debt AS Debt,
		|	PartnersARAPAccounting.ARAPMan AS ARAPMan,
		|	PartnersARAPAccounting.DebtLocal AS DebtLocal,
		|	PartnersARAPAccounting.Prepayment AS Prepayment,
		|	PartnersARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|	PartnersARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|INTO PaymentTransferBetweenBranchOffices
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates AS PartnersARAPAccounting
		|	INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|	ON PartnersARAPAccounting.ARAPObject = ARAPObjects.Ref
		|
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|	ON PartnersARAPAccounting.CorPartnerAccountingDimension = Dimension.DimensionKey
		|
		|WHERE
		|	PartnersARAPAccounting.DocumentRecorder IN (&DocumentsList)
		|	AND PartnersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
		|	AND PartnersARAPAccounting.CorARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND (PartnersARAPAccounting.Debt <> 0 OR PartnersARAPAccounting.Prepayment <> 0)
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////
		|SELECT
		|	CustomersARAPAccounting.Recorder AS Recorder,
		|	ISNULL(RefundOfPayment.Organization, Dimension.Organization) AS Organization,
		|	Dimension.Partner AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	CustomersARAPAccounting.OrderDocument AS OrderDocument,
		|	CustomersARAPAccounting.ARAPDocument AS ARAPDocument,
		|	CustomersARAPAccounting.Currency AS Currency,
		|	CustomersARAPAccounting.CashFlowItem AS CashFlowItem,
		|	CustomersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	UNDEFINED AS CorARAPObject,
		|	UNDEFINED AS CorSettlementDocument,
		|	CustomersARAPAccounting.Debt AS Debt,
		|	CustomersARAPAccounting.ARAPMan AS ARAPMan,
		|	CustomersARAPAccounting.DebtLocal AS DebtLocal,
		|	CustomersARAPAccounting.Prepayment AS Prepayment,
		|	CustomersARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|	CustomersARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|INTO PartnersARAPAccounting
		|FROM
		|	CustomersARAPAccounting AS CustomersARAPAccounting
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|		ON CustomersARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
		|	LEFT JOIN PaymentTransferBetweenBranchOffices AS PaymentTransferBetweenBranchOffices
		|		ON CustomersARAPAccounting.Recorder = PaymentTransferBetweenBranchOffices.Recorder
		|	LEFT JOIN DocumentsReturnOfPayment AS RefundOfPayment
		|		ON CustomersARAPAccounting.Recorder = RefundOfPayment.Recorder
		|		AND CustomersARAPAccounting.OrderDocument = RefundOfPayment.OrderDocument
		|		AND CustomersARAPAccounting.CashFlowItem = RefundOfPayment.CashFlowItem
		|WHERE
		|	NOT CustomersARAPAccounting.ReversingEntry
		|	AND PaymentTransferBetweenBranchOffices.Recorder IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	CustomersARAPAccounting.Recorder AS Recorder,
		|	Dimension.Organization AS Organization,
		|	Dimension.Partner AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	CustomersARAPAccounting.OrderDocument AS OrderDocument,
		|	CustomersARAPAccounting.ARAPDocument AS ARAPDocument,
		|	CustomersARAPAccounting.Currency AS Currency,
		|	CustomersARAPAccounting.CashFlowItem AS CashFlowItem,
		|	CustomersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	UNDEFINED AS CorARAPObject,
		|	UNDEFINED AS CorSettlementDocument,
		|	-CustomersARAPAccounting.Debt AS Debt,
		|	-CustomersARAPAccounting.ARAPMan AS ARAPMan,
		|	-CustomersARAPAccounting.DebtLocal AS DebtLocal,
		|	-CustomersARAPAccounting.Prepayment AS Prepayment,
		|	-CustomersARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|	-CustomersARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|FROM
		|	CustomersARAPAccounting AS CustomersARAPAccounting
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|		ON CustomersARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
		|	LEFT JOIN PaymentTransferBetweenBranchOffices AS PaymentTransferBetweenBranchOffices
		|		ON CustomersARAPAccounting.Recorder = PaymentTransferBetweenBranchOffices.Recorder
		|WHERE
		|	CustomersARAPAccounting.ReversingEntry
		|	AND PaymentTransferBetweenBranchOffices.Recorder IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	TransferOfPayment.Recorder AS Recorder,
		|	TransferOfPayment.Organization AS Organization,
		|	TransferOfPayment.Partner AS Partner,
		|	TransferOfPayment.Counterparty AS Counterparty,
		|	TransferOfPayment.ARAPObject AS ARAPObject,
		|	TransferOfPayment.ARAPDocument AS ARAPDocument,
		|	TransferOfPayment.Currency AS Currency,
		|	TransferOfPayment.CashFlowItem AS CashFlowItem,
		|	TransferOfPayment.ReversingEntry AS ReversingEntry,
		|	TransferOfPayment.BusinessOperation AS BusinessOperation,
		|	TransferOfPayment.CorARAPObject AS CorARAPObject,
		|	TransferOfPayment.ARAPDocument AS CorSettlementDocument,
		|	TransferOfPayment.Debt AS Debt,
		|	TransferOfPayment.ARAPMan AS ARAPMan,
		|	TransferOfPayment.DebtLocal AS DebtLocal,
		|	TransferOfPayment.Prepayment AS Prepayment,
		|	TransferOfPayment.PrepaymentMan AS PrepaymentMan,
		|	TransferOfPayment.PrepaymentLocal AS PrepaymentLocal
		|FROM
		|	PaymentTransferBetweenBranchOffices AS TransferOfPayment
		|
		|INDEX BY
		|	Recorder,
		|	Organization,
		|	Partner,
		|	Counterparty,
		|	OrderDocument,
		|	CashFlowItem,
		|	Currency
		|";
	#EndRegion
	
	Else
	
	#Region RequestTextForSettlementsWithClientsBasedOnDocuments
		QueryTextCustomersARAPAccounting = 
		"SELECT
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	PartnersARAPAccounting.SalesOrder AS OrderDocument,
		|	PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
		|	PartnersARAPAccounting.Currency AS Currency,
		|	PartnersARAPAccounting.CashFlowItem AS CashFlowItem,
		|	FALSE AS ReversingEntry,
		|	CASE
		|		WHEN PartnersARAPAccounting.Debt < 0
		|			THEN -PartnersARAPAccounting.Debt
		|		ELSE PartnersARAPAccounting.Debt
		|	END AS Debt,
		|	CASE
		|		WHEN PartnersARAPAccounting.ARAPMan < 0
		|			THEN -PartnersARAPAccounting.ARAPMan
		|		ELSE PartnersARAPAccounting.ARAPMan
		|	END AS ARAPMan,
		|	CASE
		|		WHEN PartnersARAPAccounting.DebtLocal < 0
		|			THEN -PartnersARAPAccounting.DebtLocal
		|		ELSE PartnersARAPAccounting.DebtLocal
		|	END AS DebtLocal,
		|	CASE
		|	    WHEN PartnersARAPAccounting.Prepayment < 0
		|			THEN -PartnersARAPAccounting.Prepayment
		|		ELSE PartnersARAPAccounting.Prepayment
		|	END AS Prepayment,
		|	CASE
		|	    WHEN PartnersARAPAccounting.PrepaymentMan < 0
		|			THEN -PartnersARAPAccounting.PrepaymentMan
		|		ELSE PartnersARAPAccounting.PrepaymentMan
		|	END AS PrepaymentMan,
		|	CASE
		|		WHEN PartnersARAPAccounting.PrepaymentLocal < 0
		|			THEN -PartnersARAPAccounting.PrepaymentLocal
		|		ELSE PartnersARAPAccounting.PrepaymentLocal
		|	END AS PrepaymentLocal
		|INTO CustomersARAPAccounting
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.Recorder IN (&DocumentsList)
		|	AND (PartnersARAPAccounting.Debt <> 0
		|		OR PartnersARAPAccounting.Prepayment <> 0
		|		OR PartnersARAPAccounting.ForReturn <> 0
		|	)
		|;
		|////////////////////////////////////////////
		|SELECT
		|	CustomersARAPAccounting.Recorder AS Recorder,
		|	Dimension.Organization AS Organization,
		|	Dimension.Partner AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	CustomersARAPAccounting.OrderDocument AS OrderDocument,
		|	CustomersARAPAccounting.ARAPDocument AS ARAPDocument,
		|	CustomersARAPAccounting.Currency AS Currency,
		|	CustomersARAPAccounting.CashFlowItem AS CashFlowItem,
		|	CustomersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	UNDEFINED AS CorARAPObject,
		|	UNDEFINED AS CorSettlementDocument,
		|	SUM(CustomersARAPAccounting.Debt) AS Debt,
		|	SUM(CustomersARAPAccounting.ARAPMan) AS ARAPMan,
		|	SUM(CustomersARAPAccounting.DebtLocal) AS DebtLocal,
		|	SUM(CustomersARAPAccounting.Prepayment) AS Prepayment,
		|	SUM(CustomersARAPAccounting.PrepaymentMan) AS PrepaymentMan,
		|	SUM(CustomersARAPAccounting.PrepaymentLocal) AS PrepaymentLocal
		|INTO PartnersARAPAccounting
		|FROM
		|	CustomersARAPAccounting AS CustomersARAPAccounting
		|	LEFT JOIN
		|		InformationRegister.AccountingDimensionByPartners AS Dimension
		|	ON
		|		CustomersARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
		|GROUP BY
		|	CustomersARAPAccounting.Recorder,
		|	Dimension.Organization,
		|	Dimension.Partner,
		|	Dimension.Counterparty,
		|	CustomersARAPAccounting.OrderDocument,
		|	CustomersARAPAccounting.ARAPDocument,
		|	CustomersARAPAccounting.Currency,
		|	CustomersARAPAccounting.CashFlowItem,
		|	CustomersARAPAccounting.ReversingEntry
		|
		|INDEX BY
		|	Recorder,
		|	Organization,
		|	Partner,
		|	Counterparty,
		|	OrderDocument,
		|	CashFlowItem,
		|	Currency
		|";
	#EndRegion
	
	EndIf;
	
	Query = New Query(QueryTextCustomersARAPAccounting);
	Query.TempTablesManager = TempTablesManager;;
	Query.SetParameter("DocumentsList", DocumentsList);
	Query.Execute();
	If ForDebugging <> Undefined Then
		ForDebugging.Insert("QueryTextPartnersARAPAccounting", Query.Text);
	EndIf;

EndProcedure

Procedure GetSettlementsWithSuppliers(TempTablesManager, DocumentsList, ForDebugging = Undefined)
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
	
	#Region RequestTextForSettlementsWithSuppliersByTimeFrame
		QueryTextVendorsARAPAccounting = 
		"SELECT
		|	NestedQuery.Recorder AS Recorder,
		|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	NestedQuery.ARAPObject AS OrderDocument,
		|	NestedQuery.ARAPDocument AS ARAPDocument,
		|	NestedQuery.Currency AS Currency,
		|	NestedQuery.CashFlowItem AS CashFlowItem,
		|	NestedQuery.ReversingEntry AS ReversingEntry,
		|	CASE 
		|		WHEN SUM(NestedQuery.Debt) < 0 
		|			THEN -SUM(NestedQuery.Debt)
		|		ELSE SUM(NestedQuery.Debt)
		|	END AS Debt,
		|	CASE 
		|		WHEN SUM(NestedQuery.ARAPMan) < 0 
		|			THEN -SUM(NestedQuery.ARAPMan)
		|		ELSE SUM(NestedQuery.ARAPMan)
		|	END AS ARAPMan,
		|	CASE 
		|		WHEN SUM(NestedQuery.DebtLocal) < 0 
		|			THEN -SUM(NestedQuery.DebtLocal)
		|		ELSE SUM(NestedQuery.DebtLocal)
		|	END AS DebtLocal,
		|	CASE 
		|		WHEN SUM(NestedQuery.Prepayment) < 0 
		|			THEN -SUM(NestedQuery.Prepayment)
		|		ELSE SUM(NestedQuery.Prepayment)
		|	END AS Prepayment,
		|	CASE 
		|		WHEN SUM(NestedQuery.PrepaymentMan) < 0 
		|			THEN -SUM(NestedQuery.PrepaymentMan)
		|		ELSE SUM(NestedQuery.PrepaymentMan)
		|	END AS PrepaymentMan,
		|	CASE 
		|		WHEN SUM(NestedQuery.PrepaymentLocal) < 0 
		|			THEN -SUM(NestedQuery.PrepaymentLocal)
		|		ELSE SUM(NestedQuery.PrepaymentLocal)
		|	END AS PrepaymentLocal
		|INTO VendorsARAPAccounting
		|FROM
		|	(SELECT
		|		PartnersARAPAccounting.DocumentRecorder AS Recorder,
		|		PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|		PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
		|		PartnersARAPAccounting.Currency AS Currency,
		|		PartnersARAPAccounting.CashFlowItem AS CashFlowItem,
		|		FALSE AS ReversingEntry,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.Debt
		|			ELSE -PartnersARAPAccounting.Debt
		|		END AS Debt,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.ARAPMan
		|			ELSE -PartnersARAPAccounting.ARAPMan
		|		END AS ARAPMan,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.DebtLocal
		|			ELSE -PartnersARAPAccounting.DebtLocal
		|		END AS DebtLocal,
		|		PartnersARAPAccounting.Prepayment AS Prepayment,
		|		PartnersARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|		PartnersARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|	FROM
		|		AccumulationRegister.VendorsARAPAccountingByDueDates AS PartnersARAPAccounting
		|	WHERE
		|		PartnersARAPAccounting.DocumentRecorder IN (&DocumentsList)
		|		AND (PartnersARAPAccounting.Debt <> 0 OR PartnersARAPAccounting.Prepayment <> 0)
		|		AND PartnersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
		|		AND NOT PartnersARAPAccounting.ReversingEntry
		|
		|	UNION ALL
		|
		|	SELECT
		|		ReversedDocuments.Document AS Recorder,
		|		PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|		PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
		|		PartnersARAPAccounting.Currency AS Currency,
		|		PartnersARAPAccounting.CashFlowItem AS CashFlowItem,
		|		TRUE AS ReversingEntry,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.Debt
		|			ELSE -PartnersARAPAccounting.Debt
		|		END AS Debt,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.ARAPMan
		|			ELSE -PartnersARAPAccounting.ARAPMan
		|		END AS ARAPMan,
		|		CASE WHEN PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PartnersARAPAccounting.DebtLocal
		|			ELSE -PartnersARAPAccounting.DebtLocal
		|		END AS DebtLocal,
		|		PartnersARAPAccounting.Prepayment AS Prepayment,
		|		PartnersARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|		PartnersARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|	FROM
		|		ReversedDocuments AS ReversedDocuments
		|		LEFT JOIN
		|			AccumulationRegister.VendorsARAPAccountingByDueDates AS PartnersARAPAccounting
		|		ON
		|			ReversedDocuments.ReversedDocument = PartnersARAPAccounting.DocumentRecorder
		|	WHERE
		|		(PartnersARAPAccounting.Debt <> 0 OR PartnersARAPAccounting.Prepayment <> 0)
		|		AND PartnersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
		|		AND NOT PartnersARAPAccounting.ReversingEntry
		|
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Recorder,
		|	NestedQuery.AccountingDimensionByPartners,
		|	NestedQuery.ARAPObject,
		|	NestedQuery.ARAPDocument,
		|	NestedQuery.Currency,
		|	NestedQuery.CashFlowItem,
		|	NestedQuery.ReversingEntry
		|
		|HAVING
		|	SUM(NestedQuery.Debt) <> 0 OR SUM(NestedQuery.Prepayment) <> 0
		|;
		|
		|////////////////////////////////////////////
		|SELECT DISTINCT
		|	VendorsARAPAccounting.Recorder AS Recorder,
		|	Dimension.Organization AS Organization,
		|	Dimension.Partner AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	VendorsARAPAccounting.OrderDocument AS OrderDocument,
		|	VendorsARAPAccounting.Currency AS Currency,
		|	VendorsARAPAccounting.CashFlowItem AS CashFlowItem,
		|	CalculationsReturn.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	VendorsARAPAccounting.ReversingEntry AS ReversingEntry,
		|	VALUE(Enum.BusinessTransactions.RefundFromVendor) AS BusinessOperation
		|INTO DocumentsReturnOfPayment
		|FROM
		|	VendorsARAPAccounting AS VendorsARAPAccounting
		|	LEFT JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsReturn
		|		ON VendorsARAPAccounting.Recorder = CalculationsReturn.DocumentRecorder
		|		AND CalculationsReturn.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor)
		|
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|	ON CalculationsReturn.AccountingDimensionByPartners = Dimension.DimensionKey
		|WHERE
		|	CalculationsReturn.DocumentRecorder IS NOT NULL
		|	AND (VendorsARAPAccounting.Debt <> 0 OR VendorsARAPAccounting.Prepayment <> 0)
		|;
		|
		|////////////////////////////////////////////
		|SELECT
		|	PartnersARAPAccounting.DocumentRecorder AS Recorder,
		|	Dimension.Organization AS Organization,
		|	Dimension.Partner AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
		|	PartnersARAPAccounting.Currency AS Currency,
		|	PartnersARAPAccounting.CashFlowItem AS CashFlowItem,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.CorARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.ARAPDocument AS CorSettlementDocument,
		|	PartnersARAPAccounting.Debt AS Debt,
		|	PartnersARAPAccounting.ARAPMan AS ARAPMan,
		|	PartnersARAPAccounting.DebtLocal AS DebtLocal,
		|	PartnersARAPAccounting.Prepayment AS Prepayment,
		|	PartnersARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|	PartnersARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|INTO PaymentTransferBetweenBranchOffices
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates AS PartnersARAPAccounting
		|	INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|	ON PartnersARAPAccounting.ARAPObject = ARAPObjects.Ref
		|
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|	ON PartnersARAPAccounting.CorPartnerAccountingDimension = Dimension.DimensionKey
		|
		|WHERE
		|	PartnersARAPAccounting.DocumentRecorder IN (&DocumentsList)
		|	AND PartnersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
		|	AND PartnersARAPAccounting.CorARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND (PartnersARAPAccounting.Debt <> 0 OR PartnersARAPAccounting.Prepayment <> 0)
		|INDEX BY
		|	Recorder
		|;
		|
		|///////////////////////////////////////////////////////
		|SELECT
		|	VendorsARAPAccounting.Recorder AS Recorder,
		|	ISNULL(RefundOfPayment.Organization, Dimension.Organization) AS Organization,
		|	ISNULL(RefundOfPayment.Partner, Dimension.Partner) AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	VendorsARAPAccounting.OrderDocument AS OrderDocument,
		|	VendorsARAPAccounting.ARAPDocument AS ARAPDocument,
		|	VendorsARAPAccounting.Currency AS Currency,
		|	VendorsARAPAccounting.CashFlowItem AS CashFlowItem,
		|	VendorsARAPAccounting.ReversingEntry AS ReversingEntry,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	UNDEFINED AS CorARAPObject,
		|	UNDEFINED AS CorSettlementDocument,
		|	VendorsARAPAccounting.Debt AS Debt,
		|	VendorsARAPAccounting.ARAPMan AS ARAPMan,
		|	VendorsARAPAccounting.DebtLocal AS DebtLocal,
		|	VendorsARAPAccounting.Prepayment AS Prepayment,
		|	VendorsARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|	VendorsARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|INTO PartnersARAPAccounting
		|FROM
		|	VendorsARAPAccounting AS VendorsARAPAccounting
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|		ON VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
		|	LEFT JOIN PaymentTransferBetweenBranchOffices AS PaymentTransferBetweenBranchOffices
		|		ON VendorsARAPAccounting.Recorder = PaymentTransferBetweenBranchOffices.Recorder
		|	LEFT JOIN DocumentsReturnOfPayment AS RefundOfPayment
		|		ON VendorsARAPAccounting.Recorder = RefundOfPayment.Recorder
		|		AND VendorsARAPAccounting.OrderDocument = RefundOfPayment.OrderDocument
		|		AND VendorsARAPAccounting.CashFlowItem = RefundOfPayment.CashFlowItem
		|WHERE
		|	NOT VendorsARAPAccounting.ReversingEntry
		|	AND PaymentTransferBetweenBranchOffices.Recorder IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	VendorsARAPAccounting.Recorder AS Recorder,
		|	ISNULL(RefundOfPayment.Organization, Dimension.Organization) AS Organization,
		|	ISNULL(RefundOfPayment.Partner, Dimension.Partner) AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	VendorsARAPAccounting.OrderDocument AS OrderDocument,
		|	VendorsARAPAccounting.ARAPDocument AS ARAPDocument,
		|	VendorsARAPAccounting.Currency AS Currency,
		|	VendorsARAPAccounting.CashFlowItem AS CashFlowItem,
		|	VendorsARAPAccounting.ReversingEntry AS ReversingEntry,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	UNDEFINED AS CorARAPObject,
		|	UNDEFINED AS CorSettlementDocument,
		|	-VendorsARAPAccounting.Debt AS Debt,
		|	-VendorsARAPAccounting.ARAPMan AS ARAPMan,
		|	-VendorsARAPAccounting.DebtLocal AS DebtLocal,
		|	-VendorsARAPAccounting.Prepayment AS Prepayment,
		|	-VendorsARAPAccounting.PrepaymentMan AS PrepaymentMan,
		|	-VendorsARAPAccounting.PrepaymentLocal AS PrepaymentLocal
		|FROM
		|	VendorsARAPAccounting AS VendorsARAPAccounting
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
		|		ON VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
		|	LEFT JOIN PaymentTransferBetweenBranchOffices AS PaymentTransferBetweenBranchOffices
		|		ON VendorsARAPAccounting.Recorder = PaymentTransferBetweenBranchOffices.Recorder
		|	LEFT JOIN DocumentsReturnOfPayment AS RefundOfPayment
		|		ON VendorsARAPAccounting.Recorder = RefundOfPayment.Recorder
		|		AND VendorsARAPAccounting.OrderDocument = RefundOfPayment.OrderDocument
		|		AND VendorsARAPAccounting.CashFlowItem = RefundOfPayment.CashFlowItem
		|WHERE
		|	VendorsARAPAccounting.ReversingEntry
		|	AND PaymentTransferBetweenBranchOffices.Recorder IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	TransferOfPayment.Recorder AS Recorder,
		|	TransferOfPayment.Organization AS Organization,
		|	TransferOfPayment.Partner AS Partner,
		|	TransferOfPayment.Counterparty AS Counterparty,
		|	TransferOfPayment.ARAPObject AS ARAPObject,
		|	TransferOfPayment.ARAPDocument AS ARAPDocument,
		|	TransferOfPayment.Currency AS Currency,
		|	TransferOfPayment.CashFlowItem AS CashFlowItem,
		|	TransferOfPayment.ReversingEntry AS ReversingEntry,
		|	TransferOfPayment.BusinessOperation AS BusinessOperation,
		|	TransferOfPayment.CorARAPObject AS CorARAPObject,
		|	TransferOfPayment.ARAPDocument AS CorSettlementDocument,
		|	TransferOfPayment.Debt AS Debt,
		|	TransferOfPayment.ARAPMan AS ARAPMan,
		|	TransferOfPayment.DebtLocal AS DebtLocal,
		|	TransferOfPayment.Prepayment AS Prepayment,
		|	TransferOfPayment.PrepaymentMan AS PrepaymentMan,
		|	TransferOfPayment.PrepaymentLocal AS PrepaymentLocal
		|FROM
		|	PaymentTransferBetweenBranchOffices AS TransferOfPayment
		|
		|INDEX BY
		|	Recorder,
		|	Organization,
		|	Partner,
		|	Counterparty,
		|	OrderDocument,
		|	CashFlowItem,
		|	ReversingEntry,
		|	Currency
		|";
	#EndRegion
	
	Else
	
	#Region RequestTextForSettlementsWithSuppliersBasedOnDocuments
		QueryTextVendorsARAPAccounting = 
		"SELECT
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	PartnersARAPAccounting.PurchaseOrder AS OrderDocument,
		|	PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
		|	PartnersARAPAccounting.Currency AS Currency,
		|	PartnersARAPAccounting.CashFlowItem AS CashFlowItem,
		|	FALSE AS ReversingEntry,
		|	CASE
		|		WHEN PartnersARAPAccounting.Debt < 0
		|			THEN -PartnersARAPAccounting.Debt
		|		ELSE PartnersARAPAccounting.Debt
		|	END AS Debt,
		|	CASE
		|		WHEN PartnersARAPAccounting.ARAPMan < 0
		|			THEN -PartnersARAPAccounting.ARAPMan
		|		ELSE PartnersARAPAccounting.ARAPMan
		|	END AS ARAPMan,
		|	CASE
		|		WHEN PartnersARAPAccounting.DebtLocal < 0
		|			THEN -PartnersARAPAccounting.DebtLocal
		|		ELSE PartnersARAPAccounting.DebtLocal
		|	END AS DebtLocal,
		|	CASE
		|		WHEN PartnersARAPAccounting.Prepayment < 0
		|			THEN -PartnersARAPAccounting.Prepayment
		|		ELSE PartnersARAPAccounting.Prepayment
		|	END AS Prepayment,
		|	CASE
		|		WHEN PartnersARAPAccounting.PrepaymentMan < 0
		|			THEN -PartnersARAPAccounting.PrepaymentMan
		|		ELSE PartnersARAPAccounting.PrepaymentMan
		|	END AS PrepaymentMan,
		|	CASE
		|		WHEN PartnersARAPAccounting.PrepaymentLocal < 0
		|			THEN -PartnersARAPAccounting.PrepaymentLocal
		|		ELSE PartnersARAPAccounting.PrepaymentLocal
		|	END AS PrepaymentLocal
		|INTO VendorsARAPAccounting
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.Recorder IN (&DocumentsList)
		|	AND (PartnersARAPAccounting.Debt <> 0
		|		OR PartnersARAPAccounting.Prepayment <> 0
		|		OR PartnersARAPAccounting.ForReturn <> 0
		|	)
		|;
		|///////////////////////////////////////////////////////
		|SELECT
		|	VendorsARAPAccounting.Recorder AS Recorder,
		|	Dimension.Organization AS Organization,
		|	Dimension.Partner AS Partner,
		|	Dimension.Counterparty AS Counterparty,
		|	VendorsARAPAccounting.OrderDocument AS OrderDocument,
		|	VendorsARAPAccounting.ARAPDocument AS ARAPDocument,
		|	VendorsARAPAccounting.Currency AS Currency,
		|	VendorsARAPAccounting.CashFlowItem AS CashFlowItem,
		|	VendorsARAPAccounting.ReversingEntry,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	UNDEFINED AS CorARAPObject,
		|	UNDEFINED AS CorSettlementDocument,
		|	SUM(VendorsARAPAccounting.Debt) AS Debt,
		|	SUM(VendorsARAPAccounting.ARAPMan) AS ARAPMan,
		|	SUM(VendorsARAPAccounting.DebtLocal) AS DebtLocal,
		|	SUM(VendorsARAPAccounting.Prepayment) AS Prepayment,
		|	SUM(VendorsARAPAccounting.PrepaymentMan) AS PrepaymentMan,
		|	SUM(VendorsARAPAccounting.PrepaymentLocal) AS PrepaymentLocal
		|INTO PartnersARAPAccounting
		|FROM
		|	VendorsARAPAccounting AS VendorsARAPAccounting
		|	LEFT JOIN
		|		InformationRegister.AccountingDimensionByPartners AS Dimension
		|	ON
		|		VendorsARAPAccounting.AccountingDimensionByPartners = Dimension.DimensionKey
		|GROUP BY
		|	VendorsARAPAccounting.Recorder,
		|	Dimension.Organization,
		|	Dimension.Partner,
		|	Dimension.Counterparty,
		|	VendorsARAPAccounting.OrderDocument,
		|	VendorsARAPAccounting.ARAPDocument,
		|	VendorsARAPAccounting.Currency,
		|	VendorsARAPAccounting.CashFlowItem,
		|	VendorsARAPAccounting.ReversingEntry
		|
		|INDEX BY
		|	Recorder,
		|	Organization,
		|	Partner,
		|	Counterparty,
		|	OrderDocument,
		|	CashFlowItem,
		|	Currency
		|";
	#EndRegion
	
	EndIf;
	
	Query = New Query(QueryTextVendorsARAPAccounting);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("DocumentsList", DocumentsList);
	Query.Execute();
	If ForDebugging <> Undefined Then
		ForDebugging.Insert("QueryTextPartnersARAPAccounting", Query.Text);
	EndIf;

EndProcedure

Procedure ReceiveCashFlowCounterparty(TempTablesManager, DocumentsList)

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Active AS Active,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusinessCash AS LineOfBusinessCash,
	|
	|	RegisterData.Cash AS Cash,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.PaymentCurrency AS PaymentCurrency,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.ARAPDocument AS ARAPDocument,
	|	RegisterData.TargetFundItem AS TargetFundItem,
	|
	|	RegisterData.PayAmount AS PayAmount,
	|	RegisterData.PaymentAmountLocal AS PaymentAmountLocal,
	|	RegisterData.PaymentAmountPaymentCurrency AS PaymentAmountPaymentCurrency,
	|	
	|	RegisterData.PostpaymentAmount AS PostpaymentAmount,
	|	RegisterData.PostpaymentAmountLocal AS PostpaymentAmountLocal,
	|	RegisterData.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
	|
	|	RegisterData.PrepaymentAmountMan AS PrepaymentAmountMan,
	|	RegisterData.PrepaymentAmountLocal AS PrepaymentAmountLocal,
	|	RegisterData.PrepaymentAmount AS PrepaymentAmount,
	|
	|	RegisterData.AmountToBePaidWithinLimit AS AmountToBePaidWithinLimit,
	|	RegisterData.AmountToBePaidAboveLimit AS AmountToBePaidAboveLimit,
	|
	|	RegisterData.VATAmount AS VATAmount,
	|	RegisterData.VATAmountCompl AS VATAmountCompl,
	|	RegisterData.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	RegisterData.PaymentAmountInTheSettlementCurrency AS PaymentAmountInTheSettlementCurrency,
	|	RegisterData.PostPaymentAmountInARAPCurrency AS PostPaymentAmountInARAPCurrency,
	|	RegisterData.PrepaymentAmountInARAPCurrency AS PrepaymentAmountInARAPCurrency,
	|
	|	RegisterData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.VATRate AS VATRate,
	|	RegisterData.PaymentRequest AS PaymentRequest,
	|	RegisterData.DeferredPosting AS DeferredPosting,
	|	RegisterData.ReversingEntry AS ReversingEntry
	|INTO RegisterData
	|FROM
	|	AccumulationRegister.RecordsCashCounterparty AS RegisterData
	|WHERE
	|	RegisterData.Recorder IN (&DocumentsList)
	|INDEX BY
	|	Period,
	|	ARAPCurrency,
	|	PaymentCurrency
	|;
	|
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Active AS Active,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusinessCash AS LineOfBusinessCash,
	|
	|	RegisterData.Cash AS Cash,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.PaymentCurrency AS PaymentCurrency,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.ARAPDocument AS ARAPDocument,
	|	RegisterData.TargetFundItem AS TargetFundItem,
	|
	|	SUM(RegisterData.PayAmount) AS PayAmount,
	|	SUM(RegisterData.PaymentAmountLocal) AS PaymentAmountLocal,
	|	SUM(RegisterData.PaymentAmountPaymentCurrency) AS PaymentAmountPaymentCurrency,
	|	
	|	SUM(RegisterData.PostpaymentAmount) AS PostpaymentAmount,
	|	SUM(RegisterData.PostpaymentAmountLocal) AS PostpaymentAmountLocal,
	|	SUM(RegisterData.PaymentAmountInPaymentCurrency) AS PaymentAmountInPaymentCurrency,
	|
	|	SUM(RegisterData.PrepaymentAmountMan) AS PrepaymentAmountMan,
	|	SUM(RegisterData.PrepaymentAmountLocal) AS PrepaymentAmountLocal,
	|	SUM(RegisterData.PrepaymentAmount) AS PrepaymentAmount,
	|
	|	SUM(RegisterData.AmountToBePaidWithinLimit) AS AmountToBePaidWithinLimit,
	|	SUM(RegisterData.AmountToBePaidAboveLimit) AS AmountToBePaidAboveLimit,
	|
	|	SUM(RegisterData.VATAmount) AS VATAmount,
	|	SUM(RegisterData.VATAmountCompl) AS VATAmountCompl,
	|	SUM(RegisterData.AmountVATCurrencyPayment) AS AmountVATCurrencyPayment,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	SUM(RegisterData.PaymentAmountInTheSettlementCurrency) AS PaymentAmountInTheSettlementCurrency,
	|	SUM(RegisterData.PostPaymentAmountInARAPCurrency) AS PostPaymentAmountInARAPCurrency,
	|	SUM(RegisterData.PrepaymentAmountInARAPCurrency) AS PrepaymentAmountInARAPCurrency,
	|
	|	RegisterData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.VATRate AS VATRate,
	|	RegisterData.DeferredPosting AS DeferredPosting,
	|	RegisterData.ReversingEntry AS ReversingEntry
	|INTO RegisterDataWithoutApplications
	|FROM
	|	RegisterData AS RegisterData
	|
	|GROUP BY
	|	RegisterData.Period,
	|	RegisterData.Active,
	|	RegisterData.Recorder,
	|	RegisterData.BusinessOperation,
	|	RegisterData.Organization,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusinessCash,
	|
	|	RegisterData.Cash,
	|	RegisterData.CashType,
	|	RegisterData.CashFlowItem,
	|	RegisterData.PaymentCurrency,
	|	RegisterData.ProductCostElement,
	|	RegisterData.PaymentType275FZ,
	|	RegisterData.CounterpartyLineOfBusiness,
	|
	|	RegisterData.Partner,
	|	RegisterData.Counterparty,
	|	RegisterData.Contract,
	|	RegisterData.ARAPObject,
	|	RegisterData.ARAPDocument,
	|	RegisterData.TargetFundItem,
	|
	|	RegisterData.ARAPCurrency,
	|
	|	RegisterData.SourceOfCashFinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.VATRate,
	|	RegisterData.DeferredPosting,
	|	RegisterData.ReversingEntry
	|
	|INDEX BY
	|	Period,
	|	ARAPCurrency,
	|	PaymentCurrency
	|;
	|
	|SELECT TOP 1
	|	RegisterData.Period AS Period
	|FROM 
	|	RegisterData AS RegisterData
	|ORDER BY
	|	RegisterData.Period ASC
	|";
	
	Query.SetParameter("DocumentsList", DocumentsList);
	Selection = Query.Execute().Select();
	StartDate = '00010101';
	If Selection.Next() Then
		StartDate = Selection.Period;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	ExchangeRates.Period AS Period,
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&StartDate, ) AS ExchangeRates
	|
	|UNION ALL
	|
	|SELECT
	|	ExchangeRates.Period,
	|	ExchangeRates.Currency,
	|	ExchangeRates.BaseCurrency,
	|	ExchangeRates.CourseNumerator,
	|	ExchangeRates.CourseDenominator
	|FROM
	|	InformationRegister.RelativeExchangeRates AS ExchangeRates
	|WHERE
	|	ExchangeRates.Period > &StartDate
	|
	|INDEX BY
	|	ExchangeRates.Period,
	|	ExchangeRates.Currency,
	|	ExchangeRates.BaseCurrency
	|;
	|
	|SELECT
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	MAX(ExchangeRates.Period) AS DateOfExchangeRateOfMutualSettlements
	|INTO DatesOfExchangeRatesOfMutualSettlements
	|FROM
	|	RegisterData AS RegisterData
	|	LEFT JOIN
	|		ExchangeRates AS ExchangeRates
	|	ON
	|		RegisterData.ARAPCurrency = ExchangeRates.Currency
	|		AND RegisterData.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|		AND RegisterData.Period >= ExchangeRates.Period
	|GROUP BY
	|	RegisterData.Recorder,
	|	RegisterData.ARAPCurrency
	|;
	|
	|SELECT
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.PaymentCurrency AS PaymentCurrency,
	|	MAX(ExchangeRates.Period) AS DateOfPaymentCurrencyExchangeRate
	|INTO DatesOfPaymentCurrencyExchangeRates
	|FROM
	|	RegisterData AS RegisterData
	|	LEFT JOIN
	|		ExchangeRates AS ExchangeRates
	|	ON
	|		RegisterData.PaymentCurrency = ExchangeRates.Currency
	|		AND RegisterData.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|		AND RegisterData.Period >= ExchangeRates.Period
	|GROUP BY
	|	RegisterData.Recorder,
	|	RegisterData.PaymentCurrency
	|
	|";
    Query.SetParameter("StartDate", StartDate);
	Query.Execute();
	
EndProcedure

Function RecordsCashCounterparty(TempTablesManager, ForDebugging = Undefined)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Active AS Active,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusinessCash AS LineOfBusinessCash,
	|
	|	RegisterData.Cash AS Cash,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.PaymentCurrency AS PaymentCurrency,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.ARAPDocument AS ARAPDocument,
	|	RegisterData.TargetFundItem AS TargetFundItem,
	|
	|	RegisterData.PayAmount AS PayAmount,
	|	RegisterData.PaymentAmountLocal AS PaymentAmountLocal,
	|	RegisterData.PaymentAmountPaymentCurrency AS PaymentAmountPaymentCurrency,
	|	
	|	RegisterData.PostpaymentAmount AS PostpaymentAmount,
	|	RegisterData.PostpaymentAmountLocal AS PostpaymentAmountLocal,
	|	RegisterData.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
	|
	|	RegisterData.PrepaymentAmountMan AS PrepaymentAmountMan,
	|	RegisterData.PrepaymentAmountLocal AS PrepaymentAmountLocal,
	|	RegisterData.PrepaymentAmount AS PrepaymentAmount,
	|
	|	RegisterData.AmountToBePaidWithinLimit AS AmountToBePaidWithinLimit,
	|	RegisterData.AmountToBePaidAboveLimit AS AmountToBePaidAboveLimit,
	|
	|	RegisterData.VATAmount AS VATAmount,
	|	RegisterData.VATAmountCompl AS VATAmountCompl,
	|	RegisterData.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	RegisterData.PaymentAmountInTheSettlementCurrency AS PaymentAmountInTheSettlementCurrency,
	|	RegisterData.PostPaymentAmountInARAPCurrency AS PostPaymentAmountInARAPCurrency,
	|	RegisterData.PrepaymentAmountInARAPCurrency AS PrepaymentAmountInARAPCurrency,
	|
	|	RegisterData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.VATRate AS VATRate,
	|	RegisterData.PaymentRequest AS PaymentRequest,
	|	RegisterData.DeferredPosting AS DeferredPosting,
	|	RegisterData.ReversingEntry
	|INTO TTNewRegisteredRecords
	|FROM
	|	RegisterData AS RegisterData
	|WHERE
	|	NOT RegisterData.DeferredPosting
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Active AS Active,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusinessCash AS LineOfBusinessCash,
	|
	|	RegisterData.Cash AS Cash,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.PaymentCurrency AS PaymentCurrency,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.ARAPDocument AS ARAPDocument,
	|	RegisterData.TargetFundItem AS TargetFundItem,
	|
	|	RegisterData.PayAmount AS PayAmount,
	|	RegisterData.PaymentAmountLocal AS PaymentAmountLocal,
	|	RegisterData.PaymentAmountPaymentCurrency AS PaymentAmountPaymentCurrency,
	|	
	|	RegisterData.PostpaymentAmount AS PostpaymentAmount,
	|	RegisterData.PostpaymentAmountLocal AS PostpaymentAmountLocal,
	|	RegisterData.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
	|
	|	RegisterData.PrepaymentAmountMan AS PrepaymentAmountMan,
	|	RegisterData.PrepaymentAmountLocal AS PrepaymentAmountLocal,
	|	RegisterData.PrepaymentAmount AS PrepaymentAmount,
	|
	|	0 AS AmountToBePaidWithinLimit,
	|	0 AS AmountToBePaidAboveLimit,
	|
	|	RegisterData.VATAmount AS VATAmount,
	|	RegisterData.VATAmountCompl AS VATAmountCompl,
	|	RegisterData.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	RegisterData.PaymentAmountInTheSettlementCurrency AS PaymentAmountInTheSettlementCurrency,
	|	RegisterData.PostPaymentAmountInARAPCurrency AS PostPaymentAmountInARAPCurrency,
	|	RegisterData.PrepaymentAmountInARAPCurrency AS PrepaymentAmountInARAPCurrency,
	|
	|	RegisterData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.VATRate AS VATRate,
	|	RegisterData.PaymentRequest AS PaymentRequest,
	|	RegisterData.DeferredPosting AS DeferredPosting,
	|	RegisterData.ReversingEntry AS ReversingEntry
	|FROM
	|	RegisterData AS RegisterData
	|	LEFT JOIN
	|		PartnersARAPAccounting AS PartnersARAPAccounting
	|	ON 
	|		RegisterData.Recorder = PartnersARAPAccounting.Recorder
	|		AND RegisterData.Organization = PartnersARAPAccounting.Organization
	|		AND RegisterData.ARAPCurrency = PartnersARAPAccounting.Currency
	|		AND RegisterData.ReversingEntry = PartnersARAPAccounting.ReversingEntry
	|WHERE
	|	PartnersARAPAccounting.Organization IS NULL
	|	AND RegisterData.DeferredPosting
	|	AND RegisterData.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|	AND RegisterData.VATAmount = 0
	|
	|UNION ALL
	|
	|// everything except the business of operation of rescheduling the paymentmedials
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Active AS Active,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusinessCash AS LineOfBusinessCash,
	|	
	|	RegisterData.Cash AS Cash,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.PaymentCurrency AS PaymentCurrency,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
	|	RegisterData.TargetFundItem AS TargetFundItem,
	|
	|	0 AS PayAmount,
	|	0 AS PaymentAmountLocal,
	|	0 AS PaymentAmountPaymentCurrency,
	|
	|	PartnersARAPAccounting.ARAPMan AS PostpaymentAmount,
	|	PartnersARAPAccounting.DebtLocal AS PostpaymentAmountLocal,
	|	PartnersARAPAccounting.Debt AS PaymentAmountInPaymentCurrency,
	|
	|	PartnersARAPAccounting.PrepaymentMan AS PrepaymentAmountMan,
	|	PartnersARAPAccounting.PrepaymentLocal AS PrepaymentAmountLocal,
	|	PartnersARAPAccounting.Prepayment AS PrepaymentAmount,
	|
	|	0 AS AmountToBePaidWithinLimit,
	|	0 AS AmountToBePaidAboveLimit,
	|
	|	RegisterData.VATAmount AS VATAmount,
	|	RegisterData.VATAmountCompl AS VATAmountCompl,
	|	RegisterData.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	0 AS PaymentAmountInTheSettlementCurrency,
	|	PartnersARAPAccounting.Debt AS PostPaymentAmountInARAPCurrency,
	|	PartnersARAPAccounting.Prepayment AS PrepaymentAmountInARAPCurrency,
	|
	|	RegisterData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.VATRate AS VATRate,
	|	UNDEFINED AS PaymentRequest,
	|	TRUE AS DeferredPosting,
	|	RegisterData.ReversingEntry AS ReversingEntry
	|
	|FROM
	|	RegisterDataWithoutApplications AS RegisterData
	|	INNER JOIN PartnersARAPAccounting AS PartnersARAPAccounting
	|	ON RegisterData.Recorder = PartnersARAPAccounting.Recorder
	|		AND RegisterData.Organization = PartnersARAPAccounting.Organization
	|		AND RegisterData.Partner = PartnersARAPAccounting.Partner
	|		AND RegisterData.Counterparty = PartnersARAPAccounting.Counterparty
	|		AND RegisterData.ARAPObject = PartnersARAPAccounting.OrderDocument
	|		AND RegisterData.CashFlowItem = PartnersARAPAccounting.CashFlowItem
	|		AND RegisterData.ARAPCurrency = PartnersARAPAccounting.Currency
	|		AND RegisterData.ReversingEntry = PartnersARAPAccounting.ReversingEntry
	|WHERE
	|	NOT RegisterData.DeferredPosting
	|	AND RegisterData.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|	AND RegisterData.VATAmount = 0
	|	AND PartnersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|	AND NOT RegisterData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices))
	|
	|UNION ALL
	|
	|// The Registered Records of the economic Operation of the rescheduling of the paymentreferences
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Active AS Active,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusinessCash AS LineOfBusinessCash,
	|	
	|	RegisterData.Cash AS Cash,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.PaymentCurrency AS PaymentCurrency,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	PartnersARAPAccounting.OrderDocument AS ARAPObject,
	|	PartnersARAPAccounting.ARAPDocument AS ARAPDocument,
	|	RegisterData.TargetFundItem AS TargetFundItem,
	|
	|	0 AS PayAmount,
	|	0 AS PaymentAmountLocal,
	|	0 AS PaymentAmountPaymentCurrency,
	|
	|	PartnersARAPAccounting.ARAPMan AS PostpaymentAmount,
	|	PartnersARAPAccounting.DebtLocal AS PostpaymentAmountLocal,
	|	PartnersARAPAccounting.Debt AS PaymentAmountInPaymentCurrency,
	|
	|	PartnersARAPAccounting.PrepaymentMan AS PrepaymentAmountMan,
	|	PartnersARAPAccounting.PrepaymentLocal AS PrepaymentAmountLocal,
	|	PartnersARAPAccounting.Prepayment AS PrepaymentAmount,
	|
	|	0 AS AmountToBePaidWithinLimit,
	|	0 AS AmountToBePaidAboveLimit,
	|
	|	RegisterData.VATAmount AS VATAmount,
	|	RegisterData.VATAmountCompl AS VATAmountCompl,
	|	RegisterData.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	0 AS PaymentAmountInTheSettlementCurrency,
	|	PartnersARAPAccounting.Debt AS PostPaymentAmountInARAPCurrency,
	|	PartnersARAPAccounting.Prepayment AS PrepaymentAmountInARAPCurrency,
	|
	|	RegisterData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	PartnersARAPAccounting.OrderDocument AS SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.VATRate AS VATRate,
	|	UNDEFINED AS PaymentRequest,
	|	TRUE AS DeferredPosting,
	|	RegisterData.ReversingEntry AS ReversingEntry
	|FROM
	|	RegisterDataWithoutApplications AS RegisterData
	|	INNER JOIN PartnersARAPAccounting AS PartnersARAPAccounting
	|	ON RegisterData.Recorder = PartnersARAPAccounting.Recorder
	|		AND RegisterData.Organization = PartnersARAPAccounting.Organization
	|		AND RegisterData.Partner = PartnersARAPAccounting.Partner
	|		AND RegisterData.Counterparty = PartnersARAPAccounting.Counterparty
	|		AND RegisterData.ARAPObject = PartnersARAPAccounting.CorARAPObject
	|		AND RegisterData.CashFlowItem = PartnersARAPAccounting.CashFlowItem
	|		AND RegisterData.ARAPCurrency = PartnersARAPAccounting.Currency
	|WHERE
	|	NOT RegisterData.DeferredPosting
	|	AND RegisterData.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|	AND RegisterData.VATAmount = 0
	|	AND PartnersARAPAccounting.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices))
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|SELECT
	|	MovementChanges.Recorder AS Recorder,
	|	
	|	SUM(MovementChanges.PostpaymentAmount) AS PostpaymentAmount,
	|	SUM(MovementChanges.PostpaymentAmountLocal) AS PostpaymentAmountLocal,
	|	SUM(MovementChanges.PaymentAmountInPaymentCurrency) AS PaymentAmountInPaymentCurrency,
	|
	|	SUM(MovementChanges.PrepaymentAmountMan) AS PrepaymentAmountMan,
	|	SUM(MovementChanges.PrepaymentAmountLocal) AS PrepaymentAmountLocal,
	|	SUM(MovementChanges.PrepaymentAmount) AS PrepaymentAmount,
	|	MAX(MovementChanges.ReversingEntry) AS ReversingEntry
	|
	|INTO TTModifiedDocuments
	|FROM
	|	(SELECT
	|		RegisterData.Recorder AS Recorder,
	|	
	|		RegisterData.PostpaymentAmount AS PostpaymentAmount,
	|		RegisterData.PostpaymentAmountLocal AS PostpaymentAmountLocal,
	|		RegisterData.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
	|
	|		RegisterData.PrepaymentAmountMan AS PrepaymentAmountMan,
	|		RegisterData.PrepaymentAmountLocal AS PrepaymentAmountLocal,
	|		RegisterData.PrepaymentAmount AS PrepaymentAmount,
	|		RegisterData.ReversingEntry AS ReversingEntry
	|	FROM
	|		RegisterData AS RegisterData
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterData.Recorder AS Recorder,
	|	
	|		-RegisterData.PostpaymentAmount AS PostpaymentAmount,
	|		-RegisterData.PostpaymentAmountLocal AS PostpaymentAmountLocal,
	|		-RegisterData.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
	|
	|		-RegisterData.PrepaymentAmountMan AS PrepaymentAmountMan,
	|		-RegisterData.PrepaymentAmountLocal AS PrepaymentAmountLocal,
	|		-RegisterData.PrepaymentAmount AS PrepaymentAmount,
	|		RegisterData.ReversingEntry AS ReversingEntry
	|	FROM
	|		TTNewRegisteredRecords AS RegisterData) AS MovementChanges
	|GROUP BY
	|	MovementChanges.Recorder
	|
	|HAVING
	|	SUM(MovementChanges.PostpaymentAmount) <> 0
	|	OR SUM(MovementChanges.PostpaymentAmountLocal) <> 0
	|	OR SUM(MovementChanges.PaymentAmountInPaymentCurrency) <> 0
	|
	|	OR SUM(MovementChanges.PrepaymentAmountMan) <> 0
	|	OR SUM(MovementChanges.PrepaymentAmountLocal) <> 0
	|	OR SUM(MovementChanges.PrepaymentAmount) <> 0
	|	OR MAX(MovementChanges.ReversingEntry)
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Active AS Active,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.BusinessOperation AS BusinessOperation,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.Department AS Department,
	|	RegisterData.LineOfBusinessCash AS LineOfBusinessCash,
	|
	|	RegisterData.Cash AS Cash,
	|	RegisterData.CashType AS CashType,
	|	RegisterData.CashFlowItem AS CashFlowItem,
	|	RegisterData.PaymentCurrency AS PaymentCurrency,
	|	RegisterData.ProductCostElement AS ProductCostElement,
	|	RegisterData.PaymentType275FZ AS PaymentType275FZ,
	|	RegisterData.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	RegisterData.Partner AS Partner,
	|	RegisterData.Counterparty AS Counterparty,
	|	RegisterData.Contract AS Contract,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.ARAPDocument AS ARAPDocument,
	|	RegisterData.TargetFundItem AS TargetFundItem,
	|
	|	RegisterData.PayAmount AS PayAmount,
	|	RegisterData.PaymentAmountLocal AS PaymentAmountLocal,
	|	RegisterData.PaymentAmountPaymentCurrency AS PaymentAmountPaymentCurrency,
	|	
	|	RegisterData.PostpaymentAmount AS PostpaymentAmount,
	|	RegisterData.PostpaymentAmountLocal AS PostpaymentAmountLocal,
	|	RegisterData.PaymentAmountInPaymentCurrency AS PaymentAmountInPaymentCurrency,
	|
	|	RegisterData.PrepaymentAmountMan AS PrepaymentAmountMan,
	|	RegisterData.PrepaymentAmountLocal AS PrepaymentAmountLocal,
	|	RegisterData.PrepaymentAmount AS PrepaymentAmount,
	|
	|	RegisterData.AmountToBePaidWithinLimit AS AmountToBePaidWithinLimit,
	|	RegisterData.AmountToBePaidAboveLimit AS AmountToBePaidAboveLimit,
	|
	|	RegisterData.VATAmount AS VATAmount,
	|	RegisterData.VATAmountCompl AS VATAmountCompl,
	|	RegisterData.AmountVATCurrencyPayment AS AmountVATCurrencyPayment,
	|
	|	RegisterData.ARAPCurrency AS ARAPCurrency,
	|	RegisterData.PaymentAmountInTheSettlementCurrency AS PaymentAmountInTheSettlementCurrency,
	|	RegisterData.PostPaymentAmountInARAPCurrency AS PostPaymentAmountInARAPCurrency,
	|	RegisterData.PrepaymentAmountInARAPCurrency AS PrepaymentAmountInARAPCurrency,
	|
	|	RegisterData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	RegisterData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	RegisterData.VATRate AS VATRate,
	|	RegisterData.PaymentRequest AS PaymentRequest,
	|	RegisterData.DeferredPosting AS DeferredPosting,
	|	RegisterData.ReversingEntry
	|FROM
	|	TTNewRegisteredRecords AS RegisterData
	|	INNER JOIN TTModifiedDocuments AS ModifiedDocuments
	|	ON RegisterData.Recorder = ModifiedDocuments.Recorder
	|
	|TOTALS BY
	|	Recorder
	|";
	
	If ForDebugging <> Undefined Then
		ForDebugging.Insert("QueryTextRegisterRecords", Query.Text);
	EndIf;
	Return Query.Execute();
	
EndFunction

// Recording of Register records of "Cash Register Records - Counterparty"
// 
// Parameters:
//  SamplingRegisteredRecordedData - QueryResultSelection - Sampling By Registrars
//  ModifiedDocuments - ValueTable, Undefined - Modified documents
//  ForDebugging - Undefined, Structure - The structure in which information is returned for debugging
//
Procedure RecordCashFlowCounterparty(SamplingRegisteredRecordedData, ModifiedDocuments,
	ForDebugging = Undefined) Export

	RecordSet = AccumulationRegisters.RecordsCashCounterparty.CreateRecordSet();
	RecordSet.Filter.Recorder.Set(SamplingRegisteredRecordedData.Recorder);
	RecordSet.AdditionalProperties.Insert("DonTSavePending");
	RecordSet.AdditionalProperties.Insert("UpdatingOfRegisteredRecordedCashCounterparty");
	Selection = SamplingRegisteredRecordedData.Select();
	While Selection.Next() Do
		FillPropertyValues(RecordSet.Add(), Selection);
	EndDo;
	DistributePaymentAccordingToSettlementDocuments(RecordSet);
	If ForDebugging = Undefined Then
		RecordSet.Write();
	EndIf;
	If ModifiedDocuments <> Undefined Then
		NewRow = ModifiedDocuments.Add();
		NewRow.Ref = SamplingRegisteredRecordedData.Recorder;
	EndIf;
	
EndProcedure

// Write down the register records "Register Records Counterparty - Counterparty"
// 
// Parameters:
//  SelectionByDocuments - QueryResultSelection - Sampling By Registrars
//  ModifiedDocuments - ValueTable, Undefined - Modified documents
//
Procedure RecordCounterpartySRegisterRecordsCounterparty(SelectionByDocuments, ModifiedDocuments) Export

	RecordSet = AccumulationRegisters.RecordsCounterpartyCounterparty.CreateRecordSet();
	RecordSet.AdditionalProperties.Insert("DeferredPosting");
	RecordSet.AdditionalProperties.Insert("UpdatingOfRegisteredRecordsCounterpartyCounterparty");
	RecordSet.Filter.Recorder.Set(SelectionByDocuments.Recorder);
	Selection = SelectionByDocuments.Select();
	While Selection.Next() Do
		FillPropertyValues(RecordSet.Add(), Selection);
	EndDo;

	RecordSet.Write();
	If ModifiedDocuments <> Undefined Then
		NewRow = ModifiedDocuments.Add();
		NewRow.Ref = SelectionByDocuments.Recorder;
	EndIf;
	
EndProcedure

Procedure DistributePaymentAccordingToSettlementDocuments(RecordSet)
	
	RegisterData = RecordSet.Unload();
	Payments = RegisterData.Copy(New Structure("DeferredPosting", False));
	FilterFields = "Organization,VATRate,DeferredPosting,ReversingEntry,"
				+ "Cash,CashFlowItem,ProductCostElement,LineOfBusinessCash,"
				+ "Partner,Counterparty,Contract,ARAPObject,CounterpartyLineOfBusiness";
	Payments.GroupBy(FilterFields, "PaymentAmountPaymentCurrency");
	Filter = New Structure(FilterFields);
	For Each Payment In Payments Do
		If Payment.PaymentAmountPaymentCurrency = 0 Then
			Continue;
		EndIf;
		FillPropertyValues(Filter, Payment);
		Filter.DeferredPosting = True;
		SettlementDocuments_ = RegisterData.FindRows(Filter);
		Totals = RegisterData.Copy(Filter);
		TotalInLocalCurrency = Totals.Total("PostpaymentAmountLocal") + Totals.Total("PrepaymentAmountLocal");
		PaymentAmountPaymentCurrency = Payment.PaymentAmountPaymentCurrency;
		For Each Record In SettlementDocuments_ Do
			//write off the debt
			If Record.PostpaymentAmountLocal <> 0 Then
				AmountInPaymentCurrency = ARAPAccountingServer.WriteOffAmountProportionally(
					PaymentAmountPaymentCurrency,
					Record.PostpaymentAmountLocal,
					TotalInLocalCurrency);
				TotalInLocalCurrency = TotalInLocalCurrency - Record.PostpaymentAmountLocal;
				Record.PaymentAmountInPaymentCurrency = AmountInPaymentCurrency;
			EndIf;
			//we will write off the prepayment
			If Record.PrepaymentAmountLocal <> 0 Then
				AmountInPaymentCurrency = ARAPAccountingServer.WriteOffAmountProportionally(
					PaymentAmountPaymentCurrency,
					Record.PrepaymentAmountLocal,
					TotalInLocalCurrency);
				TotalInLocalCurrency = TotalInLocalCurrency - Record.PrepaymentAmountLocal;
				Record.PrepaymentAmount = AmountInPaymentCurrency;
			EndIf;
		EndDo;
	EndDo;
	RecordSet.Load(RegisterData);
	
EndProcedure

Function QueryTextPartnersARAPAccounting()
	
	TextOfRegistrarsRequest = 
	"SELECT DISTINCT
	|	RegisterRecords.Recorder AS Document
	|INTO TTRecorders_
	|FROM
	|	AccumulationRegister.RecordsCounterpartyCounterparty AS RegisterRecords
	|WHERE
	|	RegisterRecords.Recorder IN (&DocumentsArray)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RegisterRecords.Recorder AS Document
	|FROM
	|	AccumulationRegister.DiscountInterestExpense AS RegisterRecords
	|WHERE
	|	RegisterRecords.Recorder IN (&DocumentsArray)
	|
	|INDEX BY
	|	Document";
	
	TempTableName = "SettlementsWithMovementPartners";
	QueryTextRefundOfPayment = 
	"SELECT DISTINCT
	|	RegisterRecords.DocumentRecorder AS Ref,
	|	DimensionKeys.Organization AS Organization
	|INTO TTRefundPayment
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS RegisterRecords
	|	INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
	|		ON RegisterRecords.AccountingDimensionByPartners = DimensionKeys.DimensionKey
	|WHERE
	|	RegisterRecords.DocumentRecorder IN (&DocumentsArray)
	|	AND RegisterRecords.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|		VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RegisterRecords.DocumentRecorder AS Ref,
	|	DimensionKeys.Organization AS Organization
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS RegisterRecords
	|	INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
	|		ON RegisterRecords.AccountingDimensionByPartners = DimensionKeys.DimensionKey
	|WHERE
	|	RegisterRecords.DocumentRecorder IN (&DocumentsArray)
	|	AND RegisterRecords.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany))";

	MovementTexts = New Array;
	MovementTexts.Add(TrafficRequestTextByTimeFrame("VendorsARAPAccounting", TempTableName));
	MovementTexts.Add(TrafficRequestTextByTimeFrame("CustomersARAPAccounting"));
	MovementTexts.Add(TrafficRequestTextByTimeFrame("VendorsARAPAccounting",,True));
	MovementTexts.Add(TrafficRequestTextByTimeFrame("CustomersARAPAccounting",,True));
	QueryTextSettlementsWithMovementPartners = StrConcat(MovementTexts, TMCommonUse.QuerySeparatorInJoin());
	

#Region RequestTextForSettlementsWithPartners
	QueryTextPartnersARAPAccounting = 
	"SELECT
	|	PartnersARAPAccounting.Period AS Period,
	|	PartnersARAPAccounting.TypeOfRegisterMovement AS TypeOfRegisterMovement,
	|	PartnersARAPAccounting.RecordType AS RecordType,
	|	PartnersARAPAccounting.Recorder AS Recorder,
	|	PartnersARAPAccounting.Organization AS Organization,
	|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
	|	PartnersARAPAccounting.ARAPObject.Organization AS OrganizationOfSettlementObject,
	|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
	|	PartnersARAPAccounting.Partner AS Partner,
	|	PartnersARAPAccounting.Counterparty AS Counterparty,
	|	PartnersARAPAccounting.Contract AS Contract,
	|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
	|	PartnersARAPAccounting.Currency Currency,
	|	SUM(PartnersARAPAccounting.Sum) AS Sum,
	|	SUM(PartnersARAPAccounting.SumMan) AS SumMan,
	|	SUM(PartnersARAPAccounting.SumCompl) AS SumCompl,
	|
	|	PartnersARAPAccounting.AmountType AS AmountType,
	|
	|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
	|	PartnersARAPAccounting.OurEnterprise AS OurEnterprise,
	|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
	|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.Organization.ParentCompany AS ThisIsParentOrganization,
	|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
	|
	|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
	|	PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PartnersARAPAccounting.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	PartnersARAPAccounting.CorARAPObject AS CorARAPObject,
	|	ISNULL(PartnersARAPAccounting.CorPartnerAccountingDimension.Organization, UNDEFINED) AS CorCompany,
	|	ISNULL(PartnersARAPAccounting.CorPartnerAccountingDimension.Partner, UNDEFINED) AS CorPartner,
	|	ISNULL(PartnersARAPAccounting.CorPartnerAccountingDimension.Counterparty, UNDEFINED) AS CorCounterparty,
	|	ISNULL(PartnersARAPAccounting.CorPartnerAccountingDimension.Contract, UNDEFINED) AS CorContract
	|	
	|INTO PartnersARAPAccounting
	|FROM
	|	SettlementsWithMovementPartners AS PartnersARAPAccounting
	|
	|GROUP BY
	|	PartnersARAPAccounting.Period,
	|	PartnersARAPAccounting.TypeOfRegisterMovement,
	|	PartnersARAPAccounting.RecordType,
	|	PartnersARAPAccounting.Recorder,
	|	PartnersARAPAccounting.AccountingDimensionByPartners,
	|	PartnersARAPAccounting.Organization,
	|	PartnersARAPAccounting.LineOfBusiness,
	|	PartnersARAPAccounting.Partner,
	|	PartnersARAPAccounting.Counterparty,
	|	PartnersARAPAccounting.Contract,
	|	PartnersARAPAccounting.ARAPObject,
	|	PartnersARAPAccounting.Currency,
	|	PartnersARAPAccounting.AmountType,
	|	PartnersARAPAccounting.OurEnterprise,
	|	PartnersARAPAccounting.ReversingEntry,
	|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers,
	|	PartnersARAPAccounting.CounterpartyCompany,
	|	PartnersARAPAccounting.BusinessOperation,
	|	PartnersARAPAccounting.CorPartnerAccountingDimension,
	|	PartnersARAPAccounting.CorARAPObject
	|
	|INDEX BY
	|	Recorder,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Counterparty";
	#EndRegion
#Region QueryTextLossAllowance

	QueryTextLossAllowance = 
	"SELECT
	|	Reserves.Period,
	|	Reserves.RecordType AS RecordType,
	|	Reserves.Recorder AS Recorder,
	|	DimensionKeys.Organization AS Organization,
	|	DimensionKeys.LineOfBusiness AS LineOfBusiness,
	|	DimensionKeys.Partner,
	|	DimensionKeys.Counterparty AS Counterparty,
	|	DimensionKeys.Contract AS Contract,
	|	Reserves.ARAPObject AS ARAPObject,
	|	Reserves.Currency AS Currency,
	|	SUM(Reserves.Sum) AS Sum,
	|	SUM(Reserves.SumMan) AS SumMan,
	|	SUM(Reserves.SumCompl) AS SumCompl,
	|	VALUE(Enum.TypesOfDebtAmounts.DebtReserve) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance) AS BusinessOperation,
	|	Reserves.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Reserves.ReversingEntry AS ReversingEntry
	|INTO LossAllowance
	|FROM
	|	AccumulationRegister.LossAllowance AS Reserves
	|		INNER JOIN  TTRecorders_ AS T
	|			ON Reserves.Recorder = T.Document
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
	|			ON Reserves.AccountingDimensionByPartners = DimensionKeys.DimensionKey
	|WHERE
	|	VALUETYPE(Reserves.Recorder) = TYPE(Document.ARAPAdjustment)
	|
	|GROUP BY
	|	Reserves.Period,
	|	Reserves.RecordType,
	|	Reserves.Recorder,
	|	Reserves.AccountingDimensionByPartners,
	|	DimensionKeys.Organization,
	|	DimensionKeys.LineOfBusiness,
	|	DimensionKeys.Partner,
	|	DimensionKeys.Counterparty,
	|	DimensionKeys.Contract,
	|	Reserves.ARAPObject,
	|	Reserves.Currency,
	|	Reserves.ReversingEntry
	|
	|INDEX BY
	|	Recorder,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency";

#EndRegion
#Region QueryTextDiscountRates_

	QueryTextDiscountRates_ = 
	"SELECT
	|	Interests.Period,
	|	Interests.RecordType AS RecordType,
	|	Interests.Recorder AS Recorder,
	|	Interests.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Interests.ARAPObject.Organization AS Organization,
	|	Interests.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	Interests.ARAPObject.Partner AS Partner,
	|	Interests.ARAPObject.Counterparty AS Counterparty,
	|	Interests.ARAPObject.Contract AS Contract,
	|	Interests.ARAPObject AS ARAPObject,
	|	Interests.Currency AS Currency,
	|	SUM(CASE WHEN Interests.RecordType = VALUE(AccumulationRecordType.Expense) THEN -Interests.DiscountingAmount ELSE Interests.DiscountingAmount END) AS Sum,
	|	SUM(CASE WHEN Interests.RecordType = VALUE(AccumulationRecordType.Expense) THEN -Interests.DiscountingAmountMan ELSE Interests.DiscountingAmountMan END) AS SumMan,
	|	SUM(CASE WHEN Interests.RecordType = VALUE(AccumulationRecordType.Expense) THEN -Interests.DiscountingAmountCompl ELSE Interests.DiscountingAmountCompl END) AS SumCompl,
	|	VALUE(Enum.TypesOfDebtAmounts.DebtDiscount) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting) AS BusinessOperation
	|INTO DiscountRates_
	|FROM
	|	AccumulationRegister.DiscountInterestExpense AS Interests
	|		INNER JOIN  TTRecorders_ AS T
	|			ON Interests.Recorder = T.Document
	|
	|GROUP BY
	|	Interests.Period,
	|	Interests.RecordType,
	|	Interests.Recorder,
	|	Interests.AccountingDimensionByPartners,
	|	Interests.ARAPObject,
	|	Interests.Currency
	|
	|INDEX BY
	|	Recorder,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency";

#EndRegion




#Region QueryTextParentCompany

	QueryTextParentCompany = 
	"SELECT DISTINCT
	|	PartnersARAPAccounting.Organization AS Organization,
	|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany
	|FROM
	|	SettlementsWithMovementPartners AS PartnersARAPAccounting";

#EndRegion


// It is written in the usual fields
#Region DebtExpense
//Debt Offset document
		#Region DebtExpenseOnNetting
		//Debt Expense table (write off all accounts receivable)
		DebtExpenseOnNetting = 
		"//Debt Expense table (write off all accounts receivable)
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""DebtExpenseOnNetting"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	10 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) = TYPE(Document.ARAPSettlement)";
		#EndRegion

//Payment documents: Receipt of BDS, PKO
		#Region DebtExpenseForSomeoneElseSSettlementObject
		// The receipt of money to the parent organization (filial) closes the debt in the branch (parent organization)
		DebtExpenseForSomeoneElseSSettlementObject =  
		"//Upon receipt of money for the branch, we will close the debt of the branch
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS Organization,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS CorPartner,
		|	PartnersARAPAccounting.Counterparty AS CorCounterparty,
		|	PartnersARAPAccounting.Contract AS CorContract,
		|	PartnersARAPAccounting.ARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS CorCurrencyOfARAPAccounting,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AdjAmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
		|	""DebtExpenseForSomeoneElseSSettlementObject"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	20 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.CashAccountReceiptNote),
		|		TYPE(Document.BankAccountReceiptNote))
		|	AND PartnersARAPAccounting.Organization <> PartnersARAPAccounting.OrganizationOfSettlementObject";
		#EndRegion

//Payment documents: JSC, Write-offs, ACW
		#Region ExpenseInOrganizationForSomeoneElseSPaymentObject
		// We pay in the parent organization (branch) for the object of calculation of the branch (parent organization)
		ExpenseInOrganizationForSomeoneElseSPaymentObject = 
		"//When paying for the branch office for Receipt in the documents of the advance report, write-off of the BDS and ACW, we will substitute the Expense in the parent organization
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS CorLineOfBusiness,
		|	PartnersARAPAccounting.Partner AS CorPartner,
		|	PartnersARAPAccounting.Counterparty AS CorCounterparty,
		|	PartnersARAPAccounting.Contract AS CorContract,
		|	PartnersARAPAccounting.ARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS CorCurrencyOfARAPAccounting,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AdjAmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
		|	""ExpenseInOrganizationForSomeoneElseSPaymentObject"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	30 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.ExpenseReport),
		|		TYPE(Document.CashVoucher),
		|		TYPE(Document.BankAccountIssue))
		|	AND PartnersARAPAccounting.Organization <> PartnersARAPAccounting.OrganizationOfSettlementObject";
		#EndRegion

//Refund of payment reclassification of advance payment (Dr <60.01> :: Cr <60.02>)
		#Region ExpenseReclassificationOfAdvance
		ExpenseReclassificationOfAdvance = 
		"//Refund at the advance rate: Repayment of debt after the transfer of the advance
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	RefundOfPayment.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS CorLineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ExpenseReclassificationOfAdvance"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	RefundOfPayment.Organization = RefundOfPayment.Organization.ParentCompany AS ThisIsParentOrganization,
		|	TRUE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	40 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN TTRefundPayment AS RefundOfPayment
		|		ON PartnersARAPAccounting.Recorder = RefundOfPayment.Ref
		|WHERE
		|	PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
		|	AND PartnersARAPAccounting.CorARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
		|";
		#EndRegion

//Refund of payment transfer to the branch (Dr <62.02, 79.02> :: Cr <79.02, 60.02>)
		#Region ExpenseRefundOfPaymentTransferToBranch
		ExpenseRefundOfPaymentTransferToBranch = 
		"//Refund at the advance rate: We write off the advance in the parent organization when returning in the branch
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS CorLineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ExpenseRefundOfPaymentTransferToBranch"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	TRUE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	50 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN TTRefundPayment AS RefundOfPayment
		|		ON PartnersARAPAccounting.Recorder = RefundOfPayment.Ref
		|WHERE
		|	PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
		|	AND PartnersARAPAccounting.CorARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND PartnersARAPAccounting.Organization <> RefundOfPayment.Organization
		|";
		#EndRegion
//Debt write-off document
		#Region DebtExpenseOnWriteOff
		DebtExpenseOnWriteOff = 
		"//When writing off debt 
		|SELECT
		|	PartnersARAPAccounting.Period AS Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	Reserves.Sum AS AmountInCurrency,
		|	Reserves.SumMan AS Sum,
		|	Reserves.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	Reserves.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	Reserves.SumCompl / 
		|		CASE WHEN Reserves.Sum = 0 
		|			THEN CASE WHEN Reserves.SumCompl = 0 
		|							THEN 1 
		|							ELSE Reserves.SumCompl
		|					END
		|			ELSE Reserves.Sum
		|		END AS MutualSettlementsExchangeRate,
		|	Reserves.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""DebtExpenseOnWriteOff"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	60 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN LossAllowance AS Reserves
		|	ON PartnersARAPAccounting.Recorder = Reserves.Recorder
		|		AND PartnersARAPAccounting.AccountingDimensionByPartners = Reserves.AccountingDimensionByPartners
		|		AND PartnersARAPAccounting.ARAPObject = Reserves.ARAPObject
		|		AND PartnersARAPAccounting.Currency = Reserves.Currency
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) = TYPE(Document.ARAPAdjustment)";
		#EndRegion
//Discounting
		#Region DebtConsumptionAtDiscounting
		DebtConsumptionAtDiscounting = 
		"//When discounting debt 
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	Interests.Sum AS AmountInCurrency,
		|	Interests.SumMan AS Sum,
		|	Interests.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	Interests.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	Interests.SumCompl / 
		|		CASE WHEN Interests.Sum = 0 
		|			THEN CASE WHEN Interests.SumCompl = 0 
		|							THEN 1 
		|							ELSE Interests.SumCompl
		|					END
		|			ELSE Interests.Sum
		|		END AS MutualSettlementsExchangeRate,
		|	Interests.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""DebtConsumptionAtDiscounting"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	70 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN DiscountRates_ AS Interests
		|	ON PartnersARAPAccounting.Recorder = Interests.Recorder
		|		AND PartnersARAPAccounting.AccountingDimensionByPartners = Interests.AccountingDimensionByPartners
		|		AND PartnersARAPAccounting.ARAPObject = Interests.ARAPObject
		|		AND PartnersARAPAccounting.Currency = Interests.Currency
		|
		|ORDER BY
		|	Order,
		|	PartnersARAPAccounting.Recorder,
		|	PartnersARAPAccounting.Organization,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum DESC
		|TOTALS
		|	MAX(CounterpartyCompany),
		|	MAX(ThisIsRefundOfAdvance)
		|BY
		|	PartnersARAPAccounting.Recorder,
		|	PartnersARAPAccounting.Organization";
		#EndRegion

		DebtExpense = New Array;
		DebtExpense.Add(DebtExpenseOnNetting);
		DebtExpense.Add(DebtExpenseForSomeoneElseSSettlementObject);
		DebtExpense.Add(ExpenseInOrganizationForSomeoneElseSPaymentObject);
		DebtExpense.Add(ExpenseReclassificationOfAdvance);
		DebtExpense.Add(ExpenseRefundOfPaymentTransferToBranch);
		DebtExpense.Add(DebtExpenseOnWriteOff);
		DebtExpense.Add(DebtConsumptionAtDiscounting);
		
		//Debited debt for repayment
		QueryTextAccountsReceivable = StrConcat(DebtExpense, TMCommonUse.QuerySeparatorInJoin());
#EndRegion


// It is written in fields with the prefix Cor
#Region ArrivalOfDebt
//Debt Offset document
		#Region ArrivalOfDebtOnNetting
		ArrivalOfDebtOnNetting = 
		"//The table of Arrival of debt (we receive all accounts payable)
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS CorLineOfBusiness,
		|	PartnersARAPAccounting.Partner AS CorPartner,
		|	PartnersARAPAccounting.Counterparty AS CorCounterparty,
		|	PartnersARAPAccounting.Contract AS CorContract,
		|	PartnersARAPAccounting.ARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.Currency AS Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS CorCurrencyOfARAPAccounting,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AdjAmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
		|	""ArrivalOfDebtOnNetting"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	10 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) = TYPE(Document.ARAPSettlement)";
		#EndRegion

//Payment documents: Receipt of BDS, PKO
		#Region JoiningOrganizationForSomeoneElseSPaymentObject
		JoiningOrganizationForSomeoneElseSPaymentObject = //in a branch office, this is an expense to the parent organization
		"//When receiving money for a branch, we will substitute the Arrival to the parent organization for the expense in the receipt documents of the BDS and ICO
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Receipt),
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""JoiningOrganizationForSomeoneElseSPaymentObject"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	20 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.CashAccountReceiptNote),
		|		TYPE(Document.BankAccountReceiptNote))
		|	AND PartnersARAPAccounting.Organization <> PartnersARAPAccounting.OrganizationOfSettlementObject";
		#EndRegion
		
//Payment documents: JSC, Write-offs, ACW
		#Region ArrivalOfDebtForSomeoneElseSObjectOfCalculations
		// When paying for someone else's calculation object, the supplier's debt for this calculation object is formed
		ArrivalOfDebtForSomeoneElseSObjectOfCalculations = 
		"//When paying for a branch, we will close the branch's debt
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Receipt),
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ArrivalOfDebtForSomeoneElseSObjectOfCalculations"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	30 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.ExpenseReport),
		|		TYPE(Document.CashVoucher),
		|		TYPE(Document.BankAccountIssue))
		|	AND PartnersARAPAccounting.Organization <> PartnersARAPAccounting.OrganizationOfSettlementObject
		|";
		#EndRegion

//Refund of payment reclassification of advance payment (Dr <60.01> :: Cr <60.02>)
		#Region ArrivalReclassificationOfAdvance
		ArrivalReclassificationOfAdvance = 
		"// Refund at the advance rate - Transfer of the advance
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Receipt),
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS CorLineOfBusiness,
		|	PartnersARAPAccounting.Partner AS CorPartner,
		|	PartnersARAPAccounting.Counterparty AS CorCounterparty,
		|	PartnersARAPAccounting.Contract AS CorContract,
		|	PartnersARAPAccounting.ARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS CorCurrencyOfARAPAccounting,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AdjAmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
		|	""ArrivalReclassificationOfAdvance"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	TRUE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	40 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN TTRefundPayment AS RefundOfPayment
		|		ON PartnersARAPAccounting.Recorder = RefundOfPayment.Ref
		|		AND PartnersARAPAccounting.Organization = RefundOfPayment.Organization
		|WHERE
		|	PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
		|	AND PartnersARAPAccounting.CorARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|";
		#EndRegion

//Refund of payment transfer to the branch (Dr <62.02, 79.02> :: Cr <79.02, 60.02>)
		#Region ArrivalRefundOfPaymentTransferToBranch
		ArrivalRefundOfPaymentTransferToBranch = 
		"// Refund at the advance rate - Transfer of the advance
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Receipt),
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	RefundOfPayment.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ArrivalRefundOfPaymentTransferToBranch"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	TRUE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	50 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN TTRefundPayment AS RefundOfPayment
		|		ON PartnersARAPAccounting.Recorder = RefundOfPayment.Ref
		|WHERE
		|	PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
		|	AND PartnersARAPAccounting.CorARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND PartnersARAPAccounting.Organization <> PartnersARAPAccounting.CorCompany
		|";
		#EndRegion
//Debt write-off document
		#Region ArrivalOfDebtWhenWritingOff
		ArrivalOfDebtWhenWritingOff = 
		"//When writing off debt (the arrival table is exactly the same as the expense table) 
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	Reserves.Sum AS AmountInCurrency,
		|	Reserves.SumMan AS Sum,
		|	Reserves.SumCompl AS SumCompl,
		|	Reserves.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	Reserves.SumCompl / 
		|		CASE WHEN Reserves.Sum = 0 
		|			THEN CASE WHEN Reserves.SumCompl = 0 
		|							THEN 1 
		|							ELSE Reserves.SumCompl
		|					END
		|			ELSE Reserves.Sum
		|		END AS MutualSettlementsExchangeRate,
		|	Reserves.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ArrivalOfDebtWhenWritingOff"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	60 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN LossAllowance AS Reserves
		|	ON PartnersARAPAccounting.Recorder = Reserves.Recorder
		|		AND PartnersARAPAccounting.AccountingDimensionByPartners = Reserves.AccountingDimensionByPartners
		|		AND PartnersARAPAccounting.ARAPObject = Reserves.ARAPObject
		|		AND PartnersARAPAccounting.Currency = Reserves.Currency
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) = TYPE(Document.ARAPAdjustment)";
		#EndRegion
//Discounting
		#Region ArrivalOfDebtAtDiscounting
		ArrivalOfDebtAtDiscounting = 
		"//When discounting debt (the arrival table is exactly the same as the expense table) 
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	Interests.Sum AS AmountInCurrency,
		|	Interests.SumMan AS Sum,
		|	Interests.SumCompl AS SumCompl,
		|	Interests.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	Interests.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	Interests.SumCompl / 
		|		CASE WHEN Interests.Sum = 0 
		|			THEN CASE WHEN Interests.SumCompl = 0 
		|							THEN 1 
		|							ELSE Interests.SumCompl
		|					END
		|			ELSE Interests.Sum
		|		END AS MutualSettlementsExchangeRate,
		|	Interests.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ArrivalOfDebtAtDiscounting"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.ThisIsParentOrganization AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
		|	70 AS Order
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN DiscountRates_ AS Interests
		|	ON PartnersARAPAccounting.Recorder = Interests.Recorder
		|		AND PartnersARAPAccounting.AccountingDimensionByPartners = Interests.AccountingDimensionByPartners
		|		AND PartnersARAPAccounting.ARAPObject = Interests.ARAPObject
		|		AND PartnersARAPAccounting.Currency = Interests.Currency
		|
		|ORDER BY
		|	Order,
		|	PartnersARAPAccounting.Recorder,
		|	PartnersARAPAccounting.Organization,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum DESC
		|;";
		#EndRegion
		ArrivalOfDebt = New Array;
		ArrivalOfDebt.Add(ArrivalOfDebtOnNetting);
		ArrivalOfDebt.Add(JoiningOrganizationForSomeoneElseSPaymentObject);
		ArrivalOfDebt.Add(ArrivalOfDebtForSomeoneElseSObjectOfCalculations);
		ArrivalOfDebt.Add(ArrivalReclassificationOfAdvance);
		ArrivalOfDebt.Add(ArrivalRefundOfPaymentTransferToBranch);
		ArrivalOfDebt.Add(ArrivalOfDebtWhenWritingOff);
		ArrivalOfDebt.Add(ArrivalOfDebtAtDiscounting);
		
		//Repayable debt
		QueryTextAccountsPayable = StrConcat(ArrivalOfDebt, TMCommonUse.QuerySeparatorInJoin());

#EndRegion

	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfRegistrarsRequest);
	QueriesTexts.Add(QueryTextRefundOfPayment);
	QueriesTexts.Add(QueryTextSettlementsWithMovementPartners);
	QueriesTexts.Add(QueryTextPartnersARAPAccounting);
	QueriesTexts.Add(QueryTextLossAllowance);
	QueriesTexts.Add(QueryTextDiscountRates_);
	QueriesTexts.Add(QueryTextParentCompany);
	QueriesTexts.Add(QueryTextAccountsReceivable);
	QueriesTexts.Add(QueryTextAccountsPayable);
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Return QueryText;
	
EndFunction

Function TrafficRequestTextByTimeFrame(TableName, TempTableName = "", ReversingEntry = False)
	
	QueryText = 
	"SELECT
	|	VendorsARAPAccounting.Period AS Period,
	|	VendorsARAPAccounting.RecordType AS TypeOfRegisterMovement,
	|	CASE
	|		WHEN &NotRefundOfPayment AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt) AND &Resource <> 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		WHEN &NotRefundOfPayment AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense) AND &Resource <> 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VendorsARAPAccounting.RecordType
	|	END AS RecordType,
	|	&Recorder AS Recorder,
	|	DimensionKeys.Organization,
	|	DimensionKeys.LineOfBusiness AS LineOfBusiness,
	|	DimensionKeys.Partner,
	|	DimensionKeys.Counterparty AS Counterparty,
	|	DimensionKeys.Contract AS Contract,
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	VendorsARAPAccounting.Currency,
	|	1*CASE WHEN VendorsARAPAccounting.Debt <> 0
	|		THEN VendorsARAPAccounting.Debt
	|		ELSE VendorsARAPAccounting.Prepayment
	|	END AS Sum,
	|	1*CASE WHEN VendorsARAPAccounting.ARAPMan <> 0
	|		THEN VendorsARAPAccounting.ARAPMan
	|		ELSE VendorsARAPAccounting.PrepaymentMan
	|	END AS SumMan,
	|	1*CASE WHEN VendorsARAPAccounting.DebtLocal <> 0
	|		THEN VendorsARAPAccounting.DebtLocal
	|		ELSE VendorsARAPAccounting.PrepaymentLocal
	|	END AS SumCompl,
	|
	|	CASE WHEN VendorsARAPAccounting.DebtLocal <> 0
	|		THEN VALUE(Enum.TypesOfDebtAmounts.VendorAccountsPayable)
	|		ELSE VALUE(Enum.TypesOfDebtAmounts.PrepaymentToVendor)
	|	END AS AmountType,
	|
	|	&TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
	|	DimensionKeys.Partner = VALUE(Catalog.Partners.OurEnterprise) AS OurEnterprise,
	|	VALUETYPE(DimensionKeys.Counterparty) = TYPE(Catalog.Companies) AS CounterpartyCompany,
	|
	|	VendorsARAPAccounting.BusinessOperation AS BusinessOperation,
	|	&ReversingEntry AS ReversingEntry,
	|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccounting.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	VendorsARAPAccounting.CorARAPObject AS CorARAPObject
	|	
	|,&TableName
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccounting
	|		INNER JOIN TTRecorders_ AS T
	|			ON VendorsARAPAccounting.DocumentRecorder = T.Document
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
	|			ON VendorsARAPAccounting.AccountingDimensionByPartners = DimensionKeys.DimensionKey
	|		LEFT JOIN TTRefundPayment AS Return
	|			ON VendorsARAPAccounting.DocumentRecorder = Return.Ref
	|WHERE
	|	NOT VendorsARAPAccounting.BusinessOperation IN 
	|		(VALUE(Enum.BusinessTransactions.RecordShortagesAtVendorSExpenseOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.RecordShortagesAtThirdPartyExpenseOnGoodsReceipt))";
	
	Return PerformSubstitutions(QueryText, TableName, TempTableName, ReversingEntry);
	
EndFunction

#Region DistributionOfRegisteredRecordsCounterpartyCounterparty

Procedure CarryOutNetting(AccountsReceivable, AccountsPayable, RegisterRecordTable) Export
	
	CommonFields   = "Period,BusinessOperation,Organization,Department,Currency,ReversingEntry";
	DebitFields  = "Partner,Counterparty,Contract,LineOfBusiness,ARAPObject,AmountType,ARAPCurrency,SourceOfARAPFinancialAccountingGroup";
	CreditFields = "CorPartner,CorCounterparty,CorContract,CorLineOfBusiness,CorARAPObject,CorAmountType,CorCurrencyOfARAPAccounting,CorSourceOfARAPFinancialAccountingGroup";
	SumFields    = "Sum,SumCompl,AmountInCurrency,AmountInARAPCurrency,AdjAmountInARAPCurrency";
	
	If RegisterRecordTable = Undefined Then
		RegisterRecordTable = AccumulationRegisters.RecordsCounterpartyCounterparty.CreateRecordSet().UnloadColumns();
	Else
		CommonFields = "Recorder," + CommonFields;
	EndIf;
	
	LastIndex = AccountsPayable.Count()-1;
	OurEnterprise = Catalogs.Partners.OurEnterprise;
	ARAPSettlement = Enums.BusinessTransactions.ARAPSettlement;
	For Each Debit In AccountsReceivable Do
		IndexOf = -1;
		For Each Credit In AccountsPayable Do
			
			IndexOf = IndexOf + 1;
			If Credit.SumCompl = 0 Then
				Continue;
			EndIf;
			LastPayment = IndexOf = LastIndex;
			
			If Debit.ReversingEntry And Debit.SumCompl < 0 And Credit.SumCompl < 0 Then
				Sum            = -ARAPAccountingServer.DeductAmount(-Debit.Sum, -Credit.Sum, LastPayment);
				SumCompl        = -ARAPAccountingServer.DeductAmount(-Debit.SumCompl, -Credit.SumCompl, LastPayment);
				AmountInCurrency     = -ARAPAccountingServer.DeductAmount(-Debit.AmountInCurrency, -Credit.AmountInCurrency, LastPayment);
			Else
				Sum            = ARAPAccountingServer.DeductAmount(Debit.Sum, Credit.Sum, LastPayment);
				SumCompl        = ARAPAccountingServer.DeductAmount(Debit.SumCompl, Credit.SumCompl, LastPayment);
				AmountInCurrency     = ARAPAccountingServer.DeductAmount(Debit.AmountInCurrency, Credit.AmountInCurrency, LastPayment);
			EndIf;
			
			If Debit.ARAPCurrency <> Credit.CorCurrencyOfARAPAccounting
				Or (Debit.AmountInARAPCurrency <> Credit.AdjAmountInARAPCurrency
					And Debit.BusinessOperation = ARAPSettlement) Then
				AmountInARAPCurrency = DebitingAmountAtExchangeRate(SumCompl, Debit, LastPayment);
				AdjAmountInARAPCurrency = DebitingAmountAtExchangeRate(SumCompl, Credit, LastPayment, "Balanced");
			Else
				AmountInARAPCurrency = DebitingAmountAtExchangeRate(SumCompl, Debit, LastPayment);
				AdjAmountInARAPCurrency = AmountInARAPCurrency;
			EndIf;
			
			If SumCompl <> 0 Then
				NewMovement = RegisterRecordTable.Add();
				FillPropertyValues(NewMovement, Debit, CommonFields+","+DebitFields, SumFields);
				FillPropertyValues(NewMovement, Credit, CreditFields, SumFields);
				
				NewMovement.Sum           = Sum;
				NewMovement.SumCompl       = SumCompl;
				NewMovement.AmountInCurrency = AmountInCurrency;
				NewMovement.AmountInARAPCurrency    = AmountInARAPCurrency;
				NewMovement.AdjAmountInARAPCurrency = AdjAmountInARAPCurrency;
				
				If Debit.Organization <> Credit.Organization Then
					
					If Debit.ThisIsRefundOfAdvance Then
						ExpenseInParentOrganization = Debit.RecordType = AccumulationRecordType.Expense
							And (Debit.ThisIsParentOrganization Or Not Debit.ThisIsParentOrganization And Not Credit.ThisIsParentOrganization)
							And Not Debit.TheseAreSettlementsWithCustomers;
						ExpensesInBranch = Debit.RecordType = AccumulationRecordType.Expense
							And Not Debit.ThisIsParentOrganization And Credit.ThisIsParentOrganization
							And Not Debit.TheseAreSettlementsWithCustomers;
						
					Else
						ExpenseInParentOrganization = Debit.RecordType = AccumulationRecordType.Expense
							And (Debit.ThisIsParentOrganization Or Not Debit.ThisIsParentOrganization And Not Credit.ThisIsParentOrganization);
						ExpensesInBranch = Debit.RecordType = AccumulationRecordType.Expense
							And Not Debit.ThisIsParentOrganization And Credit.ThisIsParentOrganization;
						
					EndIf;
					
					If ExpenseInParentOrganization Or ExpensesInBranch Then
						NewMovement.CorPartner = OurEnterprise;
						NewMovement.CorCounterparty = Credit.Organization;
						If TypeOf(Debit.Recorder) <> Type("DocumentRef.ARAPSettlement") Then
							ChangeCorContract(NewMovement, OurEnterprise);
						EndIf;
					Else
						NewMovement.Partner = OurEnterprise;
						NewMovement.Counterparty = Credit.Organization;
						If TypeOf(Debit.Recorder) <> Type("DocumentRef.ARAPSettlement") Then
							ChangeContract(NewMovement, OurEnterprise);
						EndIf;
					EndIf;
					
					NewMovementBalanced = RegisterRecordTable.Add();
					FillPropertyValues(NewMovementBalanced, Debit, DebitFields, SumFields);
					FillPropertyValues(NewMovementBalanced, Credit, CommonFields+","+CreditFields, SumFields);
					FillPropertyValues(NewMovementBalanced, NewMovement, SumFields);
					
					If ExpenseInParentOrganization Or ExpensesInBranch Then
						NewMovementBalanced.Partner = OurEnterprise;
						NewMovementBalanced.Counterparty = Debit.Organization;
						If TypeOf(Debit.Recorder) <> Type("DocumentRef.ARAPSettlement") Then
							ChangeContract(NewMovementBalanced, OurEnterprise);
						EndIf;
					Else
						NewMovementBalanced.CorPartner = OurEnterprise;
						NewMovementBalanced.CorCounterparty = Debit.Organization;
						If TypeOf(Debit.Recorder) <> Type("DocumentRef.ARAPSettlement") Then
							ChangeCorContract(NewMovementBalanced, OurEnterprise);
						EndIf;
					EndIf;
					
					If TypeOf(Debit.Recorder) <> Type("DocumentRef.ARAPSettlement") Then
						If Debit.TheseAreSettlementsWithCustomers Then
							NewMovement.ARAPObject = Credit.CorARAPObject;
							NewMovement.CorARAPObject = Debit.ARAPObject;
							
							NewMovement.SourceOfARAPFinancialAccountingGroup = Credit.CorARAPObject;
							NewMovement.CorSourceOfARAPFinancialAccountingGroup = Debit.ARAPObject;
							
							NewMovement.AmountType = Credit.CorAmountType;
							NewMovement.CorAmountType = Debit.AmountType;
							
						Else
							NewMovementBalanced.ARAPObject = Credit.CorARAPObject;
							NewMovementBalanced.CorARAPObject = Debit.ARAPObject;
							
							NewMovementBalanced.SourceOfARAPFinancialAccountingGroup = Credit.CorARAPObject;
							NewMovementBalanced.CorSourceOfARAPFinancialAccountingGroup = Debit.ARAPObject;
							
							NewMovementBalanced.AmountType = Credit.CorAmountType;
							NewMovementBalanced.CorAmountType = Debit.AmountType;
						EndIf;
					EndIf;
					
				ElsIf Debit.ThisIsRefundOfAdvance And Debit.TheseAreSettlementsWithCustomers Then
						
					NewMovement.Contract = Credit.CorContract;
					NewMovement.CorContract = Debit.Contract;
					
					NewMovement.ARAPObject = Credit.CorARAPObject;
					NewMovement.CorARAPObject = Debit.ARAPObject;
					
					NewMovement.SourceOfARAPFinancialAccountingGroup = Credit.CorARAPObject;
					NewMovement.CorSourceOfARAPFinancialAccountingGroup = Debit.ARAPObject;
					
					NewMovement.AmountType = Credit.CorAmountType;
					NewMovement.CorAmountType = Debit.AmountType;
						
				EndIf;
			EndIf;
			If Debit.SumCompl <= 0 Then
				Break;
			EndIf;
		EndDo;// on accounts payable
	EndDo;// on accounts receivable
	
EndProcedure

Procedure ChangeContract(Movement, OurEnterprise)
	
	If Movement.Partner = OurEnterprise And ValueIsFilled(Movement.Contract) Then
		Contract = Movement.Contract;
		Movement.Contract = Movement.CorContract;
		Movement.CorContract = Contract;
	EndIf;
	
EndProcedure

Procedure ChangeCorContract(Movement, OurEnterprise)
	
	If Movement.CorPartner = OurEnterprise And ValueIsFilled(Movement.CorContract) Then
		CorContract = Movement.CorContract;
		Movement.CorContract = Movement.Contract;
		Movement.Contract = CorContract;
	EndIf;
	
EndProcedure

Function DebitingAmountAtExchangeRate(SumCompl, Data, LastPayment, Balanced = "")
	
	NameOfAmountFieldInSettlementCurrency = ?(IsBlankString(Balanced), "AmountInARAPCurrency", "AdjAmountInARAPCurrency");
	AmountARAP = Round(SumCompl/?(Data.MutualSettlementsExchangeRate=0, 1, Data.MutualSettlementsExchangeRate), 2);
	AmountInARAPCurrency = ARAPAccountingServer.DeductAmount(Data[NameOfAmountFieldInSettlementCurrency], AmountARAP, 
												LastPayment And Data[NameOfAmountFieldInSettlementCurrency] <= AmountARAP);
	If Data.SumCompl <= 0 And Data[NameOfAmountFieldInSettlementCurrency] <> 0 Then
		AmountInARAPCurrency = AmountInARAPCurrency + Data[NameOfAmountFieldInSettlementCurrency];
	EndIf;
	
	Return AmountInARAPCurrency;
	
EndFunction

#EndRegion

#Region OldCalculationArchitecture
Function RequestTextSettlementsWithPartnersOldArchitecture()
	
	TextOfRegistrarsRequest = 
	"SELECT DISTINCT
	|	RegisterRecords.Recorder AS Document
	|INTO TTRecorders_
	|FROM
	|	AccumulationRegister.RecordsCounterpartyCounterparty AS RegisterRecords
	|WHERE
	|	RegisterRecords.Recorder IN (&DocumentsArray)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RegisterRecords.Recorder AS Document
	|FROM
	|	AccumulationRegister.DiscountInterestExpense AS RegisterRecords
	|WHERE
	|	RegisterRecords.Recorder IN (&DocumentsArray)
	|
	|INDEX BY
	|	Document";
	
	TempTableName = "SettlementsWithMovementPartners";
	QueryTextRefundOfPayment = 
	"SELECT
	|	UNDEFINED AS Ref,
	|	UNDEFINED AS Organization
	|INTO TTRefundPayment
	|WHERE
	|	FALSE";
	
	MovementTexts = New Array;
	MovementTexts.Add(TrafficRequestTextForDocuments("VendorsARAPAccounting", TempTableName));
	MovementTexts.Add(TrafficRequestTextForDocuments("CustomersARAPAccounting"));
	QueryTextSettlementsWithMovementPartners = StrConcat(MovementTexts, TMCommonUse.QuerySeparatorInJoin());
	

#Region RequestTextForSettlementsWithPartners
	QueryTextPartnersARAPAccounting = 
	"SELECT
	|	PartnersARAPAccounting.Period AS Period,
	|	PartnersARAPAccounting.TypeOfRegisterMovement AS TypeOfRegisterMovement,
	|	PartnersARAPAccounting.RecordType AS RecordType,
	|	PartnersARAPAccounting.Recorder AS Recorder,
	|	PartnersARAPAccounting.Organization AS Organization,
	|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
	|	PartnersARAPAccounting.ARAPObject.Organization AS OrganizationOfSettlementObject,
	|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
	|	PartnersARAPAccounting.Partner AS Partner,
	|	PartnersARAPAccounting.Counterparty AS Counterparty,
	|	PartnersARAPAccounting.Contract AS Contract,
	|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
	|	PartnersARAPAccounting.Currency Currency,
	|	SUM(PartnersARAPAccounting.Sum) AS Sum,
	|	SUM(PartnersARAPAccounting.SumMan) AS SumMan,
	|	SUM(PartnersARAPAccounting.SumCompl) AS SumCompl,
	|
	|	PartnersARAPAccounting.AmountType AS AmountType,
	|
	|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
	|	PartnersARAPAccounting.OurEnterprise AS OurEnterprise,
	|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
	|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.Organization.ParentCompany AS ThisIsParentOrganization,
	|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry,
	|
	|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
	|	PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|	
	|INTO PartnersARAPAccounting
	|FROM
	|	SettlementsWithMovementPartners AS PartnersARAPAccounting
	|
	|GROUP BY
	|	PartnersARAPAccounting.Period,
	|	PartnersARAPAccounting.TypeOfRegisterMovement,
	|	PartnersARAPAccounting.RecordType,
	|	PartnersARAPAccounting.Recorder,
	|	PartnersARAPAccounting.AccountingDimensionByPartners,
	|	PartnersARAPAccounting.Organization,
	|	PartnersARAPAccounting.LineOfBusiness,
	|	PartnersARAPAccounting.Partner,
	|	PartnersARAPAccounting.Counterparty,
	|	PartnersARAPAccounting.Contract,
	|	PartnersARAPAccounting.ARAPObject,
	|	PartnersARAPAccounting.Currency,
	|	PartnersARAPAccounting.AmountType,
	|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers,
	|	PartnersARAPAccounting.OurEnterprise,
	|	PartnersARAPAccounting.ReversingEntry,
	|	PartnersARAPAccounting.CounterpartyCompany,
	|	PartnersARAPAccounting.BusinessOperation
	|
	|INDEX BY
	|	Recorder,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Counterparty";
	#EndRegion
#Region QueryTextLossAllowance

	QueryTextLossAllowance = 
	"SELECT
	|	Reserves.Period,
	|	Reserves.RecordType AS RecordType,
	|	Reserves.Recorder AS Recorder,
	|	DimensionKeys.Organization AS Organization,
	|	DimensionKeys.LineOfBusiness AS LineOfBusiness,
	|	DimensionKeys.Partner,
	|	DimensionKeys.Counterparty AS Counterparty,
	|	DimensionKeys.Contract AS Contract,
	|	Reserves.ARAPObject AS ARAPObject,
	|	Reserves.Currency AS Currency,
	|	SUM(Reserves.Sum) AS Sum,
	|	SUM(Reserves.SumMan) AS SumMan,
	|	SUM(Reserves.SumCompl) AS SumCompl,
	|	VALUE(Enum.TypesOfDebtAmounts.DebtReserve) AS AmountType,
	|	VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance) AS BusinessOperation,
	|	Reserves.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Reserves.ReversingEntry AS ReversingEntry
	|INTO LossAllowance
	|FROM
	|	AccumulationRegister.LossAllowance AS Reserves
	|		INNER JOIN  TTRecorders_ AS T
	|			ON Reserves.Recorder = T.Document
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
	|			ON Reserves.AccountingDimensionByPartners = DimensionKeys.DimensionKey
	|WHERE
	|	VALUETYPE(Reserves.Recorder) = TYPE(Document.ARAPAdjustment)
	|
	|GROUP BY
	|	Reserves.Period,
	|	Reserves.RecordType,
	|	Reserves.Recorder,
	|	Reserves.AccountingDimensionByPartners,
	|	DimensionKeys.Organization,
	|	DimensionKeys.LineOfBusiness,
	|	DimensionKeys.Partner,
	|	DimensionKeys.Counterparty,
	|	DimensionKeys.Contract,
	|	Reserves.ARAPObject,
	|	Reserves.Currency,
	|	Reserves.ReversingEntry
	|
	|INDEX BY
	|	Recorder,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency";

#EndRegion
#Region QueryTextParentCompany

	QueryTextParentCompany = 
	"SELECT DISTINCT
	|	PartnersARAPAccounting.Organization AS Organization,
	|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany
	|FROM
	|	SettlementsWithMovementPartners AS PartnersARAPAccounting";

#EndRegion



#Region DebtExpense
// Debt Offset document
		#Region DebtExpenseOnNetting
		//Debt Expense table (write off all accounts receivable)
		DebtExpenseOnNetting = 
		"//Debt Expense table (write off all accounts receivable)
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""DebtExpenseOnNetting"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) = TYPE(Document.ARAPSettlement)";
		#EndRegion

// Payment documents: Receipt of BDS, PKO
		#Region DebtExpenseForSomeoneElseSSettlementObject
		// The receipt of money to the parent organization (filial) closes the debt in the branch (parent organization)
		DebtExpenseForSomeoneElseSSettlementObject =  
		"//Upon receipt of money for the branch, we will close the debt of the branch
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS Organization,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS CorPartner,
		|	PartnersARAPAccounting.Counterparty AS CorCounterparty,
		|	PartnersARAPAccounting.Contract AS CorContract,
		|	PartnersARAPAccounting.ARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS CorCurrencyOfARAPAccounting,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AdjAmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
		|	""DebtExpenseForSomeoneElseSSettlementObject"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.CashAccountReceiptNote),
		|		TYPE(Document.BankAccountReceiptNote))
		|	AND PartnersARAPAccounting.Organization <> PartnersARAPAccounting.OrganizationOfSettlementObject";
		#EndRegion

// Payment documents: Write-offs, RKO
		#Region ExpenseInOrganizationForSomeoneElseSPaymentObject
		// We pay in the parent organization (branch) for the object of calculation of the branch (parent organization)
		ExpenseInOrganizationForSomeoneElseSPaymentObject = 
		"//When paying for a branch, we will substitute the Expense in the parent organization in the documents of the write-off of the BDS and ACW
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS CorLineOfBusiness,
		|	PartnersARAPAccounting.Partner AS CorPartner,
		|	PartnersARAPAccounting.Counterparty AS CorCounterparty,
		|	PartnersARAPAccounting.Contract AS CorContract,
		|	PartnersARAPAccounting.ARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS CorCurrencyOfARAPAccounting,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AdjAmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
		|	""ExpenseInOrganizationForSomeoneElseSPaymentObject"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.CashVoucher),
		|		TYPE(Document.BankAccountIssue))
		|	AND PartnersARAPAccounting.Organization <> PartnersARAPAccounting.OrganizationOfSettlementObject";
		#EndRegion
		
// Refund of payment at the rate of advance payment: Write-offs, RKO
		#Region ExpenseRepaymentOfDebt
		ExpenseRepaymentOfDebt = 
		"//Refund at the advance rate: Repayment of debt after the transfer of the advance
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization.ParentCompany AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS CorLineOfBusiness,
		|	PartnersARAPAccounting.Partner AS CorPartner,
		|	PartnersARAPAccounting.Counterparty AS CorCounterparty,
		|	PartnersARAPAccounting.Contract AS CorContract,
		|	PartnersARAPAccounting.ARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS CorCurrencyOfARAPAccounting,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AdjAmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
		|	""ExpenseRepaymentOfDebt"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	TRUE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN TTRefundPayment AS RefundOfPayment
		|		ON PartnersARAPAccounting.Recorder = RefundOfPayment.Ref
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND NOT PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer))
		|	AND PartnersARAPAccounting.Organization = PartnersARAPAccounting.Organization.ParentCompany";
		#EndRegion
		
// Refund of payment at the rate of advance payment for the parent organization or branch: Write-offs, RKO
		#Region ExpenseWriteOffOfAdvancePaymentWhenReturningFililal
		ExpenseWriteOffOfAdvancePaymentWhenReturningFililal = 
		"//Refund at the advance rate: We write off the advance in the parent organization when returning in the branch
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization.ParentCompany AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS CorLineOfBusiness,
		|	PartnersARAPAccounting.Partner AS CorPartner,
		|	PartnersARAPAccounting.Counterparty AS CorCounterparty,
		|	PartnersARAPAccounting.Contract AS CorContract,
		|	PartnersARAPAccounting.ARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS CorCurrencyOfARAPAccounting,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AdjAmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
		|	""ExpenseWriteOffOfAdvancePaymentWhenReturningFililal"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	TRUE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN TTRefundPayment AS RefundOfPayment
		|		ON PartnersARAPAccounting.Recorder = RefundOfPayment.Ref
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND NOT PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer))";
		#EndRegion
// Debt write-off document
		#Region DebtExpenseOnWriteOff
		DebtExpenseOnWriteOff = 
		"//When writing off debt 
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	Reserves.Sum AS AmountInCurrency,
		|	Reserves.SumMan AS Sum,
		|	Reserves.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	Reserves.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	Reserves.SumCompl / 
		|		CASE WHEN Reserves.Sum = 0 
		|			THEN CASE WHEN Reserves.SumCompl = 0 
		|							THEN 1 
		|							ELSE Reserves.SumCompl
		|					END
		|			ELSE Reserves.Sum
		|		END AS MutualSettlementsExchangeRate,
		|	Reserves.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""DebtExpenseOnWriteOff"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN LossAllowance AS Reserves
		|	ON PartnersARAPAccounting.Recorder = Reserves.Recorder
		|		AND PartnersARAPAccounting.AccountingDimensionByPartners = Reserves.AccountingDimensionByPartners
		|		AND PartnersARAPAccounting.ARAPObject = Reserves.ARAPObject
		|		AND PartnersARAPAccounting.Currency = Reserves.Currency
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) = TYPE(Document.ARAPAdjustment)";
		#EndRegion
// The document is the report of the commissionaire, the report to the Committee, the report of the Commission by the organizations
		#Region ExpenseRetentionOfRemuneration
		ExpenseRetentionOfRemuneration = 
		"//When withholding rewards 
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	ISNULL(CCRegisteredRecords.Sum, 0) AS AmountInCurrency,
		|	ISNULL(CCRegisteredRecords.Sum, 0) AS Sum,
		|	ISNULL(CCRegisteredRecords.SumCompl, 0) AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.CounterpartyCompany AS CounterpartyCompany,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	ISNULL(CCRegisteredRecords.Sum, 0) AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ExpenseRetentionOfRemuneration"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	LEFT JOIN AccumulationRegister.RecordsCounterpartyCounterparty AS CCRegisteredRecords
		|	ON PartnersARAPAccounting.Recorder = CCRegisteredRecords.Recorder
		|		AND PartnersARAPAccounting.Organization = CCRegisteredRecords.Organization
		|		AND PartnersARAPAccounting.Partner = CCRegisteredRecords.CorPartner
		|		AND PartnersARAPAccounting.Counterparty = CCRegisteredRecords.CorCounterparty
		|		AND PartnersARAPAccounting.Contract = CCRegisteredRecords.CorContract
		|		AND (PartnersARAPAccounting.ARAPObject = CCRegisteredRecords.ARAPObject
		|			OR PartnersARAPAccounting.ARAPObject = CCRegisteredRecords.CorARAPObject)
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.ConsignmentReportFromCustomer),
		|		TYPE(Document.ConsignmentReportToVendor),
		|		TYPE(Document.CommissionReportIntercompany))
		|	AND PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction),
		|		VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor))
		|
		|ORDER BY
		|	PartnersARAPAccounting.Recorder,
		|	PartnersARAPAccounting.Organization,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum DESC
		|TOTALS
		|	MAX(CounterpartyCompany),
		|	MAX(ThisIsRefundOfAdvance)
		|BY
		|	PartnersARAPAccounting.Recorder,
		|	PartnersARAPAccounting.Organization";
		#EndRegion

		DebtExpense = New Array;
		DebtExpense.Add(DebtExpenseOnNetting);
		DebtExpense.Add(DebtExpenseForSomeoneElseSSettlementObject);
		DebtExpense.Add(ExpenseInOrganizationForSomeoneElseSPaymentObject);
		DebtExpense.Add(ExpenseRepaymentOfDebt);
		DebtExpense.Add(ExpenseWriteOffOfAdvancePaymentWhenReturningFililal);
		DebtExpense.Add(DebtExpenseOnWriteOff);
		DebtExpense.Add(ExpenseRetentionOfRemuneration);
		
		//Debited debt for repayment
		QueryTextAccountsReceivable = StrConcat(DebtExpense, TMCommonUse.QuerySeparatorInJoin());
#EndRegion



#Region ArrivalOfDebt
// Debt Offset document
		#Region ArrivalOfDebtOnNetting
		ArrivalOfDebtOnNetting = 
		"//The table of Arrival of debt (we receive all accounts payable)
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS CorLineOfBusiness,
		|	PartnersARAPAccounting.Partner AS CorPartner,
		|	PartnersARAPAccounting.Counterparty AS CorCounterparty,
		|	PartnersARAPAccounting.Contract AS CorContract,
		|	PartnersARAPAccounting.ARAPObject AS CorARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS CorAmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS CorCurrencyOfARAPAccounting,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AdjAmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
		|	""ArrivalOfDebtOnNetting"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) = TYPE(Document.ARAPSettlement)";
		#EndRegion

// Payment documents: Receipt of BDS, PKO
		#Region JoiningOrganizationForSomeoneElseSPaymentObject
		JoiningOrganizationForSomeoneElseSPaymentObject = //in a branch office, this is an expense to the parent organization
		"//When receiving money for a branch, we will substitute the Arrival to the parent organization for the expense in the receipt documents of the BDS and ICO
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Receipt),
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""JoiningOrganizationForSomeoneElseSPaymentObject"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.CashAccountReceiptNote),
		|		TYPE(Document.BankAccountReceiptNote))
		|	AND PartnersARAPAccounting.Organization <> PartnersARAPAccounting.OrganizationOfSettlementObject";
		#EndRegion
		
// Payment documents: Write-offs, RKO
		#Region ArrivalOfDebtForSomeoneElseSObjectOfCalculations
		// When paying for someone else's calculation object, the supplier's debt for this calculation object is formed
		ArrivalOfDebtForSomeoneElseSObjectOfCalculations = 
		"//When paying for a branch, we will close the branch's debt
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Receipt),
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject,
		|	PartnersARAPAccounting.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.OrganizationOfSettlementObject AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ArrivalOfDebtForSomeoneElseSObjectOfCalculations"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.CashVoucher),
		|		TYPE(Document.BankAccountIssue))
		|	AND PartnersARAPAccounting.Organization <> PartnersARAPAccounting.OrganizationOfSettlementObject";
		#EndRegion

// Refund at the rate of the advance payment: receipt of the BDS, PKO
		#Region ArrivalTransferOfAdvancePayment
		ArrivalTransferOfAdvancePayment = 
		"// Refund at the advance rate - Transfer of the advance
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Receipt),
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization.ParentCompany,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	RefundOfPayment.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ArrivalTransferOfAdvancePayment"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	TRUE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN TTRefundPayment AS RefundOfPayment
		|		ON PartnersARAPAccounting.Recorder = RefundOfPayment.Ref
		|		AND PartnersARAPAccounting.Organization = RefundOfPayment.Organization
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND NOT PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer))";
		#EndRegion

// Refund at the rate of the advance payment: receipt of the BDS, PKO, write-off of the BDS, RKO
		#Region ArrivalTransferToAdvancePaymentWhenReturningBranch
		ArrivalTransferToAdvancePaymentWhenReturningBranch = 
		"// Refund at the advance rate - Transfer of the advance
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	VALUE(AccumulationRecordType.Receipt),
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	RefundOfPayment.Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.ARAPObject.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	PartnersARAPAccounting.Sum AS AmountInCurrency,
		|	PartnersARAPAccounting.SumMan AS Sum,
		|	PartnersARAPAccounting.SumCompl AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	PartnersARAPAccounting.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ArrivalTransferToAdvancePaymentWhenReturningBranch"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	TRUE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN TTRefundPayment AS RefundOfPayment
		|		ON PartnersARAPAccounting.Recorder = RefundOfPayment.Ref
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND NOT PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.RefundFromVendor),
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer))
		|	AND PartnersARAPAccounting.Organization <> RefundOfPayment.Organization";
		#EndRegion
//Debt write-off document
		#Region ArrivalOfDebtWhenWritingOff
		ArrivalOfDebtWhenWritingOff = 
		"//When writing off debt (the arrival table is exactly the same as the expense table) 
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	Reserves.Sum AS AmountInCurrency,
		|	Reserves.SumMan AS Sum,
		|	Reserves.SumCompl AS SumCompl,
		|	Reserves.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance) AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	Reserves.SumCompl / 
		|		CASE WHEN Reserves.Sum = 0 
		|			THEN CASE WHEN Reserves.SumCompl = 0 
		|							THEN 1 
		|							ELSE Reserves.SumCompl
		|					END
		|			ELSE Reserves.Sum
		|		END AS MutualSettlementsExchangeRate,
		|	Reserves.Sum AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ArrivalOfDebtWhenWritingOff"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	INNER JOIN LossAllowance AS Reserves
		|	ON PartnersARAPAccounting.Recorder = Reserves.Recorder
		|		AND PartnersARAPAccounting.AccountingDimensionByPartners = Reserves.AccountingDimensionByPartners
		|		AND PartnersARAPAccounting.ARAPObject = Reserves.ARAPObject
		|		AND PartnersARAPAccounting.Currency = Reserves.Currency
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) = TYPE(Document.ARAPAdjustment)";
		#EndRegion
// The document is the report of the commissionaire, the report to the Committee, the report of the Commission by the organizations
		#Region ArrivalRetentionOfRemuneration
		ArrivalRetentionOfRemuneration = 
		"//When withholding a reward 
		|SELECT
		|	PartnersARAPAccounting.Period,
		|	PartnersARAPAccounting.RecordType AS RecordType,
		|	PartnersARAPAccounting.Recorder AS Recorder,
		|	PartnersARAPAccounting.Organization AS Organization,
		|	PartnersARAPAccounting.Organization.ParentCompany AS ParentCompany,
		|	PartnersARAPAccounting.Organization AS APARObjectOwner,
		|	PartnersARAPAccounting.LineOfBusiness AS LineOfBusiness,
		|	PartnersARAPAccounting.Partner AS Partner,
		|	PartnersARAPAccounting.Counterparty AS Counterparty,
		|	PartnersARAPAccounting.Contract AS Contract,
		|	PartnersARAPAccounting.ARAPObject AS ARAPObject,
		|	PartnersARAPAccounting.Currency,
		|	ISNULL(CCRegisteredRecords.Sum, 0) AS AmountInCurrency,
		|	ISNULL(CCRegisteredRecords.Sum, 0) AS Sum,
		|	ISNULL(CCRegisteredRecords.SumCompl, 0) AS SumCompl,
		|	PartnersARAPAccounting.AmountType AS AmountType,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessTransactionRegister,
		|	PartnersARAPAccounting.BusinessOperation AS BusinessOperation,
		|	PartnersARAPAccounting.ARAPObject.Department AS Department,
		|	PartnersARAPAccounting.Currency AS ARAPCurrency,
		|	PartnersARAPAccounting.SumCompl / 
		|		CASE WHEN PartnersARAPAccounting.Sum = 0 
		|			THEN CASE WHEN PartnersARAPAccounting.SumCompl = 0 THEN 1 ELSE PartnersARAPAccounting.SumCompl END
		|			ELSE PartnersARAPAccounting.Sum 
		|		END AS MutualSettlementsExchangeRate,
		|	ISNULL(CCRegisteredRecords.Sum, 0) AS AmountInARAPCurrency,
		|	PartnersARAPAccounting.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|	""ArrivalRetentionOfRemuneration"" AS TableName,
		|	PartnersARAPAccounting.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
		|	PartnersARAPAccounting.Organization = PartnersARAPAccounting.ParentCompany AS ThisIsParentOrganization,
		|	FALSE AS ThisIsRefundOfAdvance,
		|	PartnersARAPAccounting.ReversingEntry AS ReversingEntry
		|FROM
		|	PartnersARAPAccounting AS PartnersARAPAccounting
		|	LEFT JOIN AccumulationRegister.RecordsCounterpartyCounterparty AS CCRegisteredRecords
		|	ON PartnersARAPAccounting.Recorder = CCRegisteredRecords.Recorder
		|		AND PartnersARAPAccounting.Organization = CCRegisteredRecords.Organization
		|		AND PartnersARAPAccounting.Partner = CCRegisteredRecords.Partner
		|		AND PartnersARAPAccounting.Counterparty = CCRegisteredRecords.Counterparty
		|		AND PartnersARAPAccounting.Contract = CCRegisteredRecords.Contract
		|		AND (PartnersARAPAccounting.ARAPObject = CCRegisteredRecords.ARAPObject
		|			OR PartnersARAPAccounting.ARAPObject = CCRegisteredRecords.CorARAPObject)
		|WHERE
		|	PartnersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND VALUETYPE(PartnersARAPAccounting.Recorder) IN (
		|		TYPE(Document.ConsignmentReportFromCustomer),
		|		TYPE(Document.ConsignmentReportToVendor),
		|		TYPE(Document.CommissionReportIntercompany))
		|	AND PartnersARAPAccounting.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction),
		|		VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor))";
		#EndRegion

		ArrivalOfDebt = New Array;
		ArrivalOfDebt.Add(ArrivalOfDebtOnNetting);
		ArrivalOfDebt.Add(JoiningOrganizationForSomeoneElseSPaymentObject);
		ArrivalOfDebt.Add(ArrivalOfDebtForSomeoneElseSObjectOfCalculations);
		ArrivalOfDebt.Add(ArrivalTransferOfAdvancePayment);
		ArrivalOfDebt.Add(ArrivalTransferToAdvancePaymentWhenReturningBranch);
		ArrivalOfDebt.Add(ArrivalOfDebtWhenWritingOff);
		ArrivalOfDebt.Add(ArrivalRetentionOfRemuneration);
		
		//Repayable debt
		QueryTextAccountsPayable = StrConcat(ArrivalOfDebt, TMCommonUse.QuerySeparatorInJoin());

#EndRegion

	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfRegistrarsRequest);
	QueriesTexts.Add(QueryTextRefundOfPayment);
	QueriesTexts.Add(QueryTextSettlementsWithMovementPartners);
	QueriesTexts.Add(QueryTextPartnersARAPAccounting);
	QueriesTexts.Add(QueryTextLossAllowance);
	QueriesTexts.Add(QueryTextParentCompany);
	QueriesTexts.Add(QueryTextAccountsReceivable);
	QueriesTexts.Add(QueryTextAccountsPayable);
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Return QueryText;
	
EndFunction

Function TrafficRequestTextForDocuments(TableName, TempTableName = "", ReversingEntry = False)
	
	QueryText = 
	"SELECT
	|	VendorsARAPAccounting.Period,
	|	VendorsARAPAccounting.RecordType AS TypeOfRegisterMovement,
	|	CASE
	|		WHEN (VendorsARAPAccounting.Debt < 0 OR VendorsARAPAccounting.Prepayment + VendorsARAPAccounting.ForReturn < 0)
	|			AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		WHEN (VendorsARAPAccounting.Debt < 0 OR VendorsARAPAccounting.Prepayment + VendorsARAPAccounting.ForReturn < 0)
	|			AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VendorsARAPAccounting.RecordType
	|	END AS RecordType,
	|	VendorsARAPAccounting.Recorder AS Recorder,
	|	DimensionKeys.Organization,
	|	DimensionKeys.LineOfBusiness AS LineOfBusiness,
	|	DimensionKeys.Partner,
	|	DimensionKeys.Counterparty AS Counterparty,
	|	DimensionKeys.Contract AS Contract,
	|	VendorsARAPAccounting.PurchaseOrder AS ARAPObject,
	|	VendorsARAPAccounting.Currency,
	|	1*CASE WHEN VendorsARAPAccounting.Debt <> 0
	|		THEN CASE WHEN VendorsARAPAccounting.Debt < 0 THEN -VendorsARAPAccounting.Debt ELSE VendorsARAPAccounting.Debt END
	|		ELSE CASE WHEN VendorsARAPAccounting.Prepayment + VendorsARAPAccounting.ForReturn < 0 THEN -(VendorsARAPAccounting.Prepayment + VendorsARAPAccounting.ForReturn) ELSE VendorsARAPAccounting.Prepayment + VendorsARAPAccounting.ForReturn END
	|	END AS Sum,
	|	1*CASE WHEN VendorsARAPAccounting.ARAPMan <> 0
	|		THEN CASE WHEN VendorsARAPAccounting.ARAPMan < 0 THEN -VendorsARAPAccounting.ARAPMan ELSE VendorsARAPAccounting.ARAPMan END
	|		ELSE CASE WHEN VendorsARAPAccounting.PrepaymentMan < 0 THEN -VendorsARAPAccounting.PrepaymentMan ELSE VendorsARAPAccounting.PrepaymentMan END
	|	END AS SumMan,
	|	1*CASE WHEN VendorsARAPAccounting.DebtLocal <> 0
	|		THEN CASE WHEN VendorsARAPAccounting.DebtLocal < 0 THEN -VendorsARAPAccounting.DebtLocal ELSE VendorsARAPAccounting.DebtLocal END
	|		ELSE CASE WHEN VendorsARAPAccounting.PrepaymentLocal < 0 THEN -VendorsARAPAccounting.PrepaymentLocal ELSE VendorsARAPAccounting.PrepaymentLocal END
	|	END AS SumCompl,
	|
	|	CASE WHEN VendorsARAPAccounting.DebtLocal <> 0
	|		THEN VALUE(Enum.TypesOfDebtAmounts.VendorAccountsPayable)
	|		ELSE VALUE(Enum.TypesOfDebtAmounts.PrepaymentToVendor)
	|	END AS AmountType,
	|
	|	&TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
	|	DimensionKeys.Partner = VALUE(Catalog.Partners.OurEnterprise) AS OurEnterprise,
	|	VendorsARAPAccounting.DebtLocal < 0 OR VendorsARAPAccounting.PrepaymentLocal < 0 AS ReversingEntry,
	|	VALUETYPE(DimensionKeys.Counterparty) = TYPE(Catalog.Companies) AS CounterpartyCompany,
	|
	|	VendorsARAPAccounting.BusinessOperation AS BusinessOperation,
	|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|	
	|,&TableName
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS VendorsARAPAccounting
	|		INNER JOIN TTRecorders_ AS T
	|			ON VendorsARAPAccounting.Recorder = T.Document
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
	|			ON VendorsARAPAccounting.AccountingDimensionByPartners = DimensionKeys.DimensionKey
	|WHERE
	|	NOT VendorsARAPAccounting.BusinessOperation IN 
	|		(VALUE(Enum.BusinessTransactions.RecordShortagesAtVendorSExpenseOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.RecordShortagesAtThirdPartyExpenseOnGoodsReceipt))";
	
	QueryText = PerformSubstitutions(QueryText, TableName, TempTableName, ReversingEntry);
	If TableName <> "VendorsARAPAccounting" Then
		QueryText = StrReplace(QueryText, "PurchaseOrder", "SalesOrder");
		QueryText = StrReplace(QueryText, "AccumulationRecordType.Receipt", "AccumulationRecordType._Expense");
		QueryText = StrReplace(QueryText, "AccumulationRecordType.Expense", "AccumulationRecordType.Receipt");
		QueryText = StrReplace(QueryText, "AccumulationRecordType._Expense", "AccumulationRecordType.Expense");
	EndIf;
	
	Return QueryText;
	
EndFunction
#EndRegion

Function PerformSubstitutions(QueryText, TableName, TempTableName, ReversingEntry)
	
	If ReversingEntry Then
		QueryText = StrReplace(QueryText, "1*", "-");
		QueryText = StrReplace(QueryText, "VendorsARAPAccounting.Period", "T.RecordingInAccountingDate");
		QueryText = StrReplace(QueryText, "TTRecorders_", "ReversedDocuments");
		QueryText = StrReplace(QueryText, "T.Document", "T.ReversedDocument");
		QueryText = StrReplace(QueryText, "&ReversingEntry", "TRUE");
		QueryText = StrReplace(QueryText, "&Recorder", "T.Document");
	Else
		QueryText = StrReplace(QueryText, "&Recorder", "VendorsARAPAccounting.DocumentRecorder");
		QueryText = StrReplace(QueryText, "1*", "");
		QueryText = StrReplace(QueryText, "&ReversingEntry", "VendorsARAPAccounting.ReversingEntry");
	EndIf;
	
	ResourceName = "VendorsARAPAccounting.DebtLocal";
	If TableName = "VendorsARAPAccounting" Then
		QueryText = StrReplace(QueryText, "&NotRefundOfPayment", "Return.Ref IS NULL");
		QueryText = StrReplace(QueryText, "&TheseAreSettlementsWithCustomers", "FALSE");
	Else
		EnumerationMetadata = Metadata.Enums.TypesOfDebtAmounts.EnumValues;
		ResourceName = TableName + "." + "PrepaymentLocal";
		QueryText = StrReplace(QueryText, "VendorsARAPAccounting", TableName);
		QueryText = StrReplace(QueryText, "PrepaymentToVendor", EnumerationMetadata.PrepaymentFromCustomer.Name);
		QueryText = StrReplace(QueryText, "VendorAccountsPayable", EnumerationMetadata.CustomerAccountsReceivable.Name);
		QueryText = StrReplace(QueryText, "VendorAccountsPayable", EnumerationMetadata.CustomerAccountsReceivable.Name);
		QueryText = StrReplace(QueryText, "&NotRefundOfPayment", "TRUE");
		QueryText = StrReplace(QueryText, "&TheseAreSettlementsWithCustomers", "TRUE");
	EndIf;
	QueryText = StrReplace(QueryText, "&Resource", ResourceName);
	
	If TempTableName = "" Then
		QueryText = StrReplace(QueryText, Chars.LF + ",&TableName", "");
	Else
		QueryText = StrReplace(QueryText, ",&TableName", "INTO " + TempTableName);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextRecordsCounterpartyCounterparty()
	
	Return
	"SELECT
	|	NewRegisteredRecords_.Period,
	|	NewRegisteredRecords_.LineNumber,
	|	NewRegisteredRecords_.Recorder AS Recorder,
	|
	|	NewRegisteredRecords_.BusinessOperation,
	|	NewRegisteredRecords_.Organization,
	|	NewRegisteredRecords_.Department,
	|
	|	NewRegisteredRecords_.LineOfBusiness,
	|	NewRegisteredRecords_.Partner,
	|	NewRegisteredRecords_.Counterparty AS Counterparty,
	|	NewRegisteredRecords_.ARAPObject AS ARAPObject,
	|	NewRegisteredRecords_.Contract,
	|
	|	NewRegisteredRecords_.CorLineOfBusiness,
	|	NewRegisteredRecords_.CorPartner,
	|	NewRegisteredRecords_.CorCounterparty AS CorCounterparty,
	|	NewRegisteredRecords_.CorARAPObject AS CorARAPObject,
	|	NewRegisteredRecords_.CorContract,
	|
	|	NewRegisteredRecords_.AmountType,
	|	NewRegisteredRecords_.CorAmountType,
	|
	|	NewRegisteredRecords_.Sum AS Sum,
	|	NewRegisteredRecords_.AmountExcludingVAT AS AmountExcludingVAT,
	|	NewRegisteredRecords_.SumCompl AS SumCompl,
	|	NewRegisteredRecords_.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|
	|	NewRegisteredRecords_.Currency,
	|	NewRegisteredRecords_.AmountInCurrency AS AmountInCurrency,
	|	NewRegisteredRecords_.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
	|
	|	NewRegisteredRecords_.ARAPCurrency,
	|	NewRegisteredRecords_.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	NewRegisteredRecords_.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
	|
	|	NewRegisteredRecords_.CorCurrencyOfARAPAccounting,
	|	NewRegisteredRecords_.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|	NewRegisteredRecords_.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency,
	|
	|	NewRegisteredRecords_.SourceOfARAPFinancialAccountingGroup,
	|	NewRegisteredRecords_.CorSourceOfARAPFinancialAccountingGroup,
	|	NewRegisteredRecords_.ReversingEntry
	|
	|INTO TTNewRegisterRegisterRecords
	|FROM
	|	&RegisterRecordTable AS NewRegisteredRecords_
	|WHERE
	|	NewRegisteredRecords_.Recorder <> UNDEFINED
	|
	|INDEX BY
	|	Recorder,
	|	NewRegisteredRecords_.Organization,
	|	NewRegisteredRecords_.Partner,
	|	Counterparty,
	|	ARAPObject,
	|	NewRegisteredRecords_.CorPartner,
	|	CorCounterparty,
	|	CorARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RegisterEntries_.Recorder,
	|
	|	RegisterEntries_.Organization,
	|	RegisterEntries_.Department
	|
	|INTO TTUnits
	|FROM
	|	AccumulationRegister.RecordsCounterpartyCounterparty AS RegisterEntries_
	|WHERE
	|	RegisterEntries_.Recorder IN (&DocumentsArray)
	|
	|INDEX BY
	|	Recorder,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewRegisteredRecords_.Period,
	|	NewRegisteredRecords_.LineNumber AS LineNumber,
	|	NewRegisteredRecords_.Recorder AS Recorder,
	|	NewRegisteredRecords_.BusinessOperation,
	|
	|	NewRegisteredRecords_.Organization,
	|	RegisterEntries_.Department,
	|
	|	NewRegisteredRecords_.LineOfBusiness,
	|	NewRegisteredRecords_.Partner,
	|	NewRegisteredRecords_.Counterparty AS Counterparty,
	|	NewRegisteredRecords_.ARAPObject AS ARAPObject,
	|	NewRegisteredRecords_.Contract,
	|
	|	NewRegisteredRecords_.CorLineOfBusiness,
	|	NewRegisteredRecords_.CorPartner,
	|	NewRegisteredRecords_.CorCounterparty AS CorCounterparty,
	|	NewRegisteredRecords_.CorARAPObject AS CorARAPObject,
	|	NewRegisteredRecords_.CorContract,
	|
	|	NewRegisteredRecords_.AmountType,
	|	NewRegisteredRecords_.CorAmountType,
	|
	|	NewRegisteredRecords_.Sum AS Sum,
	|	NewRegisteredRecords_.AmountExcludingVAT AS AmountExcludingVAT,
	|	NewRegisteredRecords_.SumCompl AS SumCompl,
	|	NewRegisteredRecords_.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|
	|	NewRegisteredRecords_.Currency,
	|	NewRegisteredRecords_.AmountInCurrency AS AmountInCurrency,
	|	NewRegisteredRecords_.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
	|
	|	NewRegisteredRecords_.ARAPCurrency,
	|	NewRegisteredRecords_.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	NewRegisteredRecords_.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
	|
	|	NewRegisteredRecords_.CorCurrencyOfARAPAccounting,
	|	NewRegisteredRecords_.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|	NewRegisteredRecords_.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency,
	|
	|	NewRegisteredRecords_.SourceOfARAPFinancialAccountingGroup,
	|	NewRegisteredRecords_.CorSourceOfARAPFinancialAccountingGroup,
	|	NewRegisteredRecords_.ReversingEntry
	|INTO TTNewRegisteredRecords
	|FROM
	|	TTNewRegisterRegisterRecords AS NewRegisteredRecords_
	|		INNER JOIN TTUnits AS RegisterEntries_
	|		ON NewRegisteredRecords_.Recorder = RegisterEntries_.Recorder
	|			AND NewRegisteredRecords_.Organization = RegisterEntries_.Organization
	|WHERE
	|	VALUETYPE(NewRegisteredRecords_.Recorder) = TYPE(Document.ARAPSettlement)
	|
	|UNION ALL
	|
	|SELECT
	|	NewRegisteredRecords_.Period,
	|	NewRegisteredRecords_.LineNumber AS LineNumber,
	|	NewRegisteredRecords_.Recorder AS Recorder,
	|	NewRegisteredRecords_.BusinessOperation,
	|
	|	NewRegisteredRecords_.Organization,
	|	NewRegisteredRecords_.Department,
	|
	|	NewRegisteredRecords_.LineOfBusiness,
	|	NewRegisteredRecords_.Partner,
	|	NewRegisteredRecords_.Counterparty AS Counterparty,
	|	NewRegisteredRecords_.ARAPObject AS ARAPObject,
	|	NewRegisteredRecords_.Contract,
	|
	|	NewRegisteredRecords_.CorLineOfBusiness,
	|	NewRegisteredRecords_.CorPartner,
	|	NewRegisteredRecords_.CorCounterparty AS CorCounterparty,
	|	NewRegisteredRecords_.CorARAPObject AS CorARAPObject,
	|	NewRegisteredRecords_.CorContract,
	|
	|	NewRegisteredRecords_.AmountType,
	|	NewRegisteredRecords_.CorAmountType,
	|
	|	NewRegisteredRecords_.Sum AS Sum,
	|	NewRegisteredRecords_.AmountExcludingVAT AS AmountExcludingVAT,
	|	NewRegisteredRecords_.SumCompl AS SumCompl,
	|	NewRegisteredRecords_.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|
	|	NewRegisteredRecords_.Currency,
	|	NewRegisteredRecords_.AmountInCurrency AS AmountInCurrency,
	|	NewRegisteredRecords_.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
	|
	|	NewRegisteredRecords_.ARAPCurrency,
	|	NewRegisteredRecords_.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	NewRegisteredRecords_.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
	|
	|	NewRegisteredRecords_.CorCurrencyOfARAPAccounting,
	|	NewRegisteredRecords_.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|	NewRegisteredRecords_.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency,
	|
	|	NewRegisteredRecords_.SourceOfARAPFinancialAccountingGroup,
	|	NewRegisteredRecords_.CorSourceOfARAPFinancialAccountingGroup,
	|	NewRegisteredRecords_.ReversingEntry
	|FROM
	|	TTNewRegisterRegisterRecords AS NewRegisteredRecords_
	|WHERE
	|	VALUETYPE(NewRegisteredRecords_.Recorder) <> TYPE(Document.ARAPSettlement)
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterEntries_.Period,
	|	RegisterEntries_.LineNumber,
	|	RegisterEntries_.Recorder,
	|	RegisterEntries_.BusinessOperation,
	|
	|	RegisterEntries_.Organization,
	|	RegisterEntries_.Department,
	|
	|	RegisterEntries_.LineOfBusiness,
	|	RegisterEntries_.Partner,
	|	RegisterEntries_.Counterparty,
	|	RegisterEntries_.ARAPObject,
	|	RegisterEntries_.Contract,
	|
	|	RegisterEntries_.CorLineOfBusiness,
	|	RegisterEntries_.CorPartner,
	|	RegisterEntries_.CorCounterparty,
	|	RegisterEntries_.CorARAPObject,
	|	RegisterEntries_.CorContract,
	|
	|	RegisterEntries_.AmountType,
	|	RegisterEntries_.CorAmountType,
	|
	|	RegisterEntries_.Sum,
	|	RegisterEntries_.AmountExcludingVAT,
	|	RegisterEntries_.SumCompl,
	|	RegisterEntries_.LocalAmountExcludingVAT,
	|
	|	RegisterEntries_.Currency,
	|	RegisterEntries_.AmountInCurrency,
	|	RegisterEntries_.AmountExcludingVATInCurrency,
	|
	|	RegisterEntries_.ARAPCurrency,
	|	RegisterEntries_.AmountInARAPCurrency,
	|	RegisterEntries_.AmountExcludingVATInARAPCurrency,
	|
	|	RegisterEntries_.CorCurrencyOfARAPAccounting,
	|	RegisterEntries_.AdjAmountInARAPCurrency,
	|	RegisterEntries_.AdjAmountExcludingVATInARAPCurrency,
	|
	|	RegisterEntries_.SourceOfARAPFinancialAccountingGroup,
	|	RegisterEntries_.CorSourceOfARAPFinancialAccountingGroup,
	|	RegisterEntries_.ReversingEntry
	|FROM
	|	AccumulationRegister.RecordsCounterpartyCounterparty AS RegisterEntries_
	|		LEFT JOIN TTNewRegisterRegisterRecords AS NewRegisteredRecords_
	|		ON RegisterEntries_.Recorder = NewRegisteredRecords_.Recorder
	|			AND RegisterEntries_.Organization = NewRegisteredRecords_.Organization
	|WHERE
	|	NewRegisteredRecords_.Recorder IS NULL
	|	AND RegisterEntries_.Recorder IN (&DocumentsArray)
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AlteredRegisteredRecords.Recorder AS Recorder,
	|
	|	COUNT(DISTINCT AlteredRegisteredRecords.AmountType) AS AmountTypeChanged,
	|	COUNT(DISTINCT AlteredRegisteredRecords.CorAmountType) AS CorAmountTypeHasBeenChanged,
	|
	|	SUM(AlteredRegisteredRecords.Sum) AS Sum,
	|	SUM(AlteredRegisteredRecords.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(AlteredRegisteredRecords.SumCompl) AS SumCompl,
	|	SUM(AlteredRegisteredRecords.LocalAmountExcludingVAT) AS LocalAmountExcludingVAT,
	|
	|	SUM(AlteredRegisteredRecords.AmountInCurrency) AS AmountInCurrency,
	|	SUM(AlteredRegisteredRecords.AmountExcludingVATInCurrency) AS AmountExcludingVATInCurrency,
	|
	|	SUM(AlteredRegisteredRecords.AmountInARAPCurrency) AS AmountInARAPCurrency,
	|	SUM(AlteredRegisteredRecords.AmountExcludingVATInARAPCurrency) AS AmountExcludingVATInARAPCurrency,
	|
	|	SUM(AlteredRegisteredRecords.AdjAmountInARAPCurrency) AS AdjAmountInARAPCurrency,
	|	SUM(AlteredRegisteredRecords.AdjAmountExcludingVATInARAPCurrency) AS AdjAmountExcludingVATInARAPCurrency
	|
	|INTO TTModifiedDocuments
	|FROM
	|	(SELECT
	|		RegisterEntries_.Recorder AS Recorder,
	|
	|		RegisterEntries_.AmountType AS AmountType,
	|		RegisterEntries_.CorAmountType AS CorAmountType,
	|
	|		RegisterEntries_.Sum AS Sum,
	|		RegisterEntries_.AmountExcludingVAT AS AmountExcludingVAT,
	|		RegisterEntries_.SumCompl AS SumCompl,
	|		RegisterEntries_.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|
	|		RegisterEntries_.AmountInCurrency AS AmountInCurrency,
	|		RegisterEntries_.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
	|
	|		RegisterEntries_.AmountInARAPCurrency AS AmountInARAPCurrency,
	|		RegisterEntries_.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
	|
	|		RegisterEntries_.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|		RegisterEntries_.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency
	|	FROM
	|		AccumulationRegister.RecordsCounterpartyCounterparty AS RegisterEntries_
	|	WHERE
	|		RegisterEntries_.Recorder IN (&DocumentsArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		NewRegisteredRecords_.Recorder AS Recorder,
	|
	|		NewRegisteredRecords_.AmountType AS AmountType,
	|		NewRegisteredRecords_.CorAmountType AS CorAmountType,
	|
	|		-NewRegisteredRecords_.Sum AS Sum,
	|		-NewRegisteredRecords_.AmountExcludingVAT AS AmountExcludingVAT,
	|		-NewRegisteredRecords_.SumCompl AS SumCompl,
	|		-NewRegisteredRecords_.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|
	|		-NewRegisteredRecords_.AmountInCurrency AS AmountInCurrency,
	|		-NewRegisteredRecords_.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
	|
	|		-NewRegisteredRecords_.AmountInARAPCurrency AS AmountInARAPCurrency,
	|		-NewRegisteredRecords_.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
	|
	|		-NewRegisteredRecords_.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|		-NewRegisteredRecords_.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency
	|	FROM
	|		TTNewRegisteredRecords AS NewRegisteredRecords_
	|	) AS AlteredRegisteredRecords
	|
	|GROUP BY
	|	AlteredRegisteredRecords.Recorder
	|
	|HAVING
	|	COUNT(DISTINCT AlteredRegisteredRecords.AmountType) > 1
	|	OR COUNT(DISTINCT AlteredRegisteredRecords.CorAmountType) > 1
	|
	|	OR SUM(AlteredRegisteredRecords.Sum) <> 0
	|	OR SUM(AlteredRegisteredRecords.AmountExcludingVAT) <> 0
	|	OR SUM(AlteredRegisteredRecords.SumCompl) <> 0
	|	OR SUM(AlteredRegisteredRecords.LocalAmountExcludingVAT) <> 0
	|
	|	OR SUM(AlteredRegisteredRecords.AmountInCurrency) <> 0
	|	OR SUM(AlteredRegisteredRecords.AmountExcludingVATInCurrency) <> 0
	|
	|	OR SUM(AlteredRegisteredRecords.AmountInARAPCurrency) <> 0
	|	OR SUM(AlteredRegisteredRecords.AmountExcludingVATInARAPCurrency) <> 0
	|
	|	OR SUM(AlteredRegisteredRecords.AdjAmountInARAPCurrency) <> 0
	|	OR SUM(AlteredRegisteredRecords.AdjAmountExcludingVATInARAPCurrency) <> 0
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewRegisteredRecords_.Period,
	|	NewRegisteredRecords_.LineNumber AS LineNumber,
	|	NewRegisteredRecords_.Recorder AS Recorder,
	|	NewRegisteredRecords_.BusinessOperation,
	|
	|	NewRegisteredRecords_.Organization,
	|	NewRegisteredRecords_.Department,
	|
	|	NewRegisteredRecords_.Organization.ParentCompany AS CompanyParentCompany,
	|
	|	NewRegisteredRecords_.LineOfBusiness,
	|	NewRegisteredRecords_.Partner,
	|	NewRegisteredRecords_.Counterparty AS Counterparty,
	|	NewRegisteredRecords_.ARAPObject AS ARAPObject,
	|	NewRegisteredRecords_.Contract,
	|
	|	CounterpartiesOfCompany.ParentCompany AS CounterpartyParentCompany,
	|	ARAPObjects.Department AS ObjectOfCalculationsDivision,
	|	ARAPObjects.UUID AS ARAPObjectIsUniqueIdentifier,
	|
	|	NewRegisteredRecords_.CorLineOfBusiness,
	|	NewRegisteredRecords_.CorPartner,
	|	NewRegisteredRecords_.CorCounterparty AS CorCounterparty,
	|	NewRegisteredRecords_.CorARAPObject AS CorARAPObject,
	|	NewRegisteredRecords_.CorContract,
	|
	|	CorCounterpartiesCompanies.ParentCompany AS CorCounterpartyParentCompany,
	|	CorObjectsOfCalculations.Department AS CorObjectOfCalculationsDivision,
	|	CorObjectsOfCalculations.UUID AS CorARAPObjectUniqueIdentifier,
	|
	|	NewRegisteredRecords_.AmountType,
	|	NewRegisteredRecords_.CorAmountType,
	|
	|	NewRegisteredRecords_.Sum AS Sum,
	|	NewRegisteredRecords_.AmountExcludingVAT AS AmountExcludingVAT,
	|	NewRegisteredRecords_.SumCompl AS SumCompl,
	|	NewRegisteredRecords_.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|
	|	NewRegisteredRecords_.Currency,
	|	NewRegisteredRecords_.AmountInCurrency AS AmountInCurrency,
	|	NewRegisteredRecords_.AmountExcludingVATInCurrency AS AmountExcludingVATInCurrency,
	|
	|	NewRegisteredRecords_.ARAPCurrency,
	|	NewRegisteredRecords_.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	NewRegisteredRecords_.AmountExcludingVATInARAPCurrency AS AmountExcludingVATInARAPCurrency,
	|
	|	NewRegisteredRecords_.CorCurrencyOfARAPAccounting,
	|	NewRegisteredRecords_.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|	NewRegisteredRecords_.AdjAmountExcludingVATInARAPCurrency AS AdjAmountExcludingVATInARAPCurrency,
	|
	|	NewRegisteredRecords_.SourceOfARAPFinancialAccountingGroup,
	|	NewRegisteredRecords_.CorSourceOfARAPFinancialAccountingGroup,
	|	NewRegisteredRecords_.ReversingEntry,
	|
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	TTNewRegisteredRecords AS NewRegisteredRecords_
	|	INNER JOIN TTModifiedDocuments AS ModifiedDocuments
	|	ON NewRegisteredRecords_.Recorder = ModifiedDocuments.Recorder
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|	ON NewRegisteredRecords_.ARAPObject = ARAPObjects.Ref
	|	LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|	ON NewRegisteredRecords_.CorARAPObject = CorObjectsOfCalculations.Ref
	|	LEFT JOIN Catalog.Companies AS CounterpartiesOfCompany
	|	ON NewRegisteredRecords_.Counterparty = CounterpartiesOfCompany.Ref
	|	LEFT JOIN Catalog.Companies AS CorCounterpartiesCompanies
	|	ON NewRegisteredRecords_.CorCounterparty = CorCounterpartiesCompanies.Ref
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON NewRegisteredRecords_.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|ORDER BY
	|	Period,
	|	Recorder,
	|	LineNumber
	|
	|TOTALS BY
	|	Recorder
	|";
	
EndFunction

Function QueryTextBeforeWrite(RegisterName)

	QueryText = 
	"SELECT
	|	Table.Period,
	|	Table.Recorder,
	|	&MeasurementText_1,
	|	&TextAttributes,
	|	&TextResources_
	|INTO SourceTable
	|FROM 
	|	&RegisterName AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|";
	
	Dimensions = Metadata.AccumulationRegisters[RegisterName].Dimensions;
	NumberOfMeasurements = Dimensions.Count();
	MeasurementText_1 = "";
	For Each Dimension In Dimensions Do
		MeasurementText_1 = MeasurementText_1 + Chars.LF + Chars.Tab + "Table." + Dimension.Name;
		MeasurementText_1 = MeasurementText_1 + ?(Dimensions.IndexOf(Dimension) = NumberOfMeasurements - 1, "", ",");
	EndDo;
	Attributes = Metadata.AccumulationRegisters[RegisterName].Attributes;
	AttributesCount = Attributes.Count();
	TextAttributes = "";
	For Each Attribute In Attributes Do
		TextAttributes = TextAttributes + Chars.LF + Chars.Tab + "Table." + Attribute.Name;
		TextAttributes = TextAttributes + ?(Attributes.IndexOf(Attribute) = AttributesCount - 1, "", ",");
	EndDo;
	Resources = Metadata.AccumulationRegisters[RegisterName].Resources;
	NumberOfResources = Resources.Count();
	TextResources_ = "";
	For Each Resource In Resources Do
		TextResources_ = TextResources_ + Chars.LF + Chars.Tab + "Table." + Resource.Name;
		TextResources_ = TextResources_ + ?(Resources.IndexOf(Resource) = NumberOfResources - 1, "", ",");
	EndDo;
	
	QueryText = StrReplace(QueryText, "&MeasurementText_1", MeasurementText_1);
	QueryText = StrReplace(QueryText, "&TextAttributes", TextAttributes);
	QueryText = StrReplace(QueryText, "&TextResources_", TextResources_);
	QueryText = StrReplace(QueryText, "&RegisterName", "AccumulationRegister." + RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextOnWrite(RegisterName)

	QueryText = 
	"SELECT
	|	Table.Period,
	|	Table.Recorder,
	|	&MeasurementText_1,
	|	&TextAttributes,
	|	&TextResources_
	|FROM 
	|	(
	|	SELECT
	|		Table.Period,
	|		Table.Recorder,
	|		&MeasurementText_1,
	|		&TextAttributes,
	|		&SourceTableTextResources
	|	FROM
	|		SourceTable AS Table
	|
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period,
	|		Table.Recorder,
	|		&MeasurementText_1,
	|		&TextAttributes,
	|		&TextResourcesOfNewTable
	|	FROM
	|		&RegisterName AS Table
	|	WHERE
	|		Table.Recorder = &Recorder
	|	) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	&MeasurementText_1,
	|	&TextAttributes
	|HAVING
	|	&TextHaving
	|";
	
	Dimensions = Metadata.AccumulationRegisters[RegisterName].Dimensions;
	NumberOfMeasurements = Dimensions.Count();
	MeasurementText_1 = "";
	For Each Dimension In Dimensions Do
		MeasurementText_1 = MeasurementText_1 + Chars.LF + Chars.Tab + Chars.Tab + "Table." + Dimension.Name;
		MeasurementText_1 = MeasurementText_1 + ?(Dimensions.IndexOf(Dimension) = NumberOfMeasurements - 1, "", ",");
	EndDo;
	Attributes = Metadata.AccumulationRegisters[RegisterName].Attributes;
	AttributesCount = Attributes.Count();
	TextAttributes = "";
	For Each Attribute In Attributes Do
		TextAttributes = TextAttributes + Chars.LF + Chars.Tab + Chars.Tab + "Table." + Attribute.Name;
		TextAttributes = TextAttributes + ?(Attributes.IndexOf(Attribute) = AttributesCount - 1, "", ",");
	EndDo;
	Resources = Metadata.AccumulationRegisters[RegisterName].Resources;
	NumberOfResources = Resources.Count();
	TextResources_ = "";
	SourceTableTextResources = "";
	TextResourcesOfNewTable = "";
	TextHaving = "";
	For Each Resource In Resources Do
		TextResources_ = TextResources_ + Chars.LF + Chars.Tab + "SUM(Table." + Resource.Name + ")";
		TextResources_ = TextResources_ + ?(Resources.IndexOf(Resource) = NumberOfResources - 1, "", ",");
		SourceTableTextResources = SourceTableTextResources + Chars.LF + Chars.Tab + Chars.Tab + "Table." + Resource.Name;
		SourceTableTextResources = SourceTableTextResources + ?(Resources.IndexOf(Resource) = NumberOfResources - 1, "", ",");
		TextResourcesOfNewTable = TextResourcesOfNewTable + Chars.LF + Chars.Tab + Chars.Tab + "-Table." + Resource.Name;
		TextResourcesOfNewTable = TextResourcesOfNewTable + ?(Resources.IndexOf(Resource) = NumberOfResources - 1, "", ",");
		TextHaving = TextHaving + Chars.LF + Chars.Tab + ?(TextHaving = "", "SUM(Table." + Resource.Name + ") <> 0",
			"OR SUM(Table." + Resource.Name + ") <> 0");
	EndDo;
	
	QueryText = StrReplace(QueryText, "&MeasurementText_1", MeasurementText_1);
	QueryText = StrReplace(QueryText, "&TextAttributes", TextAttributes);
	QueryText = StrReplace(QueryText, "&SourceTableTextResources", SourceTableTextResources);
	QueryText = StrReplace(QueryText, "&TextResourcesOfNewTable", TextResourcesOfNewTable);
	QueryText = StrReplace(QueryText, "&TextResources_", TextResources_);
	QueryText = StrReplace(QueryText, "&TextHaving", TextHaving);
	QueryText = StrReplace(QueryText, "&RegisterName", "AccumulationRegister." + RegisterName);

	Return QueryText;
	
EndFunction

// The procedure returns the original set of records if there are no changes in the current (written) set.
// The goal is to keep the pending motion for a re-reposting of the document.
//
Procedure RestoreDeferredTransaction(Source)
	
	If Source.AdditionalProperties.Property("DeferredPosting") Or Source.DataExchange.Load Then
		Return;
	EndIf;
	
	Query = New Query(ComparisonRequestText());
	Query.TempTablesManager = Source.AdditionalProperties.ManagerTTManAccounting;
	Query.SetParameter("NewRegisteredRecords_", Source.Unload());
	
	// The query will return the original set table if there are no changes in the new set relative to the previous one.
	Original = Query.Execute().Unload();
	If Original.Count() > 0 Then
		Source.Load(Original);
	EndIf;
	
EndProcedure

Function ComparisonRequestText()
	
	// If there are no changes, return the original table
	Return
	"SELECT
	|	Table.Period,
	|	Table.BusinessOperation,
	|	Table.Organization,
	|	Table.Department,
	|	Table.LineOfBusiness,
	|	Table.Partner,
	|	Table.Counterparty,
	|	Table.Contract,
	|	Table.ARAPObject,
	|	Table.CorLineOfBusiness,
	|	Table.CorPartner,
	|	Table.CorCounterparty,
	|	Table.CorContract,
	|	Table.CorARAPObject,
	|	Table.Currency,
	|	Table.AmountInCurrency
	|INTO TTNewRegisteredRecords
	|FROM
	|	&NewRegisteredRecords_ AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Period,
	|	Table.BusinessOperation,
	|	Table.Organization,
	|	Table.Department,
	|	Table.LineOfBusiness,
	|	Table.Partner,
	|	Table.Counterparty,
	|	Table.Contract,
	|	Table.ARAPObject,
	|	Table.CorLineOfBusiness,
	|	Table.CorPartner,
	|	Table.CorCounterparty,
	|	Table.CorContract,
	|	Table.CorARAPObject,
	|	Table.Currency,
	|	SUM(Table.AmountInCurrency) AS AmountInCurrency
	|INTO ttChanges
	|FROM
	|	(SELECT
	|		SourceTable.Period AS Period,
	|		SourceTable.BusinessOperation AS BusinessOperation,
	|		SourceTable.Organization AS Organization,
	|		SourceTable.Department AS Department,
	|		SourceTable.LineOfBusiness AS LineOfBusiness,
	|		SourceTable.Partner AS Partner,
	|		SourceTable.Counterparty AS Counterparty,
	|		SourceTable.Contract AS Contract,
	|		SourceTable.ARAPObject AS ARAPObject,
	|		SourceTable.CorLineOfBusiness AS CorLineOfBusiness,
	|		SourceTable.CorPartner AS CorPartner,
	|		SourceTable.CorCounterparty AS CorCounterparty,
	|		SourceTable.CorContract AS CorContract,
	|		SourceTable.CorARAPObject AS CorARAPObject,
	|		SourceTable.Currency AS Currency,
	|		SourceTable.AmountInCurrency AS AmountInCurrency
	|	FROM
	|		SourceTable AS SourceTable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NewRegisteredRecords_.Period,
	|		NewRegisteredRecords_.BusinessOperation,
	|		NewRegisteredRecords_.Organization,
	|		NewRegisteredRecords_.Department,
	|		NewRegisteredRecords_.LineOfBusiness AS LineOfBusiness,
	|		CASE WHEN VALUETYPE(NewRegisteredRecords_.Counterparty) = TYPE(Catalog.Companies)
	|			THEN VALUE(Catalog.Partners.OurEnterprise)
	|			ELSE NewRegisteredRecords_.Partner
	|		END,
	|		NewRegisteredRecords_.Counterparty,
	|		NewRegisteredRecords_.Contract,
	|		NewRegisteredRecords_.ARAPObject,
	|		NewRegisteredRecords_.CorLineOfBusiness AS CorLineOfBusiness,
	|		CASE WHEN VALUETYPE(NewRegisteredRecords_.CorCounterparty) = TYPE(Catalog.Companies)
	|			THEN VALUE(Catalog.Partners.OurEnterprise)
	|			ELSE NewRegisteredRecords_.CorPartner
	|		END,
	|		NewRegisteredRecords_.CorCounterparty,
	|		NewRegisteredRecords_.CorContract,
	|		NewRegisteredRecords_.CorARAPObject,
	|		NewRegisteredRecords_.Currency,
	|		-NewRegisteredRecords_.AmountInCurrency
	|	FROM
	|		TTNewRegisteredRecords AS NewRegisteredRecords_) AS Table
	|
	|GROUP BY
	|	Table.Period,
	|	Table.BusinessOperation,
	|	Table.Organization,
	|	Table.LineOfBusiness,
	|	Table.Department,
	|	Table.Partner,
	|	Table.Counterparty,
	|	Table.Contract,
	|	Table.ARAPObject,
	|	Table.CorLineOfBusiness,
	|	Table.CorPartner,
	|	Table.CorCounterparty,
	|	Table.CorContract,
	|	Table.CorARAPObject,
	|	Table.Currency
	|
	|HAVING
	|	SUM(Table.AmountInCurrency) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Period,
	|	Table.Recorder,
	|	
	|	Table.BusinessOperation,
	|	Table.Organization,
	|	Table.Department,
	|	Table.LineOfBusiness,
	|	Table.Partner,
	|	Table.Counterparty,
	|	Table.Contract,
	|	Table.ARAPObject,
	|	Table.CorLineOfBusiness,
	|	Table.CorPartner,
	|	Table.CorCounterparty,
	|	Table.CorContract,
	|	Table.CorARAPObject,
	|	Table.AmountType,
	|	Table.CorAmountType,
	|	
	|	Table.Currency,
	|	Table.AmountInCurrency,
	|	Table.AmountExcludingVATInCurrency,
	|	Table.ARAPCurrency,
	|	Table.AmountInARAPCurrency,
	|	Table.AmountExcludingVATInARAPCurrency,
	|	Table.CorCurrencyOfARAPAccounting,
	|	Table.AdjAmountInARAPCurrency,
	|	Table.AdjAmountExcludingVATInARAPCurrency,
	|	Table.SourceOfARAPFinancialAccountingGroup,
	|	Table.CorSourceOfARAPFinancialAccountingGroup,
	|	
	|	Table.Sum,
	|	Table.AmountExcludingVAT,
	|	Table.SumCompl,
	|	Table.LocalAmountExcludingVAT
	|FROM
	|	SourceTable AS Table
	|WHERE
	|	NOT (TRUE IN (SELECT TOP 1 TRUE FROM ttChanges))";
	
EndFunction

Function DoNotControlCaseChanges(Source)
	
	Return
		Source.AdditionalProperties.Property("RegisterDataChanged")
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(Source);
	
EndFunction

Procedure ToFormRegisterRecordsForOtherAssetsLiabilities(SelectionByDocuments) Export
	
	MetaAccumulationRegister = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords;
	SelectionByDocuments.Reset();
	
	While SelectionByDocuments.Next() Do
		MetaDocument = SelectionByDocuments.Recorder.Metadata();
		If Not MetaDocument.RegisterRecords.Contains(MetaAccumulationRegister) Then
			Continue;
		EndIf;
		
		RecordSet = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.CreateRecordSet();
		RecordSet.AdditionalProperties.Insert("DeferredPosting");
		RecordSet.Filter.Recorder.Set(SelectionByDocuments.Recorder);
		RecordSet.Read();
		
		MatchingOperationsToIdentifiers = New Map();
		RecordsCount = RecordSet.Count();
		
		For RecNo = 1 To RecordsCount Do
			ReverseIndex = RecordsCount - RecNo;
			CurrentRecord = RecordSet[ReverseIndex];
			If CurrentRecord.AssetRef = ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting Then
				MatchingOperationsToIdentifiers.Insert(CurrentRecord.FinRecordID, CurrentRecord.BusinessTransactionSetting);
				RecordSet.Delete(CurrentRecord);
			EndIf;
		EndDo;
		
		Selection = SelectionByDocuments.Select();
		While Selection.Next() Do
			If Selection.Organization <> Selection.CorCounterparty
			   And Selection.CompanyParentCompany = Selection.CorCounterpartyParentCompany Then
				NewRecord = RecordSet.Add();
				NewRecord.Period = Selection.Period;
				NewRecord.Organization = Selection.Organization;
				NewRecord.Department = Selection.CorObjectOfCalculationsDivision;
				NewRecord.LineOfBusiness = Selection.CorLineOfBusiness;
				NewRecord.AssetRef = ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting;
				NewRecord.Dimension = Selection.CorCounterparty;
				NewRecord.DebitCredit = Enums.RecordKindsOfOtherAssetsAndLiabilities.Debit;
				NewRecord.SumCompl = Selection.SumCompl;
				NewRecord.SumMan = Selection.Sum;
				NewRecord.AmountIncludingVAT = Selection.Sum;
				NewRecord.AmountExcludingVAT = Selection.AmountExcludingVAT;
				NewRecord.FinRecordID = Selection.ARAPObjectIsUniqueIdentifier;
				If MatchingOperationsToIdentifiers[NewRecord.FinRecordID] <> Undefined Then
					NewRecord.BusinessTransactionSetting = MatchingOperationsToIdentifiers[NewRecord.FinRecordID];
				ElsIf Selection.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
					Or Selection.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
					Or Selection.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
					Or Selection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
					Or Selection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
					NewRecord.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.PaymentTransferBetweenBranchOffices;
				ElsIf Selection.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
					Or Selection.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
					NewRecord.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.SettlementOfPrepayment;
				Else
					NewRecord.BusinessTransactionSetting = Selection.BusinessTransactionSetting;
				EndIf;
			EndIf;
			
			If Selection.Organization <> Selection.Counterparty
			   And Selection.CompanyParentCompany = Selection.CounterpartyParentCompany Then
				NewRecord = RecordSet.Add();
				NewRecord.Period = Selection.Period;
				NewRecord.Organization = Selection.Organization;
				NewRecord.Department = Selection.ObjectOfCalculationsDivision;
				NewRecord.LineOfBusiness = Selection.LineOfBusiness;
				NewRecord.AssetRef = ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting;
				NewRecord.Dimension = Selection.Counterparty;
				NewRecord.DebitCredit = Enums.RecordKindsOfOtherAssetsAndLiabilities.Credit;
				NewRecord.SumCompl = Selection.SumCompl;
				NewRecord.SumMan = Selection.Sum;
				NewRecord.AmountIncludingVAT = Selection.Sum;
				NewRecord.AmountExcludingVAT = Selection.AmountExcludingVAT;
				NewRecord.FinRecordID = Selection.CorARAPObjectUniqueIdentifier;
				If MatchingOperationsToIdentifiers[NewRecord.FinRecordID] <> Undefined Then
					NewRecord.BusinessTransactionSetting = MatchingOperationsToIdentifiers[NewRecord.FinRecordID];
				ElsIf Selection.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
					Or Selection.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
					Or Selection.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
					Or Selection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
					Or Selection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
					NewRecord.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.PaymentTransferBetweenBranchOffices;
				ElsIf Selection.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
					Or Selection.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
					NewRecord.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.SettlementOfPrepayment;
				Else
					NewRecord.BusinessTransactionSetting = Selection.BusinessTransactionSetting;
				EndIf;
			EndIf;
			
			If Selection.CompanyParentCompany <> Selection.CounterpartyParentCompany
			   And Selection.CompanyParentCompany <> Selection.CorCounterpartyParentCompany Then
				If Selection.Organization = Selection.CorCounterpartyParentCompany
				 Or Selection.CompanyParentCompany = Selection.CorCounterparty Then
					NewRecord = RecordSet.Add();
					NewRecord.Period = Selection.Period;
					NewRecord.Organization = Selection.Organization;
					NewRecord.Department = Selection.CorObjectOfCalculationsDivision;
					NewRecord.LineOfBusiness = Selection.CorLineOfBusiness;
					NewRecord.AssetRef = ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting;
					NewRecord.Dimension = Selection.CorCounterparty;
					NewRecord.DebitCredit = Enums.RecordKindsOfOtherAssetsAndLiabilities.Debit;
					NewRecord.SumCompl = Selection.SumCompl;
					NewRecord.SumMan = Selection.Sum;
					NewRecord.AmountIncludingVAT = Selection.Sum;
					NewRecord.AmountExcludingVAT = Selection.AmountExcludingVAT;
					NewRecord.FinRecordID = Selection.ARAPObjectIsUniqueIdentifier;
					If MatchingOperationsToIdentifiers[NewRecord.FinRecordID] <> Undefined Then
						NewRecord.BusinessTransactionSetting = MatchingOperationsToIdentifiers[NewRecord.FinRecordID];
					Else
						NewRecord.BusinessTransactionSetting = Selection.BusinessTransactionSetting;
					EndIf;
				EndIf;
				
				If Selection.Organization = Selection.CounterpartyParentCompany
				 Or Selection.CompanyParentCompany = Selection.Counterparty Then
					NewRecord = RecordSet.Add();
					NewRecord.Period = Selection.Period;
					NewRecord.Organization = Selection.Organization;
					NewRecord.Department = Selection.ObjectOfCalculationsDivision;
					NewRecord.LineOfBusiness = Selection.LineOfBusiness;
					NewRecord.AssetRef = ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting;
					NewRecord.Dimension = Selection.Counterparty;
					NewRecord.DebitCredit = Enums.RecordKindsOfOtherAssetsAndLiabilities.Credit;
					NewRecord.SumCompl = Selection.SumCompl;
					NewRecord.SumMan = Selection.Sum;
					NewRecord.AmountIncludingVAT = Selection.Sum;
					NewRecord.AmountExcludingVAT = Selection.AmountExcludingVAT;
					NewRecord.FinRecordID = Selection.CorARAPObjectUniqueIdentifier;
					If MatchingOperationsToIdentifiers[NewRecord.FinRecordID] <> Undefined Then
						NewRecord.BusinessTransactionSetting = MatchingOperationsToIdentifiers[NewRecord.FinRecordID];
					Else
						NewRecord.BusinessTransactionSetting = Selection.BusinessTransactionSetting;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
		If RecordSet.Modified() Then
			RecordSet.Write();
		EndIf;
	EndDo;
	
EndProcedure

#Region InfobaseUpdate

// Service procedure used in update handlers.
// Adds selection for business operations to the query text.
//
Procedure AddEnabledBusinessTransactions(QueryTextByDocument, IncludedBusinessTransactions) Export

	If IncludedBusinessTransactions.Count() > 0 Then
		BsnsTransactions = "";
		For Each BusinessTransaction In IncludedBusinessTransactions Do
			BsnsTransactions = BsnsTransactions + ?(Not IsBlankString(BsnsTransactions), ", ", "") + "VALUE(Enum.BusinessTransactions." + BusinessTransaction + ")";
		EndDo;
		QueryTextByDocument = StrReplace(QueryTextByDocument, "%IncludedBusinessTransactions%",
			"DocumentData.BusinessOperation IN (" + BsnsTransactions + ")");
	Else
		QueryTextByDocument = StrReplace(QueryTextByDocument, "%IncludedBusinessTransactions%", "TRUE");
	EndIf;

EndProcedure

// Write deferred update parameters to a constant for passing the next batch of data to processing.
//
// Parameters:
//	UpdateHandlersParameters - Structure - parameters of the update handler.
//
Procedure RecordInformationAboutDelayedUpdate(UpdateHandlersParameters) Export

	ManagerOfConstant = Constants.UpdateHandlersParameters.CreateValueManager();
	ManagerOfConstant.Value = New ValueStorage(UpdateHandlersParameters);
	InfobaseUpdate.WriteData(ManagerOfConstant);

EndProcedure

// Writes a set if the number of entries in the set is greater than 10,000.
//
// Parameters:
//	RecordSet - AccountingRegisterRecordSet - Recordable set of records of the accumulation register, information, accounting
//	RecordsCount - Number - Number of entries in the set
//	RecordIfThereAreRecords - Boolean - Forced recording of a non-empty set.
//
Procedure WriteRecordSet(RecordSet, RecordsCount, RecordIfThereAreRecords = False) Export

	If RecordsCount = 0 Then
		Return;
	EndIf;
	
	If RecordsCount > 10000 Or RecordIfThereAreRecords  Then
		
		RecordsCount = 0;
		
		RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism"); 
		RecordSet.DataExchange.Recipients.AutoFill = False;
		RecordSet.Write(False);
		
	EndIf;

EndProcedure

// Loads a collection of movements into a set of records and records a set with a sign of deception.Download = True.
//
// Parameters:
//  Recorder - DocumentRef - Registrar of a recordable set of records of the accumulation register, information, accounting
//  RegisterName - String - Name of the register of accumulation, information, accounting
//  RegisterRecordsCollection - QueryResultSelection,ValueTable,Array - the collection contains records of the register
//  AdditionalParameters - Structure - additional parameters and flags specifying the loading of movements
//    may contain the following keys:
//    Registers - Collection of Accumulation register,Collection of Inventory Register,Collection of Inventory Register - Collection
//        of registers by default <Accumulation register>
//    Non-recordable set - Boolean - by default, empty sets are not recorded
//    Registering Exchange Plan nodes - Boolean - enables registration at exchange plan nodes when writing an object by
//                                                 default, changes are not registered at exchange nodes.
//
Procedure ImportRegisterRecords(Recorder, RegisterName, RegisterRecordsCollection = Undefined, AdditionalParameters = Undefined) Export
	
	// Let's define the values of additional parameters
	Registers = AccumulationRegisters;
	NotWriteEmptySet = False;
	RegisterOnExchangePlanNodes = False;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		If AdditionalParameters.Property("Registers") Then
			Registers = AdditionalParameters.Registers;
		EndIf;
		If AdditionalParameters.Property("NotWriteEmptySet") Then
			NotWriteEmptySet = AdditionalParameters.NotWriteEmptySet;
		EndIf;
		If AdditionalParameters.Property("RegisterOnExchangePlanNodes") Then
			RegisterOnExchangePlanNodes = AdditionalParameters.Property("RegisterOnExchangePlanNodes");
		EndIf;
	EndIf;
	
	If NotWriteEmptySet And RegisterRecordsCollection.Count() = 0 Then
		Return;
	EndIf;
	
	Set = Registers[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet - 
	Set.Filter.Recorder.Set(Recorder);
	If RegisterRecordsCollection <> Undefined Then
		If TypeOf(RegisterRecordsCollection) = Type("ValueTable") Then
			Set.Load(RegisterRecordsCollection);
			
		ElsIf TypeOf(RegisterRecordsCollection) = Type("QueryResultSelection") Then
			While RegisterRecordsCollection.Next() Do
				FillPropertyValues(Set.Add(), RegisterRecordsCollection);
			EndDo;
			
		Else
			For Each Movement In RegisterRecordsCollection Do
				FillPropertyValues(Set.Add(), Movement);
			EndDo;
		EndIf;
	EndIf;// The collection of movements is defined
	InfobaseUpdate.WriteData(Set, RegisterOnExchangePlanNodes);
	
EndProcedure

#EndRegion

#EndRegion
