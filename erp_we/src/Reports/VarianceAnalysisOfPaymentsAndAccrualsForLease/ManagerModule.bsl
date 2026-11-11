#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   VariantKey - String -
//
// Returns:
//  ValueTableRow, Undefined - added command or Undefined if there are no rights to view the report.
//
Function AddReportCommand(ReportsCommands, VariantKey = "") Export
	
	Result = Undefined;
	
	If AccessRight("View", Metadata.Reports.VarianceAnalysisOfPaymentsAndAccrualsForLease) Then
		
		ReportCommand = ReportsCommands.Add();
		ReportCommand.Manager = Metadata.Reports.VarianceAnalysisOfPaymentsAndAccrualsForLease.FullName();
		ReportCommand.Presentation = NStr("vi = 'Phân tích kế hoạch thực tế';
											|ru = 'План-фактный анализ';
											|en = 'Variance analysis'; fa = 'Variance analysis';
											|it = 'Analisi degli indicatori preventivati e effettivi';
											|pl = 'Analiza planowa-faktyczna';
											|tr = 'Plan-gerçek analizi'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		If ValueIsFilled(VariantKey) Then
			ReportCommand.VariantKey = VariantKey;
		EndIf;
		Result = ReportCommand;
	EndIf;
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VarianceAnalysisOfPaymentsAndAccrualsForLease);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích chênh lệch thanh toán thực tế và tính lãi trong khuôn khổ hợp đồng thuê (cho thuê).';
									|ru = 'Анализ отклонений по фактически произведенным оплатам и начислениям в рамках договоров аренды (лизинга).';
									|en = 'Analyze variances in actually made payments and accruals under rental (financial lease) contracts.'; fa = 'Analyze variances in actually made payments and accruals under rental (financial lease) contracts.';
									|it = 'Анализ отклонений по фактически произведенным оплатам и начислениям в рамках договоров аренды (лизинга).';
									|pl = 'Analiz odchyleń wg faktycznie wykonanych płatności i naliczeń w ramach umów dzierżawy (leasingu).';
									|tr = 'Kira (finansal kiralama) sözleşmeleri kapsamında fiilen yapılan ödemeler ve tahakkuklara ilişkin sapmaların analizi.'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByCustomerContract");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf