//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ReceiptsAndExpendituresAnalysis);
	DescriptionOfReport.DefineFormSettings = True;
	
	// By company.
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "IncomeAndExpensesOfEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thu nhập và chi phí theo từng giai đoạn trong doanh nghiệp nói chung, có thể chọn đối tượng phân tích.';
									|ru = 'Постатейный анализ доходов и расходов по предприятию в целом с возможностью выбора аналитики.';
									|en = 'Itemized analysis of income and expenses by enterprise as a whole with dimension selection.'; fa = 'Itemized analysis of income and expenses by enterprise as a whole with dimension selection.';
									|it = 'Постатейный анализ доходов и расходов по предприятию в целом с возможностью выбора аналитики.';
									|pl = 'Analiza według pozycji dochodów i rozchodów według przedsiębiorstwa w całości z możliwością wyboru analityki.';
									|tr = 'Boyut seçim olanağı ile bir bütün olarak işletme için gelir ve giderlerin kalem bazında analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "EnterpriseExpenses");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi phí theo từng giai đoạn trong toàn bộ doanh nghiệp.';
									|ru = 'Постатейный анализ расходов по предприятию в целом.';
									|en = 'Itemized analysis of expenses by enterprise as a whole.'; fa = 'Itemized analysis of expenses by enterprise as a whole.';
									|it = 'Постатейный анализ расходов по предприятию в целом.';
									|pl = 'Analiza według pozycji rozchodów według przedsiębiorstwa w całości.';
									|tr = 'Bir bütün olarak işletme için giderlerin kalem bazında analizi.'");
	
	// By organizations.
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "IncomeAndExpensesForOrganizations");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thu nhập và chi phí theo từng giai đoạn trong từng doanh nghiệp cho phép lựa chọn đối tượng phân tích.';
									|ru = 'Постатейный анализ доходов и расходов предприятия в разрезе организаций с возможностью выбора аналитики.';
									|en = 'Itemized analysis of enterprise income and expenses by companies with dimension selection.'; fa = 'Itemized analysis of enterprise income and expenses by companies with dimension selection.';
									|it = 'Постатейный анализ доходов и расходов предприятия в разрезе организаций с возможностью выбора аналитики.';
									|pl = 'Analiza według pozycji dochodów i rozchodów przedsiębiorstwa w przekroju firm z możliwością wyboru analityki.';
									|tr = 'Boyut seçim olanağı ile iş yerleri bağlamında işletmenin gelir ve giderlerinin kalem bazında analizi.'");
	OptionDetails.FunctionalOptions.Add("UseAccountingOfOtherIncomeExpensesInLocalAccounting");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ExpensesOfOrganizations");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chi phí theo từng giai đoạn của tập đoàn trong từng doanh nghiệp.';
									|ru = 'Постатейный анализ расходов предприятия в разрезе организаций.';
									|en = 'Itemized analysis of enterprise expenses by companies.'; fa = 'Itemized analysis of enterprise expenses by companies.';
									|it = 'Постатейный анализ расходов предприятия в разрезе организаций.';
									|pl = 'Analiza według pozycji rozchodów przedsiębiorstwa w przekroju firm.';
									|tr = 'İş yeri kapsamında giderlerin kalem bazında analizi.'");
	OptionDetails.FunctionalOptions.Add("UseAccountingOfOtherIncomeExpensesInLocalAccounting");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "IncomeAndExpensesForEnterpriseMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thu nhập và chi phí theo từng giai đoạn trong doanh nghiệp nói chung, có thể chọn đối tượng phân tích.';
									|ru = 'Постатейный анализ доходов и расходов по предприятию в целом с возможностью выбора аналитики.';
									|en = 'Itemized analysis of income and expenses by enterprise as a whole with dimension selection.'; fa = 'Itemized analysis of income and expenses by enterprise as a whole with dimension selection.';
									|it = 'Постатейный анализ доходов и расходов по предприятию в целом с возможностью выбора аналитики.';
									|pl = 'Analiza według pozycji dochodów i rozchodów według przedsiębiorstwa w całości z możliwością wyboru analityki.';
									|tr = 'Boyut seçim olanağı ile bir bütün olarak işletme için gelir ve giderlerin kalem bazında analizi.'");
	OptionDetails.Description = NStr("vi = 'Thu nhập và chi phí của doanh nghiệp (di động)';
									|ru = 'Доходы и расходы предприятия (моб.)';
									|en = 'Income and Expenses — Enterprise (mob. client)'; fa = 'Income and Expenses — Enterprise (mob. client)';
									|it = 'Доходы и расходы предприятия (моб.)';
									|pl = 'Dochody i rozchody przedsiębiorstwa (mob.)';
									|tr = 'İşletmenin gelirleri ve giderleri (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
