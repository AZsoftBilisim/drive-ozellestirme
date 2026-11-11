
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Contract          = Catalogs.CounterpartyContracts.EmptyRef();
	Partner          = Catalogs.Partners.EmptyRef();
	Orders           = New Array;
	PickByOrder = False;
	
	If ValueIsFilled(Parameters.Contract) Then
		Contract = Parameters.Contract;
		Items.TitleContract.Visible = True;
		Items.FilterContract.Title = String(Contract);
		Items.FilterContract.Visible = True;
	EndIf;
	If ValueIsFilled(Parameters.Partner) Then 
		Partner = Parameters.Partner;
		Items.CommitteeTitle.Visible = True;
		Items.FilterConsignor.Title = String(Partner);
		Items.FilterConsignor.Visible = True;
	EndIf;
	If ValueIsFilled(Parameters.Orders) Then 
		Orders = Parameters.Orders.UnloadValues();
		PickByOrder = True;
		Items.HeaderOrder.Visible = True;
		Items.FilterOrderDocument.Title = StrConcat(Orders, ", ");
		Items.FilterOrderDocument.Visible = True;
	EndIf;
	
	DocumentsList.Parameters.SetParameterValue("Contract",          Contract);
	DocumentsList.Parameters.SetParameterValue("Partner",          Partner);
	DocumentsList.Parameters.SetParameterValue("Orders",           Orders);
	DocumentsList.Parameters.SetParameterValue("PickByOrder", PickByOrder);
	DocumentsList.Parameters.SetParameterValue("StateIsNotStarted", NStr("vi = 'Chưa bắt đầu';
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
	Notify("SelectionOfAcquisitionDocumentsToReportToCommittee", SelectedDocument, ThisObject);
	
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

	Notify("SelectionOfAcquisitionDocumentsToReportToCommittee", SelectedDocument, ThisObject);
	
	Close();
	
EndProcedure

#EndRegion
