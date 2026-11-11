
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	For Each DocumentBasis In Parameters.Basis1 Do
		RowData = Basis1.Add();
		RowData.DocumentBasis = DocumentBasis;
	EndDo;
	
	If ReadOnly Then
		Items.FormExitApp.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	MessageTemplate = NStr("vi = 'Chưa điền cột ""Chứng từ cơ sở"" trong dòng %1';
							|ru = 'Не заполнена колонка ""Документ основание"" в строке %1';
							|en = 'The ""Base document"" column is not filled in the %1 line'; fa = 'The ""Base document"" column is not filled in the %1 line';
							|it = 'Non è compilata la colonna ""Documento base"" nella riga %1';
							|pl = 'Nie wypełniono kolumny ""Dokument źródłowy"" w wierszu %1';
							|tr = '%1 satırındaki ""Temel belge"" sütunu doldurulmamış'");
	
	ListOfGrounds = New Array;
	
	For Each RowData In Basis1 Do

		If Not ValueIsFilled(RowData.DocumentBasis) Then
			
			MessageText = StrTemplate(MessageTemplate, Format(RowData.LineNumber, "NG=0;"));
			
			Field = CommonClientServer.PathToTabularSection("Basis1", RowData.LineNumber, "DocumentBasis");
			Common.MessageToUser(MessageText,, Field,, Cancel);
			
		EndIf;
		
	EndDo;
	
	If ListOfGrounds.Count() <> 0 Then
		
		DetailsOfBases = Common.ObjectsAttributesValues(ListOfGrounds, "Date,Organization");
		
		CurMonthOfDisposal = Undefined;
		CurrentCompany = Undefined;
	
		For Each KeyAndValue In DetailsOfBases Do
			
			MonthOfDisposal = BegOfMonth(KeyAndValue.Value.Date);
			
			If MonthOfDisposal <> CurMonthOfDisposal 
				And CurMonthOfDisposal <> Undefined Then
				MessageText = NStr("vi = 'Cần chọn các chứng từ được lập trong cùng một tháng';
									|ru = 'Необходимо выбрать документы, оформленные в одном и том же месяце';
									|en = 'Select the documents registered in the same month'; fa = 'Select the documents registered in the same month';
									|it = 'È necessario selezionare i documenti compilati nello stesso mese';
									|pl = 'Należy wybrać dokumenty, utworzone w tym samym miesiącu';
									|tr = 'Aynı ay içinde düzenlenmiş belgeler seçilmelidir'");
				Common.MessageToUser(MessageText,,,, Cancel);
				Return;
			EndIf;
			
			If KeyAndValue.Value.Organization <> CurrentCompany 
				And CurrentCompany <> Undefined Then
				MessageText = NStr("vi = 'Cần chọn chứng từ của một doanh nghiệp';
									|ru = 'Необходимо выбрать документы одной организации';
									|en = 'Select documents of one company'; fa = 'Select documents of one company';
									|it = 'È necessario selezionare i documenti di una azienda';
									|pl = 'Należy wybrać dokumenty jednej firmy';
									|tr = 'Aynı iş yerinin belgelerinin seçilmesi gerekmektedir'");
				Common.MessageToUser(MessageText,,,, Cancel);
				Return;
			EndIf;
			
			CurMonthOfDisposal = MonthOfDisposal;
			CurrentCompany = KeyAndValue.Value.Organization;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExitApp(Command)
	
	CloseForm();

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CloseForm()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = New Array;
	For Each RowData In Basis1 Do
		Result.Add(RowData.DocumentBasis);
	EndDo;
	
	Close(Result);
	
EndProcedure

#EndRegion
