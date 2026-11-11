
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisForm, Parameters,,
	                        "CloseOnChoice, CloseOnOwnerClose, ReadOnly");
	
	Period = Common.CommonSettingsStorageLoad("DiscrepancyReportFollowingTransfer.BaseDocumentChoiceForm", 
	                                                          "PeriodOfSelectionOfGroundsActOfDivergenceAfterRelocation");
	If Period.EndDate = Date(1, 1, 1) And Period.EndDate = Date(1, 1, 1) Then
		Period.Variant = StandardPeriodVariant.Month;
	EndIf;
	
	TransferOption = "Variant1";
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		Items.InformationLabelSelections.Height = 1;
	EndIf;
	
	FillInDocumentTable();
	CreateInformationLabelSelections();
	GenerateInformationLabelNumberOfDocuments(ThisForm);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Common.CommonSettingsStorageSave("DiscrepancyReportFollowingTransfer.BaseDocumentChoiceForm",
	                                                 "PeriodOfSelectionOfGroundsActOfDivergenceAfterRelocation",
	                                                 Period);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Settings <> Undefined Then
		Settings.Delete("Period");
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If CloseForm Then
		Return;
	EndIf;
	
	If Modified And Not MoveToDocument Then
		
		HasChanges = False;
		
		RowsSelected = Basis1.FindRows(New Structure("Selected", True));
		If RowsSelected.Count() <> BasisDocuments.Count() Then
			HasChanges = True;
		ElsIf RowsSelected.Count() = 0 Or BasisDocuments.Count() = 0 Then
			
			HasChanges = True;
			
		Else
			For Each RowSelected In RowsSelected Do
				If BasisDocuments.FindByValue(RowSelected.Ref) = Undefined Then
					HasChanges = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If HasChanges Then
			QueryText = NStr("vi = 'Thành phần chứng từ cơ sở đã thay đổi. Tiếp nhận thay đổi? ';
							|ru = 'Состав документов-оснований был изменен. Принять изменения?';
							|en = 'Content of base documents was changed. Accept changes?'; fa = 'Content of base documents was changed. Accept changes?';
							|it = 'La struttura dei documenti-causali è stata modificata. Accettare le modifiche?';
							|pl = 'Skład dokumentów-podstaw został zmieniony. Akceptować zmiany?';
							|tr = 'Temel belgelerin yapısı değiştirilmiştir. Değişiklikler kabul edilsin mi?'");
			HandlerNotifications = New CallbackDescription("QuestionAboutAcceptingChangesInResponse", ThisForm);
			ShowQueryBox(HandlerNotifications, QueryText, QuestionDialogMode.YesNoCancel);
			Cancel = True;
		EndIf;
		
	ElsIf MoveToDocument  Then
		
		If Not ClearanceIsConfirmed And TabularSectionIsNotEmpty Then
			If TransferOption = "Variant1" Then
				QueryText = NStr("vi = 'Phần bảng chứng từ sẽ bị xóa và điền lại. Tiếp tục?';
								|ru = 'Табличная часть документа будет очищена и перезаполнена. Продолжить?';
								|en = 'The table will be cleared and refilled. Do you want to continue?'; fa = 'The table will be cleared and refilled. Do you want to continue?';
								|it = 'La tabella del documento verrà cancellata e ricompilata. Continuare?';
								|pl = 'Część tabelaryczna dokumentu zostanie wyczyszczona i ponownie wypełniona. Kontynuować?';
								|tr = 'Belgenin tablo kısmı temizlenecek ve yeniden doldurulacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Phần bảng chứng từ sẽ bị điền lại. Tiếp tục?';
								|ru = 'Табличная часть документа будет перезаполнена. Продолжить?';
								|en = 'Table of the document will be refilled. Continue?'; fa = 'Table of the document will be refilled. Continue?';
								|it = 'La sezione tabellare del documento verrà ricompilata. Continuare?';
								|pl = 'Część tabelaryczna dokumentu zostanie ponownie wypełniona. Kontynuować?';
								|tr = 'Belgenin tablo kısmı yeniden doldurulacaktır. Devam edilsin mi?'");
			EndIf;
			HandlerNotifications = New CallbackDescription("QuestionAboutClearingTablePartWhenAnswering", ThisForm);
			ShowQueryBox(HandlerNotifications, QueryText, QuestionDialogMode.YesNo);
			Cancel = True;
		Else
			
			MoveToDocument();
			Cancel = True;
			
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOptionOnChange(Item)
	
	FillInDocumentTable();
	
EndProcedure

#EndRegion 

#Region EventHandlersOfTablePartOfImplementation

&AtClient
Procedure SalesOfGoodsAndServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If RowSelected <> Undefined Then
		ShowValue(, Basis1.FindByID(RowSelected).Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure SalesOfGoodsAndServicesSelectedOnChange(Item)
	
	CurrentData = Items.Basis1.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OperationSign = ?(CurrentData.Selected,1,-1);
	DocumentsCount = DocumentsCount + 1*OperationSign;
	
	DisplayInformationLabelNumberOfDocuments(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure Refresh(Command)
	
	FillInDocumentTable();
	
EndProcedure

&AtClient
Procedure DisableAll(Command)
	
	SetFlagsSelected(False);
	
EndProcedure

&AtClient
Procedure SelectAll_2(Command)
	
	SetFlagsSelected(True);
	
EndProcedure

&AtClient
Procedure MoveToDocumentExecute()
	
	MoveToDocument = True;
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillInDocumentTable()
	
	TableOfDocumentBases = New ValueTable();
	TableOfDocumentBases.Columns.Add("DocumentBasis", 
		New TypeDescription("DocumentRef.InventoryTransfer, DocumentRef.CustomerInvoice, DocumentRef.ReturnOfGoodsToVendor"));
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	DocumentGrounds.DocumentBasis
	|INTO SelectedDocuments
	|FROM
	|	&DocumentGrounds AS DocumentGrounds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN SelectedDocuments.DocumentBasis IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Selected,
	|	InventoryTransfer.Number,
	|	InventoryTransfer.Date,
	|	InventoryTransfer.Ref
	|FROM
	|	Document.InventoryTransfer AS InventoryTransfer
	|		LEFT JOIN SelectedDocuments AS SelectedDocuments
	|		ON InventoryTransfer.Ref = SelectedDocuments.DocumentBasis
	|WHERE
	|	InventoryTransfer.BusinessOperation = &BusinessOperation
	|	AND InventoryTransfer.Organization = &Organization
	|	AND InventoryTransfer.CompanyRecipient = &CompanyRecipient
	|	AND InventoryTransfer.SourceWarehouse = &SourceWarehouse
	|	AND InventoryTransfer.DestinationWarehouse = &DestinationWarehouse
	|	AND InventoryTransfer.Posted
	|	AND CASE
	|			WHEN &StartDate = &DateEmpty
	|					AND &EndDate = &DateEmpty
	|				THEN TRUE
	|			WHEN &StartDate = &DateEmpty
	|				THEN InventoryTransfer.Date <= &EndDate
	|			WHEN &EndDate = &DateEmpty
	|				THEN InventoryTransfer.Date >= &StartDate
	|			ELSE InventoryTransfer.Date BETWEEN &StartDate AND &EndDate
	|		END
	|	AND CASE
	|			WHEN &SeriesAreUsedInReceivingWarehouse
	|				THEN InventoryTransfer.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)
	|			ELSE InventoryTransfer.Status = VALUE(Enum.GoodsTransferStatuses.Shipped)
	|					OR InventoryTransfer.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)
	|		END
	|
	|ORDER BY
	|	InventoryTransfer.Date DESC";
	
	Query.SetParameter("BasisDocuments", BasisDocuments);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CompanyRecipient", CompanyRecipient);
	Query.SetParameter("SourceWarehouse", SourceWarehouse);
	Query.SetParameter("DestinationWarehouse", DestinationWarehouse);
	Query.SetParameter("StartDate", Period.StartDate);
	Query.SetParameter("EndDate", Period.EndDate);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("DateEmpty", Date(1, 1, 1));
	
	SeriesAreUsedInReceivingWarehouse = WarehousesServer.UseOfSeriesInStock(DestinationWarehouse, False);
	Query.SetParameter("SeriesAreUsedInReceivingWarehouse", SeriesAreUsedInReceivingWarehouse.UseItemsBatch);
	
	For Each ListItem In BasisDocuments Do
		NewRow = TableOfDocumentBases.Add();
		NewRow.DocumentBasis = ListItem.Value;
	EndDo;
	Query.SetParameter("DocumentGrounds", TableOfDocumentBases);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Basis1.Clear();
	Else
		Basis1.Load(Result.Unload());
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionAboutAcceptingChangesInResponse(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		MoveToDocument = True;
		Close();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure QuestionAboutClearingTablePartWhenAnswering(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		MoveToDocument();
		
	Else
		
		MoveToDocument = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveToDocument()
	
	ArrayOfSelectedDocuments = New Array;
	RowsSelected = Basis1.FindRows(New Structure("Selected", True));
	For Each RowSelected In RowsSelected Do
		ArrayOfSelectedDocuments.Add(RowSelected.Ref);
	EndDo;
	
	ClearanceIsConfirmed = True;
	CloseForm = True;
	NotifyChoice(ArrayOfSelectedDocuments);
	
EndProcedure 

&AtClient
Procedure SetFlagsSelected(Include)

	For Each TableRow In Basis1 Do
		TableRow.Selected = Include;
	EndDo;
	
	If Include Then
		GenerateInformationLabelNumberOfDocuments(ThisForm)
	Else
		DocumentsCount = 0;
		DisplayInformationLabelNumberOfDocuments(ThisForm);
	EndIf;

EndProcedure

&AtServer
Procedure CreateInformationLabelSelections()

	InformationLabelSelections = NStr("vi = 'Lọc theo: %Organization%, %CompanyRecipient%, %SourceWarehouse%, %DestinationWarehouse%, %BusinessOperation%.';
										|ru = 'Отбор по: %Organization%, %CompanyRecipient%, %SourceWarehouse%, %DestinationWarehouse%, %BusinessOperation%.';
										|en = 'Filter by: %Organization%, %CompanyRecipient%, %SourceWarehouse%, %DestinationWarehouse%, %BusinessOperation%.'; fa = 'Filter by: %Organization%, %CompanyRecipient%, %SourceWarehouse%, %DestinationWarehouse%, %BusinessOperation%.';
										|it = 'Selezione per: %Organization%, %CompanyRecipient%, %SourceWarehouse%, %DestinationWarehouse%, %BusinessOperation%.';
										|pl = 'Filtr według: %Organization%, %CompanyRecipient%, %SourceWarehouse%, %DestinationWarehouse%, %BusinessOperation%.';
										|tr = 'Filtre: %Organization%, %CompanyRecipient%, %SourceWarehouse%, %DestinationWarehouse%, %BusinessOperation%.'");

	InformationLabelSelections = StrReplace(InformationLabelSelections,"%Organization%", Organization);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%CompanyRecipient%", CompanyRecipient);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%SourceWarehouse%", SourceWarehouse);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%DestinationWarehouse%", DestinationWarehouse);
	InformationLabelSelections = StrReplace(InformationLabelSelections,"%BusinessOperation%", BusinessOperation);

EndProcedure

&AtClientAtServerNoContext
Procedure GenerateInformationLabelNumberOfDocuments(Form)

	Form.DocumentsCount = 0;
	
	For Each TableRow In Form.Basis1 Do
		If TableRow.Selected Then
			Form.DocumentsCount = Form.DocumentsCount + 1;
		EndIf;
	EndDo;
	
	DisplayInformationLabelNumberOfDocuments(Form);

EndProcedure

&AtClientAtServerNoContext
Procedure DisplayInformationLabelNumberOfDocuments(Form)

	If Form.DocumentsCount <> 0 Then
		LabelText = NStr("vi = 'Đã chọn -%DocumentsCount%.';
						|ru = 'Подобрано документов - %DocumentsCount%.';
						|en = 'Selected documents - %DocumentsCount%.'; fa = 'Selected documents - %DocumentsCount%.';
						|it = 'Selezionati documenti - %DocumentsCount%.';
						|pl = 'Dobrano dokumentów - %DocumentsCount%.';
						|tr = 'Seçili belgeler - %DocumentsCount%.'");
		LabelText = StrReplace(LabelText,"%DocumentsCount%", Form.DocumentsCount);
	Else
		LabelText = NStr("vi = 'Đã chọn 0 chứng từ.';
						|ru = 'Подобрано 0 документов.';
						|en = '0 documents selected.'; fa = '0 documents selected.';
						|it = 'Selezionati 0 documenti.';
						|pl = 'Dobrano 0 dokumentów.';
						|tr = 'Seçili belge 0.'");
	EndIf;
	
	Form.InformationLabelNumberOfDocuments = LabelText;

EndProcedure

#EndRegion

