#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
		
	RequestForControl = Parameters.RequestForControl;
	ListOfItemsTS = Parameters.GoodsList;
	AllRows = Parameters.AllRows;
	
	RestoreFormSettingsWhenCreating();
	
	If ListOfItemsTS.Count() > 0 Then
		StructuresArrayIntoValueTable(ListOfItemsTS, GoodsList);
	EndIf;
	
	SetPropertiesOfDynamicCheckList(Catalogs.GoodsResearchSheets.EmptyRef());
	
	InstallWizardPages(ThisObject, "FormationOfResearch");
	
	CreateResearchDestinationTreeAtServer(RequestForControl, AllRows, Undefined, Undefined);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TreeProductsOnChange(Item)
	
	ClearMessages();
	GoodsForResearch.GetItems().Clear();
	CreateResearchDestinationTreeAtServer(RequestForControl, AllRows, ?(ValueIsFilled(TreeProducts),
		TreeProducts, Undefined), ?(ValueIsFilled(TreeTypeOfControl), TreeTypeOfControl, Undefined));
	
EndProcedure

&AtClient
Procedure TreeTypeOfControlOnChange(Item)
	
	ClearMessages();
	GoodsForResearch.GetItems().Clear();
	CreateResearchDestinationTreeAtServer(RequestForControl, AllRows, ?(ValueIsFilled(TreeProducts),
		TreeProducts, Undefined), ?(ValueIsFilled(TreeTypeOfControl), TreeTypeOfControl, Undefined));
	
EndProcedure

&AtClient
Procedure GoodsForResearchPerformerOnChange(Item)
	
	CurrentData = Items.GoodsForResearch.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.GetParent() = Undefined Then
		For Each String In CurrentData.GetItems() Do
			String.Performer = CurrentData.Performer;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsForResearchExploreOnChange(Item)
	
	CurrentData = Items.GoodsForResearch.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Explore) Then
		CurrentData.SelectPosition = True;
	Else
		CurrentData.SelectPosition = False;
	EndIf;
	
	Parent = CurrentData.GetParent();
	
	If Parent <> Undefined Then
		UpdateParentRowSelection(CurrentData.GetID());
	EndIf;
	
EndProcedure

&AtClient
Procedure SeveralItemsInStudyOnChange(Item)
	
	SaveFormSettings();
	
EndProcedure

&AtClient
Procedure Show_DetailsClick(Item)
	
	Show_Details = Not Show_Details;
	ConfigureDependentFormElements(ThisObject, "Show_Details");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsForResearch

&AtClient
Procedure GoodsForResearchSelectPositionOnChange(Item)
	
	CurrentData = Items.GoodsForResearch.CurrentData;
	
	SelectedWhenChangingOnServer(CurrentData.GetID());
	
EndProcedure

&AtClient
Procedure GoodsForResearchOnActivateRow(Item)
	
	CurrentData = Items.GoodsForResearch.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	SetPropertiesOfDynamicCheckList(CurrentData.GoodsResearchSheet);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	
	If Items.GroupPages.CurrentPage = Items.MasterPage Then
	
		GoToPreviewStep();
	
	ElsIf Items.GroupPages.CurrentPage = Items.Preview_Page Then
		
		GoToStepOfGeneratingResult();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPerformer(Command)
	
	ClearMessages();
	
	SelectedRows = Items.GoodsForResearch.SelectedRows;
	
	If GoodsForResearch.GetItems().Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Trong cây ""Chỉ định nghiên cứu"" không có dòng nào.';
								|ru = 'В дереве ""Назначение исследований"" нет ни одной строки.';
								|en = 'There are no lines in the ""Assignment of research"" tree.'; fa = 'There are no lines in the ""Assignment of research"" tree.';
								|it = 'There are no lines in the ""Assignment of research"" tree.';
								|pl = 'There are no lines in the ""Assignment of research"" tree.';
								|tr = '""İnceleme Atama"" ağacında hiç satır yok.'"));
		Return;
	ElsIf SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Trong cây ""Chỉ định nghiên cứu"" chưa chọn dòng nào.';
								|ru = 'В дереве ""Назначение исследований"" не выбрано ни одной строки.';
								|en = 'No lines are selected in the ""Assignment of research"" tree.'; fa = 'No lines are selected in the ""Assignment of research"" tree.';
								|it = 'No lines are selected in the ""Assignment of research"" tree.';
								|pl = 'No lines are selected in the ""Assignment of research"" tree.';
								|tr = '""İnceleme Atama"" ağacında hiç satır seçilmedi.'"));
		Return;
	EndIf;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("TabularSection", GoodsForResearch);
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("CloseOnChoice", True);
	PickingParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInPerformerCompletion", ThisObject, AdditionalParameters);

	OpenForm("Catalog.Users.ChoiceForm", PickingParameters,,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ClearRows(Command)
	
	Rows = GoodsForResearch.GetItems();
	If Rows.Count() > 0 Then
		SelectExcludeSelectedLines(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectRows(Command)
	
	Rows = GoodsForResearch.GetItems();
	If Rows.Count() > 0 Then
		SelectExcludeSelectedLines(True);
	EndIf;

EndProcedure

&AtClient
Procedure Back(Command)
	
	ClearMessages();
	
	If Items.GroupPages.CurrentPage = Items.ResultPage Then
		
		If CreatedObjects.Count() > 0 Then
			
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Đặt dấu xóa chứng từ';
													|ru = 'Пометить документы на удаление';
													|en = 'Mark documents for deletion'; fa = 'علامت‌گذاری اسناد برای حذف';
													|it = 'Contrassegnare i documenti per l''eliminazione';
													|pl = 'Zaznacz dokumenty do usunięcia';
													|tr = 'Silinmek için belgeleri işaretle'"));
			Buttons.Add(DialogReturnCode.Cancel);
			
			ShowQueryBox
				(New CallbackDescription("BackCompletion", ThisObject), 
				NStr("vi = 'Danh sách các nghiên cứu đã tạo không trống. Các chứng từ được tạo sẽ được đánh dấu để xóa. Đánh dấu xóa các chứng từ nghiên cứu hàng hóa và tiếp tục?';
					|ru = 'Список созданных исследований не пуст. Сформированные документы будут помечены на удаление. Пометить на удаление документы исследования товаров и продолжить?';
					|en = 'The list of created research is not empty. The generated documents will be marked for deletion. Mark the goods research documents for deletion and continue?'; fa = 'The list of created research is not empty. The generated documents will be marked for deletion. Mark the goods research documents for deletion and continue?';
					|it = 'The list of created research is not empty. The generated documents will be marked for deletion. Mark the goods research documents for deletion and continue?';
					|pl = 'The list of created research is not empty. The generated documents will be marked for deletion. Mark the goods research documents for deletion and continue?';
					|tr = 'Oluşturulan incelemeler listesi boş değil. Düzenlenen belgeler silinmek üzere işaretlenecek. Ürün inceleme belgelerini silinmek üzere işaretleyip devam edilsin mi?'"),
				Buttons);
			Return;
		Else
			InstallWizardPages(ThisObject, "Preview");
		EndIf;
		
	ElsIf Items.GroupPages.CurrentPage = Items.Preview_Page Then
		
		GoodsToPreview.GetItems().Clear();
		InstallWizardPages(ThisObject, "FormationOfResearch");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateAgain(Command)
	
	ClearMessages();
	
	GoodsToPreview.GetItems().Clear();
	GoodsForResearch.GetItems().Clear();
	CreateResearchDestinationTreeAtServer(RequestForControl, AllRows, Undefined, Undefined);
	InstallWizardPages(ThisObject, "FormationOfResearch");
	
EndProcedure

#EndRegion

#Region Private

#Region ResultOfFormation

&AtServer
Procedure CreateDocumentsOnServer(Cancel)
	
	Data = Undefined;
	AttributesList = StrSplit("Products,Characteristic,Series,Purpose,GoodsResearchSheet,ControlledLotReference,Control,Performer,Warehouse,Package,Count,Explore",",");
	TreeGoodsForResearch = FormAttributeToValue("GoodsForResearch");
	ConvertTreeToTable(TreeGoodsForResearch, AttributesList, Data);
	
	// Starting the formation
	CancelLongRunningOperation();
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Goods", Data);
	ProcedureParameters.Insert("RequestForControl", RequestForControl);
	ProcedureParameters.Insert("SeveralItemsInStudy", SeveralItemsInStudy);
	
	AddressIsResultOfFormation = PutToTempStorage(
		Documents.GoodsQualityResearch.ResultOfFormation(), UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập các nghiên cứu hàng hóa: tạo chứng từ';
														|ru = 'Формирование исследований товаров: создание документов';
														|en = 'Generate goods research: create documents'; fa = 'Generate goods research: create documents';
														|it = 'Generate goods research: create documents';
														|pl = 'Generate goods research: create documents';
														|tr = 'Ürün incelemelerinin oluşturulması: Belgelerin düzenlenmesi'");
	ExecutionParameters.ResultAddress = AddressIsResultOfFormation;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.GoodsQualityResearch.CreateDocumentsDeferred",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "CreateDocumentsDeferredCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		CreateDocumentsDeferred(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

// A tree in a table of values
// 
// Parameters:
// 	Tree - ValueTree, ValueTreeRow -
// 	AttributesList - Structure - List of tree Attributes
// 	Table - ValueTable, Undefined -
// 	Performer - CatalogRef.Users - Performer
// Returns:
// 	ValueTable, Undefined - LongDesc
&AtServer
Function ConvertTreeToTable(Tree, AttributesList, Table = Undefined, Performer = Undefined)
	
	If Table = Undefined Then
		Table = New ValueTable;
		For Each Column In AttributesList Do
			Table.Columns.Add(Column);
		EndDo;
	EndIf;
	
	For Each TreeRow In Tree.Rows Do
		
		If ValueIsFilled(TreeRow.Products) And TreeRow.SelectPosition Then
			NewRow = Table.Add();
			FillPropertyValues(NewRow, TreeRow);
			NewRow.Count = TreeRow.Explore;
			If Not ValueIsFilled(NewRow.Performer) And Performer <> Undefined Then
				NewRow.Performer = Performer;
			EndIf;
		EndIf;
		
		If ValueIsFilled(TreeRow.Performer) Then
			Performer = TreeRow.Performer;
		Else
			Performer = Undefined;
		EndIf;
		
		ConvertTreeToTable(TreeRow, AttributesList, Table, Performer);
		
	EndDo;
	
	Return Table;
	
EndFunction

&AtClient
Procedure CreateDocumentsDeferredCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	SetUpWaitingInForm(False);
	
	CreateDocumentsDeferred(Result);
	InstallWizardPages(ThisObject, "ResultOfFormation");
	
	If Result <> Undefined And Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateDocumentsDeferred(Result)

	If IsTempStorageURL(AddressIsResultOfFormation) Then

		ResultStructure1 = GetFromTempStorage(AddressIsResultOfFormation);
		AddressIsResultOfFormation = Undefined;

		ListProperties = Common.DynamicListPropertiesStructure();

		QueryText = Documents.GoodsQualityResearch.QueryTextOfDynamicGoodsResearchList();
		ListProperties.QueryText = QueryText;

		ListProperties.MainTable = "Document.GoodsQualityResearch";
		ListProperties.DynamicDataRead = True;

		Common.SetDynamicListProperties(Items.DocumentsList, ListProperties);

		LinksToCreatedDocuments = ResultStructure1.ResultOfFormation.UnloadColumn(
			"GoodsQualityResearch");

		CommonClientServer.SetDynamicListParameter(
									DocumentsList, "References", LinksToCreatedDocuments, ValueIsFilled(
			LinksToCreatedDocuments));

		CreatedObjects.LoadValues(ResultStructure1.CreatedObjects);

	EndIf;

	If TypeOf(Result) = Type("Structure") And Result.Property("Messages") Then
		For Each Message In Result.Messages Do
			Message.Message();
		EndDo;
	EndIf;

	If Result = Undefined Or Result.Status <> "Completed2" Then
		Common.MessageToUser(NStr("vi = 'Chứng từ chưa được lập đầy đủ';
									|ru = 'Документы сформированы не полностью';
									|en = 'Documents are not fully generated'; fa = 'Documents are not fully generated';
									|it = 'I documenti non sono stati creati completamente';
									|pl = 'Dokumenty zostały utworzone nie w całości';
									|tr = 'Belgeler tamamen oluşturulmadı'"));
	EndIf;

EndProcedure

&AtServer
Procedure CancelLongRunningOperation()
	
	If Not TimeConsumingOperation = Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction(OutputIdleWindow = True)
	
	CallbackOnCompletion = New CallbackDescription(TimeConsumingOperationIdleHandler, ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	IdleParameters.OutputIdleWindow = OutputIdleWindow;
	
	TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackOnCompletion,
			IdleParameters);
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtServer
Procedure Delete_CreatedObjects(Cancel)
	
	CancelLongRunningOperation();
	
	ProcedureParameters = New Structure("References", CreatedObjects.UnloadValues());
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Chỉ định nghiên cứu: xóa các đối tượng đã tạo';
			|ru = 'Назначение исследований: удаление созданных объектов';
			|en = 'Assignment of research: delete created objects'; fa = 'Assignment of research: delete created objects';
			|it = 'Assignment of research: delete created objects';
			|pl = 'Assignment of research: delete created objects';
			|tr = 'İnceleme atama: Oluşturulan nesnelerin silinmesi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.GoodsQualityResearch.DeleteObjectsOnHold",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		StartAwaitingLongAction = True;
		TimeConsumingOperationIdleHandler = "DeleteCreatedObjectsDeferredEnd";
		
	Else
		
		If TimeConsumingOperation.Status = "Error" Then
			Raise TimeConsumingOperation.BriefErrorDescription;
		EndIf;
		
		If TimeConsumingOperation.Status <> "Completed2" Then
			Cancel = True;
		EndIf;
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteCreatedObjectsDeferredEnd(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	SetUpWaitingInForm(False);
	
	If Result <> Undefined Then
		
		If Result.Status = "Error" Then
			Raise Result.BriefErrorDescription;
		EndIf;
		
		AfterDeletingCreatedObjects(Result.Status <> "Completed2");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDeletingCreatedObjects(Cancel)
	
	If Not Cancel Then
		
		CreatedObjects.Clear();
		
		ShowUserNotification(
			NStr("vi = 'Xóa các đối tượng';
				|ru = 'Удаление объектов';
				|en = 'Delete objects'; fa = 'Delete objects';
				|it = 'Eliminazione oggetti';
				|pl = 'Usunięcie obiektów';
				|tr = 'Nesnelerin silinmesi'"),
			,
			NStr("vi = 'Đặt dấu xóa các đối tượng đã tạo.';
				|ru = 'Сформированные объекты помечены на удаление.';
				|en = 'Generated objects are marked for deletion.'; fa = 'Generated objects are marked for deletion.';
				|it = 'Oggetti creati contrassegnati per l''eliminazione.';
				|pl = 'Utworzone obiekty są zaznaczone do usunięcia.';
				|tr = 'Oluşturulan nesneler silinmek üzere işaretlendi.'"));
		
		InstallWizardPages(ThisObject, "FormationOfResearch");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Preview

&AtClient
Procedure ExpandPreview(Command)
	
	For Each String In GoodsToPreview.GetItems() Do
		If Not Items.GoodsToPreview.Expanded(String.GetID()) Then
			Items.GoodsToPreview.Expand(String.GetID());
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapsePreview(Command)
	
	For Each String In GoodsToPreview.GetItems() Do
		If Items.GoodsToPreview.Expanded(String.GetID()) Then
			Items.GoodsToPreview.Collapse(String.GetID());
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure GenerateDataForPreview(Cancel)
	
	Data = Undefined;
	AttributesList = StrSplit("Products,Characteristic,Series,Purpose,GoodsResearchSheet,ControlledLotReference,Control,Performer,Warehouse,UnitOfMeasure,Package,Count,Explore",",");
	TreeGoodsForResearch = FormAttributeToValue("GoodsForResearch");
	ConvertTreeToTable(TreeGoodsForResearch, AttributesList, Data);

	If Data.Count() = 0 Then

		ErrorText = NStr("vi = 'Chưa chọn hàng hóa để nghiên cứu. Vui lòng đánh dấu vào các hàng hóa cần nghiên cứu và thử lại.';
						|ru = 'Не выбраны товары к исследованию. Отметьте флажками товары, которые необходимо исследовать и повторите попытку.';
						|en = 'No goods to research are selected. Select the goods to research and try again.'; fa = 'No goods to research are selected. Select the goods to research and try again.';
						|it = 'No goods to research are selected. Select the goods to research and try again.';
						|pl = 'No goods to research are selected. Select the goods to research and try again.';
						|tr = 'İnceleme için ürün seçilmedi. İncelenmesi gereken ürünleri işaretleyin ve tekrar deneyin.'");

		Common.MessageToUser(ErrorText, , , , Cancel);

		Return;

	EndIf;
	
	QuantityToStudy = Data.UnloadColumn("Explore");
	If QuantityToStudy.Find(0) <> Undefined Then
		ErrorText = NStr("vi = 'Chưa chỉ định số lượng cần nghiên cứu cho các hàng hóa đã chọn.';
						|ru = 'Для выбранных товаров не указано количество к исследованию.';
						|en = 'The quantity for research is not specified for the selected goods.'; fa = 'The quantity for research is not specified for the selected goods.';
						|it = 'The quantity for research is not specified for the selected goods.';
						|pl = 'The quantity for research is not specified for the selected goods.';
						|tr = 'Seçili ürünler için inceleme miktarı belirtilmemiş.'");

		Common.MessageToUser(ErrorText, , , , Cancel);

		Return;

	EndIf;
	
	GoodsToPreview.GetItems().Clear();
	
	GoodsTreeToPreview = FormAttributeToValue("GoodsToPreview");
	TreeRows = GoodsTreeToPreview.Rows;
	
	For Each TSRow In Data Do
		
		If SeveralItemsInStudy Then
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("GoodsResearchSheet", TSRow.GoodsResearchSheet);
			TheStructureOfTheSearch.Insert("Performer", TSRow.Performer);
		Else
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("GoodsResearchSheet", TSRow.GoodsResearchSheet);
			TheStructureOfTheSearch.Insert("Performer", TSRow.Performer);
			TheStructureOfTheSearch.Insert("Products", TSRow.Products);
			TheStructureOfTheSearch.Insert("Characteristic", TSRow.Characteristic);
		EndIf;
		
		FoundRows = TreeRows.FindRows(TheStructureOfTheSearch);

		If FoundRows.Count() = 0 Then
			TreeRow = TreeRows.Add();
			FillPropertyValues(TreeRow, TSRow, "GoodsResearchSheet, Performer");
			AddTreeLinePreview(TreeRow, TSRow);
		Else
			If SeveralItemsInStudy Then
				RowOfProduct = FoundRows[0];
				AddTreeLinePreview(RowOfProduct, TSRow);
			Else
				TreeRow = TreeRows.Add();
				FillPropertyValues(TreeRow, TSRow, "GoodsResearchSheet, Performer");
				AddTreeLinePreview(TreeRow, TSRow);
			EndIf;
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(GoodsTreeToPreview, "GoodsToPreview");
	
EndProcedure

&AtServer
Procedure AddTreeLinePreview(Parent, FillString)
	
	TreeRow = Parent.Rows.Add();
	TreeRow.LinePresentation = ProductsClientServer.ProductPresentation(
		FillString.Products,
		FillString.Characteristic,,
		FillString.Series,
		FillString.Purpose);
	FillPropertyValues(TreeRow, FillString,,"GoodsResearchSheet, Performer");
	
EndProcedure

#EndRegion

#Region Filters

&AtClient
Procedure BackCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	AddressIsResultOfFormation = Undefined;
	
	If CreatedObjects.Count() <> 0 Then
		
		Cancel = False;
		Delete_CreatedObjects(Cancel);
		
		If StartAwaitingLongAction Then
			StartAwaitingLongAction(False);
			SetUpWaitingInForm(True, NStr("vi = 'Đang xóa chứng từ...';
											|ru = 'Документы удаляются...';
											|en = 'Documents are being deleted...'; fa = 'Documents are being deleted...';
											|it = 'Documenti in eliminazione...';
											|pl = 'Trwa usunięcie dokumentów...';
											|tr = 'Belgeler siliniyor...'"));
		Else
			AfterDeletingCreatedObjects(Cancel);
		EndIf;
		
	Else
		InstallWizardPages(ThisObject, "Preview");
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToPreviewStep()
	
	Cancel = False;
	GenerateDataForPreview(Cancel);
	
	If Not Cancel Then
		InstallWizardPages(ThisObject, "Preview");
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToStepOfGeneratingResult()
	
	Cancel = False;
	CreateDocumentsOnServer(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	If StartAwaitingLongAction Then
		StartAwaitingLongAction(False);
		SetUpWaitingInForm(True, NStr("vi = 'Đang lập chứng từ...';
										|ru = 'Документы формируются...';
										|en = 'Documents are being generated...'; fa = 'Documents are being generated...';
										|it = 'Documenti in creazione...';
										|pl = 'Trwa utworzenie dokumentów...';
										|tr = 'Belgeler düzenleniyor...'"));
	Else
		InstallWizardPages(ThisObject, "ResultOfFormation");
	EndIf;
	
EndProcedure

#EndRegion

#Region MasterOfResearchAssignment

&AtServer
Procedure SelectedWhenChangingOnServer(Id)
	
	CurrentData = GoodsForResearch.FindByID(Id);
	Parent = CurrentData.GetParent();
	
	SelectExcludeLines(CurrentData.SelectPosition, CurrentData.GetID());
	
	If Parent <> Undefined Then
		UpdateParentRowSelection(CurrentData.GetID());
	EndIf;
	
EndProcedure

&AtServer
Procedure SelectExcludeSelectedLines(SelectionValue)
	
	Rows = GoodsForResearch.GetItems();
	
	For Each String In Rows Do
		
		String.SelectPosition = SelectionValue;
		
		SelectExcludeLines(SelectionValue, String.GetID());
		UpdateParentRowSelection(String.GetID());
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectExcludeLines(SelectionValue, Id = Undefined)
	
	If Id = Undefined Then
		CurElements = GoodsForResearch.GetItems();
	Else
		
		CurrentRow = GoodsForResearch.FindByID(Id);
		CurElements = CurrentRow.GetItems();
		
	EndIf;
	
	For Each String In CurElements Do
		String.SelectPosition = SelectionValue;
		SelectExcludeLines(SelectionValue, String.GetID());
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateParentRowSelection(Id)
	
	CurrentData = GoodsForResearch.FindByID(Id);
	Parent = CurrentData.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
	CurElements = Parent.GetItems();
	
	SelectedLines = 0;
	For Each String In CurElements Do
		If String.SelectPosition Then
			SelectedLines = SelectedLines + 1;
		EndIf;
	EndDo;
	
	If SelectedLines = CurElements.Count() Then
		Parent.SelectPosition = True;
	Else
		Parent.SelectPosition = False;
	EndIf;
	
	UpdateParentRowSelection(Parent.GetID());
	
EndProcedure

&AtServer
Procedure CreateResearchDestinationTreeAtServer(RequestForControl, AllRows, FilterProducts, FilterControlKind)
	
	Query = New Query;
	
	QueriesTexts = New Array;
	
	If AllRows Then
		QueryText =
		"SELECT
		|	Goods.LineNumber AS TheIndexOfTheData,
		|	Goods.Products AS Products,
		|	Goods.Products.ProductKind AS ProductKind,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Products.UnitOfMeasure AS UnitOfMeasure,
		|	Goods.Purpose AS Purpose,
		|	Goods.Purpose AS LineOfBusiness,
		|	Goods.Series AS Series,
		|	Goods.Count AS Count,
		|	&EmployeeResponsible AS EmployeeResponsible,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Package AS Package,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	Goods.ControlledLotReference AS ControlledLotReference
		|INTO TTListOfProducts
		|FROM
		|	Document.RequestForGoodsQualityControl.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|	AND &TextSelectionCriteriaByNomenclature
		|	AND NOT Goods.QualityIsConfirmed";
		
		Query.SetParameter("Ref", RequestForControl);
	Else
		QueryText =
		"SELECT
		|	Goods.LineNumber AS TheIndexOfTheData,
		|	Goods.Products,
		|	Goods.ProductKind AS ProductKind,
		|	Goods.Characteristic,
		|	Goods.UnitOfMeasure AS UnitOfMeasure,
		|	Goods.Purpose AS Purpose,
		|	Goods.Purpose AS LineOfBusiness,
		|	Goods.Series,
		|	Goods.Count,
		|	&EmployeeResponsible AS EmployeeResponsible,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Package AS Package,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	Goods.ControlledLotReference
		|INTO TTListOfProducts
		|FROM
		|	&SelectedRows AS Goods
		|WHERE
		|	&TextSelectionCriteriaByNomenclature";
		
		Query.SetParameter("SelectedRows", GoodsList.Unload());
		
	EndIf;
	
	If FilterProducts <> Undefined Then
		ConditionText = "Goods.Products = &Products ";
	Else
		ConditionText = "True";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TextSelectionCriteriaByNomenclature", ConditionText);
	
	QueriesTexts.Add(QueryText);
	
	ParametersForSelectingResearchDestination = GoodsResearch.ParametersForSelectingResearchDestination();
		
	ParametersOfResearchAssignmentRequest = GoodsResearch.ParametersOfResearchMapRequestText();
	ParametersOfResearchAssignmentRequest.NameOfInputTable         = "TTListOfProducts";
	ParametersOfResearchAssignmentRequest.OutputTableName         = "TTResearchAppointments";
	ParametersOfResearchAssignmentRequest.FinalPackageSeparator = False;
		
	QueriesTexts.Add(GoodsResearch.QueryTextOfGoodsResearchMaps(
																ParametersOfResearchAssignmentRequest,
																ParametersForSelectingResearchDestination));
																
	QueryText = "SELECT
	|	T.TheIndexOfTheData AS TheIndexOfTheData,
	|	T.Products AS Products,
	|	T.ProductKind AS ProductKind,
	|	T.Characteristic AS Characteristic,
	|	T.UnitOfMeasure AS UnitOfMeasure,
	|	T.Purpose AS Purpose,
	|	T.Series AS Series,
	|	T.Count AS Count,
	|	T.EmployeeResponsible AS Performer,
	|	T.Warehouse	AS Warehouse,
	|	T.Package AS Package,
	|	T.ControlledLotReference AS ControlledLotReference,
	|	T.NumberOfPackages AS NumberOfPackages,
	|	TTResearchAppointments.GoodsResearchSheet AS GoodsResearchSheet,
	|	TTResearchAppointments.Control AS Control,
	|	T.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS PieceUnitOfMeasure,
	|	TTResearchAppointments.TemplatesFilterOption AS TemplatesFilterOption,
	|	TTResearchAppointments.TamplatesNumber AS TamplatesNumber,
	|	TTResearchAppointments.TemplatesPercentage AS TemplatesPercentage
	|FROM
	|	TTListOfProducts AS T
	|		LEFT JOIN TTResearchAppointments AS TTResearchAppointments
	|		ON T.TheIndexOfTheData = TTResearchAppointments.TheIndexOfTheData
	|
	|WHERE
	|	&TextSelectionConditionByTypeOfControl
	|
	|ORDER BY
	|	T.TheIndexOfTheData";
	
	If FilterControlKind <> Undefined Then
		ConditionText = "TTResearchAppointments.GoodsResearchSheet.Control = &Control";
	Else
		ConditionText = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TextSelectionConditionByTypeOfControl", ConditionText);

	QueriesTexts.Add(QueryText);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.SetParameter("EmployeeResponsible", Common.ObjectAttributeValue(RequestForControl, "EmployeeResponsible"));
	
	If FilterProducts <> Undefined Then
		Query.SetParameter("Products", FilterProducts);
	EndIf;
	
	If FilterControlKind <> Undefined Then
		Query.SetParameter("Control", FilterControlKind);
	EndIf;
	
	GoodsResearch.SetParametersForRequestingGoodsResearchMaps(
			Query,
			ParametersForSelectingResearchDestination);
	
	Result = Query.Execute().Unload();
	
	ItemsWithoutStudyMaps = New Array;
	
	GoodsForResearch.GetItems().Clear();
	
	TreeGoodsForResearch = FormAttributeToValue("GoodsForResearch");
	TreeRows = TreeGoodsForResearch.Rows;
	
	For Each ResultString1 In Result Do
		
		If Not ValueIsFilled(ResultString1.GoodsResearchSheet) Then
			ItemsWithoutStudyMaps.Add(ResultString1.Products);
			Continue;
		EndIf;
		
		RowOfProduct = TreeRows.Find(ResultString1.GoodsResearchSheet, "GoodsResearchSheet");

		If RowOfProduct = Undefined Then
			TreeRow = TreeRows.Add();
			TreeRow.ExploreBrowsing = True;
			TreeRow.LinePresentation = String(ResultString1.GoodsResearchSheet);
			FillInControl(TreeRow, ResultString1);
			FillPropertyValues(TreeRow, ResultString1, "GoodsResearchSheet, Control");
			AddTreeRow(TreeRow, ResultString1);
		Else
			AddTreeRow(RowOfProduct, ResultString1);
		EndIf;
		
	EndDo;
	
	ItemsWithoutStudyMaps = CommonClientServer.CollapseArray(ItemsWithoutStudyMaps);
	
	If ItemsWithoutStudyMaps.Count() > 0 Then
		Template = NStr("vi = 'Sơ đồ nghiên cứu hàng hóa chưa được thiết lập cho mặt hàng ""%1""';
						|ru = 'Для номенклатуры ""%1"" не задана карта исследования товаров';
						|en = 'The goods research sheet is not set for the ""%1"" item'; fa = 'The goods research sheet is not set for the ""%1"" item';
						|it = 'The goods research sheet is not set for the ""%1"" item';
						|pl = 'The goods research sheet is not set for the ""%1"" item';
						|tr = '""%1"" öğesi için ürün inceleme kartı tanımlanmamış'");
		For Each ArrayElement In ItemsWithoutStudyMaps Do
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(Template, ArrayElement);
			Common.MessageToUser(MessageText);
		EndDo;
	EndIf;
	
	ValueToFormAttribute(TreeGoodsForResearch, "GoodsForResearch");
	
EndProcedure

&AtServer
Procedure AddTreeRow(Parent, FillString)
	
	TreeRow = Parent.Rows.Add();
	TreeRow.LinePresentation = ProductsClientServer.ProductPresentation(
		FillString.Products,
		FillString.Characteristic,,
		FillString.Series,
		FillString.Purpose);
	FillPropertyValues(TreeRow, FillString);
	
	FillInControl(TreeRow, FillString);
	
	If FillString.Control = Enums.QualityControl.Solid Then
		QuantityToExplore = FillString.Count;
	Else
		If FillString.TemplatesFilterOption = Enums.FilterOptionsOfGoodsResearchTemplates.Count Then
			QuantityToExplore = Min(FillString.Count, FillString.TamplatesNumber);
		Else
			QuantityToExplore = Round(FillString.Count * FillString.TemplatesPercentage / 100, ?(FillString.PieceUnitOfMeasure, 0, 3), 1);
		EndIf;
	EndIf;
	
	TreeRow.TamplatesNumber = QuantityToExplore;
	TreeRow.Explore = QuantityToExplore;
	
	If QuantityToExplore <> 0 Then
		TreeRow.SelectPosition = True;
	EndIf;
	
	// Update the parent's selection
	SelectedLines = 0;
	For Each String In Parent.Rows Do
		If String.SelectPosition Then
			SelectedLines = SelectedLines + 1;
		EndIf;
	EndDo;
	
	If SelectedLines = Parent.Rows.Count() Then
		Parent.SelectPosition = True;
	Else
		Parent.SelectPosition = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInControl(TreeRow, FillString)
	
	TemplateQuantity = NStr("vi = '%1, %2';
							|ru = '%1, %2';
							|en = '%1, %2'; fa = '%1, %2';
							|it = '%1, %2';
							|pl = '%1, %2';
							|tr = '%1, %2'");
	PercentageTemplate = NStr("vi = '%1, %2%';
								|ru = '%1, %2%';
								|en = '%1, %2%'; fa = '%1, %2%';
								|it = '%1, %2%';
								|pl = '%1, %2%';
								|tr = '%1, %2%'");

	If FillString.Control = Enums.QualityControl.Selective Then
		If FillString.TemplatesFilterOption = Enums.FilterOptionsOfGoodsResearchTemplates.Percent Then
			PresentationOfSamplesForResearch = StringFunctionsClientServer.SubstituteParametersToString(PercentageTemplate,
				FillString.Control, FillString.TemplatesPercentage);
		Else
			PresentationOfNumberOfSamplesToBeExamined = GetStringDeclensionsByNumber("pattern",
				FillString.TamplatesNumber, "", "NM=Cardinal", "CS=Nominative; NP=Number");
			PresentationOfSamplesForResearch = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateQuantity, FillString.Control, PresentationOfNumberOfSamplesToBeExamined[0]);
		EndIf;
		TreeRow.PresentationOfControlLine = PresentationOfSamplesForResearch;
	Else
		TreeRow.PresentationOfControlLine = String(FillString.Control);
	EndIf;

EndProcedure

#EndRegion

#Region FillType

&AtClient
Procedure FillInPerformerCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(AdditionalParameters.SelectedRows) = Type("Array") Then
		ArrayOfIdentifiers = AdditionalParameters.SelectedRows;
	Else
		ArrayOfIdentifiers = CommonClientServer.ValueInArray(AdditionalParameters.SelectedRows);
	EndIf;
	
	For Each String In ArrayOfIdentifiers Do
		
		GoodsForResearch.FindByID(String).Performer = Result;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetPropertiesOfDynamicCheckList(GoodsResearchSheet = Undefined)
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = Catalogs.GoodsResearchSheets.QueryTextOfCheckList();
	ListProperties.QueryText = QueryText;
	
	ListProperties.MainTable = "";
	ListProperties.DynamicDataRead = False;
	
	Common.SetDynamicListProperties(Items.ChecksKinds, ListProperties);
	
	CommonClientServer.SetDynamicListParameter(
									ChecksKinds, "Ref", GoodsResearchSheet);
	
EndProcedure

#EndRegion

#Region SettingManagement

&AtServer
Procedure RestoreFormSettingsWhenCreating()
	
	FormSettings = FormDataSettingsStorage.Load(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey());
	If ValueIsFilled(FormSettings) Then
		FillPropertyValues(ThisObject, FormSettings);
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveFormSettings()
	
	FormSettings = SavedFormSettings();
	
	FillPropertyValues(FormSettings, ThisObject);
	FormDataSettingsStorage.Save(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey(), FormSettings);
	
EndProcedure

&AtServer
Function SavedFormSettings()
	
	Result = New Structure;
	Result.Insert("SeveralItemsInStudy");
	
	Return Result;
	
EndFunction

&AtServer
Function ObjectKeySettingsManager()
	
	Return "GenerationWizard";
	
EndFunction

&AtServer
Function SettingsManagerSettingsKey()
	
	Return "FormSettings";
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "DocumentsList.Date");
	
	// Viewing only.
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("GoodsForResearchLinePresentation");
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("GoodsForResearchUnitOfMeasure");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("GoodsForResearchCount");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("GoodsForResearchPresentationOfControlLine");
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("GoodsForResearchExplore");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("GoodsForResearch.ExploreBrowsing");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;
	
	// The quantity for the study is not set in the study map
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa chỉ định trong sơ đồ nghiên cứu, nhập thủ công>';
																		|ru = '<В карте исследования не указано, ввести вручную>';
																		|en = '<Not specified in the research sheet, enter manually>'; fa = '<Not specified in the research sheet, enter manually>';
																		|it = '<Not specified in the research sheet, enter manually>';
																		|pl = '<Not specified in the research sheet, enter manually>';
																		|tr = '<İnceleme kartında belirtilmemiş, manuel girin>""'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("ItemsForResearchNumberOfSamples");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("GoodsForResearch.TamplatesNumber");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("GoodsForResearch.Products");
	FilterElement.ComparisonType = DataCompositionComparisonType.Filled;
	
	// No quantity has been assigned for the study
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("GoodsForResearchSelectPosition");
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("GoodsForResearch.Explore");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("GoodsForResearch.Products");
	FilterElement.ComparisonType = DataCompositionComparisonType.Filled;
	
EndProcedure

&AtClientAtServerNoContext
Procedure InstallWizardPages(Form, StepName)
	
	Items = Form.Items;
	
	If StepName = "FormationOfResearch" Then
		
		Items.GroupPages.CurrentPage = Items.MasterPage;
		
		Items.Next.Visible = True;
		Items.Back.Visible = False;
		Items.GenerateAgain.Visible = False;
		Items.Next.DefaultButton = True;
		Items.Next.Title = NStr("vi = 'Tiếp theo';
								|ru = 'Далее';
								|en = 'Next'; fa = 'بعدی';
								|it = 'Avanti';
								|pl = 'Dalej';
								|tr = 'İleri'");
		Items.Close.Title = NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Cancel';
								|pl = 'Cancel';
								|tr = 'İptal'");
		
	ElsIf StepName = "ResultOfFormation" Then
		
		Items.GroupPages.CurrentPage = Items.ResultPage;
		
		Items.Next.Visible = False;
		Items.Back.Visible = True;
		Items.GenerateAgain.Visible = True;
		Items.Close.DefaultButton = True;
		Items.Close.Title = NStr("vi = 'Đóng';
								|ru = 'Закрыть';
								|en = 'Close'; fa = 'بستن';
								|it = 'Chiudere';
								|pl = 'Zamknij';
								|tr = 'Kapat'");
	
	ElsIf StepName = "Preview" Then
		
		Items.GroupPages.CurrentPage = Items.Preview_Page;
		
		Items.Next.Visible = True;
		Items.Back.Visible = True;
		Items.GenerateAgain.Visible = False;
		Items.Next.DefaultButton = True;
		Items.Next.Title = NStr("vi = 'Tạo chứng từ';
								|ru = 'Сформировать документы';
								|en = 'Generate documents'; fa = 'ایجاد اسناد';
								|it = 'Formare i documenti';
								|pl = 'Generuj dokumenty';
								|tr = 'Belgeleri oluştur'");
		Items.Close.Title = NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Cancel';
								|pl = 'Cancel';
								|tr = 'İptal'");
		
	EndIf;
	
	ConfigureDependentFormElements(Form, "CurrentPage");
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Show_Details") 
		Or Initialize Then
		
		Items.ChecksKinds.Visible = Form.Show_Details;
		Items.Show_Details.Title = ?(Form.Show_Details,
			NStr("vi = 'Thông tin chi tiết (ẩn)';
				|ru = 'Детальная информация (скрыть)';
				|en = 'Detailed information (hide)'; fa = 'Detailed information (hide)';
				|it = 'Informazioni dettagliate (nascondere)';
				|pl = 'Szczegółowe informacje (ukryj)';
				|tr = 'Ayrıntılı bilgi (gizle)'"),
			NStr("vi = 'Thông tin chi tiết (hiển thị)';
				|ru = 'Детальная информация (показать)';
				|en = 'Detailed information (show)'; fa = 'Detailed information (show)';
				|it = 'Informazione dettagliata (mostrare)';
				|pl = 'Szczegółowe informacje (pokaż)';
				|tr = 'Ayrıntılı bilgi (göster)'"));
		
	EndIf;
	
	If AttributesStructure1.Property("CurrentPage")
		Or Initialize Then
		
		If Items.GroupPages.CurrentPage = Items.MasterPage Then
			Items.Subtitle.Title = NStr("vi = 'Bước 1/3. Chỉ định nghiên cứu.';
										|ru = 'Шаг 1 из 3. Назначение исследований';
										|en = 'Step 1 of 3. Assignment of researches'; fa = 'Step 1 of 3. Assignment of researches';
										|it = 'Step 1 of 3. Assignment of researches';
										|pl = 'Step 1 of 3. Assignment of researches';
										|tr = 'Adım 1/3. İnceleme atama'");
		ElsIf Items.GroupPages.CurrentPage = Items.Preview_Page Then
			Items.Subtitle.Title = NStr("vi = 'Bước 2/3. Xem trước';
										|ru = 'Шаг 2 из 3. Предварительный просмотр';
										|en = 'Step 2 of 3. Preview'; fa = 'Step 2 of 3. Preview';
										|it = 'Step 2 of 3. Preview';
										|pl = 'Step 2 of 3. Preview';
										|tr = 'Adım 2/3. Önizleme'");
		Else
			Items.Subtitle.Title = NStr("vi = 'Bước 3/3. Xem các chứng từ đã tạo';
										|ru = 'Шаг 3 из 3. Просмотр созданных документов';
										|en = 'Step 3 of 3. View created documents'; fa = 'Step 3 of 3. View created documents';
										|it = 'Step 3 of 3. View created documents';
										|pl = 'Step 3 of 3. View created documents';
										|tr = 'Adım 3/3. Oluşturulan belgelerin görüntülenmesi'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StructuresArrayIntoValueTable(StructuresArray, ValueTable)
	
	For Each Item In StructuresArray Do
		FillPropertyValues(ValueTable.Add(), Item);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetUpWaitingInForm(ShowTimeConsumingOperation, PresentationOperation = "")
	
	Items.FormPages.CurrentPage = ?(ShowTimeConsumingOperation,
		Items.TimeConsumingOperationPage, Items.PageElements);
	Items.Transition.Enabled = Not ShowTimeConsumingOperation;
	
	Items.TimeConsumingOperationPresentation.Title = PresentationOperation;
	
EndProcedure

#EndRegion

#EndRegion
