
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Or Not Parameters.Property("AvailableBusinessTransactionsAndDocuments") Then
		Return;
	EndIf;
	
	AddressAvailableBusinessTransactionsAndDocuments = Parameters.AvailableBusinessTransactionsAndDocuments;
	
	CreateMode = False;
	If Parameters.Property("CreateMode",CreateMode) Then
		Items.FormSelectCreate.Title = NStr("vi = 'Tạo mới';
											|ru = 'Создать';
											|en = 'Create'; fa = 'ایجاد';
											|it = 'Creare';
											|pl = 'Create';
											|tr = 'Oluştur'");
		Title = NStr("vi = 'Tạo một chứng từ giao dịch kinh doanh';
					|ru = 'Создание документа по хозяйственной операции';
					|en = 'Create document by business transaction'; fa = 'Create document by business transaction';
					|it = 'Creazione di un documento di transazione economica';
					|pl = 'Tworzenie dokumentu operacji gospodarczej';
					|tr = 'Ticari işleme ilişkin belgenin oluşturulması'");
		Items.BusinessTransactionTreeFilter.Visible = False;
		Items.TreeByDocumentsFilter.Visible = False;
		Items.FormClearCheckBoxes.Visible = False;
		Items.FormSelectCheckBoxes.Visible = False;
	EndIf;
	
	Parameters.Property("SettingsKey", SettingsKey);
	Parameters.Property("FormKey", FormKey);
	Parameters.Property("OnlyByDocumentTypes", OnlyByDocumentTypes);
	
	If OnlyByDocumentTypes Then
		
		Hierarchy = "ByDocuments";
		Title = NStr("vi = 'Chọn chứng từ';
					|ru = 'Выбор документов';
					|en = 'Select documents'; fa = 'انتخاب اسناد';
					|it = 'Scelta dei documenti';
					|pl = 'Wybór dokumentów';
					|tr = 'Belgeleri seç'");
		Items.FormByBusinessTransactions.Visible = False;
		Items.ByDocuments.Visible = False;

	Else
		
		FormSettings = Common.CommonSettingsStorageLoad(SettingsKey+FormKey, CreateMode);
		If ValueIsFilled(FormSettings) Then
			Hierarchy = FormSettings.Hierarchy;
			CurrentBusinessTransaction = FormSettings.BusinessOperation;
			CurIDOfMetadataObject = FormSettings.MetadataObjectID;
		EndIf;
		
		If Not ValueIsFilled(Hierarchy) Then
			Hierarchy = "ByDocuments";
		EndIf;
	
	EndIf;
	
	If Hierarchy = "ForBusinessTransactions" Then
		Items.PagesFilterTree.CurrentPage = Items.PageByBusinessTransactions;
		FillInTreeForBusinessOperations();
		Items.FormByBusinessTransactions.Check = True;
		Items.ByDocuments.Check = False;
	Else
		Items.PagesFilterTree.CurrentPage = Items.PageOnDocuments;
		FillInTreeByDocuments();
		Items.FormByBusinessTransactions.Check = False;
		Items.ByDocuments.Check = True;
	EndIf;
	
	If CreateMode And ValueIsFilled(FormSettings) Then
		If Hierarchy = "ForBusinessTransactions" Then
			For Each TreeItem In BusinessTransactionTree.GetItems() Do
				If TreeItem.BusinessOperation = CurrentBusinessTransaction Then
					For Each ItemValue1 In TreeItem.GetItems() Do
						If ItemValue1.MetadataObjectID = CurIDOfMetadataObject Then
							If TreeItem.ItemCount = 1 Then
								Items.BusinessTransactionTree.CurrentRow = TreeItem.GetID();
							Else
								Items.BusinessTransactionTree.CurrentRow = ItemValue1.GetID();
							EndIf;
						EndIf;
					EndDo;
				EndIf
			EndDo;
		Else
			For Each TreeItem In TreeByDocuments.GetItems() Do
				If TreeItem.MetadataObjectID = CurIDOfMetadataObject Then
					For Each ItemValue1 In TreeItem.GetItems() Do
						If ItemValue1.BusinessOperation = CurrentBusinessTransaction Then
							If TreeItem.ItemCount = 1 Then
								Items.TreeByDocuments.CurrentRow = TreeItem.GetID();
							Else
								Items.TreeByDocuments.CurrentRow = ItemValue1.GetID();
							EndIf;
						EndIf;
					EndDo;
				EndIf
			EndDo;
		EndIf
	EndIf;
	
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ExpandTheTree();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TreeSelectionOnChange(Item)
	
	If Hierarchy = "ForBusinessTransactions" Then
		CurrentData = Items.BusinessTransactionTree.CurrentData;
	Else
		CurrentData = Items.TreeByDocuments.CurrentData;
	EndIf;
	
	Parent = CurrentData.GetParent();
	
	If Parent = Undefined Then // parent row selected
		
		SubordinateTreeItems = CurrentData.GetItems();
		
		For Each TreeItem In SubordinateTreeItems Do
			TreeItem.Filter = CurrentData.Filter;
		EndDo;
		
	Else
		
		If CurrentData.Filter Then
			Parent.Filter = True;
		Else
			FilterIs_Specified = False;
			For Each TreeItem In Parent.GetItems() Do
				FilterIs_Specified = FilterIs_Specified Or TreeItem.Filter;
			EndDo;
			Parent.Filter = FilterIs_Specified;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessTransactionTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Hierarchy = "ForBusinessTransactions" Then
		CurrentData = Items.BusinessTransactionTree.CurrentData;
	Else
		CurrentData = Items.TreeByDocuments.CurrentData;
	EndIf;
	
	If CreateMode And (CurrentData.ItemCount = 1
			Or CurrentData.ItemCount = 0) Then
		StandardProcessing = False;
		EndCreation();
	EndIf;
	
EndProcedure

&AtClient
Procedure TreeByDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Hierarchy = "ForBusinessTransactions" Then
		CurrentData = Items.BusinessTransactionTree.CurrentData;
	Else
		CurrentData = Items.TreeByDocuments.CurrentData;
	EndIf;
	
	If CreateMode And (CurrentData.ItemCount = 1
			Or CurrentData.ItemCount = 0) Then
		StandardProcessing = False;
		EndCreation();
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectCreate(Command)
	
	If CreateMode Then
		EndCreation();
	Else
		
		SaveFormSettings();
		SaveSelections();
		NotifyChoice(AddressAvailableBusinessTransactionsAndDocuments);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EndCreation()
	
	If Hierarchy = "ForBusinessTransactions" Then
		CurrentData = Items.BusinessTransactionTree.CurrentData;
		WarningText = NStr("vi = 'Chọn một giao dịch kinh doanh.';
							|ru = 'Выберите хозяйственную операцию.';
							|en = 'Select a business transaction.'; fa = 'Select a business transaction.';
							|it = 'Selezionare una transazione economica.';
							|pl = 'Wybierz operację gospodarczą.';
							|tr = 'Ticari işlemi seçin.'");
	Else
		CurrentData = Items.TreeByDocuments.CurrentData;
		WarningText = NStr("vi = 'Chọn một chứng từ.';
							|ru = 'Выберите документ.';
							|en = 'Select a document.'; fa = 'Select a document.';
							|it = 'Selezionare un documento.';
							|pl = 'Wybierz dokument.';
							|tr = 'Belgeyi seçin.'");
	EndIf;
	
	If CurrentData = Undefined Then
		ShowMessageBox(,WarningText,,NStr("vi = 'Lỗi lựa chọn.';
											|ru = 'Ошибка выбора.';
											|en = 'Selection error.'; fa = 'Selection error.';
											|it = 'Errore di selezione.';
											|pl = 'Błąd wyboru.';
											|tr = 'Seçim hatası'"));
		Return;
	EndIf;
	
	Parent = CurrentData.GetParent();
	
	If Parent = Undefined Then
		
		If CurrentData.ItemCount > 1 Then
			ShowMessageBox(,WarningText,,NStr("vi = 'Lỗi lựa chọn.';
												|ru = 'Ошибка выбора.';
												|en = 'Selection error.'; fa = 'Selection error.';
												|it = 'Errore di selezione.';
												|pl = 'Błąd wyboru.';
												|tr = 'Seçim hatası'"));
			Return;
		Else
			CurrentBusinessTransaction = CurrentData.GetItems()[0].BusinessOperation;
			CurrentID = CurrentData.GetItems()[0].MetadataObjectID;
		EndIf;
		
	Else
		
		CurrentBusinessTransaction = CurrentData.BusinessOperation;
		CurrentID = CurrentData.MetadataObjectID;
				
	EndIf;
	
	StructureOfCreation = New Structure;
	StructureOfCreation.Insert("BusinessOperation", CurrentBusinessTransaction);
	StructureOfCreation.Insert("MetadataObjectID", CurrentID);
	
	SaveFormSettings(CurrentData.BusinessOperation, CurrentData.MetadataObjectID);
	
	Close(StructureOfCreation);

		
EndProcedure

&AtClient
Procedure ClearCheckBoxes(Command)
	
	If Hierarchy = "ForBusinessTransactions" Then
		Tree = BusinessTransactionTree;
	Else
		Tree = TreeByDocuments;
	EndIf;
	
	For Each String In Tree.GetItems() Do
		
		String.Filter = False;
		
		For Each SubordinateLine In String.GetItems() Do
			SubordinateLine.Filter = False;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectCheckBoxes(Command)
	
	If Hierarchy = "ForBusinessTransactions" Then
		Tree = BusinessTransactionTree;
	Else
		Tree = TreeByDocuments;
	EndIf;
	
	For Each String In Tree.GetItems() Do
		
		String.Filter = True;
		
		For Each SubordinateLine In String.GetItems() Do
			SubordinateLine.Filter = True;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ByBusinessTransactions(Command)

	If Hierarchy = "ForBusinessTransactions" Then
		Return;
	EndIf;
	
	Hierarchy = "ForBusinessTransactions";
	
	HierarchyWhenChangingOnServer();
	
	ExpandTheTree();
	
EndProcedure

&AtClient
Procedure ByDocuments(Command)
	
	If Hierarchy = "ByDocuments" Then
		Return;
	EndIf;
	
	Hierarchy = "ByDocuments";
	
	HierarchyWhenChangingOnServer();
	
	ExpandTheTree();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BusinessTransactionTreeFilter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessTransactionTree.Picture");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeByDocumentsFilter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeByDocuments.Picture");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure FillInTreeForBusinessOperations()
	
	Tree = FormAttributeToValue("BusinessTransactionTree"); 
	Tree.Rows.Clear();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CAST(AvailableBusinessTransactionsAndDocuments.BusinessOperation AS Enum.BusinessTransactions) AS BusinessOperation,
	|	AvailableBusinessTransactionsAndDocuments.MetadataObjectID,
	|	AvailableBusinessTransactionsAndDocuments.Filter,
	|	AvailableBusinessTransactionsAndDocuments.DocumentPresentation
	|INTO AvailableBusinessTransactionsAndDocuments
	|FROM
	|	&AvailableBusinessTransactionsAndDocuments AS AvailableBusinessTransactionsAndDocuments
	|WHERE
	|	AvailableBusinessTransactionsAndDocuments.AddButtonCreate OR &ChoiceMode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AvailableBusinessTransactionsAndDocuments.BusinessOperation AS BusinessOperation,
	|	PRESENTATION(AvailableBusinessTransactionsAndDocuments.BusinessOperation) AS BusinessOperationPresentation
	|FROM
	|	AvailableBusinessTransactionsAndDocuments AS AvailableBusinessTransactionsAndDocuments";
	Query.SetParameter("AvailableBusinessTransactionsAndDocuments", GetFromTempStorage(AddressAvailableBusinessTransactionsAndDocuments));
	Query.SetParameter("ChoiceMode", Not CreateMode);
	TableOfBusinessTransactionsPresentation = Query.Execute().Unload();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	AvailableBusinessTransactionsAndDocuments.BusinessOperation AS BusinessOperation,
	|	AvailableBusinessTransactionsAndDocuments.MetadataObjectID,
	|	AvailableBusinessTransactionsAndDocuments.Filter,
	|	AvailableBusinessTransactionsAndDocuments.DocumentPresentation,
	|	AvailableBusinessTransactionsAndDocuments.AccessRightInsert
	|INTO AvailableBusinessTransactionsAndDocuments
	|FROM
	|	&AvailableBusinessTransactionsAndDocuments AS AvailableBusinessTransactionsAndDocuments
	|WHERE
	|	AvailableBusinessTransactionsAndDocuments.AddButtonCreate OR &ChoiceMode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfBusinessTransactionsPresentation.BusinessOperation AS BusinessOperation,
	|	CAST(TableOfBusinessTransactionsPresentation.BusinessOperationPresentation AS STRING(100)) AS BusinessOperationPresentation
	|INTO TableOfBusinessTransactionsPresentation
	|FROM
	|	&TableOfBusinessTransactionsPresentation AS TableOfBusinessTransactionsPresentation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailableBusinessTransactionsAndDocuments.BusinessOperation AS BusinessOperation,
	|	AvailableBusinessTransactionsAndDocuments.MetadataObjectID,
	|	AvailableBusinessTransactionsAndDocuments.Filter,
	|	AvailableBusinessTransactionsAndDocuments.DocumentPresentation
	|FROM
	|	AvailableBusinessTransactionsAndDocuments AS AvailableBusinessTransactionsAndDocuments
	|		INNER JOIN TableOfBusinessTransactionsPresentation AS TableOfBusinessTransactionsPresentation
	|		ON AvailableBusinessTransactionsAndDocuments.BusinessOperation = TableOfBusinessTransactionsPresentation.BusinessOperation
	|WHERE
	|	(&ChoiceMode
	|			OR (AvailableBusinessTransactionsAndDocuments.Filter AND AvailableBusinessTransactionsAndDocuments.AccessRightInsert))
	|
	|ORDER BY
	|	TableOfBusinessTransactionsPresentation.BusinessOperationPresentation";
	
	Query.SetParameter("TableOfBusinessTransactionsPresentation", TableOfBusinessTransactionsPresentation);
	Query.SetParameter("AvailableBusinessTransactionsAndDocuments", GetFromTempStorage(AddressAvailableBusinessTransactionsAndDocuments));
	Query.SetParameter("ChoiceMode", Not CreateMode);
	
	PresentationFormationParameters = New Structure;
	PresentationFormationParameters.Insert("OnlyConsignmentSales25", GetFunctionalOption("OnlyConsignmentSales25"));
	PresentationFormationParameters.Insert("ObjectOfImplementationAdjustment", Common.MetadataObjectID(Metadata.Documents.SaleAdjustment));
	
	Selection = Query.Execute().Select();
	
	While Selection.NextByFieldValue("BusinessOperation") Do
		
		HierarchyLine = Tree.Rows.Add();
		HierarchyLine.BusinessOperation = Selection.BusinessOperation;
		HierarchyLine.Presentation = PresentationOfBusinessTransaction(Selection, PresentationFormationParameters);
		HierarchyLine.Picture = 0;
		
		FilterIs_Specified = False;
		
		While Selection.Next() Do
			
			If Not PresentationFormationParameters.OnlyConsignmentSales25 Then
				If Selection.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
					Or Selection.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
					AddBusinessOperationsCommission25(Tree, Selection);
					Continue;
				EndIf;
			EndIf;
			
			ValueRow = HierarchyLine.Rows.Add();
			ValueRow.BusinessOperation = Selection.BusinessOperation;
			ValueRow.MetadataObjectID = Selection.MetadataObjectID;
			ValueRow.Filter = Selection.Filter;
			ValueRow.Presentation = TrimAll(Selection.DocumentPresentation);
			ValueRow.Picture = 1;
			
			HierarchyLine.ItemCount = HierarchyLine.ItemCount + 1;
			
			FilterIs_Specified = FilterIs_Specified Or Selection.Filter;
		EndDo;
		
		If FilterIs_Specified Then
			HierarchyLine.Filter = True;
		
			For Each ValueRow In HierarchyLine.Rows Do
				ValueRow.Filter = True;
			EndDo;
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(Tree,"BusinessTransactionTree");
	
EndProcedure

&AtServer
Procedure FillInTreeByDocuments()
	
	Tree = FormAttributeToValue("TreeByDocuments"); 
	Tree.Rows.Clear();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	AvailableBusinessTransactionsAndDocuments.BusinessOperation                           AS BusinessOperation,
	|	AvailableBusinessTransactionsAndDocuments.MetadataObjectID                  AS MetadataObjectID,
	|	AvailableBusinessTransactionsAndDocuments.Filter                                           AS Filter,
	|	AvailableBusinessTransactionsAndDocuments.Order                                         AS LogOrder,
	|	CAST(AvailableBusinessTransactionsAndDocuments.DocumentPresentation AS STRING(100)) AS DocumentPresentation,
	|	AvailableBusinessTransactionsAndDocuments.AccessRightInsert                          AS AccessRightInsert
	|INTO AvailableBusinessTransactionsAndDocuments
	|FROM
	|	&AvailableBusinessTransactionsAndDocuments AS AvailableBusinessTransactionsAndDocuments
	|WHERE
	|	AvailableBusinessTransactionsAndDocuments.AddButtonCreate OR &ChoiceMode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailableBusinessTransactionsAndDocuments.MetadataObjectID  AS MetadataObjectID,
	|	MIN(AvailableBusinessTransactionsAndDocuments.LogOrder)         AS LogOrderGroup
	|INTO AvailableBusinessTransactionsAndGroupDocuments
	|FROM
	|	AvailableBusinessTransactionsAndDocuments AS AvailableBusinessTransactionsAndDocuments
	|GROUP BY
	|	AvailableBusinessTransactionsAndDocuments.MetadataObjectID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailableBusinessTransactionsAndDocuments.BusinessOperation          AS BusinessOperation,
	|	AvailableBusinessTransactionsAndDocuments.MetadataObjectID AS MetadataObjectID,
	|	AvailableBusinessTransactionsAndDocuments.Filter                          AS Filter,
	|	AvailableBusinessTransactionsAndGroupDocuments.LogOrderGroup     AS LogOrderGroup,
	|	AvailableBusinessTransactionsAndDocuments.LogOrder                 AS LogOrder,
	|	AvailableBusinessTransactionsAndDocuments.DocumentPresentation          AS DocumentPresentation,
	|	BusinessTransactions.Order                                           AS Order,
	|	
	|	CASE
	|		WHEN AvailableBusinessTransactionsAndDocuments.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|			THEN 0
	|		WHEN AvailableBusinessTransactionsAndDocuments.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|				OR AvailableBusinessTransactionsAndDocuments.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|			THEN 2
	|		WHEN AvailableBusinessTransactionsAndDocuments.BusinessOperation IN(&BusinessTransactionsPurchasingFromSupplier)
	|			THEN 1
	|		WHEN AvailableBusinessTransactionsAndDocuments.BusinessOperation IN(&BusinessTransactionsImportPurchase)
	|			THEN 3
	|		WHEN AvailableBusinessTransactionsAndDocuments.BusinessOperation IN(&BusinessTransactionsProcurementInEAEUCountries)
	|			THEN 4
	|		WHEN AvailableBusinessTransactionsAndDocuments.BusinessOperation IN(&BusinessTransactionsAdmissionToCommission)
	|			THEN 5
	|		ELSE 6
	|	END                                                                   AS Number
	|FROM
	|	AvailableBusinessTransactionsAndDocuments AS AvailableBusinessTransactionsAndDocuments
	|	INNER JOIN AvailableBusinessTransactionsAndGroupDocuments AS AvailableBusinessTransactionsAndGroupDocuments
	|		ON AvailableBusinessTransactionsAndGroupDocuments.MetadataObjectID = AvailableBusinessTransactionsAndDocuments.MetadataObjectID
	|	LEFT JOIN Enum.BusinessTransactions AS BusinessTransactions
	|		ON BusinessTransactions.Ref = AvailableBusinessTransactionsAndDocuments.BusinessOperation
	|WHERE
	|	(&ChoiceMode
	|			OR (AvailableBusinessTransactionsAndDocuments.Filter AND AvailableBusinessTransactionsAndDocuments.AccessRightInsert))
	|
	|ORDER BY
	|	LogOrderGroup,
	|	LogOrder,
	|	DocumentPresentation,
	|	Number,
	|	Order";
	
	DefaultParameter = New Array;
	
	AvailableBusinessTransactionsAndDocuments = GetFromTempStorage(AddressAvailableBusinessTransactionsAndDocuments); // See TMCommonUse.NewTableBusinessOperationsAndDocuments
	
	If AvailableBusinessTransactionsAndDocuments.Columns.Find("Order") = Undefined Then
		AvailableBusinessTransactionsAndDocuments.Columns.Add("Order",
			New TypeDescription("Number", New NumberQualifiers(10, 0)));
	EndIf;
	
	Query.SetParameter("AvailableBusinessTransactionsAndDocuments", AvailableBusinessTransactionsAndDocuments);
	Query.SetParameter("ChoiceMode", Not CreateMode);
	
	Query.SetParameter("BusinessTransactionsPurchasingFromSupplier",           DefaultParameter);
	Query.SetParameter("BusinessTransactionsImportPurchase",             DefaultParameter);
	Query.SetParameter("BusinessTransactionsAdmissionToCommission",              DefaultParameter);
	Query.SetParameter("BusinessTransactionsAcceptanceForResponsibleStorage", DefaultParameter);
	Query.SetParameter("BusinessTransactionsProcurementInEAEUCountries",          DefaultParameter);
	Query.SetParameter("BusinessTransactionsGoodsInTransit",                  DefaultParameter);
	Query.SetParameter("BusinessTransactionsUnfacturedDeliveries",    DefaultParameter);
	Query.SetParameter("BusinessTransactionsDoNotShareProcurementProcessing", DefaultParameter);
	
	PurchasesServer.FillInParametersOfRequestForOrderingBusinessOperations(Query.Parameters);
	
	PresentationFormationParameters = New Structure;
	PresentationFormationParameters.Insert("OnlyConsignmentSales25", GetFunctionalOption("OnlyConsignmentSales25"));
	PresentationFormationParameters.Insert("ObjectOfImplementationAdjustment", Common.MetadataObjectID(Metadata.Documents.SaleAdjustment));
	
	Selection = Query.Execute().Select();
	
	While Selection.NextByFieldValue("MetadataObjectID") Do
		
		HierarchyLine = Tree.Rows.Add();
		HierarchyLine.MetadataObjectID = Selection.MetadataObjectID;
		HierarchyLine.Presentation = TrimAll(Selection.DocumentPresentation);
		HierarchyLine.Picture = 1;
		
		FilterIs_Specified = False;
		
		While Selection.Next() Do
			
			If Not OnlyByDocumentTypes Then
				
				ValueRow = HierarchyLine.Rows.Add();
				ValueRow.MetadataObjectID = Selection.MetadataObjectID;
				ValueRow.BusinessOperation = Selection.BusinessOperation;
				ValueRow.Filter = Selection.Filter;
				ValueRow.Presentation = PresentationOfBusinessTransaction(Selection, PresentationFormationParameters);
				ValueRow.Picture = 0;
				
				HierarchyLine.ItemCount = HierarchyLine.ItemCount + 1;
			
			EndIf;
			
			FilterIs_Specified = FilterIs_Specified Or Selection.Filter;
		EndDo;
		
		If FilterIs_Specified Then
			HierarchyLine.Filter = True;
			
			If Not OnlyByDocumentTypes Then
				
				For Each ValueRow In HierarchyLine.Rows Do
					ValueRow.Filter = True;
				EndDo;
			
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(Tree,"TreeByDocuments");
	
EndProcedure

&AtServer
Procedure HierarchyWhenChangingOnServer()
	If Hierarchy = "ForBusinessTransactions" Then
		Items.PagesFilterTree.CurrentPage = Items.PageByBusinessTransactions;
		SaveSelectionsBasedOnDocuments();
		FillInTreeForBusinessOperations();
		Items.FormByBusinessTransactions.Check = True;
		Items.ByDocuments.Check = False;
	Else
		Items.PagesFilterTree.CurrentPage = Items.PageOnDocuments;
		SaveSelectionsForBusinessTransactions();
		FillInTreeByDocuments();
		Items.FormByBusinessTransactions.Check = False;
		Items.ByDocuments.Check = True;
	EndIf;
EndProcedure

&AtServer
Procedure SaveSelectionsForBusinessTransactions()
	
	Tree = FormAttributeToValue("BusinessTransactionTree");
	
	TableFilters = GetFromTempStorage(AddressAvailableBusinessTransactionsAndDocuments);
	TableFilters.FillValues(False, "Filter");
	
	Filter = New Structure("BusinessOperation, MetadataObjectID");
	
	For Each HierarchyLine In Tree.Rows Do
		
		If HierarchyLine.Filter Then
			
			Filter.BusinessOperation = HierarchyLine.BusinessOperation;
			
			For Each ValueRow In HierarchyLine.Rows Do
				If ValueRow.Filter Then
					Filter.MetadataObjectID = ValueRow.MetadataObjectID;
					
					TableFilters.FindRows(Filter)[0].Filter = True;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	PutToTempStorage(TableFilters, AddressAvailableBusinessTransactionsAndDocuments);
	
EndProcedure

&AtServer
Procedure SaveSelectionsBasedOnDocuments()
	
	Tree = FormAttributeToValue("TreeByDocuments");
	
	TableFilters = GetFromTempStorage(AddressAvailableBusinessTransactionsAndDocuments);
	TableFilters.FillValues(False, "Filter");
	
	Filter = New Structure("BusinessOperation, MetadataObjectID");
	
	For Each HierarchyLine In Tree.Rows Do
		
		If HierarchyLine.Filter Then
			
			Filter.MetadataObjectID = HierarchyLine.MetadataObjectID;
			
			For Each ValueRow In HierarchyLine.Rows Do
				If ValueRow.Filter Then
					Filter.BusinessOperation = ValueRow.BusinessOperation;
					
					TableFilters.FindRows(Filter)[0].Filter = True;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	PutToTempStorage(TableFilters, AddressAvailableBusinessTransactionsAndDocuments);
	
EndProcedure

&AtServer
Procedure SaveSelectionsOnlyByDocuments()
	
	Tree = FormAttributeToValue("TreeByDocuments");
	
	TableFilters = GetFromTempStorage(AddressAvailableBusinessTransactionsAndDocuments);
	TableFilters.FillValues(False, "Filter");
	
	Filter = New Structure("MetadataObjectID");
	
	For Each HierarchyLine In Tree.Rows Do
		
		If HierarchyLine.Filter Then
			
			Filter.MetadataObjectID = HierarchyLine.MetadataObjectID;
			FoundRows = TableFilters.FindRows(Filter);
			
			For Each FoundRow In FoundRows Do
				FoundRow.Filter = True;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	PutToTempStorage(TableFilters, AddressAvailableBusinessTransactionsAndDocuments);
	
EndProcedure


&AtServer
Procedure SaveSelections()
	
	If Hierarchy = "ForBusinessTransactions" Then
		SaveSelectionsForBusinessTransactions();
	Else
		If OnlyByDocumentTypes Then
			SaveSelectionsOnlyByDocuments();
		Else
			SaveSelectionsBasedOnDocuments();
		EndIf;
	EndIf;
	
	TableFilters = GetFromTempStorage(AddressAvailableBusinessTransactionsAndDocuments);
	If TableFilters.FindRows(New Structure("Filter", True)).Count() = 0 Then
		TableFilters.FillValues(True, "Filter");
		PutToTempStorage(TableFilters, AddressAvailableBusinessTransactionsAndDocuments);
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveFormSettings(BusinessOperation = Undefined, MetadataObjectID = Undefined)
	
	FormSettings = New Structure();
	FormSettings.Insert("BusinessOperation", BusinessOperation);
	FormSettings.Insert("MetadataObjectID", MetadataObjectID);
	FormSettings.Insert("Hierarchy", Hierarchy);
	Common.CommonSettingsStorageSave(SettingsKey+FormKey, CreateMode, FormSettings);
	
EndProcedure

&AtClient
Procedure ExpandTheTree()
	
	#If WebClient Then
		If Hierarchy = "ForBusinessTransactions" Then
			For Each TreeItem In BusinessTransactionTree.GetItems() Do
				If TreeItem.ItemCount > 1 Then
					Items.BusinessTransactionTree.Expand(TreeItem.GetID());
				EndIf;
			EndDo;
		Else
			For Each TreeItem In TreeByDocuments.GetItems() Do
				If TreeItem.ItemCount > 1 Then
					Items.TreeByDocuments.Expand(TreeItem.GetID());
				EndIf;
			EndDo;
		EndIf;
	#EndIf
	
EndProcedure

&AtServer
Function PresentationOfBusinessTransaction(Selection, Var_Parameters)
	
	PresentationOfBusinessTransaction = Selection.BusinessOperation;
	
	If Not Var_Parameters.OnlyConsignmentSales25 Then
		If Selection.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent 
			Or Selection.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
			PresentationOfBusinessTransaction = StrTemplate("%1 (%2)", Selection.BusinessOperation, ConsignmentSalesServer.PostfixCommissionSchemes(Selection.MetadataObjectID));
		ElsIf Selection.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
			Or Selection.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit 
			Or Selection.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent Then
			PresentationOfBusinessTransaction = StrTemplate("%1 (%2)", Selection.BusinessOperation, ConsignmentSalesServer.PostfixCommissionSchemes25());
		EndIf;
	EndIf;
	
	Return PresentationOfBusinessTransaction;
	
EndFunction

&AtServer
Procedure AddBusinessOperationsCommission25(Tree, Selection)
	
	Presentation = StrTemplate("%1 (%2)", Selection.BusinessOperation, ConsignmentSalesServer.PostfixCommissionSchemes(Selection.MetadataObjectID));
	
	LineInCommissionHierarchy = Tree.Rows.Find(Presentation, "Presentation");

	If LineInCommissionHierarchy = Undefined Then
		
		LineInCommissionHierarchy = Tree.Rows.Add();
		LineInCommissionHierarchy.BusinessOperation = Selection.BusinessOperation;
		LineInCommissionHierarchy.Picture = 0;
		LineInCommissionHierarchy.Presentation = Presentation;
		
	EndIf;
	
	ValueRow = LineInCommissionHierarchy.Rows.Find(Selection.MetadataObjectID, "MetadataObjectID");
	
	If ValueRow = Undefined Then
		
		ValueRow = LineInCommissionHierarchy.Rows.Add();
		ValueRow.BusinessOperation = Selection.BusinessOperation;
		ValueRow.MetadataObjectID = Selection.MetadataObjectID;
		ValueRow.Filter = Selection.Filter;
		ValueRow.Presentation = TrimAll(Selection.DocumentPresentation);
		ValueRow.Picture = 1;
		
		LineInCommissionHierarchy.Filter = ValueRow.Filter;
		LineInCommissionHierarchy.ItemCount = LineInCommissionHierarchy.ItemCount + 1;
		
	EndIf;
	
EndProcedure


#EndRegion


