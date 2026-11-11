#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//	- Undefined
//	- ValueTableRow
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ARAPReconciliationWithPartners) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Handler = "ReportsClientLocalization.ARAPReconciliationWithPartners";
		ReportCommand.Manager = Metadata.Reports.ARAPReconciliationWithPartners.FullName();
		ReportCommand.Presentation = NStr("vi = 'Đối chiếu hạch toán với tham số';
											|ru = 'Сверка расчетов с партнерами';
											|en = 'Reconciliation of AR/AP with partners'; fa = 'Reconciliation of AR/AP with partners';
											|it = 'Сверка расчетов с партнерами';
											|pl = 'Reconciliation of AR/AP with partners';
											|tr = 'İş ortakları ile alacak/borç muhasebesi mutabakatı.'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.WriteMode = "Post";
		ReportCommand.FormParameterName = "Filter.ARAPReconciliation";
		If GetFunctionalOption("BaseVersion") Then
			ReportCommand.VariantKey = "ContextBasicForARAPReconciliationsOfMutualSettlements";
		Else
			ReportCommand.VariantKey = "ARAPReconciliationCONTEXT";
		EndIf;
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ARAPReconciliationWithPartners);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ARAPReconciliation");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích đối chiếu hạch toán với khách hàng theo chứng từ.
		|Có chênh lệch giữa dữ liệu của khách hàng và chúng ta không?';
		|ru = 'Анализ задокументированных сверок расчетов с клиентами.
		|Есть ли расхождения между данными от клиента и нашими?';
		|en = 'Analysis of recorded AR/AP reconciliations with customers. 
		|Check for discrepancies between customer data and company records.'; fa = 'Analysis of recorded AR/AP reconciliations with customers. 
		|Check for discrepancies between customer data and company records.';
		|it = 'Анализ задокументированных сверок расчетов с клиентами.
		|Есть ли расхождения между данными от клиента и нашими?';
		|pl = 'Analysis of recorded AR/AP reconciliations with customers. 
		|Check for discrepancies between customer data and company records.';
		|tr = 'Müşterilerle yapılan alacak/borç muhasebesinin belgelenmiş mutabakatlarının analizi.
		|Müşteriden gelen verilerle bizim verilerimiz arasında tutarsızlıklar var mı?'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ARAPReconciliationIsBASIC");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích đối chiếu hạch toán với khách hàng theo chứng từ.
		|Có chênh lệch giữa dữ liệu của khách hàng và chúng ta không?';
		|ru = 'Анализ задокументированных сверок расчетов с клиентами.
		|Есть ли расхождения между данными от клиента и нашими?';
		|en = 'Analysis of recorded AR/AP reconciliations with customers. 
		|Check for discrepancies between customer data and company records.'; fa = 'Analysis of recorded AR/AP reconciliations with customers. 
		|Check for discrepancies between customer data and company records.';
		|it = 'Анализ задокументированных сверок расчетов с клиентами.
		|Есть ли расхождения между данными от клиента и нашими?';
		|pl = 'Analysis of recorded AR/AP reconciliations with customers. 
		|Check for discrepancies between customer data and company records.';
		|tr = 'Müşterilerle yapılan alacak/borç muhasebesinin belgelenmiş mutabakatlarının analizi.
		|Müşteriden gelen verilerle bizim verilerimiz arasında tutarsızlıklar var mı?'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ARAPReconciliationCONTEXT");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ContextBasicForARAPReconciliationsOfMutualSettlements");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf