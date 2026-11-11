
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("CommandParameter") Then
		If TypeOf(Parameters.CommandParameter) = Type("Array") Then
			ReferencesArrray = Parameters.CommandParameter;
		Else
			ReferencesArrray = CommonClientServer.ValueInArray(Parameters.CommandParameter);
		EndIf;
		
		FilterDocuments.Clear();
		For Each Ref In ReferencesArrray Do
			
			If TypeOf(Ref) = Type("CatalogRef.CounterpartyContracts") Then
				FilterContract = Ref;
			Else
				FilterDocuments.Add(Ref);
			EndIf;
			
		EndDo;
		
		FormWhenOpened = True;
		Items.Documents.Visible = False;
		Items.Contract.Visible = False;
		
	EndIf;
	
	ReportData = 1;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If FormWhenOpened Then
		GenerateReport();
	Else
		SetStateReportNotGenerated();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ContractOnChange(Item)
	SetStateReportNotGenerated();
EndProcedure

&AtClient
Procedure DocumentsOnChange(Item)
	RemoveEmptyValuesFromList(FilterDocuments);
	SetStateReportNotGenerated();
EndProcedure

&AtClient
Procedure ReportDataOnChange(Item)
	SetStateReportNotGenerated();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ObjectReport = FormAttributeToValue("Report");
	ThereIsDataToDisplay = False;
	ObjectReport.GenerateReport(Result, FilterContract, FilterDocuments.UnloadValues(), ReportData, ThereIsDataToDisplay);
	If ThereIsDataToDisplay Then
		Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
		Items.Result.StatePresentation.Visible = False;
	Else
		Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
		Items.Result.StatePresentation.Text = NStr("vi = 'Không có dữ liệu để phản ánh.';
													|ru = 'Нет данных для отображения.';
													|en = 'No data to display.'; fa = 'No data to display.';
													|it = 'Non vi sono dati per la riflessione.';
													|pl = 'Brak danych do wyświetlenia.';
													|tr = 'Görüntülenecek veriler yok.'");
		Items.Result.StatePresentation.Visible = True;
	EndIf;
	
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
												|tr = 'Rapor oluşturulmadı. Raporu oluşturmak için ""Oluştur"" butonuna tıklayın.'");
	Items.Result.StatePresentation.Visible = True;
	
EndProcedure // Set the status of the reportformed()

&AtClient
Procedure Generate(Command)
	
	If FilterContract.IsEmpty() And FilterDocuments.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chỉ ra bộ lọc theo chứng từ hoặc hợp đồng';
							|ru = 'Не указан отбор по документу или договору';
							|en = 'Filter by document or contract is not specified'; fa = 'Filter by document or contract is not specified';
							|it = 'Non è indicato il filtro per documento o contratto';
							|pl = 'Nie podano filtru według dokumentu lub kontraktu';
							|tr = 'Belge veya sözleşmeye göre filtre belirtilmedi'");
		CommonClient.MessageToUser(MessageText,,, "FilterContract");
		Return;
	EndIf;
	
	ClearMessages();
	
	GenerateReport();
	
EndProcedure

&AtClient
Procedure RemoveEmptyValuesFromList(ValueList)
	IndexOf = ValueList.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		If Not ValueIsFilled(ValueList[IndexOf].Value) Then
			ValueList.Delete(IndexOf);
		EndIf;
	EndDo
EndProcedure

#EndRegion
