#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);

	SettlementsTypeSettlementsWithCustomer = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	CounterpartiesLinkType = New TypeDescription("CatalogRef.Counterparties");
	CompanyLinkType = New TypeDescription("CatalogRef.Companies");
	
	SetVisibilityAvailabilityOfFields();
	SetCounterpartyType();
	SetVisibilityOfBasementPages();
	
	If Not ValueIsFilled(Object.Ref) Then
		OnCreatReadAtServer();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustment.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation, Object.CorrespondenceWithIncome);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.ARAPAdjustment.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	If Object.Patch Then
		Items.DebtTeamFillInOnBalances.Visible = False;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	SetBookmarksForBooksAndArticles();
	
	BlockSettlementObjects();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	Notify("Write_ARAPAdjustment", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	DocumentCorrectionClient.AfterWrite(Object);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnCreatReadAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustment.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation, Object.CorrespondenceWithIncome);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.ARAPAdjustment.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	SetVisibilityOfBasementPages();
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	If Object.Debt_.Count() > 0 And ValueIsFilled(Object.Debt_[0].ARAPCurrency) Then
		For Each String In Object.IncomeExpensesAssetsLiabilities Do
			If Not ValueIsFilled(String.Currency) Then
				String.Currency = Object.Debt_[0].ARAPCurrency;
			EndIf;
		EndDo;
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ExpensesByList Or Not ListRevenues Then
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("ArticlesWithoutSplitting", Not ExpensesByList Or Not ListRevenues);
		ArticleElements = New Structure;
		If Items.ExpensesPage.Visible Then
			ArticleElements.Insert("PresentationOfTS", Items.ExpensesPage.Title);
			ArticleElements.Insert("TSItem", "ExpensesAssetsLiabilities");
			ArticleElements.Insert("AssetRef", Items.ExpenseItem.Title);
		Else
			ArticleElements.Insert("PresentationOfTS", Items.RevenuePage.Title);
			ArticleElements.Insert("TSItem", "IncomeAssetsLiabilities");
			ArticleElements.Insert("AssetRef", Items.IncomeItem.Title);
		EndIf;
		DocumentObject.AdditionalProperties.Insert("ArticleElements", ArticleElements);
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		CheckedAttributes.Clear();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Async Procedure OrganizationOnChange(Item)
	
	Response = Await CanClearDebtAsync();
	If Response = DialogReturnCode.No Then
		Object.Organization = PreviousOrganization;
	Else
		ClearTabularSectionDebt();
		OrganizationWhenChangedOnServer();
		PreviousOrganization = Object.Organization;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure IntercompanyARAPOnChange(Item)
	
	Response = Await CanClearDebtAsync();
	If Response = DialogReturnCode.No Then
		Object.IntercompanyARAP = Not Object.IntercompanyARAP;
	Else
		ClearTabularSectionDebt();
		SettlementsBetweenOrganizationsWhenChangesAreMadeOnServer();
		PreviousCounterparty = Object.Counterparty;
		PreviousOrganization = Object.Organization;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure CounterpartyOnChange(Item)
	
	Response = Await CanClearDebtAsync();
	If Response = DialogReturnCode.No Then
		Object.Counterparty = PreviousCounterparty;
	Else
		FillInForm();
		ClearTabularSectionDebt();
		SetVisibilityOfBasementPages();
		PreviousCounterparty = Object.Counterparty;
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Return;
	EndIf;
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure AssetRefStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure AssetRefOnChange(Item)
	AssetRefOnChangeServer(Item.Name);
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure DimensionOfRevenueOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure AssetsLiabilitiesDimensionOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure PresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
EndProcedure

&AtClient
Procedure IncomeExpensesAssetsLiabilitiesSelection(Item, RowSelected, Field, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	Return;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

&AtClient
Procedure AccrualOnChange(Item)
	
	AccrualOnChangeServer();
	
EndProcedure

&AtClient
Procedure SwitchCostsWhenChanging(Item)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Expenses", ExpensesByList);
	ResponseHandler1 = New CallbackDescription("CompletingSwitching", ThisObject, AdditionalParameters);
	
	If ExpensesByList Then
		If Object.Debt_.Count() > 1 Then
			QueryText = NStr("vi = 'Chỉ có thể điều chỉnh công nợ theo danh sách các dạng theo một đối tượng hạch toán.
			|Phần bảng công nợ sẽ được rút gọn vào một bản ghi.
			|Tiếp tục?';
			|ru = 'Корректировка задолженности по списку статей возможна только по одному объекту расчетов.
			|Табличная часть задолженности будет сокращена до одной записи.
			|Продолжить?';
			|en = 'You can adjust AR/AP of the item list only for one AR/AP object.
			|AR/AP table will be reduced to one record.
			|Continue?'; fa = 'You can adjust AR/AP of the item list only for one AR/AP object.
			|AR/AP table will be reduced to one record.
			|Continue?';
			|it = 'La rettifica del debito da elenco voci è possibile solo per un oggetto di calcolo.
			|La parte tabellare del debito sarà ridotta ad una registrazione.
			|Continuare?';
			|pl = 'Korekta zadłużenia według listy pozycji jest możliwa tylko według jednego obiektu rozliczeń.
			|Sekcja tabelaryczna zadłużenia zostanie skrócona do jednego wpisu.
			|Kontynuować?';
			|tr = 'Kalem listesine göre borç düzeltmesi yalnızca bir alacak/borç nesnesi için mümkündür.
			|Borcun tablo kısmı tek bir kayda indirgenecektir.
			|Devam et?'");
			AdditionalParameters.Insert("OneToManyDebt");
			ShowQueryBox(ResponseHandler1, QueryText, QuestionDialogMode.YesNo);
		Else
			EstablishOneToManyRelationship();
		EndIf;
		
	Else
		If Object.IncomeExpensesAssetsLiabilities.Count() > 1 Then
			QueryText = NStr("vi = 'Phần bảng các dạng sẽ được rút gọn vào một bản ghi.
			|Tiếp tục?';
			|ru = 'Табличная часть статей будет сокращена до одной записи.
			|Продолжить?';
			|en = 'Item table will be reduced to one record.
			|Continue?'; fa = 'Item table will be reduced to one record.
			|Continue?';
			|it = 'La parte tabellare delle voci sarà ridotta ad una registrazione.
			|Continuare?';
			|pl = 'Sekcja tabelaryczna pozycji zostanie skrócona do jednego wpisu.
			|Kontynuować?';
			|tr = 'Borcun tablo kısmı tek bir kayda indirgenecektir.
			|Devam et?'");
			AdditionalParameters.Insert("DebtManyToOne");
			ShowQueryBox(ResponseHandler1, QueryText, QuestionDialogMode.YesNo);
		Else
			SetDebtManyToOne();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure IncomeWhenChangingSwitch(Item)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Income", ListRevenues);
	ResponseHandler1 = New CallbackDescription("CompletingSwitching", ThisObject, AdditionalParameters);
	
	If ListRevenues Then
		If Object.Debt_.Count() > 1 Then
			QueryText = NStr("vi = 'Chỉ có thể điều chỉnh công nợ theo danh sách các dạng theo một đối tượng hạch toán.
			|Phần bảng công nợ sẽ được rút gọn vào một bản ghi.
			|Tiếp tục?';
			|ru = 'Корректировка задолженности по списку статей возможна только по одному объекту расчетов.
			|Табличная часть задолженности будет сокращена до одной записи.
			|Продолжить?';
			|en = 'You can adjust AR/AP of the item list only for one AR/AP object.
			|AR/AP table will be reduced to one record.
			|Continue?'; fa = 'You can adjust AR/AP of the item list only for one AR/AP object.
			|AR/AP table will be reduced to one record.
			|Continue?';
			|it = 'La rettifica del debito da elenco voci è possibile solo per un oggetto di calcolo.
			|La parte tabellare del debito sarà ridotta ad una registrazione.
			|Continuare?';
			|pl = 'Korekta zadłużenia według listy pozycji jest możliwa tylko według jednego obiektu rozliczeń.
			|Sekcja tabelaryczna zadłużenia zostanie skrócona do jednego wpisu.
			|Kontynuować?';
			|tr = 'Kalem listesine göre borç düzeltmesi yalnızca bir alacak/borç nesnesi için mümkündür.
			|Borcun tablo kısmı tek bir kayda indirgenecektir.
			|Devam et?'");
			AdditionalParameters.Insert("OneToManyDebt");
			ShowQueryBox(ResponseHandler1, QueryText, QuestionDialogMode.YesNo);
		Else
			EstablishOneToManyRelationship();
		EndIf;
	Else
		If Object.IncomeExpensesAssetsLiabilities.Count() > 1 Then
			QueryText = NStr("vi = 'Phần bảng các dạng sẽ được rút gọn vào một bản ghi.
			|Tiếp tục?';
			|ru = 'Табличная часть статей будет сокращена до одной записи.
			|Продолжить?';
			|en = 'Item table will be reduced to one record.
			|Continue?'; fa = 'Item table will be reduced to one record.
			|Continue?';
			|it = 'La parte tabellare delle voci sarà ridotta ad una registrazione.
			|Continuare?';
			|pl = 'Sekcja tabelaryczna pozycji zostanie skrócona do jednego wpisu.
			|Kontynuować?';
			|tr = 'Borcun tablo kısmı tek bir kayda indirgenecektir.
			|Devam et?'");
			AdditionalParameters.Insert("DebtManyToOne");
			ShowQueryBox(ResponseHandler1, QueryText, QuestionDialogMode.YesNo);
		Else
			SetDebtManyToOne();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SwitchOpenWhenChanging(Item)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Debt_", DebtList);
	ResponseHandler1 = New CallbackDescription("CompletingSwitching", ThisObject, AdditionalParameters);
	
	If DebtList Then
		If Object.IncomeExpensesAssetsLiabilities.Count() > 1 Then
			QueryText = NStr("vi = 'Chỉ có thể điều chỉnh công nợ theo danh sách các đối tượng hạch toán theo một dạng.
			|Phần bảng các dạng sẽ được rút gọn vào một bản ghi.
			|Tiếp tục?';
			|ru = 'Корректировка задолженности по списку объектов расчетов возможна только по одной статье.
			|Табличная часть статей будет сокращена до одной записи.
			|Продолжить?';
			|en = 'You can adjust AR/AP of the AR/AP object list only for one item.
			|Item table will be reduced to one record.
			|Continue?'; fa = 'You can adjust AR/AP of the AR/AP object list only for one item.
			|Item table will be reduced to one record.
			|Continue?';
			|it = 'La rettifica del debito da elenco degli oggetti di calcolo è possibile solo per una voce.
			|La parte tabellare delle voci sarà ridotta ad una registrazione.
			|Continuare?';
			|pl = 'Korekta zadłużenia według listy obiektów rozliczeń jest możliwe tylko według jednej pozycji.
			|Sekcja tabelaryczna zostanie skrócona do jednego wpisu.
			|Kontynuować?';
			|tr = 'Alacak/Borç nesneleri listesine göre borç düzeltmesi yalnızca bir kalem ile mümkündür.
			|Kalemlerin tablo kısmı tek bir girişe indirilecektir.
			|Devam et?'");
			AdditionalParameters.Insert("DebtManyToOne");
			ShowQueryBox(ResponseHandler1, QueryText, QuestionDialogMode.YesNo);
		Else
			SetDebtManyToOne();
		EndIf;
	Else
		If Object.Debt_.Count() > 1 Then
			QueryText = NStr("vi = 'Phần bảng công nợ sẽ được rút gọn vào một bản ghi.
			|Tiếp tục?';
			|ru = 'Табличная часть задолженности будет сокращена до одной записи.
			|Продолжить?';
			|en = 'AR/AP table will be reduced to one record.
			|Continue?'; fa = 'AR/AP table will be reduced to one record.
			|Continue?';
			|it = 'La parte tabellare del debito sarà ridotta ad una registrazione.
			|Continuare?';
			|pl = 'Sekcja tabelaryczna zadłużenia zostanie skrócona do jednego wpisu.
			|Kontynuować?';
			|tr = 'Borcun tablo kısmı tek kayda indirilecektir.
			|Devam et?'");
			AdditionalParameters.Insert("OneToManyDebt");
			ShowQueryBox(ResponseHandler1, QueryText, QuestionDialogMode.YesNo);
		Else
			EstablishOneToManyRelationship();
			UpdatePresentationOfPaymentDate();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompletingSwitching(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		If AdditionalParameters.Property("OneToManyDebt") Then
			EstablishOneToManyRelationship();
			UpdatePresentationOfPaymentDate();
		ElsIf AdditionalParameters.Property("DebtManyToOne") Then
			SetDebtManyToOne();
		EndIf;
		
	Else
		If AdditionalParameters.Property("Expenses") Then
			ExpensesByList = Not AdditionalParameters.Expenses;
			
		ElsIf AdditionalParameters.Property("Income") Then
			ListRevenues = Not AdditionalParameters.Income;
			
		ElsIf AdditionalParameters.Property("Debt_") Then
			DebtList = Not AdditionalParameters.Debt_;
			
		EndIf;
		
	EndIf;
	
	
EndProcedure

&AtClient
Procedure CorrespondenceWithIncomeOnChange(Item)
	CorrespondenceWithRevenueWhenChangingOnServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDebt_

&AtClient
Procedure Debt_OnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.Debt_.CurrentData;
	
	If NewRow And Not Copy Then
		
		If Not ValueIsFilled(Partner) Then
			FillInForm();
		EndIf;
		
		TableRow.Partner = Partner;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Debt_PaymentType_OnChange(Item)
	TableRow = Items.Debt_.CurrentData;
	TableRow.ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	TableRow.PaymentDate = Date(1, 1, 1);
	UpdatePresentationOfPaymentDate();
EndProcedure

&AtClient
Procedure Debt_ARAPObjectOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure Debt_ARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	TableRow = Items.Debt_.CurrentData;
	
	FilterValues = New Structure;
	FilterValues.Insert("PaymentType_", TableRow.PaymentType_);
	FilterValues.Insert("Organization", Object.Organization);
	FilterValues.Insert("Counterparty",  Object.Counterparty);
	FilterValues.Insert("PaymentsAsPer275FZ" , False);
	If Object.Debt_.Count() > 1 Then
		FilterValues.Insert("ARAPCurrency" , Object.Debt_[0].ARAPCurrency);
	EndIf;
	
	If TypeOf(FilterValues.Counterparty) = Type("CatalogRef.Companies") Then
		FilterValues.Insert("Partner", PredefinedValue("Catalog.Partners.OurEnterprise"));
	Else
		FilterValues.Insert("Partner", TableRow.Partner);
	EndIf;
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("SelectingThePaymentBasis", False);
	SelectionSettings_.Insert("EditableDocument", Object.Ref);
	SelectionSettings_.Insert("Sum", 0);
	SelectionSettings_.Insert("Filter", FilterValues);
	SelectionSettings_.Insert("SelectAccountsReceivable", ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ARWriteOff"),
																True,
																False));
	SelectionSettings_.Insert("ReturnStructure", True);
	SelectionSettings_.Insert("CurrentRow", TableRow.ARAPObject);
	
	OpenForm("Catalog.ARAPObjects.ChoiceForm", SelectionSettings_, Item);
	
EndProcedure

&AtClient
Procedure ObjectOfCalculationsWithoutSplittingClearing(Item, StandardProcessing)
	
	Items.PartnerWithoutSplitting.ReadOnly = False;

EndProcedure

&AtClient
Procedure Debt_ARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)

	TableRow = Items.Debt_.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		StandardProcessing = False;
		FillPropertyValues(TableRow, ValueSelected);
		Modified = True;
	EndIf; 
	ThisIsObjectOfCalculationsProcessingSelectionOnSilver(ValueSelected, TableRow.LineNumber);
	
EndProcedure

&AtClient
Procedure ObjectOfCalculationsWithoutSplittingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	FillInDataOfCalculationObjectSelection(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure ObjectOfCalculationsWithoutSplittingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	FillInDataOfCalculationObjectSelection(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure Debt_ARAPObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	FillInDataOfCalculationObjectSelection(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure Debt_ARAPObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	FillInDataOfCalculationObjectSelection(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure ObjectOfCalculationsWithoutSplittingOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure Debt_AfterDeleteRow(Item)
	DebtAfterDeletionOnServer();
EndProcedure

&AtClient
Procedure PaymentDateWithoutDivisionOnChange(Item)
	
	Object.Debt_[0].PaymentDate = PaymentDateWithoutDivision;
	UpdatePresentationOfPaymentDate();
	
EndProcedure

&AtClient
Procedure PaymentDateWithoutDivisionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure("InitialValue", Object.Debt_[0].PaymentDate);
	CallbackDescription = New CallbackDescription("PaymentDateWithoutDivisionEndOfSelection", ThisObject);
	OpenForm("CommonForm.SelectDate", OpeningParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PaymentDateWithoutDivisionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.Debt_[0].PaymentDate = Date(1, 1, 1);
	UpdatePresentationOfPaymentDate();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExpenses

&AtClient
Procedure ExpensesOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.ExpensesAssetsLiabilities.CurrentData;
	If NewRow And Not Copy Then
		If Object.Debt_.Count() > 0 Then
			TableRow.Currency = Object.Debt_[0].ARAPCurrency;
		EndIf;
	EndIf;
	If NewRow And Not Copy Then
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, TableRow, "Object.IncomeExpensesAssetsLiabilities");
	EndIf;
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIncome

&AtClient
Procedure IncomeOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.IncomeAssetsLiabilities.CurrentData;
	If NewRow And Not Copy Then
		If Object.Debt_.Count() > 0 Then
			TableRow.Currency = Object.Debt_[0].ARAPCurrency;
		EndIf;
	EndIf;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, TableRow, "Object.IncomeExpensesAssetsLiabilities");
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// This function is used in the AutoTest of the sales process.
//
&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure AutoTestFillInTheRemainingBalance(Command) Export
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Debt_;
	CheckParameters.CheckedAttributes.Insert("Organization",           NStr("vi = 'Doanh nghiệp';
																			|ru = 'Организация';
																			|en = 'Company'; fa = 'Company';
																			|it = 'Azienda';
																			|pl = 'Firma';
																			|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Counterparty",            NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Controparte';
																			|pl = 'Kontrahent';
																			|tr = 'Cari hesap'"));
	CheckParameters.CheckedAttributes.Insert("BusinessOperation", NStr("vi = 'Ghi giảm';
																		|ru = 'Списание';
																		|en = 'Write-off'; fa = 'اسقاط';
																		|it = 'Storno';
																		|pl = 'Write-off';
																		|tr = 'Gider yazma'"));
	Notification = New CallbackDescription("AutoTestFillInTheRemainingBalanceCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure AutoTestFillInTheRemainingBalanceCompletion(Result, AdditionalParameters) Export 
	
	FillInOutstandingBalancesServer();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInAdditionalCostsForReturnsToSupplier(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Debt_;
	CheckParameters.CheckedAttributes.Insert("Organization",           NStr("vi = 'Doanh nghiệp';
																			|ru = 'Организация';
																			|en = 'Company'; fa = 'Company';
																			|it = 'Azienda';
																			|pl = 'Firma';
																			|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Counterparty",            NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Controparte';
																			|pl = 'Kontrahent';
																			|tr = 'Cari hesap'"));
	Notification = New CallbackDescription("FillInAdditionalCostsForReturnsToSupplierCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInAdditionalCostsForReturnsToSupplierCompletion(Result, AdditionalParameters) Export 
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Counterparty", Object.Counterparty);
	Notification = New CallbackDescription("TransferAdditionalExpenses", ThisObject);
	OpenForm("Document.ARAPAdjustment.Form.ChoiceFormAdditionalExpenses", FormParameters, ThisObject,,,,Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TransferAdditionalExpenses(Result, AdditionalParameters) Export 
	
	If Result <> Undefined Then
		FillInAdditionalCostsForContractsToSupplierOnServer(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// Maturity Date
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Debt_PaymentDate.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Debt_.PaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	OrGroup = AndGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.AccrualOfAccountsReceivable;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Debt_.PaymentType_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.AccrualOfAccountsPayable;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Debt_.PaymentType_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tự động>';
													|ru = '<автоматически>';
													|en = '<automatically>'; fa = '<automatically>';
													|it = '<автоматически>';
													|pl = '<automatically>';
													|tr = '<otomatik olarak>'"));
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	SetVisibilityAvailabilityOfFields();
	SetCounterpartyType();
	If Object.IncomeExpensesAssetsLiabilities.Count() > Object.Debt_.Count() Then
		InstallDebtWithoutPartitioning();
		SetArticlesAsList();
	EndIf;
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.ExpensesPage.Title = NStr("vi = 'Chi phí';
										|ru = 'Расходы';
										|en = 'Expenses'; fa = 'هزینه‌ها';
										|it = 'Spese';
										|pl = 'Expenses';
										|tr = 'Giderler'");
		Items.RevenuePage.Title = NStr("vi = 'Thu nhập';
										|ru = 'Доходы';
										|en = 'Income'; fa = 'درآمد';
										|it = 'Ricavi';
										|pl = 'Income';
										|tr = 'Gelirler'");
	EndIf;
	
	PreviousOrganization = Object.Organization;
	PreviousCounterparty = Object.Counterparty;
	
EndProcedure

&AtServer
Procedure SetDebtManyToOne()

	SetDebtAsList();
	InstallArticlesWithoutSplitting();
	
EndProcedure

&AtServer
Procedure EstablishOneToManyRelationship()

	InstallDebtWithoutPartitioning();
	SetArticlesAsListAndUpdateAmounts();
	
EndProcedure

&AtServer
Procedure InstallDebtWithoutPartitioning()
	
	If Object.Debt_.Count() = 0 Then
		NewRow = Object.Debt_.Add();
		NewRow.Partner = Partner;
		Items.Debt_.CurrentRow = NewRow.GetID();
		
	ElsIf Object.Debt_.Count() > 0 Then
		Items.Debt_.CurrentRow = Object.Debt_[0].GetID();
		If Object.Debt_.Count() > 1 Then
			ShortenTabularPart(Object.Debt_);
		EndIf;
		
	EndIf;
	Items.DebtPages.CurrentPage = Items.DebtWithoutDivision;
	DebtList = 0;
	Items.PaymentDateWithoutDivision.Visible = Object.ThisIsAccrual;
	
EndProcedure

&AtServer
Procedure SetDebtAsList()
	
	Items.DebtPages.CurrentPage = Items.DebtList;
	DebtList = 1;
		
EndProcedure

&AtServer
Procedure InstallArticlesWithoutSplitting()
	
	If Object.IncomeExpensesAssetsLiabilities.Count() = 0 Then
		NewRow = Object.IncomeExpensesAssetsLiabilities.Add();
		Items.ExpensesAssetsLiabilities.CurrentRow = NewRow.GetID();
		Items.IncomeAssetsLiabilities.CurrentRow = NewRow.GetID();
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.IncomeExpensesAssetsLiabilities");
		
	ElsIf Object.IncomeExpensesAssetsLiabilities.Count() > 0 Then
		Items.ExpensesAssetsLiabilities.CurrentRow = Object.IncomeExpensesAssetsLiabilities[0].GetID();
		Items.IncomeAssetsLiabilities.CurrentRow = Object.IncomeExpensesAssetsLiabilities[0].GetID();
		If Object.IncomeExpensesAssetsLiabilities.Count() > 1 Then
			ShortenTabularPart(Object.IncomeExpensesAssetsLiabilities);
		EndIf;
		
	EndIf;
	Object.IncomeExpensesAssetsLiabilities[0].Sum = Object.Debt_.Total("Sum");
	Items.PagesExpenses.CurrentPage = Items.ExpensesWithoutSplitting;
	ExpensesByList = 0;
	Items.PagesIncome.CurrentPage = Items.RevenueWithoutSplitting;
	ListRevenues = 0;
		
EndProcedure

&AtServer
Procedure SetArticlesAsList()
	
	Items.PagesExpenses.CurrentPage = Items.ExpensesByList;
	ExpensesByList = 1;
	Items.PagesIncome.CurrentPage = Items.ListRevenues;
	ListRevenues = 1;
		
EndProcedure

&AtServer
Procedure SetArticlesAsListAndUpdateAmounts(UpdateAmounts = True)
	
	SetArticlesAsList();
	If Object.Debt_.Count() > 0 And Object.IncomeExpensesAssetsLiabilities.Count() > 0 And UpdateAmounts Then
		Object.IncomeExpensesAssetsLiabilities[0].Sum = Object.Debt_[0].Sum;
		Object.IncomeExpensesAssetsLiabilities[0].Currency = Object.Debt_[0].ARAPCurrency;
	EndIf;
		
EndProcedure

&AtServer
Procedure ShortenTabularPart(TabPart)
	
	While TabPart.Count() > 1 Do
		TabPart.Delete(TabPart.Count()-1);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetBookmarksForBooksAndArticles()
	
	SetDebtAsList();
	If Object.Debt_.Count() = 1 And Object.IncomeExpensesAssetsLiabilities.Count() > 1 Then
		InstallDebtWithoutPartitioning();
	EndIf;
	
	// Initialize the tabular part of the articles
	If Object.IncomeExpensesAssetsLiabilities.Count() <= 1 Then
		InstallArticlesWithoutSplitting();
		
	ElsIf Object.Debt_.Count() = 1 And Object.IncomeExpensesAssetsLiabilities.Count() > 1 Then
		SetArticlesAsList();
		
	EndIf;
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure OrganizationWhenChangedOnServer()
	SetupParameters = Documents.ARAPAdjustment.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	SetVisibilityOfBasementPages();
	Return;
	
EndProcedure

&AtServer
Procedure AccrualOnChangeServer()
	
	If Object.CorrespondenceWithIncome
		And (WriteOffOperation(Object.BusinessOperation) = Enums.BusinessTransactions.ARWriteOff
			Or AccrualOperation(Object.BusinessOperation) = Enums.BusinessTransactions.AccrualOfAccountsPayable ) Then
		Object.CorrespondenceWithIncome = False;
	ElsIf Not Object.CorrespondenceWithIncome 
		And (WriteOffOperation(Object.BusinessOperation) = Enums.BusinessTransactions.APWriteOff) Then
		Object.CorrespondenceWithIncome = True;
	EndIf;
	SetVisibilityAvailabilityOfFields();
	WhenSelectingArticlesOnServer();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	TheseAreExpenses = Object.BusinessOperation = Enums.BusinessTransactions.ARWriteOff
		Or Object.BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance
		Or Object.BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsPayable;
	If TheseAreExpenses And Object.CorrespondenceWithIncome Then
		Object.CorrespondenceWithIncome = Not TheseAreExpenses;
	ElsIf Not Object.CorrespondenceWithIncome 
		And Object.BusinessOperation = Enums.BusinessTransactions.APWriteOff Then
		Object.CorrespondenceWithIncome = True;
	EndIf;
	
	If Object.ThisIsAccrual Then
		For Each TSRow In Object.Debt_ Do
			TSRow.PaymentDate = Date(1, 1, 1);
		EndDo;
	EndIf;
	SetupParameters = Documents.ARAPAdjustment.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	SetVisibilityAvailabilityOfFields();
	WhenSelectingArticlesOnServer();
	
EndProcedure

&AtServer
Procedure CorrespondenceWithRevenueWhenChangingOnServer()
	SetVisibilityAvailabilityOfFields();
	WhenSelectingArticlesOnServer();
EndProcedure

&AtServer
Procedure WhenSelectingArticlesOnServer()
	
	ArticleSelectionOptions = Documents.ARAPAdjustment.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation, Object.CorrespondenceWithIncome);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisForm, ArticleSelectionOptions);
	
EndProcedure

&AtServer
Procedure SettlementsBetweenOrganizationsWhenChangesAreMadeOnServer()
	
	SetCounterpartyType();
	SetVisibilityOfBasementPages();
	
EndProcedure

&AtServer
Procedure AssetRefOnChangeServer(TagName)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	SetupParameters = Documents.ARAPAdjustment.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
EndProcedure

&AtServer
Procedure ThisIsObjectOfCalculationsProcessingSelectionOnSilver(ARAPObject, CurrentRowNumber)
	
	If TypeOf(ARAPObject) = Type("CatalogRef.ARAPObjects") Then
		Retweets = Common.ObjectAttributesValues(ARAPObject, "Partner,ARAPCurrency,Contract");
	ElsIf TypeOf(ARAPObject) = Type("Structure") Then
		Retweets = Common.ObjectAttributesValues(ARAPObject.ARAPObject, "Partner,ARAPCurrency,Contract");
	EndIf;
	
	ItIsAllowedToWorkWithSubsidiaryPartners = False;
	If ValueIsFilled(Retweets.Contract) And TypeOf(Retweets.Contract) = Type("CatalogRef.CounterpartyContracts") Then
		ItIsAllowedToWorkWithSubsidiaryPartners = Common.ObjectAttributeValue(Retweets.Contract, "ItIsAllowedToWorkWithSubsidiaryPartners");
	EndIf;
	Items.PartnerWithoutSplitting.ReadOnly = Not ItIsAllowedToWorkWithSubsidiaryPartners;
	
	For Each TableRow In Object.Debt_ Do
		If TableRow.LineNumber = CurrentRowNumber Then
			TableRow.Partner = Retweets.Partner;
			TableRow.ARAPCurrency = Retweets.ARAPCurrency;
		EndIf;
	EndDo;
	SetVisibilityOfBasementPages();
	For Each ArticleLine In Object.IncomeExpensesAssetsLiabilities Do
		ArticleLine.Currency = Object.Debt_[0].ARAPCurrency;
	EndDo;
	
	BlockSettlementObjects();
	
EndProcedure
#EndRegion

#Region FillType

&AtServer
Procedure FillInForm()
	
	If ValueIsFilled(Object.Counterparty) Then
		Partner = CashServer.GetCounterpartyPartner(Object.Counterparty);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInOutstandingBalancesServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.APWriteOff Then
		DebtType = Enums.DebtTypes.AccountsPayableType;
	Else
		DebtType = Enums.DebtTypes.AccountsReceivableType;
	EndIf;
	
	ARAPAccountingServer.FillInOutstandingBalances(
		Object.Organization, 
		Object.Counterparty,
		DebtType, 
		Undefined, //PaymentType_
		Object.Date,
		Undefined, // Currency,
		Object.Debt_);
	BlockSettlementObjects();
	
	SetVisibilityOfBasementPages();
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetCounterpartyType()
	Items.Counterparty.TypeRestriction = ?(Object.IntercompanyARAP,CompanyLinkType,CounterpartiesLinkType);
	Items.Debt_Partner.Visible = Not Object.IntercompanyARAP;
	Items.PartnerWithoutSplitting.Visible = Not Object.IntercompanyARAP;
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfFields()
	
	Items.Accrual.ReadOnly = Not GetFunctionalOption("NewOnlineARAPAccounting");
	
	If Object.BusinessOperation = Enums.BusinessTransactions.APWriteOff
		Or Object.BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsPayable Then
		Items.TitleCounterparty.Title = NStr("vi = 'Người cho vay:';
											|ru = 'Кредитор:';
											|en = 'Creditor:'; fa = 'Creditor:';
											|it = 'Creditore:';
											|pl = 'Creditor:';
											|tr = 'Alacaklı:'");
	Else
		Items.TitleCounterparty.Title = NStr("vi = 'Phải thu:';
											|ru = 'Дебитор:';
											|en = 'Debtor:'; fa = 'بدهکار:';
											|it = 'Debitore:';
											|pl = 'Debtor:';
											|tr = 'Borçlu:'");
	EndIf;
	
	SetAvailabilityByCalculationObjectWithoutSplitting();
	
	ChoiceList = Items.BusinessOperation.ChoiceList;
	ChoiceList.Clear();
	If Object.ThisIsAccrual Then
		Object.BusinessOperation = AccrualOperation(Object.BusinessOperation);
		ChoiceList.Add(Enums.BusinessTransactions.AccrualOfAccountsReceivable, NStr("vi = 'công nợ phải thu';
																					|ru = 'дебиторской задолженности';
																					|en = 'Accounts receivable'; fa = 'حساب‌های دریافتنی';
																					|it = 'dei debiti';
																					|pl = 'należności';
																					|tr = 'alacaklar'"));
		ChoiceList.Add(Enums.BusinessTransactions.AccrualOfAccountsPayable, NStr("vi = 'các khoản phải trả';
																				|ru = 'кредиторской задолженности';
																				|en = 'Accounts payable'; fa = 'حساب‌های پرداختنی';
																				|it = 'dei crediti';
																				|pl = 'zobowiązania';
																				|tr = 'borçlar'"));
	Else
		Object.BusinessOperation = WriteOffOperation(Object.BusinessOperation);
		ChoiceList.Add(Enums.BusinessTransactions.ARWriteOff, NStr("vi = 'công nợ phải thu';
																	|ru = 'дебиторской задолженности';
																	|en = 'Accounts receivable'; fa = 'حساب‌های دریافتنی';
																	|it = 'dei debiti';
																	|pl = 'należności';
																	|tr = 'alacaklar'"));
		ChoiceList.Add(Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance, 
			NStr("vi = 'các khoản phải thu từ dự phòng';
				|ru = 'дебиторской задолженности за счет резервов';
				|en = 'AR/AP under allowance'; fa = 'دریافتنی/پرداختنی تحت ذخیره';
				|it = 'crediti per conto delle riserve';
				|pl = 'należności kosztem rezerwy';
				|tr = 'karşılıklardan alacaklar'"));
		ChoiceList.Add(Enums.BusinessTransactions.APWriteOff, NStr("vi = 'các khoản phải trả';
																	|ru = 'кредиторской задолженности';
																	|en = 'Accounts payable'; fa = 'حساب‌های پرداختنی';
																	|it = 'dei crediti';
																	|pl = 'zobowiązania';
																	|tr = 'borçlar'"));
	EndIf;
	
	Items.DebtTeamFillInOnBalances.Visible = Not Object.ThisIsAccrual;
	Items.Debt_FillInAdditionalCostsForReturnsToSupplier.Visible = Object.ThisIsAccrual;
	
	Items.CorrespondenceWithIncome.ReadOnly = Not Object.ThisIsAccrual 
		Or Object.BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsPayable;
	
	Items.ExpensesPage.Visible = Object.BusinessOperation = Enums.BusinessTransactions.ARWriteOff
		Or Object.BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance
		Or Object.BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsPayable
		Or (Object.BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsReceivable And Not Object.CorrespondenceWithIncome);
	
	UseAccountingOfOtherAssetsAndLiabilities = Constants.UseAccountingOfOtherAssetsAndLiabilities.Get();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance 
		Or Not UseAccountingOfOtherAssetsAndLiabilities Then
		Items.ExpensesPage.Title = NStr("vi = 'Chi';
										|ru = 'Расходы';
										|en = 'Expenses'; fa = 'هزینه‌ها';
										|it = 'Расходы';
										|pl = 'Expenses';
										|tr = 'Giderler'");
		Items.ExpenseItem.Title = NStr("vi = 'Dạng chi phí';
										|ru = 'Статья расходов';
										|en = 'Expense item'; fa = 'قلم هزینه';
										|it = 'Voce di spese';
										|pl = 'Rodzaj kosztu';
										|tr = 'Gider kalemi'");
		Items.ExpensesAssetsLiabilitiesAnalyticsGroup.Title = NStr("vi = 'Đối tượng phân tích chi phí';
																	|ru = 'Аналитика расходов';
																	|en = 'Expense dimension'; fa = 'بُعد هزینه';
																	|it = 'Analitica delle uscite';
																	|pl = 'Analityka kosztów';
																	|tr = 'Gider boyutu'");
	Else
		Items.ExpensesPage.Title = NStr("vi = 'Chi phí và tài sản';
										|ru = 'Расходы и активы';
										|en = 'Assets and expenses'; fa = 'دارایی‌ها و هزینه‌ها';
										|it = 'Spese e attività';
										|pl = 'Rozchody i aktywy';
										|tr = 'Giderler ve aktifler'");
		Items.ExpenseItem.Title = NStr("vi = 'Dạng chi phí / tài sản';
										|ru = 'Статья расходов / активов';
										|en = 'Asset/expense item'; fa = 'قلم دارایی/هزینه';
										|it = 'Voce di spese/attivi';
										|pl = 'Rodzaj kosztu / aktywów';
										|tr = 'Gider / varlık kalemi'");
		Items.ExpensesAssetsLiabilitiesAnalyticsGroup.Title = NStr("vi = 'Đối tượng phân tích chi phí / tài sản';
																	|ru = 'Аналитика расходов / активов';
																	|en = 'Dimension of expenses / assets'; fa = 'بُعد هزینه‌ها / دارایی‌ها';
																	|it = 'Analisi dati uscite / attivi';
																	|pl = 'Analityka rozchodów / aktywów';
																	|tr = 'Gider / varlık boyutu'");
	EndIf;
	
	Items.RevenuePage.Visible = Object.BusinessOperation = Enums.BusinessTransactions.APWriteOff
		Or (Object.BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsReceivable And Object.CorrespondenceWithIncome);
	
	If Not UseAccountingOfOtherAssetsAndLiabilities Then
		Items.RevenuePage.Title = NStr("vi = 'Thu nhập';
										|ru = 'Доходы';
										|en = 'Income'; fa = 'درآمد';
										|it = 'Доходы';
										|pl = 'Income';
										|tr = 'Gelirler'");
		Items.IncomeItem.Title = NStr("vi = 'Dạng thu nhập';
										|ru = 'Статья доходов';
										|en = 'Income item'; fa = 'قلم درآمد';
										|it = 'Voce dei ricavi';
										|pl = 'Rodzaj przychodów';
										|tr = 'Gelir kalemi'");
		Items.IncomeAssetsLiabilitiesAnalyticsGroup.Title = NStr("vi = 'Đối tượng phân tích thu nhập';
																|ru = 'Аналитика доходов';
																|en = 'Income dimension'; fa = 'بُعد درآمد';
																|it = 'Analitica dei ricavi';
																|pl = 'Analityka dochodów';
																|tr = 'Gelir boyutu'");
	Else
		Items.RevenuePage.Title = NStr("vi = 'Thu nhập và nguồn vốn';
										|ru = 'Доходы и пассивы';
										|en = 'Income and liabilities'; fa = 'درآمد و بدهی‌ها';
										|it = 'Redditi e passivi';
										|pl = 'Dochody i zobowiązania';
										|tr = 'Gelirler ve yükümlülükler'");
		Items.IncomeItem.Title = NStr("vi = 'Dạng thu nhập / nguồn vốn';
										|ru = 'Статья доходов / пассивов';
										|en = 'Income / liability item'; fa = 'قلم درآمد / بدهی';
										|it = 'Voce attività/passività';
										|pl = 'Rodzaj przychodów / zobowiązania';
										|tr = 'Gelir / yükümlülük kalemi'");
		Items.IncomeAssetsLiabilitiesAnalyticsGroup.Title = NStr("vi = 'Đối tượng phân tích thu nhập / nguồn vốn';
																|ru = 'Аналитика доходов / пассивов';
																|en = 'Dimension of income / liabilities'; fa = 'بُعد درآمد / بدهی‌ها';
																|it = 'Analisi dati entrate / uscite';
																|pl = 'Analityka dochodów / pasywów';
																|tr = 'Gelir / yükümlülük boyutu'");
	EndIf;
	
	Items.Debt_PaymentDate.Visible = Object.ThisIsAccrual;
	If DebtList = 0 And Object.Debt_.Count() = 1 Then
		Items.PaymentDateWithoutDivision.Visible = Object.ThisIsAccrual;
		If Not ValueIsFilled(Object.Debt_[0].PaymentDate)
			And (Object.Debt_[0].PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting")
				And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AccrualOfAccountsReceivable")
					Or Object.Debt_[0].PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting")
						And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AccrualOfAccountsPayable")) Then
			PaymentDateWithoutDivision = NStr("vi = '<tự động>';
												|ru = '<автоматически>';
												|en = '<automatically>'; fa = '<automatically>';
												|it = '<автоматически>';
												|pl = '<automatically>';
												|tr = '<otomatik olarak>'");
			Items.PaymentDateWithoutDivision.TextEdit = False;
			Items.PaymentDateWithoutDivision.MarkIncomplete = False;
		Else
			PaymentDateWithoutDivision = Object.Debt_[0].PaymentDate;
			Items.PaymentDateWithoutDivision.MarkIncomplete = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePresentationOfPaymentDate()
	If Not ValueIsFilled(Object.Debt_[0].PaymentDate)
		And (Object.Debt_[0].PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting")
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AccrualOfAccountsReceivable")
				Or Object.Debt_[0].PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting")
					And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AccrualOfAccountsPayable")) Then
		PaymentDateWithoutDivision = NStr("vi = '<tự động>';
											|ru = '<автоматически>';
											|en = '<automatically>'; fa = '<automatically>';
											|it = '<автоматически>';
											|pl = '<automatically>';
											|tr = '<otomatik olarak>'");
		Items.PaymentDateWithoutDivision.TextEdit = False;
		Items.PaymentDateWithoutDivision.MarkIncomplete = False;
	Else
		PaymentDateWithoutDivision = Object.Debt_[0].PaymentDate;
		Items.PaymentDateWithoutDivision.TextEdit = True;
		Items.PaymentDateWithoutDivision.MarkIncomplete = True;
	EndIf;
EndProcedure

&AtClient
Procedure PaymentDateWithoutDivisionEndOfSelection(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Object.Debt_[0].PaymentDate = Result;
	EndIf;
	UpdatePresentationOfPaymentDate();
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Async Function CanClearDebtAsync()
	
	If ThereAreLines() Then
		QueryText = NStr("vi = 'Số tiền ghi giảm công nợ có thể chưa được cập nhật.
		                        |Xóa danh sách công nợ?';
		                        |ru = 'Суммы списания задолженности могут стать неактуальным.
		                        |Очистить список задолженности?';
		                        |en = 'AR/AP write-off amounts can become irrelevant.
		                        |Clear debt list?'; fa = 'AR/AP write-off amounts can become irrelevant.
		                        |Clear debt list?';
		                        |it = 'Importi di storno del debito possono diventare obsoleti. 
		                        | Cancellare elenco del debito?';
		                        |pl = 'Kwoty umorzenia zadłużenia mogą stać się nieaktualne.
		                        |Oczyścić listę zobowiązań?';
		                        |tr = 'Borç gider yazma işlemlerinin tarihi geçmiş olabilir.
		                        |Borç listesi temizlensin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo);
	Else
		Response = DialogReturnCode.Yes;
	EndIf;
	
	Return Response;
	
EndFunction

&AtClient
Procedure ClearTabularSectionDebt()
	
	If DebtList Then
		Object.Debt_.Clear();
	Else
		Object.Debt_[0].PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.EmptyRef");
		Object.Debt_[0].ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		Object.Debt_[0].PaymentDate = Date(1, 1, 1);
		Object.Debt_[0].Partner = Partner;
		Object.Debt_[0].Sum = 0;
	EndIf;
	
EndProcedure

// Checks the fullness of the tabular part of the Debt
// 
// Returns:
//  Boolean - True if there is data
//
&AtClient
Function ThereAreLines()
	
	If DebtList Then
		ThereAreLines = Object.Debt_.Count() > 0;
	Else
		ThereAreLines = Not (Object.Debt_[0].PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.EmptyRef")
			And Object.Debt_[0].ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef")
			And Object.Debt_[0].Sum = 0)
	EndIf;
	
	Return ThereAreLines;
	
EndFunction

&AtServer
Procedure BlockSettlementObjects()
	
	UnlockDataForEdit(, UUID);
	
	ArrayOfCalculationObjects = New Array;
	For Each TableRow In Object.Debt_ Do
		If ValueIsFilled(TableRow.ARAPObject) Then
			ArrayOfCalculationObjects.Add(TableRow.ARAPObject);
		EndIf;
	EndDo;
	
	CommonClientServer.CollapseArray(ArrayOfCalculationObjects);
	
	For Each ARAPObject In ArrayOfCalculationObjects Do
		//@skip-warning
		Try
		LockDataForEdit(ARAPObject,, UUID);
		Except
		EndTry;
	EndDo;
	
EndProcedure

#EndRegion

&AtServer
Procedure SetVisibilityOfBasementPages()
	
	ARAPCurrency = Undefined;
	Multicurrency = False;
	
	For Each Page1 In Object.Debt_ Do
		
		If ARAPCurrency <> Undefined And ARAPCurrency <> Page1.ARAPCurrency Then
			Multicurrency = True;
			Break;
		EndIf;
		ARAPCurrency = Page1.ARAPCurrency;
		
	EndDo;
	
	If Multicurrency Then
		Items.FooterGroup.CurrentPage = Items.MulticurrencyGroup;
	Else
		Items.FooterGroup.CurrentPage = Items.DocumentGroup_2;
	EndIf;
	
	Items.ListExpensesSwitch.Visible = Not Multicurrency;
	Items.GroupAmountOfExpenses.Visible = Not Multicurrency;
	Items.ListIncomeSwitch.Visible = Not Multicurrency;
	Items.GroupAmountOfIncome.Visible = Not Multicurrency;
	
EndProcedure

&AtClient
Procedure Debt_ARAPCurrencyOnChange(Item)
	SetVisibilityOfBasementPages();
EndProcedure

&AtServer
Function AccrualOperation(BusinessOperation)
	
	Result = BusinessOperation;
	If BusinessOperation = Enums.BusinessTransactions.ARWriteOff
		Or BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance Then
		Result = Enums.BusinessTransactions.AccrualOfAccountsReceivable;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.APWriteOff Then
		Result = Enums.BusinessTransactions.AccrualOfAccountsPayable;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function WriteOffOperation(BusinessOperation)
	
	Result = BusinessOperation;
	If BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsReceivable Then
		Result = Enums.BusinessTransactions.ARWriteOff;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsPayable Then
		Result = Enums.BusinessTransactions.APWriteOff;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInAdditionalCostsForContractsToSupplierOnServer(AddExpensesForGoods)
	
	If AddExpensesForGoods.Count() = 0 Then
		Return;
	EndIf;
	
	ReturnDocuments = New Array;
	Complaints = New Array;
	For Each Page1 In AddExpensesForGoods Do
		If ValueIsFilled(Page1.Claim) Then
			Complaints.Add(Page1.Claim);
		Else
			ReturnDocuments.Add(Page1.DocumentReturnPolicy);
		EndIf;
	EndDo;
	
	DetailsOfDocuments = Common.ObjectsAttributesValues(ReturnDocuments, "Currency,Partner,ARAPObject,Department");
	ClaimDetails = Common.ObjectsAttributesValues(Complaints, "Currency,Partner,ARAPObject");
	For Each Expense In AddExpensesForGoods Do
		If ValueIsFilled(Expense.Claim) Then
			Attributes = ClaimDetails[Expense.Claim];
		Else
			Attributes = DetailsOfDocuments[Expense.DocumentReturnPolicy];
		EndIf;
		NewRow = Object.Debt_.Add();
		NewRow.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		NewRow.Partner = Attributes.Partner;
		NewRow.ARAPCurrency = Attributes.Currency;
		NewRow.Sum = Expense.AdditExpenseAmount;
		NewRow.ARAPObject = Attributes.ARAPObject;
	EndDo;
	
	If Object.IncomeExpensesAssetsLiabilities.Count() = 0 Then
		NewRow = Object.IncomeExpensesAssetsLiabilities.Add();
	Else
		NewRow = Object.IncomeExpensesAssetsLiabilities[0];
	EndIf;
	If Attributes.Property("Department") Then
		NewRow.Department = Attributes.Department;
	EndIf;
	NewRow.Currency = Attributes.Currency;
	NewRow.Sum = Object.Debt_.Total("Sum");
	
EndProcedure

&AtServer
Procedure DebtAfterDeletionOnServer()
	SetVisibilityOfBasementPages();
	BlockSettlementObjects();
EndProcedure

&AtServer
Procedure SetAvailabilityByCalculationObjectWithoutSplitting()
	
	If Object.Debt_.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(CounterpartyContracts.ItIsAllowedToWorkWithSubsidiaryPartners, FALSE) AS ItIsAllowedToWorkWithSubsidiaryPartners
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON ARAPObjects.Contract = CounterpartyContracts.Ref
	|WHERE
	|	ARAPObjects.Ref = &ARAPObject";
	
	Query.SetParameter("ARAPObject", Object.Debt_[0].ARAPObject);
	Selection = Query.Execute().Select();
	
	ItIsAllowedToWorkWithSubsidiaryPartners = False;
	If Selection.Next() Then
		ItIsAllowedToWorkWithSubsidiaryPartners = Selection.ItIsAllowedToWorkWithSubsidiaryPartners;
	EndIf;
	Items.PartnerWithoutSplitting.ReadOnly = Not ItIsAllowedToWorkWithSubsidiaryPartners;
	
EndProcedure

&AtClient
Procedure FillInDataOfCalculationObjectSelection(Text, ChoiceData, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		SelectionSettings = ARAPAccountingClientServer.SelectionDataSelectionStructure();
		SelectionSettings.Counterparty  = Object.Counterparty;
		SelectionSettings.Organization = Object.Organization;
		SelectionSettings.Text       = Text;
		
		ARAPAccountingServerCall.ObjectOfCalculationsBasisOfPaymentProcessingOfReceiptOfSelectionData(
			ChoiceData, 
			SelectionSettings, 
			, 
			True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
