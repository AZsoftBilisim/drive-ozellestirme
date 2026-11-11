#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AccruedExciseAmounts);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AccruedExciseAmounts");
	OptionDetails.LongDesc = NStr("vi = 'Thông tin về số tiền thuế TTĐB đã tính trong kỳ được chọn.';
									|ru = 'Информация о суммах акцизов, начисленных в выбранном периоде.';
									|en = 'Information on excise amounts accrued in the selected period.'; fa = 'Information on excise amounts accrued in the selected period.';
									|it = 'Information on excise amounts accrued in the selected period.';
									|pl = 'Information on excise amounts accrued in the selected period.';
									|tr = 'Seçilen dönemde tahakkuk eden tüketim vergisi tutarlarına ilişkin bilgiler.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Internal

// Adds an informational message to the report header.
//
// Parameters:
//	ResultDocument - SpreadsheetDocument - Report result.
//	DataSelectionValues - Structure - see Get Metadata values ().
//
Procedure AddInformationalMessageToHeader(ResultDocument, DataSelectionValues) Export
	
	If ReportDataIsUpToDate(DataSelectionValues) Then
		Return;
	EndIf;
	
	MessageText = NStr("vi = 'Dữ liệu trong báo cáo có thể chưa được cập nhật:
	|Đang có các nhiệm vụ chưa hoàn thành liên quan đến việc kết chuyển bổ sung không tức thời đối với chứng từ về thuế TTĐB.';
	|ru = 'Данные в отчете могут быть неактуальны:
	|Имеются невыполненные задания неоперативного допроведения документов по акцизам.';
	|en = 'Data in the report might be outdated:
	|There are incomplete jobs of backdate additional posting of excise documents.'; fa = 'Data in the report might be outdated:
	|There are incomplete jobs of backdate additional posting of excise documents.';
	|it = 'Data in the report might be outdated:
	|There are incomplete jobs of backdate additional posting of excise documents.';
	|pl = 'Data in the report might be outdated:
	|There are incomplete jobs of backdate additional posting of excise documents.';
	|tr = 'Raporda yer alan veriler geçerli olmayabilir:
	|Tüketim vergileriyle ilgili belgelerin operasyonel olmayan şekilde ek düzenlenmesi için yerine getirilmemiş görevler mevcut.'");
	
	ResultDocument.Area("R1C1").Text = MessageText;
	ResultDocument.Area("R1C1").TextColor = Metadata.StyleItems.TextColorIssue.Value;
	ResultDocument.Area(1, 1, 1, ).RowHeight = 0;
	
EndProcedure

#EndRegion

#Region Private

Function ReportDataIsUpToDate(DataSelectionValues)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	PRESENTATION(JobsForCalculating.Organization) AS OrganizationPresentation
	|FROM
	|	InformationRegister.JobsOfBackdateAdditionalDocumentPosting AS JobsForCalculating
	|WHERE
	|	JobsForCalculating.JobKind = VALUE(Catalog.BackdateJobKinds.RecordExciseRegisterRecords)
	|	AND CASE WHEN &NoOrganizationSelection THEN TRUE ELSE JobsForCalculating.Organization IN (&CompaniesList) END
	|	AND CASE WHEN &Period = DATETIME(1, 1, 1) THEN TRUE ELSE JobsForCalculating.TaskPeriod <= &Period END
	|GROUP BY
	|	PRESENTATION(JobsForCalculating.Organization)";
	
	Query.SetParameter("NoOrganizationSelection", DataSelectionValues.CompaniesList.Count() = 0);
	Query.SetParameter("CompaniesList", DataSelectionValues.CompaniesList);
	Query.SetParameter("Period", DataSelectionValues.Period);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Result.IsEmpty();
	
EndFunction

#EndRegion

#EndIf