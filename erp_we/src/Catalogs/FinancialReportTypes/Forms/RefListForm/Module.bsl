
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.DeletionMode Then
		Title = NStr("vi = 'Xóa phần tử báo cáo';
					|ru = 'Удаление элемента отчета';
					|en = 'Remove report item'; fa = 'Remove report item';
					|it = 'Eliminazione di un elemento del report';
					|pl = 'Usuwanie elementu raportu';
					|tr = 'Rapor ögesi silinmesi'");
		Items.CancelButton.Title = NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'");
	EndIf;
	
	ActionCopy = 0;
	ActionMove = 1;
	ActionDelete = 2;
	MainAction = ActionCopy;
	
	ReportItem = Parameters.ReportItem;
	ElementDescription = Common.ObjectAttributeValue(ReportItem, "NameForPrinting");
	DeletionMode = Parameters.DeletionMode;
	DeleteAll = Parameters.DeleteAll;
	UpdateLinkTree();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CopyToAllOnChange(Item)
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure MoveTo_OnChange(Item)
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure DeleteAll_3OnChange(Item)
	
	SetAvailability();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersItemRefTree

&AtClient
Procedure ItemRefTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure("Key",Item.CurrentData.ReportKind);
	FormParameters.Insert("CurrentReportItem", Item.CurrentData.ReportItem);
	OpenForm("Catalog.FinancialReportTypes.ObjectForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure ItemRefTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CommandExecute(Command)
	
	Response = Undefined;

	
	ShowQueryBox(New CallbackDescription("CommandExecuteCompletion", ThisObject), NStr("vi = 'Thao tác không thể phục hồi. Tiếp tục??';
																						|ru = 'Действие необратимо. Продолжить??';
																						|en = 'Action cannot be undone. Continue?'; fa = 'Action cannot be undone. Continue?';
																						|it = 'L''azione è irreversibile. Continuare??';
																						|pl = 'Działanie jest nieodwracalne. Kontynuować??';
																						|tr = 'İşlem geri alınamaz. Devam edilsin mi?'"),QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure CommandExecuteCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    SelectedElement = Undefined;
    If MainAction = ActionMove Then
        If Items.ItemRefTree.CurrentRow = Undefined Then
            ShowMessageBox(Undefined, NStr("vi = 'Hãy chỉ ra báo cáo nguồn tham chiếu mới.';
											|ru = 'Укажите отчет новый источник ссылок.';
											|en = 'Specify a report new reference source.'; fa = 'Specify a report new reference source.';
											|it = 'Specificare il report nuova fonte di riferimenti.';
											|pl = 'Wskaż raport nowe źródło odnośników.';
											|tr = 'Yeni bir bağlantı kaynağı raporu belirt.'"));
            Return;
        EndIf;
        CurrentData = Items.ItemRefTree.CurrentData;
        SelectedElement = CurrentData.ReportItem;
        If Not ValueIsFilled(SelectedElement) Then
            SubordinateRows = FinancialReportingClient.SubordinateLinesOfFormElement(CurrentData);
            SelectedElement = SubordinateRows[0].ReportItem;
        EndIf;
    EndIf;
    ExecuteAction(SelectedElement);
    
    Close(True);

EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Procedure SetAvailability()
	
	If DeleteAll Then
		MainAction = ActionDelete;
		Items.CopyToAll.Enabled = False;
		Items.MoveTo_.Enabled = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ExecuteAction(SelectedElement = Undefined)
	
	// we will copy the original data to the selected element and break the connection
	If SelectedElement <> Undefined Then
		NewOriginal = SelectedElement.GetObject();
		FillInElementData(NewOriginal);
		NewOriginal.LinkedItem1 = Undefined;
		NewOriginal.Write();
	EndIf;
	
	ReportsKinds = FinancialReportingServer.SubordinateRows(ItemRefTree);
	For Each ReportKind In ReportsKinds Do
		ReportItems = FinancialReportingServer.SubordinateRows(ReportKind);
		For Each ElementReference In ReportItems Do
			
			If SelectedElement <> Undefined And ElementReference.ReportItem = SelectedElement Then
				Continue;
			EndIf;
			
			ElementObject = ElementReference.ReportItem.GetObject();
			If MainAction = ActionDelete Then
				ElementObject.SetDeletionMark(True);
			EndIf;
			ElementObject.LinkedItem1 = SelectedElement;
			If MainAction = ActionCopy Then
				FillInElementData(ElementObject);
			EndIf;
			ElementObject.Write();
			
		EndDo;// by elements of the same report type
	EndDo;// by types of reports
	
EndProcedure

&AtServer
Procedure FillInElementData(ReceiverObject)
	
	FillPropertyValues(ReceiverObject, ReportItem,,"Code,Owner,Parent,NameForPrinting,Comment");
	
	TitleOutput = ReceiverObject.ItemKindAttributes.Find(ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.DisplayItemTitle);
	If TitleOutput <> Undefined Then
		ReceiverObject.ItemKindAttributes.Delete(TitleOutput);
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ItemKindAttributes.Ref AS Ref,
	|	ItemKindAttributes.LineNumber AS LineNumber,
	|	ItemKindAttributes.Attribute AS Attribute,
	|	ItemKindAttributes.Value AS Value
	|FROM
	|	Catalog.FinancialReportItems.ItemKindAttributes AS ItemKindAttributes
	|WHERE
	|	(NOT (ItemKindAttributes.Attribute.PredefinedDataName = ""ReportRowCode""
	|	OR ItemKindAttributes.Attribute.PredefinedDataName = ""Note"")
	|	AND ItemKindAttributes.Ref = &ElementOfFinancialReportsLink)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FormulaOperands.LineNumber AS LineNumber,
	|	FormulaOperands.Ref AS Ref,
	|	FormulaOperands.Id AS Id,
	|	FormulaOperands.Operand AS Operand
	|FROM
	|	Catalog.FinancialReportItems.FormulaOperands AS FormulaOperands
	|WHERE
	|	FormulaOperands.Ref = &ElementOfFinancialReportsLink
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableItems.LineNumber AS LineNumber,
	|	TableItems.Ref AS Ref,
	|	TableItems.String AS String,
	|	TableItems.Column AS Column,
	|	TableItems.Item AS Item
	|FROM
	|	Catalog.FinancialReportItems.TableItems AS TableItems
	|WHERE
	|	TableItems.Ref = &ElementOfFinancialReportsLink";
	
	Query.SetParameter("ElementOfFinancialReportsLink", ReportItem);
	ResultsArray = Query.ExecuteBatch();
	
	AddAttributes = ResultsArray[0].Unload(); //ItemKindAttributes
	For Each Attribute In AddAttributes Do
		NewRow = ReceiverObject.ItemKindAttributes.Add();
		FillPropertyValues(NewRow, Attribute);
	EndDo;
	ReceiverObject.FormulaOperands.Load(ResultsArray[1].Unload());
	ReceiverObject.TableItems.Load(ResultsArray[2].Unload());
	
EndProcedure

&AtServer
Procedure UpdateLinkTree()
	
	TreeParameters = InternationalReportingClientServer.NewElementTreeParameters();
	TreeParameters.NameOfTreeElement = "ItemRefTree";
	TreeParameters.Insert("ReportItem", Parameters.ReportItem);
	TreeParameters.Insert("GLAccount_", Parameters.GLAccount_);
	
	InternationalReportingServer.UpdateElementReferenceTree(ThisForm, TreeParameters);
	
	RefsCount = TreeParameters.RefsCount;
	TextTemplate1 = NStr("vi = 'Đã tìm thấy tham chiếu đến phần tử ""%1""
						|trong các báo cáo khác (%2).
						|Hãy chọn thao tác:';
						|ru = 'На элемент ""%1""
						|обнаружены ссылки в других отчетах (%2 шт).
						|Выберите действие:';
						|en = 'References to the ""%1""
						|item are found in other reports (%2).
						|Select action:'; fa = 'References to the ""%1""
						|item are found in other reports (%2).
						|Select action:';
						|it = 'Per elemento ""%1""
						|sono stati rilevati i collegamenti in altri report (%2 pz).
						|Selezionare un''azione:';
						|pl = 'Do elementu ""%1""
						|wykryto odnośniki w innych raportach (%2 szt.).
						|Wybierz działanie:';
						|tr = '""%1"" öğesi için
						|diğer raporlarda bağlantılar bulundu (%2 tane).
						|İşlem seçin:'");
	
	Text = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, ElementDescription, RefsCount);
	Items.Explanation.Title = Text;
	
	Items.MoveTo_.ReadOnly = RefsCount = 1;
	If Items.MoveTo_.ReadOnly Then
		MainAction = ActionCopy;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
