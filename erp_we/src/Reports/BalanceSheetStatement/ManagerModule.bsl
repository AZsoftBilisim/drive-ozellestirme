#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Checks whether the cost calculation is up-to-date and
// displays a warning label in the table document of the report.
//
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer - Report settings Builder
//  ResultDocument - SpreadsheetDocument - table document of the report result.
//
Procedure DisplayReportRelevance(SettingsComposer, ResultDocument) Export
	
	CompanyArray = Undefined;
	FilterOrganizations = FinancialReportingServer.FindSelectionElement(SettingsComposer.Filter,"Organization");
	If TypeOf(FilterOrganizations) = Type("DataCompositionFilterItem") And FilterOrganizations.Use Then
		If TypeOf(FilterOrganizations.RightValue) = Type("ValueList") Then
			CompanyArray = FilterOrganizations.RightValue.UnloadValues();
		Else
			CompanyArray = TMCommonUseClientServer.Array(FilterOrganizations.RightValue);
		EndIf;
	EndIf;
	
	ReportPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportPeriod").Value; // StandardPeriod - 
	CalculationState = CostCalculationAppliedAlgorithms.CurStateOfCalculation(
							ReportPeriod.EndDate, CompanyArray, Catalogs.MonthEndClosingOperations.LotsAndCostCalculation);
	DistributionOfMutualSettlementsIsExecuted = GetFunctionalOption("NewOnlineARAPAccounting") 
											Or MutualSettlementsAreRelevant(CompanyArray, ReportPeriod);
	
	WarningText = "";
	SetPrivilegedMode(True);
	AssetLiabilityRecordsArePopulated = Constants.AssetLiabilityRecordsArePopulated.Get();
	If Not AssetLiabilityRecordsArePopulated Then
		WarningText = NStr("vi = 'Để làm việc với báo cáo sau khi cập nhật cấu hình lên phiên bản mới, cần điền dữ liệu ban đầu về các dạng tài sản và nguồn vốn.
								|Để thực hiện điều này, cần thực hiện lệnh cùng tên từ phân hệ Danh mục và quản trị - Kết quả kinh doanh và kiểm soát.';
								|ru = 'Для работы отчета после обновления конфигурации на новую редакцию требуется выполнить первоначальное заполнение данных по статьям активов и пассивов.
								|Для этого необходимо выполнить одноименную команду из раздела НСИ и администрирование - Финансовый результат и контроллинг.';
								|en = 'To work with the report after the configuration is updated up to a new version, execute initial filling of the data according to asset and liability items.
								|To do so, execute the same command from Master data and settings - Profitability & cost.'; fa = 'To work with the report after the configuration is updated up to a new version, execute initial filling of the data according to asset and liability items.
								|To do so, execute the same command from Master data and settings - Profitability & cost.';
								|it = 'Affinché il report funzioni, dopo aver aggiornato la configurazione alla nuova edizione, è necessario eseguire la compilazione iniziale dei dati sugli elementi delle attività e delle passività
								|.Per fare questo, è necessario eseguire il comando omonimo dalla sezione NSI e amministrazione - Risultato finanziario e controllo.';
								|pl = 'Aby raport działał, po zaktualizowaniu konfiguracji do nowego wydania, konieczne jest przeprowadzenie wstępnego wypełniania danych wg pozycji aktywów i pasywów.
								|Aby to zrobić, musisz uruchomić polecenie o tej samej nazwie z sekcji Ustawienia – Wynik finansowy i kontrolowanie.';
								|tr = 'Konfigürasyon yeni bir revizyona yükseltildikten sonra raporun çalışması için, varlık ve yükümlülük kalemlerine göre ilk veri doldurma işleminin yapılması gerekir.
								|Bunu gerçekleştirmek için, Master veri ve yönetim - Finansal sonuçlar ve kontrol bölümünden aynı isimli komutu çalıştır.'");
	ElsIf ThereAreTasksOfNonOperationalQueueReflectingRegisteredRecordsOnManagementBalanceSheet(CompanyArray, ReportPeriod) Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Данные отчета могут быть не актуальны, так как имеются невыполненные задания неоперативной очереди с видом ""%1"" (регистр ""%2"")';
						|vi = 'The report data may not be up to date, as there are uncompleted backdate queue jobs with the ""%1"" type (the ""%2"" register)';
						|en = 'The report data may not be up to date, as there are uncompleted backdate queue jobs with the ""%1"" type (the ""%2"" register)'; fa = 'The report data may not be up to date, as there are uncompleted backdate queue jobs with the ""%1"" type (the ""%2"" register)';
						|it = 'The report data may not be up to date, as there are uncompleted backdate queue jobs with the ""%1"" type (the ""%2"" register)';
						|pl = 'The report data may not be up to date, as there are uncompleted backdate queue jobs with the ""%1"" type (the ""%2"" register)';
						|tr = 'Rapor verileri güncel olmayabilir, çünkü ""%1"" türünde (""%2"" kaydında) operasyonel olmayan kuyrukta yürütülmemiş görevler bulunmaktadır.'", Common.DefaultLanguageCode()),
					Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords,
					Metadata.InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.Synonym);
	ElsIf CalculationState = Enums.StatesOfMonthEndClosingOperations.DoneWithErrors
				Or CalculationState = Enums.StatesOfMonthEndClosingOperations.NotCompleted
				Or Not DistributionOfMutualSettlementsIsExecuted Then
		WarningText = NStr("vi = 'Dữ liệu báo cáo có thể không liên quan, vì không phải tất cả các giai đoạn của tháng đóng cửa đã hoàn thành, ảnh hưởng đến Kết quả kinh doanh trong kế toán quản trị.';
							|ru = 'Данные отчета могут быть не актуальны, так как выполнены не все этапы закрытия месяца, влияющие на финансовый результат в управленческом учете.';
							|en = 'Report data may be irrelevant as not all month-end closing stages that influence the financial result in management accounting are executed.'; fa = 'Report data may be irrelevant as not all month-end closing stages that influence the financial result in management accounting are executed.';
							|it = 'I dati del rapporto potrebbero non essere aggiornati, dal momento che non tutte le fasi della chiusura del mese influiscono sul risultato finanziario della contabilità gestionale.';
							|pl = 'Dane z raportu mogą być nie aktualne, ponieważ nie są spełnione wszystkie etapy zamknięcia miesiąca, wpływające na wynik finansowy w ewidencji zarządczej.';
							|tr = 'Yönetim muhasebesinde finansal sonucu etkileyen ay sonu kapanışının tüm aşamaları gerçekleştirilmediği için rapor verileri güncel olmayabilir.'");
	EndIf;
	
	If Not IsBlankString(WarningText) Then
		WarningTable_ = New SpreadsheetDocument;
		AreaWarning = WarningTable_.Area(1,1,1,1);
		AreaWarning.Text = WarningText;
		AreaWarning.TextColor = StyleColors.NegativeTextColor;
		ResultDocument.InsertArea(AreaWarning, ResultDocument.Area(1,1,1,1), SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
EndProcedure

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BalanceSheetStatement);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích các chỉ tiêu tài chính vào đầu, cuối kỳ và các biến động.';
									|ru = 'Анализ финансовых показателей на начало и конец периода и их изменения.';
									|en = 'Analysis of financial indicators on the period start and end, and their changes.'; fa = 'Analysis of financial indicators on the period start and end, and their changes.';
									|it = 'Анализ финансовых показателей на начало и конец периода и их изменения.';
									|pl = 'Analiza wskaźników finansowych na początek i koniec okresu i ich zmiany.';
									|tr = 'Dönem başı ve dönem sonu finansal göstergelerin analizi ve değişimleri.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "BalanceSheetStatement");
	OptionDetails.LongDesc = NStr("vi = 'Các chỉ tiêu tài chính nào theo dạng tài sản và nguồn vốn?
		|Các chỉ tiêu tài chính nào theo doanh nghiệp và bộ phận?
		|Có vi phạm tính cân đối hay không?';
		|ru = 'Каковы финансовые показатели по статьям активов и пассивов?
		|Каковы финансовые показатели по организациям и подразделениям?
		|Есть ли нарушение баланса?';
		|en = 'Verify financial indicators of items of assets and liabilities.
		|Check financial indicators of companies and business units.
		|Verify if there is balance violation.'; fa = 'Verify financial indicators of items of assets and liabilities.
		|Check financial indicators of companies and business units.
		|Verify if there is balance violation.';
		|it = 'Каковы финансовые показатели по статьям активов и пассивов?
		|Каковы финансовые показатели по организациям и подразделениям?
		|Есть ли нарушение баланса?';
		|pl = 'Jakie są wskaźniki finansowe według pozycji aktywów i zobowiązań?
		|Jakie są wskaźniki finansowe według firm i działów? 
		|Czy istnieje naruszenie bilansu?';
		|tr = 'Varlıklar ve yükümlülükler kalemleri için finansal göstergeler nelerdir?
		|İş yerleri ve departmanlar için finansal göstergeler nelerdir?
		|Bakiye tutarsızlığı var mıdır?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ManBalanceByDirections");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát các chỉ số tài chính trong các lĩnh vực và điều khoản của tài sản/nguồn vốn.';
									|ru = 'Контроль финансовых показателей по направлениям и статьям активов/пассивов.';
									|en = 'Control over financial indicators by lines of business and asset/liability items.'; fa = 'Control over financial indicators by lines of business and asset/liability items.';
									|it = 'Контроль финансовых показателей по направлениям и статьям активов/пассивов.';
									|pl = 'Kontrola wskaźników finansowych według kierunków i pozycji aktywów /zobowiązań.';
									|tr = 'İş kollarına ve varlık/yükümlülük kalemlerine göre finansal göstergelerin kontrolü.'");
	OptionDetails.FunctionalOptions.Add("EnterpriseManagement");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ManBalanceByCompanies");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát các chỉ số tài chính cho các doanh nghiệp và mặt hàng của tài sản/nguồn vốn.';
									|ru = 'Контроль финансовых показателей по организациям и статьям активов/пассивов.';
									|en = 'Control over financial indicators by companies and  asset/liability items.'; fa = 'Control over financial indicators by companies and  asset/liability items.';
									|it = 'Контроль финансовых показателей по организациям и статьям активов/пассивов.';
									|pl = 'Kontrola wskaźników finansowych według firm i pozycji aktywów /zobowiązań.';
									|tr = 'İş yerlerine ve varlık/yükümlülük kalemlerine göre finansal göstergelerin kontrolü.'");
	OptionDetails.FunctionalOptions.Add("EnterpriseManagement");
	
EndProcedure

#EndRegion

#EndRegion

// Parameters:
// 	Companies - Array, Undefined - LongDesc
// 	ReportPeriod - StandardPeriod - 
// Returns:
// 	Boolean - LongDesc
Function MutualSettlementsAreRelevant(Companies, ReportPeriod)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Calculations.AccountingDimensionByPartners
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Analysts
	|	ON Calculations.AccountingDimensionByPartners = Analysts.Ref
	|WHERE
	|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (Analysts.Organization IN (&CompanyArray) OR &ByAllCompanies)
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
	|	AND (Analysts.Organization IN (&CompanyArray) OR &ByAllCompanies)
	|	AND Calculations.Active";
	
	Query.SetParameter("BeginOfPeriod", ReportPeriod.StartDate);
	Query.SetParameter("EndOfPeriod", ReportPeriod.EndDate);
	Query.SetParameter("CompanyArray", Companies);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Companies));
	
	CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
	CalculationAnalysts.Companies = Companies;
	
	CalculationStart = ARAPAllocationServerCall.StartOfCalculations(EndOfMonth(ReportPeriod.EndDate), CalculationAnalysts);
	
	ThereAreRegisteredRecordsAccordingToCalculations = Not Query.Execute().IsEmpty();
	PeriodInRecalculationRange = (ValueIsFilled(CalculationStart) And CalculationStart <= ReportPeriod.EndDate);

	Return (ThereAreRegisteredRecordsAccordingToCalculations And Not PeriodInRecalculationRange) Or Not ThereAreRegisteredRecordsAccordingToCalculations;
	
EndFunction

#Region Private

// Checks the availability of non-operational queue tasks to reflect Registered Records on the management balance sheet for the period.
//
// Parameters:
//  Companies - Undefined, Array of CatalogRef.Companies - list of organizations to check
//  ReportPeriod - StandardPeriod - the period for which the check is performed.
//
// Returns:
//   Boolean - True if there is at least one task.
Function ThereAreTasksOfNonOperationalQueueReflectingRegisteredRecordsOnManagementBalanceSheet(Companies, ReportPeriod)
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	TRUE AS HasJobs
	|FROM
	|	InformationRegister.JobsOfBackdateAdditionalDocumentPosting AS QueueRegister
	|WHERE
	|	QueueRegister.JobKind = VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords)
	|	AND QueueRegister.TaskPeriod <= &EndOfPeriod
	|	AND (QueueRegister.Organization IN (&CompanyArray)
	|	OR &ByAllCompanies)";
	
	Query.SetParameter("EndOfPeriod", ?(ValueIsFilled(ReportPeriod.EndDate),
		ReportPeriod.EndDate, Date(3999, 12, 31)));
	Query.SetParameter("CompanyArray", Companies);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Companies));
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

#EndRegion

#EndIf