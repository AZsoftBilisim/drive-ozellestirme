
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Contract = Catalogs.CounterpartyContracts.EmptyRef();
	Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
	
	If Parameters.Property("Contract", Contract) Then
		Contract = Parameters.Contract;
	EndIf;
	If Parameters.Property("Terms") Then 
		Terms = Parameters.Terms;
	EndIf;
	
	DocumentsList.Parameters.SetParameterValue("Contract", Contract);
	DocumentsList.Parameters.SetParameterValue("Terms", Terms);
	DocumentsList.Parameters.SetParameterValue("StateNotStarted", NStr("vi = 'Chưa bắt đầu';
																		|ru = 'Не начат';
																		|en = 'Not started'; fa = 'شروع‌نشده';
																		|it = 'Non è iniziato';
																		|pl = 'Nie rozpoczęto';
																		|tr = 'Başlatılmadı'"));
	
EndProcedure

#EndRegion


#Region FormTableItemsEventHandlers

&AtClient
Procedure DocumentsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	SelectedDocument = Undefined;
	
	CurrentData = Items.DocumentsList.CurrentData;
	If CurrentData <> Undefined Then
		SelectedDocument = CurrentData.Ref;
	EndIf;
	Notify("SelectionOfSalesDocumentsToReportToCommittee", SelectedDocument, ThisForm);
	
	Close();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectDocument(Command)
	
	SelectedDocument = Undefined;
	
	CurrentData = Items.DocumentsList.CurrentData;
	If CurrentData <> Undefined Then
		SelectedDocument = CurrentData.Ref;
	EndIf;
	Notify("SelectionOfSalesDocumentsToReportToCommittee", SelectedDocument, ThisForm);
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure DocumentsListOnGetDataAtServer(TagName, Settings, Rows)
	
	If Not AccessRight("Read", Metadata.Documents.CustomerInvoice) Then
		
		SetPrivilegedMode(True);
		
		For Each KeyOfLineToDesign In Rows.GetKeys() Do
			ListLine = Rows[KeyOfLineToDesign];
			ListLine.Appearance["Ref"].SetParameterValue(
				"Text", String(KeyOfLineToDesign));
		EndDo;
		
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

#EndRegion
