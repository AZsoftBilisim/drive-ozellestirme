
#Region FormEventHandlers 

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TempStorageAddress = Parameters.TempStorageAddress;
	EditMode      = Parameters.EditMode;
	Organization              = Parameters.Organization;
	
	DocumentsExport.Load(GetFromTempStorage(TempStorageAddress));
	RevenueAmountTotal = DocumentsExport.Total("RevenueAmount");
	RevenueAdjustmentTotal = DocumentsExport.Total("RevenueAdjustment");
	
	Items.FormMoveToDocument.Visible = EditMode;
	Items.FormClose.DefaultButton = Not EditMode;
	Items.DocumentsExport.ReadOnly = Not EditMode;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit And Modified Then
		Cancel = True;
		WarningText = NStr("vi = 'Chưa chuyển dữ liệu vào chứng từ. Sau khi đóng, sẽ không lưu những thay đổi của bạn.';
							|ru = 'Данные не были перенесены в документ. После закрытия, сделанные Вами изменения сохранены не будут.';
							|en = 'Data is not added to the document. After closing, the changes you made will not be saved.'; fa = 'Data is not added to the document. After closing, the changes you made will not be saved.';
							|it = 'I dati non sono stati trasferiti nel documento. Dopo la chiusura, le modifiche apportate non saranno salvate.';
							|pl = 'Dane nie zostały przeniesione do dokumentu. Po zamknięciu zmiany nie zostaną zapisane.';
							|tr = 'Veriler belgeye transfer edilmedi. Kapattıktan sonra, yapılan değişiklikler kaydedilmeyecektir.'");
		Return;
	EndIf;
	
	If Modified Then
		Cancel = True;
		CallbackDescription = New CallbackDescription("HandlerAlertIssueBeforeClosing", ThisObject);
		QueryText = NStr("vi = 'Chưa chuyển dữ liệu vào chứng từ. Chuyển?';
						|ru = 'Данные не перенесены в документ. Перенести?';
						|en = 'Data is not added to the document. Do you want to add it?'; fa = 'Data is not added to the document. Do you want to add it?';
						|it = 'I dati non sono stati trasferiti nel documento. Trasferire?';
						|pl = 'Dane nie są przeniesione do dokumentu. Przenieść?';
						|tr = 'Veriler belgeye transfer edilmedi. Transfer et?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentsExportSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.DocumentsExport.CurrentData;
	If Field = Items.DocumentsExportDocument Then
		
		If ValueIsFilled(CurrentRow.Document) And Not EditMode Then
			ShowValue(Undefined, CurrentRow.Document);
			StandardProcessing = False;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	Cancel = False;
	
	ClearMessages();
	CheckFillingOfTablePart(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	Modified = False;
	Close(PlaceExportDocumentsInTemporaryStorage());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CheckFillingOfTablePart(Cancel)
	
	For CurIndex__ = 0 To DocumentsExport.Count()-1 Do
		
		If Not ValueIsFilled(DocumentsExport[CurIndex__].Document) Then
			ErrorText = NStr("vi = 'Chưa điền chứng từ trong dòng %LineNumber%';
							|ru = 'Не заполнен документ в строке %LineNumber%';
							|en = 'Document in line %LineNumber% is not specified'; fa = 'Document in line %LineNumber% is not specified';
							|it = 'Non è stato compilato il documento nella riga %LineNumber%';
							|pl = 'W dokumencie nie jest wypełniony wiersz %LineNumber%';
							|tr = '%LineNumber% satırında belge doldurulmadı'");
			ErrorText = StrReplace(ErrorText,"%LineNumber%",CurIndex__+1);
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				CommonClientServer.PathToTabularSection("DocumentsExport", CurIndex__ + 1, "Document"),
				,
				Cancel);
		EndIf;
		
		If Not ValueIsFilled(DocumentsExport[CurIndex__].RevenueAmount) 
			 And Not ValueIsFilled(DocumentsExport[CurIndex__].RevenueAdjustment) Then
			ErrorText = NStr("vi = 'Chưa điền số tiền trong dòng %LineNumber%';
							|ru = 'Не заполнена сумма в строке %LineNumber%';
							|en = 'Amount is not filled in line %LineNumber%'; fa = 'Amount is not filled in line %LineNumber%';
							|it = 'Non è stato compilato l''importo nella riga %LineNumber%';
							|pl = 'Nie jest wypełniona kwota w wierszu %LineNumber%';
							|tr = '%LineNumber% satırında tutar doldurulmadı'");
			ErrorText = StrReplace( ErrorText,"%LineNumber%",CurIndex__+1);
			CommonClientServer.MessageToUser(
				ErrorText ,
				,
				CommonClientServer.PathToTabularSection("DocumentsExport", CurIndex__ + 1, "Sum"),
				,
				Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function PlaceExportDocumentsInTemporaryStorage()
	
	Return PutToTempStorage(DocumentsExport.Unload(), TempStorageAddress);
	
EndFunction

&AtClient
Procedure HandlerAlertIssueBeforeClosing(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		Cancel = False;
		CheckFillingOfTablePart(Cancel);
		If Not Cancel Then
			Modified = False;
			Close(PlaceExportDocumentsInTemporaryStorage());
		EndIf;
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentsExportOnChange(Item)
	
	RevenueAmountTotal = DocumentsExport.Total("RevenueAmount");
	RevenueAdjustmentTotal = DocumentsExport.Total("RevenueAdjustment");
	
EndProcedure


#EndRegion