
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ProvisionObject") Then
		ProvisionObject = Parameters.ProvisionObject;
	EndIf;
	
	If Parameters.Property("Period") Then
		Period = Parameters.Period;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	GenerateReport();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ObjectReport = FormAttributeToValue("Report");
	ThereIsDataToDisplay = False;
	ObjectReport.GenerateReport(Result, ProvisionObject, Period, ThereIsDataToDisplay);
	If ThereIsDataToDisplay Then
		Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
		Items.Result.StatePresentation.Visible = False;
		Result.ShowGrid = False;
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

#EndRegion
