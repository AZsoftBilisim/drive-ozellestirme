
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SetTextOfDynamicListQueries();

	SetUpListOfDocuments();

	RestoreSettings();

	NewServiceParametersOfForm = New Structure();
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);
	
	If Not AccessRight("InteractiveInsert", Metadata.Documents.FixedAssetsInitialRecognition2_4)
		And Not AccessRight("InteractiveInsert", Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation) Then
		
		Items.ListIssueAcceptanceForAccounting.Visible = False;
		Items.ListContextMenuIssueAcceptanceForAccounting.Visible = False;
		Items.List_ExpensesIssueAcceptanceForAccountingBasedOnDeviations.Visible = False;
	EndIf;

	If Not AccessRight("InteractiveInsert", Metadata.Documents.FixedAssetsCostAdditions2_4) Then
		Items.ListToIssueUpgrade.Visible = False;
		Items.ListToArrangeInclusionOfExpensesInCost.Visible = False;
		Items.ListContextMenuIssueUpgrade.Visible = False;
		Items.ListContextMenuIssueInclusionOfExpensesInCost.Visible = False;
		Items.List_ExpensesIssueUpgradeBasedOnDeviations.Visible = False;
	EndIf;

	If Not AccessRight("InteractiveInsert", Metadata.Documents.AllocateVariancesToFixedAssetCost) Then
		Items.ListToArrangeAssignmentOfDeviationsToCostOfFA.Visible = False;
		Items.ListContextMenuAssignDeviationsToCostOfFA.Visible = False;
		Items.List_ExpensesAssignDeviationsToCostOfFAOnBasisOfDeviations.Visible = False;
	EndIf;
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently() Then
		Items.ListDateOfRecognitionAccounting.Visible = False;
		Items.ListDateOfRecognitionManagementAccounting.Title = NStr("vi = 'Ngày tiếp nhận vào kế toán';
																	|ru = 'Дата принятия к учету';
																	|en = 'Date of recognition'; fa = 'تاریخ شناسایی';
																	|it = 'Data di accettazione';
																	|pl = 'Data przyjęcia do ewidencji';
																	|tr = 'Muhasebeleştirme tarihi'");
		Items.ListGroupState.ShowInHeader = False;
		Items.ListDocumentsReflectedWOOPicture.Visible = False;
		Items.ListDocumentsReflectedIn_Image.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseConstructionObjects") Then
		Items.ListFixedAsset.Title = NStr("vi = 'Tài sản cố định';
											|ru = 'Основное средство';
											|en = 'Fixed asset'; fa = 'دارایی ثابت';
											|it = 'Capitale fisso';
											|pl = 'Środek trwały';
											|tr = 'Sabit kıymetler'");
		Items.List_ExpensesFixedAsset.Title = NStr("vi = 'Tài sản cố định';
													|ru = 'Основное средство';
													|en = 'Fixed asset'; fa = 'دارایی ثابت';
													|it = 'Capitale fisso';
													|pl = 'Środek trwały';
													|tr = 'Sabit kıymetler'");
	EndIf;
	
	If Not FormServiceParameters.ComplianceCAAccountingIsKept Then
		Items.ListDocumentsReflectedInImage.Visible = False;
	EndIf;
	
	#Region StandardMechanisms
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ListOfDocumentsGroupLocalVerification);
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing, AdditionalParameters);
	
	// StandardSubsystems.AttachableCommands
	DocumentTypesUsed = New Array;
	For Each OperationDescription In BusinessTransactionsAndDocuments Do
		DocumentTypesUsed.Add(Type("DocumentRef." + StrSplit(OperationDescription.FullDocumentName, ".")[1]));
	EndDo;

	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListDocumentsCommandBar;
	PlacementParameters.GroupsPrefix = "ListDocuments";
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartUpdatingList(0);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "WritingDocumentToFALog" Then
		UpdateDataWhenFormBecomesActive();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterPeriodOnChange(Item)

	If FilterPeriod.StartDate = '00010101' Then
		If FilterPeriod.EndDate = '00010101' Then
			FilterPeriod.Variant = StandardPeriodVariant.ThisMonth;
		Else
			FilterPeriod.StartDate = BegOfMonth(FilterPeriod.EndDate);
		EndIf;
	EndIf;

	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)

	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure FilterFixedAssetOnChange(Item)
	
	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure SelectionToHideRecordedExpensesOnChange(Item)
	
	SetLineSelections(ThisObject);

EndProcedure

&AtClient
Procedure SelectionOfDeviationsOnlyOnChange(Item)
	
	SetLineSelections(ThisObject);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ListFixedAsset
		Or Field = Items.ListAssetID
		Or Field = Items.ListCode Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.FixedAsset);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)

	ListOfFA = New Map();
	
	For Each Item In Items.List.SelectedRows Do
		
		RowData = List.FindByID(Item);
		
		CompaniesList = ListOfFA.Get(RowData.FixedAsset);
		If CompaniesList = Undefined Then
			CompaniesList = New Map();
		EndIf;
		
		CompaniesList.Insert(RowData.Organization, RowData.Organization);
		ListOfFA.Insert(RowData.FixedAsset, CompaniesList);
		
	EndDo;
	
	For Each RowData In List_Expenses Do
		
		CompaniesList = ListOfFA.Get(RowData.FixedAsset);
		If CompaniesList <> Undefined
			And CompaniesList.Get(RowData.Organization) <> Undefined Then
			
			RowData.ShowInList = True;
		Else
			RowData.ShowInList = False;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList_Expenses

&AtClient
Procedure List_ExpensesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.List_Expenses.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(, CurrentData.Document);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListDocuments

&AtClient
Procedure ListDocumentsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListDocumentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Items.ListDocumentsGroupCreateGenerated.ChildItems.Count() <> 0 Then 
		If Copy Then
			TMCommonUseClient.CopyItem(Item);
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then 
			TeamStructure_ = New Structure("Name", Items.ListDocumentsGroupCreateGenerated.ChildItems[0].Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDocumentsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListDocumentsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);

	TMCommonUseClient.SetDeletionMark(Item, Title, CompletionHandler);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueAcceptanceForAccounting(Command)
	
	ParametersOfSelectedLines = ParametersOfSelectedListLines(List, Items.List.SelectedRows);

	If Not CheckParametersOfSelectedLinesInList(ParametersOfSelectedLines)Then
		Return;
	EndIf;
	
	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", ParametersOfSelectedLines.CurrentCompany);
	
	AddReflectionInAccountingForDesignOfDocument(ParametersOfSelectedLines, TheseGrounds);
	
	If ParametersOfSelectedLines.ThereAreConstructionObjects Then
		
		TheseGrounds.Insert("ConstructionObject", ParametersOfSelectedLines.ListOfFA[0]);
		
	Else
		
		If ParametersOfSelectedLines.ListOfFA.Count() = 1 Then
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA[0]);
		Else
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA);
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure("Basis", TheseGrounds);
	
	If ParametersOfSelectedLines.ThereAreNodesComponents Then
		OpenForm("Document.RecognizeSubAssetsComponentsOfDepreciation.ObjectForm", FormParameters);
	Else
		OpenForm("Document.FixedAssetsInitialRecognition2_4.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueUpgrade(Command)
	
	ParametersOfSelectedLines = ParametersOfSelectedListLines(List, Items.List.SelectedRows);
	
	If Not CheckParametersOfSelectedLinesInList(ParametersOfSelectedLines)Then
		Return;
	EndIf;
	
	If ParametersOfSelectedLines.ThereAreNodesComponents Then
		ShowMessageBox(, NStr("vi = 'Không hỗ trợ tạo nâng cấp đối với các chi tiết (thành phần khấu hao).
									  |Cần chọn tài sản cố định chính.';
									  |ru = 'Не поддерживается оформление модернизации для узлов (компонент амортизации).
									  |Необходимо выбрать основные средства.';
									  |en = 'Cannot register appreciation for sub-assets (depreciation component).
									  |Select fixed assets.'; fa = 'Cannot register appreciation for sub-assets (depreciation component).
									  |Select fixed assets.';
									  |it = 'Cannot register appreciation for sub-assets (depreciation component).
									  |Select fixed assets.';
									  |pl = 'Cannot register appreciation for sub-assets (depreciation component).
									  |Select fixed assets.';
									  |tr = 'Alt varlıklar (amortisman bileşenleri) için modernizasyon düzenlenmesi desteklenmiyor. 
									  | Sabit kıymetlerin seçilmesi gerekir.'"));
		Return;
	EndIf;
	
	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", ParametersOfSelectedLines.CurrentCompany);
	TheseGrounds.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.FixedAssetsCostAdditions"));

	AddReflectionInAccountingForDesignOfDocument(ParametersOfSelectedLines, TheseGrounds);

	If ParametersOfSelectedLines.ThereAreConstructionObjects Then
		
		TheseGrounds.Insert("ConstructionObject", ParametersOfSelectedLines.ListOfFA[0]);
		
	Else
		
		If ParametersOfSelectedLines.ListOfFA.Count() = 1 Then
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA[0]);
		Else
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA);
		EndIf;
		
	EndIf;

	FormParameters = New Structure("Basis", TheseGrounds);
	
	OpenForm("Document.FixedAssetsCostAdditions2_4.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure IssueInclusionOfExpensesInCost(Command)
	
	ParametersOfSelectedLines = ParametersOfSelectedListLines(List, Items.List.SelectedRows);
	
	If Not CheckParametersOfSelectedLinesInList(ParametersOfSelectedLines)Then
		Return;
	EndIf;

	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", ParametersOfSelectedLines.CurrentCompany);
	TheseGrounds.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost"));

	AddReflectionInAccountingForDesignOfDocument(ParametersOfSelectedLines, TheseGrounds);

	If ParametersOfSelectedLines.ThereAreConstructionObjects Then
		
		TheseGrounds.Insert("ConstructionObject", ParametersOfSelectedLines.ListOfFA[0]);
		
	Else
		
		If ParametersOfSelectedLines.ListOfFA.Count() = 1 Then
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA[0]);
		Else
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA);
		EndIf;
		
	EndIf;

	FormParameters = New Structure("Basis", TheseGrounds);
	
	OpenForm("Document.FixedAssetsCostAdditions2_4.ObjectForm", FormParameters);

EndProcedure

&AtClient
Procedure AssignDeviationsToCostOfFA(Command)
	
	ParametersOfSelectedLines = ParametersOfSelectedListLines(List, Items.List.SelectedRows);
	
	If Not CheckParametersOfSelectedLinesInList(ParametersOfSelectedLines)Then
		Return;
	EndIf;

	If ParametersOfSelectedLines.ThereAreNodesComponents
		And ParametersOfSelectedLines.ThereAreObjectsOfExploitation Then
		ShowMessageBox(, NStr("vi = 'Không hỗ trợ việc lập chứng từ đồng thời cho cả các bộ phận (thành phần khấu hao) và tài sản cố định.
									  |Cần phải chọn hoặc là các chi tiết (thành phần khấu hao), hoặc là tài sản cố định.';
									  |ru = 'Не поддерживается оформление документа одновременно узлов (компонент амортизации) и основных средств.
									  |Необходимо выбрать либо узлы (компоненты амортизации), либо основные средства.';
									  |en = 'Cannot register the document for sub-assets (depreciation component) and fixed assets simultaneously.
									  |Select either sub-assets (depreciation components) or fixed assets.'; fa = 'Cannot register the document for sub-assets (depreciation component) and fixed assets simultaneously.
									  |Select either sub-assets (depreciation components) or fixed assets.';
									  |it = 'Cannot register the document for sub-assets (depreciation component) and fixed assets simultaneously.
									  |Select either sub-assets (depreciation components) or fixed assets.';
									  |pl = 'Cannot register the document for sub-assets (depreciation component) and fixed assets simultaneously.
									  |Select either sub-assets (depreciation components) or fixed assets.';
									  |tr = 'Alt varlıklar (amortisman bileşenleri) ve sabit kıymetler için aynı anda belge düzenlenmesi desteklenmiyor. 
									  | Ya alt varlıkların (amortisman bileşenlerinin) ya da sabit kıymetlerin seçilmesi gerekir.'"));
		Return;
	EndIf;
	
	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", ParametersOfSelectedLines.CurrentCompany);

	AddReflectionInAccountingForDesignOfDocument(ParametersOfSelectedLines, TheseGrounds);

	If ParametersOfSelectedLines.ThereAreConstructionObjects Then
		
		TheseGrounds.Insert("ConstructionObject", ParametersOfSelectedLines.ListOfFA[0]);
		
	Else
		
		If ParametersOfSelectedLines.ListOfFA.Count() = 1 Then
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA[0]);
		Else
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA);
		EndIf;
		
	EndIf;

	FormParameters = New Structure("Basis", TheseGrounds);
	
	OpenForm("Document.AllocateVariancesToFixedAssetCost.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure IssueAcceptanceForAccountingBasedOnDeviations(Command)
	
	ParametersOfSelectedLines = ParametersOfSelectedListLines(List_Expenses, Items.List_Expenses.SelectedRows);

	If Not CheckParametersOfSelectedLinesInList(ParametersOfSelectedLines)Then
		Return;
	EndIf;
	
	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", ParametersOfSelectedLines.CurrentCompany);
	TheseGrounds.Insert("AdjustmentModeFromPreviousDate", True);
	TheseGrounds.Insert("CorrectionDate", ParametersOfSelectedLines.VariancePeriod);
	
	AddReflectionInAccountingForDesignOfDocument(ParametersOfSelectedLines, TheseGrounds);
	
	If ParametersOfSelectedLines.ThereAreConstructionObjects Then
		
		TheseGrounds.Insert("ConstructionObject", ParametersOfSelectedLines.ListOfFA[0]);
		
	Else
		
		If ParametersOfSelectedLines.ListOfFA.Count() = 1 Then
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA[0]);
		Else
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA);
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure("Basis", TheseGrounds);
	
	If ParametersOfSelectedLines.ThereAreNodesComponents Then
		OpenForm("Document.RecognizeSubAssetsComponentsOfDepreciation.ObjectForm", FormParameters);
	Else
		OpenForm("Document.FixedAssetsInitialRecognition2_4.ObjectForm", FormParameters);
	EndIf;

EndProcedure

&AtClient
Procedure IssueUpgradeBasedOnDeviations(Command)
	
	ParametersOfSelectedLines = ParametersOfSelectedListLines(List_Expenses, Items.List_Expenses.SelectedRows);
	
	If Not CheckParametersOfSelectedLinesInList(ParametersOfSelectedLines)Then
		Return;
	EndIf;

	If ParametersOfSelectedLines.ThereAreNodesComponents Then
		ShowMessageBox(, NStr("vi = 'Không hỗ trợ tạo nâng cấp đối với các bộ phận (thành phần khấu hao).
									  |Cần chọn tài sản cố định chính.';
									  |ru = 'Не поддерживается оформление модернизации для узлов (компонент амортизации).
									  |Необходимо выбрать основные средства.';
									  |en = 'Cannot register appreciation for sub-assets (depreciation component).
									  |Select fixed assets.'; fa = 'Cannot register appreciation for sub-assets (depreciation component).
									  |Select fixed assets.';
									  |it = 'Cannot register appreciation for sub-assets (depreciation component).
									  |Select fixed assets.';
									  |pl = 'Cannot register appreciation for sub-assets (depreciation component).
									  |Select fixed assets.';
									  |tr = 'Alt varlıklar (amortisman bileşenleri) için modernizasyon düzenlenmesi desteklenmiyor. 
									  | Sabit kıymetlerin seçilmesi gerekir.'"));
		Return;
	EndIf;
	
	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", ParametersOfSelectedLines.CurrentCompany);
	TheseGrounds.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.FixedAssetsCostAdditions"));
	TheseGrounds.Insert("AdjustmentModeFromPreviousDate", True);
	TheseGrounds.Insert("CorrectionDate", ParametersOfSelectedLines.VariancePeriod);

	AddReflectionInAccountingForDesignOfDocument(ParametersOfSelectedLines, TheseGrounds);

	If ParametersOfSelectedLines.ThereAreConstructionObjects Then
		
		TheseGrounds.Insert("ConstructionObject", ParametersOfSelectedLines.ListOfFA[0]);
		
	Else
		
		If ParametersOfSelectedLines.ListOfFA.Count() = 1 Then
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA[0]);
		Else
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA);
		EndIf;
		
	EndIf;

	FormParameters = New Structure("Basis", TheseGrounds);
	
	OpenForm("Document.FixedAssetsCostAdditions2_4.ObjectForm", FormParameters);

EndProcedure

&AtClient
Procedure IssueInclusionOfExpensesInCostBasedOnDeviations(Command)
	
	ParametersOfSelectedLines = ParametersOfSelectedListLines(List_Expenses, Items.List_Expenses.SelectedRows);
	
	If Not CheckParametersOfSelectedLinesInList(ParametersOfSelectedLines)Then
		Return;
	EndIf;

	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", ParametersOfSelectedLines.CurrentCompany);
	TheseGrounds.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost"));
	TheseGrounds.Insert("AdjustmentModeFromPreviousDate", True);
	TheseGrounds.Insert("CorrectionDate", ParametersOfSelectedLines.VariancePeriod);

	AddReflectionInAccountingForDesignOfDocument(ParametersOfSelectedLines, TheseGrounds);

	If ParametersOfSelectedLines.ThereAreConstructionObjects Then
		
		TheseGrounds.Insert("ConstructionObject", ParametersOfSelectedLines.ListOfFA[0]);
		
	Else
		
		If ParametersOfSelectedLines.ListOfFA.Count() = 1 Then
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA[0]);
		Else
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA);
		EndIf;
		
	EndIf;

	FormParameters = New Structure("Basis", TheseGrounds);
	
	OpenForm("Document.FixedAssetsCostAdditions2_4.ObjectForm", FormParameters);

EndProcedure

&AtClient
Procedure AssignDeviationsToCostOfFAOnBasisOfDeviations(Command)
	
	ParametersOfSelectedLines = ParametersOfSelectedListLines(List_Expenses, Items.List_Expenses.SelectedRows);
	
	If Not CheckParametersOfSelectedLinesInList(ParametersOfSelectedLines)Then
		Return;
	EndIf;

	TheseGrounds = New Structure;
	TheseGrounds.Insert("Date", CommonClient.SessionDate());
	TheseGrounds.Insert("Organization", ParametersOfSelectedLines.CurrentCompany);

	AddReflectionInAccountingForDesignOfDocument(ParametersOfSelectedLines, TheseGrounds);

	If ParametersOfSelectedLines.ThereAreConstructionObjects Then
		
		TheseGrounds.Insert("ConstructionObject", ParametersOfSelectedLines.ListOfFA[0]);
		
	Else
		
		If ParametersOfSelectedLines.ListOfFA.Count() = 1 Then
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA[0]);
		Else
			TheseGrounds.Insert("FixedAsset", ParametersOfSelectedLines.ListOfFA);
		EndIf;
		
	EndIf;

	FormParameters = New Structure("Basis", TheseGrounds);
	
	OpenForm("Document.AllocateVariancesToFixedAssetCost.ObjectForm", FormParameters);

EndProcedure

&AtClient
Procedure UpdateList(Command)
	
	StartUpdatingList();

EndProcedure

&AtClient
Procedure CapitalizationCostStructureReport(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;

	FormParameters = New Structure;
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("VariantKey", "CostStructure_");
	FormParameters.Insert("CommandParameter", CurrentData.FixedAsset);
	FormParameters.Insert("CommandDetails", New Structure);
	OpenForm("Report.CapitalizationExpenseStructure.Form", FormParameters,, True);

EndProcedure

&AtClient
Procedure ListDocumentsCancellationOfEvent(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListDocuments, Title);
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
EndProcedure

&AtClient
Procedure ListOfDocumentsPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListDocuments, Title);

	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
EndProcedure

&AtClient
Procedure CopyDocumentsList(Command)
	
	TMCommonUseClient.CopyItem(Items.ListDocuments);
	
EndProcedure

&AtClient
Procedure DocumentsListInstallUncheckDelete(Command)
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);

	TMCommonUseClient.SetDeletionMark(Items.ListDocuments, Title, CompletionHandler);
	
EndProcedure

&AtClient
Procedure ListOfInternationalAccountingEntriesDocuments(Command)
	If Items.ListDocuments.CurrentData <> Undefined Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Items.ListDocuments.CurrentData.Ref);
	EndIf; 
	Return;
	
EndProcedure

#Region AttachableCommands

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, SelectionsForCreatingDocument());
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	
	FormKey = DefaultFormAssignmentKey();
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	TMCommonUseClient.CreateDocumentViaSelectionForm(AddressBusinessTransactionsAndDocuments,
		FormKey, PurposeUseKey, SelectionsForCreatingDocument());
		
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.ListDocuments);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure UpdateDataWhenFormBecomesActive()

	AttachIdleHandler("Attachable_UpdateDataWhenFormBecomesActive", 0.8, True);

EndProcedure

&AtClient
Procedure Attachable_UpdateDataWhenFormBecomesActive()
	
	If IsInputAvailable()	
		And Items.GroupPages.CurrentPage = Items.Expenses_Page Then
		
		StartUpdatingList();
	Else
		UpdateDataWhenFormBecomesActive();
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListDocuments);
EndProcedure

&AtClient
Procedure StartUpdatingList(WaitCompletion = Undefined)

	TimeConsumingOperation = StartUpdatingListOnServer(WaitCompletion);
	CallbackOnCompletion = New CallbackDescription("UpdateListCompletion", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtServer
Function StartUpdatingListOnServer(Val WaitCompletion)

	ShouldSaveSettings();

	SetDynamicListSelections_();

	FunctionParameters = New Structure;
	FunctionParameters.Insert("Organization", FilterOrganization);
	FunctionParameters.Insert("Department", FilterDepartment);
	FunctionParameters.Insert("FixedAsset", FilterFixedAsset);
	FunctionParameters.Insert("BeginOfPeriod", FilterPeriod.StartDate);
	FunctionParameters.Insert("EndOfPeriod", FilterPeriod.EndDate);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);

	If WaitCompletion <> Undefined Then
		ExecutionParameters.WaitCompletion = WaitCompletion;
	EndIf;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "DataProcessors.RecognizeAndIncludeExpensesInFixedAssetCost.WorkplaceData", FunctionParameters);
	
	Items.GroupExpenses1.Title = 
		StrTemplate(NStr("vi = 'Các sai lệch về chi phí liên quan đến các tài sản cố định được chọn từ %1 đến %2';
						|ru = 'Отклонения в затратах по выбранным основным средствам с %1 по %2';
						|en = 'Cost variances in selected fixed assets from %1 to %2'; fa = 'Cost variances in selected fixed assets from %1 to %2';
						|it = 'Cost variances in selected fixed assets from %1 to %2';
						|pl = 'Cost variances in selected fixed assets from %1 to %2';
						|tr = 'Seçilen sabit kıymetlerde %1 ile %2 arasındaki maliyet farkları'"),
				Format(?(FilterPeriod.StartDate <> '00010101', FilterPeriod.StartDate, BegOfMonth(CurrentSessionDate())), "DLF=D;"),
				Format(?(FilterPeriod.EndDate <> '00010101', FilterPeriod.EndDate, CurrentSessionDate()), "DLF=D;"));
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure UpdateListCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;

	UpdateListOfFilesOnServer(Result.ResultAddress);
	
EndProcedure 

&AtServer
Procedure UpdateListOfFilesOnServer(Val ResultAddress)
	
	CurrentRow = Items.List.CurrentRow;
	If CurrentRow <> Undefined Then
		RowData = List.FindByID(CurrentRow);
		CurrentRowData = New Structure("FixedAsset,Organization");
		FillPropertyValues(CurrentRowData, RowData);
	Else
		CurrentRowData = Undefined;
	EndIf;
	
	List.Clear();
	List_Expenses.Clear();
	
	Items.ListAmountAccounting.Title = NStr("vi = 'KTDN';
											|ru = 'БУ';
											|en = 'LA'; fa = 'محلی';
											|it = 'Contabilità civilistica';
											|pl = 'EK';
											|tr = 'Genel Muhasebe'");
	Items.ListAmountFA.Title = NStr("vi = 'KTTh';
									|ru = 'НУ';
									|en = 'TA'; fa = 'مالیاتی';
									|it = 'Contabilità fiscale';
									|pl = 'EP';
									|tr = 'Vergi muhasebesi'");
	Items.ListAmountOfUU.Title = NStr("vi = 'UU';
										|ru = 'УУ';
										|en = 'MA'; fa = 'مدیریت';
										|it = 'Contabilità Gestionale';
										|pl = 'EZ';
										|tr = 'Yönetim Muhasebesi'");

	Items.List_ExpensesAmountAccounting.Title = NStr("vi = 'KTDN';
													|ru = 'БУ';
													|en = 'LA'; fa = 'محلی';
													|it = 'Contabilità civilistica';
													|pl = 'EK';
													|tr = 'Genel Muhasebe'");
	Items.List_ExpensesAmountFA.Title = NStr("vi = 'KTTh';
											|ru = 'НУ';
											|en = 'TA'; fa = 'مالیاتی';
											|it = 'Contabilità fiscale';
											|pl = 'EP';
											|tr = 'Vergi muhasebesi'");
	Items.List_ExpensesAmountOfUU.Title = NStr("vi = 'UU';
												|ru = 'УУ';
												|en = 'MA'; fa = 'مدیریت';
												|it = 'Contabilità Gestionale';
												|pl = 'EZ';
												|tr = 'Yönetim Muhasebesi'");
	
	Result = GetFromTempStorage(ResultAddress); // DataProcessors.RecognizeAndIncludeExpensesInFixedAssetCost.WorkplaceData
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CommonClientServer.SupplementTable(Result.List, List);
	CommonClientServer.SupplementTable(Result.List_Expenses, List_Expenses);
	
	If Result.LocalCurrencyList.Count() = 1 Then
		
		CurrencyOfMan = String(Constants.ManagementAccountingCurrency.Get());
		ComplCurrency = String(Result.LocalCurrencyList[0].ComplCurrency);
		
		Items.ListAmountAccounting.Title = StrTemplate(NStr("vi = 'KTDN (%1)';
															|ru = 'БУ (%1)';
															|en = 'LA (%1)'; fa = 'LA (%1)';
															|it = 'Contabilità ordinaria (%1)';
															|pl = 'EK (%1)';
															|tr = 'Genel Muhasebe (%1):'"), ComplCurrency);
		Items.ListAmountFA.Title = StrTemplate(NStr("vi = 'KTTh (%1)';
													|ru = 'НУ (%1)';
													|en = 'TA (%1)'; fa = 'TA (%1)';
													|it = 'НУ (%1)';
													|pl = 'EP (%1)';
													|tr = 'VM (%1)'"), ComplCurrency);
		Items.ListAmountOfUU.Title = StrTemplate(NStr("vi = 'KTQT (%1)';
														|ru = 'УУ (%1)';
														|en = 'MA (%1)'; fa = 'MA (%1)';
														|it = 'Contabilità Gestionale (%1)';
														|pl = 'EZ (%1)';
														|tr = 'Yönetim Muhasebesi(%1):'"), CurrencyOfMan);
	
		Items.List_ExpensesAmountAccounting.Title = StrTemplate(NStr("vi = 'KTDN (%1)';
																	|ru = 'БУ (%1)';
																	|en = 'LA (%1)'; fa = 'LA (%1)';
																	|it = 'Contabilità ordinaria (%1)';
																	|pl = 'EK (%1)';
																	|tr = 'Genel Muhasebe (%1):'"), ComplCurrency);
		Items.List_ExpensesAmountFA.Title = StrTemplate(NStr("vi = 'KTTh (%1)';
															|ru = 'НУ (%1)';
															|en = 'TA (%1)'; fa = 'TA (%1)';
															|it = 'НУ (%1)';
															|pl = 'EP (%1)';
															|tr = 'VM (%1)'"), ComplCurrency);
		Items.List_ExpensesAmountOfUU.Title = StrTemplate(NStr("vi = 'KTQT (%1)';
																|ru = 'УУ (%1)';
																|en = 'MA (%1)'; fa = 'MA (%1)';
																|it = 'Contabilità Gestionale (%1)';
																|pl = 'EZ (%1)';
																|tr = 'Yönetim Muhasebesi(%1):'"), CurrencyOfMan);
		
	EndIf;
	
	If CurrentRowData <> Undefined Then
		SearchResult = List.FindRows(CurrentRowData);
		If SearchResult.Count() <> 0 Then
			Items.List.CurrentRow = SearchResult[0].GetID();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections_()
	
	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterOrganization));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"Department",
		FilterDepartment,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterDepartment));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"FixedAsset",
		FilterFixedAsset,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterFixedAsset));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"AdditionalRecord",
		False,
		DataCompositionComparisonType.Equal,
		,
		Not ValueIsFilled(FilterOrganization));
		
	ListDocuments.Parameters.SetParameterValue("BeginOfPeriod", FilterPeriod.StartDate);
	
	ListDocuments.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(FilterPeriod.EndDate),
			EndOfDay(FilterPeriod.EndDate),
			EndOfDay(Date(3999, 12, 31))));
			
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	AttributesToSaveNames = 
	"FilterPeriod,FilterOrganization,FilterDepartment,FilterFixedAsset,
	|SelectionShowRecordedExpenses,FilterOnlyDeviations";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisObject);
	
	Common.CommonSettingsStorageSave(
		Metadata.DataProcessors.RecognizeAndIncludeExpensesInFixedAssetCost.FullName(), 
		PurposeUseKey, 
		Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	FilterPeriod.Variant = StandardPeriodVariant.ThisMonth;
	
	Settings = Common.CommonSettingsStorageLoad(
		Metadata.DataProcessors.RecognizeAndIncludeExpensesInFixedAssetCost.FullName(), 
		PurposeUseKey);
	
	If TypeOf(Settings) = Type("Structure") Then
		
		FilterPeriod = CommonClientServer.StructureProperty(Settings, "FilterPeriod", StandardPeriodVariant.ThisMonth);
		FilterOrganization = CommonClientServer.StructureProperty(Settings, "FilterOrganization", Catalogs.Companies.EmptyRef());
		FilterDepartment = CommonClientServer.StructureProperty(Settings, "FilterDepartment", Catalogs.BusinessStructure.EmptyRef());
		FilterFixedAsset = CommonClientServer.StructureProperty(Settings, "FilterFixedAsset", Catalogs.Assets.EmptyRef());
		SelectionShowRecordedExpenses = CommonClientServer.StructureProperty(Settings, "SelectionShowRecordedExpenses", False);
		FilterOnlyDeviations = CommonClientServer.StructureProperty(Settings, "FilterOnlyDeviations", False);
		
	EndIf;
	
	SetLineSelections(ThisObject);

EndProcedure

&AtClient
Function ParametersOfSelectedListLines(FormList_, SelectedRows)
	
	ListOfFA = New Array;

	CurrentCompany = Undefined;
	ThereAreObjectsOfExploitation = False;
	ThereAreConstructionObjects = False;
	ThereIsGroupFA = False;
	ThereAreNodesComponents = False;
	ThereAreDifferentOrganizations = False;
	TakenIntoAccountMA = False;
	ACTakenIntoAccount = False;
	TakenIntoAccountTA = False;
	VariancePeriod = '00010101';
	
	ThisIsListOfCosts = FormList_ = List_Expenses;
	
	For Each RowID In SelectedRows Do
		
		RowData = FormList_.FindByID(RowID);
		
		If TypeOf(RowData.FixedAsset) = Type("CatalogRef.ConstructionObjects") Then
			ThereAreConstructionObjects = True;
		EndIf;
		
		If RowData.OSType = PredefinedValue("Enum.FATypes.Asset")
			Or RowData.OSType = PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets") Then
			
			ThereAreObjectsOfExploitation = True;
		
		ElsIf RowData.OSType = PredefinedValue("Enum.FATypes.GroupFA") Then
			
			ThereIsGroupFA = True;
		
		ElsIf RowData.OSType = PredefinedValue("Enum.FATypes.DepreciationComponent")
			Or RowData.OSType = PredefinedValue("Enum.FATypes.Node") Then
			
			ThereAreNodesComponents = True;
		EndIf;
		
		If RowData.Organization <> CurrentCompany 
			And CurrentCompany <> Undefined Then
			ThereAreDifferentOrganizations = True;
		EndIf;
				
		TakenIntoAccountMA = TakenIntoAccountMA Or RowData.TakenIntoAccountMA;
		ACTakenIntoAccount = ACTakenIntoAccount Or RowData.ACTakenIntoAccount;
		TakenIntoAccountTA = TakenIntoAccountTA Or RowData.TakenIntoAccountTA;
		
		If ThisIsListOfCosts Then
			VariancePeriod = ?(VariancePeriod <> '00010101', Min(VariancePeriod, RowData.VariancePeriod), RowData.VariancePeriod);
		EndIf;
		
		If ListOfFA.Find(RowData.FixedAsset) = Undefined Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
		
		CurrentCompany = RowData.Organization;
		
	EndDo;
	
	ParametersOfSelectedListLines = New Structure;
	ParametersOfSelectedListLines.Insert("ThereAreObjectsOfExploitation", ThereAreObjectsOfExploitation);
	ParametersOfSelectedListLines.Insert("ThereAreConstructionObjects", ThereAreConstructionObjects);
	ParametersOfSelectedListLines.Insert("ThereIsGroupFA", ThereIsGroupFA);
	ParametersOfSelectedListLines.Insert("ThereAreNodesComponents", ThereAreNodesComponents);
	ParametersOfSelectedListLines.Insert("ThereAreDifferentOrganizations", ThereAreDifferentOrganizations);
	ParametersOfSelectedListLines.Insert("CurrentCompany", CurrentCompany);
	ParametersOfSelectedListLines.Insert("VariancePeriod", VariancePeriod);
	ParametersOfSelectedListLines.Insert("TakenIntoAccountMA", TakenIntoAccountMA);
	ParametersOfSelectedListLines.Insert("ACTakenIntoAccount", ACTakenIntoAccount);
	ParametersOfSelectedListLines.Insert("TakenIntoAccountTA", TakenIntoAccountTA);
	ParametersOfSelectedListLines.Insert("ListOfFA", ListOfFA);
	
	Return ParametersOfSelectedListLines;
	
EndFunction

&AtClient
Function CheckParametersOfSelectedLinesInList(ParametersOfSelectedLines)
	
	If ParametersOfSelectedLines.ListOfFA.Count() = 0 Then
		Return False;
	EndIf;
	
	If ParametersOfSelectedLines.ThereAreDifferentOrganizations Then
		ShowMessageBox(, NStr("vi = 'Cần chọn tài sản cố định của một doanh nghiệp';
								|ru = 'Необходимо выбрать основные средства одной организации';
								|en = 'Select fixed assets of one company'; fa = 'Select fixed assets of one company';
								|it = 'È necessario selezionare le immobilizzazioni di una azienda';
								|pl = 'Należy wybrać środki trwałe jednej firmy';
								|tr = 'Aynı iş yerinin sabit kıymetlerinin seçilmesi gerekmektedir'"));
		Return False;
	EndIf;

	If ParametersOfSelectedLines.ThereAreConstructionObjects
		And (ParametersOfSelectedLines.ThereIsGroupFA
			Or ParametersOfSelectedLines.ThereAreNodesComponents
			Or ParametersOfSelectedLines.ThereAreObjectsOfExploitation) Then
			
		ShowMessageBox(, NStr("vi = 'Không hỗ trợ tạo chứng từ đồng thời với đối tượng xây dựng cơ bản và tài sản cố định.
									  |Cần chọn một đối tượng xây dựng cơ bản hoặc tài sản cố định.';
									  |ru = 'Не поддерживается оформление документа одновременно объектов строительства и основных средств.
									  |Необходимо выбрать либо один объект строительства, либо основные средства.';
									  |en = 'Cannot register the document for assets under construction and fixed assets simultaneously.
									  |Select either one asset under construction or fixed assets.'; fa = 'Cannot register the document for assets under construction and fixed assets simultaneously.
									  |Select either one asset under construction or fixed assets.';
									  |it = 'Cannot register the document for assets under construction and fixed assets simultaneously.
									  |Select either one asset under construction or fixed assets.';
									  |pl = 'Cannot register the document for assets under construction and fixed assets simultaneously.
									  |Select either one asset under construction or fixed assets.';
									  |tr = 'Yapım aşamasındaki varlıklar ile sabit kıymetler için aynı anda belge düzenlenmesi desteklenmiyor. 
									  | Ya tek bir yapım aşamasındaki varlık ya da sabit kıymetleri seçmelisiniz.'"));
									  
		Return False;
	EndIf;
	
	If ParametersOfSelectedLines.ThereAreNodesComponents
		And ParametersOfSelectedLines.ThereAreObjectsOfExploitation Then
			
		ShowMessageBox(, NStr("vi = 'Không hỗ trợ việc tạo chứng từ đồng thời cho cả các chi tiết (thành phần khấu hao) và tài sản cố định.
									  |Cần phải chọn hoặc là các bộ phận (thành phần khấu hao), hoặc là tài sản cố định.';
									  |ru = 'Не поддерживается оформление документа одновременно для узлов (компонент амортизации) и основных средств.
									  |Необходимо выбрать либо узлы (компоненты амортизации), либо основные средства.';
									  |en = 'Cannot register the document for  sub-assets (depreciation component) and fixed assets simultaneously.
									  |Select either sub-assets (depreciation components) or fixed assets.'; fa = 'Cannot register the document for  sub-assets (depreciation component) and fixed assets simultaneously.
									  |Select either sub-assets (depreciation components) or fixed assets.';
									  |it = 'Cannot register the document for  sub-assets (depreciation component) and fixed assets simultaneously.
									  |Select either sub-assets (depreciation components) or fixed assets.';
									  |pl = 'Cannot register the document for  sub-assets (depreciation component) and fixed assets simultaneously.
									  |Select either sub-assets (depreciation components) or fixed assets.';
									  |tr = 'Alt varlıklar (amortisman bileşenleri) ve sabit kıymetler için aynı anda belge düzenlenmesi desteklenmiyor. 
									  | Ya alt varlıkların (amortisman bileşenlerinin) ya da sabit kıymetlerin seçilmesi gerekir.'"));
		Return False;
	EndIf;
	
	If ParametersOfSelectedLines.ThereAreConstructionObjects
		And ParametersOfSelectedLines.ListOfFA.Count() > 1 Then
			
		ShowMessageBox(, NStr("vi = 'Không hỗ trợ tạo chứng từ cho nhiều đối tượng xây dựng cơ bản.
									  |Cần chọn một đối tượng xây dựng cơ bản.';
									  |ru = 'Не поддерживается оформление документа для нескольких объектов строительства.
									  |Необходимо выбрать один объект строительства.';
									  |en = 'Cannot register the document for several assets under construction.
									  |Select one asset under construction.'; fa = 'Cannot register the document for several assets under construction.
									  |Select one asset under construction.';
									  |it = 'Cannot register the document for several assets under construction.
									  |Select one asset under construction.';
									  |pl = 'Cannot register the document for several assets under construction.
									  |Select one asset under construction.';
									  |tr = 'Birden fazla yapım aşamasındaki varlık için belge düzenlenmesi desteklenmiyor. 
									  | Tek bir yapım aşamasındaki varlık seçilmelidir.'"));
									  
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure AddReflectionInAccountingForDesignOfDocument(ParametersOfSelectedLines, TheseGrounds)

	If ParametersOfSelectedLines.TakenIntoAccountMA 
		And ParametersOfSelectedLines.ACTakenIntoAccount
		And (ParametersOfSelectedLines.TakenIntoAccountTA
			Or Not FormServiceParameters.ComplianceCAAccountingIsKept) Then
				
		TheseGrounds.Insert("RecordInManAccounting", True);
		TheseGrounds.Insert("PostInAccounting", True);
		
	Else
		
		TheseGrounds.Insert("RecordInManAccounting", Not ParametersOfSelectedLines.TakenIntoAccountMA);
		TheseGrounds.Insert("PostInAccounting", Not ParametersOfSelectedLines.ACTakenIntoAccount);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetLineSelections(Form)

	SelectingListLines = New Structure;
	SelectingCostListLines = New Structure;

	SelectingCostListLines.Insert("ShowInList", True);
	
	If Not Form.SelectionShowRecordedExpenses Then
		SelectingListLines.Insert("Considered_3", False);
		SelectingCostListLines.Insert("Considered_3", False);
	EndIf;
	
	If Form.FilterOnlyDeviations Then
		SelectingListLines.Insert("ThereAreVariances", True);
	EndIf;
	
	Form.Items.List.RowFilter = ?(SelectingListLines.Count() <> 0, New FixedStructure(SelectingListLines), Undefined);
	Form.Items.List_Expenses.RowFilter = New FixedStructure(SelectingCostListLines);
	
EndProcedure

&AtServer
Procedure SetUpListOfDocuments()

	TableOfValuesAvailable = InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload(),
		FilterBusinessTransactions,
		FilterDocumentTypes,
		SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
	TMCommonUse.WorkplaceData(
		BusinessTransactionsAndDocuments.Unload(), 
		DefaultFormAssignmentKey(), 
		NStr("vi = 'tất cả';
			|ru = 'все';
			|en = 'all'; fa = 'همه';
			|it = 'all';
			|pl = 'all';
			|tr = 'tümü'"));
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListDocuments, BusinessTransactionsAndDocuments);

	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form = ThisObject;
	ParametersStructure.NameOfCreateGroup = "ListDocumentsGroupCreateGenerated";
	ParametersStructure.GroupNameCreateContext = "ListDocumentsGroupCreateGeneratedContext";
	ParametersStructure.NameOfCopyButton = "CopyDocumentsList";
	ParametersStructure.NameOfCopyContextMenuButton = "ListDocumentsCopyContext";
	ParametersStructure.ChangeButtonName = "ListDocumentsChange";
	ParametersStructure.NameOfChangeContextMenuButton = "DocumentsListChangeContext";
	ParametersStructure.ButtonNamePost = "ListOfDocumentsPost";
	ParametersStructure.NameOfHoldContextMenuButton = "ListDocumentsHoldContext";
	ParametersStructure.NameOfCancelEventButton = "ListDocumentsCancellationOfEvent";
	ParametersStructure.NameOfCancelButtonIsContextMenu = "ListDocumentsCancellationContext";
	ParametersStructure.NameOfMarkDeleteButton = "ListDocumentsSetDeleteMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu = "ListDocumentsSetDeleteContextTag";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
EndProcedure

&AtServerNoContext
Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey, UnregisteredDocuments = False)
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetsInitialRecognition;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	String.ButtonGroup                 = "Recognition";

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.RecognizeSubAssetsComponentsOfDepreciation;
	String.FullDocumentName			= Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	String.ButtonGroup                 = "Recognition";

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetsCostAdditions;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsCostAdditions2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	String.ButtonGroup                 = "Modernization";
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.AllocateVariancesToFixedAssetCost;
	String.FullDocumentName			= Metadata.Documents.AllocateVariancesToFixedAssetCost.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	String.ButtonGroup                 = "Modernization";
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetCostAndDepreciationAdjustment;
	String.FullDocumentName			= Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	String.ButtonGroup                 = "CostAndDepreciationAdjustments";

	For Cnt = 1 To BusinessTransactionsAndDocuments.Count() Do
		BusinessTransactionsAndDocuments[Cnt - 1].Order = Cnt;
	EndDo;
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessTransactionsAndDocuments, 
								FilterBusinessTransactions, 
								FilterDocumentTypes, 
								PurposeUseKey);
	
	Return TableOfValuesAvailable;
		
EndFunction

&AtServer
Procedure SetTextOfDynamicListQueries()

	QueryText = 
	"SELECT
	|	FixedAssetsDocumentsOverridable.FixedAsset,
	|	FixedAssetsDocumentsOverridable.Ref,
	|	FixedAssetsDocumentsOverridable.Organization,
	|	FixedAssetsDocumentsOverridable.Date AS Date,
	|	FixedAssetsDocumentsOverridable.CorrectionPeriodStart AS CorrectionPeriodStart,
	|	FixedAssetsDocumentsOverridable.CorrectionPeriodEnd AS CorrectionPeriodEnd,
	|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
	|	FixedAssetsDocumentsOverridable.BusinessOperation,
	|	FixedAssetsDocumentsOverridable.Department,
	|	DocumentsRegistryOverridable.EmployeeResponsible,
	|	DocumentsRegistryOverridable.More,
	|	DocumentsRegistryOverridable.Comment,
	|	FixedAssetsDocumentsOverridable.Posted,
	|	DocumentsRegistryOverridable.DeletionMark,
	|
	|	CASE
	|		WHEN FixedAssetsDocumentsOverridable.Posted
	|			THEN 0
	|		WHEN DocumentsRegistryOverridable.DeletionMark
	|			THEN 1
	|		ELSE 2
	|	END AS CustomPicture,
	|
	|	FixedAssetsDocumentsOverridable.AdditionalRecord,
	|	DocumentsRegistryOverridable.AdditionalRecord AS AdditionalEntryRegistry,
	|	FixedAssetsDocumentsOverridable.RefType,
	|	VALUETYPE(FixedAssetsDocumentsOverridable.Ref) AS TheTypeOfReferenceDocument,
	|	&CheckStatus AS CheckStatus,
	|	CAST(&CheckingIndicator AS BOOLEAN) AS CheckingIndicator,
	|
	|	CASE
	|		WHEN FixedAssetsDocumentsOverridable.RecordInManAccounting
	|				AND FixedAssetsDocumentsOverridable.Posted
	|			THEN 1
	|		WHEN FixedAssetsDocumentsOverridable.RecordInManAccounting
	|				AND NOT FixedAssetsDocumentsOverridable.Posted
	|			THEN 2
	|		ELSE 0
	|	END AS ReflectedWOOPicture,
	|	
	|	CASE
	|		WHEN FixedAssetsDocumentsOverridable.RecordInLocalAccounting
	|				AND FixedAssetsDocumentsOverridable.Posted
	|			THEN 1
	|		WHEN FixedAssetsDocumentsOverridable.RecordInLocalAccounting
	|				AND NOT FixedAssetsDocumentsOverridable.Posted
	|			THEN 2
	|		ELSE 0
	|	END AS ReflectedIn_Image,
	|
	|	
	|	CASE
	|		WHEN FixedAssetsDocumentsOverridable.RecordInTA
	|				AND FixedAssetsDocumentsOverridable.Posted
	|			THEN 1
	|		WHEN FixedAssetsDocumentsOverridable.RecordInTA
	|				AND NOT FixedAssetsDocumentsOverridable.Posted
	|			THEN 2
	|		ELSE 0
	|	END AS ReflectedInImage,
	|	
	|	CASE
	|		WHEN FilesExistOverridable.HasFiles IS NULL
	|			THEN 0
	|		WHEN FilesExistOverridable.HasFiles
	|			THEN 1
	|		ELSE 0
	|	END AS HasFiles
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS FixedAssetsDocumentsOverridable
	|
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistryOverridable
	|		ON (DocumentsRegistryOverridable.Ref = FixedAssetsDocumentsOverridable.Ref)
	|			AND (NOT DocumentsRegistryOverridable.AdditionalRecord)
	|
	|		LEFT JOIN InformationRegister.FilesExist AS FilesExistOverridable
	|		ON FixedAssetsDocumentsOverridable.Ref = FilesExistOverridable.ObjectWithFiles
	|		
	|{WHERE
	|	FixedAssetsDocumentsOverridable.FixedAsset.* AS FixedAsset,
	|	FixedAssetsDocumentsOverridable.Ref.* AS Ref,
	|	FixedAssetsDocumentsOverridable.Organization.* AS Organization,
	|	FixedAssetsDocumentsOverridable.Date AS Date,
	|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
	|	FixedAssetsDocumentsOverridable.BusinessOperation AS BusinessOperation,
	|	FixedAssetsDocumentsOverridable.Department.* AS Department,
	|	DocumentsRegistryOverridable.EmployeeResponsible.* AS EmployeeResponsible,
	|	DocumentsRegistryOverridable.More AS More,
	|	DocumentsRegistryOverridable.Comment AS Comment,
	|	FixedAssetsDocumentsOverridable.Posted AS Posted,
	|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
	|
	|	(FixedAssetsDocumentsOverridable.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		OR &EndOfPeriod = DATETIME(1, 1, 1)
	|			AND FixedAssetsDocumentsOverridable.Date >= &BeginOfPeriod)}";
	
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.ListDocuments, ListProperties);
	
EndProcedure

&AtClient
Procedure SetClearDeletionMarkCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
		NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	EndIf;
	
EndProcedure

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtClient
Function SelectionsForCreatingDocument()
	
	StructureSelections = New Structure;
	StructureSelections.Insert("AdjustmentModeFromPreviousDate", True);
	
	If ValueIsFilled(FilterOrganization) Then
		StructureSelections.Insert("Organization", FilterOrganization);
	EndIf;
	
	If ValueIsFilled(FilterFixedAsset) Then
		StructureSelections.Insert("FixedAsset", FilterFixedAsset);
	EndIf;
	
	Return StructureSelections;
	
EndFunction

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "RecognizeAndIncludeExpensesInFixedAssetCost";
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
		
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListDocuments.Date", "ListDocumentsDate");
		
	#Region ListDateOfRegistrationBU_Text
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListDateOfRecognitionAccounting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DateOfRecognitionAccounting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không được tiếp nhận';
													|ru = 'Не принято к учету';
													|en = 'Not recognized'; fa = 'شناسایی‌نشده';
													|it = 'Non riconosciuto in contabilità';
													|pl = 'Nie przyjęto do ewidencji';
													|tr = 'Muhasebeleştirilmemiş'"));
	
	#EndRegion
	
	#Region ListDateOfAcceptanceToAccountNU_Text
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListDateOfRecognitionInTaxAccounting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DateOfRecognitionInTaxAccounting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không được tiếp nhận';
													|ru = 'Не принято к учету';
													|en = 'Not recognized'; fa = 'شناسایی‌نشده';
													|it = 'Non riconosciuto in contabilità';
													|pl = 'Nie przyjęto do ewidencji';
													|tr = 'Muhasebeleştirilmemiş'"));
	
	#EndRegion
	
	#Region ListDateOfAcceptanceToACCOUNT_U_Text
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListDateOfRecognitionManagementAccounting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DateOfRecognitionManagementAccounting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không được tiếp nhận';
													|ru = 'Не принято к учету';
													|en = 'Not recognized'; fa = 'شناسایی‌نشده';
													|it = 'Non riconosciuto in contabilità';
													|pl = 'Nie przyjęto do ewidencji';
													|tr = 'Muhasebeleştirilmemiş'"));
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

#EndRegion
