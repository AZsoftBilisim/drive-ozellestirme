
#Region ProcessingStructureOfFillingParametersFormCommandCountersellers

&AtClient
Procedure FindAnalytics(Command)
	FindAnalyticsAtServer();
EndProcedure

&AtClient
Procedure Fix(Command)
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Theo dữ liệu của bản ghi kết chuyển gốc, sẽ điền lại các biểu ghi: %1
		|
		|Nhiệm vụ phản ánh lại vào KTDN, Kế toán quốc tế, thuế GTGT và chưa tạo đóng tháng. Tiếp tục?';
		|ru = 'По данным первичных движений будут перезаполнены регистры: %1
		|
		|Задания к переотражению в БУ, МФУ, НДС и к закрытию месяца созданы не будут. Продолжить?';
		|en = 'The following registers will be re-populated: %1 according to the primary register records data
		|
		|Jobs to be recorded in the local accounting, IFRS, VAT and by the month-end closing will not be created. Continue?'; fa = 'The following registers will be re-populated: %1 according to the primary register records data
		|
		|Jobs to be recorded in the local accounting, IFRS, VAT and by the month-end closing will not be created. Continue?';
		|it = 'I registri saranno ricompilati in base ai dati di movimenti primari: %1
		|
		|I task di ri-registrazione in contabilità ordinaria, contabilità finanziaria internazionale, IVA e alla chiusura del mese non saranno creati. Continuare?';
		|pl = 'Wg danych pierwotnych przepływów zostaną ponownie wypełnione rejestry: %1
		|
		|Zadania do ponownego odzwierciedlenia w ewidencji księgowej, międzynarodowej ewidencji księgowej, VAT i do zamknięcia miesiąca nie będą utworzone. Kontynuować?';
		|tr = 'Birincil hareketlerin verilerine göre, kayıtlar yeniden doldurulacaktır: %1
		|
		| AC, UFM, KDV''de yeniden raporlama ve ay sonu kapanışı için görevler oluşturulmayacaktır. Devam edilsin mi?'"),
		RegisterNames());
	ShowQueryBox(New CallbackDescription("FixCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FixCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		Message(NStr("vi = 'Bắt đầu giao dịch:';
					|ru = 'Начало операции:';
					|en = 'Operation start:'; fa = 'Operation start:';
					|it = 'Inizio operazione:';
					|pl = 'Początek operacji:';
					|tr = 'İşlem başlangıcı:'") + " " + CurrentDate());
		FixAtServer();
		Message(NStr("vi = 'Đã thực hiện giao dịch thành công:';
					|ru = 'Операция выполнена успешно:';
					|en = 'Operation has been successfully installed:'; fa = 'Operation has been successfully installed:';
					|it = 'Operazione completata con successo:';
					|pl = 'Operacja została wykonana pomyślnie:';
					|tr = 'İşlem başarıyla tamamlandı:'") + " " + CurrentDate());
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function RegisterNames(OnlyPlanned = False)
	If Not OnlyPlanned Then
		Return 
			StrTemplate("
			|	%1
			|	%2
			|	%3
			|	%4
			|	%5
			|	%6",
			Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Synonym,
			Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Synonym,
			Metadata.AccumulationRegisters.CustomersARAPAccountingPlannedShipments.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries.Synonym
			);
	Else
		Return 
			StrTemplate("
			|	%1
			|	%2
			|	%3
			|	%4",
			Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Synonym,
			Metadata.AccumulationRegisters.CustomersARAPAccountingPlannedShipments.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Synonym,
			Metadata.AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries.Synonym
			);
	EndIf;
EndFunction

&AtServer
Function FindProblematicAnalytics()
	
	Operations = New Array;
	
	Query = New Query;
	Query.Text = AnalyticsQueryTextForRecalculation();
	Query.SetParameter("Operations", Operations);
	
	Results = Query.ExecuteBatch();
	
	Errors = New Structure;
	Dimension = Results[5].Unload();
	Dimension.Indexes.Add("AccountingDimensionByPartners");
	Dimension.Indexes.Add("ARAPObject");
	Errors.Insert("Dimension", Dimension);
	Errors.Insert("RegisterAdjustments", Results[6].Unload());
	
	Return Errors;
	
EndFunction

&AtServer
Function AnalyticsQueryTextForRecalculation()
	
	QueryText = 
	"SELECT
	|	CustomersARAPAccountingByDueDates.DocumentRecorder AS DocumentRecorder,
	|	CustomersARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingByDueDates.Currency AS Currency,
	|	SUM(CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CustomersARAPAccountingByDueDates.Prepayment - CustomersARAPAccountingByDueDates.Debt
	|			ELSE CustomersARAPAccountingByDueDates.Debt - CustomersARAPAccountingByDueDates.Prepayment
	|		END) AS Sum
	|INTO TTCustomersOnTime
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|WHERE
	|	CustomersARAPAccountingByDueDates.Active
	|	AND NOT CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.RegisterAdjustment
	|
	|GROUP BY
	|	CustomersARAPAccountingByDueDates.DocumentRecorder,
	|	CustomersARAPAccountingByDueDates.AccountingDimensionByPartners,
	|	CustomersARAPAccountingByDueDates.ARAPObject,
	|	CustomersARAPAccountingByDueDates.Currency
	|
	|HAVING
	|	SUM(CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CustomersARAPAccountingByDueDates.Prepayment - CustomersARAPAccountingByDueDates.Debt
	|			ELSE CustomersARAPAccountingByDueDates.Debt - CustomersARAPAccountingByDueDates.Prepayment
	|		END) <> 0
	|
	|INDEX BY
	|	DocumentRecorder,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomersARAPAccounting.Recorder AS Recorder,
	|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|	CustomersARAPAccounting.Currency AS Currency,
	|	SUM(CASE
	|			WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccounting.Sum
	|			ELSE CustomersARAPAccounting.Sum
	|		END) AS SumTurnover
	|INTO TTCustomers
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|WHERE
	|	CustomersARAPAccounting.Active
	|	AND NOT CustomersARAPAccounting.Recorder REFS Document.RegisterAdjustment
	|
	|GROUP BY
	|	CustomersARAPAccounting.Recorder,
	|	CustomersARAPAccounting.AccountingDimensionByPartners,
	|	CustomersARAPAccounting.ARAPObject,
	|	CustomersARAPAccounting.Currency
	|
	|HAVING
	|	SUM(CASE
	|			WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccounting.Sum
	|			ELSE CustomersARAPAccounting.Sum
	|		END) <> 0
	|
	|INDEX BY
	|	Recorder,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorsARAPAccountingByDueDates.DocumentRecorder AS DocumentRecorder,
	|	VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingByDueDates.Currency AS Currency,
	|	SUM(CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN VendorsARAPAccountingByDueDates.Prepayment - VendorsARAPAccountingByDueDates.Debt
	|			ELSE VendorsARAPAccountingByDueDates.Debt - VendorsARAPAccountingByDueDates.Prepayment
	|		END) AS Sum
	|INTO TTSuppliersByTerms
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|WHERE
	|	VendorsARAPAccountingByDueDates.Active
	|	AND NOT VendorsARAPAccountingByDueDates.DocumentRecorder REFS Document.RegisterAdjustment
	|
	|GROUP BY
	|	VendorsARAPAccountingByDueDates.DocumentRecorder,
	|	VendorsARAPAccountingByDueDates.AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDueDates.ARAPObject,
	|	VendorsARAPAccountingByDueDates.Currency
	|
	|HAVING
	|	SUM(CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN VendorsARAPAccountingByDueDates.Prepayment - VendorsARAPAccountingByDueDates.Debt
	|			ELSE VendorsARAPAccountingByDueDates.Debt - VendorsARAPAccountingByDueDates.Prepayment
	|		END) <> 0
	|
	|INDEX BY
	|	DocumentRecorder,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorsARAPAccounting.Recorder AS Recorder,
	|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	VendorsARAPAccounting.Currency AS Currency,
	|	SUM(CASE
	|			WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN VendorsARAPAccounting.Sum
	|			ELSE -VendorsARAPAccounting.Sum
	|		END) AS SumTurnover
	|INTO TTSuppliers
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|WHERE
	|	VendorsARAPAccounting.Active
	|	AND NOT VendorsARAPAccounting.Recorder REFS Document.RegisterAdjustment
	|
	|GROUP BY
	|	VendorsARAPAccounting.Recorder,
	|	VendorsARAPAccounting.AccountingDimensionByPartners,
	|	VendorsARAPAccounting.ARAPObject,
	|	VendorsARAPAccounting.Currency
	|
	|HAVING
	|	SUM(CASE
	|			WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN VendorsARAPAccounting.Sum
	|			ELSE -VendorsARAPAccounting.Sum
	|		END) <> 0
	|
	|INDEX BY
	|	Recorder,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.Currency AS SettlementsCurrency,
	|	NestedQuery.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers
	|INTO TTAnalytics_
	|FROM
	|	(SELECT DISTINCT
	|		ISNULL(TTCustomers.AccountingDimensionByPartners, TTCustomersOnTime.AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|		ISNULL(TTCustomers.ARAPObject, TTCustomersOnTime.ARAPObject) AS ARAPObject,
	|		ISNULL(TTCustomers.Currency, TTCustomersOnTime.Currency) AS Currency,
	|		TRUE AS TheseAreSettlementsWithCustomers
	|	FROM
	|		TTCustomersOnTime AS TTCustomersOnTime
	|			FULL JOIN TTCustomers AS TTCustomers
	|			ON (TTCustomers.Recorder = TTCustomersOnTime.DocumentRecorder)
	|				AND (TTCustomers.AccountingDimensionByPartners = TTCustomersOnTime.AccountingDimensionByPartners)
	|				AND (TTCustomers.ARAPObject = TTCustomersOnTime.ARAPObject)
	|				AND (TTCustomers.Currency = TTCustomersOnTime.Currency)
	|	WHERE
	|		ISNULL(TTCustomersOnTime.Sum, 0) <> ISNULL(TTCustomers.SumTurnover, 0)
	|		
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		ISNULL(TTSuppliers.AccountingDimensionByPartners, TTSuppliersByTerms.AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|		ISNULL(TTSuppliers.ARAPObject, TTSuppliersByTerms.ARAPObject) AS ARAPObject,
	|		ISNULL(TTSuppliers.Currency, TTSuppliersByTerms.Currency) AS Currency,
	|		FALSE AS TheseAreSettlementsWithCustomers
	|	FROM
	|		TTSuppliersByTerms AS TTSuppliersByTerms
	|			FULL JOIN TTSuppliers AS TTSuppliers
	|			ON (TTSuppliers.Recorder = TTSuppliersByTerms.DocumentRecorder)
	|				AND (TTSuppliers.AccountingDimensionByPartners = TTSuppliersByTerms.AccountingDimensionByPartners)
	|				AND (TTSuppliers.ARAPObject = TTSuppliersByTerms.ARAPObject)
	|				AND (TTSuppliers.Currency = TTSuppliersByTerms.Currency)
	|	WHERE
	|		ISNULL(TTSuppliersByTerms.Sum, 0) <> ISNULL(TTSuppliers.SumTurnover, 0)
	|	) AS NestedQuery
	|	
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	SettlementsCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Dimension.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Dimension.ARAPObject AS ARAPObject,
	|	Dimension.SettlementsCurrency AS SettlementsCurrency,
	|	Dimension.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers
	|FROM
	|	TTAnalytics_ AS Dimension
	|ORDER BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	SettlementsCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.Recorder AS Recorder,
	|	NestedQuery.Operation AS Operation
	|FROM
	|	(SELECT DISTINCT
	|		RegisterAdjustment.Ref AS Recorder,
	|		RegisterAdjustment.Operation AS Operation
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|		INNER JOIN Document.RegisterAdjustment AS RegisterAdjustment
	|			ON CustomersARAPAccountingByDueDates.DocumentRecorder = RegisterAdjustment.Ref
	|		INNER JOIN TTAnalytics_ AS Dimension
	|			ON CustomersARAPAccountingByDueDates.AccountingDimensionByPartners = Dimension.AccountingDimensionByPartners
	|				AND CustomersARAPAccountingByDueDates.ARAPObject = Dimension.ARAPObject
	|				AND CustomersARAPAccountingByDueDates.Currency = Dimension.SettlementsCurrency
	|	WHERE
	|		CustomersARAPAccountingByDueDates.Active
	|		AND RegisterAdjustment.Operation <> VALUE(Enum.RegisterAdjustmentOperations.ManualAdjustment)
	|		
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		RegisterAdjustment.Ref AS Recorder,
	|		RegisterAdjustment.Operation AS Operation
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		INNER JOIN Document.RegisterAdjustment AS RegisterAdjustment
	|			ON VendorsARAPAccountingByDueDates.DocumentRecorder = RegisterAdjustment.Ref
	|		INNER JOIN TTAnalytics_ AS Dimension
	|			ON VendorsARAPAccountingByDueDates.AccountingDimensionByPartners = Dimension.AccountingDimensionByPartners
	|				AND VendorsARAPAccountingByDueDates.ARAPObject = Dimension.ARAPObject
	|				AND VendorsARAPAccountingByDueDates.Currency = Dimension.SettlementsCurrency
	|	WHERE
	|		VendorsARAPAccountingByDueDates.Active
	|		AND RegisterAdjustment.Operation <> VALUE(Enum.RegisterAdjustmentOperations.ManualAdjustment)
	|	) AS NestedQuery
	|
	|ORDER BY
	|	Recorder";
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure FindAnalyticsAtServer()
	
	SpreadsheetDocument.Clear();
	
	Errors = FindProblematicAnalytics();
	If Errors.Dimension.Count() > 0 Then
		DisplayTableWithTitle(Errors.Dimension,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối tượng phân tích hạch toán theo thơi hạn để tính lại (Số lượng: %1)';
					|ru = 'Аналитика расчетов по срокам для пересчета (Количество: %1)';
					|en = 'Calculation dimension by due dates for recalculation (Quantity: %1)'; fa = 'Calculation dimension by due dates for recalculation (Quantity: %1)';
					|it = 'Calculation dimension by due dates for recalculation (Quantity: %1)';
					|pl = 'Calculation dimension by due dates for recalculation (Quantity: %1)';
					|tr = 'Yeniden hesaplama için zamanlama hesaplamasının analizi (Miktar:%1)'"),
				String(Errors.Dimension.Count())));
	Else
		PrintTitle_1(NStr("vi = 'Không tìm thấy lỗi';
							|ru = 'Ошибок не обнаружено';
							|en = 'No errors detected'; fa = 'No errors detected';
							|it = 'Non sono stati rilevati errori';
							|pl = 'Nie wykryto błędów';
							|tr = 'Hatalar algılanmıyor'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure FixAtServer()
	
	SpreadsheetDocument.Clear();
	
	Errors = FindProblematicAnalytics();
	If Errors.Dimension.Count() = 0 Then
		PrintTitle_1(NStr("vi = 'Không tìm thấy lỗi';
							|ru = 'Ошибок не обнаружено';
							|en = 'No errors detected'; fa = 'No errors detected';
							|it = 'Non sono stati rilevati errori';
							|pl = 'Nie wykryto błędów';
							|tr = 'Hatalar algılanmıyor'"));
		Return;
	EndIf;
	
	RemoveSystemRegisterAdjustments(Errors);
	For Each Dimension In Errors.Dimension Do
		FillBySpecifiedOnServer(Dimension.AccountingDimensionByPartners, Dimension.ARAPObject);
	EndDo;
	
	DisplayTableWithTitle(Errors.Dimension,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã tính toán lại (Số lượng: %1)';
				|ru = 'Выполнен пересчет (Количество: %1)';
				|en = 'Recalculation is performed (Quantity: %1)'; fa = 'Recalculation is performed (Quantity: %1)';
				|it = 'Recalculation is performed (Quantity: %1)';
				|pl = 'Recalculation is performed (Quantity: %1)';
				|tr = 'Yeniden hesaplama yapıldı (Miktar: %1)'"),
			String(Errors.Dimension.Count())));
	
EndProcedure

&AtServer
Procedure FillBySpecifiedOnServer(DimensionKeyOfAccountingByPartners, ARAPObject)
	
	If Not ValueIsFilled(DimensionKeyOfAccountingByPartners) Then
		ExceptionText = NStr("vi = 'Để điền từng phần, hãy chỉ ra Khóa đối tượng phân tích kế toán theo bạn hàng';
							|ru = 'Для частичного заполнения укажите Ключ аналитики учета по партнерам.';
							|en = 'For partial filling, specify a Dimension key of accounting by partners.'; fa = 'For partial filling, specify a Dimension key of accounting by partners.';
							|it = 'Per la compilazione parziale, indicare la Chiave di analisi di contabilità per partner.';
							|pl = 'Dla częściowego wypełnienia podaj Klucz analityki ewidencji według parnterów.';
							|tr = 'Kısmi tamamlama için İş Ortağı muhasebe boyutu anahtarını belirt.'");
		Raise ExceptionText;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("AccountingDimensionByPartners", DimensionKeyOfAccountingByPartners);
	Query.SetParameter("ARAPObject",ARAPObject);
	
	Query.Text = "
	|SELECT DISTINCT
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency         AS Currency,
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	DATETIME(1,1,1) AS RecalculationStartDate,
	|	DATETIME(3999,1,1) AS PeriodForMonitoringChangesAndCreatingTasks
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency         AS Currency,
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	DATETIME(1,1,1) AS RecalculationStartDate,
	|	DATETIME(3999,1,1) AS PeriodForMonitoringChangesAndCreatingTasks
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency         AS Currency,
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	DATETIME(1,1,1) AS RecalculationStartDate,
	|	DATETIME(3999,1,1) AS PeriodForMonitoringChangesAndCreatingTasks
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency         AS Currency,
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	DATETIME(1,1,1) AS RecalculationStartDate,
	|	DATETIME(3999,1,1) AS PeriodForMonitoringChangesAndCreatingTasks
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.AccountingDimensionByPartners = &AccountingDimensionByPartners";
	
	ObjectsTable = Query.Execute().Unload();
	
	ARAPAccountingInternal.ClearSettlementRegistersAndDeleteServiceRecorders(
		?(ValueIsFilled(ARAPObject), ARAPObject, Undefined),
		?(ValueIsFilled(DimensionKeyOfAccountingByPartners), DimensionKeyOfAccountingByPartners, Undefined));
	
	MainParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
	OnlineARAPAccountingServer.CompleteOperationalSettlements(MainParameters, ObjectsTable);
	
EndProcedure

&AtServer
Procedure RemoveSystemRegisterAdjustments(Errors)
	
	AnalystTable = Errors.Dimension;
	For Each Adjusting In Errors.RegisterAdjustments Do
		
		AdjustingObject = Adjusting.Recorder.GetObject(); // DocumentObject.RegisterAdjustment
		For Each Register In AdjustingObject.RegistersTable Do
			RegisterRecords = AdjustingObject.RegisterRecords[Register.Name]; // AccumulationRegisterRecordSet
			RegisterRecords.DataExchange.Load = True;
			RegisterOfSettlementsWithClients = Register.Name = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name;
			If RegisterOfSettlementsWithClients Or Register.Name = Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name Then
				RegisterRecords.Read();
				RegisterRecordTable = RegisterRecords.Unload();
				For Each Dimension In AnalystTable Do
					If Dimension.TheseAreSettlementsWithCustomers <> RegisterOfSettlementsWithClients Then
						Continue;
					EndIf;
					If RegisterRecordTable.Count() = 0 Then
						Break;
					EndIf;
					Filter = New Structure();
					Filter.Insert("AccountingDimensionByPartners", Dimension.AccountingDimensionByPartners);
					Filter.Insert("ARAPObject", Dimension.ARAPObject);
					Filter.Insert("Currency", Dimension.SettlementsCurrency);
					FoundRows = RegisterRecordTable.FindRows(Filter);
					For Each String In FoundRows Do
						RegisterRecordTable.Delete(String);
					EndDo;
				EndDo;//according to analysts
				RegisterRecords.Load(RegisterRecordTable);
				RegisterRecords.Write();
			EndIf;//this is a time register
		EndDo;//by register movements
		
	EndDo;//according to the documents adjustment of registers
	
EndProcedure

#Region OutputToTabularDocument

&AtServer
Procedure PrintTitle_1(Var_Title)
	
	Template = FormAttributeToValue("Object").GetTemplate("Template");
	HeaderArea_ = Template.GetArea("Title2|Column");
	
	HeaderArea_.Parameters.Value = Var_Title;
	SpreadsheetDocument.Put(HeaderArea_);
	
EndProcedure

&AtServer
Procedure DisplayTableWithTitle(Table, Var_Title = "", LongDesc = "")
	
	Template = FormAttributeToValue("Object").GetTemplate("Template");
	HeaderArea_ = Template.GetArea("Title2|Column");
	
	HeaderArea_.Parameters.Value = Var_Title;
	SpreadsheetDocument.Put(HeaderArea_);
	
	If LongDesc <> "" Then
		Area = SpreadsheetDocument.GetArea(2,1);
		Area.CurrentArea.Text = LongDesc;
		SpreadsheetDocument.Put(Area);
	EndIf;
	
	Discrepancies = OutputTableOfValues(Table);
	Discrepancies.Area().CreateFormatOfRows();
	SpreadsheetDocument.Put(Discrepancies);
	
EndProcedure

&AtServer
Function OutputTableOfValues(Table, TableHeaderArea = Undefined)
	
	TabDocument = New SpreadsheetDocument;
	ColumnsWidths = ColumnsWidths();
	LineNumber = 1;
	
	// Output the table header
	If TableHeaderArea <> Undefined Then
		TabDocument.Put(TableHeaderArea);
		LineNumber = LineNumber + 1;
	EndIf;
	
	Arial8Bold = New Font("Arial",8,True);
	Line = New Line(SpreadsheetDocumentCellLineType.Solid,1,False);
	AllRefsType = DescriptionOfTypeOfAlmostAllLinks();
	
	// Output the table header
	Column_Index = 0;
	While Column_Index < Table.Columns.Count() Do
		Column = Table.Columns[Column_Index];
		ColumnWidth = ColumnsWidths[Column.Name];
		
		Area = TabDocument.Area(LineNumber, Column_Index + 1, LineNumber, Column_Index + 1);
		Area.Text = Column.Name;
		Area.ColumnWidth = ?(ColumnWidth = Undefined, 9, ColumnWidth);
		Area.Outline(Line,Line,Line,Line);
		Area.Font = Arial8Bold;
		Area.BorderColor = StyleColors.ReportLineColor;
		Area.BackColor = StyleColors.ReportHeaderBackColor;
		
		Column_Index = Column_Index + 1;
	EndDo;
	
	// We display the rows of the table
	RowIndex2 = 0;
	While RowIndex2 < Table.Count() Do
		Table_Row = Table[RowIndex2];
		Column_Index = 0;
		While Column_Index < Table.Columns.Count() Do
			Column = Table.Columns[Column_Index];
			Area = TabDocument.Area(RowIndex2 + LineNumber + 1, Column_Index + 1, RowIndex2 + LineNumber + 1, Column_Index + 1);
			Value = Table_Row[Column.Name];
			Area.Text = Format(Value, "NG=0");
			If AllRefsType.ContainsType(TypeOf(Value)) Then
				Area.Details = Value;
			EndIf;
			If CommonClientServer.IsNumber(Value) Then
				Area.HorizontalAlign=HorizontalAlign.Right;
			EndIf;
			Area.Outline(Line,Line,Line,Line);
			Area.BorderColor = StyleColors.ReportLineColor;
			Column_Index = Column_Index + 1;
		EndDo;
		RowIndex2 = RowIndex2 + 1;
	EndDo;
	
	Return TabDocument;
	
EndFunction

&AtServer
Function DescriptionOfTypeOfAlmostAllLinks() Export
	
	// We add all documents, enumerations, etc. to the all Catalogs type.
	AlmostAllRefs = New TypeDescription(Catalogs.AllRefsType(), Documents.AllRefsType().Types());
	AlmostAllRefs = New TypeDescription(AlmostAllRefs, Enums.AllRefsType().Types());
	AlmostAllRefs = New TypeDescription(AlmostAllRefs, ChartsOfCharacteristicTypes.AllRefsType().Types());
	AlmostAllRefs = New TypeDescription(AlmostAllRefs, ChartsOfAccounts.AllRefsType().Types());
	Return AlmostAllRefs;
	
EndFunction

&AtServer
Function ColumnsWidths()
	
	Result = New Map;
	
	ResourceWidth = 9;
	
	Result.Insert("Recorder",45);
	Result.Insert("DocumentRecorder",40);
	Result.Insert("AccountingDimensionByPartners",55);
	Result.Insert("ARAPObject",40);
	Result.Insert("SettlementsCurrency",10);
	Result.Insert("Operation",40);
	Result.Insert("TheseAreSettlementsWithCustomers",20);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion