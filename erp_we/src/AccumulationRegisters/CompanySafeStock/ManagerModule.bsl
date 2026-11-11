#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Start the convolution of movements in the "reserves of goods of organizations" register for all organizations.
//
Procedure CollapseRegisterReservesOfGoodsOfOrganizations() Export
	
	If ThereAreExtraReserves(False) <> "NoExtraReserves" Then
		AllocateReservesByPeriod();
	EndIf;
	
	OffsetCounterProvisions();
	
	If Not ThereAreRecordsOfStorno() Then
		Return;
	EndIf;
	
	ToFormReservesToCoverExcessStorno();
	CollapseRegisteredRecordsInOrganizationsProductReserves();
	
EndProcedure

// Returns the name of an additional property that indicates that the record is being written by the convolution engine.
//
// Returns:
//	String - the name of the additional property.
//
Function FlagForWhetherSetIsRecordedDuringConvolution() Export
	
	Return "ConvolutionOfRegisteredRecordsOfReservesOfGoodsOfOrganizationsIsPerformed";
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region ConvolutionOfRegisteredRecords

Procedure OffsetCounterProvisions()
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = InventoriesServer.TextOfCounterReserveRequest("TTCounterReserveAnalysts");
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Result = Query.ExecuteBatchWithIntermediateData();
	
	If Result[0].IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		
		LockItem = Block.Add("AccumulationRegister.CompanySafeStock");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = Result[0];
		LockItem.UseFromDataSource("ItemsLocationAttributes", "ItemsLocationAttributes");
		LockItem.UseFromDataSource("InventoryOwnerAttribute", "InventoryOwnerAttribute");
		LockItem.UseFromDataSource("Organization", "Organization");
		LockItem.UseFromDataSource("CCDNumber", "CCDNumber");
		
		Block.Lock();
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		
		Query.Text = InventoriesServer.TextOfCounterReserveRequest("SelectionOrderedByOrganization", "TTCounterReserveAnalysts");
		
		AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
		
		TableOfCounterReserves = Query.Execute().Unload();
		
		If TableOfCounterReserves.Count() = 0 Then
			CommitTransaction();
			Return;
		EndIf;
		
		CompanyTable = TableOfCounterReserves.Copy(, "Organization");
		CompanyTable.GroupBy("Organization");
		
		RegisterRecordTable = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
		
		TheStructureOfTheSearch = New Structure("Organization");
		
		For Each OrganizationLine In CompanyTable Do
			
			TheStructureOfTheSearch.Organization = OrganizationLine.Organization;
			
			SearchForStrings = TableOfCounterReserves.FindRows(TheStructureOfTheSearch);
			For Each FoundRow In SearchForStrings Do
				
				ExpenseLine = RegisterRecordTable.Add();
				ExpenseLine.RecordType = AccumulationRecordType.Expense;
				FillPropertyValues(ExpenseLine, FoundRow);
				
				AddCorRecordToReserveSet(RegisterRecordTable, ExpenseLine);
				
				ArrivalLine = RegisterRecordTable.Add();
				ArrivalLine.RecordType = AccumulationRecordType.Receipt;
				FillPropertyValues(ArrivalLine, FoundRow);
				
				AddCorRecordToReserveSet(RegisterRecordTable, ArrivalLine);
				
			EndDo;
			
			If RegisterRecordTable.Count() > 0 Then
				
				RegisterAdjustment = Documents.RegisterAdjustment.CreateDocument();
				RegisterAdjustment.Date = CurrentSessionDate();
				RegisterAdjustment.Comment = NStr("vi = 'Tự động tạo khi đối trừ dự phòng hàng hóa của các doanh nghiệp.';
													|ru = 'Создан автоматически при зачете встречных резервов товаров организаций.';
													|en = 'Created automatically while setting off counter reserves of company goods.'; fa = 'Created automatically while setting off counter reserves of company goods.';
													|it = 'Generato automaticamente in sede di compensazione di riserve reciproche di merci delle aziende.';
													|pl = 'Utworzono automatycznie podczas zaliczania wzajemnych rezerw towarów firmy.';
													|tr = 'İş yeri ürünlerinin karşılık yedekleri mahsup edilirken otomatik olarak oluşturulur.'", Common.DefaultLanguageCode());
				
				NewRow = RegisterAdjustment.RegistersTable.Add();
				NewRow.Name = "CompanySafeStock";
				
				RegisterAdjustment.Write();
				
				Set = AccumulationRegisters.CompanySafeStock.CreateRecordSet();
				Set.Filter.Recorder.Set(RegisterAdjustment.Ref);
				Set.Load(RegisterRecordTable);
				Set.AdditionalProperties.Insert("NotReflectedInBudgeting", True);
				StructureOfTemporaryTables = New Structure("TempTablesManager", New TempTablesManager);
				Set.AdditionalProperties.Insert("ForConducting", New Structure("StructureOfTemporaryTables", StructureOfTemporaryTables));
				Set.Write = True;
				Set.Write();
				
				RegisterRecordTable.Clear();
				
			EndIf;
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra lỗi khi đối trừ dự phòng: %1';
				|ru = 'Возникла ошибка зачете встречных резервов: %1';
				|en = 'An error occurred when offsetting counter reserves: %1'; fa = 'An error occurred when offsetting counter reserves: %1';
				|it = 'Возникла ошибка зачете встречных резервов: %1';
				|pl = 'An error occurred when offsetting counter reserves: %1';
				|tr = 'Karşılık rezervlerinin mahsup edilmesinde hata oluştu: %1'"),
			DetailErrorDescription(ErrorInfo())
		);
		
		WriteLogEvent(NStr("vi = 'Đối trừ dự phòng hàng hóa của các doanh nghiệp';
							|ru = 'Зачет встречных резервов товаров организаций';
							|en = 'Set off counter reserves of company goods'; fa = 'Set off counter reserves of company goods';
							|it = 'Compensazione di riserve reciproche di merci delle aziende';
							|pl = 'Zaliczanie wzajemnych rezerw towarów firmy';
							|tr = 'İş yeri ürünlerinin karşılık yedeklerinin mahsup edilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.AccumulationRegisters.CompanySafeStock,,
			ErrorText
		);
			
	EndTry;
	
EndProcedure

Procedure CollapseRegisteredRecordsInOrganizationsProductReserves()
	
	LoggersWithConvolutionErrors = New Array;
	
	RequestingCurLogger = New Query;
	RequestingCurLogger.Text =
	"SELECT TOP 1
	|	CompanySafeStock.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.ThisIsReverseTransaction
	|	AND NOT CompanySafeStock.Recorder IN (&LoggersWithConvolutionErrors)";
	
	ThereAreRegistrarsStorno = True;
	Counter = 0;
	
	While ThereAreRegistrarsStorno Do
		
		Counter = Counter + 1;
		
		RequestingCurLogger.SetParameter("LoggersWithConvolutionErrors", LoggersWithConvolutionErrors);
		LoggerSelection = RequestingCurLogger.Execute().Select();
		
		If Not LoggerSelection.Next() Then
			ThereAreRegistrarsStorno = False;
			
			For Each ArrRow In LoggersWithConvolutionErrors Do
				CollapseRegisteredRecordsOnReservesOfGoodsOfOrganizationsOnCurRegistrarStorno(ArrRow);
			EndDo;
			
			If ThereAreRecordsOfStorno() Then
				ExceptionText = NStr("vi = 'Không thể đối trừ tất cả bản ghi đảo ngược dự phòng hàng hóa trong doanh nghiệp. Chi tiết xem Nhật ký sự kiện';
									|ru = 'Не удалось зачесть все сторно записи резервов товаров организаций. Подробнее - см. Журанал регистрации';
									|en = 'Cannot set off all storno entries of company goods reserves. For more information, see the event log'; fa = 'Cannot set off all storno entries of company goods reserves. For more information, see the event log';
									|it = 'Non siamo riusciti a procedere alla compensazione dello storno delle riserve di merci delle aziende. Per maggiori dettagli v. Log di registrazione';
									|pl = 'Nie udało się zaliczyć wszystkie storno-wpisy rezerw towarów firm. Więcej - patrz Dziennik rejestracji';
									|tr = 'İş yeri yedeklerinin tüm ters kayıtları mahsup edilmedi. Daha fazla ayrıntı için bakın. Kayıt defteri'");
				RecordConvolutionErrorOfVZHR(ExceptionText);
				Raise ExceptionText;
			EndIf;
			
		ElsIf Not CollapseRegisteredRecordsOnReservesOfGoodsOfOrganizationsOnCurRegistrarStorno(LoggerSelection.Recorder)
			And LoggersWithConvolutionErrors.Find(LoggerSelection.Recorder) = Undefined Then
			
			LoggersWithConvolutionErrors.Add(LoggerSelection.Recorder);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function CollapseRegisteredRecordsOnReservesOfGoodsOfOrganizationsOnCurRegistrarStorno(CurRegistrarStorno)
		
	RequestToSetLock = New Query;
	RequestToSetLock.Text =
	"SELECT
	|	CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanySafeStock.Organization AS Organization,
	|	CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber AS CCDNumber,
	|	CompanySafeStock.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	CompanySafeStock.CorCompany AS CorCompany,
	|	ENDOFPERIOD(CompanySafeStock.Period, MONTH) AS Period
	|INTO TTStornoRecords
	|FROM
	|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.Recorder = &CurRegistrarStorno
	|	AND CompanySafeStock.ThisIsReverseTransaction
	|	AND CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ReserveRegistrars.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CompanySafeStock AS ReserveRegistrars
	|		INNER JOIN TTStornoRecords AS TTStornoRecords
	|		ON ReserveRegistrars.ItemsLocationAttributes = TTStornoRecords.ItemsLocationAttributes
	|			AND ReserveRegistrars.Organization = TTStornoRecords.Organization
	|			AND ReserveRegistrars.InventoryOwnerAttribute = TTStornoRecords.InventoryOwnerAttribute
	|			AND ReserveRegistrars.CCDNumber = TTStornoRecords.CCDNumber
	|			AND ReserveRegistrars.CorInventoryOwnerAttribute = TTStornoRecords.CorInventoryOwnerAttribute
	|			AND ReserveRegistrars.CorCompany = TTStornoRecords.CorCompany
	|			AND (ENDOFPERIOD(ReserveRegistrars.Period, MONTH) = TTStornoRecords.Period)
	|			AND (ReserveRegistrars.RecordType = VALUE(AccumulationRecordType.Receipt))
	|			AND (NOT ReserveRegistrars.ThisIsReverseTransaction)
	|			AND (ReserveRegistrars.Recorder <> &CurRegistrarStorno)";
	
	RequestToSetLock.SetParameter("CurRegistrarStorno", CurRegistrarStorno);
	ReserveRegistrars = RequestToSetLock.Execute().Unload();
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		
		LockItem = Block.Add("AccumulationRegister.CompanySafeStock.RecordSet");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = ReserveRegistrars;
		LockItem.UseFromDataSource("Recorder", "Recorder");
		
		LockItem = Block.Add("AccumulationRegister.CompanySafeStock.RecordSet");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Recorder",CurRegistrarStorno);
		
		Block.Lock();
		
		RequestForCreditReverse = New Query;
		RequestForCreditReverse.Text =
		"SELECT
		|	ENDOFPERIOD(RegistrarRegisteredRecordsAreReversed.Period, MONTH) AS Period,
		|	RegistrarRegisteredRecordsAreReversed.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	RegistrarRegisteredRecordsAreReversed.Organization AS Organization,
		|	RegistrarRegisteredRecordsAreReversed.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	RegistrarRegisteredRecordsAreReversed.CCDNumber AS CCDNumber,
		|	RegistrarRegisteredRecordsAreReversed.ThisIsReverseTransaction AS ThisIsReverseTransaction,
		|	SUM(RegistrarRegisteredRecordsAreReversed.Count) AS Count,
		|	SUM(CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(RegistrarRegisteredRecordsAreReversed.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE CAST(RegistrarRegisteredRecordsAreReversed.QuantityByGBRN AS NUMBER(23, 11))
		|		END) AS QuantityByGBRN,
		|	RegistrarRegisteredRecordsAreReversed.CorCompany AS CorCompany,
		|	RegistrarRegisteredRecordsAreReversed.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
		|FROM
		|	AccumulationRegister.CompanySafeStock AS RegistrarRegisteredRecordsAreReversed
		|WHERE
		|	RegistrarRegisteredRecordsAreReversed.Recorder = &CurRegistrarStorno
		|	AND RegistrarRegisteredRecordsAreReversed.RecordType = VALUE(AccumulationRecordType.Receipt)
		|
		|GROUP BY
		|	ENDOFPERIOD(RegistrarRegisteredRecordsAreReversed.Period, MONTH),
		|	RegistrarRegisteredRecordsAreReversed.ItemsLocationAttributes,
		|	RegistrarRegisteredRecordsAreReversed.Organization,
		|	RegistrarRegisteredRecordsAreReversed.InventoryOwnerAttribute,
		|	RegistrarRegisteredRecordsAreReversed.CCDNumber,
		|	RegistrarRegisteredRecordsAreReversed.ThisIsReverseTransaction,
		|	RegistrarRegisteredRecordsAreReversed.CorCompany,
		|	RegistrarRegisteredRecordsAreReversed.CorInventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ENDOFPERIOD(RegisteredRecordsOfReserveRegistrars.Period, MONTH) AS Period,
		|	RegisteredRecordsOfReserveRegistrars.Recorder AS Recorder,
		|	RegisteredRecordsOfReserveRegistrars.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	RegisteredRecordsOfReserveRegistrars.Organization AS Organization,
		|	RegisteredRecordsOfReserveRegistrars.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	RegisteredRecordsOfReserveRegistrars.CCDNumber AS CCDNumber,
		|	RegisteredRecordsOfReserveRegistrars.ThisIsReverseTransaction AS ThisIsReverseTransaction,
		|	SUM(RegisteredRecordsOfReserveRegistrars.Count) AS Count,
		|	SUM(CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(RegisteredRecordsOfReserveRegistrars.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE CAST(RegisteredRecordsOfReserveRegistrars.QuantityByGBRN AS NUMBER(23, 11))
		|		END) AS QuantityByGBRN,
		|	RegisteredRecordsOfReserveRegistrars.CorCompany AS CorCompany,
		|	RegisteredRecordsOfReserveRegistrars.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
		|FROM
		|	AccumulationRegister.CompanySafeStock AS RegisteredRecordsOfReserveRegistrars
		|WHERE
		|	RegisteredRecordsOfReserveRegistrars.Recorder IN(&BlockedReserveRegistrars)
		|	AND RegisteredRecordsOfReserveRegistrars.RecordType = VALUE(AccumulationRecordType.Receipt)
		|
		|GROUP BY
		|	ENDOFPERIOD(RegisteredRecordsOfReserveRegistrars.Period, MONTH),
		|	RegisteredRecordsOfReserveRegistrars.Recorder,
		|	RegisteredRecordsOfReserveRegistrars.ItemsLocationAttributes,
		|	RegisteredRecordsOfReserveRegistrars.Organization,
		|	RegisteredRecordsOfReserveRegistrars.InventoryOwnerAttribute,
		|	RegisteredRecordsOfReserveRegistrars.CCDNumber,
		|	RegisteredRecordsOfReserveRegistrars.ThisIsReverseTransaction,
		|	RegisteredRecordsOfReserveRegistrars.CorCompany,
		|	RegisteredRecordsOfReserveRegistrars.CorInventoryOwnerAttribute";
		
		RequestForCreditReverse.SetParameter("CurRegistrarStorno", CurRegistrarStorno);
		RequestForCreditReverse.SetParameter("BlockedReserveRegistrars", ReserveRegistrars.UnloadColumn("Recorder"));
		
		AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(
			RequestForCreditReverse);
		
		QueryResults = RequestForCreditReverse.ExecuteBatch();
		
		RegistrarRegisteredRecordsAreReversed		= QueryResults[0].Unload();
		RegisteredRecordsOfReserveRegistrars_	= QueryResults[1].Unload();
		
		ReserveRowSearchFields = "Period,ItemsLocationAttributes,Organization,InventoryOwnerAttribute,CCDNumber,CorCompany,CorInventoryOwnerAttribute,ThisIsReverseTransaction";
		SelectionOfReserveRowSearch = New Structure(ReserveRowSearchFields);
		
		RegisteredRecordsOfReserveRegistrars_.Indexes.Add(ReserveRowSearchFields);
		RegisteredRecordsOfReserveRegistrars_.Indexes.Add("Recorder");
		
		ModifiedReserveRegistrars = New Map;
		
		StornoLoggerSet = AccumulationRegisters.CompanySafeStock.CreateRecordSet();
		StornoLoggerSet.Filter.Recorder.Set(CurRegistrarStorno);
		StornoLoggerSet.AdditionalProperties.Insert(FlagForWhetherSetIsRecordedDuringConvolution(), True);
		StornoLoggerSet.AdditionalProperties.Insert("NotReflectedInBudgeting", True);
		StructureOfTemporaryTables = New Structure("TempTablesManager", New TempTablesManager);
		
		StornoLoggerSet.AdditionalProperties.Insert("ForConducting", 
			New Structure("StructureOfTemporaryTables",StructureOfTemporaryTables));
		
		For Each StringIsStorno In RegistrarRegisteredRecordsAreReversed Do
			
			If Not StringIsStorno.ThisIsReverseTransaction Then
				
				NewLineStorno = StornoLoggerSet.Add();
				FillPropertyValues(NewLineStorno, StringIsStorno);
				AddCorRecordToReserveSet(StornoLoggerSet, NewLineStorno);
				
				Continue;
			EndIf;
			
			FillPropertyValues(SelectionOfReserveRowSearch, StringIsStorno);
			SelectionOfReserveRowSearch.ThisIsReverseTransaction = False;
			
			ReserveLines = RegisteredRecordsOfReserveRegistrars_.FindRows(SelectionOfReserveRowSearch);
			
			If ReserveLines.Count() = 0 Then
				ExceptionText = NStr("vi = 'Đảo ngược thừa';
									|ru = 'Лишнее сторно';
									|en = 'Excessive storno'; fa = 'Excessive storno';
									|it = 'Storno in eccesso';
									|pl = 'Zbędne storno ';
									|tr = 'Ekstra ters kayıt'");
				Raise ExceptionText;
			EndIf;
			
			For Each ReserveLine In ReserveLines Do
				
				NumberOfCredits_ = Min(-StringIsStorno.Count, ReserveLine.Count);
				
				ReserveLine.QuantityByGBRN	= ReserveLine.QuantityByGBRN - NumberOfCredits_
													* ReserveLine.QuantityByGBRN / ReserveLine.Count;
				ReserveLine.Count		= ReserveLine.Count - NumberOfCredits_;
				
				StringIsStorno.QuantityByGBRN	= StringIsStorno.QuantityByGBRN + NumberOfCredits_
													* StringIsStorno.QuantityByGBRN / StringIsStorno.Count;
				StringIsStorno.Count			= StringIsStorno.Count + NumberOfCredits_;
				
				ModifiedReserveRegistrars.Insert(ReserveLine.Recorder);
				
				If StringIsStorno.Count = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			If StringIsStorno.Count <> 0 Then
				
				NewLineStorno = StornoLoggerSet.Add();
				FillPropertyValues(NewLineStorno, StringIsStorno);
				AddCorRecordToReserveSet(StornoLoggerSet, NewLineStorno);
				
			EndIf;
			
		EndDo;
		
		StornoLoggerSet.Write();
		
		For Each KeyValue In ModifiedReserveRegistrars Do
			
			SetOfReserveRegistrars = AccumulationRegisters.CompanySafeStock.CreateRecordSet();
			SetOfReserveRegistrars.Filter.Recorder.Set(KeyValue.Key);
			SetOfReserveRegistrars.AdditionalProperties.Insert(FlagForWhetherSetIsRecordedDuringConvolution(), True);
			SetOfReserveRegistrars.AdditionalProperties.Insert("NotReflectedInBudgeting", True);
			StructureOfTemporaryTables = New Structure("TempTablesManager", New TempTablesManager);
			
			SetOfReserveRegistrars.AdditionalProperties.Insert("ForConducting", 
				New Structure("StructureOfTemporaryTables",StructureOfTemporaryTables));
			
			ReserveLines = RegisteredRecordsOfReserveRegistrars_.FindRows(New Structure("Recorder", KeyValue.Key));
			
			For Each ReserveLine In ReserveLines Do
				
				If ReserveLine.Count <> 0 Then
					
					NewLineOfReserves = SetOfReserveRegistrars.Add();	
					FillPropertyValues(NewLineOfReserves, ReserveLine);
					AddCorRecordToReserveSet(SetOfReserveRegistrars, NewLineOfReserves);
					
				EndIf;
				
			EndDo;
			
			SetOfReserveRegistrars.Write();
			
		EndDo;
		
		CommitTransaction();
		Return True;
	Except
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Không thể thu gọn dự phòng hàng hóa của các doanh nghiệp theo biểu ghi đảo ngược %CurRegistrarStorno% do nguyên nhân ""%ErrorReason%"".';
							|ru = 'Не удалось свернуть резервы товаров организаций по регистратору сторно %CurRegistrarStorno% по причине ""%ErrorReason%"".';
							|en = 'Cannot roll up company goods reserves by storno recorder %CurRegistrarStorno%. Reason: %ErrorReason%.'; fa = 'Cannot roll up company goods reserves by storno recorder %CurRegistrarStorno%. Reason: %ErrorReason%.';
							|it = 'Impossibile comprimere le scorte delle merci delle organizzazioni nel registratore di storno %CurRegistrarStorno% a causa di ""%ErrorReason%"".';
							|pl = 'Nie udało się zwinąć rezerwy towarów firm według rejestratora storno %CurRegistrarStorno% z powodu ""%ErrorReason%"".';
							|tr = '""%ErrorReason%"" nedeniyle iş yeri ürün karşılıklarının ters kaydı%CurRegistrarStorno% göre yapılamadı.'");
		MessageText = StrReplace(MessageText, "%ErrorReason%", DetailErrorDescription(ErrorInfo()));
		MessageText = StrReplace(MessageText, "%CurRegistrarStorno%", CurRegistrarStorno);
		
		RecordConvolutionErrorOfVZHR(MessageText);
		
		Return False;
	EndTry;
	
EndFunction

Procedure AddCorRecordToReserveSet(RecordSet, RecordOriginal) Export
	
	CorRecord = RecordSet.Add();
	FillPropertyValues(CorRecord, RecordOriginal);
	
	If RecordOriginal.RecordType = AccumulationRecordType.Receipt Then
		CorRecord.RecordType = AccumulationRecordType.Expense;
	Else
		CorRecord.RecordType = AccumulationRecordType.Receipt;
	EndIf;
	
	CorRecord.Organization = RecordOriginal.CorCompany;
	CorRecord.InventoryOwnerAttribute  = RecordOriginal.CorInventoryOwnerAttribute;
	CorRecord.CorCompany = RecordOriginal.Organization;
	CorRecord.CorInventoryOwnerAttribute  = RecordOriginal.InventoryOwnerAttribute;
	
EndProcedure

// Outputs a convolution error message to the log.
//
Procedure RecordConvolutionErrorOfVZHR(MessageText)
	
	EventName = NStr("vi = 'Đối chiếu bản ghi kết chyển dự phòng hàng hóa trong doanh nghiệp';
					|ru = 'Свертка движений по резервам товаров организаций';
					|en = 'Roll up records by company goods reserves'; fa = 'Roll up records by company goods reserves';
					|it = 'Riduzione delle operazioni relative alle riserve di merci delle aziende';
					|pl = 'Konwolucja ruchów dla rezerw towarów firmy';
					|tr = 'İş yeri ürün yedek akışlarının işlenmesi'", Common.DefaultLanguageCode());
	WriteLogEvent(
		EventName,
		EventLogLevel.Error,,,
		MessageText
	);
	
EndProcedure

// Returns whether the IB has reverse entries in incoming movements (i.e. convolution of movements is required).
//
// Returns:
//	Boolean - a sign of the presence of the records of the reverse.
//
Function ThereAreRecordsOfStorno()
	
	Query = New Query;
	
	Query.Text =
	"SELECT TOP 1
	|	Reserves.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CompanySafeStock AS Reserves
	|WHERE 
	|	Reserves.ThisIsReverseTransaction";
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

Function ThereAreExtraReserves(CheckConstant) Export
	
	DateOfFirstReserve = InventoriesServer.DateOfFirstReserve(Undefined);
	
	If Not ValueIsFilled(DateOfFirstReserve) Then
		AddConstantPeriodsOfReservesOfGoodsOfOrganizationsAreRelevant(True);
		Return "NoExtraReserves";
	EndIf;
	
	If CheckConstant 
		And Constants.PeriodsOfCompanySafeStockAreRelevant.Get() Then
		Return "NoExtraReserves";
	EndIf;
	
	QueryText =
	"SELECT
	|	ENDOFPERIOD(ProvisionsForPeriods.Period, MONTH) AS Period,
	|	ProvisionsForPeriods.Organization AS Organization,
	|	ProvisionsForPeriods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ProvisionsForPeriods.CCDNumber AS CCDNumber,
	|	ProvisionsForPeriods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ProvisionsForPeriods.CountTurnover AS ProvisionInPeriod,
	|	ProvisionsForPeriods.CountOpeningBalance AS CountOpeningBalance
	|INTO ProvisionsForPeriods
	|FROM
	|	AccumulationRegister.CompanySafeStock.BalanceAndTurnovers(&BeginOfPeriod, , Month, RegisterRecords, ) AS ProvisionsForPeriods
	|WHERE
	|	ProvisionsForPeriods.CountTurnover > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	NestedQuery.Period AS Period,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	-(MIN(NestedQuery.CountClosingBalance) - MIN(NestedQuery.CountOpeningBalance)) AS QuantityToTransfer,
	|	SUM(NestedQuery.Reserve) AS Reserve
	|FROM
	|	(SELECT
	|		ENDOFPERIOD(GoodsOfOrganizationsBalancesAndTurnover.Period, MONTH) AS Period,
	|		GoodsOfOrganizationsBalancesAndTurnover.Organization AS Organization,
	|		GoodsOfOrganizationsBalancesAndTurnover.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		GoodsOfOrganizationsBalancesAndTurnover.CCDNumber AS CCDNumber,
	|		GoodsOfOrganizationsBalancesAndTurnover.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		GoodsOfOrganizationsBalancesAndTurnover.CountOpeningBalance AS CountOpeningBalance,
	|		GoodsOfOrganizationsBalancesAndTurnover.CountClosingBalance AS CountClosingBalance,
	|		0 AS Reserve
	|	FROM
	|		AccumulationRegister.CompanyGoods.BalanceAndTurnovers(
	|				&BeginOfPeriod,
	|				,
	|				Month,
	|				RegisterRecords,
	|				(Organization, InventoryOwnerAttribute, CCDNumber, ItemsLocationAttributes) IN
	|					(SELECT
	|						ProvisionsForPeriods.Organization AS Organization,
	|						ProvisionsForPeriods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|						ProvisionsForPeriods.CCDNumber AS CCDNumber,
	|						ProvisionsForPeriods.ItemsLocationAttributes AS ItemsLocationAttributes
	|					FROM
	|						ProvisionsForPeriods AS ProvisionsForPeriods)) AS GoodsOfOrganizationsBalancesAndTurnover
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProvisionsForPeriods.Period,
	|		ProvisionsForPeriods.Organization,
	|		ProvisionsForPeriods.InventoryOwnerAttribute,
	|		ProvisionsForPeriods.CCDNumber,
	|		ProvisionsForPeriods.ItemsLocationAttributes,
	|		-ProvisionsForPeriods.CountOpeningBalance,
	|		-ProvisionsForPeriods.CountOpeningBalance,
	|		ProvisionsForPeriods.ProvisionInPeriod
	|	FROM
	|		ProvisionsForPeriods AS ProvisionsForPeriods) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.Organization,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.ItemsLocationAttributes
	|
	|HAVING
	|	-(MIN(NestedQuery.CountClosingBalance) - MIN(NestedQuery.CountOpeningBalance)) < SUM(NestedQuery.Reserve) AND
	|	SUM(NestedQuery.Reserve) > 0";
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("BeginOfPeriod", BegOfMonth(DateOfFirstReserve));
	
	SetPrivilegedMode(True);
	NoExtraReserves = Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	If NoExtraReserves Then
		AddConstantPeriodsOfReservesOfGoodsOfOrganizationsAreRelevant(True);
		Return "NoExtraReserves";
	Else
		AddConstantPeriodsOfReservesOfGoodsOfOrganizationsAreRelevant(False);
		Return "ThereAreExtraReserves";
	EndIf;
	
EndFunction

Function AllocateReservesByPeriod() Export

	DateOfFirstReserve = InventoriesServer.DateOfFirstReserve(Undefined);
	
	If Not ValueIsFilled(DateOfFirstReserve) Then
		AddConstantPeriodsOfReservesOfGoodsOfOrganizationsAreRelevant(True);
		Return "NoExtraReserves";
	EndIf;
	
	DateOfFirstReserve = EndOfMonth(DateOfFirstReserve);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CompanySafeStock.Period AS Period
	|FROM
	|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|
	|ORDER BY
	|	Period DESC";
	
	Selection = Query.Execute().Select();
	
	Selection.Next();
	
	LastReserveDate = EndOfMonth(Selection.Period);
	
	CurrentMonth = DateOfFirstReserve;
	
	Cancel = False;
	
	While CurrentMonth <= LastReserveDate Do
		
		If Not AllocateReservesInPeriod(CurrentMonth) Then
			Cancel = True;
			Break;
		EndIf;
		
		CurrentMonth = EndOfMonth(CurrentMonth + 1);
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	CompanySafeStock.Period AS Period
		|FROM
		|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
		|
		|ORDER BY
		|	Period DESC";
		
		Selection = Query.Execute().Select();
		
		Selection.Next();
		
		LastReserveDate = EndOfMonth(Selection.Period);
	EndDo;
	
	If Not Cancel Then
		Return ThereAreExtraReserves(False);
	Else
		AddConstantPeriodsOfReservesOfGoodsOfOrganizationsAreRelevant(False);
		Return "Error";
	EndIf;	
	
EndFunction

Function AllocateReservesInPeriod(CurrentMonth)
	
	TempTablesManager = New TempTablesManager;
	
	BeginTransaction();
	
	Try
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("AccumulationRegister.CompanySafeStock");
		LockItem.Mode = DataLockMode.Exclusive;
		
		LockItem = DataLock.Add("AccumulationRegister.CompanyGoods");
		LockItem.Mode = DataLockMode.Shared;
		
		DataLock.Lock();
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("BeginningOfBorderPeriod", New Boundary(BegOfMonth(CurrentMonth),BoundaryType.Including));
		Query.SetParameter("PeriodEndBoundary", New Boundary(EndOfMonth(CurrentMonth),BoundaryType.Including));
		Query.SetParameter("BeginOfPeriod", BegOfMonth(CurrentMonth));
		Query.SetParameter("EndOfPeriod", EndOfMonth(CurrentMonth));
		Query.SetParameter("RegisteredRecordsOfCancelledDocument",
									AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns());
		
		QueryText =
		"SELECT
		|	ENDOFPERIOD(ProvisionsForPeriods.Period, MONTH) AS Period,
		|	ProvisionsForPeriods.Organization AS Organization,
		|	ProvisionsForPeriods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	ProvisionsForPeriods.CCDNumber AS CCDNumber,
		|	ProvisionsForPeriods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	-ProvisionsForPeriods.CountTurnover AS Count,
		|	CASE
		|		WHEN NOT &UseTraceableImportedGoodsAccounting
		|				OR BEGINOFPERIOD(ProvisionsForPeriods.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|			THEN 0
		|		ELSE -CAST(ProvisionsForPeriods.QuantityByGBRNTurnover AS NUMBER(23, 11))
		|	END AS QuantityByGBRN
		|INTO DocumentRegisterRecords
		|FROM
		|	AccumulationRegister.CompanySafeStock.BalanceAndTurnovers(&BeginningOfBorderPeriod, &PeriodEndBoundary, Month, RegisterRecords, ) AS ProvisionsForPeriods
		|WHERE
		|	ProvisionsForPeriods.CountTurnover > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentRegisterRecords.Period AS Period,
		|	DocumentRegisterRecords.Organization AS Organization,
		|	DocumentRegisterRecords.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DocumentRegisterRecords.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DocumentRegisterRecords.CCDNumber AS CCDNumber,
		|	DocumentRegisterRecords.Count AS Count,
		|	CAST(DocumentRegisterRecords.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN
		|INTO RegisteredRecordsOfCancelledDocument
		|FROM
		|	&RegisteredRecordsOfCancelledDocument AS DocumentRegisterRecords
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Period AS Period,
		|	NestedQuery.Organization AS Organization,
		|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	NestedQuery.CCDNumber AS CCDNumber,
		|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	-(MIN(NestedQuery.CountClosingBalance) - MIN(NestedQuery.CountOpeningBalance)) AS QuantityToTransfer,
		|	-(MIN(NestedQuery.QuantityByGBRNClosingBalance) - MIN(NestedQuery.QuantityByGBRNOpeningBalance)) AS ProductBatchIDCountTransferred
		|INTO TTQuantityToTransmit
		|FROM
		|	(SELECT
		|		ENDOFPERIOD(GoodsOfOrganizationsBalancesAndTurnover.Period, MONTH) AS Period,
		|		GoodsOfOrganizationsBalancesAndTurnover.Organization AS Organization,
		|		GoodsOfOrganizationsBalancesAndTurnover.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		GoodsOfOrganizationsBalancesAndTurnover.CCDNumber AS CCDNumber,
		|		GoodsOfOrganizationsBalancesAndTurnover.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		GoodsOfOrganizationsBalancesAndTurnover.CountOpeningBalance AS CountOpeningBalance,
		|		GoodsOfOrganizationsBalancesAndTurnover.CountClosingBalance AS CountClosingBalance,
		|		CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(GoodsOfOrganizationsBalancesAndTurnover.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE GoodsOfOrganizationsBalancesAndTurnover.QuantityByGBRNOpeningBalance
		|		END AS QuantityByGBRNOpeningBalance,
		|		CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(GoodsOfOrganizationsBalancesAndTurnover.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE CAST(GoodsOfOrganizationsBalancesAndTurnover.QuantityByGBRNClosingBalance AS NUMBER(23, 11))
		|		END AS QuantityByGBRNClosingBalance
		|	FROM
		|		AccumulationRegister.CompanyGoods.BalanceAndTurnovers(
		|				&BeginningOfBorderPeriod,
		|				&PeriodEndBoundary,
		|				Month,
		|				RegisterRecords,
		|				(Organization, InventoryOwnerAttribute, CCDNumber, ItemsLocationAttributes) IN
		|					(SELECT
		|						DocumentRegisterRecords.Organization AS Organization,
		|						DocumentRegisterRecords.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|						DocumentRegisterRecords.CCDNumber AS CCDNumber,
		|						DocumentRegisterRecords.ItemsLocationAttributes AS ItemsLocationAttributes
		|					FROM
		|						DocumentRegisterRecords AS DocumentRegisterRecords)) AS GoodsOfOrganizationsBalancesAndTurnover
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ENDOFPERIOD(&BeginOfPeriod, MONTH),
		|		CompanySafeStockBalance.Organization,
		|		CompanySafeStockBalance.InventoryOwnerAttribute,
		|		CompanySafeStockBalance.CCDNumber,
		|		CompanySafeStockBalance.ItemsLocationAttributes,
		|		-CompanySafeStockBalance.CountBalance,
		|		-CompanySafeStockBalance.CountBalance,
		|		CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(&BeginOfPeriod, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE -CompanySafeStockBalance.QuantityByGBRNBalance
		|		END,
		|		CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(&BeginOfPeriod, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE -CAST(CompanySafeStockBalance.QuantityByGBRNBalance AS NUMBER(23, 11))
		|		END
		|	FROM
		|		AccumulationRegister.CompanySafeStock.Balance(
		|				&BeginOfPeriod,
		|				(Organization, InventoryOwnerAttribute, CCDNumber, ItemsLocationAttributes) IN
		|					(SELECT
		|						DocumentRegisterRecords.Organization AS Organization,
		|						DocumentRegisterRecords.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|						DocumentRegisterRecords.CCDNumber AS CCDNumber,
		|						DocumentRegisterRecords.ItemsLocationAttributes AS ItemsLocationAttributes
		|					FROM
		|						DocumentRegisterRecords AS DocumentRegisterRecords)) AS CompanySafeStockBalance
		|	WHERE
		|		CompanySafeStockBalance.CountBalance > 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ENDOFPERIOD(&BeginOfPeriod, MONTH),
		|		DocumentRegisterRecords.Organization,
		|		DocumentRegisterRecords.InventoryOwnerAttribute,
		|		DocumentRegisterRecords.CCDNumber,
		|		DocumentRegisterRecords.ItemsLocationAttributes,
		|		0,
		|		0,
		|		0,
		|		0
		|	FROM
		|		DocumentRegisterRecords AS DocumentRegisterRecords) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.CCDNumber,
		|	NestedQuery.Period,
		|	NestedQuery.InventoryOwnerAttribute,
		|	NestedQuery.ItemsLocationAttributes,
		|	NestedQuery.Organization
		|
		|HAVING
		|	MIN(NestedQuery.CountClosingBalance) - MIN(NestedQuery.CountOpeningBalance) < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Organization AS Organization,
		|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	NestedQuery.CCDNumber AS CCDNumber,
		|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes
		|INTO TTSelectionsOfBusinessBalances
		|FROM
		|	(SELECT
		|		TTQuantityToTransmit.Period AS Period,
		|		TTQuantityToTransmit.Organization AS Organization,
		|		TTQuantityToTransmit.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		TTQuantityToTransmit.CCDNumber AS CCDNumber,
		|		TTQuantityToTransmit.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		TTQuantityToTransmit.QuantityToTransfer AS QuantityToTransfer,
		|		0 AS Reserve
		|	FROM
		|		TTQuantityToTransmit AS TTQuantityToTransmit
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Period,
		|		DocumentRegisterRecords.Organization,
		|		DocumentRegisterRecords.InventoryOwnerAttribute,
		|		DocumentRegisterRecords.CCDNumber,
		|		DocumentRegisterRecords.ItemsLocationAttributes,
		|		0,
		|		-DocumentRegisterRecords.Count
		|	FROM
		|		DocumentRegisterRecords AS DocumentRegisterRecords) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Period,
		|	NestedQuery.Organization,
		|	NestedQuery.InventoryOwnerAttribute,
		|	NestedQuery.CCDNumber,
		|	NestedQuery.ItemsLocationAttributes
		|
		|HAVING
		|	SUM(NestedQuery.QuantityToTransfer) < SUM(NestedQuery.Reserve) AND
		|	SUM(NestedQuery.Reserve) > 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	Organization,
		|	CCDNumber";
		
		Query.Text = QueryText;
		
		AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
		
		Query.ExecuteBatch();
		
		QueryText =
		"
		|	SELECT &TextTTBalancesByMonth;
		|	
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GroupedBalances.Period AS Period,
		|	GroupedBalances.Organization AS Organization,
		|	GroupedBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GroupedBalances.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	GroupedBalances.CCDNumber AS CCDNumber,
		|	MIN(GroupedBalances.CountBalance) AS CountBalance,
		|	MIN(GroupedBalances.QuantityByGBRNBalance) AS QuantityByGBRNBalance,
		|	SUM(GroupedBalances.PeriodCounter) AS PeriodCounter
		|INTO GroupedBalances
		|FROM
		|	&TextBalancesByMonth AS GroupedBalances
		|
		|GROUP BY
		|	Period,
		|	PeriodNumber,
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|
		|HAVING
		|	(MIN(GroupedBalances.CountBalance) <> 0
		|	AND SUM(GroupedBalances.PeriodCounter) >= &TotalPeriods - GroupedBalances.PeriodNumber + 1)
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ENDOFPERIOD(TableNewReserves.Period, MONTH) AS Period,
		|	TableNewReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	TableNewReserves.CCDNumber AS CCDNumber,
		|	TableNewReserves.Organization AS Organization,
		|	TableNewReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TableNewReserves.CorCompany AS CorCompany,
		|	TableNewReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	SUM(TableNewReserves.Count) AS Count,
		|	SUM(CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(TableNewReserves.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE CAST(TableNewReserves.QuantityByGBRN AS NUMBER(23, 11))
		|		END) AS QuantityByGBRN,
		|	TableNewReserves.RecordType AS RecordType
		|INTO TTOriginalTableTableNewReserves
		|FROM
		|	AccumulationRegister.CompanySafeStock AS TableNewReserves
		|		INNER JOIN TTSelectionsOfBusinessBalances AS TTSelectionsOfBusinessBalances
		|		ON TableNewReserves.ItemsLocationAttributes = TTSelectionsOfBusinessBalances.ItemsLocationAttributes
		|			AND TableNewReserves.InventoryOwnerAttribute = TTSelectionsOfBusinessBalances.InventoryOwnerAttribute
		|			AND TableNewReserves.Organization = TTSelectionsOfBusinessBalances.Organization
		|			AND TableNewReserves.CCDNumber = TTSelectionsOfBusinessBalances.CCDNumber
		|WHERE
		|	TableNewReserves.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND NOT TableNewReserves.ThisIsReverseTransaction
		|	AND TableNewReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
		|
		|GROUP BY
		|	TableNewReserves.CCDNumber,
		|	TableNewReserves.Organization,
		|	TableNewReserves.ItemsLocationAttributes,
		|	ENDOFPERIOD(TableNewReserves.Period, MONTH),
		|	TableNewReserves.InventoryOwnerAttribute,
		|	TableNewReserves.RecordType,
		|	TableNewReserves.CorInventoryOwnerAttribute,
		|	TableNewReserves.CorCompany
		|
		|HAVING
		|	SUM(TableNewReserves.Count) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	ENDOFPERIOD(TableNewReserves.Period, MONTH),
		|	TableNewReserves.ItemsLocationAttributes,
		|	TableNewReserves.CCDNumber,
		|	TableNewReserves.CorCompany,
		|	TableNewReserves.CorInventoryOwnerAttribute,
		|	TableNewReserves.Organization,
		|	TableNewReserves.InventoryOwnerAttribute,
		|	SUM(TableNewReserves.Count),
		|	SUM(CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(TableNewReserves.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE CAST(TableNewReserves.QuantityByGBRN AS NUMBER(23, 11))
		|		END),
		|	VALUE(AccumulationRecordType.Expense)
		|FROM
		|	AccumulationRegister.CompanySafeStock AS TableNewReserves
		|		INNER JOIN TTSelectionsOfBusinessBalances AS TTSelectionsOfBusinessBalances
		|		ON TableNewReserves.ItemsLocationAttributes = TTSelectionsOfBusinessBalances.ItemsLocationAttributes
		|			AND TableNewReserves.InventoryOwnerAttribute = TTSelectionsOfBusinessBalances.InventoryOwnerAttribute
		|			AND TableNewReserves.Organization = TTSelectionsOfBusinessBalances.Organization
		|			AND TableNewReserves.CCDNumber = TTSelectionsOfBusinessBalances.CCDNumber
		|WHERE
		|	TableNewReserves.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND NOT TableNewReserves.ThisIsReverseTransaction
		|	AND TableNewReserves.RecordType = VALUE(AccumulationRecordType.Receipt)
		|
		|GROUP BY
		|	TableNewReserves.CorInventoryOwnerAttribute,
		|	TableNewReserves.CCDNumber,
		|	TableNewReserves.CorCompany,
		|	TableNewReserves.RecordType,
		|	TableNewReserves.ItemsLocationAttributes,
		|	ENDOFPERIOD(TableNewReserves.Period, MONTH),
		|	TableNewReserves.Organization,
		|	TableNewReserves.InventoryOwnerAttribute
		|
		|HAVING
		|	SUM(TableNewReserves.Count) > 0";
		
		ParametersForAddingBalancesToRequestForEachMonth = InventoriesServer.ParametersForAddingBalancesToRequestForEachMonth();
		ParametersForAddingBalancesToRequestForEachMonth.ThereIsSelectionByCCDNumber = True;
		
		TotalPeriods = InventoriesServer.AddBalanceControlForEachMonthToRequest(Query,
																					QueryText,
																					ParametersForAddingBalancesToRequestForEachMonth,
																					CurrentMonth);
		
		Query.SetParameter("TotalPeriods", TotalPeriods);
		
		AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
		
		Query.Text = QueryText;
		
		QueryResults = Query.ExecuteBatchWithIntermediateData();
		
		TableNewReserves = QueryResults[QueryResults.UBound()].Unload(); // ValueTable
		TableNewReserves.Columns.Add("ThisIsReverseTransaction", New TypeDescription("Boolean"));
		
		TableNewReserves = InventoriesServer.DistributeReservesOfGoodsOfOrganizationsByPeriods(TotalPeriods, TableNewReserves, TempTablesManager);
		
		QueryText =
		"SELECT
		|	TableNewReserves.Period AS Period,
		|	TableNewReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	TableNewReserves.Organization AS Organization,
		|	TableNewReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TableNewReserves.CCDNumber AS CCDNumber,
		|	TableNewReserves.CorCompany AS CorCompany,
		|	TableNewReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	TableNewReserves.Count AS Count,
		|	CAST(TableNewReserves.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
		|	TableNewReserves.RecordType AS RecordType
		|INTO TTTableNewReserves
		|FROM
		|	&TableNewReserves AS TableNewReserves
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Period AS Period,
		|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	NestedQuery.Organization AS Organization,
		|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	NestedQuery.CCDNumber AS CCDNumber,
		|	NestedQuery.CorCompany AS CorCompany,
		|	NestedQuery.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	SUM(NestedQuery.Count) AS Count,
		|	SUM(NestedQuery.QuantityByGBRN) AS QuantityByGBRN,
		|	SUM(NestedQuery.Count) < 0 AS ThisIsReverseTransaction,
		|	NestedQuery.RecordType AS RecordType
		|FROM
		|	(SELECT
		|		TableNewReserves.Period AS Period,
		|		TableNewReserves.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		TableNewReserves.Organization AS Organization,
		|		TableNewReserves.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		TableNewReserves.CCDNumber AS CCDNumber,
		|		TableNewReserves.CorCompany AS CorCompany,
		|		TableNewReserves.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|		TableNewReserves.Count AS Count,
		|		CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(TableNewReserves.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE TableNewReserves.QuantityByGBRN
		|		END AS QuantityByGBRN,
		|		TableNewReserves.RecordType AS RecordType
		|	FROM
		|		TTTableNewReserves AS TableNewReserves
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SourceTableNewReserves.Period,
		|		SourceTableNewReserves.ItemsLocationAttributes,
		|		SourceTableNewReserves.Organization,
		|		SourceTableNewReserves.InventoryOwnerAttribute,
		|		SourceTableNewReserves.CCDNumber,
		|		SourceTableNewReserves.CorCompany,
		|		SourceTableNewReserves.CorInventoryOwnerAttribute,
		|		-SourceTableNewReserves.Count,
		|		CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(SourceTableNewReserves.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			ELSE -SourceTableNewReserves.QuantityByGBRN
		|		END,
		|		SourceTableNewReserves.RecordType
		|	FROM
		|		TTOriginalTableTableNewReserves AS SourceTableNewReserves) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Period,
		|	NestedQuery.ItemsLocationAttributes,
		|	NestedQuery.Organization,
		|	NestedQuery.InventoryOwnerAttribute,
		|	NestedQuery.CCDNumber,
		|	NestedQuery.CorCompany,
		|	NestedQuery.CorInventoryOwnerAttribute,
		|	NestedQuery.RecordType
		|
		|HAVING
		|	SUM(NestedQuery.Count) <> 0";
		
		Query.Text = QueryText;
		Query.SetParameter("TableNewReserves", TableNewReserves);
		
		AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
		
		TableNewReserves = Query.Execute().Unload();
		
		If TableNewReserves.Count() > 0 Then
			
			RegisterAdjustment = Documents.RegisterAdjustment.CreateDocument();
			RegisterAdjustment.Date = CurrentMonth;
			RegisterAdjustment.Comment = NStr("vi = 'Được tạo tự động khi phân bổ dự phòng hàng hóa trong các doanh nghiệp theo kỳ.';
												|ru = 'Создан автоматически при распределении резервов товаров организаций по периодам.';
												|en = 'Created automatically while allocating company goods reserves by periods.'; fa = 'Created automatically while allocating company goods reserves by periods.';
												|it = 'Generato automaticamente durante allocazione di riserve delle merci delle società per periodi.';
												|pl = 'Utworzony automatycznie przy podziale rezerwy towarów firm po okresach.';
												|tr = 'İş yerlerinin ürün yedeklerini dönemlere göre dağıtırken otomatik olarak oluşturulmuştur.'",
			Common.DefaultLanguageCode());
			
			NewRow = RegisterAdjustment.RegistersTable.Add();
			NewRow.Name = "CompanySafeStock";
			
			RegisterAdjustment.Write();
			
			Set = AccumulationRegisters.CompanySafeStock.CreateRecordSet();
			Set.Filter.Recorder.Set(RegisterAdjustment.Ref);
			Set.Load(TableNewReserves);
			
			//Set.Additional properties.Insert(Accumulation registers.Reserves of the organization's products.The sign of the record set of the envelope(), True);
			StructureOfTemporaryTables = New Structure("TempTablesManager", New TempTablesManager);
			Set.AdditionalProperties.Insert("ForConducting", 
			New Structure("StructureOfTemporaryTables",StructureOfTemporaryTables));
			Set.Write = True;
			Set.Write();
			
		EndIf;
		
		// If there are extra reserves left after the distribution, they just need to be reversed
		QueryText =
		"SELECT
		|	NestedQuery.Period AS Period,
		|	NestedQuery.Organization AS Organization,
		|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	NestedQuery.CCDNumber AS CCDNumber,
		|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	SUM(NestedQuery.Reserve) - SUM(NestedQuery.QuantityToTransfer) AS ExtraReserve
		|INTO TTExcessReserves
		|FROM
		|	(SELECT
		|		TTQuantityToTransmit.Period AS Period,
		|		TTQuantityToTransmit.Organization AS Organization,
		|		TTQuantityToTransmit.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		TTQuantityToTransmit.CCDNumber AS CCDNumber,
		|		TTQuantityToTransmit.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		TTQuantityToTransmit.QuantityToTransfer AS QuantityToTransfer,
		|		0 AS Reserve
		|	FROM
		|		TTQuantityToTransmit AS TTQuantityToTransmit
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ENDOFPERIOD(ProvisionsForPeriods.Period, MONTH),
		|		ProvisionsForPeriods.Organization,
		|		ProvisionsForPeriods.InventoryOwnerAttribute,
		|		ProvisionsForPeriods.CCDNumber,
		|		ProvisionsForPeriods.ItemsLocationAttributes,
		|		0,
		|		ProvisionsForPeriods.CountTurnover
		|	FROM
		|		AccumulationRegister.CompanySafeStock.BalanceAndTurnovers(&BeginningOfBorderPeriod, &PeriodEndBoundary, Month, RegisterRecords, ) AS ProvisionsForPeriods
		|	WHERE
		|		ProvisionsForPeriods.CountTurnover > 0) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Period,
		|	NestedQuery.Organization,
		|	NestedQuery.InventoryOwnerAttribute,
		|	NestedQuery.CCDNumber,
		|	NestedQuery.ItemsLocationAttributes
		|
		|HAVING
		|	SUM(NestedQuery.Reserve) - SUM(NestedQuery.QuantityToTransfer) > 0 AND
		|	SUM(NestedQuery.Reserve) > 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	InventoryOwnerAttribute,
		|	Period,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ENDOFPERIOD(CompanySafeStock.Period, MONTH) AS Period,
		|	CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStock.CCDNumber AS CCDNumber,
		|	CompanySafeStock.Organization AS Organization,
		|	CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	CompanySafeStock.CorCompany AS CorCompany,
		|	CompanySafeStock.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	SUM(CASE
		|			WHEN CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN CompanySafeStock.Count
		|			ELSE -CompanySafeStock.Count
		|		END) AS Count,
		|	SUM(CASE
		|			WHEN NOT &UseTraceableImportedGoodsAccounting
		|					OR BEGINOFPERIOD(CompanySafeStock.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|				THEN 0
		|			WHEN CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11))
		|			ELSE -CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11))
		|		END) AS QuantityByGBRN
		|FROM
		|	TTExcessReserves AS TTExcessReserves
		|		LEFT JOIN AccumulationRegister.CompanySafeStock AS CompanySafeStock
		|		ON (ENDOFPERIOD(CompanySafeStock.Period, MONTH) = TTExcessReserves.Period)
		|			AND (CompanySafeStock.ItemsLocationAttributes = TTExcessReserves.ItemsLocationAttributes)
		|			AND (CompanySafeStock.Organization = TTExcessReserves.Organization)
		|			AND (CompanySafeStock.InventoryOwnerAttribute = TTExcessReserves.InventoryOwnerAttribute)
		|			AND (CompanySafeStock.CCDNumber = TTExcessReserves.CCDNumber)
		|
		|GROUP BY
		|	CompanySafeStock.Organization,
		|	CompanySafeStock.InventoryOwnerAttribute,
		|	CompanySafeStock.CorInventoryOwnerAttribute,
		|	CompanySafeStock.CorCompany,
		|	ENDOFPERIOD(CompanySafeStock.Period, MONTH),
		|	CompanySafeStock.ItemsLocationAttributes,
		|	CompanySafeStock.CCDNumber
		|
		|HAVING
		|	SUM(CASE
		|			WHEN CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN CompanySafeStock.Count
		|			ELSE -CompanySafeStock.Count
		|		END) > 0";
		
		Query.Text = QueryText;
		
		QueryResults = Query.ExecuteBatchWithIntermediateData();
		
		ExcessReserves = QueryResults[0].Unload();
		
		SearchColumns = "ItemsLocationAttributes,CCDNumber,Organization,InventoryOwnerAttribute";
		SearchSelection = New Structure(SearchColumns);
		
		ReservesWithCorPart = QueryResults[1].Unload(); // ValueTable
		ReservesWithCorPart.Indexes.Add(SearchColumns);
		
		If ExcessReserves.Count() > 0 Then
			
			RegisterRecordTable = AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns();
			
			For Each RowOfTables In ExcessReserves Do
				
				UnallocatedExcessReserve = RowOfTables.ExtraReserve;
				FillPropertyValues(SearchSelection, RowOfTables);
				
				PartCor = ReservesWithCorPart.FindRows(SearchSelection);
				
				For Each ArrRow In PartCor Do
					
					ReverseQuantity = Min(UnallocatedExcessReserve, ArrRow.Count);
					
					StringOfStornow = RegisterRecordTable.Add();
					FillPropertyValues(StringOfStornow, ArrRow);
					StringOfStornow.RecordType = AccumulationRecordType.Receipt;
					StringOfStornow.Count = - ReverseQuantity;
					StringOfStornow.QuantityByGBRN = - ReverseQuantity * ArrRow.QuantityByGBRN / ArrRow.Count;
					StringOfStornow.ThisIsReverseTransaction  = True;
					
					StornowLine = RegisterRecordTable.Add();
					FillPropertyValues(StornowLine, StringOfStornow);
					StornowLine.RecordType    = AccumulationRecordType.Expense;
					StornowLine.Organization    = StringOfStornow.CorCompany;
					StornowLine.InventoryOwnerAttribute     = StringOfStornow.CorInventoryOwnerAttribute;
					StornowLine.CorCompany = StringOfStornow.Organization;
					StornowLine.CorInventoryOwnerAttribute  = StringOfStornow.InventoryOwnerAttribute;
					
					UnallocatedExcessReserve = UnallocatedExcessReserve - ReverseQuantity;
					
					If UnallocatedExcessReserve = 0 Then
						Break;
					EndIf;
					
				EndDo;
				
				If UnallocatedExcessReserve <> 0 Then
					ExceptionText = NStr("vi = 'Lỗi phân bổ dự phòng vượt mức. Liên hệ với nhà phát triển.';
										|ru = 'Ошибка при распределении лишних резервов. Обратитесь к разработчикам.';
										|en = 'An error occurred while allocating excessive reserves. Contact the developers.'; fa = 'An error occurred while allocating excessive reserves. Contact the developers.';
										|it = 'Errore di allocazione delle scorte in eccesso. Contattare i progettisti.';
										|pl = 'Błąd przy podziale dodatkowych rezerw. Należy skontaktować się z developerami.';
										|tr = 'Fazla yedekler dağıtılırken hata oluştu. Geliştiricilere başvuru yap.'");
					Raise ExceptionText;
				EndIf;
				
			EndDo;
			
			If RegisterRecordTable.Count() > 0 Then
				
				RegisterAdjustment = Documents.RegisterAdjustment.CreateDocument();
				RegisterAdjustment.Date = CurrentMonth;
				RegisterAdjustment.Comment = NStr("vi = 'Được tạo tự động khi đảo ngược dự phòng thừa.';
													|ru = 'Создан автоматически при сторнировании лишнего резерва.';
													|en = 'Created automatically while reversing an excessive reserve.'; fa = 'Created automatically while reversing an excessive reserve.';
													|it = 'Создан автоматически при сторнировании лишнего резерва.';
													|pl = 'Created automatically while reversing an excessive reserve.';
													|tr = 'Fazla rezervlerin tersine kaydı sırasında otomatik olarak oluşturulmuştur.'",
				Common.DefaultLanguageCode());
				
				NewRow = RegisterAdjustment.RegistersTable.Add();
				NewRow.Name = "CompanySafeStock";
				
				RegisterAdjustment.Write();
				
				Set = AccumulationRegisters.CompanySafeStock.CreateRecordSet();
				Set.Filter.Recorder.Set(RegisterAdjustment.Ref);
				Set.Load(RegisterRecordTable);
				
				StructureOfTemporaryTables = New Structure("TempTablesManager", New TempTablesManager);
				Set.AdditionalProperties.Insert("ForConducting", New Structure("StructureOfTemporaryTables",StructureOfTemporaryTables));
				Set.Write = True;
				Set.Write();
				
			EndIf;
			
		EndIf;
		
		CommitTransaction();
		
		Return True;
		
	Except
		
		RollbackTransaction();
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra lỗi trong khi chuyển dự phòng hàng hóa của các doanh nghiệp trong kỳ %1: %2';
				|ru = 'Возникла ошибка при переносе резервов товаров организаций за период %1: %2';
				|en = 'An error occurred when transferring company goods reserves for the period %1: %2'; fa = 'An error occurred when transferring company goods reserves for the period %1: %2';
				|it = 'Возникла ошибка при переносе резервов товаров организаций за период %1: %2';
				|pl = 'An error occurred when transferring company goods reserves for the period %1: %2';
				|tr = 'İş yerlerinin %1: %2 dönemine ait ürün rezervleri aktarılırken hata oluştu'"),
			Format(CurrentMonth, "DLF=DD"),
			DetailErrorDescription(ErrorInfo())
		);
		
		WriteLogEvent(NameOfReserveTransferEvent(),
			EventLogLevel.Error,
			Metadata.AccumulationRegisters.CompanySafeStock,,
			ErrorText
		);
		
		Return False;
		
	EndTry;
	
EndFunction

Function NameOfReserveTransferEvent() Export
	Return NStr("vi = 'Chuyển dự phòng hàng hóa của doanh nghiệp';
				|ru = 'Перенос резервов товаров организаций';
				|en = 'Transfer company goods reserves'; fa = 'Transfer company goods reserves';
				|it = 'Trasferimento delle scorte di merci delle società';
				|pl = 'Przenoszenie rezerw towarów firm';
				|tr = 'İş yerlerinin ürün yedeklerinin aktarılması'", Common.DefaultLanguageCode());
EndFunction

Procedure AddConstantPeriodsOfReservesOfGoodsOfOrganizationsAreRelevant(Value)
	
	SetPrivilegedMode(True);
	Constants.PeriodsOfCompanySafeStockAreRelevant.Set(Value);
	SetPrivilegedMode(False);
	
EndProcedure

Procedure ToFormReservesToCoverExcessStorno()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanySafeStock.Organization AS Organization,
	|	CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber AS CCDNumber,
	|	CompanySafeStock.Period AS Period,
	|	CompanySafeStock.RecordType AS RecordType,
	|	CompanySafeStock.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	CompanySafeStock.CorCompany AS CorCompany,
	|	FALSE AS ThisIsReverseTransaction,
	|	-SUM(CompanySafeStock.Count) AS Count,
	|	-SUM(CompanySafeStock.QuantityByGBRN) AS QuantityByGBRN
	|FROM
	|	(SELECT
	|		CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CompanySafeStock.Organization AS Organization,
	|		CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber AS CCDNumber,
	|		ENDOFPERIOD(CompanySafeStock.Period, MONTH) AS Period,
	|		CompanySafeStock.RecordType AS RecordType,
	|		CompanySafeStock.Count AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(CompanySafeStock.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11))
	|		END AS QuantityByGBRN,
	|		CompanySafeStock.CorCompany AS CorCompany,
	|		CompanySafeStock.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|	FROM
	|		AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|	WHERE
	|		NOT CompanySafeStock.ThisIsReverseTransaction
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CompanySafeStock.ItemsLocationAttributes,
	|		CompanySafeStock.Organization,
	|		CompanySafeStock.InventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber,
	|		ENDOFPERIOD(CompanySafeStock.Period, MONTH),
	|		CompanySafeStock.RecordType,
	|		CompanySafeStock.Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(CompanySafeStock.Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE CAST(CompanySafeStock.QuantityByGBRN AS NUMBER(23, 11))
	|		END,
	|		CompanySafeStock.CorCompany,
	|		CompanySafeStock.CorInventoryOwnerAttribute
	|	FROM
	|		AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|	WHERE
	|		CompanySafeStock.ThisIsReverseTransaction) AS CompanySafeStock
	|
	|GROUP BY
	|	CompanySafeStock.RecordType,
	|	CompanySafeStock.Organization,
	|	CompanySafeStock.CCDNumber,
	|	CompanySafeStock.Period,
	|	CompanySafeStock.InventoryOwnerAttribute,
	|	CompanySafeStock.ItemsLocationAttributes,
	|	CompanySafeStock.CorCompany,
	|	CompanySafeStock.CorInventoryOwnerAttribute
	|
	|HAVING
	|	SUM(CompanySafeStock.Count) < 0";
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	BeginTransaction();
	
	Try
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("AccumulationRegister.CompanySafeStock");
		LockItem.Mode = DataLockMode.Exclusive;
		
		DataLock.Lock();
		
		ReservesToCoverExcessStorno = Query.Execute().Unload();
		
		If ReservesToCoverExcessStorno.Count() = 0 Then
			RollbackTransaction();
			Return;
		EndIf;
		
		RegisterAdjustment = Documents.RegisterAdjustment.CreateDocument();
		RegisterAdjustment.Date = CurrentSessionDate();
		RegisterAdjustment.Comment = NStr("vi = 'Tạo tự động khi ghi giảm dự phòng đảo ngược dư thừa.';
											|ru = 'Создан автоматически при удалении лишних сторно-резервов.';
											|en = 'Created automatically while deleting excess reserve storno.'; fa = 'Created automatically while deleting excess reserve storno.';
											|it = 'Creato automaticamente quando si eliminano scritture di storno in eccesso.';
											|pl = 'Utworzony automatycznie po usunięciu zbędnych storno-rezerw.';
											|tr = 'Fazla iptal yedekleri silindiğinde otomatik olarak oluşturulur.'",
			Common.DefaultLanguageCode()
		);
		
		NewRow = RegisterAdjustment.RegistersTable.Add();
		NewRow.Name = "CompanySafeStock";
		
		RegisterAdjustment.Write();
		
		Set = AccumulationRegisters.CompanySafeStock.CreateRecordSet();
		Set.Filter.Recorder.Set(RegisterAdjustment.Ref);
		Set.Load(ReservesToCoverExcessStorno);
		
		StructureOfTemporaryTables = New Structure("TempTablesManager", New TempTablesManager);
		Set.AdditionalProperties.Insert("ForConducting", New Structure("StructureOfTemporaryTables",StructureOfTemporaryTables));
		Set.Write = True;
		Set.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã xảy ra lỗi khi đối trừ dự phòng: %1';
																					|ru = 'Возникла ошибка зачете встречных резервов: %1';
																					|en = 'An error occurred when offsetting counter reserves: %1'; fa = 'An error occurred when offsetting counter reserves: %1';
																					|it = 'Возникла ошибка зачете встречных резервов: %1';
																					|pl = 'An error occurred when offsetting counter reserves: %1';
																					|tr = 'Karşılık rezervlerinin mahsup edilmesinde hata oluştu: %1'"),
			DetailErrorDescription(ErrorInfo())
		);
		
		WriteLogEvent(NStr("vi = 'Khấu trừ dự phòng hàng hóa của các doanh nghiệp';
							|ru = 'Зачет встречных резервов товаров организаций';
							|en = 'Set off counter reserves of company goods'; fa = 'Set off counter reserves of company goods';
							|it = 'Compensazione di riserve reciproche di merci delle aziende';
							|pl = 'Zaliczanie wzajemnych rezerw towarów firmy';
							|tr = 'İş yeri ürünlerinin karşılık yedeklerinin mahsup edilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.AccumulationRegisters.CompanySafeStock,,
			ErrorText
		);
		
	EndTry;
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf