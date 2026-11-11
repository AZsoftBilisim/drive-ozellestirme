
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("GenerateOnOpen") Then
		GenerateOnOpen = Parameters.GenerateOnOpen;
	EndIf;
	
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("ReportData") Then
			ReportData = Parameters.Filter.ReportData;
		EndIf;
		If Parameters.Filter.Property("ReportPeriod") Then
			If TypeOf(Parameters.Filter.ReportPeriod) = Type("StandardBeginningDate") Then
				ReportPeriod = Parameters.Filter.ReportPeriod.Date;
			Else
				ReportPeriod = Parameters.Filter.ReportPeriod;
			EndIf;
			If Parameters.Filter.Property("ARAPObject") Then
				FilterARAPObject =  Parameters.Filter.ARAPObject;
			EndIf;
		EndIf;
	EndIf;
	
	If Parameters.Property("CommandParameter") Then
		If TypeOf(Parameters.CommandParameter) = Type("Array") Then
			ReferencesArrray = Parameters.CommandParameter;
		Else
			ReferencesArrray = CommonClientServer.ValueInArray(Parameters.CommandParameter);
		EndIf;
		FilterDocuments.Clear();
		For Each Ref In ReferencesArrray Do
			FilterDocuments.Add(Ref);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If GenerateOnOpen Then
		GenerateReport();
	Else
		SetStateReportNotGenerated();
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ObjectReport = FormAttributeToValue("Report");
	ThereIsDataToDisplay = False;
	ObjectReport.GenerateReport(Result, ReportPeriod, FilterDocuments.UnloadValues(), ReportData, FilterARAPObject, ThereIsDataToDisplay);
	If ThereIsDataToDisplay Then
		Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
		Items.Result.StatePresentation.Visible = False;
	Else
		Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
		Items.Result.StatePresentation.Text = NStr("vi = 'Không có dữ liệu để hiển thị.';
													|ru = 'Нет данных для отображения.';
													|en = 'No data to display.'; fa = 'No data to display.';
													|it = 'Non vi sono dati per la riflessione.';
													|pl = 'Brak danych do wyświetlenia.';
													|tr = 'Görüntülenecek veriler yok.'");
		Items.Result.StatePresentation.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure Generate(Command)
	GenerateReport();
EndProcedure

// The procedure sets the display of the status "Report has not been generated" when changing the fields of the report.
//
&AtClient
Procedure SetStateReportNotGenerated()
	
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	Items.Result.StatePresentation.Text = NStr("vi = 'Chưa lập báo cáo. Hãy nhấn nút ""Lập báo cáo"" để nhận báo cáo.';
												|ru = 'Отчет не сформирован. Нажмите ""Сформировать"" для получения отчета.';
												|en = 'Report not generated. To generate the report, click ""Generate"".'; fa = 'Report not generated. To generate the report, click ""Generate"".';
												|it = 'Il report non è stato creato. Fate clic su ""Crea"" per ricevere il rapporto.';
												|pl = 'Raport nie został wygenerowany. Kliknij ""Utwórz"", aby wygenerować raport.';
												|tr = 'Rapor oluşturulmadı. Raporu almak için ""Oluştur"" butonuna tıklayın.'");
	Items.Result.StatePresentation.Visible = True;
	
EndProcedure // Set the status of the reportformed()

#EndRegion
