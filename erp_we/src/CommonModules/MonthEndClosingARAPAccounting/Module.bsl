#Region Public

// Complements the request text of the mechanism for generating monthly closing tasks.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames) Export
	
	MatchingRequests = MatchingRequestsToControlRegisters(Query);
	
	For Each MapItem In MatchingRequests Do
		MonthEndTransactionsServer.AddTableNamesForTasks(Query, MapItem.Key);
		MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key,
			MapItem.Value,
			Query.TempTablesManager.Tables,
			QueryText,
			TempTablesQueryText,
			TemporaryTableNames);
	EndDo;
	
EndProcedure

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_PostingToPartnersARAPAccountingAndARAPRevaluation(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation);
	
	NewRow.MultilingualName = "vi = 'Lập các lưu chuyển cho đối trừ công nợ với các đối tác và đánh giá lại đối trừ công nợ';
								|ru = 'Формирование движений по расчетам с партнерами и переоценка расчетов';
								|en = 'Generate register records by AR/AP with partners and AR/AP revaluation';
								|it = 'Generazione dei movimenti relativi con  pagamenti ai partner e rivalutazione dei pagamenti';
								|pl = 'Formowanie ruchów dla rozliczeń z partnerami oraz przeszacowanie rozliczeń';
								|tr = 'İş ortaklarıyla yapılan hesaplamalara ilişkin hareketlerin düzenlenmesi ve hesaplamaların yeniden değerlemesi'"; // @NStr-1
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"MonthEndClosingARAPAccounting.Use_FormationOfRegisteredRecordsForSettlementsWithPartnersAndReEvaluationOfSettlements");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"MonthEndClosingARAPAccounting.Registration_FormationOfRegisteredRecordsForSettlementsWithPartnersAndReassessmentOfSettlements");
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"MonthEndClosingARAPAccounting.Perform_GenerationOfRegisteredRecordsForPartnersARAPAccountingAndRevaluationOfCalculations");
		NewRow.PerformedAtPreliminaryClosingOfMonth = True;
	NewRow.UpdateStateOfStages.Add(Catalogs.MonthEndClosingOperations.AdditionalDocumentPosting);
EndProcedure

// Parameters:
// 	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure Use_FormationOfRegisteredRecordsForSettlementsWithPartnersAndReEvaluationOfSettlements(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT TOP 1
	|	Calculations.AccountingDimensionByPartners
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Analysts
	|	ON Calculations.AccountingDimensionByPartners = Analysts.Ref
	|WHERE
	|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Analysts.Organization IN (&CompanyArray)
	|	AND Calculations.Active
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Calculations.AccountingDimensionByPartners
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Analysts
	|	ON Calculations.AccountingDimensionByPartners = Analysts.Ref
	|WHERE
	|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Analysts.Organization IN (&CompanyArray)
	|	AND Calculations.Active";
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	ThereAreRegisteredRecordsAccordingToCalculations = Not Query.Execute().IsEmpty();
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
		CalculationAnalysts.Companies = CalculationParameters.CompanyArray;
		
		CalculationStart = ARAPAllocationServerCall.StartOfCalculations(EndOfMonth(CalculationParameters.Period), CalculationAnalysts);
		PeriodInRecalculationRange = (ValueIsFilled(CalculationStart) And CalculationStart <= CalculationParameters.RegistrationPeriod);
		
	Else
		
		CalculationStart = MonthEndTransactionsServer.CalculationStart(
			HandlerParameters.Data_Stage.Code,
			HandlerParameters.CalculationParameters.EndOfPeriod,
			Undefined,
			CalculationParameters.CompanyArray);
		
		PeriodInRecalculationRange = MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True);
		HandlerParameters.ExplanationTable_.Clear();
		
		If PeriodInRecalculationRange Then
			Query.SetParameter("BegOfMonth", BegOfMonth(CalculationParameters.RegistrationPeriod));
		Else
			Query.SetParameter("BegOfMonth", Date(1,1,1,1,1,2));
		EndIf;
		Query.SetParameter("PeriodInRecalculationRange", PeriodInRecalculationRange);
		
		Query.Text = ARAPAccountingInternal.TextOfRequestForIncorrectBalancesOfSettlementsByTerms("TTIncorrectSettlementBalances");
		Query.Execute();
		
		Query.Text = "DROP TTAnalytics_; DROP TTBalance; DROP TTManualAdjustments";
		Query.Execute();
		
		Query.Text = ARAPAccountingInternal.TextOfRequestForIncorrectBalancesOfSettlementsByTerms("TTIncorrectSettlementBalancesManualAdjustments", False);
		Query.Execute();
		
		Query.Text = "DROP TTAnalytics_; DROP TTManualAdjustments";
		Query.Execute();
		
		Query.Text = ARAPAccountingInternal.QueryTextDetailedBalance("TTExpandedBalanceOfSettlements");
		Query.Execute();
		
		Query.Text = "DROP TTAnalytics_; DROP TTBalance_; DROP TTManualAdjustments";
		Query.Execute();
		
		Query.Text = ARAPAccountingInternal.QueryTextDetailedBalance("TTExpandedBalanceOfSettlementsManualAdjustments", False);
		Query.Execute();
		
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	RegistersForCalculation = Documents.ExchangeDifferenceCalculation.CalculationRegisters(Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting);
	RegistersForCalculation = Documents.ExchangeDifferenceCalculation.CalculationRegisters(Enums.BusinessTransactions.RevaluationOfCustomersARAP, RegistersForCalculation);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	ThereAreCurrencyBalances = Documents.ExchangeDifferenceCalculation.ThereAreCurrencyBalances(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		RegistersForCalculation);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, CalculationParameters.CompanyArray.Count());
	
	ReEvaluationRequired = Documents.ExchangeDifferenceCalculation.RequiresReassessmentOfSettlements(
		CalculationParameters.CompanyArray,
		CalculationParameters.RegistrationPeriod);
	
	TTIncorrectBalancesManualAdjustments = Query.TempTablesManager.Tables.Find("TTIncorrectSettlementBalancesManualAdjustments");
	TTDeployedBalanceManualAdjustments = Query.TempTablesManager.Tables.Find("TTExpandedBalanceOfSettlementsManualAdjustments");

	ThereAreIncorrectManualAdjustments = TTIncorrectBalancesManualAdjustments <> Undefined 
		And Not TTIncorrectBalancesManualAdjustments.GetData().IsEmpty()
		Or TTDeployedBalanceManualAdjustments <> Undefined
		And Not TTDeployedBalanceManualAdjustments.GetData().IsEmpty();
	
	If Not ReEvaluationRequired And Not PeriodInRecalculationRange And Not ThereAreIncorrectManualAdjustments Then
		
		If Not ThereAreRegisteredRecordsAccordingToCalculations Then
			
			// No calculation is required.
			MonthEndTransactionsServer.NoNeedToSetState(
				HandlerParameters,
				NStr("vi = 'Không có bản ghi kết chuyển hạch toán công nợ với khách hàng và nhà cung cấp.';
					|ru = 'Нет движений по взаиморасчетам с клиентами и поставщиками.';
					|en = 'No register records in customer and vendor AR/AP.'; fa = 'No register records in customer and vendor AR/AP.';
					|it = 'Non vi sono movimenti per i conti reciproci con clienti e fornitori.';
					|pl = 'Brak przepływów według rozliczeń wzajemnych z klientami i dostawcami.';
					|tr = 'Müşteriler ve tedarikçiler ile mutabakata ilişkin herhangi bir hareket bulunmamaktadır.'", Common.DefaultLanguageCode()));
			
			If Not ThereAreCurrencyBalances Then
				MonthEndTransactionsServer.NoNeedToSetState(
					HandlerParameters,
					NStr("vi = 'Không có số dư nguyên tệ hạch toán công nợ với khách hàng và nhà cung cấp.';
						|ru = 'Нет валютных остатков по взаиморасчетам с клиентами и поставщиками.';
						|en = 'No currency balance for customer and vendor AR/AP.'; fa = 'No currency balance for customer and vendor AR/AP.';
						|it = 'Non vi sono saldi valutari per i conti reciproci con i clienti e fornitori.';
						|pl = 'Brak sald walutowych według rozliczeń wzajemnych z klientami i dostawcami.';
						|tr = 'Müşteriler ve tedarikçilerle yapılan mutabakatlarda para birimi bakiyesi bulunmamaktadır.'", Common.DefaultLanguageCode()));
			EndIf;
			
		Else
			// The calculation was completed successfully.
		EndIf;
		
	Else
		
		// Recalculation is required.
		If PeriodInRecalculationRange Then
			
			HandlerParameters.Data_Stage.SettlementStartDate = BegOfMonth(CalculationStart);
			
			OperationText = NStr("vi = 'Tạo các bản ghi kết chuyển bắt đầu từ kỳ %1';
								|ru = 'Формирование движений начиная с периода %1';
								|en = 'Generate records starting from the period %1'; fa = 'Generate records starting from the period %1';
								|it = 'Generazione di movimenti partendo dal periodo %1';
								|pl = 'Generowanie ruchów zaczynając od okresu %1';
								|tr = '%1 döneminden başlamak üzere hareket oluşturma'", Common.DefaultLanguageCode());
			
			MonthEndTransactionsServer.SetStateFailed(
				HandlerParameters,
				StringFunctionsClientServer.SubstituteParametersToString(
					OperationText,
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationStart)));
			
		EndIf;
		
		If ReEvaluationRequired Then
			
			ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
				Metadata.Reports.DetailedCalculationOfCurrencyRevaluation.FullName() + ".Form", True);
			ActionMoreDetails.FormParameters.Insert("GenerateOnOpen", True);
			ActionMoreDetails.FormParameters.Insert("AllCompanies", Not ValueIsFilled(HandlerParameters.CalculationParameters.CompanyArray));
			
			If PeriodInRecalculationRange Then
				MonthEndTransactionsServer.SetStateFailed(
					HandlerParameters,
					NStr("vi = 'Tính toán chênh lệch tỷ giá hạch toán công nợ với khách hàng và nhà cung cấp.';
						|ru = 'Расчет курсовых разниц по взаиморасчетам с клиентами и поставщиками.';
						|en = 'Calculation of exchange differences for customer and vendor AR/AP.'; fa = 'Calculation of exchange differences for customer and vendor AR/AP.';
						|it = 'Calcolo delle differenze dei tassi di cambio per i conti reciproci con clienti e fornitori.';
						|pl = 'Obliczenie różnic kursowych według rozliczeń wzajemnych z klientami i dostawcami.';
						|tr = 'Müşteriler ve tedarikçilerle yapılan mutabakatlarda kur farklarının hesaplanması.'", Common.DefaultLanguageCode()),
					MonthEndTransactionsServer.DefaultDetailsText(),
					ActionMoreDetails);
			Else
				MonthEndTransactionsServer.SetStateExecutedWithErrors(
					HandlerParameters,
					NStr("vi = 'Tính toán chênh lệch tỷ giá hạch toán công nợ với khách hàng và nhà cung cấp.';
						|ru = 'Расчет курсовых разниц по взаиморасчетам с клиентами и поставщиками.';
						|en = 'Calculation of exchange differences for customer and vendor AR/AP.'; fa = 'Calculation of exchange differences for customer and vendor AR/AP.';
						|it = 'Calcolo delle differenze dei tassi di cambio per i conti reciproci con clienti e fornitori.';
						|pl = 'Obliczenie różnic kursowych według rozliczeń wzajemnych z klientami i dostawcami.';
						|tr = 'Müşteriler ve tedarikçilerle yapılan mutabakatlarda kur farklarının hesaplanması.'", Common.DefaultLanguageCode()),
					MonthEndTransactionsServer.DefaultDetailsText(),
					ActionMoreDetails);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	MonthEndTransactionsServer.SetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", ReEvaluationRequired);
	
EndProcedure

// Parameters:
// 	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure Registration_FormationOfRegisteredRecordsForSettlementsWithPartnersAndReassessmentOfSettlements(HandlerParameters) Export
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		HandlerParameters.Data_Stage.Description = NStr("vi = 'Tính toán chênh lệch tỷ giá hạch toán công nợ với khách hàng và nhà cung cấp';
														|ru = 'Расчет курсовых разниц по взаиморасчетам с клиентами и поставщиками';
														|en = 'Calculation of exchange differences for customer and vendor AR/AP'; fa = 'Calculation of exchange differences for customer and vendor AR/AP';
														|it = 'Calculation of exchange differences for customer and vendor AR/AP';
														|pl = 'Calculation of exchange differences for customer and vendor AR/AP';
														|tr = 'Müşteriler ve tedarikçilerle yapılan mutabakatlarda kur farklarının hesaplanması'");
		HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Thực hiện';
														|ru = 'Выполнить';
														|en = 'Run'; fa = 'اجرا';
														|it = 'Eseguire';
														|pl = 'Run';
														|tr = 'Yürüt'");
	Else
		HandlerParameters.Data_Stage.Description = NStr("vi = 'Tạo các bản ghi kết chuyển theo các khoản khấu trừ thanh toán';
														|ru = 'Формирование движений по данным взаиморасчетов';
														|en = 'Generate register records according to AR/AP accounting data'; fa = 'Generate register records according to AR/AP accounting data';
														|it = 'Generazione dei movimenti secondo i dati della regolazione reciproca dei conti';
														|pl = 'Tworzenie ruchów wg danych rozliczeń wzajemnych';
														|tr = 'Mutabakatlara göre hareketlerin oluşumu'");
		HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Lập báo cáo';
														|ru = 'Сформировать';
														|en = 'Generate'; fa = 'ایجاد';
														|it = 'Generare';
														|pl = 'Generate';
														|tr = 'Oluştur'");
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

Procedure DescriptionOfChecks_FormationOfRegisteredRecordsOnSettlementsWithPartnersAndReassessmentOfSettlements(TableOfChecks) Export
	
	// Discrepancies in the balances of operational and financial registers of mutual settlements.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"CheckingSettlementBalances",
		Catalogs.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"MonthEndClosingARAPAccounting.CheckingSettlementBalances");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Sự khác biệt trong biểu ghi hạch toán';
			|ru = 'Расхождения в регистрах взаиморасчетов';
			|en = 'Discrepancies in the mutual settlement registers'; fa = 'Discrepancies in the mutual settlement registers';
			|it = 'Divergenze nei registri dei pagamenti reciproci';
			|pl = 'Odchylenie w rejestrach rozliczeń wzajemnych';
			|tr = 'Mutabakat kayıtlarında tutarsızlık'"),
		NStr("vi = 'Có 2 cách sửa lỗi: 
			|1) Cuối tháng xuất hiện chênh lệch và điều chỉnh số dư vào đầu tháng đóng.
			|Nhiệm vụ được phản ánh lại vào KTDN, Kế toán quốc tế, thuế GTGT và nhiệm vụ cần đóng tháng sẽ không được tạo ra lúc này.
			|2) Để chỉnh sửa bản ghi kết chuyển của chứng từ dẫn đến số dư không chính xác, cần kết chuyển lại các chứng từ tương ứng.';
			|ru = 'Существует 2 способа исправления: 
			|1) Закрытие месяца выявит расхождения и скорректирует остатки на начало закрываемого месяца.
			|Задания к переотражению в БУ, МФУ, НДС и к закрытию месяца при этом созданы не будут.
			|2) Для исправления движений документов, приведших к некорректным остаткам необходимо перепровести соответствующие документы.';
			|en = 'There are 2 correction methods:
			|1) Month-end closing will reveal discrepancy and will adjust balance to the beginning of the closing month.
			|Assignments for rerun in LA, financial accounting, VAT and by the month-end closing will not be created.
			|2) Re-post the relevant documents to adjust the transfer records that led to invalid balances.'; fa = 'There are 2 correction methods:
			|1) Month-end closing will reveal discrepancy and will adjust balance to the beginning of the closing month.
			|Assignments for rerun in LA, financial accounting, VAT and by the month-end closing will not be created.
			|2) Re-post the relevant documents to adjust the transfer records that led to invalid balances.';
			|it = 'Esistono 2 metodi di correzione: 
			|1) La chiusura di un mese rivelerà discrepanze e adeguerà i saldi all''inizio del mese da chiudere.
			|I task da rilevare nella contabilità, contabilità finanziaria internazionale, IVA e alla chiusura del mese non saranno creati.
			|2) Per la correzione dei movimenti dei  documenti che portano a saldi errati devono essere ritrasmessi ai documenti pertinenti.';
			|pl = 'Istnieje 2 sposoby korekty: 
			|1) Zamknięcie miesiąca ujawni odchylenie i poprawi salda na początek zamykanego miesiąca.
			|Zadania do ponownego odbicia w EK, Międzynarodowej ewidencji finansowej, VAT i do zamknięcia miesiąca przy tym nie będą utworzone.
			|2) Dla korekty ruchów dokumentów, które doprowadziły do niepoprawnych sald należy ponownie zaksięgować odpowiednie dokumenty.';
			|tr = 'İki düzeltme yöntemi mevcut: 
			|1) Ayı kapanışı tutarsızlıkları ortaya çıkaracak ve kapatılan ayın başındaki bakiyeleri ayarlayacaktır.
			|AC, UFM, KDV''ye ve ay sonuna kadar yeniden yansıtma görevleri oluşturulmayacaktır.
			|2) Hatalı bakiyelere yol açan belge kayıtlarının düzeltilmesi için ilgili belgelerin yeniden gönderilmesi gerekir.'"));
	
	// Automatically uncorrected discrepancies in the balances of operational and financial registers of mutual settlements 
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"CheckingSettlementBalancesManualAdjustment",
		Catalogs.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"MonthEndClosingARAPAccounting.CheckingSettlementBalancesManualAdjustment");
		
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Sự khác biệt trong biểu ghi hạch toán';
			|ru = 'Расхождения в регистрах взаиморасчетов';
			|en = 'Discrepancies in the mutual settlement registers'; fa = 'Discrepancies in the mutual settlement registers';
			|it = 'Divergenze nei registri dei pagamenti reciproci';
			|pl = 'Odchylenie w rejestrach rozliczeń wzajemnych';
			|tr = 'Mutabakat kayıtlarında tutarsızlık'"),
		NStr("vi = 'Theo đối tượng phân tích và đối tượng hạch toán đã chỉ ra, phát hiện có điều chỉnh thủ công các biểu ghi.
			|Chỉ có thể chỉnh sửa bằng cách điều chỉnh thủ công biểu ghi.';
			|ru = 'По указанным аналитикам и объектам расчетов обнаружены ручные корректировки регистров.
			|Исправление возможно только ручной корректировкой регистров.';
			|en = 'Manual register adjustments are detected by specified dimensions and AR/AP objects.
			|Correction is possible only by manual register adjustments.'; fa = 'Manual register adjustments are detected by specified dimensions and AR/AP objects.
			|Correction is possible only by manual register adjustments.';
			|it = 'In base all''analisi dati indicata e agli oggetti dei calcoli, sono stati rilevate correzioni manuali dei registri.
			|È possibile correggere i registri solo manualmente.';
			|pl = 'Wg podanych analityk i obiektów rozliczeń wykryto ręczne korekty rejestrów.
			|Korygowanie jest możliwe tylko za pomocą ręcznej korekty rejestrów.';
			|tr = 'Belirtilen boyutlar ve alacak/borç nesneleri için kayıtların manuel ayarlamaları tespit edildi.
			|Düzeltme, yalnızca kayıtların manuel olarak ayarlanmasıyla mümkündür.'"));
	// The expanded balance on mutual settlements.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"CheckingExpandedBalance",
		Catalogs.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"MonthEndClosingARAPAccounting.CheckingExpandedBalance");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Số dư mở rộng theo biểu ghi hạch toán';
			|ru = 'Развернутое сальдо по регистрам взаиморасчетов';
			|en = 'Detailed balance on mutual settlement registers'; fa = 'Detailed balance on mutual settlement registers';
			|it = 'Saldo dettagliato per registri dei pagamenti reciproci';
			|pl = 'Saldo rozwinięte wg rejestrów rozliczeń wzajemnych';
			|tr = 'Mutabakat kayıtlarına göre ayrıntılı bakiye'"),
		NStr("vi = 'Nếu có số dư mở rộng khi hạch toán công nợ theo cùng một đối tượng hạch toán và đối tượng phân tích
			|có thể xuất hiện lỗi phân bổ hạch toán công nợ trong các biểu ghi tài chính.';
			|ru = 'При наличии развернутого сальдо по взаиморасчетам в рамках одного объекта расчетов и аналитики
			|могут возникать ошибки распределения взаиморасчетов в финансовых регистрах.';
			|en = 'If there is detailed balance on mutual settlements within one AR/AP and dimension object
			| errors can arise when distributing mutual settlements in financial registers.'; fa = 'If there is detailed balance on mutual settlements within one AR/AP and dimension object
			| errors can arise when distributing mutual settlements in financial registers.';
			|it = 'Se esiste un saldo dettagliato sui pagamenti reciproci nell''ambito di un oggetto di calcoli e analisi
			|possono verificarsi gli errori di allocazione dei pagamenti reciproci nei registri finanziari.';
			|pl = 'W razie obecności rozwiniętego salda wg rozliczeń wzajemnych  w ramach jednego obiektu rozliczeń i analityki
			|mogą powstać błędy rozdzielenia rozliczeń wzajemnych w rejestrach finansowych.';
			|tr = 'Aynı alacak/borç nesnesi ve boyut nesnesi içinde
			|ayrıntılı bir mutabakat bakiyesi varsa, finansal kayıtlarda mutabakatların dağılımında hatalar meydana gelebilir.'"));
		
	// Uncorrectable automatically expanded balance on mutual settlements
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"CheckingExpandedBalanceManualAdjustment",
		Catalogs.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"MonthEndClosingARAPAccounting.CheckingExpandedBalanceManualAdjustment");
		
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Số dư mở rộng theo biểu ghi hạch toán';
			|ru = 'Развернутое сальдо по регистрам взаиморасчетов';
			|en = 'Detailed balance on mutual settlement registers'; fa = 'Detailed balance on mutual settlement registers';
			|it = 'Saldo dettagliato per registri dei pagamenti reciproci';
			|pl = 'Saldo rozwinięte wg rejestrów rozliczeń wzajemnych';
			|tr = 'Mutabakat kayıtlarına göre ayrıntılı bakiye'"),
		NStr("vi = 'Nếu có số dư mở rộng khi hạch toán công nợ theo cùng một đối tượng hạch toán và đối tượng phân tích
			|có thể xuất hiện lỗi phân bổ hạch toán công nợ trong các biểu ghi tài chính.';
			|ru = 'При наличии развернутого сальдо по взаиморасчетам в рамках одного объекта расчетов и аналитики
			|могут возникать ошибки распределения взаиморасчетов в финансовых регистрах.';
			|en = 'If there is detailed balance on mutual settlements within one AR/AP and dimension object
			| errors can arise when distributing mutual settlements in financial registers.'; fa = 'If there is detailed balance on mutual settlements within one AR/AP and dimension object
			| errors can arise when distributing mutual settlements in financial registers.';
			|it = 'Se esiste un saldo dettagliato sui pagamenti reciproci nell''ambito di un oggetto di calcoli e analisi
			|possono verificarsi gli errori di allocazione dei pagamenti reciproci nei registri finanziari.';
			|pl = 'W razie obecności rozwiniętego salda wg rozliczeń wzajemnych  w ramach jednego obiektu rozliczeń i analityki
			|mogą powstać błędy rozdzielenia rozliczeń wzajemnych w rejestrach finansowych.';
			|tr = 'Aynı alacak/borç nesnesi ve boyut nesnesi içinde
			|ayrıntılı bir mutabakat bakiyesi varsa, finansal kayıtlarda mutabakatların dağılımında hatalar meydana gelebilir.'"));
	
EndProcedure

Procedure CheckingSettlementBalances(CheckParameters) Export
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		Return;
	EndIf;
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("PaymentType_", NStr("vi = 'Kiểu thanh toán';
										|ru = 'Тип расчетов';
										|en = 'Payment type'; fa = 'نوع پرداخت';
										|it = 'Tipo di regolamento';
										|pl = 'Typ rozliczeń';
										|tr = 'Ödeme tipi'"));
	FieldList.Add("Organization");
	FieldList.Add("AccountingDimensionByPartners", NStr("vi = 'Chỉ số hạch toán theo bạn hàng';
														|ru = 'Аналитика учета по партнерам';
														|en = 'Accounting dimension by partners'; fa = 'بُعد حسابداری بر اساس شرکای تجاری';
														|it = 'Contabilità analitica per partner';
														|pl = 'Analityka ewidencji według partnerów';
														|tr = 'İş ortaklarına göre hesap boyutu'"));
	FieldList.Add("ARAPObject",            NStr("vi = 'Đối tượng tính toán';
												|ru = 'Объект расчетов';
												|en = 'AR/AP object'; fa = 'موضوع دریافتنی/پرداختنی';
												|it = 'Oggetto di regolamenti';
												|pl = 'Obiekt rozliczeń';
												|tr = 'Alacak/Borç nesnesi'"));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTIncorrectSettlementBalances",
		NStr("vi = 'Sửa chữa số dư không chính xác trên sổ Máy tính tiền của các khoản khấu trừ thanh toán vào đầu kỳ %2.';
			|ru = 'Исправление некорректных остатков по финансовым регистрам взаиморасчетов на начало периода %2.';
			|en = 'Correction of incorrect opening balances on financial mutual settlement registers %2.'; fa = 'Correction of incorrect opening balances on financial mutual settlement registers %2.';
			|it = 'Correzione di saldi errati sui registri finanziari delle transazioni reciproche all''inizio del periodo %2.';
			|pl = 'Korekta niepoprawnych sald wg rejestrów finansowych rozliczeń wzajemnych na początek okresu %2.';
			|tr = '%2 döneminin başında finansal mutabakat kayıtlarındaki hatalı bakiyelerin düzeltilmesi.'"),
		FieldList,,);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
	
EndProcedure

Procedure CheckingSettlementBalancesManualAdjustment(CheckParameters) Export
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		Return;
	EndIf;
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("PaymentType_", NStr("vi = 'Kiểu hạch toán';
										|ru = 'Тип расчетов';
										|en = 'Payment type'; fa = 'نوع پرداخت';
										|it = 'Tipo di regolamento';
										|pl = 'Typ rozliczeń';
										|tr = 'Ödeme tipi'"));
	FieldList.Add("Organization");
	FieldList.Add("AccountingDimensionByPartners", NStr("vi = 'Chỉ số hạch toán theo bạn hàng';
														|ru = 'Аналитика учета по партнерам';
														|en = 'Accounting dimension by partners'; fa = 'بُعد حسابداری بر اساس شرکای تجاری';
														|it = 'Contabilità analitica per partner';
														|pl = 'Analityka ewidencji według partnerów';
														|tr = 'İş ortaklarına göre hesap boyutu'"));
	FieldList.Add("ARAPObject",            NStr("vi = 'Đối tượng hạch toán';
												|ru = 'Объект расчетов';
												|en = 'AR/AP object'; fa = 'موضوع دریافتنی/پرداختنی';
												|it = 'Oggetto di regolamenti';
												|pl = 'Obiekt rozliczeń';
												|tr = 'Alacak/Borç nesnesi'"));
	FieldList.Add("ManualAdjustment",       NStr("vi = 'Điều chỉnh thủ công các biểu ghi';
												|ru = 'Ручная корректировка регистров';
												|en = 'Manual register adjustment'; fa = 'Manual register adjustment';
												|it = 'Correzione manuale dei registri';
												|pl = 'Ręczna korekta rejestrów';
												|tr = 'Manuel düzeltme kaydı'"));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTIncorrectSettlementBalancesManualAdjustments",
		NStr("vi = 'Chú ý! Cần chỉnh sửa số dư hạch toán công nợ. Không thể chỉnh sửa số dư tự động, bởi vì đã nhập chứng từ sai ""Điều chỉnh biểu ghi""';
			|ru = 'Внимание! Требуется исправление остатков взаиморасчетов. Исправить остатки автоматически невозможно, так как введен некорректный документ ""Корректировка регистров""';
			|en = 'Warning. Correct AR/AP balance. Cannot correct the balance automatically as the incorrect ""Register adjustment"" document is entered'; fa = 'Warning. Correct AR/AP balance. Cannot correct the balance automatically as the incorrect ""Register adjustment"" document is entered';
			|it = 'Attenzione! È richiesta la correzione dei saldi dei conti reciproci. Non è possibile correggere i saldi automaticamente, poiché è inserito il documento ""Correzione registri"" errato';
			|pl = 'Uwaga! Wymagana jest korekta sald rozliczeń wzajemnych. Nie można skorygować salda automatycznie, ponieważ jest wprowadzony niepoprawny dokument ""Korekta rejestrów""';
			|tr = 'Dikkat! Mutabakat bakiyelerinin düzeltilmesi gerekmektedir. Hatalı bir ""Düzeltme kaydı"" belgesi girildiği için bakiyelerin otomatik olarak düzeltilmesi mümkün değildir'"),
		FieldList,,);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
	
EndProcedure

Procedure CheckingExpandedBalance(CheckParameters) Export 
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		Return;
	EndIf;
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("PaymentType_", NStr("vi = 'Kiểu thanh toán';
										|ru = 'Тип расчетов';
										|en = 'Payment type'; fa = 'نوع پرداخت';
										|it = 'Tipo di regolamento';
										|pl = 'Typ rozliczeń';
										|tr = 'Ödeme tipi'"));
	FieldList.Add("Organization");
	FieldList.Add("AccountingDimensionByPartners", NStr("vi = 'Chỉ số hạch toán theo bạn hàng';
														|ru = 'Аналитика учета по партнерам';
														|en = 'Accounting dimension by partners'; fa = 'بُعد حسابداری بر اساس شرکای تجاری';
														|it = 'Contabilità analitica per partner';
														|pl = 'Analityka ewidencji według partnerów';
														|tr = 'İş ortaklarına göre hesap boyutu'"));
	FieldList.Add("ARAPObject",            NStr("vi = 'Đối tượng tính toán';
												|ru = 'Объект расчетов';
												|en = 'AR/AP object'; fa = 'موضوع دریافتنی/پرداختنی';
												|it = 'Oggetto di regolamenti';
												|pl = 'Obiekt rozliczeń';
												|tr = 'Alacak/Borç nesnesi'"));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTExpandedBalanceOfSettlements",
		NStr("vi = 'Sửa chữa số dư mở rộng của sổ Máy tính tiền của các khoản khấu trừ thanh toán vào đầu kỳ %2.';
			|ru = 'Исправление развернутого сальдо по финансовым регистрам взаиморасчетов на начало периода %2.';
			|en = 'Correction of detailed opening balance on financial mutual settlement registers %2.'; fa = 'Correction of detailed opening balance on financial mutual settlement registers %2.';
			|it = 'Correzione di saldo dettagliato sui registri finanziari delle transazioni reciproche all''inizio del periodo %2.';
			|pl = 'Korekta rozwiniętego salda wg rejestrów finansowych rozliczeń wzajemnych na początek okresu %2.';
			|tr = '%2 döneminin başındaki finansal mutabakat kayıtlarının ayrıntılı bakiyesinin düzeltilmesi.'"),
		FieldList,,);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
		
EndProcedure

Procedure CheckingExpandedBalanceManualAdjustment(CheckParameters) Export 
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		Return;
	EndIf;
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("PaymentType_", NStr("vi = 'Kiểu hạch toán';
										|ru = 'Тип расчетов';
										|en = 'Payment type'; fa = 'نوع پرداخت';
										|it = 'Tipo di regolamento';
										|pl = 'Typ rozliczeń';
										|tr = 'Ödeme tipi'"));
	FieldList.Add("Organization");
	FieldList.Add("AccountingDimensionByPartners", NStr("vi = 'Chỉ số hạch toán theo bạn hàng';
														|ru = 'Аналитика учета по партнерам';
														|en = 'Accounting dimension by partners'; fa = 'بُعد حسابداری بر اساس شرکای تجاری';
														|it = 'Contabilità analitica per partner';
														|pl = 'Analityka ewidencji według partnerów';
														|tr = 'İş ortaklarına göre hesap boyutu'"));
	FieldList.Add("ARAPObject",            NStr("vi = 'Đối tượng hạch toán';
												|ru = 'Объект расчетов';
												|en = 'AR/AP object'; fa = 'موضوع دریافتنی/پرداختنی';
												|it = 'Oggetto di regolamenti';
												|pl = 'Obiekt rozliczeń';
												|tr = 'Alacak/Borç nesnesi'"));
	FieldList.Add("ManualAdjustment",       NStr("vi = 'Điều chỉnh thủ công các biểu ghi';
												|ru = 'Ручная корректировка регистров';
												|en = 'Manual register adjustment'; fa = 'Manual register adjustment';
												|it = 'Correzione manuale dei registri';
												|pl = 'Ręczna korekta rejestrów';
												|tr = 'Manuel düzeltme kaydı'"));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTExpandedBalanceOfSettlementsManualAdjustments",
		NStr("vi = 'Chú ý! Cần chỉnh sửa số dư mở chi tiết. Không thể tự động chỉnh sửa, bởi vì đã nhập chứng từ sai ""Điều chỉnh biểu ghi""';
			|ru = 'Внимание! Требуется исправление развернутого сальдо. Исправить автоматически невозможно, так как введен некорректный документ ""Корректировка регистров""';
			|en = 'Warning. Credit and debit balance correction is required. Cannot correct automatically as the incorrect document ""Register adjustment"" is entered'; fa = 'Warning. Credit and debit balance correction is required. Cannot correct automatically as the incorrect document ""Register adjustment"" is entered';
			|it = 'Attenzione! È richiesta la correzione del saldo aperto. Non è possibile correggerlo automaticamente, poiché è inserito il documento ""Correzione registri"" errato';
			|pl = 'Uwaga! Wymagana jest korekta salda rozwiniętego. Nie można skorygować automatycznie, ponieważ jest wprowadzony niepoprawny dokument ""Korekta rejestrów""';
			|tr = 'Dikkat! Ayrıntılı bakiye düzeltmesi gereklidir. Hatalı bir ""Düzeltme kaydı"" belgesi girildiği için otomatik olarak düzeltmek imkansızdır'"),
		FieldList,,);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
		
EndProcedure

Procedure Perform_GenerationOfRegisteredRecordsForPartnersARAPAccountingAndRevaluationOfCalculations(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
		CalculationAnalysts.Companies = CalculationParameters.CompanyArray;
		
		ARAPAllocationServerCall.CalculateEverything(CalculationParameters.EndOfPeriod, CalculationAnalysts);
		
		//Revaluation at the end of the month or by days if there were no settlements
		Documents.ExchangeDifferenceCalculation.ReassessCustomerSettlements(
			CalculationParameters.CompanyArray,
			CalculationParameters.RegistrationPeriod);
		Documents.ExchangeDifferenceCalculation.ReassessSettlementsWithSuppliers(
			CalculationParameters.CompanyArray,
			CalculationParameters.RegistrationPeriod);
		
	Else
		
		CalculationParameters = HandlerParameters.CalculationParameters;
	
		CalculationStart = MonthEndTransactionsServer.CalculationStart(
			HandlerParameters.Data_Stage.Code,
			CalculationParameters.EndOfPeriod,
			,
			CalculationParameters.CompanyArray);
			
		KeyOperationName = StringFunctionsClientServer.SubstituteParametersToString(
				"MonthEndTransactions.%1",
				TrimAll(HandlerParameters.Data_Stage.Code));
		MeasurementDetails 		= PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperationName);
		DataVolume	= 0;
		
		ReEvaluationRequired = MonthEndTransactionsServer.GetAdditionalHandlerProperty(HandlerParameters, "ReEvaluationRequired", False);
		ThereIsTaskForCalculation = (CalculationStart <= CalculationParameters.EndOfPeriod);
		If ReEvaluationRequired And Not ThereIsTaskForCalculation Then
			CalculationStart = CalculationParameters.EndOfPeriod; // recalculate only the specified month
		EndIf;
		
		While CalculationStart <= HandlerParameters.CalculationParameters.EndOfPeriod Do
		
			JobNumber 	 	= MonthEndTransactionsServer.IncreaseTaskNumber();
			PeriodEnding 	= EndOfMonth(CalculationStart);
			AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationStart, CalculationParameters.CompanyArray);
			
			BeginTransaction();
			
			Try
				
				MonthEndTransactionsServer.BlockTaskRegister(
					JobNumber,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				CalculationDataForMonth = MonthEndTransactionsServer.MonthlyTasks(
					CalculationStart,
					PeriodEnding,
					JobNumber,
					AvailableCompanies,
					HandlerParameters.Data_Stage.Code);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
						|%2';
						|ru = 'При выполнении расчета за период %1 произошла ошибка:
						|%2';
						|en = 'An error occurred when calculating for the %1 period:
						|%2'; fa = 'An error occurred when calculating for the %1 period:
						|%2';
						|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
						|%2';
						|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
						|%2';
						|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
						|%2'", Common.DefaultLanguageCode()),
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					AvailableCompanies,
					CalculationStart);
				
			EndTry;
			
			//Bug fixes.
			
			ARAPAccountingInternal.FixSettlementBalances(CalculationStart, CalculationDataForMonth.Organization);
			ARAPAccountingInternal.CorrectReversedBalance(CalculationStart, CalculationDataForMonth.Organization);
			
			For Each Organization In CalculationDataForMonth.Organization Do
				//Revaluation at the end of the month or by days if there were no settlements
				Documents.ExchangeDifferenceCalculation.ReassessCustomerSettlements(
					Organization, PeriodEnding);
				Documents.ExchangeDifferenceCalculation.ReassessSettlementsWithSuppliers(
					Organization, PeriodEnding);
			EndDo;
			
			MonthEndTransactionsServer.DeleteTasksToBeCalculatedForCurPeriod(HandlerParameters, CalculationDataForMonth);
			
			ReEvaluationRequired = Documents.ExchangeDifferenceCalculation.RequiresReassessmentOfSettlements(
				AvailableCompanies,
				PeriodEnding);
			
			If ReEvaluationRequired Then
				Documents.ExchangeDifferenceCalculation.ReassessCustomerSettlements(
					AvailableCompanies,
					PeriodEnding);
				Documents.ExchangeDifferenceCalculation.ReassessSettlementsWithSuppliers(
					AvailableCompanies,
					PeriodEnding);
			EndIf;
			
			CalculationStart = PeriodEnding + 1;
			
		EndDo;
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
		
	EndIf;
	
EndProcedure

#Region RequestTextsForTasksAtEndOfMonth

// Parameters:
//   Query - Query
//
// Returns:
//   See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
//
Function QueryTextCustomersARAPAccounting(Query) Export
	
	If Not Query.Parameters.Property("NewCalculations") Then
		Query.SetParameter("NewCalculations", GetFunctionalOption("NewOnlineARAPAccounting"));
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	CASE WHEN Table.CreateTasksByEndOfNextMonth
	|		THEN DATEADD(Table.Month, MONTH, 1)
	|		ELSE Table.Month
	|	END AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Document Document
	|FROM 
	|	ChangesTableCustomersARAPAccounting AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_
EndFunction

// Parameters:
//   Query - Query
//
// Returns:
//   See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
//
Function QueryTextVendorsARAPAccounting(Query) Export
	
	If Not Query.Parameters.Property("NewCalculations") Then
		Query.SetParameter("NewCalculations", GetFunctionalOption("NewOnlineARAPAccounting"));
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	CASE WHEN Table.CreateTasksByEndOfNextMonth
	|		THEN DATEADD(Table.Month, MONTH, 1)
	|		ELSE Table.Month
	|	END AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Document AS Document
	|FROM
	|	ChangesTableVendorsARAPAccounting AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_
EndFunction

// Parameters:
//   Query - Query
//
// Returns:
//   See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
//
Function QueryTextDocumentAmountsInAccountingCurrency(Query) Export
	
	QueryText = "
	|SELECT DISTINCT
	|	CASE WHEN Table.CreateTasksByEndOfNextMonth
	|		THEN BEGINOFPERIOD(DATEADD(Table.Period, MONTH, 1), MONTH)
	|		ELSE BEGINOFPERIOD(Table.Period, MONTH)
	|	END AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation) AS Operation,
	|	Table.ARAPObject.Organization AS Organization,
	|	Table.Recorder AS Document
	|FROM
	|	AmountsOfDocumentsInCurrenciesOfChangeAccounting AS Table
	|WHERE
	|	Table.RecalculateBasedOnARAPData
	|	AND NOT Table.ARAPObject.Organization IS NULL 
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_
EndFunction

// Parameters:
//   Query - Query
//
// Returns:
//   See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
//
Function QueryTextVendorsARAPAccountingByDueDates(Query) Export
	
	TempTablesQueryText = "SELECT
	|	VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDueDates.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingByDueDates.OccurrenceDate AS OccurrenceDate,
	|	VendorsARAPAccountingByDueDates.Debt AS Debt,
	|	CASE
	|		WHEN VendorsARAPAccountingByDueDates.OccurrenceDate > VendorsARAPAccountingByDueDates.PlannedRepaymentDate
	|			THEN 0
	|		ELSE DATEDIFF(VendorsARAPAccountingByDueDates.OccurrenceDate, VendorsARAPAccountingByDueDates.PlannedRepaymentDate, DAY)
	|	END AS DeferredPayment,
	|	DimensionKeysOfAccountingByPartners.Contract AS Contract,
	|	DimensionKeysOfAccountingByPartners.Organization AS Organization,
	|	Companies.ParentCompany AS ParentCompany,
	|	BEGINOFPERIOD(VendorsARAPAccountingByDueDates.Period, MONTH) AS Month,
	|	VendorsARAPAccountingByDueDates.DocumentRecorder AS DocumentRecorder,
	|	VendorsARAPAccountingByDueDates.CreateTasksByEndOfNextMonth AS CreateTasksByEndOfNextMonth
	|INTO TTPaymentSchedule
	|FROM
	|	ChangesTableVendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			INNER JOIN Catalog.Companies AS Companies
	|			ON DimensionKeysOfAccountingByPartners.Organization = Companies.Ref
	|		ON VendorsARAPAccountingByDueDates.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|WHERE
	|	VALUETYPE(VendorsARAPAccountingByDueDates.ARAPDocument) IN (&TypesOfDocumentsInvolvedInDiscounting)
	|	AND VALUETYPE(VendorsARAPAccountingByDueDates.DocumentRecorder) <> TYPE(Document.ExchangeDifferenceCalculation)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentSchedule.OccurrenceDate AS OccurrenceDate,
	|	MAX(FinancialAccountingPolicy.Period) AS Period,
	|	FinancialAccountingPolicy.Organization AS Organization
	|INTO TTAccountingPolicyPeriods
	|FROM
	|	TTPaymentSchedule AS TTPaymentSchedule
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS FinancialAccountingPolicy
	|		ON TTPaymentSchedule.ParentCompany = FinancialAccountingPolicy.Organization
	|			AND TTPaymentSchedule.OccurrenceDate >= FinancialAccountingPolicy.Period
	|
	|GROUP BY
	|	TTPaymentSchedule.OccurrenceDate,
	|	FinancialAccountingPolicy.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccountingPolicyPeriods.OccurrenceDate AS OccurrenceDate,
	|	TTAccountingPolicyPeriods.Period AS Period,
	|	TTAccountingPolicyPeriods.Organization AS Organization
	|INTO TTAccountingPolicyForOrganizations
	|FROM
	|	TTAccountingPolicyPeriods AS TTAccountingPolicyPeriods
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS FinancialAccountingPolicy
	|		ON TTAccountingPolicyPeriods.Period = FinancialAccountingPolicy.Period
	|			AND TTAccountingPolicyPeriods.Organization = FinancialAccountingPolicy.Organization
	|WHERE
	|	FinancialAccountingPolicy.AccountingForDiscountedAccountsPayableToVendors
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	QueryText = "
	|SELECT DISTINCT
	|	CASE WHEN TTDeferral.CreateTasksByEndOfNextMonth
	|		THEN BEGINOFPERIOD(DATEADD(TTDeferral.Month, MONTH, 1), MONTH)
	|		ELSE TTDeferral.Month
	|	END AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.CalculationOfDiscountInterestExpenses) AS Operation,
	|	TTDeferral.Organization AS Organization,
	|	TTDeferral.DocumentRecorder AS Document
	|FROM
	|	TTPaymentSchedule AS TTDeferral
	|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON TTDeferral.Contract = CounterpartyContracts.Ref
	|		INNER JOIN TTAccountingPolicyForOrganizations AS TTAccountingPolicyForOrganizations
	|		ON TTDeferral.ParentCompany = TTAccountingPolicyForOrganizations.Organization
	|			AND TTDeferral.OccurrenceDate = TTAccountingPolicyForOrganizations.OccurrenceDate
	|WHERE
	|	CounterpartyContracts.DiscountRate > 0
	|	AND CounterpartyContracts.ApplicationDiscountingPeriod < TTDeferral.DeferredPayment";
	
	TemporaryTable = "TTPaymentSchedule, TTAccountingPolicyPeriods, TTAccountingPolicyForOrganizations";
	
	Query.SetParameter("TypesOfDocumentsInvolvedInDiscounting", AccumulationRegisters.DiscountInterestExpense.GetTypesOfDocumentsInvolvedInDiscounting());
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(
		QueryText,
		TempTablesQueryText,
		TemporaryTable);
	
	Return StructureOfQueryTexts_
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function MatchingRequestsToControlRegisters(Query)
	
	MatchingQueryTexts = New Map();
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		MatchingQueryTexts.Insert("ChangesTableCustomersARAPAccounting", QueryTextCustomersARAPAccounting(Query));
		MatchingQueryTexts.Insert("ChangesTableVendorsARAPAccounting", QueryTextVendorsARAPAccounting(Query));
		MatchingQueryTexts.Insert("AmountsOfDocumentsInCurrenciesOfChangeAccounting", QueryTextDocumentAmountsInAccountingCurrency(Query));
		MatchingQueryTexts.Insert("ChangesTableVendorsARAPAccountingByDueDates", QueryTextVendorsARAPAccountingByDueDates(Query));
	EndIf;
	Return MatchingQueryTexts;
	
EndFunction

#EndRegion