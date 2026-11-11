
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Form = CommandExecuteParameters.Source; // ClientApplicationForm - 
	If Form.FormName = "Catalog.FinancialReportTypes.Form.ItemForm" Then
		Item = Form.Object; // FormDataStructure -
		ReportKind = Item.Ref;
		ReportingSet = Form.ReportingSet;
		If Not ValueIsFilled(ReportKind) Or Form.Modified Then
			ShowQueryBox(
				New CallbackDescription("CommandProcessingCompletion", 
					ThisObject,
					New Structure("Form, ReportingSet, ReportKind", Form, ReportingSet, ReportKind)),
				NStr("vi = 'Trước khi kiểm tra sẽ ghi lại những dữ liệu chưa được lưu.
							|Tiếp tục?';
							|ru = 'Перед проверкой не сохраненные данные будут записаны.
							|Продолжить?';
							|en = 'Unsaved data will be saved before check.
							|Continue?'; fa = 'Unsaved data will be saved before check.
							|Continue?';
							|it = 'Prima della verifica, i dati non salvati verranno registrati.
							|Continuare?';
							|pl = 'Przed weryfikacją niezapisane dane zostaną zapisane.
							|Kontynuować?';
							|tr = 'Kontrolden önce kaydedilmemiş veriler kayıt edilecektir.
							|Devam edilsin mi?'"),
				QuestionDialogMode.YesNo);
			Return;
		EndIf;// no data recorded
	EndIf;// this is the shape of the element
	
	GenerateReport(Form, ReportingSet, ReportKind);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CommandProcessingCompletion(QuestionResult, AdditionalParameters) Export

	Form = AdditionalParameters.Form; // ManagedFormExtensionForCatalogs - 
	ReportingSet = AdditionalParameters.ReportingSet;
	ReportKind = AdditionalParameters.ReportKind;
	Response = QuestionResult;

	If Response = DialogReturnCode.Yes Then
		Form.Write();
	ElsIf Response = DialogReturnCode.No Then
		Return;
	EndIf;

	GenerateReport(Form, ReportingSet, ReportKind);

EndProcedure

&AtClient
Procedure GenerateReport(Val Form, Val ReportingSet, Val ReportKind)

	If Form.FormName = "Catalog.FinancialReportTypes.Form.ListForm" Then
		CurrentData = Form.Items.List.CurrentData;
		If CurrentData = Undefined Then
			Return;
		EndIf;
		If Not CurrentData.IsFolder Then
			ReportKind = Form.Items.List.CurrentRow;
		EndIf;// this is not a band
	EndIf;// this is a list form

	If ReportKind <> Undefined Then
		Filter = New Structure("ReportingSet, ReportKind", ReportingSet, ReportKind);
		FormParameters = New Structure("Filter, GenerateReport", Filter, True);
		OpenForm("Report.FinancialReport.Form.ReportForm", FormParameters, Form, True);
	EndIf;
    
EndProcedure

#EndRegion